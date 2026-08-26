import { test } from "node:test";
import assert from "node:assert/strict";

import { behaviorCoverage, coverageOutcomes } from "./coverage.mjs";
import { renderCoverage, renderCoverageFailures, renderCoverageSummary } from "./report.mjs";

const entries = [
  { export: "MiniMap", section: "dom" },
  { export: "ViewportPortal", section: "dom" },
  { export: "OnConnect", section: "callbacks" },
  { export: "useNodes", section: "hooks" },
];

const witnesses = [
  { export: "MiniMap", selector: ".react-flow__minimap" },
  { export: "ViewportPortal", selector: ".react-flow__viewport-portal" },
  { export: "OnConnect", names: ["onConnect"] },
  { export: "useNodes", names: ["useNodes"] },
];

const holes = [
  { export: "ViewportPortal", reason: "no fixture mounts one", ticket: "https://github.com/jonbae/PSFlow/issues/60" },
  { export: "OnConnect", reason: "no scenario draws a connection yet" },
  { export: "useNodes", reason: "the hooks section needs probes", ticket: "https://github.com/jonbae/PSFlow/issues/59" },
];

const traces = [
  {
    scenario: "mount-baseline--nodes-general",
    sections: {
      dom: { page: {}, root: { tag: "div", attrs: { class: "react-flow__minimap" }, children: [] } },
      callbacks: [],
      hooks: {},
    },
  },
];

const outcomesOf = (over = {}) => coverageOutcomes(entries, { witnesses, holes, traces, ...over });

test("the artifact states the termination condition and whether it holds", () => {
  const report = renderCoverage(outcomesOf(), behaviorCoverage({}, { scenarioIds: [] }), { baseline: "12.11.0" });

  assert.match(report, /either driven or a deliberately declared hole/);
  assert.match(report, /1 of 4 export-bearing entries driven/);
  assert.match(report, /3 declared holes/);
});

test("the two counts are printed apart, and the report says why they are never summed", () => {
  const report = renderCoverage(outcomesOf(), behaviorCoverage({}, { scenarioIds: [] }), { baseline: "12.11.0" });

  assert.match(report, /never summed/);
  assert.match(report, /## Export coverage/);
  assert.match(report, /## Behavior coverage/);
});

test("an undeclared hole is named in the artifact rather than only in the exit code", () => {
  const report = renderCoverage(outcomesOf({ holes: [] }), behaviorCoverage({}, { scenarioIds: [] }), {
    baseline: "12.11.0",
  });

  assert.match(report, /undeclared/);
  assert.match(report, /`OnConnect`/);
});

test("every export's witness is printed, so a wrong one can be read and disputed", () => {
  const report = renderCoverage(outcomesOf(), behaviorCoverage({}, { scenarioIds: [] }), { baseline: "12.11.0" });

  assert.match(report, /\.react-flow__minimap/);
  assert.match(report, /onConnect/);
  assert.match(report, /mount-baseline--nodes-general/);
});

test("a clean register says so in one line; a broken one says what to fix", () => {
  assert.match(renderCoverageSummary(outcomesOf(), behaviorCoverage({}, { scenarioIds: [] })), /^coverage: 1 of 4/);

  const failures = renderCoverageFailures(
    coverageOutcomes(entries, {
      witnesses: [...witnesses, { export: "MiniMapNode", selector: ".react-flow__minimap-node" }],
      holes: [holes[0], holes[2]],
      traces,
    }),
    behaviorCoverage({ 5684: { bucket: "gate-pending", gate: "system", scenario: "nobody-wrote-this" } }, {})
  ).join("\n");

  assert.match(failures, /OnConnect/, "the undeclared hole");
  assert.match(failures, /MiniMapNode/, "the stale witness");
  assert.match(failures, /nobody-wrote-this/, "the gate-pending row naming a scenario the corpus does not hold");
});

test("holes sharing a reason are listed together, so the reason is written once", () => {
  const shared = [
    { export: "ViewportPortal", reason: "no fixture portals anything" },
    { export: "OnConnect", reason: "no fixture portals anything" },
    { export: "useNodes", reason: "the hooks section has no probe" },
  ];
  const report = renderCoverage(outcomesOf({ holes: shared }), behaviorCoverage({}, { scenarioIds: [] }), {
    baseline: "12.11.0",
  });
  const holesSection = report.slice(report.indexOf("## The declared holes"));

  assert.equal(holesSection.match(/no fixture portals anything/g).length, 1);
  assert.match(holesSection, /`OnConnect`, `ViewportPortal`|`ViewportPortal`, `OnConnect`/);
  assert.match(holesSection, /the hooks section has no probe/);
});
