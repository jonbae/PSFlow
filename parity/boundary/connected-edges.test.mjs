// Exercise the JS entry: the existing Graph properties call below the boundary
// and cannot detect a curried function or reconstruction of consumer objects.
import assert from 'node:assert/strict';
import test from 'node:test';
import { getConnectedEdges as upstream } from '../../oracle/index.js';
import { getConnectedEdges as psflow } from '../../index.js';

test('getConnectedEdges accepts both arrays and returns the consumer edges', () => {
  const nodes = [{ id: 'a', position: { x: 0, y: 0 }, data: {} }];
  const edges = [
    { id: 'out', source: 'a', target: 'b', custom: { label: 'consumer' }, optional: undefined },
    { id: 'unrelated', source: 'b', target: 'c' },
    { id: 'in', source: 'd', target: 'a' },
  ];
  const expected = upstream(nodes, edges);
  const actual = psflow(nodes, edges);
  assert.ok(Array.isArray(actual), 'a JS call returns an array, not the next curried function');
  assert.equal(psflow.length, upstream.length);
  assert.deepEqual(actual, expected);
  for (let index = 0; index < expected.length; index++) {
    assert.equal(actual[index], expected[index], 'the original consumer object survives');
  }
});

const node = id => ({ id, position: { x: 0, y: 0 }, data: {} });
const edge = (id, source, target) => ({ id, source, target });
const cases = [
  ['empty nodes', [], [edge('a-b', 'a', 'b')]],
  ['empty edges', [node('a')], []],
  ['both endpoints, self-loops and input order', [node('b'), node('a')], [
    edge('incoming', 'c', 'a'), edge('skip', 'c', 'd'), edge('loop', 'b', 'b'), edge('outgoing', 'a', 'd'),
  ]],
  ['duplicate node and edge ids', [node('a'), node('a')], [
    edge('same-id', 'a', 'b'), edge('same-id', 'c', 'a'), edge('skip', 'c', 'd'),
  ]],
  ['empty string ids', [node('')], [edge('in', 'a', ''), edge('out', '', 'b'), edge('skip', 'a', 'b')]],
];
for (const [name, nodes, edges] of cases) {
  test(`getConnectedEdges matches upstream: ${name}`, () => {
    const expected = upstream(nodes, edges);
    const actual = psflow(nodes, edges);
    assert.deepEqual(actual, expected);
    assert.notEqual(actual, edges, 'filter returns a fresh array');
    for (let index = 0; index < expected.length; index++) assert.equal(actual[index], expected[index]);
  });
}

test('getConnectedEdges preserves frozen consumer objects, symbols and present undefined', () => {
  const marker = Symbol('consumer');
  const original = Object.freeze({
    ...edge('a-b', 'a', 'b'), custom: Object.freeze({ label: 'kept' }), optional: undefined, [marker]: 'kept',
  });
  const nodes = Object.freeze([Object.freeze(node('a'))]);
  const edges = Object.freeze([original, original]);
  const expected = upstream(nodes, edges);
  const actual = psflow(nodes, edges);
  assert.deepEqual(actual, expected);
  assert.notEqual(actual, edges);
  assert.equal(actual[0], original);
  assert.equal(actual[1], original);
  assert.equal(actual[0][marker], 'kept');
  assert.ok(Object.hasOwn(actual[0], 'optional'));
});
