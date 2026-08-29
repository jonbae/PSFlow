// The driver — the React component that mounts a fixture.
//
// A hand-maintained twin of `xyflow/examples/react/src/generic-tests/Flow.tsx`.
// The "make hand-translation impossible" bar that governs fixtures absolutely
// does not govern this file: a driver mistake shows up identically on both
// sides, while a boundary mistake is a real bug the net exists to catch. That
// is why this is hand-written and the fixtures are not.
//
// Everything below is upstream's, with four named differences. Two are forced:
//
//   * `FlowConfig` is declared here rather than being the ambient global
//     upstream's `app.d.ts` supplies, because that file's types come from
//     `@xyflow/react`'s declarations and ps-flow ships none yet (ticket 070).
//     Nothing typechecks this directory — esbuild transpiles it — so the
//     fixtures' `satisfies FlowConfig` is erased along with the rest.
//   * the props are `unknown`-shaped for the same reason. The upstream fixture
//     objects are spread onto `ReactFlow` exactly as upstream spreads them.
//
// The third is deliberate: **every callback prop is installed and observed**
// (`./callbacks.ts`). The net's `callbacks` section is the only witness a
// handler has — one that never fires leaves the DOM identical and every other
// section agreeing — so a handler no fixture sets would be a handler neither
// side is ever asked for. Upstream's own `Flow.tsx` has nothing to say about
// this, since it is not being compared against anything.
//
// The fourth is selective probing: a `?probe=` variant derives a replacement
// node/edge/connection-line type from the fixture graph and, for `flow-node`,
// mounts `NetObserver`. Plain runs bypass both changes and retain the upstream
// graph object.
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

import { useObservedHandlers } from './callbacks';
import { deriveProbeGraph } from '../probe-graph.mjs';
import { ConnectionLineProbe, EdgeProbe, NetObserver, NodeProbe } from './Probes';

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
  const variant = new URLSearchParams(window.location.search).get('probe') ?? 'plain';
  const derived = deriveProbeGraph(flowConfig, variant, { NodeProbe, EdgeProbe, ConnectionLineProbe });
  const [nodes, setNodes] = useState(derived.flowProps?.nodes);
  const [edges, setEdges] = useState(derived.flowProps?.edges);

  const onNodesChange = useCallback((changes: unknown[]) => setNodes((nds) => applyNodeChanges(changes, nds)), []);
  const onEdgesChange = useCallback((changes: unknown[]) => setEdges((eds) => applyEdgeChanges(changes, eds)), []);
  const onConnect = useCallback((params: unknown) => setEdges((eds) => addEdge(params, eds)), []);

  const props = { ...derived.flowProps, nodes, edges, onNodesChange, onEdgesChange, onConnect };

  // Every callback prop upstream declares, each recording its call into the
  // in-page log and then deferring to whatever `props` held under the same
  // name — including the three above. Spread *after* `props`, which is what
  // makes that true of the fixture's own handlers as well as of the 45 no
  // fixture sets.
  const observed = useObservedHandlers(props);

  return (
    <div style={{ height: '100%' }}>
      <ReactFlow {...props} {...observed}>
        {new URLSearchParams(window.location.search).get('observe') === 'callbacks' && variant === 'flow-node' && (
          <NetObserver nodeId={(nodes?.[0] as { id?: string } | undefined)?.id} probes />
        )}
        {flowConfig.controlsProps && <Controls {...flowConfig.controlsProps} />}
        {flowConfig.panelProps && <Panel {...flowConfig.panelProps} />}
        {flowConfig.minimapProps && <MiniMap {...flowConfig.minimapProps} />}
        {flowConfig.backgroundProps && <Background {...flowConfig.backgroundProps} />}
      </ReactFlow>
    </div>
  );
};
