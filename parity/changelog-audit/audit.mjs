// Changelog audit — join + gate. Joins the extracted changelog entries against
// the hand-authored verdicts and writes `report.md` (a committed audit
// snapshot).
//
// Two gates, both non-zero exit:
//
//   1. Coverage — every PR in `entries.json` must have a `verdicts.json` key.
//      This is what catches the *next* version bump: bumping `xyflow/` surfaces
//      new PRs, and each one fails the build until it is bucketed. Same
//      key-presence mechanism as `partition()` in ../surface/diff.mjs.
//
//   2. Evidence — every verdict in a "covered" bucket must cite non-empty
//      evidence. Without this the audit degrades into a wall of unfalsifiable
//      assertions; with it, each no-action claim names a file a reviewer can
//      open. The two silent-gap buckets instead require a `ticket` or an
//      in-branch fix, recorded in `note`.

import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { readFileSync, writeFileSync, existsSync } from "node:fs";

const here = dirname(fileURLToPath(import.meta.url));
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

// ─── Buckets ──────────────────────────────────────────────────────────────
// `covered` buckets assert the change needs no action *and* name the artifact
// that makes that true. `gap` buckets are the two silent-gap outcomes. `n/a`
// is for changes with no possible PSFlow analogue.
// Bucket keys are the gate names, deliberately: a covered bucket says which
// gate would go red. `smoke` is absent because no in-range PR is covered by
// `smoke.spec.ts` — add it when one is, rather than carrying an empty bucket.
const BUCKETS = {
  docs: { kind: "covered", label: "Docs / types / tooling only — no runtime behavior" },
  "ts-only": { kind: "covered", label: "TypeScript-only (type signature, generics, inference)" },
  surface: { kind: "covered", label: "Surface change — gated by parity:surface" },
  function: { kind: "covered", label: "Pure-math change — gated by function parity, differential against the @psflow/oracle bundle" },
  conformance: { kind: "covered", label: "Behavior covered by a spec in the conformance test suite" },
  unit: { kind: "covered", label: "Behavior covered by a PureScript unit/property test" },
  "ported-ungated": { kind: "gap", label: "Ported and correct, but no gate exercises it (test debt)" },
  "not-ported": { kind: "gap", label: "Behavior not present in PSFlow" },
  "n/a": { kind: "na", label: "No PSFlow analogue (Svelte-only, build tooling, infra)" },
};

const prs = Object.keys(entries).sort((a, b) => Number(a) - Number(b));

// ─── Gate 1: coverage ─────────────────────────────────────────────────────
const unbucketed = prs.filter(
  (pr) => !Object.prototype.hasOwnProperty.call(verdicts, pr)
);

// ─── Gate 2: well-formedness ──────────────────────────────────────────────
const problems = [];
for (const pr of prs) {
  const v = verdicts[pr];
  if (!v) continue; // already reported by gate 1
  const meta = BUCKETS[v.bucket];
  if (!meta) {
    problems.push(`#${pr}: unknown bucket "${v.bucket}"`);
    continue;
  }
  if (meta.kind === "covered" && !String(v.evidence ?? "").trim()) {
    problems.push(`#${pr}: bucket "${v.bucket}" is a covered bucket and requires non-empty evidence`);
  }
  if (meta.kind === "gap" && !v.ticket && !String(v.note ?? "").trim()) {
    problems.push(`#${pr}: bucket "${v.bucket}" is a silent gap and requires a ticket or a note recording the in-branch fix`);
  }
}

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

const bucketTable = (bucket) => {
  const rows = byBucket.get(bucket) ?? [];
  if (!rows.length) return "_none._\n";
  const isGap = BUCKETS[bucket].kind === "gap";
  const lastCol = isGap ? "Ticket / fix" : "Evidence";
  const cell = (v) =>
    isGap ? esc(v.ticket ? `ticket ${v.ticket}` : v.note) : esc(v.evidence);
  return [
    `| PR | Pkg | Version | Change | ${lastCol} |`,
    "|---|---|---|---|---|",
    ...rows.map((pr) => {
      const v = verdicts[pr];
      const e = entries[pr];
      return `| ${prLink(pr)} | ${e.pkg} | ${e.version} | ${esc(e.title)} | ${cell(v)} |`;
    }),
  ].join("\n") + "\n";
};

const counts = Object.keys(BUCKETS)
  .map((b) => `| \`${b}\` | ${BUCKETS[b].kind} | ${(byBucket.get(b) ?? []).length} | ${BUCKETS[b].label} |`)
  .join("\n");

const coveredTotal = Object.keys(BUCKETS)
  .filter((b) => BUCKETS[b].kind === "covered")
  .reduce((n, b) => n + (byBucket.get(b) ?? []).length, 0);
const gapTotal = Object.keys(BUCKETS)
  .filter((b) => BUCKETS[b].kind === "gap")
  .reduce((n, b) => n + (byBucket.get(b) ?? []).length, 0);

const section = (bucket) =>
  `### \`${bucket}\` — ${BUCKETS[bucket].label}\n\n${bucketTable(bucket)}`;

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
and fails if any *covered* verdict cites no evidence, which is what keeps this
an audit rather than a list of assertions.

Note that \`verdicts.json\` embeds each PR's title alongside the verdict, so the
committed half of this audit is self-contained: \`xyflow/\` is gitignored and
does not survive a clean clone, where \`npm run parity:changelog\` hard-fails by
design (as \`parity:surface\` does).

## Summary

- **covered** (no action): ${coveredTotal}
- **silent gaps** (fixed in-branch or ticketed): ${gapTotal}
- **n/a**: ${(byBucket.get("n/a") ?? []).length}

| Bucket | Kind | Count | Meaning |
|---|---|---|---|
${counts}

## Silent gaps

${section("ported-ungated")}
${section("not-ported")}
## Covered

${section("surface")}
${section("function")}
${section("conformance")}
${section("unit")}
${section("ts-only")}
${section("docs")}
## Not applicable

${section("n/a")}`;

writeFileSync(join(here, "report.md"), report);

// ─── Console summary + gates ──────────────────────────────────────────────
console.log(
  `[audit] ${prs.length} PRs: covered=${coveredTotal} gaps=${gapTotal} ` +
    `n/a=${(byBucket.get("n/a") ?? []).length}`
);
console.log(`[audit] report → ${join(here, "report.md")}`);

if (orphans.length) {
  console.warn(
    `[audit] note: ${orphans.length} verdict(s) for PRs no longer in range ` +
      `(prune from verdicts.json): ${orphans.map((p) => `#${p}`).join(", ")}`
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
    "\nBucket each in verdicts.json. Covered buckets require evidence; the\n" +
      "ported-ungated / not-ported buckets require a ticket or an in-branch fix."
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
