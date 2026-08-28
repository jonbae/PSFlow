import { test } from "node:test";
import assert from "node:assert/strict";

import { defineScenario } from "../harness/scenario.mjs";
import { deriveProbePlan, probeVariants } from "./probes.mjs";

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
    probeVariants(plain, plan).map(({ id, variant }) => [id, variant]),
    [
      ["click-selects-node--probe-flow-node", "flow-node"],
      ["wheel-zooms-the-pane--probe-flow-node", "flow-node"],
      ["mount-baseline--nodes-general--probe-edge", "edge"],
      ["connect-source-handle-to-target-handle--probe-connection-line", "connection-line"],
    ]
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
