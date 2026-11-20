// Upstream is the oracle here: `EdgeWrapper` renders `{ ...defaultEdgeOptions,
// ...edge }`, and `Handle`'s `onConnectExtended` hands `onConnect` the
// connection spread over the options and adds `addEdge` of that to an
// uncontrolled flow. These build both sides' answers from the same objects.
import assert from 'node:assert/strict';
import { addEdge } from '@xyflow/react';

const attrs = { 'data-kind': 'x' };
const labelStyle = { fill: 'red' };

// Every one of the 23 members, as a default.
export const allDefaults = {
  type: 'smoothstep',
  animated: true,
  hidden: false,
  deletable: false,
  selectable: false,
  data: { from: 'defaults' },
  markerStart: 'arrow',
  markerEnd: { type: 'arrowclosed', color: 'red' },
  zIndex: 3,
  ariaLabel: 'default label',
  interactionWidth: 7,
  label: 'D',
  labelStyle,
  labelShowBg: false,
  labelBgStyle: { fill: 'blue' },
  labelBgPadding: [1, 2],
  labelBgBorderRadius: 5,
  style: { stroke: 'green' },
  className: 'dflt',
  reconnectable: 'target',
  focusable: false,
  ariaRole: 'note',
  domAttributes: attrs,
};

const base = { id: 'e', source: 'a', target: 'b' };

export const cases = [
  [allDefaults, base],
  // The edge's own values win, `false` included.
  [allDefaults, { ...base, type: 'step', animated: false, focusable: true, reconnectable: false, label: 'own', ariaRole: 'img' }],
  // An edge that owns a key holding `undefined` keeps it undefined.
  [allDefaults, { ...base, type: undefined, label: undefined, className: undefined, domAttributes: undefined, reconnectable: undefined }],
  // Absent options merge nothing.
  [{}, { ...base, labelStyle }],
  [{ reconnectable: false, focusable: true }, base],
  [{ reconnectable: true }, { ...base, reconnectable: 'source' }],
];

// Compared member by member over both objects' keys. A key holding
// `undefined` on one side reads the same as no key on the other: the
// renderer reads values, and ps-flow's records hold no `undefined`.
export const checkMerge = (merge) => () => {
  cases.forEach(([defaults, edge], i) => {
    const expected = { ...defaults, ...edge };
    const actual = merge(defaults)(edge);
    for (const key of new Set([...Object.keys(expected), ...Object.keys(actual)])) {
      assert.deepEqual(actual[key], expected[key], `case ${i}: \`${key}\``);
    }
  });
};

export const connection = { source: 'a', target: 'b', sourceHandle: null, targetHandle: null };

const token = Symbol('custom default');
const arbitraryDefaults = {
  ...allDefaults,
  source: 'default-source-node',
  target: 'default-target-node',
  pathOptions: { curvature: 0.9, custom: 'path' },
  selected: true,
  sourceHandle: 'default-source',
  targetHandle: 'default-target',
  custom: { retained: true },
  ownUndefined: undefined,
  [token]: { retained: 'symbol' },
};

export const checkArbitraryMerge = (merge) => () => {
  for (const edge of [
    base,
    { ...base, selected: false, pathOptions: { offset: 42 }, custom: null, [token]: false },
    { ...base, selected: undefined, pathOptions: undefined, sourceHandle: undefined, targetHandle: null, custom: undefined, [token]: undefined },
  ]) {
    const expected = { ...arbitraryDefaults, ...edge };
    const { rendered, original } = merge(arbitraryDefaults)(edge);
    assert.deepEqual(original, expected, 'all enumerable string and symbol keys survive the spread');
    for (const key of ['selected', 'sourceHandle', 'targetHandle', 'pathOptions']) {
      const value = expected[key];
      assert.deepEqual(rendered[key], value ?? undefined, `rendered default: ${key}`);
    }
    assert.equal(rendered.pathOptions, expected.pathOptions);
    assert.equal(original.custom, expected.custom);
    assert.equal(original[token], expected[token]);
  }
};

export const checkConnect = (connect) => () => {
  for (const defaults of [undefined, allDefaults, arbitraryDefaults, { ...arbitraryDefaults, id: 'custom-id' }, { animated: true, type: 'step' }]) {
    const { params, edges } = connect(defaults ?? null)();
    const expectedParams = { ...defaults, ...connection };
    assert.equal(params.length, 1);
    assert.deepEqual(params[0], expectedParams);
    const [expectedEdge] = addEdge(expectedParams, []);
    assert.equal(edges.length, 1);
    assert.deepEqual(edges[0], expectedEdge, 'uncontrolled edges preserve every default key');
    for (const key of new Set([...Object.keys(expectedEdge), ...Object.keys(edges[0])])) {
      assert.deepEqual(edges[0][key], expectedEdge[key], `added edge: \`${key}\``);
    }
  }
};
