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

test("the sections this ticket does capture are not declared pending", () => {
  const declared = PENDING.map((p) => p.section);
  assert.ok(!declared.includes("driving"), "the driving log is what this ticket built");
  assert.ok(!declared.includes("console"), "console capture is a page listener and is built");
});

test("a trace whose pending sections are still empty passes through unchanged", () => {
  const sections = empty();
  assert.equal(assertPendingStillEmpty(sections), sections);
});

// The inversion that makes the declaration worth writing: a forgotten entry
// bites the next run rather than rotting. Without it, landing `dom` capture and
// leaving the entry behind reports the section as unobserved while it is being
// observed.
test("a section that gained content fails as a stale declaration", () => {
  const sections = empty();
  sections.dom.root = { tag: "div", attrs: {}, children: [] };

  assert.throws(() => assertPendingStillEmpty(sections), (e) => {
    assert.ok(e instanceof PendingSectionError);
    assert.match(e.message, /dom/);
    assert.match(e.message, /#51/);
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
  sections.callbacks.push({ name: "onNodesChange", args: [] });
  sections.props["node-probe#1"] = { id: "1" };

  assert.throws(() => assertPendingStillEmpty(sections), (e) => {
    assert.match(e.message, /callbacks/);
    assert.match(e.message, /props/);
    return true;
  });
});
