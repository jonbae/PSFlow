// JS-entry witnesses for the full Node | InternalNode | id input contract.
import assert from 'node:assert/strict';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';
import { getNodesBounds as upstream } from '../../oracle/index.js';
import { getNodesBounds as psflow } from '../../index.js';

test('getNodesBounds returns a rect from one JS call with omitted options', () => {
  const nodes = [
    { id: 'a', position: { x: -20, y: 30 }, data: {}, width: 50, height: 25 },
    { id: 'b', position: { x: 100, y: -10 }, data: {}, width: 20, height: 40 },
  ];
  assert.deepEqual(psflow(nodes), upstream(nodes));
  assert.equal(psflow.length, upstream.length);
});

test('getNodesBounds resolves ids and plain nodes through the lookup, keeps internal inputs, and includes a zero box for misses', () => {
  const internal = (id, x, y) => ({
    id, position: { x: -999, y: -999 }, data: {}, measured: { width: 20, height: 10 },
    internals: { positionAbsolute: { x, y } },
  });
  const a = internal('a', 100, 200);
  const b = internal('b', 150, 300);
  const own = internal('own', 250, 400);
  const nodes = ['a', { id: 'b', position: { x: 900, y: 900 }, data: {}, width: 5, height: 5 }, own, 'missing'];
  const lookup = new Map([['a', a], ['b', b], ['own', internal('own', 9999, 9999)]]);
  const calls = [];
  const nodeLookup = { get(id) { calls.push(id); return lookup.get(id); } };
  const params = { nodeLookup, nodeOrigin: [0.5, 0.5] };
  const expected = upstream(nodes, params);
  const expectedCalls = calls.splice(0);
  assert.deepEqual(psflow(nodes, params), expected);
  assert.deepEqual(calls, expectedCalls);
});

test('getNodesBounds propagates NaN through every box merge in either input order', () => {
  const normal = { id: 'normal', position: { x: 10, y: 20 }, width: 30, height: 40 };
  for (const invalid of [
    { ...normal, id: 'nan-x', position: { x: NaN, y: 20 } },
    { ...normal, id: 'nan-y', position: { x: 10, y: NaN } },
    { ...normal, id: 'nan-width', width: NaN },
    { ...normal, id: 'nan-height', height: NaN },
  ]) {
    for (const nodes of [[invalid, normal], [normal, invalid]]) {
      assert.deepEqual(psflow(nodes), upstream(nodes));
    }
  }
});

const basic = { id: 'a', position: { x: 50, y: 80 }, width: 40, height: 20 };
const internal = { ...basic, internals: { positionAbsolute: { x: 150, y: 180 } } };
const cases = [
  ['empty nodes', [[]]],
  ['explicit undefined options', [[basic], undefined]],
  ['empty options', [[basic], {}]],
  ['ids without a lookup contribute zero boxes', [['a', 'missing']]],
  ['global origin', [[basic], { nodeOrigin: [0.5, 1] }]],
  ['own origin overrides global origin', [[{ ...basic, origin: [1, 0] }, basic], { nodeOrigin: [0.5, 1] }]],
  ['partial measured dimensions and independent fallbacks', [[
    { ...basic, measured: { width: 0 }, initialWidth: 999, height: undefined, initialHeight: 35 },
    { id: 'b', position: { x: -20, y: -40 }, measured: { height: 12 }, initialWidth: 25 },
  ]]],
  ['missing dimensions default to zero', [[{ id: 'a', position: { x: 1, y: 2 } }]]],
  ['internal nodes use absolute positions and ignore origins', [[{ ...internal, origin: [1, 1] }], { nodeOrigin: [0.5, 0.5] }]],
  ['lookup miss for a plain node contributes zero instead of falling back', [[basic, internal], { nodeLookup: new Map() }]],
  ['nullish measured fields fall back independently', [[{ ...basic, measured: { width: null, height: undefined }, width: null, initialWidth: 10 }]]],
];
for (const [name, args] of cases) {
  test(`getNodesBounds matches upstream: ${name}`, () => {
    assert.deepEqual(psflow(...args), upstream(...args));
    assert.notEqual(psflow(...args), psflow(...args), 'the result rect is fresh');
  });
}

test('getNodesBounds matches signed zero, infinities and negative dimensions', () => {
  for (const x of [0, -0, Infinity, -Infinity]) {
    for (const width of [0, -0, 10, -10, Infinity]) {
      const a = { ...internal, width, measured: undefined, internals: { positionAbsolute: { x, y: -0 } } };
      const b = { ...internal, width: 0, internals: { positionAbsolute: { x: -0, y: 0 } } };
      for (const nodes of [[a], [a, b], [b, a]]) assert.deepEqual(psflow(nodes), upstream(nodes));
    }
  }
});

test('getNodesBounds reads only used geometry fields and short-circuits dimension fallbacks', () => {
  const nodes = [{
    ...basic, measured: { width: 30, height: 20 },
    get width() { throw new Error('measured width wins'); },
    get height() { throw new Error('measured height wins'); },
    get sourcePosition() { throw new Error('unrelated node prop'); },
    get data() { throw new Error('unrelated consumer data'); },
  }];
  assert.deepEqual(psflow(nodes), upstream(nodes));
});

test('getNodesBounds leaves frozen nodes, options and lookup entries unchanged', () => {
  const frozen = Object.freeze({ ...internal, position: Object.freeze(internal.position), internals: Object.freeze(internal.internals) });
  const nodes = Object.freeze(['a', frozen]);
  const nodeLookup = new Map([['a', frozen]]);
  const params = Object.freeze({ nodeLookup, nodeOrigin: Object.freeze([0.5, 0.5]) });
  assert.deepEqual(psflow(nodes, params), upstream(nodes, params));
  assert.equal(nodeLookup.get('a'), frozen);
});

const observe = (fn, args) => {
  const messages = [];
  const warn = console.warn;
  console.warn = (...args) => messages.push(args);
  try { return { value: fn(...args), messages }; }
  catch (error) { return { error: { name: error.name, message: error.message }, messages }; }
  finally { console.warn = warn; }
};

test('getNodesBounds matches malformed-option error and empty-input timing', () => {
  for (const args of [[[], null], [[basic], null], [[basic], { nodeOrigin: null }], [[{ ...basic, origin: [0, 0] }], { nodeOrigin: null }]]) {
    assert.deepEqual(observe(psflow, args), observe(upstream, args));
  }
});

test('getNodesBounds matches the vendored development warning before the empty-input return', async () => {
  // The shared oracle is intentionally production-only. Build just this
  // vendored export in memory to observe its development branch independently.
  const result = await build({
    stdin: { contents: 'export { getNodesBounds } from "./xyflow/packages/system/src/utils/graph.ts";', resolveDir: fileURLToPath(new URL('../../', import.meta.url)), loader: 'ts' },
    bundle: true, format: 'esm', platform: 'neutral', write: false,
    define: { 'process.env.NODE_ENV': '"development"' }, logLevel: 'silent',
  });
  const { getNodesBounds: developmentUpstream } = await import(`data:text/javascript;base64,${Buffer.from(result.outputFiles[0].text).toString('base64')}`);
  const previous = process.env.NODE_ENV;
  process.env.NODE_ENV = 'development';
  try {
    for (const args of [[[]], [[basic]], [[basic], { nodeLookup: new Map() }], [[], null]]) {
      assert.deepEqual(observe(psflow, args), observe(developmentUpstream, args));
    }
  } finally {
    if (previous === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = previous;
  }
});
