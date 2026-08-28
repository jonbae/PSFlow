// Changelog audit — join + gate. Joins the extracted changelog entries against
// the hand-authored verdicts and writes `report.md` (a committed audit
// snapshot).
//
// Three gates, all non-zero exit:
//
//   1. Coverage — every PR in `entries.json` must have a `verdicts.json` key.
//      This is what catches the *next* version bump: bumping `xyflow/` surfaces
//      new PRs, and each one fails the build until it is bucketed. Same
//      key-presence mechanism as `claim()` in ../surface/allowlist.mjs.
//
//   2. Well-formedness — each row satisfies its bucket's rule, in
//      `buckets.mjs`: a covered bucket cites evidence, a gap names a ticket or
//      an in-branch fix, an accepted bucket gives a written reason. Without this
//      the audit degrades into a wall of unfalsifiable assertions; with it, each
//      no-action claim names something a reviewer can open.
//
//   3. The `gate-pending` join — a row whose plan is a gate names the scenario
//      or test that will prove it, and the name has to resolve. This is the one
//      gate here that reads something outside this directory: the corpus's
//      **name space** (`parity/system/corpus/index.mjs`), which is every id a
//      scenario exists under plus the thirty `reserved.mjs` holds for scenarios
//      #60 will write. A row against a name in neither is a typo or an
//      invention, and both look exactly like a plan in a JSON file.
//
// Why (3) is worth reaching across the repo for: `gate-pending` is what let
// fifty test-debt rows stop being silent gaps without any of them being called
// covered. That trade only holds while the plans are real, and the only
// mechanical thing about a plan is whether the name in it exists.

import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";
import { readFileSync, writeFileSync, existsSync } from "node:fs";

import { BUCKETS, rowProblems } from "./buckets.mjs";
import { RegistryError, routeSpace } from "../driver/registry.mjs";
import { scenarioNames } from "../system/corpus/index.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");
const load = (name) => JSON.parse(readFileSync(join(here, name), "utf8"));

const entriesPath = join(here, "entries.json");
if (!existsSync(entriesPath)) {
  console.error(
    "[audit] FAIL: entries.json not found — run extract-entries.mjs first\n" +
      "(`npm run parity:changelog` does both). It needs the vendored `xyflow/`\n" +
      "checkout, which is gitignored and absent on a clean clone."
  );
  process.exit(1);
}

const { reactVersion, systemVersion, floors, entries } = load("entries.json");
const verdicts = load("verdicts.json");

// The corpus is assembled from the same two registries the driver page is built
// from, so it needs the vendored tree — which `entries.json` above already
// implies. There is no degraded mode: an audit that skipped the join because it
// could not read the corpus would report the `gate-pending` rows as well-formed
// on exactly the run that could not check them.
let names;
try {
  const { fixtures, components } = routeSpace(repoRoot);
  names = scenarioNames(fixtures, components);
} catch (e) {
  if (!(e instanceof RegistryError)) throw e;
  console.error(
    `[audit] FAIL: the corpus could not be assembled, so no gate-pending row's\n` +
      `scenario could be checked against it:\n\n  ${e.message}\n`
  );
  process.exit(1);
}

const prs = Object.keys(entries).sort((a, b) => Number(a) - Number(b));

// ─── Gate 1: coverage ─────────────────────────────────────────────────────
const unbucketed = prs.filter(
  (pr) => !Object.prototype.hasOwnProperty.call(verdicts, pr)
);

// ─── Gates 2 and 3: well-formedness, and the gate-pending join ────────────
const problems = prs.flatMap((pr) =>
  verdicts[pr] ? rowProblems(pr, verdicts[pr], { scenarios: names }) : [] // absent is gate 1's to report
);

// Verdicts for PRs that are no longer in range (e.g. the floor moved up) are
// stale bookkeeping, not a build failure — reported so they can be pruned.
const orphans = Object.keys(verdicts)
  .filter((k) => !k.startsWith("_") && !Object.prototype.hasOwnProperty.call(entries, k))
  .sort((a, b) => Number(a) - Number(b));

// ─── Report ───────────────────────────────────────────────────────────────
const now = new Date().toISOString().slice(0, 10);
const byBucket = new Map(Object.keys(BUCKETS).map((b) => [b, []]));
for (const pr of prs) {
  const v = verdicts[pr];
  if (v && byBucket.has(v.bucket)) byBucket.get(v.bucket).push(pr);
}

const prLink = (pr) => `[#${pr}](https://github.com/xyflow/xyflow/pull/${pr})`;
const esc = (s) => String(s ?? "").replace(/\|/g, "\\|");
const rows = (bucket) => byBucket.get(bucket) ?? [];
const count = (kind) =>
  Object.keys(BUCKETS)
    .filter((b) => BUCKETS[b].kind === kind)
    .reduce((n, b) => n + rows(b).length, 0);

/** Whether a net-bound row's scenario exists yet, or is still only a name. */
const written = (v) => names.written.includes(v.scenario);
const provenBy = (v) =>
  v.gate === "system"
    ? `\`${esc(v.scenario)}\`${written(v) ? "" : " _(reserved)_"}`
    : esc(v.test);

/**
 * The last column of a bucket's table — the thing that would have to be wrong
 * for the row to be wrong. Covered rows cite evidence, accepted rows give the
 * reason, gaps point at whoever owns the work.
 */
const claimOf = (v) => {
  if (BUCKETS[v.bucket].kind === "covered") return esc(v.evidence);
  if (BUCKETS[v.bucket].kind === "accepted") return esc(v.reason);
  return esc(v.ticket ? `ticket ${v.ticket}` : v.note);
};

const table = (bucket, columns) => {
  if (!rows(bucket).length) return "_none._\n";
  return [
    `| PR | Pkg | Version | Change | ${columns.map(([head]) => head).join(" | ")} |`,
    `|---|---|---|---|${columns.map(() => "---|").join("")}`,
    ...rows(bucket).map((pr) => {
      const [v, e] = [verdicts[pr], entries[pr]];
      const cells = columns.map(([, cell]) => cell(v)).join(" | ");
      return `| ${prLink(pr)} | ${e.pkg} | ${e.version} | ${esc(e.title)} | ${cells} |`;
    }),
  ].join("\n") + "\n";
};

const CLAIM = {
  covered: "Evidence",
  accepted: "Reason",
  gap: "Ticket / fix",
  na: "Note",
};

const section = (bucket, columns) =>
  `### \`${bucket}\` — ${BUCKETS[bucket].label}\n\n` +
  table(bucket, columns ?? [[CLAIM[BUCKETS[bucket].kind], claimOf]]);

// The test-debt cohort: the rows tickets 076–079 filed as `ported-ungated`, each
// carrying in `debt` the ticket that filed it. Derived rather than written down,
// because the correction this audit records is a *count* — one of the fifty-seven
// turned out not to be ported at all — and a hand-typed count is exactly the
// thing that goes quietly stale the next time a row moves. `debt` is separate
// from `ticket` because the two answer different questions: which ticket filed
// the row, and who owns the work now. Seven rows disagree, which is why one
// field cannot serve as the other.
const filed = prs.filter((pr) => verdicts[pr]?.debt);
const debt = filed.filter((pr) => verdicts[pr].bucket !== "not-ported");
const misfiled = filed.filter((pr) => verdicts[pr].bucket === "not-ported");
const debtBuckets = Object.keys(BUCKETS)
  .map((bucket) => [bucket, debt.filter((pr) => verdicts[pr].bucket === bucket).length])
  .filter(([, n]) => n > 0);

const counts = Object.keys(BUCKETS)
  .map((b) => `| \`${b}\` | ${BUCKETS[b].kind} | ${rows(b).length} | ${BUCKETS[b].label} |`)
  .join("\n");

const pending = rows("gate-pending").map((pr) => verdicts[pr]);
const unwritten = pending.filter((v) => v.gate === "system" && !written(v));

const report = `# Changelog audit — \`@xyflow/react\` 12.3.5 → ${reactVersion}

_Generated by \`npm run parity:changelog\` — do not edit by hand. Last run: ${now}._

Range: \`@xyflow/react\` **>${floors.react} → ${reactVersion}** and
\`@xyflow/system\` **>${floors.system} → ${systemVersion}**, as vendored under
\`xyflow/\`. Floors are exclusive — they are the versions PSFlow was originally
ported against, so their own entries were part of the original port.

**${prs.length} unique PRs.** A PR that touched both packages appears in both
CHANGELOGs with the same title and is audited once, attributed to \`react\`.
\`- Updated dependencies […]\` roll-ups carry no PR id and are not audit entries.

Every PR is bucketed in \`verdicts.json\`. \`npm run parity:changelog\` fails if
any in-range PR lacks a verdict — that is what catches the next version bump —
and fails if any row breaks its bucket's rule: a *covered* row citing no
evidence, an *accepted* row giving no reason, or a *gate-pending* row naming a
scenario the corpus neither holds nor reserves. Together those are what keep
this an audit rather than a list of assertions.

Note that \`verdicts.json\` embeds each PR's title alongside the verdict, so the
committed half of this audit is self-contained: \`xyflow/\` is gitignored and
does not survive a clean clone, where \`npm run parity:changelog\` hard-fails by
design (as \`parity:surface\` does).

## Summary

- **covered** (no action): ${count("covered")}
- **gaps** (planned, ticketed or fixed in-branch): ${count("gap")}
- **accepted** (ungated by decision): ${count("accepted")}
- **n/a**: ${count("na")}

| Bucket | Kind | Count | Meaning |
|---|---|---|---|
${counts}

## The test debt

Tickets 076–079 filed **${filed.length} rows** as ported-but-ungated after the
12.3.5 → 12.11.0 sweep, and \`tickets/080-test-debt-dispositions.md\` decided what
becomes of each. **${debt.length} of them are the debt.** The ${misfiled.length === 1 ? "one that is not" : `${misfiled.length} that are not`} is
${misfiled.map(prLink).join(", ")} — filed as ported and correct
and neither: upstream's viewport Promise settles when the transition *finishes*
and PSFlow's \`Aff\` settles when it *starts*, so it is \`not-ported\` and sits on
the [divergence backlog](https://github.com/jonbae/PSFlow/issues/22). The net
could not have caught it either — it compares end states, and both sides arrive
at the same viewport whatever path they took.

Where the ${debt.length} went: ${debtBuckets.map(([b, n]) => `\`${b}\` ${n}`).join(", ")}.
None of them moved into a covered bucket. A plan is a gap.

## Gaps

A gap is a change nothing proves. \`gate-pending\` is a gap with a named gate
coming, \`ported-ungated\` is one with no plan at all, and \`not-ported\` is
behavior PSFlow does not have. A planned gate is never a covered bucket, which
is what makes the first of the three worth having.

${section("gate-pending", [
  ["Gate", (v) => `\`${esc(v.gate)}\``],
  ["Proven by", provenBy],
  ["Stage", (v) => (v.stage ? `${v.stage}` : "—")],
])}
${
  unwritten.length
    ? `${unwritten.length} of the ${pending.length} \`gate-pending\` rows name a scenario the corpus **reserves but ` +
      `has not written yet** (marked _(reserved)_ above): the id is spoken for in ` +
      `\`parity/system/corpus/reserved.mjs\` and no other source may take it, but nothing drives it until the ` +
      `thirty test-debt scenarios land. Those rows are gaps twice over, and \`parity/system/coverage.md\` counts ` +
      `them apart from the ones whose scenario exists.\n`
    : "Every `gate-pending` row names a scenario or test that exists.\n"
}
${section("ported-ungated")}
${section("not-ported")}
## Accepted

An accepted row is ported and will never be gated, by decision rather than by
omission — which is the only way the gap count can reach zero without something
being called covered that is not. The reason is the whole record.

${section("accepted-ungated")}
## Covered

\`system\` is empty and is carried anyway, which no other bucket is: ${rows("gate-pending").filter((pr) => verdicts[pr].gate === "system").length} rows name
it as the gate they graduate into, so it is pointed at even while it holds
nothing. The rule the rest of the table follows — no bucket without a row —
is what keeps \`smoke\` out, since no in-range PR is covered by \`smoke.spec.ts\`.

${section("surface")}
${section("function")}
${section("conformance")}
${section("unit")}
${section("system")}
${section("ts-only")}
${section("docs")}
## Not applicable

${section("n/a")}`;

writeFileSync(join(here, "report.md"), report);

// ─── Console summary + gates ──────────────────────────────────────────────
console.log(
  `[audit] ${prs.length} PRs: covered=${count("covered")} gaps=${count("gap")} ` +
    `accepted=${count("accepted")} n/a=${count("na")}`
);
console.log(
  `[audit] ${pending.length} gate-pending row(s), ${unwritten.length} naming a scenario the corpus has reserved ` +
    `but not written`
);
console.log(`[audit] report → ${join(here, "report.md")}`);

if (orphans.length) {
  console.warn(
    `[audit] note: ${orphans.length} verdict(s) for PRs no longer in range ` +
      `(prune from verdicts.json): ${orphans.map((p) => `#${p}`).join(", ")}`
  );
}

// A reserved id nothing names is a reservation with no purpose left — the row it
// was held for was rebucketed, or the id was renamed on one side only. A note
// rather than a failure: the register belongs to the corpus, and #61's
// retirement scenarios may yet claim one.
const unclaimed = names.reserved.filter(
  (id) => !pending.some((v) => v.scenario === id) && !names.written.includes(id)
);
if (unclaimed.length) {
  console.warn(
    `[audit] note: ${unclaimed.length} reserved scenario id(s) no gate-pending row names and no source has ` +
      `written: ${unclaimed.join(", ")}`
  );
}

if (unbucketed.length) {
  console.error(
    `\n[audit] FAIL: ${unbucketed.length} PR(s) in range have no verdict in verdicts.json:`
  );
  for (const pr of unbucketed) {
    const e = entries[pr];
    console.error(`  - #${pr} (${e.pkg} ${e.version}) ${e.title}`);
  }
  console.error(
    "\nBucket each in verdicts.json. Covered buckets require evidence; the gap\n" +
      "buckets require a ticket or an in-branch fix, and a gate-pending row\n" +
      "also names the gate, the scenario or test, and the boundary stage."
  );
  process.exitCode = 1;
}

if (problems.length) {
  console.error(`\n[audit] FAIL: ${problems.length} malformed verdict(s):`);
  for (const p of problems) console.error(`  - ${p}`);
  process.exitCode = 1;
}

if (!unbucketed.length && !problems.length) {
  console.log("[audit] OK: every in-range PR has a well-formed verdict.");
}
