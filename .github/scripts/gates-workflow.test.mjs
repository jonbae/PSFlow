// The gates workflow's own self-test — outside the gate scheme, for the same
// reason `test:surface` and `test:harness` are: it proves an instrument does
// what it claims, not that PSFlow matches xyflow. A red one means CI is
// misconfigured, not that the port broke.
//
// It exists because everything it asserts is otherwise a claim in prose. "CI
// runs the five gates on every pull request" and "the net runs in the image its
// checkpoints were captured in" are true of the workflow the day it is written
// and silently false the day someone edits one of the two files — which is the
// **stale** failure mode this repo treats as first-class everywhere else.
// README's five-gate table is the source of truth here: the workflow is checked
// against it, not the other way around.
//
// Every claim is a function of the files it reads, so the **falsification
// probes** at the bottom can drive *the same* comparison against a deliberately
// broken workflow and assert it goes red. A comparator that quietly stopped
// comparing — a parser that finds no steps, a table regex that matches nothing
// — is exactly what a green run here would otherwise look like.
//
// The parser is deliberately small, YAML being a dependency this repo does not
// have. It assumes `gates.yml` writes steps as `- ` list items under `steps:`
// with their keys indented beneath them.

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

const read = (path) => readFileSync(join(repoRoot, path), "utf8");

const WORKFLOW = ".github/workflows/gates.yml";
const SOURCES = {
  workflow: read(WORKFLOW),
  readme: read("README.md"),
  packageJson: read("package.json"),
};

/** The checks outside the gate scheme that CI runs after the five gates, in order. */
const BEYOND_GATES = [
  "npm run parity:boundary",
  "npm run test:boundary",
  "npm run build:package",
  "npm run parity:package",
];

/**
 * What CI puts in front of system parity's documented command: the runner that
 * captures in the Playwright image matching `package-lock.json`, which is where
 * the recorded checkpoints were captured.
 */
const LINUX_RUNNER = "node parity/system/linux.mjs";

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

/** README's five-gate table, as `{ gate, command }`. */
function fiveGateTable(readme) {
  const section = readme.slice(readme.indexOf("## The five gates"));
  const next = section.indexOf("\n## ", 1);
  const table = next === -1 ? section : section.slice(0, next);

  return [...table.matchAll(/^\|\s*\*\*(.+?)\*\*\s*\|\s*`(.+?)`\s*\|/gm)].map(
    ([, gate, command]) => ({ gate, command })
  );
}

/** One reading of the files, which is what every claim below is written against. */
function view({ workflow, readme, packageJson }) {
  // Comments explain; they do not run. Every claim reads the YAML without them.
  const uncommented = workflow
    .split("\n")
    .filter((line) => !/^\s*#/.test(line))
    .join("\n");

  const steps = parseSteps(uncommented);
  const table = fiveGateTable(readme);

  const ci = readme.slice(readme.indexOf("## Continuous integration"));
  const ciEnd = ci.indexOf("\n## ", 1);

  return {
    workflow,
    uncommented,
    steps,
    table,
    ciSection: ciEnd === -1 ? ci : ci.slice(0, ciEnd),
    cheap: table.filter(({ gate }) => gate !== "system parity"),
    /** All five gates, each with the command line CI runs it by. */
    gates: table.map(({ gate, command }) => ({
      gate,
      command: gate === "system parity" ? `${LINUX_RUNNER} ${command}` : command,
    })),
    scripts: JSON.parse(packageJson).scripts,
    /** Steps whose `run` executes `command` as a command line of its own. */
    running: (command) =>
      steps.filter((step) => step.run.split("\n").some((line) => line.trim() === command)),
  };
}

const CLAIMS = {
  "the parser found the workflow's steps": ({ steps, uncommented }) => {
    const declared = uncommented.match(/^\s*- (?:name|uses):/gm) ?? [];

    assert.ok(steps.length >= 8, `parsed ${steps.length} steps from ${WORKFLOW}`);
    assert.equal(steps.length, declared.length, "every step the file declares was parsed");
  },

  // Every pull request is the schedule, so a filter is a change to it: a
  // `branches` filter skips the stacked pull requests this repo opens, and a
  // `paths` filter skips the ones whose files someone judged harmless.
  "the workflow runs on every pull request": ({ uncommented }) => {
    const on = uncommented.slice(uncommented.indexOf("\non:"), uncommented.indexOf("\njobs:")).split("\n");
    const at = on.findIndex((line) => /^\s*pull_request:/.test(line));

    assert.notEqual(at, -1, "the workflow has a pull_request trigger");
    assert.match(on[at], /^\s*pull_request:\s*$/, "with no inline filter");

    const next = on.slice(at + 1).find((line) => line.trim() !== "");
    assert.ok(
      next === undefined || indentOf(next) <= indentOf(on[at]),
      `pull_request carries no filter: ${next?.trim()}`
    );
  },

  "README's five-gate table still lists five gates": ({ table, cheap }) => {
    assert.equal(table.length, 5, `parsed ${table.length} gates from README's table`);
    assert.deepEqual(
      cheap.map(({ gate }) => gate),
      ["surface parity", "function parity", "conformance test suite", "smoke test suite"]
    );
  },

  // The acceptance criterion is "the README's runnable table matches what CI
  // actually runs", in both directions: a gate whose command README renames is
  // a gate CI stops running under the name it is documented by, and a gate CI
  // runs twice is a gate whose second run is invisible in the report.
  "each cheap gate is run by exactly one step, by its documented command": ({ cheap, running }) => {
    for (const { gate, command } of cheap) {
      assert.equal(running(command).length, 1, `${gate}: \`${command}\` in ${WORKFLOW}`);
    }
  },

  // A decision, and one that has to survive the next edit. The net runs on
  // every pull request because it is the only gate that sees most runtime
  // behavior. It runs in the image its checkpoints were captured in, because
  // the capture environment is part of each receipt, and a bare
  // `npm run parity:system` on the runner would capture somewhere no recorded
  // wave has. It runs last among the gates because it is the most expensive.
  "system parity runs once, through the Linux runner, after the four cheap gates": ({
    table,
    cheap,
    steps,
    running,
    ciSection,
  }) => {
    const [systemParity] = table.filter(({ gate }) => gate === "system parity");
    const command = `${LINUX_RUNNER} ${systemParity.command}`;
    const at = (line) => steps.indexOf(running(line)[0]);

    assert.equal(running(command).length, 1, `\`${command}\` in ${WORKFLOW}`);
    assert.equal(running(systemParity.command).length, 0, "the net is not run on the host as well");
    assert.equal(running(command)[0].if, undefined, "it runs unconditionally");
    for (const { gate, command: line } of cheap) {
      assert.ok(at(line) < at(command), `${gate} runs before system parity`);
    }
    assert.ok(ciSection.includes(`\`${command}\``), `README's CI section names \`${command}\``);
  },

  // Surface parity is the only **hard precondition**, so the gates after it are
  // reached only when it passed. That property is GitHub's default and nothing
  // in the file states it — an `if:` on any of them would restore the run
  // without restoring the precondition, and every other claim here would stay
  // green.
  "surface parity runs first, and no gate after it is exempt from its failure": ({
    gates,
    steps,
    running,
  }) => {
    const at = (command) => steps.indexOf(running(command)[0]);
    const surface = at("npm run parity:surface");

    for (const { gate, command } of gates.filter((row) => row.gate !== "surface parity")) {
      assert.ok(surface < at(command), `surface parity runs before ${gate}`);
      assert.equal(running(command)[0].if, undefined, `${gate} runs unconditionally`);
    }
  },

  // Steps after a failure are skipped, which is the blocking half; this is the
  // reporting half, and skipped-in-silence is what it exists to prevent.
  "a red surface parity is reported as blocking the interpretation of the rest": ({
    steps,
    running,
  }) => {
    const [surface] = running("npm run parity:surface");

    assert.ok(surface.id, "the surface parity step is addressable by an id");

    const blocked = steps.filter((step) => step.if?.includes(`steps.${surface.id}.`));
    assert.equal(blocked.length, 1, `one step reports on steps.${surface.id}`);
    assert.match(blocked[0].if, /failure\(\)/, "it runs only when something failed");
    assert.match(blocked[0].if, /== 'failure'/, "and only when surface parity is what failed");
    assert.match(blocked[0].run, /GITHUB_STEP_SUMMARY/, "it reports into the run's summary");
    assert.ok(
      steps.indexOf(blocked[0]) < steps.indexOf(running("spago test")[0]),
      "and it is reached before the gates it says were not run"
    );
  },

  // The repo's single most repeated failure is a gate that prints instead of
  // failing. A workflow is a new place for that to happen — and unlike a
  // script, it can do it in one word — so the words are refused outright. A
  // step that genuinely needs one is a decision to take here first.
  "no step can swallow a non-zero exit": ({ uncommented }) => {
    for (const swallow of [/continue-on-error/, /\|\|/, /set \+e/, /;\s*true\b/]) {
      assert.doesNotMatch(uncommented, swallow, `${swallow} in ${WORKFLOW}`);
    }
  },

  // Not gates, so the five-gate table cannot hold them: this list does, and
  // README's CI section has to name each one. They run after every gate, so a
  // red one never withholds a gate's result, and in this order, because the
  // package check reads the `dist/` that the package build writes.
  "the checks outside the gate scheme each run once, in order, after the five gates": ({
    gates,
    steps,
    running,
    ciSection,
  }) => {
    const at = (command) => steps.indexOf(running(command)[0]);
    let previous = Math.max(...gates.map(({ command }) => at(command)));

    for (const command of BEYOND_GATES) {
      assert.equal(running(command).length, 1, `\`${command}\` in ${WORKFLOW}`);
      assert.ok(at(command) > previous, `\`${command}\` runs after the steps before it in the list`);
      assert.equal(running(command)[0].if, undefined, `\`${command}\` runs unconditionally`);
      assert.ok(ciSection.includes(`\`${command}\``), `README's CI section names \`${command}\``);
      previous = at(command);
    }
  },

  "every npm script the workflow runs exists": ({ uncommented, scripts }) => {
    const referenced = [...uncommented.matchAll(/npm run ([\w:-]+)/g)].map(([, script]) => script);

    assert.ok(referenced.length > 0, "the workflow runs npm scripts");
    for (const script of new Set(referenced)) {
      assert.ok(script in scripts, `package.json has no \`${script}\` script`);
    }
  },
};

for (const [claim, holds] of Object.entries(CLAIMS)) {
  test(claim, () => holds(view(SOURCES)));
}

// ─── Falsification probes ──────────────────────────────────────────────────
//
// Each breaks one thing in the files and names the claim that must catch it,
// driving the same comparison the tests above run. The patch is asserted to
// have changed something first: a probe whose edit silently missed would prove
// the comparator went red about nothing at all.

const PROBES = [
  {
    breaks: "the parser found the workflow's steps",
    by: "the job declaring no steps the parser can read",
    patch: { workflow: (w) => w.replace("    steps:", "    steps: []") },
  },
  {
    breaks: "the workflow runs on every pull request",
    by: "the pull request trigger going away",
    patch: { workflow: (w) => w.replace("\n  pull_request:", "") },
  },
  {
    breaks: "the workflow runs on every pull request",
    by: "a paths filter skipping the pull requests that touch nothing in it",
    patch: {
      workflow: (w) => w.replace("\n  pull_request:\n", '\n  pull_request:\n    paths: ["src/**"]\n'),
    },
  },
  {
    breaks: "the workflow runs on every pull request",
    by: "a branches filter skipping stacked pull requests",
    patch: { workflow: (w) => w.replace("\n  pull_request:\n", "\n  pull_request: { branches: [master] }\n") },
  },
  {
    breaks: "each cheap gate is run by exactly one step, by its documented command",
    by: "a gate dropping out of the workflow",
    patch: { workflow: (w) => w.replace("        run: spago test\n", "") },
  },
  {
    breaks: "each cheap gate is run by exactly one step, by its documented command",
    by: "README documenting a command CI does not run",
    patch: { readme: (r) => r.replace("`npm run test:conformance`", "`npm run test:conform`") },
  },
  {
    breaks: "system parity runs once, through the Linux runner, after the four cheap gates",
    by: "the net dropping out of the workflow",
    patch: {
      workflow: (w) => w.replace("        run: node parity/system/linux.mjs npm run parity:system\n", ""),
    },
  },
  {
    breaks: "system parity runs once, through the Linux runner, after the four cheap gates",
    by: "the net capturing on the host instead of in the image",
    patch: {
      workflow: (w) =>
        w.replace("run: node parity/system/linux.mjs npm run parity:system", "run: npm run parity:system"),
    },
  },
  {
    breaks: "system parity runs once, through the Linux runner, after the four cheap gates",
    by: "the net running before the smoke suite",
    patch: {
      workflow: (w) =>
        w
          .replace("run: npm run test:smoke", "run: SWAP")
          .replace("run: node parity/system/linux.mjs npm run parity:system", "run: npm run test:smoke")
          .replace("run: SWAP", "run: node parity/system/linux.mjs npm run parity:system"),
    },
  },
  {
    breaks: "system parity runs once, through the Linux runner, after the four cheap gates",
    by: "README's CI section no longer naming how CI runs the net",
    patch: {
      readme: (r) => r.replace("`node parity/system/linux.mjs npm run parity:system`", "the net"),
    },
  },
  {
    breaks: "surface parity runs first, and no gate after it is exempt from its failure",
    by: "the net exempting itself from the precondition",
    patch: {
      workflow: (w) =>
        w.replace("        id: system_parity\n", "        id: system_parity\n        if: always()\n"),
    },
  },
  {
    breaks: "surface parity runs first, and no gate after it is exempt from its failure",
    by: "a later gate exempting itself from the precondition",
    patch: {
      workflow: (w) =>
        w.replace(
          "      - name: Conformance test suite\n",
          "      - name: Conformance test suite\n        if: always()\n"
        ),
    },
  },
  {
    breaks: "a red surface parity is reported as blocking the interpretation of the rest",
    by: "the surface parity step losing the id its report is addressed to",
    patch: { workflow: (w) => w.replace("        id: surface_parity\n", "") },
  },
  {
    breaks: "no step can swallow a non-zero exit",
    by: "a gate being allowed to fail without failing the run",
    patch: {
      workflow: (w) =>
        w.replace(
          "        run: npm run test:smoke",
          "        continue-on-error: true\n        run: npm run test:smoke"
        ),
    },
  },
  {
    breaks: "the checks outside the gate scheme each run once, in order, after the five gates",
    by: "the boundary checks dropping out of the workflow",
    patch: { workflow: (w) => w.replace("        run: npm run parity:boundary\n", "") },
  },
  {
    breaks: "the checks outside the gate scheme each run once, in order, after the five gates",
    by: "the boundary tests dropping out of the workflow",
    patch: { workflow: (w) => w.replace("        run: npm run test:boundary\n", "") },
  },
  {
    breaks: "the checks outside the gate scheme each run once, in order, after the five gates",
    by: "a check running before the net, where a red one would withhold the net's result",
    patch: {
      workflow: (w) =>
        w
          .replace("run: npm run parity:boundary", "run: SWAP")
          .replace("run: node parity/system/linux.mjs npm run parity:system", "run: npm run parity:boundary")
          .replace("run: SWAP", "run: node parity/system/linux.mjs npm run parity:system"),
    },
  },
  {
    breaks: "the checks outside the gate scheme each run once, in order, after the five gates",
    by: "the package check running before the build it reads",
    patch: {
      workflow: (w) =>
        w
          .replace("run: npm run build:package", "run: npm run SWAP")
          .replace("run: npm run parity:package", "run: npm run build:package")
          .replace("run: npm run SWAP", "run: npm run parity:package"),
    },
  },
  {
    breaks: "the checks outside the gate scheme each run once, in order, after the five gates",
    by: "README's CI section no longer naming the package check",
    patch: {
      readme: (r) =>
        r.replace("consumer with\n`npm run parity:package`.", "consumer."),
    },
  },
  {
    breaks: "every npm script the workflow runs exists",
    by: "the workflow calling a script package.json does not have",
    patch: {
      workflow: (w) =>
        w.replace("        run: npm run test:ci\n", "        run: npm run test:ci-renamed\n"),
    },
  },
];

for (const { breaks, by, patch } of PROBES) {
  test(`falsified: ${breaks} — ${by}`, () => {
    const broken = { ...SOURCES };
    for (const [file, edit] of Object.entries(patch)) {
      broken[file] = edit(SOURCES[file]);
      assert.notEqual(broken[file], SOURCES[file], `the probe's edit to ${file} changed nothing`);
    }

    assert.throws(() => CLAIMS[breaks](view(broken)), assert.AssertionError);
  });
}
