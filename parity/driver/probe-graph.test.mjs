import { test } from "node:test";
import assert from "node:assert/strict";

import { deriveProbeGraph } from "./probe-graph.mjs";

const NodeProbe = () => "node";
const EdgeProbe = () => "edge";
const ConnectionLineProbe = () => "connection";
const probes = { NodeProbe, EdgeProbe, ConnectionLineProbe };

const fixture = () => ({
  flowProps: {
    nodes: [
      { id: "n1", type: "input", data: { label: "one" }, position: { x: 0, y: 0 } },
      { id: "n2", data: { label: "two" }, position: { x: 100, y: 0 } },
    ],
    edges: [{ id: "e1", source: "n1", target: "n2", type: "smoothstep" }],
    nodeTypes: { existing: () => "existing" },
  },
});

test("a plain run receives upstream's graph object unchanged", () => {
  const upstream = fixture();
  assert.equal(deriveProbeGraph(upstream, "plain", probes), upstream);
});

test("the node probe replaces one derived node type instead of wrapping a builtin", () => {
  const upstream = fixture();
  const derived = deriveProbeGraph(upstream, "flow-node", probes);

  assert.equal(derived.flowProps.nodes[0], upstream.flowProps.nodes[0]);
  assert.equal(derived.flowProps.nodes[1].type, "__psflow_node_probe");
  assert.equal(derived.flowProps.nodeTypes.__psflow_node_probe, NodeProbe);
  assert.equal(derived.flowProps.nodeTypes.existing, upstream.flowProps.nodeTypes.existing);
  assert.equal(upstream.flowProps.nodes[1].type, undefined, "the vendored fixture graph was not mutated");
});

test("the node probe skips hidden tail nodes and fails when none can mount", () => {
  const upstream = fixture();
  upstream.flowProps.nodes.push({ id: "hidden", hidden: true });
  const derived = deriveProbeGraph(upstream, "flow-node", probes);

  assert.equal(derived.flowProps.nodes[1].type, "__psflow_node_probe");
  assert.equal(derived.flowProps.nodes[2], upstream.flowProps.nodes[2]);
  assert.throws(
    () => deriveProbeGraph({ flowProps: { nodes: [{ id: "hidden", hidden: true }], edges: [] } }, "flow-node", probes),
    /no visible node/
  );
});

test("edge and connection-line probes are separately derived variants", () => {
  const upstream = fixture();
  const edge = deriveProbeGraph(upstream, "edge", probes);
  const connection = deriveProbeGraph(upstream, "connection-line", probes);

  assert.equal(edge.flowProps.edges[0].type, "__psflow_edge_probe");
  assert.equal(edge.flowProps.edgeTypes.__psflow_edge_probe, EdgeProbe);
  assert.equal(edge.flowProps.connectionLineComponent, undefined);
  assert.equal(connection.flowProps.connectionLineComponent, ConnectionLineProbe);
  assert.equal(connection.flowProps.edges, upstream.flowProps.edges);
});
