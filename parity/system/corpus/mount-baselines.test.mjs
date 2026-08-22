import { test } from "node:test";
import assert from "node:assert/strict";

import { ScenarioError } from "../harness/scenario.mjs";
import { mountBaselines } from "./mount-baselines.mjs";
import { CorpusError, idOf, routeOf } from "./routes.mjs";

const registered = (...routes) => routes.map((route) => ({ route, file: `/vendored${route.slice(1)}` }));

test("a registry key becomes the page's hash route", () => {
  assert.equal(routeOf("./nodes/general.ts"), "/tests/generic/nodes/general");
  assert.equal(routeOf("./pane/non-defaults.ts"), "/tests/generic/pane/non-defaults");
});

// Semantic, never a sequence number: a gate cites scenarios by name, and a
// number moves the moment the corpus is trimmed.
test("a fixture's path flattens into a semantic scenario id", () => {
  assert.equal(idOf("./nodes/general.ts"), "mount-baseline--nodes-general");
  assert.equal(idOf("./node-toolbar/general.ts"), "mount-baseline--node-toolbar-general");
  assert.equal(idOf("./pane/non-defaults.ts"), "mount-baseline--pane-non-defaults");
});

// Derived rather than written down, which is what makes "mount-only is a
// general rule for every fixture" structural: adding a fixture adds its
// baseline, and there is no second list to forget.
test("every registered fixture gets a baseline, in registry order", () => {
  const scenarios = mountBaselines(registered("./nodes/general.ts", "./edges/general.ts"));

  assert.deepEqual(
    scenarios.map((s) => [s.id, s.route]),
    [
      ["mount-baseline--nodes-general", "/tests/generic/nodes/general"],
      ["mount-baseline--edges-general", "/tests/generic/edges/general"],
    ]
  );
});

// The cheapest scenario there is, and the point of this milestone: no action
// vocabulary at all. A baseline that drove something would be a scenario the
// corpus ticket owns, arriving early and unreviewed.
test("a baseline drives nothing — it mounts, settles and is captured", async () => {
  const [scenario] = mountBaselines(registered("./nodes/general.ts"));
  let reached = false;

  await scenario.run(
    new Proxy(
      {},
      {
        get() {
          reached = true;
          throw new Error("a mount-only baseline reached for the action vocabulary");
        },
      }
    )
  );

  assert.equal(reached, false);
  assert.equal(scenario.touch, false);
});

// The registry guards routes; two paths can still flatten onto one id. Left
// alone the second scenario's traces would land on the first's file names, and
// the run would compare one fixture against another and report the difference
// as a library divergence.
test("two fixtures that flatten onto one id fail rather than sharing trace files", () => {
  assert.throws(() => mountBaselines(registered("./a/b-c.ts", "./a-b/c.ts")), (e) => {
    assert.ok(e instanceof CorpusError);
    assert.match(e.message, /mount-baseline--a-b-c/);
    assert.match(e.message, /\.\/a\/b-c\.ts/);
    assert.match(e.message, /\.\/a-b\/c\.ts/);
    return true;
  });
});

// `defineScenario` is what holds the id to the naming rule, and deriving ids
// does not get to bypass it.
test("a fixture whose name could not be a scenario id is refused by defineScenario", () => {
  assert.throws(() => mountBaselines(registered("./Nodes/General.ts")), ScenarioError);
});
