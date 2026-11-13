import assert from 'node:assert/strict';
import test from 'node:test';
import { isNode as upstream } from '../../oracle/index.js';
import { isNode as psflow } from '../../index.js';

const observe = (fn, value) => {
  try { return { value: fn(value) }; }
  catch (error) { return { error: { name: error.name, message: error.message } }; }
};

test('isNode preserves upstream native errors for primitive inputs', () => {
  for (const value of [null, undefined, 0, false, '', 'node', 0n, Symbol('node')]) {
    assert.deepEqual(observe(psflow, value), observe(upstream, value));
  }
});

test('isNode uses presence across inherited keys and function objects', () => {
  const fn = Object.assign(() => {}, { id: undefined, position: null });
  for (const value of [{}, { id: '' }, { id: undefined, position: undefined },
    Object.create({ id: 'inherited', position: null }), fn,
    { id: 'a', position: {}, source: undefined }, { id: 'a', position: {}, target: undefined }]) {
    assert.equal(psflow(value), upstream(value));
  }
  assert.equal(psflow.length, upstream.length);
});

test('isNode preserves short-circuit presence-check order without reading values', () => {
  const receipt = (fn, keys) => {
    const seen = [];
    const value = new Proxy({}, {
      has(_, key) { seen.push(key); return keys.includes(key); },
      get() { throw new Error('guards only check key presence'); },
    });
    return { value: fn(value), seen };
  };
  for (const keys of [[], ['id'], ['id', 'position'], ['id', 'position', 'source'], ['id', 'position', 'target']]) {
    assert.deepEqual(receipt(psflow, keys), receipt(upstream, keys));
  }
});
