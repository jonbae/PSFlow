// Direct calls through the JS entry, compared with the rebuilt vendored source.
import assert from 'node:assert/strict';
import test from 'node:test';
import { getOutgoers as upstream } from '../../oracle/index.js';
import { getOutgoers as psflow } from '../../index.js';

const node = id => ({ id, position: { x: 0, y: 0 }, data: {} });
const edge = (id, source, target) => ({ id, source, target });

test('getOutgoers accepts three JS arguments and returns original nodes in node-array order', () => {
  const query = { id: 'a' };
  const nodes = [{ ...node('b'), custom: { label: 'kept' }, optional: undefined }, node('c'), node('a')];
  const edges = [edge('a-c', 'a', 'c'), edge('a-b', 'a', 'b'), edge('b-a', 'b', 'a')];
  const expected = upstream(query, nodes, edges);
  const actual = psflow(query, nodes, edges);
  assert.ok(Array.isArray(actual), 'a JS call returns an array, not the next curried function');
  assert.equal(psflow.length, upstream.length);
  assert.deepEqual(actual, expected);
  for (let index = 0; index < expected.length; index++) assert.equal(actual[index], expected[index]);
  assert.notEqual(actual, nodes);
});

test('getOutgoers returns early for empty or absent ids without reading the other arguments', () => {
  for (const query of [{ id: '' }, {}, { id: undefined }, { id: null }]) {
    assert.deepEqual(psflow(query, undefined, undefined), upstream(query, undefined, undefined));
    assert.notEqual(psflow(query, undefined, undefined), psflow(query, undefined, undefined));
  }
});

const cases = [
  ['empty nodes', { id: 'a' }, [], [edge('a-b', 'a', 'b')]],
  ['empty edges', { id: 'a' }, [node('b')], []],
  ['unmatched source', { id: 'a' }, [node('b')], [edge('c-b', 'c', 'b')]],
  ['incoming edges do not count', node('a'), [node('b')], [edge('b-a', 'b', 'a')]],
  ['duplicates and self-loops preserve node-array order', { id: 'a' }, [node('b'), node('c'), node('b'), node('a')], [
    edge('a-c', 'a', 'c'), edge('a-b', 'a', 'b'), edge('a-b-again', 'a', 'b'), edge('a-a', 'a', 'a'),
  ]],
  ['empty string target id', { id: 'a' }, [node(''), node('b')], [edge('a-empty', 'a', '')]],
];
for (const [name, query, nodes, edges] of cases) {
  test(`getOutgoers matches upstream: ${name}`, () => {
    const expected = upstream(query, nodes, edges);
    const actual = psflow(query, nodes, edges);
    assert.deepEqual(actual, expected);
    assert.notEqual(actual, nodes);
    for (let index = 0; index < expected.length; index++) assert.equal(actual[index], expected[index]);
  });
}

test('getOutgoers preserves frozen consumer nodes, custom keys, symbols and present undefined', () => {
  const marker = Symbol('consumer');
  const original = Object.freeze({ ...node('b'), custom: Object.freeze({ label: 'kept' }), optional: undefined, [marker]: 'kept' });
  const nodes = Object.freeze([original, original]);
  const edges = Object.freeze([Object.freeze(edge('a-b', 'a', 'b'))]);
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
