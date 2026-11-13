// Every callable export, entered from JavaScript with only what upstream's
// declarations require, against upstream.
//
// A TypeScript consumer may leave out anything its declaration marks optional.
// ps-flow publishes upstream's declarations (`distribution/README.md`), so
// whatever compiles against them has to run. This file reads the published
// `@xyflow/react` declarations with the TypeScript checker and derives, for
// each component, hook and function, the parameters and object members that
// are required. The tables below supply exactly those and nothing more: a
// table entry that supplies a member the declaration leaves optional, or omits
// one it requires, fails before anything is mounted.
//
// Each component then mounts where a consumer puts it: under `<ReactFlow />`,
// inside a custom node, inside a custom edge, or on its own. Each hook runs
// inside a custom node, which has both the store and a node id. Each function
// is called with the same arguments on both sides and must return the same
// value. The claim is acceptance, not rendering: what each component draws is
// the conformance suite's and the net's.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createRequire } from 'node:module';
import { isDeepStrictEqual } from 'node:util';
import ts from 'typescript';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const sides = [
  ['upstream', upstream],
  ['psflow', psflow],
];

// ── What the declarations require ──────────────────────────────────────

const require = createRequire(import.meta.url);
const declarations = require.resolve('@xyflow/react').replace(/umd[/\\]index\.js$/, 'esm/index.d.ts');

const program = ts.createProgram([declarations], {
  module: ts.ModuleKind.ESNext,
  moduleResolution: ts.ModuleResolutionKind.Bundler,
  target: ts.ScriptTarget.ESNext,
  jsx: ts.JsxEmit.ReactJSX,
  strict: true,
  noEmit: true,
  skipLibCheck: true,
  types: [],
});
const checker = program.getTypeChecker();
const entry = program.getSourceFile(declarations);
assert.ok(entry, `could not read ${declarations}`);

const optionalParameter = (parameter) => {
  const declaration = parameter.valueDeclaration;
  return Boolean(declaration && checker.isOptionalParameter(declaration));
};

// The members a value of this parameter's type must have. Only plain object
// types are read: `unknown`, a union, an array, a function or a primitive is
// supplied whole, so its members are not the table's to choose.
const requiredMembers = (parameter) => {
  const declaredType = checker.getTypeOfSymbolAtLocation(parameter, entry);
  if (declaredType.flags & (ts.TypeFlags.Unknown | ts.TypeFlags.Any)) return null;
  const type = checker.getNonNullableType(declaredType);
  if (type.isUnion() || checker.isArrayType(type) || type.getCallSignatures().length) return null;
  if (!(type.flags & ts.TypeFlags.Object) && !type.isIntersection()) return null;
  return checker
    .getPropertiesOfType(type)
    .filter((member) => !(member.flags & ts.SymbolFlags.Optional))
    .map((member) => member.name)
    .sort();
};

// One entry per callable value export: each call signature's required
// parameters, with the required members of each.
const declared = new Map();
for (const exported of checker.getExportsOfModule(checker.getSymbolAtLocation(entry))) {
  const symbol = exported.flags & ts.SymbolFlags.Alias ? checker.getAliasedSymbol(exported) : exported;
  if (!(symbol.flags & ts.SymbolFlags.Value)) continue;
  const signatures = checker.getTypeOfSymbolAtLocation(symbol, entry).getCallSignatures();
  if (!signatures.length) continue;
  declared.set(
    exported.name,
    signatures.map((signature) =>
      signature
        .getParameters()
        .filter((parameter) => !optionalParameter(parameter))
        .map(requiredMembers)
    )
  );
}

// ── The minimum each export is given ───────────────────────────────────

const node = (id, y, type) => ({
  id,
  type: 'custom',
  position: { x: 0, y },
  data: {},
  width: 50,
  height: 20,
  handles: [{ id: null, type, position: type === 'source' ? 'bottom' : 'top', x: 20, y: 0, width: 6, height: 6 }],
});
const nodes = () => [node('a', 0, 'source'), node('b', 120, 'target')];
const edges = () => [{ id: 'e', source: 'a', target: 'b', type: 'custom' }];
const plainNode = { id: 'a', position: { x: 0, y: 0 }, data: {} };
const plainEdge = { id: 'e', source: 'a', target: 'b' };
const endpoints = { sourceX: 0, sourceY: 0, targetX: 100, targetY: 100 };
const sides4 = { sourcePosition: 'bottom', targetPosition: 'top' };

// Where a consumer mounts each component, and the props it is given.
const components = {
  ReactFlow: ['root', {}],
  ReactFlowProvider: ['root', { children: 'child' }],
  Panel: ['flow', {}],
  Background: ['flow', {}],
  Controls: ['flow', {}],
  ControlButton: ['flow', {}],
  MiniMap: ['flow', {}],
  MiniMapNode: [
    'flow',
    { id: 'a', x: 0, y: 0, width: 10, height: 10, borderRadius: 2, className: '', shapeRendering: 'auto', selected: false },
  ],
  ViewportPortal: ['flow', { children: 'portal' }],
  Handle: ['node', { type: 'source', position: 'top' }],
  NodeToolbar: ['node', {}],
  NodeResizer: ['node', {}],
  NodeResizeControl: ['node', {}],
  EdgeText: ['edge', { x: 0, y: 0 }],
  BaseEdge: ['edge', { path: 'M 0,0 L 100,100' }],
  StraightEdge: ['edge', { ...endpoints }],
  StepEdge: ['edge', { ...endpoints, ...sides4 }],
  BezierEdge: ['edge', { ...endpoints, ...sides4 }],
  SimpleBezierEdge: ['edge', { ...endpoints, ...sides4 }],
  SmoothStepEdge: ['edge', { ...endpoints, ...sides4 }],
  EdgeToolbar: ['edge', { x: 0, y: 0, edgeId: 'e' }],
  EdgeLabelRenderer: ['edge', { children: 'label' }],
};

// Each hook's arguments. Every hook runs inside a custom node.
const hooks = {
  useReactFlow: [],
  useUpdateNodeInternals: [],
  useNodes: [],
  useEdges: [],
  useViewport: [],
  useKeyPress: [],
  useNodesState: [[]],
  useEdgesState: [[]],
  useStore: [(state) => state.nodes.length],
  useStoreApi: [],
  useOnViewportChange: [{}],
  useOnSelectionChange: [{ onChange: () => {} }],
  useNodesInitialized: [],
  useHandleConnections: [{ type: 'source' }],
  useNodeConnections: [],
  useNodesData: ['a'],
  useConnection: [],
  useInternalNode: ['a'],
  useNodeId: [],
  experimental_useOnNodesChangeMiddleware: [(changes) => changes],
  experimental_useOnEdgesChangeMiddleware: [(changes) => changes],
};

// Each function's arguments, built fresh for each side.
const functions = {
  getSimpleBezierPath: () => [{ ...endpoints }],
  getBezierPath: () => [{ ...endpoints }],
  getSmoothStepPath: () => [{ ...endpoints }],
  getStraightPath: () => [{ ...endpoints }],
  getEdgeCenter: () => [{ ...endpoints }],
  getBezierEdgeCenter: () => [
    { ...endpoints, sourceControlX: 0, sourceControlY: 50, targetControlX: 100, targetControlY: 50 },
  ],
  getViewportForBounds: () => [{ x: 0, y: 0, width: 100, height: 100 }, 400, 300, 0.5, 2, 0.1],
  getNodesBounds: () => [[{ ...plainNode, width: 50, height: 20 }]],
  getIncomers: () => [{ id: 'b' }, [plainNode, { ...plainNode, id: 'b' }], [plainEdge]],
  getOutgoers: () => [{ id: 'a' }, [plainNode, { ...plainNode, id: 'b' }], [plainEdge]],
  getConnectedEdges: () => [[plainNode], [plainEdge]],
  addEdge: () => [{ source: 'a', target: 'b', sourceHandle: null, targetHandle: null }, []],
  reconnectEdge: () => [
    { ...plainEdge },
    { source: 'a', target: 'c', sourceHandle: null, targetHandle: null },
    [{ ...plainEdge }],
  ],
  applyNodeChanges: () => [[{ type: 'select', id: 'a', selected: true }], [{ ...plainNode }]],
  applyEdgeChanges: () => [[{ type: 'select', id: 'e', selected: true }], [{ ...plainEdge }]],
  isNode: () => [{ ...plainNode }],
  isEdge: () => [{ ...plainEdge }],
};

const membersOf = (value) =>
  value !== null && typeof value === 'object' && !Array.isArray(value) ? Object.keys(value).sort() : null;

// The arguments match one of the export's signatures: one argument per
// required parameter, and each object argument has exactly the required
// members of its parameter.
const matchesDeclaration = (name, args) => {
  const signatures = declared.get(name);
  assert.ok(signatures, `${name} has no call signature in upstream's declarations`);
  const fits = signatures.some(
    (required) =>
      required.length === args.length &&
      required.every((members, i) => members === null || isDeepStrictEqual(membersOf(args[i]), members))
  );
  assert.ok(
    fits,
    `${name}: arguments ${JSON.stringify(args.map(membersOf))} match no declared signature's required ` +
      `parameters ${JSON.stringify(signatures)}`
  );
};

// ── Mounting ───────────────────────────────────────────────────────────

// What one render logs. Upstream logs no error for any of these mounts, so
// ps-flow must not either: React's development build reports through
// `console.error`, including the warning a layout effect raises on a server.
function quietly(render) {
  const logged = [];
  const { error, warn } = console;
  console.error = (...args) => logged.push(['error', String(args[0])]);
  console.warn = (...args) => logged.push(['warn', String(args[0])]);
  try {
    return { html: render(), logged };
  } finally {
    Object.assign(console, { error, warn });
  }
}

const place = (library, where, element) => {
  const { ReactFlow } = library;
  const flow = (extra) => createElement(ReactFlow, { nodes: nodes(), edges: edges(), ...extra });
  switch (where) {
    case 'root':
      return element;
    case 'flow':
      return flow({ children: element });
    case 'node':
      return flow({ nodeTypes: { custom: () => element } });
    case 'edge':
      return flow({ edgeTypes: { custom: () => element } });
    default:
      throw new Error(`no placement ${where}`);
  }
};

// ── The checks ─────────────────────────────────────────────────────────

test('the tables cover every callable export the declarations publish', () => {
  const tabled = [...Object.keys(components), ...Object.keys(hooks), ...Object.keys(functions)].sort();
  assert.deepEqual(tabled, [...declared.keys()].sort());
});

for (const [name, [where, props]] of Object.entries(components)) {
  test(`<${name} /> mounts with only its required props`, () => {
    matchesDeclaration(name, [props]);
    for (const [label, library] of sides) {
      const { [name]: Component } = library;
      const { html, logged } = quietly(() => renderToStaticMarkup(place(library, where, createElement(Component, props))));
      assert.ok(typeof html === 'string', `${label} rendered nothing`);
      assert.deepEqual(
        logged.filter(([level]) => level === 'error'),
        [],
        `${label} logged an error mounting <${name} />`
      );
    }
  });
}

for (const [name, args] of Object.entries(hooks)) {
  test(`${name}() runs with only its required arguments`, () => {
    matchesDeclaration(name, args);
    for (const [label, library] of sides) {
      let ran = false;
      const Probe = () => {
        library[name](...args);
        ran = true;
        return null;
      };
      const { logged } = quietly(() => renderToStaticMarkup(place(library, 'node', createElement(Probe))));
      assert.ok(ran, `${label} never ran ${name}`);
      assert.deepEqual(
        logged.filter(([level]) => level === 'error'),
        [],
        `${label} logged an error running ${name}`
      );
    }
  });
}

for (const [name, args] of Object.entries(functions)) {
  test(`${name}() returns upstream's value with only its required arguments`, () => {
    matchesDeclaration(name, args());
    const [up, ps] = sides.map(([, library]) => library[name](...args()));
    assert.deepEqual(ps, up);
  });
}
