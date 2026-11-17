// Exercise stale or incomplete review inputs in a disposable checkout-shaped
// fixture. No upstream source, runtime state or evidence in the repo is edited.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { copyFile, mkdir, mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { refreshReconciliation, renderReconciliation } from './refresh-reconciliation.mjs';
import { json, validateMapping } from './psflow-integration.mjs';

const repo = fileURLToPath(new URL('../../', import.meta.url));
let root;
before(async () => {
  root = await mkdtemp(join(tmpdir(), 'psflow-reconciliation-'));
  const current = await json(join(repo, 'aamf/step2/reconciliation.json'));
  const paths = new Set([
    ...Object.keys(current.targetHashes), ...Object.keys(current.evidenceHashes),
    ...current.units.map(u => `xyflow/${u.source}`),
    ...Object.keys(current.packages).map(p => `xyflow/packages/${p}/package.json`),
    'package.json', 'AAMF_STEP2_MAPPING.md', 'aamf/step2/reconciliation.json',
    'aamf/step2/pilot-reconciliation.json', 'aamf/step4/order-11/profiles.json',
    'aamf/step1/inventory.json', 'aamf/step1/imports.json',
  ]);
  await Promise.all([...paths].map(async path => {
    await mkdir(dirname(join(root, path)), { recursive: true });
    await copyFile(join(repo, path), join(root, path));
  }));
  // Only the read-only ancestry check uses Git; mutations use copied files.
  await symlink(join(repo, '.git'), join(root, '.git'));
});
after(async () => { if (root) await rm(root, { recursive: true, force: true }); });

async function withEdit(path, edit, run) {
  const full = join(root, path);
  const original = await readFile(full, 'utf8');
  try { await writeFile(full, edit(original)); await run(); }
  finally { await writeFile(full, original); }
}
const editJson = change => text => {
  const value = JSON.parse(text);
  change(value);
  return `${JSON.stringify(value, null, 2)}\n`;
};

test('all certified units agree in both outputs; repeated refresh is stable', async () => {
  await refreshReconciliation(root, true);
  await refreshReconciliation(root);
  await refreshReconciliation(root, true);
  const mapping = await json(join(root, 'aamf/step2/reconciliation.json'));
  assert.equal(mapping.units.length, 171);
  assert.deepEqual(mapping.tasks, []);
  assert.deepEqual(mapping.counts, { Reuse: 170, 'Accepted difference': 1 });
  assert.equal(mapping.units.filter(u => u.knownIssues.length).length, 8);
  // A current review must never become an executable Step 2 pilot input.
  await assert.rejects(validateMapping(mapping, join(root, 'xyflow'), root));
});

test('missing certified unit and changed vendored source are rejected', async () => {
  await withEdit('aamf/step1/inventory.json', editJson(j => j.pop()), async () => {
    await assert.rejects(renderReconciliation(root), /Certified scope changed/);
  });
  await withEdit('xyflow/packages/system/src/utils/general.ts', text => `${text}\n// fault\n`, async () => {
    await assert.rejects(renderReconciliation(root), /Stale source/);
  });
});

test('unowned dispositions and broken evidence anchors cannot close a profile', async () => {
  await withEdit('aamf/step4/order-11/profiles.json', editJson(j => {
    j.profiles.E03.disposition = 'Finish conversion';
  }), async () => { await assert.rejects(renderReconciliation(root), /Unowned work: E03/); });
  await withEdit('aamf/step4/order-11/profiles.json', editJson(j => {
    j.profiles.E01.evidenceRefs[0] = 'AAMF_STEP3_RESULTS.md#nonexistent-evidence';
  }), async () => { await assert.rejects(renderReconciliation(root), /Missing evidence anchor/); });
});

test('target/evidence drift, stale dispositions and queued tasks fail check mode', async () => {
  await withEdit('src/Boundary/Store.purs', text => `${text}\n-- fault\n`, async () => {
    await assert.rejects(refreshReconciliation(root, true), /Stale reconciliation/);
  });
  await withEdit('aamf/step2/reconciliation.json', editJson(j => {
    j.units[0].disposition = 'Fix behavior';
  }), async () => { await assert.rejects(refreshReconciliation(root, true), /Stale reconciliation/); });
  await withEdit('test/Test/Parity/Geometry.purs', text => `${text}\n-- fault\n`, async () => {
    await assert.rejects(refreshReconciliation(root, true), /Stale reconciliation/);
  });
  await withEdit('aamf/step2/reconciliation.json', editJson(j => {
    j.tasks.push({ id: 'psflow-w01-viewport' });
  }), async () => { await assert.rejects(refreshReconciliation(root, true), /Stale reconciliation/); });
});

test('pilot input and source-to-target ownership remain guarded', async () => {
  await withEdit('aamf/step2/pilot-reconciliation.json', text => `${text}\n`, async () => {
    await assert.rejects(renderReconciliation(root), /Historical pilot input changed/);
  });
  await withEdit('AAMF_STEP2_MAPPING.md', text => text.replace(
    '(src/React/Additional/Background.purs)', '(src/React/Additional/Controls.purs)'), async () => {
    await assert.rejects(renderReconciliation(root), /Target mismatch/);
  });
});
