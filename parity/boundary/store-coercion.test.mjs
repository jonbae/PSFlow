// Unusual store writes, entered from JavaScript, against upstream: a number
// member that is `NaN`, `undefined` or a string, and a callback that is a
// falsy value other than `null` or `undefined`.
//
// Upstream's store is a plain object, so it holds each value as written and
// its internals use it with JavaScript's own operators: `Math.min` and
// `Math.max` coerce and propagate `NaN`, `cb?.()` calls any value that is not
// `null` or `undefined` and throws for one that is not a function, and
// `if (cb)` skips a falsy one. Each check compares the value stored and what
// the store goes on to do with it, error included. The first half runs in a
// server render and drives the store directly; the second mounts each flow
// in a browser, through `browser/harness.mjs`, for the uses that run after
// mount. `store-coercion.cases.mjs` says what each of those writes and drives.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';
import { open } from './browser/harness.mjs';
import cases from './store-coercion.cases.mjs';
import { serializeValue } from '../system/harness/serialize.mjs';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const sides = [
  ['upstream', upstream],
  ['psflow', psflow],
];

const graph = () => ({
  nodes: [
    { id: 'a', position: { x: 0, y: 0 }, data: { label: 'a' }, measured: { width: 40, height: 20 } },
    { id: 'b', position: { x: 100, y: 60 }, data: { label: 'b' }, measured: { width: 40, height: 20 } },
  ],
  edges: [{ id: 'ab', source: 'a', target: 'b' }],
});

function mount(library) {
  const flow = {};
  function Probe() {
    flow.api = library.useStoreApi();
    flow.instance = library.useReactFlow();
    return null;
  }
  const { nodes, edges } = graph();
  renderToStaticMarkup(createElement(library.ReactFlow, { nodes, edges, children: createElement(Probe) }));
  return flow;
}

const bothAsync = async (run) => {
  const [up, ps] = await Promise.all(sides.map(([, library]) => run(library)));
  return { up, ps };
};

const recorder = (calls) => ({
  update: () => {},
  destroy: () => {},
  getViewport: () => ({ x: 0, y: 0, zoom: 1 }),
  setViewport: (viewport) => (calls.push(['setViewport', viewport]), Promise.resolve(undefined)),
  setViewportConstrained: (viewport, extent, translateExtent) => (
    calls.push(['setViewportConstrained', viewport, extent, translateExtent]), Promise.resolve(undefined)
  ),
  scaleTo: () => Promise.resolve(true),
  scaleBy: () => Promise.resolve(true),
  setScaleExtent: (extent) => calls.push(['setScaleExtent', extent]),
  setTranslateExtent: () => {},
  syncViewport: () => {},
  setClickDistance: () => {},
});

// How a call settled: its value, or the kind of error it threw or rejected
// with. Error messages name upstream's minified variables, so only the kind
// is compared.
const outcome = async (run) => {
  try {
    return ['returned', serializeValue(await run())];
  } catch (error) {
    return ['threw', error?.constructor?.name ?? typeof error];
  }
};

const unusual = [
  ['NaN', NaN],
  ['undefined', undefined],
  ['null', null],
  ['a numeric string', '0.75'],
  ['a string', 'small'],
];

// ── Numbers outside their type ─────────────────────────────────────────

for (const [label, value] of unusual) {
  test(`a fit with a minZoom of ${label} sets the viewport upstream sets`, async () => {
    const { up, ps } = await bothAsync(async (library) => {
      const { api } = mount(library);
      const calls = [];
      api.setState({ panZoom: recorder(calls), width: 400, height: 200, fitViewQueued: true, minZoom: value, maxZoom: 2 });
      api.getState().setNodes(graph().nodes);
      await new Promise((resolve) => setTimeout(resolve, 5));
      return { calls: serializeValue(calls), stored: serializeValue(api.getState().minZoom) };
    });
    assert.deepEqual(ps, up);
  });

  test(`a fit with a maxZoom of ${label} and a fit option of 4 sets the viewport upstream sets`, async () => {
    const { up, ps } = await bothAsync(async (library) => {
      const { api } = mount(library);
      const calls = [];
      api.setState({
        panZoom: recorder(calls),
        width: 400,
        height: 200,
        fitViewQueued: true,
        fitViewOptions: { minZoom: 4 },
        maxZoom: value,
      });
      api.getState().setNodes(graph().nodes);
      await new Promise((resolve) => setTimeout(resolve, 5));
      return serializeValue(calls);
    });
    assert.deepEqual(ps, up);
  });

  test(`setCenter and panBy with a width of ${label} call the instance as upstream does`, async () => {
    const { up, ps } = await bothAsync(async (library) => {
      const { api } = mount(library);
      const calls = [];
      api.setState({ panZoom: recorder(calls), width: value, height: 200, maxZoom: value });
      const results = [
        await outcome(() => api.getState().setCenter(10, 20)),
        await outcome(() => api.getState().panBy({ x: 5, y: value })),
      ];
      return { results, calls: serializeValue(calls) };
    });
    assert.deepEqual(ps, up);
  });

  test(`setMinZoom with a maxZoom of ${label} passes upstream's extent on`, async () => {
    const { up, ps } = await bothAsync(async (library) => {
      const { api } = mount(library);
      const calls = [];
      api.setState({ panZoom: recorder(calls), maxZoom: value });
      api.getState().setMinZoom(0.25);
      return serializeValue(calls);
    });
    assert.deepEqual(ps, up);
  });
}

// ── Falsy callbacks ────────────────────────────────────────────────────

// `getElementsToRemove` asks `onBeforeDelete` only when it is truthy.
for (const [label, value] of [
  ['0', 0],
  ['false', false],
  ['an empty string', ''],
  ['NaN', NaN],
]) {
  test(`deleteElements with onBeforeDelete set to ${label} deletes as upstream does`, async () => {
    const { up, ps } = await bothAsync(async (library) => {
      const { api, instance } = mount(library);
      const calls = [];
      api.setState({ onBeforeDelete: value, onNodesDelete: (nodes) => calls.push(nodes.map((n) => n.id)) });
      const result = await outcome(() => instance.deleteElements({ nodes: [{ id: 'a' }] }));
      return { result, calls, stored: serializeValue(api.getState().onBeforeDelete) };
    });
    assert.deepEqual(ps, up);
  });
}

// `onNodesDelete?.(…)`, `onDelete?.(…)` and `onNodesChange?.(…)` call any
// value that is not `null` or `undefined`, so a falsy one throws.
for (const member of ['onNodesDelete', 'onDelete', 'onEdgesDelete']) {
  test(`deleteElements with ${member} set to false fails where upstream fails`, async () => {
    const { up, ps } = await bothAsync(async (library) => {
      const { api, instance } = mount(library);
      const calls = [];
      api.setState({ [member]: false, onNodesChange: (changes) => calls.push(changes.map((c) => [c.type, c.id])) });
      const result = await outcome(() => instance.deleteElements({ nodes: [{ id: 'a' }] }));
      return { result, calls };
    });
    assert.deepEqual(ps, up);
  });
}

test('triggerNodeChanges with onNodesChange set to 0 fails where upstream fails', async () => {
  const { up, ps } = await bothAsync(async (library) => {
    const { api } = mount(library);
    api.setState({ onNodesChange: 0 });
    return outcome(() => api.getState().triggerNodeChanges([{ type: 'select', id: 'a', selected: true }]));
  });
  assert.deepEqual(ps, up);
});

// ── After mount, in a browser ──────────────────────────────────────────

const casesFile = fileURLToPath(new URL('./store-coercion.cases.mjs', import.meta.url));
const falsification = 'falsification: the sides write different values';
let harness;

before(async () => {
  harness = await open(casesFile);
});
after(() => harness?.close());

test('the page runs every case in the table', () => {
  assert.deepEqual(harness.names, cases.map((c) => c.name));
  assert.equal(new Set(harness.names).size, harness.names.length, 'two cases share a name');
});

test('a case whose sides write different values differs', async () => {
  const { upstream: up, psflow: ps } = await harness.run(falsification);
  assert.notDeepEqual(ps, up);
});

for (const { name } of cases) {
  if (name === falsification) continue;
  test(name, async () => {
    const { upstream: up, psflow: ps } = await harness.run(name);
    assert.ok(up.state !== null, 'upstream did not mount');
    assert.deepEqual(ps, up);
  });
}
