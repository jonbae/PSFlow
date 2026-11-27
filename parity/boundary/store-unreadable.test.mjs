// Structured store members written with a value of the wrong shape, against
// upstream, after mount: `store-unreadable.cases.mjs` says what each case
// writes and what it goes on to do.
//
// Upstream's store is a plain object, so it holds the value as written, and
// each place its code reads the member does to it what JavaScript does. A
// case compares what a consumer can read afterward: each step's result or the
// kind of error it threw, the callbacks fired, what was printed, the store
// and the DOM.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { open } from './browser/harness.mjs';
import cases from './store-unreadable.cases.mjs';

const casesFile = fileURLToPath(new URL('./store-unreadable.cases.mjs', import.meta.url));
const falsification = 'falsification: the sides write different values';
let harness;

before(async () => {
  harness = await open(casesFile);
});
after(() => harness?.close());

test('the page runs every case in the table', () => {
  assert.deepEqual(harness.names, cases.map((c) => c.name));
  assert.equal(new Set(harness.names).size, harness.names.length, 'two cases share a name');
});

test('a case whose sides write different values differs', async () => {
  const { upstream: up, psflow: ps } = await harness.run(falsification);
  assert.notDeepEqual(ps, up);
});

for (const { name } of cases) {
  if (name === falsification) continue;
  test(name, async () => {
    const { upstream: up, psflow: ps } = await harness.run(name);
    assert.ok(up.state !== null, 'upstream did not mount');
    assert.deepEqual(ps, up);
  });
}
