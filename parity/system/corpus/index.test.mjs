import { test } from "node:test";
import assert from "node:assert/strict";

import { defineScenario } from "../harness/scenario.mjs";
import { CorpusError, assertDistinctIds, buildCorpus } from "./index.mjs";
import { seedScenarios } from "./seed.mjs";

const fixtures = (...routes) => routes.map((route) => ({ route, file: `/vendored${route.slice(1)}` }));

const COMPONENTS = [
  { route: "/examples/color-mode", kind: "example-driver", file: "/vendored/ColorMode/index.tsx" },
  { route: "/smoke", kind: "contract", file: "/repo/Smoke.tsx" },
];

const ids = (scenarios) => scenarios.map((s) => s.id);
const probeIds = (baseline) => [
  "click-selects-node--probe-flow-node",
  "wheel-zooms-the-pane--probe-flow-node",
  `${baseline}--probe-edge`,
  "connect-source-handle-to-target-handle--probe-connection-line",
];

test("the corpus is the baselines, the seed, and the hole-derived probe variants", () => {
  const corpus = buildCorpus(fixtures("./nodes/general.ts"), COMPONENTS);

  assert.deepEqual(ids(corpus), [
    "mount-baseline--nodes-general",
    "mount-baseline--examples-color-mode",
    ...ids(seedScenarios),
    ...probeIds("mount-baseline--nodes-general"),
  ]);
});

// An example driver declares its own flow inline, so it *is* a fixture and gets
// a baseline on the same general rule. A contract component renders a
// ps-flow-specific guard and is a fixture of nothing — mounting it on the
// upstream side would compare a page written against ps-flow's own contract
// with upstream's reading of it, which is not a claim the net makes.
test("the example driver gets a baseline and the contract components do not", () => {
  const corpus = buildCorpus(fixtures("./nodes/general.ts"), COMPONENTS);
  const baselines = corpus.filter((scenario) => scenario.variant === "plain").map((scenario) => scenario.id).filter((id) => id.startsWith("mount-baseline--"));

  assert.deepEqual(baselines, ["mount-baseline--nodes-general", "mount-baseline--examples-color-mode"]);
});

test("a corpus with no components at all is still the fixtures' baselines and the seed", () => {
  assert.deepEqual(ids(buildCorpus(fixtures("./pane/general.ts"))), [
    "mount-baseline--pane-general",
    ...ids(seedScenarios),
    ...probeIds("mount-baseline--pane-general"),
  ]);
});

// The hazard this file exists for, tested where it can be reached. A derived
// baseline's id always leads with `mount-baseline--` and no hand-written
// scenario's does, so today's two sources cannot collide — the two that arrive
// later are hand-named, written by someone reading a changelog row rather than
// this file, and that is when a duplicate is easiest to introduce and hardest
// to see afterwards.
test("an id two sources both claim fails rather than sharing trace files", () => {
  const twice = ["/tests/generic/nodes/general", "/tests/generic/pane/general"].map((route) =>
    defineScenario({ id: "drag-node-release", route, run: async () => {} })
  );

  assert.throws(() => assertDistinctIds(twice), (e) => {
    assert.ok(e instanceof CorpusError);
    assert.match(e.message, /drag-node-release/);
    assert.match(e.message, /nodes\/general/);
    assert.match(e.message, /pane\/general/);
    return true;
  });
});

test("the whole corpus passes that check as it stands", () => {
  const corpus = buildCorpus(fixtures("./nodes/general.ts"), COMPONENTS);

  assert.deepEqual(assertDistinctIds(corpus), corpus);
});

test("every scenario in the corpus has a distinct id", () => {
  const corpus = buildCorpus(
    fixtures(
      "./edges/general.ts",
      "./node-toolbar/general.ts",
      "./nodes/general.ts",
      "./pane/general.ts",
      "./pane/non-defaults.ts"
    ),
    COMPONENTS
  );

  assert.deepEqual([...new Set(ids(corpus))].length, corpus.length);
});
