import assert from 'node:assert/strict';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';
import { reconnectEdge as upstream } from '../../oracle/index.js';
import { reconnectEdge as psflow } from '../../index.js';

test('reconnectEdge accepts JS arguments, preserves untouched references and consumer keys on the replacement', () => {
  const marker = Symbol('consumer');
  const old = { id: 'old', source: 'a', target: 'b', label: 'kept', optional: undefined, [marker]: 'kept' };
  const untouched = { id: 'other', source: 'b', target: 'c', custom: {} };
  const connection = { source: 'c', target: 'd', sourceHandle: null, targetHandle: undefined };
  const edges = [old, untouched];
  const expected = upstream(old, connection, edges);
  const actual = psflow(old, connection, edges);
  assert.ok(Array.isArray(actual), 'one JS call returns the edge array');
  assert.equal(psflow.length, upstream.length);
  assert.deepEqual(actual, expected);
  assert.equal(actual[0], untouched);
  assert.notEqual(actual[1], old);
  assert.deepEqual(Reflect.ownKeys(actual[1]), Reflect.ownKeys(expected[1]));
});

const old = { id: 'old', source: 'a', target: 'b', sourceHandle: 'before', label: 'kept', optional: undefined };
const untouched = { id: 'other', source: 'b', target: 'c' };
const connection = { source: 'c', target: 'd' };
for (const [name, options] of [
  ['omitted', undefined], ['empty options', {}], ['replace true', { shouldReplaceId: true }],
  ['replace false', { shouldReplaceId: false }], ['replace undefined', { shouldReplaceId: undefined }],
  ['replace null', { shouldReplaceId: null }], ['custom generator', { shouldReplaceId: true, getEdgeId: c => `custom-${c.source}` }],
]) {
  test(`reconnectEdge matches option/default behavior: ${name}`, () => {
    const edges = [old, untouched];
    const args = [old, connection, edges];
    if (name !== 'omitted') args.push(options);
    const expected = upstream(...args);
    const actual = psflow(...args);
    assert.deepEqual(actual, expected);
    assert.equal(actual[0], untouched);
    assert.notEqual(actual, edges);
    assert.deepEqual(Reflect.ownKeys(actual.at(-1)), Reflect.ownKeys(expected.at(-1)));
  });
}

test('reconnectEdge preserves null/undefined/empty handles and writes missing handles as own keys', () => {
  for (const sourceHandle of [undefined, null, '', 'source']) {
    for (const targetHandle of [undefined, null, '', 'target']) {
      const next = { ...connection, sourceHandle, targetHandle };
      const expected = upstream(old, next, [old]);
      const actual = psflow(old, next, [old]);
      assert.deepEqual(actual, expected);
      assert.ok(Object.hasOwn(actual[0], 'sourceHandle'));
      assert.ok(Object.hasOwn(actual[0], 'targetHandle'));
    }
  }
  assert.deepEqual(psflow(old, connection, [old]), upstream(old, connection, [old]));
});

test('reconnectEdge removes every matching id, preserves other order and copies the supplied old edge', () => {
  const first = { ...old, label: 'array-first' };
  const duplicate = { ...old, label: 'array-second' };
  const last = { id: 'last', source: 'x', target: 'y' };
  const edges = [untouched, first, duplicate, last];
  const expected = upstream(old, connection, edges);
  const actual = psflow(old, connection, edges);
  assert.deepEqual(actual, expected);
  assert.equal(actual[0], untouched);
  assert.equal(actual[1], last);
});

test('reconnectEdge gives the generator the original connection and reads mutations afterward', () => {
  const run = fn => {
    const next = { ...connection, custom: 'original' };
    const seen = [];
    const result = fn(old, next, [old, untouched], {
      shouldReplaceId: true,
      getEdgeId: function (value) {
        seen.push(value === next, this === undefined, value.custom);
        value.source = 'mutated';
        return 'generated';
      },
    });
    return { result, seen };
  };
  assert.deepEqual(run(psflow), run(upstream));
});

test('reconnectEdge keeps the exact input array and reports the right callback on both error branches', () => {
  for (const [candidate, next, edges] of [
    [old, { source: '', target: 'd' }, [old, untouched]],
    [old, { source: 'c', target: '' }, [old, untouched]],
    [old, connection, [untouched]],
  ]) {
    const run = fn => {
      const events = [];
      const options = {
        flag: 'copied', shouldReplaceId: true,
        getEdgeId() { throw new Error('must not generate on error'); },
        onError: function (code, message) {
          events.push({ code, message, receiverIsCopy: this !== options, flag: this.flag, sameCallback: this.onError === options.onError });
        },
      };
      const result = fn(candidate, next, edges, options);
      assert.equal(result, edges);
      return events;
    };
    assert.deepEqual(run(psflow), run(upstream));
  }
});

test('reconnectEdge preserves getter, find, generator and replacement-read order', () => {
  const run = fn => {
    const events = [];
    const read = (object, name, value) => Object.defineProperty(object, name, { enumerable: true, get() { events.push(name); return value; } });
    const backing = read({ source: 'a', target: 'b' }, 'id', 'old');
    read(backing, 'custom', 'kept');
    // Native rest can read the excluded getter twice on an object's cold
    // fast-copy path, even between two upstream calls. A proxy-backed input
    // gives both sides the same reproducible property-access experiment.
    const original = new Proxy(backing, {});
    const next = {};
    for (const [key, value] of Object.entries({ source: 'c', target: 'd', sourceHandle: null, targetHandle: null })) read(next, key, value);
    const options = {};
    read(options, 'shouldReplaceId', true);
    read(options, 'getEdgeId', value => { events.push(value === next ? 'generate-original' : 'generate-copy'); return 'generated'; });
    read(options, 'onError', () => {});
    const result = fn(original, next, [original, untouched], options);
    return { result, events };
  };
  const expected = run(upstream);
  assert.deepEqual(run(upstream), expected, 'the reference getter receipt must reproduce');
  assert.deepEqual(run(psflow), expected);
});

test('reconnectEdge copies enumerable own keys safely and leaves frozen inputs untouched', () => {
  const marker = Symbol('consumer');
  const original = Object.assign(Object.create({ inherited: 'excluded' }), old, { [marker]: 'kept' });
  Object.defineProperty(original, '__proto__', { enumerable: true, value: { consumer: 'kept' } });
  Object.defineProperty(original, 'nonEnumerable', { value: 'excluded' });
  Object.freeze(original);
  const edges = Object.freeze([original, Object.freeze({ ...untouched })]);
  const next = Object.freeze({ ...connection });
  const options = Object.freeze({ shouldReplaceId: true });
  const expected = upstream(original, next, edges, options);
  const actual = psflow(original, next, edges, options);
  assert.deepEqual(actual, expected);
  assert.deepEqual(Reflect.ownKeys(actual[1]), Reflect.ownKeys(expected[1]));
  assert.equal(Object.getPrototypeOf(actual[1]), Object.getPrototypeOf(expected[1]));
  assert.equal(actual[0], edges[1]);
});

const observe = (fn, args) => {
  const messages = [];
  const warn = console.warn;
  console.warn = (...args) => messages.push(args);
  try { return { value: fn(...args), messages }; }
  catch (error) { return { error: { name: error.name, message: error.message }, messages }; }
  finally { console.warn = warn; }
};

test('reconnectEdge propagates callback exceptions and null-option errors', () => {
  for (const options of [null, { onError() { throw new Error('consumer error'); } }]) {
    const args = [old, { source: '', target: 'd' }, [old], options];
    assert.deepEqual(observe(psflow, args), observe(upstream, args));
  }
});

test('reconnectEdge matches React-layer default development warnings', async () => {
  const result = await build({
    stdin: { contents: 'export { reconnectEdge } from "./xyflow/packages/react/src/utils/edges.ts";', resolveDir: fileURLToPath(new URL('../../', import.meta.url)), loader: 'ts' },
    bundle: true, format: 'esm', platform: 'neutral', write: false,
    alias: { '@xyflow/system': fileURLToPath(new URL('../../xyflow/packages/system/src/index.ts', import.meta.url)) },
    define: { 'process.env.NODE_ENV': '"development"' }, logLevel: 'silent',
  });
  const { reconnectEdge: developmentUpstream } = await import(`data:text/javascript;base64,${Buffer.from(result.outputFiles[0].text).toString('base64')}`);
  const previous = process.env.NODE_ENV;
  process.env.NODE_ENV = 'development';
  try {
    for (const args of [[old, { source: '', target: 'd' }, [old]], [old, connection, []], [old, connection, [], { onError: null }]]) {
      assert.deepEqual(observe(psflow, args), observe(developmentUpstream, args));
    }
  } finally {
    if (previous === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = previous;
  }
});
