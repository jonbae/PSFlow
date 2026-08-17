// The gates workflow's own self-test — outside the gate scheme, for the same
// reason `test:surface` and `test:harness` are: it proves an instrument does
// what it claims, not that PSFlow matches xyflow. A red one means CI is
// misconfigured, not that the port broke.
//
// It exists because everything this file asserts is otherwise a claim in prose.
// "CI runs the four cheap gates" and "system parity is excluded" are true of
// the workflow the day it is written and silently false the day someone edits
// one of the two files — which is the **stale** failure mode this repo treats
// as first-class everywhere else. README's five-gate table is the source of
// truth here: the workflow is checked against it, not the other way around.
//
// The parser below is deliberately small — YAML is not a dependency this repo
// has — so it makes two assumptions about `gates.yml`: steps are `- ` list
// items under `steps:`, and a step's keys are indented consistently beneath
// it. A parse that stops finding steps would make every assertion here pass
// vacuously, so the step count is asserted first.

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

const read = (path) => readFileSync(join(repoRoot, path), "utf8");

const WORKFLOW = ".github/workflows/gates.yml";
const workflow = read(WORKFLOW);

/** Comments explain; they do not run. Every assertion below reads the YAML without them. */
const uncommented = workflow
  .split("\n")
  .filter((line) => !/^\s*#/.test(line))
  .join("\n");

const indentOf = (line) => line.match(/^\s*/)[0].length;

/** The steps of every job, as `{ name, id, if, run }`. */
function parseSteps(yaml) {
  const chunks = [];
  let stepsIndent = null;
  let itemIndent = null;
  let current = null;

  for (const line of yaml.split("\n")) {
    const opensSteps = line.match(/^(\s*)steps:\s*$/);
    if (opensSteps) {
      [stepsIndent, itemIndent, current] = [opensSteps[1].length, null, null];
      continue;
    }
    if (stepsIndent === null || line.trim() === "") continue;
    if (indentOf(line) <= stepsIndent) {
      [stepsIndent, current] = [null, null];
      continue;
    }

    const item = line.match(/^(\s*)- \S/);
    if (item && (itemIndent === null || item[1].length === itemIndent)) {
      itemIndent = item[1].length;
      chunks.push((current = [line]));
    } else if (current) {
      current.push(line);
    }
  }

  return chunks.map((chunk) => {
    const field = (key) => {
      const at = chunk.findIndex((line) => new RegExp(`^\\s*(?:- )?${key}:(\\s|$)`).test(line));
      if (at === -1) return undefined;

      const value = chunk[at].replace(new RegExp(`^\\s*(?:- )?${key}:\\s*`), "").trim();
      if (!/^[|>][-+]?$/.test(value)) return value;

      // A block scalar: its body is the lines indented under the key.
      const body = [];
      for (const line of chunk.slice(at + 1)) {
        if (indentOf(line) <= indentOf(chunk[at])) break;
        body.push(line);
      }
      return body.join("\n");
    };

    return {
      name: field("name"),
      id: field("id"),
      if: field("if"),
      run: field("run") ?? "",
      text: chunk.join("\n"),
    };
  });
}

const steps = parseSteps(uncommented);

/** `| **surface parity** | `npm run parity:surface` | …` — README's five-gate table. */
function fiveGateTable(readme) {
  const section = readme.slice(readme.indexOf("## The five gates"));
  const next = section.indexOf("\n## ", 1);
  const table = next === -1 ? section : section.slice(0, next);

  return [...table.matchAll(/^\|\s*\*\*(.+?)\*\*\s*\|\s*`(.+?)`\s*\|/gm)].map(
    ([, gate, command]) => ({ gate, command })
  );
}

const table = fiveGateTable(read("README.md"));
const cheap = table.filter(({ gate }) => gate !== "system parity");

/** Steps whose `run` executes `command` as a command line of its own. */
const stepsRunning = (command) =>
  steps.filter((step) => step.run.split("\n").some((line) => line.trim() === command));

test("the parser found the workflow's steps", () => {
  const declared = uncommented.match(/^\s*- (?:name|uses):/gm) ?? [];

  assert.ok(steps.length >= 8, `parsed ${steps.length} steps from ${WORKFLOW}`);
  assert.equal(steps.length, declared.length, "every step the file declares was parsed");
  assert.ok(
    steps.every((step) => step.name || step.text.includes("uses:")),
    "every parsed step is a named step or a `uses:`"
  );
});

test("the workflow runs on every pull request", () => {
  const on = uncommented.slice(uncommented.indexOf("\non:"), uncommented.indexOf("\njobs:"));

  assert.match(on, /^\s*pull_request:/m);
});

test("README's five-gate table still lists five gates", () => {
  assert.equal(table.length, 5, `parsed ${table.length} gates from README's table`);
  assert.deepEqual(
    cheap.map(({ gate }) => gate),
    ["surface parity", "function parity", "conformance test suite", "smoke test suite"]
  );
});

// The acceptance criterion is "the README's runnable table matches what CI
// actually runs", in both directions: a gate whose command README renames is a
// gate CI stops running under the name it is documented by, and a gate CI runs
// twice is a gate whose second run is invisible in the report.
test("each of the four cheap gates is run by exactly one step, by its documented command", () => {
  for (const { gate, command } of cheap) {
    assert.equal(stepsRunning(command).length, 1, `${gate}: \`${command}\` in ${WORKFLOW}`);
  }
});

// Not an omission — a decision, and one that has to survive the next edit.
// Its per-run cost is not knowable until the corpus exists (~240 runs at two
// sides by two captures, each settling on its own clock), and the per-PR /
// nightly / bump-only question is answered by that measurement.
test("system parity is not in the per-PR workflow, and the reason is recorded", () => {
  const [systemParity] = table.filter(({ gate }) => gate === "system parity");

  assert.equal(stepsRunning(systemParity.command).length, 0);
  assert.ok(!uncommented.includes(systemParity.command), `${systemParity.command} in ${WORKFLOW}`);
  assert.match(workflow, /system parity/i, "the workflow records why it is excluded");
});

test("surface parity runs before the other three gates", () => {
  const at = (command) => steps.indexOf(stepsRunning(command)[0]);
  const surface = at("npm run parity:surface");

  for (const { gate, command } of cheap.filter(({ gate }) => gate !== "surface parity")) {
    assert.ok(surface < at(command), `surface parity runs before ${gate}`);
  }
});

// Surface parity is the only **hard precondition**: interop breakage has a
// cheap static signature and an expensive runtime shadow, so a red one makes
// every downstream result unreadable rather than merely suspect. Steps after a
// failure are skipped, which is the blocking half; this is the reporting half,
// and skipped-in-silence is exactly what it exists to prevent.
test("a red surface parity is reported as blocking the interpretation of the rest", () => {
  const [surface] = stepsRunning("npm run parity:surface");

  assert.ok(surface.id, "the surface parity step is addressable by an id");

  const blocked = steps.filter((step) => step.if?.includes(`steps.${surface.id}.`));
  assert.equal(blocked.length, 1, `one step reports on steps.${surface.id}`);
  assert.match(blocked[0].if, /failure\(\)/, "it runs only when something failed");
  assert.match(blocked[0].if, /== 'failure'/, "and only when surface parity is what failed");
  assert.match(blocked[0].run, /GITHUB_STEP_SUMMARY/, "it reports into the run's summary");
  assert.ok(
    steps.indexOf(blocked[0]) < steps.indexOf(stepsRunning("spago test")[0]),
    "and it is reached before the gates it says were not run"
  );
});

// The repo's single most repeated failure is a gate that prints instead of
// failing. A workflow is a new place for that to happen — and unlike a script,
// it can do it in one word — so the words are refused outright. A step that
// genuinely needs one is a decision to take here first.
test("no step can swallow a non-zero exit", () => {
  for (const swallow of [/continue-on-error/, /\|\|/, /set \+e/, /;\s*true\b/]) {
    assert.doesNotMatch(uncommented, swallow, `${swallow} in ${WORKFLOW}`);
  }
});

test("every npm script the workflow runs exists", () => {
  const { scripts } = JSON.parse(read("package.json"));
  const referenced = [...uncommented.matchAll(/npm run ([\w:-]+)/g)].map(([, script]) => script);

  assert.ok(referenced.length > 0, "the workflow runs npm scripts");
  for (const script of new Set(referenced)) {
    assert.ok(script in scripts, `package.json has no \`${script}\` script`);
  }
});
