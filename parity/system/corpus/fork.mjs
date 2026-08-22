// The fork staleness gate — what keeps the conformance seed honest (#55).
//
// The seed is a **one-time fork of upstream's own end-to-end suite**, and
// deliberately not a mirror. A spec asserts upstream's expectations against
// ps-flow alone; the scenario lifted from it drives both sides and asserts
// nothing. Drift between the two is legitimate, and re-syncing them would be
// the wrong instinct — the scenario is allowed to have moved on.
//
// **Silent drift is not legitimate.** A baseline bump that rewrites one of
// those specs leaves the lifted scenario untouched, and the scenario goes stale
// with nothing whatever to notice: it still drives, both sides still answer,
// the trace still compares. This is the first bump cost on the map with no
// mechanical detector, and it is built here because the seed is what creates
// the hazard.
//
// ## What is registered
//
// Every **unit** of upstream source the seed depends on, against a hash of that
// source and the scenarios that depend on it. There are two kinds.
//
// **The forked specs**, per `test` and per `beforeEach`-style hook. Hooks are
// units because upstream's `goto` lives in one: a bump that moved a fixture's
// route would change no test's text at all, and every scenario in that describe
// would quietly start mounting a 404.
//
// **The sources the seed reads an assumption out of**, hashed whole — the four
// vendored fixtures and the **example driver**. These are not forked; both sides
// mount them unmodified, so a change to one is symmetric and lands in the trace
// diff. What is *not* symmetric is that the transcription reads them. Upstream's
// `selectOption({ label: 'dark' })` names the option; `select-dark-color-mode`
// presses ArrowDown once, because `selectOption` is not an input event and has
// no place in the closed primitive tier — so the option *order* in
// `ColorMode/index.tsx` is part of that scenario, and a bump reordering it would
// drive `system` with every spec hash still affirmed. `.react-flow__node`
// first-match, `deleteKeyCode: 'd'`, `interactionWidth: 42` and `minZoom: 0.25`
// are the same shape in the four fixtures. They have no unit structure a
// scenario cites, so the whole file is the unit.
//
// Five outcomes, and only the first passes:
//
//   * **affirmed** — the unit's source is the one the entry recorded
//   * **moved** — it changed, and the scenarios lifted from it must be
//     **re-affirmed**: read the new spec, decide whether the scenario still
//     drives what it should, and stamp the new hash. Never re-synced.
//   * **stale** — the entry names a unit that is no longer in the spec, which
//     is the same inversion every register in this repo uses: entries bite when
//     they stop corresponding to reality
//   * **unregistered** — the spec holds a unit no entry names, which is what a
//     bump that *adds* a test looks like. Left alone it would be a test nobody
//     decided about, and deciding not to lift one is a decision this file
//     records rather than an omission it tolerates.
//   * **unlifted** — a seed scenario no entry names. The seed is defined as a
//     fork, so a scenario with no origin is one whose drift nothing can detect.
//
// A **not-lifted** entry — `scenarios: []` — is the ordinary case rather than
// an exception: most of the forty-three tests assert one attribute of a static
// render, and their fixture's mount-only baseline compares the whole DOM and
// covers them all at once. It carries a written reason, exactly as a region
// does, and for the same purpose: the decision is legible and reviewable, and
// it is what stops "we did not get round to it" from wearing the same clothes
// as "this one is covered".
//
// ## Hashing, and what it is deliberately blind to
//
// The unit's source text, line endings normalized and nothing else. Not the
// interactions it drives — extracting *those* would be a second implementation
// of the transcription, and one that could only ever be as right as the reading
// that produced the scenario. The hash asks a smaller and answerable question:
// **did this change at all?** A reformat re-affirms everything, which is a
// cheap false positive; a rewritten drag that no hash noticed would be an
// expensive false negative.

import ts from "typescript";
import { createHash } from "node:crypto";
import { readFileSync, statSync } from "node:fs";
import { resolve } from "node:path";

export class ForkError extends Error {
  constructor(message) {
    super(message);
    this.name = "ForkError";
  }
}

/**
 * The spec files the seed was lifted from, repo-relative.
 *
 * Four are the `generic-*` suites driving the vendored fixtures; `props.spec.ts`
 * drives the **example driver** instead, because upstream ships no props
 * fixture to twin. Written down rather than globbed: a file appearing under
 * `e2e/` that this list does not name is upstream growing a suite, which is a
 * decision to take rather than scenery to absorb. `readUnits` fails on one of
 * these going missing, for the same reason.
 */
export const FORKED_SPECS = [
  "xyflow/tests/playwright/e2e/edges.spec.ts",
  "xyflow/tests/playwright/e2e/node-toolbar.spec.ts",
  "xyflow/tests/playwright/e2e/nodes.spec.ts",
  "xyflow/tests/playwright/e2e/pane.spec.ts",
  "xyflow/tests/playwright/e2e/props.spec.ts",
];

/**
 * What happened to one *entry*. The other two failures in the list above —
 * *unregistered* and *unlifted* — belong to no entry by construction: one is a
 * unit with no entry and the other a scenario with no entry, so they ride
 * beside this on `forkOutcomes`' result rather than in it.
 */
export const OUTCOME = Object.freeze({
  affirmed: "affirmed",
  moved: "moved",
  stale: "stale",
});

/**
 * The `test` an entry carries when its whole file is the unit.
 *
 * Deliberately not a title a test could have: the register keys on
 * `spec` + `test`, and a real test called "(the whole file)" would collide with
 * the file's own entry and one of the two would read as unregistered forever.
 */
export const WHOLE_FILE = "(the whole file)";

// Playwright's runners, its suites, and the hooks that carry a `goto`. A
// modifier between them and the call — `test.describe.only`, `test.skip` — says
// how the test runs, not what it is, so it is stripped before classifying. A
// skipped test is still a test the fork has to decide about.
const RUNNERS = new Set(["test", "it"]);
const HOOKS = new Set(["beforeEach", "beforeAll", "afterEach", "afterAll"]);
const MODIFIERS = new Set(["only", "skip", "fixme", "fail", "slow", "serial", "parallel"]);

/** `test.describe.only` → `["test", "describe", "only"]`, or null for anything else. */
const chainOf = (expression) => {
  const parts = [];
  let node = expression;
  while (ts.isPropertyAccessExpression(node)) {
    parts.unshift(node.name.text);
    node = node.expression;
  }
  if (!ts.isIdentifier(node)) return null;
  parts.unshift(node.text);
  return parts;
};

const classify = (expression) => {
  const chain = chainOf(expression);
  if (!chain) return null;

  while (chain.length > 1 && MODIFIERS.has(chain.at(-1))) chain.pop();

  const [head] = chain;
  const tail = chain.at(-1);

  if (chain.length === 1 && RUNNERS.has(head)) return { kind: "test" };
  if (tail === "describe" && (RUNNERS.has(head) || chain.length === 1)) return { kind: "suite" };
  if (HOOKS.has(tail) && (RUNNERS.has(head) || chain.length === 1)) return { kind: "hook", name: tail };
  return null;
};

const titleOf = (call) => {
  const [first] = call.arguments;
  return first && ts.isStringLiteralLike(first) ? first.text : null;
};

/** How a unit is named in the register: the describes it sits under, then itself. */
export const TITLE_SEPARATOR = " > ";

export const hashOf = (text) =>
  `sha256:${createHash("sha256").update(text.replace(/\r\n/g, "\n"), "utf8").digest("hex")}`;

/**
 * Every test and hook in one spec file, as `{ spec, test, hash }`.
 *
 * `spec` is whatever path the caller passes, so a register entry and an
 * extraction agree on it without either resolving a checkout.
 *
 * Syntax only — `ts.createSourceFile`, no program and no checker. What is being
 * read is which call is a test and what its source says, and neither is a
 * question about types.
 */
export const extractUnits = (spec, source) => {
  const file = ts.createSourceFile(spec, source, ts.ScriptTarget.ESNext, true, ts.ScriptKind.TS);
  const units = [];

  const walk = (node, path) => {
    if (ts.isCallExpression(node)) {
      const what = classify(node.expression);

      if (what?.kind === "suite") {
        const title = titleOf(node);
        const body = node.arguments.at(-1);
        if (title !== null && body) return walk(body, [...path, title]);
      }
      if (what?.kind === "test") {
        const title = titleOf(node);
        if (title !== null) {
          units.push({ spec, test: [...path, title].join(TITLE_SEPARATOR), hash: hashOf(node.getText()) });
          return;
        }
      }
      if (what?.kind === "hook") {
        units.push({ spec, test: [...path, what.name].join(TITLE_SEPARATOR), hash: hashOf(node.getText()) });
        return;
      }
    }
    ts.forEachChild(node, (child) => walk(child, path));
  };

  walk(file, []);

  // Two units under one name would be indistinguishable in the register: an
  // entry would claim whichever the extraction happened to reach first, and the
  // other would read as unregistered forever. Upstream writes one hook per
  // describe and no two tests share a title, so this fires only on a bump that
  // changed that — which is a change worth a person looking at.
  const seen = new Set();
  for (const { test } of units) {
    if (seen.has(test)) {
      throw new ForkError(
        `${spec} holds two units named ${JSON.stringify(test)}. The register names a unit by its title, ` +
          `so one of the two could never be registered. Give them different titles in a comment beside ` +
          `the entry, or narrow the fork.`
      );
    }
    seen.add(test);
  }

  return units;
};

const readSource = (repoRoot, spec, why) => {
  const file = resolve(repoRoot, spec);
  if (!statSync(file, { throwIfNoEntry: false })?.isFile()) {
    throw new ForkError(
      `no ${why} at ${file}. The conformance seed depends on it, so its absence means either the ` +
        `vendored tree needs re-vendoring or a baseline bump moved it — and the second is a decision, ` +
        `not something to route around.`
    );
  }
  return readFileSync(file, "utf8");
};

/**
 * Every unit the register covers: each spec's tests and hooks, then one
 * whole-file unit per source the seed reads an assumption out of.
 *
 * `sources` are repo-relative paths. They are passed in rather than listed here
 * because they are *derived* — the vendored fixture root and the example
 * drivers, from the driver's own registries — and deriving them here would make
 * this module depend on the driver to answer a question about upstream's specs.
 * `parity/system/fork.mjs` is where the two are wired together, which is the
 * one place in the net that already does wiring.
 */
export const readUnits = (repoRoot, { specs = FORKED_SPECS, sources = [] } = {}) => [
  ...specs.flatMap((spec) => extractUnits(spec, readSource(repoRoot, spec, "forked spec"))),
  ...sources.map((spec) => ({
    spec,
    test: WHOLE_FILE,
    hash: hashOf(readSource(repoRoot, spec, "depended-on source")),
  })),
];

/**
 * Checks the register's shape. Throws `ForkError`; nothing here is a finding.
 *
 * The one rule with an argument behind it is the last: **a not-lifted entry
 * needs a written reason.** `scenarios: []` is how "covered by the fixture's
 * mount-only baseline" and "nobody got round to it" both look, and the whole
 * value of the register is telling those apart.
 */
export const validateFork = (entries) => {
  if (!Array.isArray(entries)) throw new ForkError("the fork register must be an array");

  const seen = new Set();
  entries.forEach((entry, i) => {
    const at = `fork entry ${i} (${entry?.test ?? "no test"})`;
    for (const field of ["spec", "test", "hash", "affirmedAgainst"]) {
      if (typeof entry?.[field] !== "string" || entry[field] === "") throw new ForkError(`${at}: needs a ${field}`);
    }
    if (!entry.hash.startsWith("sha256:")) throw new ForkError(`${at}: hash is not a sha256`);
    if (!Array.isArray(entry.scenarios)) throw new ForkError(`${at}: scenarios must be an array`);

    const key = `${entry.spec}${TITLE_SEPARATOR}${entry.test}`;
    if (seen.has(key)) throw new ForkError(`${at}: duplicate entry`);
    seen.add(key);

    if (entry.scenarios.length === 0 && (typeof entry.reason !== "string" || entry.reason === "")) {
      throw new ForkError(
        `${at}: lifts no scenario and gives no reason. "covered by the fixture's mount-only baseline" ` +
          `and "nobody got round to it" look identical without one, and telling those apart is what this ` +
          `register is for.`
      );
    }
  });

  return entries;
};

const keyOf = ({ spec, test }) => `${spec}${TITLE_SEPARATOR}${test}`;

/**
 * The register read against the specs it forked and the corpus it names.
 *
 * `scenarioIds` are the ids the corpus actually holds — every scenario, not
 * only the seed's, because an entry is free to name a scenario from any source.
 * `seedIds` are the lifted ones, which are the only ones that *must* be named.
 */
export const forkOutcomes = (entries, units, { scenarioIds = [], seedIds = [] } = {}) => {
  validateFork(entries);

  const byKey = new Map(units.map((unit) => [keyOf(unit), unit]));
  const known = new Set(scenarioIds);
  const named = new Set(entries.flatMap((entry) => entry.scenarios));

  const registered = entries.map((entry) => {
    const unit = byKey.get(keyOf(entry));
    const outcome = !unit ? OUTCOME.stale : unit.hash === entry.hash ? OUTCOME.affirmed : OUTCOME.moved;
    const dangling = entry.scenarios.filter((id) => !known.has(id));

    return { ...entry, outcome, found: unit?.hash ?? null, dangling };
  });

  const claimed = new Set(entries.map(keyOf));

  return {
    entries: registered,
    unregistered: units.filter((unit) => !claimed.has(keyOf(unit))),
    unlifted: seedIds.filter((id) => !named.has(id)),
    get ok() {
      return (
        this.entries.every((e) => e.outcome === OUTCOME.affirmed && e.dangling.length === 0) &&
        this.unregistered.length === 0 &&
        this.unlifted.length === 0
      );
    },
  };
};

/**
 * Re-affirmed entries: the ones whose unit moved get the new hash and this
 * baseline's stamp.
 *
 * **It cannot create an entry and it cannot delete one.** That is the same line
 * `recordRegions` draws and it is drawn in the same place: re-recording what a
 * decision already covers is cheap, and making the decision is a reviewed
 * change to the file. A test that appeared in a bump stays unregistered until
 * someone writes down what to do about it, and an entry whose test is gone
 * stays stale until someone reads why.
 */
export const affirmFork = (entries, outcomes, baseline) => {
  const moved = new Map(
    outcomes.entries.filter((e) => e.outcome === OUTCOME.moved).map((e) => [keyOf(e), e.found])
  );

  return entries.map((entry) =>
    moved.has(keyOf(entry)) ? { ...entry, hash: moved.get(keyOf(entry)), affirmedAgainst: baseline } : entry
  );
};

/** What went wrong, as lines. Empty when the register is clean. */
export const renderForkFailures = (outcomes) => {
  const said = [];

  const moved = outcomes.entries.filter((e) => e.outcome === OUTCOME.moved);
  if (moved.length) {
    said.push(
      `${moved.length} forked spec(s) changed. The scenarios lifted from them need **re-affirming**, not`,
      `re-syncing: read the new spec, decide whether the scenario still drives what it should, and stamp`,
      `the new hash with \`node parity/system/fork.mjs --affirm\`.`,
      ...moved.map((e) => `  ${e.spec} — ${e.test}\n    lifted: ${e.scenarios.join(", ") || "(nothing)"}`)
    );
  }

  const stale = outcomes.entries.filter((e) => e.outcome === OUTCOME.stale);
  if (stale.length) {
    said.push(
      `${stale.length} entr(ies) name a test the spec no longer holds — renamed, moved or deleted by a bump:`,
      ...stale.map((e) => `  ${e.spec} — ${e.test}\n    lifted: ${e.scenarios.join(", ") || "(nothing)"}`)
    );
  }

  const dangling = outcomes.entries.filter((e) => e.dangling.length);
  if (dangling.length) {
    said.push(
      `${dangling.length} entr(ies) name a scenario the corpus does not hold:`,
      ...dangling.map((e) => `  ${e.test} → ${e.dangling.join(", ")}`)
    );
  }

  if (outcomes.unregistered.length) {
    said.push(
      `${outcomes.unregistered.length} unit(s) of the upstream source the seed depends on are in no entry.`,
      `A bump added a test or a fixture, and deciding not to lift one is a decision this register records —`,
      `add an entry naming the scenarios it is lifted into or depended on by, or an empty list and a`,
      `written reason:`,
      ...outcomes.unregistered.map((u) => `  ${u.spec} — ${u.test}`)
    );
  }

  if (outcomes.unlifted.length) {
    said.push(
      `${outcomes.unlifted.length} seed scenario(s) are named by no entry. The seed is a fork, so a scenario`,
      `with no origin recorded is one whose drift nothing can detect:`,
      ...outcomes.unlifted.map((id) => `  ${id}`)
    );
  }

  return said;
};

/**
 * One line, for a run that passed — and it counts the three things separately
 * on purpose. "Lifted" is a claim about a scenario's origin, so a depended-on
 * source must not be counted as one: nothing was lifted out of `nodes/general.ts`,
 * the seed only reads it.
 */
export const renderForkSummary = (outcomes) => {
  const sources = outcomes.entries.filter((e) => e.test === WHOLE_FILE);
  const tests = outcomes.entries.filter((e) => e.test !== WHOLE_FILE);
  const lifted = tests.filter((e) => e.scenarios.length).length;

  return (
    `fork: ${outcomes.entries.length} upstream unit(s) affirmed — ${lifted} of ${tests.length} spec unit(s) ` +
    `lifted, ${tests.length - lifted} declined with a reason, and ${sources.length} depended-on source(s).`
  );
};
