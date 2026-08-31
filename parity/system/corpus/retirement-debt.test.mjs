import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { routeSpace } from "../../driver/registry.mjs";
import { CorpusError, buildCorpus } from "./index.mjs";
import {
  LIVENESS,
  RETIREMENTS,
  assertRetirementsResolve,
  retiredTestProblems,
  retirementDebtScenarios,
} from "./retirement-debt.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(here, "..", "..", "..");
const SPEC_DIR = join(repoRoot, "examples", "react-smoke", "tests");
const TRACES = join(repoRoot, "parity", "system", "traces");

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

const trace = (scenario, side) => {
  const path = join(TRACES, `${scenario}.${side}.capture1.json`);
  return existsSync(path) ? JSON.parse(readFileSync(path, "utf8")) : null;
};

test("every retirement names a scenario the real corpus holds", () => {
  assert.deepEqual(assertRetirementsResolve(realCorpus()).length > 0, true);
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

// What `section` buys over the citation. A name that resolves says a scenario
// exists; this says the scenario does the work where the register claims it
// does — on both sides, since a section only one side recorded is not a
// comparison. Read off the stored traces, so it is a fact about a run that
// happened rather than a second declaration.
test("every retirement's scenario recorded something in the section it retires into", () => {
  for (const { spec, test: title, section, scenarios } of RETIREMENTS) {
    for (const id of scenarios) {
      for (const side of ["upstream", "psflow"]) {
        const captured = trace(id, side);
        assert.ok(captured, `${spec} — ${title}: ${id} has no stored ${side} trace`);
        const observed = captured.sections[section];
        const empty = observed === null || (Array.isArray(observed) ? observed.length === 0 : Object.keys(observed).length === 0);
        assert.ok(!empty, `${spec} — ${title}: ${id}'s ${side} trace has nothing in \`${section}\``);
      }
    }
  }
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
// not, and the file that survived kept exactly the two tests that were never
// parity assertions.
test("the smoke spec retired eight tests and kept its two liveness ones", () => {
  const source = specSource("smoke.spec.ts");
  assert.ok(source !== null, "smoke.spec.ts is the liveness suite and does not retire");

  const retired = RETIREMENTS.filter((retirement) => retirement.spec === "smoke.spec.ts");
  const live = LIVENESS.filter((entry) => entry.spec === "smoke.spec.ts");
  assert.equal(retired.length, 8);
  assert.equal(live.length, 2);

  // Ten titles went in and ten are accounted for. Without `LIVENESS` a renamed
  // survivor would read as a title that is neither retired nor present, which
  // is exactly the reading "no coverage is lost" has to rule out.
  assert.equal(retired.length + live.length, 10);
  for (const { test: title } of live) assert.ok(source.includes(title), `smoke.spec.ts no longer holds ${title}`);
});

test("the node-props spec retired whole", () => {
  assert.equal(specSource("node-props.spec.ts"), null);
  assert.equal(RETIREMENTS.filter((retirement) => retirement.spec === "node-props.spec.ts").length, 2);
  assert.equal(LIVENESS.filter((entry) => entry.spec === "node-props.spec.ts").length, 0);
});

test("every retirement-debt scenario is cited by a retirement", () => {
  const cited = new Set(RETIREMENTS.flatMap(({ scenarios }) => scenarios));
  for (const { id } of retirementDebtScenarios) {
    assert.ok(cited.has(id), `${id} is written as retirement debt and retires nothing`);
  }
});
