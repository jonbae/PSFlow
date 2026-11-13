// Step 3 H: the numeric call sites W13 left, entered from JavaScript.
//
// Upstream bounds boxes with `Math.min` and `Math.max` and bends a smoothstep
// path with them, so a `NaN` propagates and `-0` sorts below `+0` whatever the
// operand order. PureScript's `min` and `max` go through `Ord`, which does
// neither. Each check runs the same inputs through both libraries and compares
// with `Object.is` semantics.
import assert from 'node:assert/strict';
import test from 'node:test';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';

const special = [-Infinity, -1, -0, 0, 1, Infinity, NaN];

const node = (id, x, y) => ({ id, position: { x, y }, data: {}, width: 10, height: 10 });

test('getNodesBounds unions boxes as Math.min and Math.max do', () => {
  let count = 0;
  for (const first of special) for (const second of special) {
    for (const nodes of [
      [node('a', first, 0), node('b', second, 0)],
      [node('a', 0, first), node('b', 0, second)],
      [node('a', first, second)],
    ]) {
      assert.deepStrictEqual(
        psflow.getNodesBounds(nodes),
        upstream.getNodesBounds(nodes),
        `case ${++count}: ${JSON.stringify(nodes.map((n) => [n.position.x, n.position.y]))}`
      );
    }
  }
});

test('getSmoothStepPath bends and centers as upstream does for any coordinate', () => {
  const positions = ['top', 'right', 'bottom', 'left'];
  let count = 0;
  for (const value of special) for (const field of ['sourceX', 'sourceY', 'targetX', 'targetY']) {
    for (const sourcePosition of positions) for (const targetPosition of positions) {
      const params = {
        sourceX: 0, sourceY: 0, targetX: 100, targetY: 80,
        sourcePosition, targetPosition, [field]: value,
      };
      assert.deepStrictEqual(
        psflow.getSmoothStepPath(params),
        upstream.getSmoothStepPath(params),
        `case ${++count}: ${JSON.stringify(params)}`
      );
    }
  }
});
