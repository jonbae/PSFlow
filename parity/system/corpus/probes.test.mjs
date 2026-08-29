import { test } from "node:test";
import assert from "node:assert/strict";

import { defineScenario } from "../harness/scenario.mjs";
import { compileProbePlan, deriveProbePlan, probeVariants, readProbePlan } from "./probes.mjs";

const ISSUE_59 = { ticket: "https://github.com/jonbae/PSFlow/issues/59" };
const hole = (section, names, issue = ISSUE_59) => ({
  export: names[0],
  section,
  outcome: "hole",
  hole: issue,
  witness: { kind: "names", names },
});

test("the probe plan is derived from ticket 59's actual holes and their witnesses", () => {
  const outcomes = {
    exports: [
      hole("hooks", ["useViewport"]),
      hole("api", ["getState"]),
      hole("props", ["node-props"]),
      hole("props", ["edge-props", "edge-component-props"]),
      hole("callbacks", ["useOnSelectionChange"]),
      hole("dom", ["ignored"], { ticket: "https://github.com/jonbae/PSFlow/issues/62" }),
    ],
  };

  assert.deepEqual(deriveProbePlan(outcomes), {
    callbacks: ["useOnSelectionChange"],
    hooks: ["useViewport"],
    api: ["getState"],
    props: ["edge-component-props", "edge-props", "node-props"],
  });
});

test("the production plan is compiled from retired holes through the current census and witnesses", () => {
  const classification = {
    UseOptions: ["options", "dual-run-callback", [], ""],
    useThing: ["hook", "dual-run-hook", [], ""],
  };
  const retiredHoles = [{ exports: ["UseOptions", "useThing"], reason: "needs probes", ...ISSUE_59 }];
  const witnesses = [
    { export: "UseOptions", names: ["useOptionsCallback"] },
    { export: "useThing", names: ["useThing"] },
  ];

  assert.deepEqual(compileProbePlan(retiredHoles, classification, witnesses), {
    callbacks: ["useOptionsCallback"],
    hooks: ["useThing"],
    api: [],
    props: [],
  });
  assert.equal(readProbePlan().hooks.includes("useViewport"), true);
});

const source = (id, probeCapabilities = []) =>
  defineScenario({ id, route: "/tests/generic/nodes/general", run: async () => {}, probeCapabilities });

test("only variants required by the derived plan join the corpus", () => {
  const plain = [
    source("mount-baseline--nodes-general"),
    source("click-selects-node", ["selection"]),
    source("wheel-zooms-the-pane", ["viewport"]),
    source("connect-source-handle-to-target-handle", ["connection"]),
  ];
  const plan = {
    callbacks: ["useOnSelectionChange", "useOnViewportChange"],
    hooks: ["useViewport"],
    api: ["getState"],
    props: ["connection-line-props", "edge-component-props", "edge-props", "node-props"],
  };

  assert.deepEqual(
    probeVariants(plain, plan).map(({ id, variant, probeCallback }) => [id, variant, probeCallback]),
    [
      ["click-selects-node--probe-flow-node", "flow-node", "useOnSelectionChange"],
      ["wheel-zooms-the-pane--probe-flow-node", "flow-node", "useOnViewportChange"],
      ["mount-baseline--nodes-general--probe-edge", "edge", null],
      ["connect-source-handle-to-target-handle--probe-connection-line", "connection-line", null],
    ]
  );
});

test("flow hooks still get a baseline probe when the plan needs no callback interaction", () => {
  const plain = [source("mount-baseline--nodes-general")];

  assert.deepEqual(
    probeVariants(plain, { callbacks: [], hooks: ["useViewport"], api: [], props: [] }).map(
      ({ id, variant, probeCallback }) => [id, variant, probeCallback]
    ),
    [["mount-baseline--nodes-general--probe-flow-node", "flow-node", null]]
  );
});

test("a probe need with no source that can exercise it fails instead of being silently dropped", () => {
  assert.throws(
    () =>
      probeVariants([source("mount-baseline--nodes-general")], {
        callbacks: [],
        hooks: [],
        api: [],
        props: ["connection-line-props"],
      }),
    /connection/
  );
});
