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
    const [first, ...rest] = flowProps.nodes;
    return {
      ...flowConfig,
      flowProps: {
        ...flowProps,
        nodes: [{ ...first, type: NODE_TYPE }, ...rest],
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
