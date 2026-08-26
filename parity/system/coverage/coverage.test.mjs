import { test } from "node:test";
import assert from "node:assert/strict";

import { OUTCOME, behaviorCoverage, coverageOutcomes, exportEntries } from "./coverage.mjs";

const entries = [
  { export: "MiniMap", section: "dom" },
  { export: "OnConnect", section: "callbacks" },
];

const witnesses = [
  { export: "MiniMap", selector: ".react-flow__minimap" },
  { export: "OnConnect", names: ["onConnect"] },
];

const sections = (over = {}) => ({
  dom: { page: {}, root: { tag: "div", attrs: { class: "react-flow" }, children: [] } },
  callbacks: [],
  ...over,
});

const trace = (scenario, over) => ({ scenario, sections: sections(over) });

test("an export counts as driven only when a trace that ran actually held it", () => {
  const held = { root: { tag: "div", attrs: { class: "react-flow__minimap" }, children: [] } };
  const outcomes = coverageOutcomes(entries, {
    witnesses,
    holes: [{ export: "OnConnect", reason: "no scenario draws a connection yet" }],
    traces: [trace("mount-baseline--nodes-general", { dom: held })],
  });

  const [minimap, connect] = outcomes.exports;
  assert.equal(minimap.outcome, OUTCOME.driven);
  assert.deepEqual(minimap.drivenBy, ["mount-baseline--nodes-general"]);
  assert.equal(connect.outcome, OUTCOME.hole);
  assert.equal(outcomes.ok, true);
});

test("an undeclared hole fails, and a declared one passes", () => {
  const outcomes = coverageOutcomes(entries, { witnesses, holes: [], traces: [trace("mount-baseline--pane-general")] });

  assert.deepEqual(
    outcomes.exports.map((e) => e.outcome),
    [OUTCOME.undeclared, OUTCOME.undeclared]
  );
  assert.equal(outcomes.ok, false);
});

test("an export with no witness fails, which is what a bump that adds one looks like", () => {
  const outcomes = coverageOutcomes(entries, {
    witnesses: [witnesses[0]],
    holes: [{ export: "OnConnect", reason: "no scenario draws a connection yet" }],
    traces: [trace("mount-baseline--pane-general")],
  });

  assert.equal(outcomes.exports[1].outcome, OUTCOME.unwitnessed);
  assert.equal(outcomes.ok, false, "a hole does not stand in for a witness — the two say different things");
  assert.deepEqual(outcomes.staleHoles, [], "and its hole is not yet wrong — nothing could have said otherwise");
});

test("a witness naming an export the census no longer carries is stale", () => {
  const outcomes = coverageOutcomes(entries, {
    witnesses: [...witnesses, { export: "MiniMapNode", selector: ".react-flow__minimap-node" }],
    holes: [{ export: "OnConnect", reason: "no scenario draws a connection yet" }],
    traces: [trace("mount-baseline--pane-general")],
  });

  assert.deepEqual(outcomes.staleWitnesses, ["MiniMapNode"]);
  assert.equal(outcomes.ok, false);
});

test("a hole over an export something did drive is stale — the reason stopped being true", () => {
  const held = { root: { tag: "div", attrs: { class: "react-flow__minimap" }, children: [] } };
  const outcomes = coverageOutcomes(entries, {
    witnesses,
    holes: [
      { export: "MiniMap", reason: "no fixture mounts a minimap" },
      { export: "OnConnect", reason: "no scenario draws a connection yet" },
    ],
    traces: [trace("mount-baseline--nodes-general", { dom: held })],
  });

  assert.deepEqual(
    outcomes.staleHoles.map((h) => h.export),
    ["MiniMap"]
  );
  assert.equal(outcomes.ok, false);
});

test("the two counts are kept apart, and the termination condition is what green means", () => {
  const held = { root: { tag: "div", attrs: { class: "react-flow__minimap" }, children: [] } };
  const outcomes = coverageOutcomes(entries, {
    witnesses,
    holes: [{ export: "OnConnect", reason: "no scenario draws a connection yet" }],
    traces: [trace("mount-baseline--nodes-general", { dom: held })],
  });

  assert.deepEqual(outcomes.counts, { total: 2, driven: 1, holes: 1, undeclared: 0, unwitnessed: 0 });
  assert.equal(outcomes.terminated, true);
});

test("a field the noise policy deletes is unobserved, not driven", () => {
  const held = { root: { tag: "div", attrs: { class: "react-flow", "data-testid": "rf__minimap" }, children: [] } };
  const byTestId = [{ export: "MiniMap", selector: "[data-testid=rf__minimap]" }, witnesses[1]];
  const args = { witnesses: byTestId, holes: [], traces: [trace("mount-baseline--nodes-general", { dom: held })] };

  assert.equal(coverageOutcomes(entries, args).exports[0].outcome, OUTCOME.driven);
  assert.equal(
    coverageOutcomes(entries, {
      ...args,
      rules: [{ kind: "delete", at: "dom/**/attrs/data-testid", reason: "supposing the policy deleted it" }],
    }).exports[0].outcome,
    OUTCOME.undeclared
  );
});

test("the export-bearing entries and their sections are read off the census", () => {
  const found = exportEntries({
    _schema: { doc: "ignored" },
    MiniMap: ["component", "dual-run-dom", [], ""],
    useNodes: ["hook", "dual-run-hook", [], ""],
    getBezierPath: ["pure-fn", "oracle", [], ""],
    Position: ["enum-value", "dual-run-value", [], ""],
  });

  assert.deepEqual(found, [
    { export: "MiniMap", section: "dom" },
    { export: "useNodes", section: "hooks" },
  ]);
});

test("behavior coverage is hand-declared, and counted in its own currency", () => {
  const behavior = behaviorCoverage(
    {
      _schema: { doc: "ignored" },
      5684: { bucket: "gate-pending", gate: "system", scenario: "drag-node-release" },
      5450: { bucket: "gate-pending", gate: "system", scenario: "drag-node-autopan" },
      4725: { bucket: "surface", evidence: "present in psflow.json" },
    },
    { scenarioIds: ["drag-node-release", "drag-node-autopan", "mount-baseline--nodes-general"] }
  );

  assert.deepEqual(
    behavior.rows.map((r) => r.pr),
    ["5450", "5684"]
  );
  assert.equal(behavior.counts.declared, 2);
  assert.equal(behavior.ok, true);
});

test("a gate-pending row naming a scenario the corpus does not hold fails", () => {
  // The rule ticket 080 wrote down and deferred: the row names a scenario, and
  // the name means nothing until the corpus holds it.
  const behavior = behaviorCoverage(
    { 5684: { bucket: "gate-pending", gate: "system", scenario: "drag-node-somersault" } },
    { scenarioIds: ["drag-node-release"] }
  );

  assert.deepEqual(behavior.dangling, [{ pr: "5684", scenario: "drag-node-somersault" }]);
  assert.equal(behavior.ok, false);
});

test("a gate-pending row that names no scenario cannot be joined to anything", () => {
  const behavior = behaviorCoverage({ 5684: { bucket: "gate-pending", gate: "system" } }, { scenarioIds: [] });

  assert.deepEqual(behavior.unnamed, ["5684"]);
  assert.equal(behavior.ok, false);
});
