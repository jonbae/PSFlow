import { test } from "node:test";
import assert from "node:assert/strict";

import { SECTIONS } from "../trace-format.mjs";
import { PENDING, assertPendingStillEmpty } from "./pending.mjs";

const empty = () => ({
  dom: { page: { scrollX: 0, scrollY: 0, visualViewportScale: 1 }, root: null },
  callbacks: [],
  hooks: {},
  api: { queries: {}, calls: [] },
  props: {},
  console: [],
  driving: [],
});

test("every declared gap names a real section, and says who lands it", () => {
  for (const entry of PENDING) {
    assert.ok(SECTIONS.includes(entry.section), `${entry.section} is not one of the seven sections`);
    assert.ok(entry.what, `${entry.section} does not say what is missing`);
    assert.equal(typeof entry.issue, "number", `${entry.section} does not name the issue that lands it`);
  }
});

test("the sections capture does fill are not declared pending", () => {
  assert.deepEqual(PENDING, [], "all seven trace sections have capture now");
});

test("a trace whose pending sections are still empty passes through unchanged", () => {
  const sections = empty();
  assert.equal(assertPendingStillEmpty(sections), sections);
});

test("the empty register permits content in every export-bearing section", () => {
  const sections = empty();
  sections.hooks["flow-probe"] = { useViewport: { x: 0, y: 0, zoom: 1 } };
  sections.api.queries.toObject = { nodes: [], edges: [] };
  sections.api.calls.push({ method: "zoomIn", args: [], result: null });
  sections.props["node-probe#1"] = { id: "1" };
  assert.equal(assertPendingStillEmpty(sections), sections);
});
