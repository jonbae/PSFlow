import { test } from "node:test";
import assert from "node:assert/strict";

import { defineScenario } from "../harness/scenario.mjs";
import { CorpusError, RESERVED, assertDistinctIds, buildCorpus, scenarioNames } from "./index.mjs";
import { retirementDebtScenarios } from "./retirement-debt.mjs";
import { seedScenarios } from "./seed.mjs";
import { testDebtScenarios } from "./test-debt.mjs";

const fixtures = (...routes) => routes.map((route) => ({ route, file: `/vendored${route.slice(1)}` }));

// A contract component beside the example driver, though the registry has held
// none since #61: the filter that decides which components get a baseline is
// what these tests are about, and a list with one kind in it cannot exercise it.
const COMPONENTS = [
  { route: "/examples/color-mode", kind: "example-driver", file: "/vendored/ColorMode/index.tsx" },
  { route: "/guard", kind: "contract", file: "/repo/Guard.tsx" },
];

const ids = (scenarios) => scenarios.map((s) => s.id);
const probeIds = (baseline) => [
  "click-selects-node--probe-flow-node",
  "wheel-zooms-the-pane--probe-flow-node",
  `${baseline}--probe-edge`,
  "connect-source-handle-to-target-handle--probe-connection-line",
];

test("the corpus is the baselines, the seed, the test-debt and retirement-debt scenarios, and the hole-derived probe variants", () => {
  const corpus = buildCorpus(fixtures("./nodes/general.ts"), COMPONENTS);

  assert.deepEqual(ids(corpus), [
    "mount-baseline--nodes-general",
    "mount-baseline--examples-color-mode",
    ...ids(seedScenarios),
    ...ids(testDebtScenarios),
    ...ids(retirementDebtScenarios),
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

test("a corpus with no components at all is still the fixtures' baselines and the written sources", () => {
  assert.deepEqual(ids(buildCorpus(fixtures("./pane/general.ts"))), [
    "mount-baseline--pane-general",
    ...ids(seedScenarios),
    ...ids(testDebtScenarios),
    ...ids(retirementDebtScenarios),
    ...probeIds("mount-baseline--pane-general"),
  ]);
});

// The hazard this file exists for, tested where it can be reached. A derived
// baseline's id always leads with `mount-baseline--` and no hand-written
// scenario's does, so the derived source cannot collide with any of them — the
// three hand-named sources can, being written at different times by people
// reading a changelog row or a retiring spec rather than this file, and that is
// when a duplicate is easiest to introduce and hardest to see afterwards.
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

// The name space is what the changelog audit's `gate-pending` rows join against
// (#58). Written and reserved both resolve; the split is what keeps "waiting on
// a run" and "waiting on someone to write it" from reading as one thing.
test("the name space is every written id plus every reserved one, kept apart", () => {
  const names = scenarioNames(fixtures("./nodes/general.ts"), COMPONENTS);

  assert.deepEqual(names.written, ids(buildCorpus(fixtures("./nodes/general.ts"), COMPONENTS)));
  assert.deepEqual(names.reserved, Object.keys(RESERVED));
  assert.equal(names.reserved.length, 30);

  // Since #60 wrote them, every reserved id is also a written one — which is
  // the register doing its job rather than going quiet. The two lists stay
  // separate because they answer different questions, and a name that fell out
  // of `test-debt.mjs` would drop out of `written` while staying `reserved`,
  // so its rows would keep resolving and say so.
  assert.deepEqual(
    names.reserved.filter((id) => !names.written.includes(id)),
    [],
    "every reserved id is written now that the test-debt scenarios exist"
  );
});
