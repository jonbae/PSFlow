import assert from 'node:assert/strict';
import test from 'node:test';
import { isEdge as upstream } from '../../oracle/index.js';
import { isEdge as psflow } from '../../index.js';

const observe = (fn, value) => {
  try { return { value: fn(value) }; }
  catch (error) { return { error: { name: error.name, message: error.message } }; }
};

test('isEdge preserves upstream native errors for primitive inputs', () => {
  for (const value of [null, undefined, 0, false, '', 'edge', 0n, Symbol('edge')]) {
    assert.deepEqual(observe(psflow, value), observe(upstream, value));
  }
});

test('isEdge checks key presence across inherited fields and function objects', () => {
  const fn = Object.assign(() => {}, { id: undefined, source: null, target: undefined });
  for (const value of [{}, { id: 'a' }, { id: 'a', source: 'b' },
    { id: undefined, source: undefined, target: undefined },
    Object.create({ id: 'a', source: 'b', target: 'c' }), fn,
    { id: 'a', source: 'b', target: 'c', position: {} }]) assert.equal(psflow(value), upstream(value));
  assert.equal(psflow.length, upstream.length);
});

test('isEdge preserves short-circuit presence-check order without reading values', () => {
  const receipt = (fn, keys) => {
    const seen = [];
    const value = new Proxy({}, {
      has(_, key) { seen.push(key); return keys.includes(key); },
      get() { throw new Error('guards only check key presence'); },
    });
    return { value: fn(value), seen };
  };
  for (const keys of [[], ['id'], ['id', 'source'], ['id', 'source', 'target'], ['id', 'target']]) {
    assert.deepEqual(receipt(psflow, keys), receipt(upstream, keys));
  }
});
