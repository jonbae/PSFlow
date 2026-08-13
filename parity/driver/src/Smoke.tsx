// PSFlow-authored smoke component. This preserves the liveness page and the
// hand-authored assertions that ticket 061 will retire, but reaches the library
// through `@xyflow/react`, which build.mjs aliases to index.js.
import { useCallback, useState } from 'react';
import {
  Background,
  Controls,
  MiniMap,
  Position,
  ReactFlow,
  addEdge,
  applyEdgeChanges,
  applyNodeChanges,
} from '@xyflow/react';

const initialNodes = [
  {
    id: 'n1',
    position: { x: 0, y: 0 },
    data: {},
    sourcePosition: Position.Right,
    targetPosition: Position.Left,
    width: 100,
    height: 40,
    measured: { width: 100, height: 40 },
  },
  {
    id: 'n2',
    position: { x: 250, y: 100 },
    data: {},
    sourcePosition: Position.Right,
    targetPosition: Position.Left,
    width: 100,
    height: 40,
    measured: { width: 100, height: 40 },
  },
];

const initialEdges = [{ id: 'e1-2', source: 'n1', target: 'n2' }];

export default function Smoke() {
  const [nodes, setNodes] = useState(initialNodes);
  const [edges, setEdges] = useState(initialEdges);

  const onNodesChange = useCallback((changes: unknown[]) => {
    (window as any).__lastNodeChanges = changes;
    (window as any).__lastNodeChangesCount =
      ((window as any).__lastNodeChangesCount ?? 0) + 1;
    setNodes((current) => applyNodeChanges(changes, current));
  }, []);

  const onEdgesChange = useCallback((changes: unknown[]) => {
    setEdges((current) => applyEdgeChanges(changes, current));
  }, []);

  const onConnect = useCallback((connection: unknown) => {
    (window as any).__lastConnection = connection;
    setEdges((current) => addEdge(connection, current));
  }, []);

  return (
    <div style={{ height: '100%' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        defaultViewport={{ x: 0, y: 0, zoom: 1 }}
        connectOnClick
      >
        <Background />
        <Controls />
        <MiniMap />
      </ReactFlow>
    </div>
  );
}
