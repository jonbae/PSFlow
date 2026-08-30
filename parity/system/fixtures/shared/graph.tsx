// The graph the ps-flow-authored fixtures start from.
//
// `.tsx`, and deliberately, though it renders nothing: the driver's registry
// globs `**/*.ts` across both fixture roots and turns **every** match into a
// route, exactly as upstream's own `import.meta.glob` does. A shared `.ts`
// helper here would therefore be mounted as a fixture, get a mount-only
// baseline derived for it, and fail on the page for having no default export.
// The same reason upstream's `components/` are `.tsx`.
//
// Upstream's `nodes/general.ts` is the shape every lifted scenario already aims
// at — `.react-flow__node` first-match, `Node-1` through `Node-4` — and a
// fixture here that invented its own ids would make every test-debt scenario
// read differently from the seed scenario beside it, for nothing. So these are
// upstream's four ordinary nodes and two edges, without the six special-case
// nodes whose own props are the conditions upstream's suite drives.
//
// Functions rather than constants: two fixtures spreading one shared array
// would hand `<ReactFlow>` the same node objects, and `adoptUserNodes` writes
// internals onto what it is given.

export const nodes = () => [
  { id: 'Node-1', data: { label: 'Node-1' }, position: { x: 0, y: 0 }, type: 'input' },
  { id: 'Node-2', data: { label: 'Node-2' }, position: { x: -100, y: 100 }, type: 'output' },
  { id: 'Node-3', data: { label: 'Node-3' }, position: { x: 100, y: 100 } },
  { id: 'Node-4', data: { label: 'Node-4' }, position: { x: 0, y: 200 }, type: 'output' },
];

export const edges = () => [
  { id: '1-2', type: 'default', source: 'Node-1', target: 'Node-2', label: 'edge' },
  { id: '1-3', type: 'default', source: 'Node-1', target: 'Node-3', label: 'edge' },
];
