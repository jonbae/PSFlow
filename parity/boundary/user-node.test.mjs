import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

function observe(library, node) {
  let result;
  function Probe() {
    const instance = library.useReactFlow();
    const internal = library.useInternalNode(node.id);
    result = { instance: instance.getInternalNode(node.id), hook: internal };
    return null;
  }
  renderToStaticMarkup(createElement(library.ReactFlow, { nodes: [node], edges: [], children: createElement(Probe) }));
  return result;
}

test('getInternalNode and useInternalNode retain the original consumer node', () => {
  const symbol = Symbol('consumer');
  const original = Object.freeze({ id: 'a', position: { x: 10, y: 20 }, data: {}, custom: {}, optional: undefined, [symbol]: 1 });
  for (const library of [upstream, psflow]) {
    const value = observe(library, original);
    assert.equal(value.instance.internals.userNode, original);
    assert.equal(value.hook.internals.userNode, original);
    assert.equal(value.hook.internals.userNode.custom, original.custom);
    assert.ok(Object.hasOwn(value.hook.internals.userNode, 'optional'));
  }
});
