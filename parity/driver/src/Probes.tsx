// The two probe levels (#59): one child of the flow for instance/hooks, and
// node/edge components for the props they receive. The latter replace a type
// in a graph derived from the fixture; they do not wrap a builtin, because
// upstream exports no builtin node or edge components to wrap.

import { Component, useMemo, type ErrorInfo, type ReactNode } from 'react';
import {
  experimental_useOnEdgesChangeMiddleware,
  experimental_useOnNodesChangeMiddleware,
  useConnection,
  useEdges,
  useEdgesState,
  useHandleConnections,
  useInternalNode,
  useKeyPress,
  useNodeConnections,
  useNodeId,
  useNodes,
  useNodesData,
  useNodesInitialized,
  useNodesState,
  useOnSelectionChange,
  useOnViewportChange,
  useReactFlow,
  useStore,
  useStoreApi,
  useUpdateNodeInternals,
  useViewport,
} from '@xyflow/react';

import plan from 'psflow:probes';
import { installObservationLog } from '../observations.mjs';
import { publishCallLog } from './callbacks';

type Props = Record<string, unknown>;
type HookContext = { nodeId?: string };

const identity = <T,>(value: T): T => value;
const storeSlice = (state: Props) => ({
  nodes: state.nodes,
  edges: state.edges,
  transform: state.transform,
  viewportInitialized: state.viewportInitialized,
});

const callback = (name: string) => publishCallLog().probe(name);

const hooks: Record<string, (context: HookContext) => unknown> = {
  experimental_useOnEdgesChangeMiddleware: () => experimental_useOnEdgesChangeMiddleware(identity),
  experimental_useOnNodesChangeMiddleware: () => experimental_useOnNodesChangeMiddleware(identity),
  useConnection: () => useConnection(),
  useEdges: () => useEdges(),
  useEdgesState: () => useEdgesState([]),
  useHandleConnections: () => useHandleConnections({ type: 'source' }),
  useInternalNode: ({ nodeId }) => useInternalNode(nodeId as string),
  useKeyPress: () => useKeyPress(null),
  useNodeConnections: () => useNodeConnections(),
  useNodeId: () => useNodeId(),
  useNodes: () => useNodes(),
  useNodesData: ({ nodeId }) => useNodesData(nodeId as string),
  useNodesInitialized: () => useNodesInitialized(),
  useNodesState: () => useNodesState([]),
  useOnSelectionChange: () => {
    const onChange = useMemo(() => callback('useOnSelectionChange'), []);
    return useOnSelectionChange({ onChange });
  },
  useOnViewportChange: () => {
    const observe = useMemo(() => callback('useOnViewportChange'), []);
    return useOnViewportChange({ onStart: observe, onChange: observe, onEnd: observe });
  },
  useReactFlow: () => useReactFlow(),
  useStore: () => useStore(storeSlice),
  useStoreApi: () => {
    const api = useStoreApi();
    installObservationLog(window).recordQuery('getState', api.getState());
    return api;
  },
  useUpdateNodeInternals: () => useUpdateNodeInternals(),
  useViewport: () => useViewport(),
};

const NODE_HOOKS = new Set(['useHandleConnections', 'useNodeConnections', 'useNodeId']);

type BoundaryProps = { probe: string; name: string; children: ReactNode };

class HookBoundary extends Component<BoundaryProps, { failed: boolean }> {
  state = { failed: false };

  static getDerivedStateFromError() {
    return { failed: true };
  }

  componentDidCatch(error: Error, _info: ErrorInfo) {
    installObservationLog(window).recordHookError(this.props.probe, this.props.name, error);
  }

  render() {
    return this.state.failed ? null : this.props.children;
  }
}

const HookProbe = ({ probe, name, context }: { probe: string; name: string; context: HookContext }) => {
  const observe = hooks[name];
  if (!observe) throw new Error(`the generated probe plan names no hook implementation for ${name}`);
  const value = observe(context);
  installObservationLog(window).recordHook(probe, name, value);
  return null;
};

const HookLevel = ({ probe, names, context }: { probe: string; names: string[]; context: HookContext }) => (
  <>
    {names.map((name) => (
      <HookBoundary key={name} probe={probe} name={name}>
        <HookProbe probe={probe} name={name} context={context} />
      </HookBoundary>
    ))}
  </>
);

/** Mounted for every net run; hook probes join it only on `flow-node` variants. */
export const NetObserver = ({ nodeId, probes }: { nodeId?: string; probes: boolean }) => {
  installObservationLog(window).attach(useReactFlow());
  if (!probes) return null;
  const names = plan.hooks.filter((name: string) => !NODE_HOOKS.has(name));
  return <HookLevel probe="flow-probe" names={names} context={{ nodeId }} />;
};

export const NodeProbe = (props: Props) => {
  installObservationLog(window).recordProps('node-props', props);
  const names = plan.hooks.filter((name: string) => NODE_HOOKS.has(name));
  return (
    <div>
      {String((props.data as Props | undefined)?.label ?? props.id ?? '')}
      <HookLevel probe="node-probe" names={names} context={{ nodeId: String(props.id) }} />
    </div>
  );
};

export const EdgeProbe = (props: Props) => {
  const log = installObservationLog(window);
  log.recordProps('edge-component-props', props);
  log.recordProps('edge-props', props);
  return null;
};

export const ConnectionLineProbe = (props: Props) => {
  installObservationLog(window).recordProps('connection-line-props', props);
  return null;
};
