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
  { exports: ["ViewportPortal"], reason: "no fixture mounts one", ticket: "https://github.com/jonbae/PSFlow/issues/60" },
  { exports: ["OnConnect"], reason: "no scenario draws a connection yet" },
  { exports: ["useNodes"], reason: "the hooks section needs probes", ticket: "https://github.com/jonbae/PSFlow/issues/59" },
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
    { exports: ["ViewportPortal", "OnConnect"], reason: "no fixture portals anything" },
    { exports: ["useNodes"], reason: "the hooks section has no probe" },
  ];
  const report = renderCoverage(outcomesOf({ holes: shared }), behaviorCoverage({}, { scenarioIds: [] }), {
    baseline: "12.11.0",
  });
  const holesSection = report.slice(report.indexOf("## The declared holes"));

  assert.equal(holesSection.match(/no fixture portals anything/g).length, 1);
  assert.match(holesSection, /`OnConnect`, `ViewportPortal`|`ViewportPortal`, `OnConnect`/);
  assert.match(holesSection, /the hooks section has no probe/);
});

test("a witness that needed defending prints its defence, not just its rule", () => {
  // The whole safeguard against a derived number being wrong is that the rule is
  // visible and disputable. A `note` is where the doubtful ones argue their
  // case, so an artifact that printed the selector and swallowed the note would
  // hide exactly the entries most worth arguing with.
  const defended = [
    { export: "MiniMap", selector: ".react-flow__minimap" },
    {
      export: "ViewportPortal",
      selector: ".react-flow__viewport-portal *",
      note: "the container is drawn for every flow, so only its content witnesses the export",
    },
    { export: "OnConnect", names: ["onConnect"] },
    { export: "useNodes", names: ["useNodes"] },
  ];
  const report = renderCoverage(outcomesOf({ witnesses: defended }), behaviorCoverage({}, { scenarioIds: [] }), {
    baseline: "12.11.0",
  });

  assert.match(report, /only its content witnesses the export/);
  assert.match(report, /## The witnesses that argue their case/);
});

// Behavior coverage's whole risk is a plan reading as coverage. The artifact has
// to say, per row, which of the three a name is: a scenario that exists, an id
// reserved for one nobody has written, or neither — and the three have to be
// distinguishable at a glance, not inferable from a count at the top.
test("each declared behavior says whether its scenario is written, reserved, or neither", () => {
  const behavior = behaviorCoverage(
    {
      5684: { bucket: "gate-pending", gate: "system", scenario: "mount-baseline--nodes-general", stage: 2 },
      5450: { bucket: "gate-pending", gate: "system", scenario: "drag-node-autopan", stage: 2 },
      4880: { bucket: "gate-pending", gate: "unit", test: "a predicate test over isInputDOMNode" },
    },
    { scenarioIds: ["mount-baseline--nodes-general"], reservedIds: ["drag-node-autopan"] }
  );
  const report = renderCoverage(outcomesOf(), behavior, { baseline: "12.11.0" });

  assert.match(report, /3 behavior\(s\) declared/);
  assert.match(report, /1 of 2 net-bound\s+rows name a scenario that exists/);
  assert.match(report, /\| 5684 \| system \| `mount-baseline--nodes-general` \| 2 \| written \|/);
  assert.match(report, /\| 5450 \| system \| `drag-node-autopan` \| 2 \| reserved \|/);
  // A test is prose that carries its own backticks; only a scenario id is code.
  assert.match(report, /\| 4880 \| unit \| a predicate test over isInputDOMNode \| — \| — \|/);
  assert.match(renderCoverageSummary(outcomesOf(), behavior), /1 against a reserved scenario id/);
});
