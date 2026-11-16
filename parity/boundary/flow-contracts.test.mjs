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

// Differences outside the type contracts, each owned by an issue. A case
// listed here must differ in exactly the stated way and match otherwise, and
// it fails as stale once the sides agree, so the entry goes when its cause
// does.
const deprecation = (entry) => entry.text?.startsWith('[DEPRECATED] `useHandleConnections`');
const known = [
  {
    cases: (name) => name.startsWith('useHandleConnections'),
    issue: 'A custom node renders once more than upstream at mount (jonbae/PSFlow#207)',
    // `useHandleConnections` warns on every call, so a node rendered more
    // often logs the warning more often, and nothing else differs.
    holds(upstream, psflow) {
      const count = (result) => result.console.filter(deprecation).length;
      const without = (result) => ({ ...result, console: result.console.filter((e) => !deprecation(e)) });
      assert.deepEqual(without(psflow), without(upstream));
      assert.ok(count(psflow) > count(upstream), 'ps-flow no longer logs more deprecation warnings');
    },
  },
];

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
  const claim = known.find((k) => k.cases(name));
  test(claim ? `${name} — known: ${claim.issue}` : name, async () => {
    const { upstream, psflow } = await harness.run(name);
    assert.ok(upstream.state !== null, 'upstream did not mount');
    if (!claim) return assert.deepEqual(psflow, upstream);
    assert.notDeepEqual(psflow, upstream, `stale: the sides agree, so retire the claim for ${claim.issue}`);
    claim.holds(upstream, psflow);
  });
}
