// Differential regressions for custom-node mount renders and controlled selection.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { fileURLToPath } from 'node:url';
import cases from './node-rendering.cases.mjs';
import { open } from './browser/harness.mjs';

let harness;
before(async () => {
  harness = await open(fileURLToPath(new URL('./node-rendering.cases.mjs', import.meta.url)));
});
after(() => harness?.close());

for (const { name } of cases) {
  test(name, async () => {
    const { upstream, psflow } = await harness.run(name);
    assert.deepEqual(psflow, upstream);
    if (name.startsWith('custom node:')) {
      assert.equal(upstream[0].renders, 2, 'the custom node rendered at mount and after measurement');
      assert.equal(upstream[1].label, 'updated', 'a subsequent node update reaches the component');
    }
    if (name.includes('an ignored controlled change')) {
      assert.deepEqual(upstream.driven.map(({ drawn }) => drawn), [false, false, false, true]);
      assert.deepEqual(upstream.driven.slice(1).map(({ same }) => same), [true, true, false]);
    } else if (name.startsWith('selection:')) {
      const unselecting = name.includes('another notification');
      assert.equal(upstream.internal, !unselecting, 'the action changed the internal selection');
      assert.equal(upstream.drawn, unselecting, 'ignored controlled changes have not reached the DOM');
    }
  });
}
