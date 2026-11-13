import assert from 'node:assert/strict';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';
import * as upstream from '../../oracle/index.js';
import * as psflow from '../../index.js';

test('addEdge matches React-layer development warnings and propagates consumer errors', async () => {
  const bundle = await build({
    stdin: { contents: 'export { addEdge } from "./xyflow/packages/react/src/utils/edges.ts";', resolveDir: fileURLToPath(new URL('../../', import.meta.url)), loader: 'ts' },
    bundle: true, format: 'esm', platform: 'neutral', write: false,
    alias: { '@xyflow/system': fileURLToPath(new URL('../../xyflow/packages/system/src/index.ts', import.meta.url)) },
    define: { 'process.env.NODE_ENV': '"development"' }, logLevel: 'silent',
  });
  const reference = await import(`data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].text).toString('base64')}`);
  const observe = (fn, options) => {
    const messages = [];
    const original = console.warn;
    console.warn = (...args) => messages.push(args);
    try { return { result: fn({ source: '', target: 'b' }, [], options), messages }; }
    catch (error) { return { error: { name: error.name, message: error.message }, messages }; }
    finally { console.warn = original; }
  };
  const previous = process.env.NODE_ENV;
  process.env.NODE_ENV = 'development';
  try {
    for (const options of [undefined, {}, { onError: null }, { onError() { throw new Error('consumer error'); } }]) {
      assert.deepEqual(observe(psflow.addEdge, options), observe(reference.addEdge, options));
    }
  } finally {
    if (previous === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = previous;
  }
});

test('addEdge copies the consumer edge/connection and retains untouched edges', () => {
  const symbol = Symbol('consumer');
  const untouched = Object.freeze({ id: 'other', source: 'x', target: 'y', custom: {} });
  for (const id of [[], [['id', 'given']], [['id', undefined]]]) {
    for (const sourceHandle of [undefined, null, '', 'source']) {
      const input = Object.freeze({ source: 'a', target: 'b', sourceHandle, targetHandle: null, custom: {}, optional: undefined, [symbol]: 1, ...Object.fromEntries(id) });
      const edges = Object.freeze([untouched]);
      const expected = upstream.addEdge(input, edges);
      const actual = psflow.addEdge(input, edges);
      assert.equal(psflow.addEdge.length, upstream.addEdge.length);
      assert.deepEqual(actual, expected);
      assert.equal(actual[0], untouched);
      assert.notEqual(actual[1], input);
      assert.equal(actual[1].custom, input.custom);
      assert.deepEqual(Reflect.ownKeys(actual[1]), Reflect.ownKeys(expected[1]));
    }
  }
});

test('addEdge uses the original array concat operation after validation', () => {
  const run = fn => {
    const edges = [];
    const events = [];
    edges.concat = function (value) {
      events.push(this === edges, value.custom);
      return ['consumer concat result'];
    };
    return { result: fn({ source: 'a', target: 'b', custom: 1 }, edges), events };
  };
  assert.deepEqual(run(psflow.addEdge), run(upstream.addEdge));
});

test('addEdge keeps duplicate/invalid arrays and calls options with upstream arguments and receiver', () => {
  const run = fn => {
    const events = [];
    const connection = { source: 'a', target: 'b', custom: 1 };
    const edges = [{ id: 'old', source: 'a', target: 'b', sourceHandle: null }];
    const options = {
      custom: 'options',
      getEdgeId: function (value) { events.push(['id', value === connection, this === undefined, value.custom]); return 'custom'; },
      onError: function (...args) { events.push(['error', this !== options, this.custom, ...args]); },
    };
    const duplicate = fn(connection, edges, options);
    const invalid = fn({ source: '', target: 'b' }, edges, options);
    const added = fn(connection, [], options);
    const complete = fn({ id: 'explicit', ...connection }, [], options);
    return { events, duplicate: duplicate === edges, invalid: invalid === edges, added, complete };
  };
  assert.deepEqual(run(psflow.addEdge), run(upstream.addEdge));
  for (const sourceHandle of [undefined, null, '', 'handle']) {
    for (const targetHandle of [undefined, null, '', 'handle']) {
      const edges = [{ id: 'old', source: 'a', target: 'b', sourceHandle, targetHandle }];
      const connection = { source: 'a', target: 'b', sourceHandle: null, targetHandle: undefined };
      const expected = upstream.addEdge(connection, edges);
      const actual = psflow.addEdge(connection, edges);
      assert.deepEqual(actual, expected);
      assert.equal(actual === edges, expected === edges);
    }
  }
  assert.throws(() => psflow.addEdge({ source: 'a', target: 'b' }, [], null), TypeError);
  assert.throws(() => upstream.addEdge({ source: 'a', target: 'b' }, [], null), TypeError);
});

test('consumer helpers preserve enumerable symbols and __proto__ without copying inherited/nonenumerable fields', () => {
  const symbol = Symbol('consumer');
  const input = Object.assign(Object.create({ inherited: 1 }), {
    id: 'a', source: 'a', target: 'b', position: { x: 0, y: 0 }, data: {}, optional: undefined, [symbol]: 3,
  });
  Object.defineProperty(input, '__proto__', { value: { consumer: 1 }, enumerable: true });
  Object.defineProperty(input, 'hiddenCustom', { value: 2 });
  for (const name of ['applyNodeChanges', 'applyEdgeChanges', 'addEdge']) {
    const args = name === 'addEdge' ? [input, []] : [[{ id: 'a', type: 'select', selected: true }], [input]];
    const expected = upstream[name](...args)[0];
    const actual = psflow[name](...args)[0];
    assert.deepEqual(actual, expected);
    assert.deepEqual(Reflect.ownKeys(actual), Reflect.ownKeys(expected));
    assert.equal(Object.getPrototypeOf(actual), Object.prototype);
    assert.ok(Object.hasOwn(actual, '__proto__'));
  }
});

test('consumer helpers preserve getter, generator and validation order', () => {
  const run = (implementation, name) => {
    const events = [];
    const observe = (tag, value) => new Proxy(value, {
      get(target, key, receiver) { events.push([tag, 'get', String(key)]); return Reflect.get(target, key, receiver); },
      ownKeys(target) { events.push([tag, 'keys']); return Reflect.ownKeys(target); },
      has(target, key) { events.push([tag, 'has', String(key)]); return Reflect.has(target, key); },
    });
    const input = observe('input', { id: 'a', source: 'a', target: 'b', position: { x: 0, y: 0 }, data: {}, custom: undefined });
    const changes = [observe('change', { type: 'dimensions', id: 'a', dimensions: observe('dimensions', { width: 40, height: 30 }), setAttributes: true, resizing: false })];
    const result = name === 'addEdge'
      ? implementation(input, [observe('existing', { id: 'other', source: 'a', target: 'c' })], observe('options', {}))
      : implementation(changes, [input]);
    // Materialize any retained proxy before comparing: assert.deepEqual itself
    // reads proxies, and must not append to the receipt it is checking.
    const values = result.map(value => ({ ...value }));
    return { result: values, events: events.slice() };
  };
  for (const name of ['applyNodeChanges', 'applyEdgeChanges', 'addEdge']) {
    const expected = run(upstream[name], name);
    assert.deepEqual(run(upstream[name], name), expected, 'oracle is self-consistent');
    assert.deepEqual(run(psflow[name], name), expected);
  }
});

for (const name of ['applyNodeChanges', 'applyEdgeChanges']) {
  test(`${name} retains untouched consumer references and keys`, () => {
    const symbol = Symbol('consumer');
    const element = { id: 'a', position: { x: 0, y: 0 }, data: {}, source: 'a', target: 'b', custom: {}, optional: undefined, [symbol]: 1 };
    const elements = Object.freeze([Object.freeze(element)]);
    const expected = upstream[name]([], elements);
    const actual = psflow[name]([], elements);
    assert.equal(psflow[name].length, upstream[name].length);
    assert.deepEqual(actual, expected);
    assert.notEqual(actual, elements);
    assert.equal(actual[0], element);
  });
}

test('applyNodeChanges preserves raw position, dimensions, attributes and resizing semantics', () => {
  const symbol = Symbol('dimensions');
  const dimensions = { width: 40, height: 30, custom: undefined, [symbol]: 'kept' };
  const node = Object.freeze({ id: 'a', position: { x: 0, y: 0 }, data: {}, measured: Object.freeze({ width: 10, height: 10, previous: true }) });
  for (const change of [
    { type: 'position' }, { type: 'position', position: undefined, dragging: undefined },
    { type: 'position', position: { x: 5, y: 10 }, dragging: true },
    { type: 'position', position: null, dragging: null },
    ...[undefined, false, true, 'width', 'height', 'other'].map(setAttributes => ({ type: 'dimensions', dimensions, setAttributes, resizing: true })),
    { type: 'dimensions', dimensions: null },
    ...[undefined, null, false, true, 1].map(resizing => ({ type: 'dimensions', resizing })),
  ]) {
    const changes = [{ id: 'a', ...change }];
    const actual = psflow.applyNodeChanges(changes, [node]);
    const expected = upstream.applyNodeChanges(changes, [node]);
    assert.deepEqual(actual, expected);
    assert.deepEqual(Reflect.ownKeys(actual[0]), Reflect.ownKeys(expected[0]));
    assert.equal(actual[0].position, expected[0].position);
    if (change.dimensions) {
      assert.notEqual(actual[0].measured, dimensions);
      assert.deepEqual(Reflect.ownKeys(actual[0].measured), Reflect.ownKeys(expected[0].measured));
    }
  }
});

for (const name of ['applyNodeChanges', 'applyEdgeChanges']) {
  test(`${name} shallow-copies touched/add/replace items and preserves change ordering`, () => {
    const symbol = Symbol('consumer');
    const original = { id: 'a', position: { x: 0, y: 0 }, data: {}, source: 'a', target: 'b', custom: {}, optional: undefined, [symbol]: 1 };
    const untouched = { ...original, id: 'untouched' };
    const replacement = { ...original, id: 'replacement', extra: undefined };
    const added = { ...original, id: 'added' };
    Object.defineProperty(original, 'nonEnumerable', { value: 1 });
    for (const changes of [
      [{ type: 'select', id: 'a', selected: true }],
      [{ type: 'select', id: 'a', selected: undefined }],
      [{ type: 'unknown', id: 'a' }],
      [{ type: 'select', id: 'a', selected: true }, { type: 'remove', id: 'a' }, { type: 'select', id: 'a', selected: false }],
      [{ type: 'remove', id: 'a' }, { type: 'replace', id: 'a', item: replacement }, { type: 'select', id: 'a', selected: true }],
      [{ type: 'replace', id: 'a', item: replacement }, { type: 'remove', id: 'a' }],
      [{ type: 'select', id: 'missing', selected: true }],
      ...[undefined, 0, 1, -1, -20, 2.5, NaN, Infinity].map(index => [
        { type: 'add', item: added, index }, { type: 'remove', id: 'a' }, { type: 'add', item: replacement, index: 0 },
      ]),
    ]) {
      const elements = Object.freeze([Object.freeze(original), Object.freeze(untouched)]);
      const expected = upstream[name](changes, elements);
      const actual = psflow[name](changes, elements);
      assert.deepEqual(actual, expected);
      for (let i = 0; i < expected.length; i++) {
        assert.deepEqual(Reflect.ownKeys(actual[i]), Reflect.ownKeys(expected[i]));
        if (expected[i] === original || expected[i] === untouched) assert.equal(actual[i], expected[i]);
        else assert.ok(![original, untouched, replacement, added].includes(actual[i]));
        assert.equal(actual[i].custom, expected[i].custom);
      }
    }
  });
}
