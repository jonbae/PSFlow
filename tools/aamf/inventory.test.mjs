// Fail before network/install work when a replay would overwrite evidence or
// put AAMF state in the checkout. Exercise the real command, including symlinks.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, readdir, rm, symlink, writeFile, mkdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, test } from 'node:test';

const command = fileURLToPath(new URL('./inventory.mjs', import.meta.url));
const repo = fileURLToPath(new URL('../../', import.meta.url));
let fixture;
before(async () => { fixture = await mkdtemp(join(tmpdir(), 'psflow-inventory-guards-')); });
after(async () => { await rm(fixture, { recursive: true, force: true }); });
function rejects(args, message) {
  const result = spawnSync(process.execPath, [command, ...args], { encoding: 'utf8', timeout: 10000 });
  assert.equal(result.error, undefined, result.error?.message);
  assert.equal(result.status, 1, result.stdout + result.stderr);
  assert.match(result.stderr, message);
  assert.equal(result.stdout, '', 'no command or install should have started');
}

test('invalid arguments and AAMF-invalid project names fail before creating paths', async () => {
  rejects([], /Usage:/);
  for (const name of ['review.12', 'Review', 'review_12', '../review', '']) {
    rejects([join(fixture, 'invalid-work'), join(fixture, 'invalid-artifacts'), name], /Usage:/);
  }
  assert.deepEqual(await readdir(fixture), []);
});

test('existing workspace and artifact bytes cannot be overwritten', async () => {
  const work = join(fixture, 'existing-work');
  const artifacts = join(fixture, 'existing-artifacts');
  await mkdir(work);
  await writeFile(join(work, 'keep'), 'original workspace');
  await writeFile(artifacts, 'original artifacts');
  rejects([work, join(fixture, 'unused-artifacts'), 'review'], /Refusing to overwrite existing path/);
  rejects([join(fixture, 'unused-work'), artifacts, 'review'], /Refusing to overwrite existing path/);
  assert.equal(await readFile(join(work, 'keep'), 'utf8'), 'original workspace');
  assert.equal(await readFile(artifacts, 'utf8'), 'original artifacts');
  assert.ok(!(await readdir(fixture)).includes('unused-work'));
});

test('checkout state and workspace/artifact nesting are rejected even through symlinks', async () => {
  const alias = join(fixture, 'checkout-alias');
  await symlink(repo, alias, 'dir');
  rejects([join(repo, 'forbidden-state'), join(fixture, 'unused'), 'review'], /outside the PSFlow checkout/);
  rejects([join(alias, 'forbidden-state'), join(fixture, 'unused'), 'review'], /outside the PSFlow checkout/);
  const work = join(fixture, 'nested-work');
  rejects([work, join(work, 'artifacts'), 'review'], /must be separate/);
  rejects([join(work, 'state'), work, 'review'], /must be separate/);
  // Resolve an existing alias to the workspace's parent, with new children.
  const parentAlias = join(fixture, 'parent-alias');
  await symlink(dirname(work), parentAlias, 'dir');
  rejects([work, join(parentAlias, 'nested-work/artifacts'), 'review'], /must be separate/);
  assert.ok(!(await readdir(fixture)).includes('nested-work'));
});
