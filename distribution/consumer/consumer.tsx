// A TypeScript consumer of the packed package, which `check.mjs` type-checks
// and never runs. It is written the way upstream's documentation writes a
// flow: a typed custom node and edge, the state hooks, `addEdge`, the chrome
// components and the store. The `@ts-expect-error` lines hold the gaps that
// `gaps.mjs` writes into a type: if an overlay stops applying, the expected
// error disappears and the check fails.
import { useCallback, useState } from 'react';
import {
  Background,
  BackgroundVariant,
  BaseEdge,
  Controls,
  EdgeLabelRenderer,
  Handle,
  MarkerType,
  MiniMap,
  NodeResizer,
  NodeToolbar,
  Panel,
  Position,
  ReactFlow,
  ReactFlowProvider,
  addEdge,
  getBezierPath,
  useEdgesState,
  useNodesState,
  useReactFlow,
  useStore,
  useStoreApi,
  type Edge,
  type EdgeProps,
  type EdgeTypes,
  type Node,
  type NodeProps,
  type NodeTypes,
  type OnConnect,
  type ReactFlowInstance,
  type ReactFlowState,
} from 'ps-flow';

type CounterNode = Node<{ count: number }, 'counter'>;
type LabeledEdge = Edge<{ caption: string }, 'labeled'>;

function CounterNodeView({ data, selected }: NodeProps<CounterNode>) {
  return (
    <>
      <NodeResizer isVisible={selected} minWidth={40} />
      <NodeToolbar position={Position.Top}>count</NodeToolbar>
      <Handle type="target" position={Position.Top} />
      <div>{data.count}</div>
      <Handle type="source" position={Position.Bottom} />
    </>
  );
}

function LabeledEdgeView({ id, sourceX, sourceY, targetX, targetY, sourcePosition, targetPosition, data }: EdgeProps<LabeledEdge>) {
  const [path, labelX, labelY] = getBezierPath({ sourceX, sourceY, targetX, targetY, sourcePosition, targetPosition });
  return (
    <>
      <BaseEdge id={id} path={path} />
      <EdgeLabelRenderer>
        <div style={{ position: 'absolute', transform: `translate(${labelX}px, ${labelY}px)` }}>{data?.caption}</div>
      </EdgeLabelRenderer>
    </>
  );
}

const nodeTypes: NodeTypes = { counter: CounterNodeView };
const edgeTypes: EdgeTypes = { labeled: LabeledEdgeView };

const initialNodes: CounterNode[] = [
  { id: 'a', type: 'counter', position: { x: 0, y: 0 }, data: { count: 1 } },
  { id: 'b', type: 'counter', position: { x: 0, y: 120 }, data: { count: 2 } },
];
const initialEdges: LabeledEdge[] = [{ id: 'a-b', source: 'a', target: 'b', type: 'labeled', data: { caption: 'a to b' } }];

function Flow() {
  const [nodes, , onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState<Edge>(initialEdges);
  const [instance, setInstance] = useState<ReactFlowInstance<CounterNode, Edge> | null>(null);
  const { fitView } = useReactFlow();
  const nodeCount = useStore((state: ReactFlowState) => state.nodes.length);
  const store = useStoreApi();

  const onConnect: OnConnect = useCallback((connection) => setEdges((current) => addEdge(connection, current)), [setEdges]);

  const reset = () => {
    store.setState({ minZoom: 0.25 });
    store.setState((state) => ({ maxZoom: state.maxZoom * 2 }));
    // @ts-expect-error ps-flow refuses a whole-state replacement (gaps.mjs: store-replace).
    store.setState({ minZoom: 0.25 }, true);
    void fitView({ padding: 0.1 });
    instance?.setNodes((current) => current.map((node) => ({ ...node, data: { count: 0 } })));
  };

  return (
    <ReactFlow
      nodes={nodes}
      edges={edges}
      onNodesChange={onNodesChange}
      onEdgesChange={onEdgesChange}
      onConnect={onConnect}
      onInit={setInstance}
      nodeTypes={nodeTypes}
      edgeTypes={edgeTypes}
      defaultEdgeOptions={{ markerEnd: { type: MarkerType.ArrowClosed } }}
      fitView
    >
      <Background variant={BackgroundVariant.Dots} gap={[20, 20]} />
      <Controls />
      <MiniMap pannable zoomable />
      <Panel>
        <button onClick={reset}>{nodeCount}</button>
      </Panel>
    </ReactFlow>
  );
}

export function App() {
  return (
    <ReactFlowProvider>
      <Flow />
    </ReactFlowProvider>
  );
}
