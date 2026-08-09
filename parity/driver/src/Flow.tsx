// The driver — the React component that mounts a fixture.
//
// A twin of `xyflow/examples/react/src/generic-tests/Flow.tsx`, line for line.
// The "make hand-translation impossible" bar that governs fixtures absolutely
// does not govern this file: a driver mistake shows up identically on both
// sides, while a boundary mistake is a real bug the net exists to catch. That
// is why this is hand-written and the fixtures are not.
//
// Everything below is upstream's, with two differences, both forced:
//
//   * `FlowConfig` is declared here rather than being the ambient global
//     upstream's `app.d.ts` supplies, because that file's types come from
//     `@xyflow/react`'s declarations and ps-flow ships none yet (ticket 070).
//     Nothing typechecks this directory — esbuild transpiles it — so the
//     fixtures' `satisfies FlowConfig` is erased along with the rest.
//   * the props are `unknown`-shaped for the same reason. The upstream fixture
//     objects are spread onto `ReactFlow` exactly as upstream spreads them.
//
// `@xyflow/react` is a build-level alias (see `../build.mjs`). It resolves to
// ps-flow's `index.js` for the conformance run and to the vendored upstream for
// the net's other run; this file cannot tell which, and that is the point — one
// driver bundled twice means a driver difference can never be mistaken for a
// library difference.
import { useState, useCallback } from 'react';
import {
  ReactFlow,
  applyNodeChanges,
  applyEdgeChanges,
  addEdge,
  Controls,
  Panel,
  MiniMap,
  Background,
} from '@xyflow/react';

export type FlowConfig = {
  flowProps?: Record<string, unknown> & { nodes: unknown[]; edges: unknown[] };
  panelProps?: Record<string, unknown>;
  backgroundProps?: Record<string, unknown>;
  controlsProps?: Record<string, unknown>;
  minimapProps?: Record<string, unknown>;
};

type FlowProps = {
  flowConfig: FlowConfig;
};

export default ({ flowConfig }: FlowProps) => {
  const [nodes, setNodes] = useState(flowConfig.flowProps?.nodes);
  const [edges, setEdges] = useState(flowConfig.flowProps?.edges);
  const props = { ...flowConfig.flowProps, nodes, edges };

  const onNodesChange = useCallback((changes: unknown[]) => setNodes((nds) => applyNodeChanges(changes, nds)), []);
  const onEdgesChange = useCallback((changes: unknown[]) => setEdges((eds) => applyEdgeChanges(changes, eds)), []);
  const onConnect = useCallback((params: unknown) => setEdges((eds) => addEdge(params, eds)), []);

  return (
    <div style={{ height: '100%' }}>
      <ReactFlow {...props} onNodesChange={onNodesChange} onEdgesChange={onEdgesChange} onConnect={onConnect}>
        {flowConfig.controlsProps && <Controls {...flowConfig.controlsProps} />}
        {flowConfig.panelProps && <Panel {...flowConfig.panelProps} />}
        {flowConfig.minimapProps && <MiniMap {...flowConfig.minimapProps} />}
        {flowConfig.backgroundProps && <Background {...flowConfig.backgroundProps} />}
      </ReactFlow>
    </div>
  );
};
