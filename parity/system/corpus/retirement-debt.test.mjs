import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { routeSpace } from "../../driver/registry.mjs";
import { CorpusError, assertRetirementsResolve, buildCorpus } from "./index.mjs";
import { RETIREMENTS, retiredTestProblems, retirementDebtScenarios } from "./retirement-debt.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(here, "..", "..", "..");
const SPEC_DIR = join(repoRoot, "examples", "react-smoke", "tests");

// The real registry, not a synthetic one. The register's whole claim is about
// the corpus the net actually drives: a citation that resolves against a corpus
// assembled for a test says nothing about the one the gate builds.
const realCorpus = () => {
  const { fixtures, components } = routeSpace(repoRoot);
  return buildCorpus(fixtures, components);
};

const specSource = (spec) => {
  const path = join(SPEC_DIR, spec);
  return existsSync(path) ? readFileSync(path, "utf8") : null;
};

// The two liveness tests are what the smoke suite is *for* after the
// retirement, and nothing else in this file would notice them going: a
// retirement register only ever says what left.
const LIVENESS = ["the driver page mounts and renders its fixture", "no console errors during a 5-second interaction session"];

test("every retirement names a scenario the real corpus holds", () => {
  const corpus = realCorpus();
  const written = new Set(corpus.map((scenario) => scenario.id));

  for (const { spec, test: title, scenarios } of RETIREMENTS) {
    assert.ok(scenarios.length > 0, `${spec} — ${title}: retired with no scenario named`);
    for (const id of scenarios) {
      assert.ok(written.has(id), `${spec} — ${title}: cites ${id}, which the corpus does not hold`);
    }
  }
});

// The falsification the check above is worth nothing without: a green result is
// equally what a resolver that inspects nothing would produce.
test("a citation the corpus does not hold fails", () => {
  const corpus = realCorpus().filter((scenario) => scenario.id !== "minimap-default-click");

  assert.throws(
    () => assertRetirementsResolve(corpus),
    (error) => error instanceof CorpusError && /minimap-default-click/.test(error.message)
  );
});

test("no retired test is still in the spec that held it", () => {
  assert.deepEqual(retiredTestProblems(specSource), []);
});

test("a spec that still holds a retired title is reported", () => {
  const problems = retiredTestProblems((spec) =>
    spec === "smoke.spec.ts" ? 'test("node drag fires onNodesChange", async () => {});' : null
  );

  assert.equal(problems.length, 1);
  assert.match(problems[0], /smoke\.spec\.ts still holds the retired test "node drag fires onNodesChange"/);
});

// Per test rather than per file is the whole shape of this register, and this
// is what it buys: `node-props.spec.ts` retired whole and `smoke.spec.ts` did
// not, and the file that survived kept exactly the two tests that are not
// parity assertions.
test("the smoke spec retired eight tests and kept its two liveness ones", () => {
  const source = specSource("smoke.spec.ts");
  assert.ok(source !== null, "smoke.spec.ts is the liveness suite and does not retire");

  const smoke = RETIREMENTS.filter((retirement) => retirement.spec === "smoke.spec.ts");
  assert.equal(smoke.length, 8);
  for (const title of LIVENESS) assert.ok(source.includes(title), `smoke.spec.ts no longer holds ${title}`);
});

test("the node-props spec retired whole", () => {
  assert.equal(specSource("node-props.spec.ts"), null);
  assert.equal(RETIREMENTS.filter((retirement) => retirement.spec === "node-props.spec.ts").length, 2);
});

test("every retirement-debt scenario is cited by a retirement", () => {
  const cited = new Set(RETIREMENTS.flatMap(({ scenarios }) => scenarios));
  for (const { id } of retirementDebtScenarios) {
    assert.ok(cited.has(id), `${id} is written as retirement debt and retires nothing`);
  }
});
