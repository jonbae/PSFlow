// The fork staleness gate — the command (`npm run parity:fork`, #55).
//
//   node parity/system/fork.mjs [--affirm]
//
//     --affirm  restamp the entries whose forked spec **moved** with its new
//               hash and this checkout's baseline. It cannot create an entry
//               and it cannot delete one: a test a bump added stays
//               unregistered, and an entry whose test is gone stays stale,
//               until someone writes down what to do about it. The same line
//               `compare.mjs --record` draws for regions, in the same place.
//
// The mechanism, the five outcomes and why the seed is a fork rather than a
// mirror are all in `corpus/fork.mjs`; this file reads the vendored specs, the
// register and the corpus, and says what it found.
//
// It runs standalone and it runs as `net.mjs`'s first step, which is where it
// earns its keep: capturing a hundred and twenty traces against a corpus whose
// relation to upstream is in question produces an artifact that has to be
// thrown away once the question is answered. `--compare-only` skips it, because
// re-diffing stored traces needs no vendored checkout at all.
//
// Exit codes: 0 the register is affirmed, 1 it is not, 2 it could not be read —
// a missing vendored spec, a malformed entry, a spec whose units cannot be told
// apart.

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { collectComponents, collectFixtures, directComponents, fixtureRoots } from "../driver/registry.mjs";
import { buildCorpus } from "./corpus/index.mjs";
import {
  ForkError,
  affirmFork,
  forkOutcomes,
  readUnits,
  renderForkFailures,
  renderForkSummary,
} from "./corpus/fork.mjs";
import { seedScenarios } from "./corpus/seed.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

export const FORK_REGISTER = join(here, "corpus", "fork.json");

const readJson = (path) => JSON.parse(readFileSync(path, "utf8"));

/**
 * Reads the register against the vendored specs and the corpus.
 *
 * Exported so `net.mjs` runs the same check this command does, rather than a
 * second reading of the same files that could drift from it.
 */
export const checkFork = () => {
  const register = readJson(FORK_REGISTER);
  const corpus = buildCorpus(collectFixtures(fixtureRoots(repoRoot)), collectComponents(directComponents(repoRoot)));

  return {
    register,
    outcomes: forkOutcomes(register.forked, readUnits(repoRoot), {
      scenarioIds: corpus.map((s) => s.id),
      seedIds: seedScenarios.map((s) => s.id),
    }),
  };
};

/** The gate's own words, so `net.mjs` says exactly what the command says. */
export const reportFork = (outcomes) =>
  outcomes.ok ? renderForkSummary(outcomes) : ["the fork register is not affirmed.", ...renderForkFailures(outcomes)].join("\n");

const main = () => {
  const affirming = process.argv.slice(2).includes("--affirm");
  const { register, outcomes } = checkFork();

  if (affirming) {
    const baseline = readJson(join(repoRoot, "xyflow/packages/react/package.json")).version;
    const forked = affirmFork(register.forked, outcomes, baseline);
    const restamped = forked.filter((entry, i) => entry !== register.forked[i]);

    if (!restamped.length) {
      console.log("nothing moved — no entry needed re-affirming.");
    } else {
      writeFileSync(FORK_REGISTER, JSON.stringify({ ...register, forked }, null, 2) + "\n");
      console.log(
        `re-affirmed ${restamped.length} entr(ies) against ${baseline}:\n` +
          restamped.map((e) => `  ${e.test}\n    lifted: ${e.scenarios.join(", ") || "(nothing)"}`).join("\n") +
          `\nRead each one's new spec before you commit this: re-affirming says the lifted scenario still ` +
          `drives what it should, and nothing here checked that.`
      );
    }

    // Re-read, so what is reported is the register as it now stands. An entry
    // that was stale or unregistered is untouched by affirming and still fails.
    const { outcomes: after } = checkFork();
    console.log(reportFork(after));
    return after.ok ? 0 : 1;
  }

  console.log(reportFork(outcomes));
  return outcomes.ok ? 0 : 1;
};

if (resolve(process.argv[1] ?? "") === resolve(fileURLToPath(import.meta.url))) {
  try {
    process.exit(main());
  } catch (e) {
    console.error(e instanceof ForkError || e instanceof SyntaxError ? e.message : e);
    process.exit(2);
  }
}
