import { test } from "node:test";
import assert from "node:assert/strict";

import { SECTIONS } from "../trace-format.mjs";
import { PENDING, PendingSectionError, assertPendingStillEmpty } from "./pending.mjs";

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
  const declared = PENDING.map((p) => p.section);
  assert.ok(!declared.includes("driving"), "the driving log is the harness's own (#35)");
  assert.ok(!declared.includes("console"), "console capture is a page listener and is built");
  assert.ok(!declared.includes("dom"), "the element tree landed with the gate (#51)");
  assert.ok(!declared.includes("callbacks"), "the in-page call log landed with the section (#54)");
});

test("a trace whose pending sections are still empty passes through unchanged", () => {
  const sections = empty();
  assert.equal(assertPendingStillEmpty(sections), sections);
});

// The inversion that makes the declaration worth writing: a forgotten entry
// bites the next run rather than rotting. Without it, landing a section's
// capture and leaving its entry behind reports the section as unobserved while
// it is being observed — which is exactly what `dom` would now be doing.
test("a section that gained content fails as a stale declaration", () => {
  const sections = empty();
  sections.hooks["flow-probe"] = { useViewport: { x: 0, y: 0, zoom: 1 } };

  assert.throws(() => assertPendingStillEmpty(sections), (e) => {
    assert.ok(e instanceof PendingSectionError);
    assert.match(e.message, /hooks/);
    assert.match(e.message, /#59/);
    assert.match(e.message, /pending\.mjs/);
    return true;
  });
});

test("api is judged on its queries, because api.calls is captured", () => {
  const withCalls = empty();
  withCalls.api.calls.push({ method: "zoomIn", args: [], result: null });
  assert.doesNotThrow(() => assertPendingStillEmpty(withCalls));

  const withQueries = empty();
  withQueries.api.queries.toObject = { nodes: [], edges: [] };
  assert.throws(() => assertPendingStillEmpty(withQueries), /api/);
});

test("several landing at once are all named, not just the first", () => {
  const sections = empty();
  sections.hooks["flow-probe"] = { useViewport: { x: 0, y: 0, zoom: 1 } };
  sections.props["node-probe#1"] = { id: "1" };

  assert.throws(() => assertPendingStillEmpty(sections), (e) => {
    assert.match(e.message, /hooks/);
    assert.match(e.message, /props/);
    return true;
  });
});
