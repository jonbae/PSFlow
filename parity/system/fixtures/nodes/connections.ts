// A node with more than one edge on a handle (#4949).
//
// `probe-node-connections` reads `useNodeConnections` off the DOM, and this is
// the graph that makes the reading mean something: the hub is connected **three
// times through one source handle** and twice through one target handle, which
// is the shape a hook returning one connection per handle would get wrong while
// a hook returning one per edge gets right. A star graph with a single edge per
// handle would be answered identically by both.
//
// The scenario adds a further edge by dragging one, so the reading is compared
// once at mount and once after the graph has changed underneath the hook.

import ConnectionsNode from './components/ConnectionsNode';

export default {
  flowProps: {
    fitView: true,
    nodeTypes: { connections: ConnectionsNode },
    nodes: [
      { id: 'hub', type: 'connections', data: { label: 'hub' }, position: { x: 160, y: 160 } },
      { id: 'up-1', type: 'connections', data: { label: 'up-1' }, position: { x: 0, y: 0 } },
      { id: 'up-2', type: 'connections', data: { label: 'up-2' }, position: { x: 320, y: 0 } },
      { id: 'down-1', type: 'connections', data: { label: 'down-1' }, position: { x: 0, y: 320 } },
      { id: 'down-2', type: 'connections', data: { label: 'down-2' }, position: { x: 320, y: 320 } },
      { id: 'down-3', type: 'connections', data: { label: 'down-3' }, position: { x: 640, y: 320 } },
    ],
    edges: [
      { id: 'up-1-hub', source: 'up-1', sourceHandle: 'out', target: 'hub', targetHandle: 'in' },
      { id: 'up-2-hub', source: 'up-2', sourceHandle: 'out', target: 'hub', targetHandle: 'in' },
      { id: 'hub-down-1', source: 'hub', sourceHandle: 'out', target: 'down-1', targetHandle: 'in' },
      { id: 'hub-down-2', source: 'hub', sourceHandle: 'out', target: 'down-2', targetHandle: 'in' },
      { id: 'hub-down-3', source: 'hub', sourceHandle: 'out', target: 'down-3', targetHandle: 'in' },
    ],
  },
};
