// `ReactFlowProps` and the types its members carry, field by field, mounted
// in a browser on both sides.
//
// Step 4 order 10 audits each E02 type's fields at their readers
// (`AAMF_TYPE_CONTRACT_REVIEW.md`). Most of `<ReactFlow />`'s members take
// effect after mount: `<StoreUpdater />` writes them in an effect, a pane or
// a handle reads them on input, or a measurement decides them. A server
// render sees none of that, so these cases run in Chromium through
// `browser/harness.mjs`, one page per side, and compare everything a
// consumer can read back. `flow-contracts.cases.mjs` says what each case
// mounts and drives.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { open } from './browser/harness.mjs';
import cases from './flow-contracts.cases.mjs';

const casesFile = fileURLToPath(new URL('./flow-contracts.cases.mjs', import.meta.url));
let harness;

before(async () => {
  harness = await open(casesFile);
});
after(() => harness?.close());

const falsification = 'falsification: the sides mount different props';

test('the page runs every case in the table', () => {
  assert.deepEqual(harness.names, cases.map((c) => c.name));
  assert.equal(new Set(harness.names).size, harness.names.length, 'two cases share a name');
});

test('a case whose sides mount different props differs', async () => {
  const { upstream, psflow } = await harness.run(falsification);
  assert.notDeepEqual(psflow, upstream);
});

for (const { name } of cases) {
  if (name === falsification) continue;
  test(name, async () => {
    const { upstream, psflow } = await harness.run(name);
    assert.ok(upstream.state !== null, 'upstream did not mount');
    assert.deepEqual(psflow, upstream);
  });
}
