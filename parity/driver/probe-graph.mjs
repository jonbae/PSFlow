// Derives a probed graph from the fixture the page already selected (#59).
// The source graph is never mutated, and plain runs bypass this module's
// changes entirely. Each prop-bearing component replaces one element type;
// wrapping a builtin is impossible because upstream exports no builtin node or
// edge components to wrap.

const NODE_TYPE = "__psflow_node_probe";
const EDGE_TYPE = "__psflow_edge_probe";

export class ProbeGraphError extends Error {
  constructor(message) {
    super(message);
    this.name = "ProbeGraphError";
  }
}

const flowPropsOf = (flowConfig, variant) => {
  if (!flowConfig?.flowProps) throw new ProbeGraphError(`${variant}: the fixture has no flowProps graph to derive`);
  return flowConfig.flowProps;
};

export const deriveProbeGraph = (flowConfig, variant, { NodeProbe, EdgeProbe, ConnectionLineProbe }) => {
  if (variant === "plain") return flowConfig;
  const flowProps = flowPropsOf(flowConfig, variant);

  if (variant === "flow-node") {
    if (!flowProps.nodes?.length) throw new ProbeGraphError(`${variant}: the fixture graph has no node to replace`);
    // The selection-capable source clicks the first node, so replace the last
    // visible one: the probe observes a mechanically chosen mounted node
    // without swallowing the ordinary target that makes the hook callback live.
    const probeIndex = flowProps.nodes.findLastIndex((node) => node.hidden !== true);
    if (probeIndex === -1) throw new ProbeGraphError(`${variant}: the fixture graph has no visible node to replace`);
    return {
      ...flowConfig,
      flowProps: {
        ...flowProps,
        nodes: flowProps.nodes.map((node, index) => (index === probeIndex ? { ...node, type: NODE_TYPE } : node)),
        nodeTypes: { ...flowProps.nodeTypes, [NODE_TYPE]: NodeProbe },
      },
    };
  }

  if (variant === "edge") {
    if (!flowProps.edges?.length) throw new ProbeGraphError(`${variant}: the fixture graph has no edge to replace`);
    const [first, ...rest] = flowProps.edges;
    return {
      ...flowConfig,
      flowProps: {
        ...flowProps,
        edges: [{ ...first, type: EDGE_TYPE }, ...rest],
        edgeTypes: { ...flowProps.edgeTypes, [EDGE_TYPE]: EdgeProbe },
      },
    };
  }

  if (variant === "connection-line") {
    return { ...flowConfig, flowProps: { ...flowProps, connectionLineComponent: ConnectionLineProbe } };
  }

  throw new ProbeGraphError(`unknown probe graph variant ${JSON.stringify(variant)}`);
};
