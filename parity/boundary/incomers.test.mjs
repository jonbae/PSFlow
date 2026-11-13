// Compare the actual JS entry with the rebuilt vendored oracle. The existing
// Graph properties call below this boundary and cannot detect a curried call.
import assert from 'node:assert/strict';
import test from 'node:test';
import { getIncomers as upstream } from '../../oracle/index.js';
import { getIncomers as psflow } from '../../index.js';

const node = id => ({ id, position: { x: 0, y: 0 }, data: {} });
const edge = (id, source, target) => ({ id, source, target });

test('getIncomers accepts all three JS arguments and returns original nodes in node-array order', () => {
  const query = { id: 'a' };
  const nodes = [{ ...node('b'), custom: { label: 'kept' }, optional: undefined }, node('c'), node('a')];
  const edges = [edge('c-a', 'c', 'a'), edge('b-a', 'b', 'a'), edge('a-b', 'a', 'b')];
  const expected = upstream(query, nodes, edges);
  const actual = psflow(query, nodes, edges);
  assert.ok(Array.isArray(actual), 'a JS call returns an array, not the next curried function');
  assert.equal(psflow.length, upstream.length);
  assert.deepEqual(actual, expected);
  for (let index = 0; index < expected.length; index++) assert.equal(actual[index], expected[index]);
  assert.notEqual(actual, nodes);
});

test('getIncomers returns early for empty or absent ids without reading the other arguments', () => {
  for (const query of [{ id: '' }, {}, { id: undefined }, { id: null }]) {
    // The oracle's guard returns before either array is touched.
    const expected = upstream(query, undefined, undefined);
    const actual = psflow(query, undefined, undefined);
    assert.deepEqual(actual, expected);
    assert.notEqual(actual, psflow(query, undefined, undefined), 'each result array is fresh');
  }
});

const cases = [
  ['empty nodes', { id: 'a' }, [], [edge('b-a', 'b', 'a')]],
  ['empty edges', { id: 'a' }, [node('b')], []],
  ['unmatched target', { id: 'a' }, [node('b')], [edge('b-c', 'b', 'c')]],
  ['outgoing edges do not count', node('a'), [node('b')], [edge('a-b', 'a', 'b')]],
  ['duplicates and self-loops preserve node-array order', { id: 'a' }, [node('b'), node('c'), node('b'), node('a')], [
    edge('c-a', 'c', 'a'), edge('b-a', 'b', 'a'), edge('b-a-again', 'b', 'a'), edge('a-a', 'a', 'a'),
  ]],
  ['empty string source id', { id: 'a' }, [node(''), node('b')], [edge('empty-a', '', 'a')]],
];
for (const [name, query, nodes, edges] of cases) {
  test(`getIncomers matches upstream: ${name}`, () => {
    const expected = upstream(query, nodes, edges);
    const actual = psflow(query, nodes, edges);
    assert.deepEqual(actual, expected);
    assert.notEqual(actual, nodes);
    for (let index = 0; index < expected.length; index++) assert.equal(actual[index], expected[index]);
  });
}

test('getIncomers preserves frozen consumer nodes, custom keys, symbols and present undefined', () => {
  const marker = Symbol('consumer');
  const original = Object.freeze({ ...node('b'), custom: Object.freeze({ label: 'kept' }), optional: undefined, [marker]: 'kept' });
  const nodes = Object.freeze([original, original]);
  const edges = Object.freeze([Object.freeze(edge('b-a', 'b', 'a'))]);
  const query = Object.freeze({ id: 'a' });
  const expected = upstream(query, nodes, edges);
  const actual = psflow(query, nodes, edges);
  assert.deepEqual(actual, expected);
  assert.notEqual(actual, nodes);
  assert.equal(actual[0], original);
  assert.equal(actual[1], original);
  assert.ok(Object.hasOwn(actual[0], 'optional'));
  assert.equal(actual[0][marker], 'kept');
});
