import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { IMPERATIVE_QUERIES, createObservationLog } from "./observations.mjs";
import { IMPERATIVE_MUTATORS } from "../system/harness/actions.mjs";

const here = dirname(fileURLToPath(import.meta.url));

const instance = () => ({
  getNodes: () => [{ id: "n1" }],
  getNode: (id) => ({ id }),
  getInternalNode: (id) => ({ id, internals: { positionAbsolute: { x: 1, y: 2 } } }),
  getEdges: () => [{ id: "e1", source: "n1", target: "n2" }],
  getEdge: (id) => ({ id, source: "n1", target: "n2" }),
  getIntersectingNodes: (rect) => [{ id: "n1", rect }],
  isNodeIntersecting: (_node, _rect, partially) => partially,
  getNodesBounds: (ids) => ({ x: 0, y: 0, width: ids.length * 10, height: 10 }),
  getHandleConnections: (query) => [{ ...query, edgeId: "e1" }],
  getNodeConnections: (query) => [{ ...query, edgeId: "e1" }],
  toObject: () => ({
    nodes: [{ id: "n1" }],
    edges: [{ id: "e1", source: "n1", target: "n2" }],
    viewport: { x: 10, y: 20, zoom: 1.5 },
  }),
  getZoom: () => 1.5,
  getViewport: () => ({ x: 10, y: 20, zoom: 1.5 }),
  screenToFlowPosition: (position) => ({ x: position.x - 10, y: position.y - 20 }),
  flowToScreenPosition: (position) => ({ x: position.x + 10, y: position.y + 20 }),
  viewportInitialized: true,
  setViewport: async (viewport) => ({ movedTo: viewport }),
});

test("the observation bridge snapshots instance queries and toObject is among them", () => {
  const log = createObservationLog();
  log.attach(instance());

  assert.deepEqual(log.read().api.queries, {
    getNodes: [{ id: "n1" }],
    getNode: { id: "n1" },
    getInternalNode: { id: "n1", internals: { positionAbsolute: { x: 1, y: 2 } } },
    getEdges: [{ id: "e1", source: "n1", target: "n2" }],
    getEdge: { id: "e1", source: "n1", target: "n2" },
    getIntersectingNodes: [
      { id: "n1", rect: { x: 0, y: 0, width: 0, height: 0 } },
    ],
    isNodeIntersecting: true,
    getNodesBounds: { x: 0, y: 0, width: 10, height: 10 },
    getHandleConnections: [{ type: "source", nodeId: "n1", edgeId: "e1" }],
    getNodeConnections: [{ nodeId: "n1", edgeId: "e1" }],
    toObject: {
      nodes: [{ id: "n1" }],
      edges: [{ id: "e1", source: "n1", target: "n2" }],
      viewport: { x: 10, y: 20, zoom: 1.5 },
    },
    getZoom: 1.5,
    getViewport: { x: 10, y: 20, zoom: 1.5 },
    screenToFlowPosition: { x: -10, y: -20 },
    flowToScreenPosition: { x: 10, y: 20 },
    viewportInitialized: true,
  });
});

test("settled queries and driving mutators partition every crossed ReactFlowInstance member", () => {
  const source = readFileSync(join(here, "..", "..", "src", "Boundary", "Instance.purs"), "utf8");
  const body = source.match(/type JsReactFlowInstance =([\s\S]*?)\n\s*\}/)?.[1] ?? "";
  const crossed = [...body.matchAll(/^\s*(?:\{|,)\s*([A-Za-z][A-Za-z0-9]*)\s*::/gm)].map((match) => match[1]);
  const observed = [...IMPERATIVE_QUERIES, ...IMPERATIVE_MUTATORS];

  assert.deepEqual([...new Set(observed)].sort(), crossed.sort());
  assert.equal(observed.length, crossed.length, "no instance member is classified twice");
});

test("registered hook-store queries are evaluated only when the settled snapshot is read", () => {
  const log = createObservationLog();
  let state = { revision: 1 };

  log.registerQuery("getState", () => state);
  state = { revision: 2 };

  assert.deepEqual(log.read().api.queries.getState, { revision: 2 });
});

test("hook and props probes are keyed by probe id and serialized on receipt", () => {
  const log = createObservationLog();
  const hooks = { viewport: { x: 0, y: 0, zoom: 1 } };
  const props = { id: "n1", selected: false };

  log.recordHook("flow-probe", "useViewport", hooks.viewport);
  log.recordProps("node-props", props);
  hooks.viewport.x = 99;
  props.selected = true;

  assert.deepEqual(log.read(), {
    hooks: { "flow-probe": { useViewport: { x: 0, y: 0, zoom: 1 } } },
    api: { queries: {} },
    props: { "node-props": { id: "n1", selected: false } },
    failures: [],
  });
});

test("imperative calls await and serialize their return value", async () => {
  const log = createObservationLog();
  log.attach(instance());

  assert.deepEqual(await log.call("setViewport", [{ x: 1, y: 2, zoom: 3 }]), {
    movedTo: { x: 1, y: 2, zoom: 3 },
  });
});
