import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { digest, json } from './psflow-integration.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(process.argv[2]);
assert.equal(execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim(),
  '7dc475d81ef9796b5b90f57a29475eaafa375753', 'Unsupported AAMF revision');
const plans = [];
for (const spec of await json(join(here, 'step2-patches.json'))) {
  const path = join(root, spec.path);
  const current = await readFile(path, 'utf8');
  let original = current;
  if (digest(original) !== spec.originalHash) {
    for (const [before, after] of [...spec.changes].reverse()) {
      assert.equal(original.split(after).length - 1, 1, `Unrecognized build: ${path}`);
      original = original.replace(after, before);
    }
  }
  assert.equal(digest(original), spec.originalHash, `Unrecognized build: ${path}`);
  let patched = original;
  for (const [before, after] of spec.changes) {
    assert.equal(patched.split(before).length - 1, 1);
    patched = patched.replace(before, after);
  }
  plans.push({ path, patched, originalHash: spec.originalHash, patchedHash: digest(patched) });
}
// Verify all seven inputs before writing any of them. Rebuild AAMF before
// reapplying if upstream or the build toolchain changes.
for (const plan of plans) await writeFile(plan.path, plan.patched);
const adapter = await readFile(join(here, 'psflow-integration.mjs'));
await writeFile(join(root, 'dist/core/psflow-integration.mjs'), adapter);
console.log(JSON.stringify({ adapterSha256: digest(adapter), patches: plans.map(({ path, originalHash, patchedHash }) => ({ path, originalHash, patchedHash })) }, null, 2));
