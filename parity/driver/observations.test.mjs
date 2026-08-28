import { test } from "node:test";
import assert from "node:assert/strict";

import { createObservationLog } from "./observations.mjs";

const instance = () => ({
  getNodes: () => [{ id: "n1" }],
  getEdges: () => [{ id: "e1", source: "n1", target: "n2" }],
  toObject: () => ({
    nodes: [{ id: "n1" }],
    edges: [{ id: "e1", source: "n1", target: "n2" }],
    viewport: { x: 10, y: 20, zoom: 1.5 },
  }),
  getZoom: () => 1.5,
  getViewport: () => ({ x: 10, y: 20, zoom: 1.5 }),
  viewportInitialized: true,
  setViewport: async (viewport) => ({ movedTo: viewport }),
});

test("the observation bridge snapshots instance queries and toObject is among them", () => {
  const log = createObservationLog();
  log.attach(instance());

  assert.deepEqual(log.read().api.queries, {
    getNodes: [{ id: "n1" }],
    getEdges: [{ id: "e1", source: "n1", target: "n2" }],
    toObject: {
      nodes: [{ id: "n1" }],
      edges: [{ id: "e1", source: "n1", target: "n2" }],
      viewport: { x: 10, y: 20, zoom: 1.5 },
    },
    getZoom: 1.5,
    getViewport: { x: 10, y: 20, zoom: 1.5 },
    viewportInitialized: true,
  });
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
