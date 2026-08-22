import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import {
  FORKED_SPECS,
  ForkError,
  OUTCOME,
  affirmFork,
  extractUnits,
  forkOutcomes,
  hashOf,
  readUnits,
  renderForkFailures,
  validateFork,
} from "./fork.mjs";
import { seedScenarios } from "./seed.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..", "..");

const register = JSON.parse(readFileSync(join(here, "fork.json"), "utf8"));

const SPEC = `
import { test, expect } from '@playwright/test';

test.describe('Nodes', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/tests/generic/nodes/general');
  });

  test.describe('dragging', () => {
    test('dragging a node', async ({ page }) => {
      await page.mouse.down();
    });

    test.skip('a skipped one is still a test', async ({ page }) => {});
  });

  test('classes get applied', async ({ page }) => {});
});
`;

const titles = (units) => units.map((u) => u.test);

// ── Extraction ─────────────────────────────────────────────────────────────

test("a unit's name is the describes it sits under, then itself", () => {
  assert.deepEqual(titles(extractUnits("a.spec.ts", SPEC)), [
    "Nodes > beforeEach",
    "Nodes > dragging > dragging a node",
    "Nodes > dragging > a skipped one is still a test",
    "Nodes > classes get applied",
  ]);
});

// A hook is a unit because upstream's `goto` lives in one. A bump that moved a
// fixture's route would change no test's text at all, and every scenario in
// that describe would quietly start mounting a 404.
test("a hook is registered like a test, so a moved route cannot pass silently", () => {
  const [hook] = extractUnits("a.spec.ts", SPEC);
  const moved = extractUnits("a.spec.ts", SPEC.replace("nodes/general", "nodes/renamed"));

  assert.equal(hook.test, "Nodes > beforeEach");
  assert.notEqual(hook.hash, moved[0].hash);
  assert.deepEqual(
    moved.slice(1).map((u) => u.hash),
    extractUnits("a.spec.ts", SPEC).slice(1).map((u) => u.hash),
    "no test's own text changed"
  );
});

// A modifier says how a test runs, not what it is. A skipped test is still a
// test the fork has to decide about — and one that upstream un-skips in a bump
// should not read as a brand new test either.
test("a modifier does not change what a call is", () => {
  const plain = extractUnits("a.spec.ts", SPEC.replace("test.skip(", "test("));

  assert.ok(titles(plain).includes("Nodes > dragging > a skipped one is still a test"));
});

test("the hash ignores line endings and nothing else", () => {
  assert.equal(hashOf("test('a', () => {});\n"), hashOf("test('a', () => {});\r\n"));
  assert.notEqual(hashOf("test('a', () => {});"), hashOf("test('b', () => {});"));
});

// Two units under one name would be indistinguishable in the register: an entry
// would claim whichever the extraction reached first, and the other would read
// as unregistered forever.
test("two units under one name fail rather than one being unregisterable", () => {
  const twice = SPEC.replace("test('classes get applied'", "test('dragging a node'").replace(
    "test.describe('dragging', () => {",
    ""
  );

  assert.throws(() => extractUnits("a.spec.ts", twice.replace("});\n\n  test('dragging a node'", "\n  test('dragging a node'")), ForkError);
});

// ── The register's shape ───────────────────────────────────────────────────

const entry = (over = {}) => ({
  spec: "a.spec.ts",
  test: "Nodes > dragging > dragging a node",
  hash: hashOf("x"),
  scenarios: ["drag-moves-node"],
  affirmedAgainst: "12.11.0",
  ...over,
});

test("an entry needs a spec, a test, a hash and the baseline it was affirmed against", () => {
  for (const field of ["spec", "test", "hash", "affirmedAgainst"]) {
    assert.throws(() => validateFork([entry({ [field]: "" })]), ForkError, field);
  }
});

// The rule with an argument behind it: `scenarios: []` is how "covered by the
// fixture's mount-only baseline" and "nobody got round to it" both look, and
// telling those apart is the whole value of the register.
test("an entry that lifts nothing needs a written reason", () => {
  assert.throws(() => validateFork([entry({ scenarios: [] })]), (e) => {
    assert.ok(e instanceof ForkError);
    assert.match(e.message, /reason/);
    return true;
  });

  assert.doesNotThrow(() => validateFork([entry({ scenarios: [], reason: "covered by the baseline" })]));
});

test("two entries for one unit fail", () => {
  assert.throws(() => validateFork([entry(), entry()]), ForkError);
});

// ── Outcomes ───────────────────────────────────────────────────────────────

const units = [
  { spec: "a.spec.ts", test: "Nodes > dragging > dragging a node", hash: hashOf("x") },
  { spec: "a.spec.ts", test: "Nodes > beforeEach", hash: hashOf("goto") },
];

const outcomes = (entries, over = {}) =>
  forkOutcomes(entries, units, { scenarioIds: ["drag-moves-node"], seedIds: ["drag-moves-node"], ...over });

test("a unit whose source is the one the entry recorded is affirmed", () => {
  const result = outcomes([entry(), entry({ test: "Nodes > beforeEach", hash: hashOf("goto") })]);

  assert.deepEqual(result.entries.map((e) => e.outcome), [OUTCOME.affirmed, OUTCOME.affirmed]);
  assert.equal(result.ok, true);
});

// The hazard the whole register exists for. A bump rewrites the spec, the
// lifted scenario keeps driving, both sides keep answering, and nothing at all
// says the scenario no longer corresponds to what upstream now tests.
test("a forked spec that changed fails, naming the scenarios to re-affirm", () => {
  const result = outcomes([entry({ hash: hashOf("what it used to say") }), entry({ test: "Nodes > beforeEach", hash: hashOf("goto") })]);

  assert.equal(result.entries[0].outcome, OUTCOME.moved);
  assert.equal(result.ok, false);
  assert.match(renderForkFailures(result).join("\n"), /re-affirming/);
  assert.match(renderForkFailures(result).join("\n"), /drag-moves-node/);
});

test("an entry naming a unit the spec no longer holds is stale", () => {
  const result = outcomes([entry({ test: "Nodes > dragging > a test that was deleted" }), entry({ test: "Nodes > beforeEach", hash: hashOf("goto") })]);

  assert.equal(result.entries[0].outcome, OUTCOME.stale);
  assert.equal(result.ok, false);
});

// What a bump that *adds* a test looks like. Deciding not to lift one is a
// decision the register records rather than an omission it tolerates.
test("a unit no entry names fails as unregistered", () => {
  const result = outcomes([entry()]);

  assert.deepEqual(result.unregistered.map((u) => u.test), ["Nodes > beforeEach"]);
  assert.equal(result.ok, false);
  assert.match(renderForkFailures(result).join("\n"), /Nodes > beforeEach/);
});

test("an entry naming a scenario the corpus does not hold fails", () => {
  const result = outcomes(
    [entry({ scenarios: ["drag-moves-node", "a-scenario-that-was-renamed"] }), entry({ test: "Nodes > beforeEach", hash: hashOf("goto") })],
    { scenarioIds: ["drag-moves-node"] }
  );

  assert.deepEqual(result.entries[0].dangling, ["a-scenario-that-was-renamed"]);
  assert.equal(result.ok, false);
});

// The seed is defined as a fork, so a scenario with no origin recorded is one
// whose drift nothing can detect.
test("a seed scenario no entry names fails as unlifted", () => {
  const result = outcomes([entry(), entry({ test: "Nodes > beforeEach", hash: hashOf("goto") })], {
    seedIds: ["drag-moves-node", "a-scenario-nobody-forked"],
  });

  assert.deepEqual(result.unlifted, ["a-scenario-nobody-forked"]);
  assert.equal(result.ok, false);
});

// ── Affirming ──────────────────────────────────────────────────────────────

test("affirming restamps a moved entry's hash and baseline", () => {
  const entries = [entry({ hash: hashOf("old") }), entry({ test: "Nodes > beforeEach", hash: hashOf("goto") })];
  const [restamped, untouched] = affirmFork(entries, outcomes(entries), "12.12.0");

  assert.equal(restamped.hash, hashOf("x"));
  assert.equal(restamped.affirmedAgainst, "12.12.0");
  assert.equal(untouched.affirmedAgainst, "12.11.0", "an affirmed entry is not restamped");
});

// The same line `recordRegions` draws: re-recording what a decision already
// covers is cheap, and making the decision is a reviewed change to the file.
test("affirming cannot create an entry or delete one", () => {
  const entries = [entry({ test: "Nodes > dragging > a test that was deleted" })];
  const after = affirmFork(entries, outcomes(entries), "12.12.0");

  assert.equal(after.length, 1);
  assert.equal(after[0].test, "Nodes > dragging > a test that was deleted");
  assert.equal(forkOutcomes(after, units, { scenarioIds: ["drag-moves-node"] }).entries[0].outcome, OUTCOME.stale);
});

// ── The committed register, against the vendored specs ─────────────────────

test("every forked spec is in the vendored tree", () => {
  assert.deepEqual(
    FORKED_SPECS.map((spec) => spec.replace("xyflow/tests/playwright/e2e/", "")).sort(),
    ["edges.spec.ts", "node-toolbar.spec.ts", "nodes.spec.ts", "pane.spec.ts", "props.spec.ts"]
  );
  assert.equal(readUnits(repoRoot).length > 0, true);
});

test("the committed register is affirmed against the vendored specs", () => {
  const result = forkOutcomes(register.forked, readUnits(repoRoot), {
    scenarioIds: seedScenarios.map((s) => s.id),
    seedIds: seedScenarios.map((s) => s.id),
  });

  assert.deepEqual(renderForkFailures(result), []);
  assert.equal(result.ok, true);
});

// A green gate is equally what a gate that reads nothing would produce, so the
// same machinery is shown to go red. `parity/boundary/drift.mjs` and
// `Test.Parity.Util` name their runners `falsify` for the same reason.
//
// One digit, and exactly one entry moves. That precision is the point of
// hashing per unit rather than per file: a bump that rewrites one test asks for
// one scenario to be re-affirmed, not for the whole spec's worth.
test("falsify: a single edited character in a forked spec fails the register", () => {
  const spec = FORKED_SPECS.find((s) => s.endsWith("nodes.spec.ts"));
  const source = readFileSync(resolve(repoRoot, spec), "utf8");
  const tampered = source.replace("await page.mouse.move(500, 500);", "await page.mouse.move(500, 501);");
  assert.notEqual(tampered, source, "the line the probe edits is still in upstream's spec");

  const units = readUnits(repoRoot).filter((u) => u.spec !== spec).concat(extractUnits(spec, tampered));
  const result = forkOutcomes(register.forked, units, {
    scenarioIds: seedScenarios.map((s) => s.id),
    seedIds: seedScenarios.map((s) => s.id),
  });

  assert.equal(result.ok, false);
  assert.deepEqual(
    result.entries.filter((e) => e.outcome === OUTCOME.moved).map((e) => e.test),
    ["Nodes > dragging > dragging a node"]
  );
});
