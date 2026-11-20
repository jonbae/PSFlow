import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

function observe(library, node, props = {}) {
  let result;
  function Probe() {
    const instance = library.useReactFlow();
    const internal = library.useInternalNode(node.id);
    const store = library.useStoreApi();
    result = { instance: instance.getInternalNode(node.id), hook: internal, flow: instance, store };
    return null;
  }
  const flow = createElement(library.ReactFlow, { nodes: [node], edges: [], ...props, children: createElement(Probe) });
  // SSR does not run StoreUpdater's effects. Seed uncontrolled nodes directly
  // through the provider so both libraries start with the same live store.
  renderToStaticMarkup(props.defaultNodes
    ? createElement(library.ReactFlowProvider, { defaultNodes: props.defaultNodes }, flow)
    : flow);
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

test('uncontrolled changes retain consumer fields through later reads and delete callbacks', async () => {
  const symbol = Symbol('consumer');
  const original = Object.freeze({ id: 'a', position: { x: 10, y: 20 }, data: {}, custom: {}, optional: undefined, [symbol]: 1 });
  for (const library of [upstream, psflow]) {
    const callbacks = [];
    const { flow, store } = observe(library, original, {
      nodes: undefined,
      defaultNodes: [original],
    });
    store.setState({ onNodesDelete(nodes) { callbacks.push(nodes); } });
    let expected = [original];
    for (const changes of [
      [{ type: 'select', id: 'a', selected: true }],
      [{ type: 'position', id: 'a', position: { x: 30, y: 40 }, dragging: false }],
      [{ type: 'dimensions', id: 'a', dimensions: { width: 50, height: 60 }, setAttributes: true, resizing: false }],
    ]) {
      expected = upstream.applyNodeChanges(changes, expected);
      store.getState().triggerNodeChanges(changes);
      const stored = store.getState().nodes[0];
      for (const node of [stored, flow.getNode('a'), flow.getNodes()[0], flow.getInternalNode('a').internals.userNode]) {
        assert.deepEqual(node, expected[0]);
        assert.deepEqual(Reflect.ownKeys(node), Reflect.ownKeys(expected[0]));
        assert.equal(node.custom, original.custom);
      }
    }
    const stored = store.getState().nodes[0];
    const deleted = await flow.deleteElements({ nodes: [{ id: 'a' }] });
    assert.equal(callbacks.length, 1);
    assert.equal(callbacks[0][0], stored);
    assert.equal(deleted.deletedNodes[0], stored);
    assert.deepEqual(callbacks[0], expected);
    assert.deepEqual(flow.getNodes(), []);
  }
});
