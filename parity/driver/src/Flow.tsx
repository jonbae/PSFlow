// The driver — the React component that mounts a fixture.
//
// A hand-maintained twin of `xyflow/examples/react/src/generic-tests/Flow.tsx`.
// The "make hand-translation impossible" bar that governs fixtures absolutely
// does not govern this file: a driver mistake shows up identically on both
// sides, while a boundary mistake is a real bug the net exists to catch. That
// is why this is hand-written and the fixtures are not.
//
// Everything below is upstream's, with six named differences. Two are forced:
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
// node/edge/connection-line type from the fixture graph. Plain runs bypass that
// and retain the upstream graph object.
//
// It is also where `NetObserver` is mounted, and it is mounted for **every**
// observed run rather than only for a probe variant, which is what its own
// `probes` prop is for and what its doc comment always said. It renders nothing unless probing; what it does
// unconditionally is hand the flow instance to the observation bridge, which is
// the only way the harness can reach it. Gated on the variant instead, the
// `call` primitive answered "no ReactFlow instance is attached" for every plain
// scenario — so the imperative half of the vocabulary existed and could not be
// used, which is not a thing a corpus can see from the outside: the three
// scenarios that drive it are the first ones ever to have tried (#60).
//
// The fifth and sixth arrived with the thirty test-debt scenarios (#60), which
// name conditions no vendored fixture sets. Both are **fixture-declared and
// inert unless a fixture asks**, so every scenario written before them drives
// the same component it always did:
//
//   * **chrome props may be a list.** `<Panel>` renders once per entry, and so
//     do the other three. One upstream row is a claim about centring a panel at
//     `top-center` *and* at `bottom-center` — two panels at once — and a
//     scenario mounts one route: with a single slot the two positions could
//     only ever be two fixtures, which is two scenarios, which is a row that
//     resolves to neither.
//   * **the flow's props may change after it has mounted.** A fixture's
//     `afterMount` is merged over `flowProps` when the scenario presses the
//     driver's one control, rendered `position: fixed` and outside
//     `<ReactFlow>` so it is in no `dom` section and displaces no layout. The
//     three StoreUpdater rows are about what happens when a tracked prop
//     *changes*, and nothing in the closed action vocabulary can change one:
//     the vocabulary drives a page, and props come from above it.
//
// And a rule rather than a third knob: **change handlers, and the `nodes` and
// `edges` props they feed, are installed only for a controlled fixture** — one
// that supplies `flowProps.nodes`. An uncontrolled fixture (`defaultNodes`)
// handed `onNodesChange` would call `applyNodeChanges(changes, undefined)` on
// its first change and flip itself to controlled halfway through a scenario.
//
// A knob for suppressing them on a *controlled* fixture was written and then
// removed, because nothing needed it. It was meant to leave a flow's nodes
// unmeasured, which is what upstream's own error text describes ("Please use
// onNodesChange as explained in the docs") — but measurement is internal, done
// by the resize observer straight into the node lookup, and it happens whether
// or not the consumer feeds anything back. `fixtures/nodes/unmeasured.ts` says
// what does leave a node unmeasured.
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
import { AFTER_MOUNT } from '../controls.mjs';
import { deriveProbeGraph } from '../probe-graph.mjs';
import { ConnectionLineProbe, EdgeProbe, NetObserver, NodeProbe } from './Probes';

type ChromeProps = Record<string, unknown> | Record<string, unknown>[];

export type FlowConfig = {
  flowProps?: Record<string, unknown> & { nodes?: unknown[]; edges?: unknown[] };
  panelProps?: ChromeProps;
  backgroundProps?: ChromeProps;
  controlsProps?: ChromeProps;
  minimapProps?: ChromeProps;
  afterMount?: Record<string, unknown>;
};

const chrome = (props: ChromeProps | undefined): Record<string, unknown>[] =>
  props === undefined ? [] : Array.isArray(props) ? props : [props];

type FlowProps = {
  flowConfig: FlowConfig;
};

export default ({ flowConfig }: FlowProps) => {
  const variant = new URLSearchParams(window.location.search).get('probe') ?? 'plain';
  const derived = deriveProbeGraph(flowConfig, variant, { NodeProbe, EdgeProbe, ConnectionLineProbe });
  const [nodes, setNodes] = useState(derived.flowProps?.nodes);
  const [edges, setEdges] = useState(derived.flowProps?.edges);
  const [changed, setChanged] = useState(false);

  const onNodesChange = useCallback((changes: unknown[]) => setNodes((nds) => applyNodeChanges(changes, nds)), []);
  const onEdgesChange = useCallback((changes: unknown[]) => setEdges((eds) => applyEdgeChanges(changes, eds)), []);
  const onConnect = useCallback((params: unknown) => setEdges((eds) => addEdge(params, eds)), []);

  // A controlled fixture is one that supplies `nodes`, and only it is handed the
  // change handlers and the state they feed. An uncontrolled fixture keeps
  // `nodes` and `edges` off `<ReactFlow>` altogether, so `defaultNodes` decides.
  const controlled = derived.flowProps?.nodes !== undefined;
  const graph = controlled
    ? { nodes, edges, onNodesChange, onEdgesChange, onConnect }
    : { onConnect };

  const props = { ...derived.flowProps, ...graph, ...(changed ? flowConfig.afterMount : null) };

  // Every callback prop upstream declares, each recording its call into the
  // in-page log and then deferring to whatever `props` held under the same
  // name — including the three above. Spread *after* `props`, which is what
  // makes that true of the fixture's own handlers as well as of the 45 no
  // fixture sets.
  const observed = useObservedHandlers(props);

  return (
    <div style={{ height: '100%' }}>
      {flowConfig.afterMount && (
        <button
          type="button"
          data-testid={AFTER_MOUNT}
          onClick={() => setChanged(true)}
          style={{ position: 'fixed', right: 0, bottom: 0, zIndex: 10000 }}
        >
          after mount
        </button>
      )}
      <ReactFlow {...props} {...observed}>
        {new URLSearchParams(window.location.search).get('observe') === 'callbacks' && (
          <NetObserver nodeId={(nodes?.[0] as { id?: string } | undefined)?.id} probes={variant === 'flow-node'} />
        )}
        {chrome(flowConfig.controlsProps).map((one, i) => (
          <Controls key={i} {...one} />
        ))}
        {chrome(flowConfig.panelProps).map((one, i) => (
          <Panel key={i} {...one} />
        ))}
        {chrome(flowConfig.minimapProps).map((one, i) => (
          <MiniMap key={i} {...one} />
        ))}
        {chrome(flowConfig.backgroundProps).map((one, i) => (
          <Background key={i} {...one} />
        ))}
      </ReactFlow>
    </div>
  );
};
