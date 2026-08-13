// Surface parity — diff + report generator. Compares the upstream and PSFlow
// API surfaces extracted by the sibling scripts, subtracts the documented
// divergence allowlist, and writes `report.md` (a committed parity snapshot).
//
// Gates (all accumulate into `process.exitCode`, so one pass reports every
// failing bucket rather than stopping at the first):
//
//   * a non-empty "missing in PSFlow" *export* bucket after allowlisting;
//   * a non-empty missing/extra *prop-member* bucket after allowlisting;
//   * a non-empty shape- or behavior-divergence bucket after allowlisting;
//   * any allowlist entry that no longer claims a real difference — stale;
//   * any allowlist entry whose reason nobody could act on — malformed.
//
// The prop buckets used to be informational — they printed divergence while
// the script still exited 0, which is exactly how the xPos/yPos rename
// (ticket 069) survived for months. They now gate. Legitimate divergence is
// expressed in allowlist.json rather than tolerated silently.
//
// **Values, not names.** An upstream *value* is satisfied only by a PSFlow
// *value*. The two sides used to be merged into one value∪type name set, with
// a comment calling the merge deliberate — it "sidesteps that
// value/type-classification mismatch". The census measured it and found no
// mismatch: `import { Position } from 'ps-flow'` was genuinely `undefined`, so
// the comment described the papering-over rather than a modelling difference.
// Both extractors already emitted the two sets separately, so removing the
// union was a deletion.
//
// The *extra* bucket keeps the union, and that asymmetry is deliberate: it
// answers a different question. Missing asks whether an upstream export is
// satisfied in kind; extra asks whether PSFlow publishes a name upstream does
// not have at all. `Position` is upstream's name, so PSFlow holding both the
// value and a PureScript type of that name is not an extension.

import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, join } from "node:path";
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { PROP_TYPES } from "./prop-types.mjs";
import { shapeDifferences } from "./shape.mjs";
import { behaviorDifferences, describeObservation } from "./behavior.mjs";
import {
  AllowlistError,
  RETIRING_EVENT,
  RETIRING_STAGE,
  claim,
  liveRenames,
  validateReasons,
} from "./allowlist.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const load = (name) => JSON.parse(readFileSync(join(here, name), "utf8"));

const upstream = load("upstream.json");
const psflow = load("psflow.json");
const allowPath = join(here, "allowlist.json");
const allow = existsSync(allowPath)
  ? load("allowlist.json")
  : { exports: { missing: {}, extra: {} }, shapes: {}, behavior: {}, props: {} };

const allowMissing = allow.exports?.missing ?? {};
const allowExtra = allow.exports?.extra ?? {};
const allowShapes = allow.shapes ?? {};
const allowBehaviorEnums = allow.behavior?.enums ?? {};
const allowBehaviorFunctions = allow.behavior?.functions ?? {};

// Every entry needs a written reason, and a shape entry needs one that names
// what will retire it — an entry nobody can act on is a failure of the register
// whether or not it claimed something this run. Collected rather than thrown,
// so a malformed reason does not hide the comparison it sits beside: the
// entries still claim what they claim, it is only the prose that is unusable.
const malformed = [];
const checkReasons = (register, entries, rule) => {
  try {
    validateReasons(register, entries, rule);
  } catch (e) {
    if (!(e instanceof AllowlistError)) throw e;
    malformed.push(e.message);
  }
};

checkReasons("exports.missing", allowMissing);
checkReasons("exports.extra", allowExtra);
checkReasons("shapes", allowShapes, RETIRING_EVENT);
checkReasons("behavior.enums", allowBehaviorEnums, RETIRING_STAGE);
checkReasons("behavior.functions", allowBehaviorFunctions, RETIRING_STAGE);
for (const { name } of PROP_TYPES) {
  const cfg = allow.props?.[name] ?? {};
  checkReasons(`props.${name}.missing`, cfg.missing);
  checkReasons(`props.${name}.extra`, cfg.extra);
  checkReasons(`props.${name}.drift`, cfg.drift);
}

const setOf = (xs) => new Set(xs);
const diff = (a, b) => [...a].filter((x) => !b.has(x)).sort();

const upstreamValues = setOf(upstream.valueExports);
const upstreamTypes = setOf(upstream.typeExports);
const psflowValues = setOf(psflow.valueExports);
const psflowTypes = setOf(psflow.typeExports);

const upstreamAll = setOf([...upstream.valueExports, ...upstream.typeExports]);
const psflowAll = setOf([...psflow.valueExports, ...psflow.typeExports]);

const missingValues = diff(upstreamValues, psflowValues);
const missingTypes = diff(upstreamTypes, psflowTypes);
const missingRaw = [...missingValues, ...missingTypes].sort();
const extraRaw = diff(psflowAll, upstreamAll);

const missing = claim(missingRaw, allowMissing);
const extra = claim(extraRaw, allowExtra);

// ─── Shape divergence (fails the run) ─────────────────────────────────────
// Applied to every export PSFlow publishes, not scoped to the boundary
// manifest's crossed set. A gate bounded by the conversion plan would be
// invisible-by-construction outside it — this effort's own bug in miniature,
// and the class it would have hidden longest (component wrapper kind, stage 4
// at the earliest) is the one a ~20-line scratch script rediscovered ticket 27
// from, before this gate existed.
//
// The set compared is PSFlow's exports, not the union of both sides, and the
// asymmetry is the same one the missing/extra buckets draw. A PSFlow-only
// export has no upstream shape, reads as `absent` here, and still needs a
// written reason. An *upstream*-only value has nothing on this side to have a
// shape at all — it is a missing export, reported once as that rather than
// twice as a name and a shape.
const shapeRows = shapeDifferences(upstream.shapes ?? {}, psflow.shapes ?? {}, psflow.valueExports);
const shapeByName = new Map(shapeRows.map((r) => [r.name, r]));
const shapeDiff = claim(
  shapeRows.map((r) => r.name),
  allowShapes
);

// ─── Value behavior (fails the run) ──────────────────────────────────────
// The upstream extractor has already bundled and imported the vendored entry
// point to read shapes. Import that exact artifact here and compare it with the
// package barrel a consumer reaches. The fixtures in behavior.mjs are cloned
// from one frozen input for each side, so this is call-and-compare rather than
// two expectations which merely happen to look alike.
const upstreamRuntime = await import(pathToFileURL(join(here, "upstream-bundle.mjs")).href);
const psflowRuntime = await import(pathToFileURL(join(here, "..", "..", "index.js")).href);
const behaviorRows = behaviorDifferences(upstreamRuntime, psflowRuntime);
const behaviorById = new Map(
  [...behaviorRows.enums, ...behaviorRows.functions].map((row) => [row.id, row])
);
const behaviorEnums = claim(behaviorRows.enums.map((row) => row.id), allowBehaviorEnums);
const behaviorFunctions = claim(behaviorRows.functions.map((row) => row.id), allowBehaviorFunctions);

// ─── Prop diffs (fails the run) ───────────────────────────────────────────
// `props.<Type>.rename` maps an upstream member name to the PSFlow name that
// stands in for it. It is applied to the *upstream* set before diffing, so an
// intentional rename cancels on both sides from a single entry instead of
// surfacing as two rows (one missing, one extra) that can drift apart later.
// This is how 069's xPos → positionAbsoluteX should have been expressible.
const propDiff = (name) => {
  const cfg = allow.props?.[name] ?? {};
  const renames = cfg.rename ?? {};
  const upstreamMembers = upstream.props[name] ?? [];
  const psflowMembers = psflow.props[name] ?? [];
  const up = setOf(upstreamMembers.map((m) => renames[m] ?? m));
  const ps = setOf(psflowMembers);
  // `drift` annotates a member in the report and suppresses nothing, so it is
  // not a claim — but a drift key naming a member neither side has any longer
  // is as stale as any other entry, and goes stale by the same rule.
  const annotated = setOf([...upstreamMembers, ...psflowMembers]);
  return {
    missing: claim(diff(up, ps), cfg.missing ?? {}),
    extra: claim(diff(ps, up), cfg.extra ?? {}),
    renames: liveRenames(renames, upstreamMembers, psflowMembers),
    drift: claim([...annotated], cfg.drift ?? {}).stale,
  };
};
const propResults = Object.fromEntries(PROP_TYPES.map((p) => [p.name, propDiff(p.name)]));

const propFailures = PROP_TYPES.filter(
  (p) =>
    propResults[p.name].missing.unclaimed.length > 0 ||
    propResults[p.name].extra.unclaimed.length > 0
).map((p) => p.name);

// ─── Stale entries (fails the run) ────────────────────────────────────────
// One register, one rule: an entry that no longer corresponds to a real
// difference fails. Permanent entries included — a permanent entry that stops
// matching means upstream changed or PSFlow gained the export, and either is
// worth hearing about. Without this, a boundary stage erases six shape
// divergences, nobody deletes the entries, and the allowlist covers
// differences that no longer exist so the next real one lands on a live entry.
const staleEntries = [
  ...missing.stale.map((n) => [`exports.missing.${n}`, "no upstream export of that name is missing from PSFlow"]),
  ...extra.stale.map((n) => [`exports.extra.${n}`, "PSFlow no longer publishes that name, or upstream now does too"]),
  ...shapeDiff.stale.map((n) => [`shapes.${n}`, "the two shapes agree now — the divergence it recorded is gone"]),
  ...behaviorEnums.stale.map((n) => [`behavior.enums.${n}`, "the frozen enum objects no longer differ in that class"]),
  ...behaviorFunctions.stale.map((n) => [`behavior.functions.${n}`, "that call no longer differs in that class"]),
  ...PROP_TYPES.flatMap((p) => {
    const r = propResults[p.name];
    return [
      ...r.missing.stale.map((n) => [`props.${p.name}.missing.${n}`, "that member is not missing from PSFlow"]),
      ...r.extra.stale.map((n) => [`props.${p.name}.extra.${n}`, "PSFlow no longer has that extra member"]),
      ...r.renames.stale.map((n) => [`props.${p.name}.rename.${n}`, "the rename cancels nothing: check both names still exist, one per side"]),
      ...r.drift.map((n) => [`props.${p.name}.drift.${n}`, "no member of that name on either side to annotate"]),
    ];
  }),
];

// ─── Report ───────────────────────────────────────────────────────────────
const now = new Date().toISOString().slice(0, 10);
const list = (xs) => (xs.length ? xs.map((x) => `\`${x}\``).join(", ") : "_none_");
const knownTable = (names, allowMap) =>
  names.length
    ? names.map((n) => `| \`${n}\` | ${allowMap[n]} |`).join("\n")
    : "| _none_ | |";

const propSection = (name, r) => {
  const cfg = allow.props?.[name] ?? {};
  const drift = cfg.drift ?? {};
  const annotate = (x) => (drift[x] ? `\`${x}\` _(${drift[x]})_` : `\`${x}\``);
  return [
    `### ${name}`,
    "",
    `- upstream members: ${(upstream.props[name] ?? []).length}, PSFlow members: ${(psflow.props[name] ?? []).length}`,
    `- **missing in PSFlow** (${r.missing.unclaimed.length}): ${
      r.missing.unclaimed.length ? r.missing.unclaimed.map(annotate).join(", ") : "_none_"
    }`,
    `- **extra in PSFlow** (${r.extra.unclaimed.length}): ${list(r.extra.unclaimed)}`,
    r.renames.live.length
      ? `- allowlisted renames: ${r.renames.live.map(([from, to]) => `\`${from}\` → \`${to}\``).join(", ")}`
      : null,
    r.missing.claimed.length
      ? `- allowlisted missing: ${r.missing.claimed.map((n) => `\`${n}\` _(${cfg.missing[n]})_`).join(", ")}`
      : null,
    r.extra.claimed.length
      ? `- allowlisted extra: ${r.extra.claimed.map((n) => `\`${n}\` _(${cfg.extra[n]})_`).join(", ")}`
      : null,
    "",
  ]
    .filter((l) => l !== null)
    .join("\n");
};

const shapeTable = (names, { withReason }) =>
  names.length
    ? names
        .map((n) => {
          const row = shapeByName.get(n);
          const cells = [`\`${n}\``, `\`${row.upstream}\``, `\`${row.psflow}\``];
          if (withReason) cells.push(allowShapes[n] ?? "");
          return `| ${cells.join(" | ")} |`;
        })
        .join("\n")
    : `| _none_ |${" |".repeat(withReason ? 3 : 2)}`;

const shortObservation = (observation) => {
  const text = describeObservation(observation).replace(/\|/g, "\\|").replace(/\r?\n/g, " ");
  return text.length > 180 ? `${text.slice(0, 177)}…` : text;
};

const behaviorTable = (names, allowMap = null) =>
  names.length
    ? names.map((id) => {
        const row = behaviorById.get(id);
        const cells = [
          `\`${row.name}\``,
          `\`${row.differenceClass}\``,
          shortObservation(row.upstream),
          shortObservation(row.psflow),
        ];
        if (allowMap) cells.push(allowMap[id] ?? "");
        return `| ${cells.join(" | ")} |`;
      }).join("\n")
    : `| _none_ |${" |".repeat(allowMap ? 4 : 3)}`;

const report = `# Surface parity — export, shape, behavior and prop-member report

_Generated by \`npm run parity:surface\` — do not edit by hand. Last run: ${now}._

Upstream: \`@xyflow/react\` **${upstream.reactVersion}** / \`@xyflow/system\` **${upstream.systemVersion}**.
PSFlow was originally ported against \`@xyflow/react@^12.3.5\`. Every changelog
entry between that floor and the baseline above has since been bucketed by the
12.3.5→12.11.0 drift audit (ticket 071), so a divergence below is a genuine
port gap, not unclassified version drift — see
[\`parity/changelog-audit/report.md\`](../changelog-audit/report.md).

Method: names and prop members are extracted from upstream via the TypeScript
compiler API (resolves \`export *\`, renames, type-only exports) and *shapes* by
bundling the same vendored entry point and importing it — \`forwardRef\` and
\`memo\` are calls, not declarations. PSFlow's values come from **importing**
\`index.js\`, which is why this gate needs \`spago build\` first and is no longer
standalone; its type names still come from \`src/React.purs\`, types having no
runtime existence to import.

The same two imported barrels supply the behavioral checks: frozen snapshots
of the eight enum objects are deep-compared, then seventeen pure functions are
called with cloned copies of one shared input each and their returns compared.
This is still a seconds-only Node gate; it mounts nothing and needs no browser.

An upstream **value** is satisfied only by a PSFlow **value**. The two name
sets were merged until ticket 041, which passed nine audience-reaching absences
by construction: \`import { Position } from 'ps-flow'\` was \`undefined\` while
this report called it present. The *extra* bucket keeps the union, because it
asks a different question — whether PSFlow publishes a name upstream does not
have at all.

**Every allowlist entry below is live.** An entry that no longer corresponds to
a real difference **fails as stale**, permanent entries included — the
allowlist is the second implementation of a **region** (\`CONTEXT.md\`), and the
rule is the same on both: a register bites when its entries stop being true,
instead of accumulating silently until a real divergence lands on one and
passes.

## Top-level exports

- upstream: ${upstreamAll.size} names (${upstream.valueExports.length} value + ${upstream.typeExports.length} type)
- PSFlow: ${psflowAll.size} names (${psflow.valueExports.length} value + ${psflow.typeExports.length} type)

### ❌ Missing in PSFlow (parity gaps — gates CI)

${missing.unclaimed.length ? missing.unclaimed.map((x) => `- \`${x}\` (${upstreamValues.has(x) ? "value" : "type"})`).join("\n") : "_none — full parity (modulo the allowlist below)._"}

### ➕ Extra in PSFlow (extensions / PS-idiom — informational)

${extra.unclaimed.length ? extra.unclaimed.map((x) => `- \`${x}\``).join("\n") : "_none._"}

### 📋 Known divergences (allowlisted)

**Intentionally absent from PSFlow:**

| Symbol | Rationale |
|--------|-----------|
${knownTable(missing.claimed, allowMissing)}

**PSFlow-only, intentional:**

| Symbol | Rationale |
|--------|-----------|
${knownTable(extra.claimed, allowExtra)}

## Shape parity (gates CI)

\`typeof\`, arity and React wrapper kind of every value \`index.js\` publishes,
compared against the vendored upstream's. Deliberately **not** scoped to the
boundary manifest's crossed set: a gate bounded by the conversion plan is
invisible-by-construction outside it, and the class that would have hidden
longest — component wrapper kind, boundary stage 4 at the earliest — is the one
this comparison rediscovered ticket 27 from.

Sharp edge, accepted: \`Function.length\` ignores default and rest parameters,
so an arity difference is occasionally a legitimate difference in how the two
sides declare their parameters rather than a currying gap. Those entries are
permanent rather than transitional.

- compared: ${psflow.valueExports.length} · same shape: ${psflow.valueExports.length - shapeRows.length} · differ: ${shapeRows.length}

### ❌ Un-allowlisted shape divergence (gates CI)

| Symbol | upstream | PSFlow |
|--------|----------|--------|
${shapeTable(shapeDiff.unclaimed, { withReason: false })}

### 📋 Known shape divergences (allowlisted)

Each entry names the event that retires it, so a boundary stage's definition of
done is mechanical: delete that stage's entries and this gate must stay green.

| Symbol | upstream | PSFlow | Retired by |
|--------|----------|--------|------------|
${shapeTable(shapeDiff.claimed, { withReason: true })}

## Value behavior parity (gates CI)

The eight enum objects must be frozen and deep-equal upstream. The seventeen
pure functions are then called through \`index.js\` with the same inputs as the
vendored upstream bundle. A difference is keyed by both export and class, so an
allowlisted currying gap cannot later hide a different return-value regression.

- enum objects compared: 8 · differ: ${behaviorRows.enums.length}
- pure functions called: 17 · agree: ${17 - behaviorRows.functions.length} · differ: ${behaviorRows.functions.length}

### ❌ Un-allowlisted enum divergence (gates CI)

| Export | Difference class | upstream | PSFlow |
|--------|------------------|----------|--------|
${behaviorTable(behaviorEnums.unclaimed)}

### ❌ Un-allowlisted pure-function divergence (gates CI)

| Export | Difference class | upstream | PSFlow |
|--------|------------------|----------|--------|
${behaviorTable(behaviorFunctions.unclaimed)}

### 📋 Known behavioral divergences (allowlisted)

Every entry names its retiring boundary stage. Fixing only part of a divergence
changes its class, which makes the old entry stale and the new class unclaimed.

| Export | Difference class | upstream | PSFlow | Retired by |
|--------|------------------|----------|--------|------------|
${behaviorTable(
  [...behaviorEnums.claimed, ...behaviorFunctions.claimed],
  { ...allowBehaviorEnums, ...allowBehaviorFunctions }
)}

## Prop-member parity (gates CI)

Members are restricted to those declared in the xyflow sources (inherited React
DOM attributes are excluded on both sides). Divergence must be declared in
\`allowlist.json\` under \`props.<Type>\` — as a \`rename\` (an upstream member
PSFlow surfaces under another name, cancelled on both sides by one entry) or as
a \`missing\`/\`extra\` entry with a rationale. Anything else fails the gate. The
\`xPos\`/\`yPos\` → \`positionAbsoluteX\`/\`positionAbsoluteY\` rename that this
section once merely printed was closed by ticket 069.

A rename is live only while all three of its premises hold — upstream still has
the name it translates from, PSFlow still has the name it translates to, and
PSFlow does not also publish upstream's own name. A rename that cancels nothing
is stale, and a rename standing in front of a member PSFlow has since added
under upstream's own name would otherwise hide a genuine extra member.

**Limit of this comparison: it is name-only.** Neither \`upstream.json\` nor
\`psflow.json\` carries member *types*, so a member whose type or arity changed
upstream while keeping its name still passes. That is an accepted limit, not an
oversight — making it type-aware needs a PureScript type printer, since today's
PS extraction is a brace-depth scan over \`type X = { … }\` synonyms. Tracked
separately; do not read a passing prop gate as a guarantee of type parity.

${PROP_TYPES.map((p) => propSection(p.name, propResults[p.name])).join("\n")}`;

writeFileSync(join(here, "report.md"), report);

// ─── Console summary + gates ──────────────────────────────────────────────
console.log(`[diff] missing(gap)=${missing.unclaimed.length} extra=${extra.unclaimed.length} ` +
  `allowlisted(missing)=${missing.claimed.length} allowlisted(extra)=${extra.claimed.length}`);
console.log(
  `[diff] shapes compared=${psflow.valueExports.length} ` +
    `same=${psflow.valueExports.length - shapeRows.length} ` +
    `differ=${shapeDiff.unclaimed.length} allowlisted=${shapeDiff.claimed.length}`
);
console.log(
  `[diff] behavior enums=8/${behaviorRows.enums.length}/${behaviorEnums.unclaimed.length} ` +
    `functions=17/${behaviorRows.functions.length}/${behaviorFunctions.unclaimed.length} ` +
    "(checked/differ/unallowlisted)"
);
console.log(
  `[diff] props ` +
    PROP_TYPES.map(
      (p) =>
        `${p.name}=${propResults[p.name].missing.unclaimed.length}/${propResults[p.name].extra.unclaimed.length}`
    ).join(" ") +
    " (missing/extra, after allowlist)"
);
console.log(`[diff] report → ${join(here, "report.md")}`);

if (missing.unclaimed.length > 0) {
  console.error(`\n[diff] FAIL: ${missing.unclaimed.length} upstream export(s) missing from PSFlow and not allowlisted:`);
  for (const n of missing.unclaimed) console.error(`  - ${n} (${upstreamValues.has(n) ? "value" : "type"})`);
  console.error(
    "An upstream value is satisfied only by a PSFlow value: a runtime object held\n" +
      "here as a PureScript type is `undefined` to a JS consumer. Triage into a\n" +
      "ticket and add to allowlist.json, or surface the gap."
  );
  process.exitCode = 1;
}

if (shapeDiff.unclaimed.length > 0) {
  console.error(`\n[diff] FAIL: ${shapeDiff.unclaimed.length} export(s) differ in shape and are not allowlisted:`);
  for (const n of shapeDiff.unclaimed) {
    const row = shapeByName.get(n);
    console.error(`  - ${n}: upstream ${row.upstream}, PSFlow ${row.psflow}`);
  }
  console.error(
    "Cross the export in the boundary module, or add it to allowlist.json under\n" +
      "`shapes` with a reason naming the boundary stage or ticket that retires it."
  );
  process.exitCode = 1;
}

const unclaimedBehavior = [
  ...behaviorEnums.unclaimed.map((id) => behaviorById.get(id)),
  ...behaviorFunctions.unclaimed.map((id) => behaviorById.get(id)),
];
if (unclaimedBehavior.length > 0) {
  console.error(`\n[diff] FAIL: ${unclaimedBehavior.length} value behavior difference(s) are not allowlisted:`);
  for (const row of unclaimedBehavior) {
    console.error(`  - ${row.name} [${row.differenceClass}]`);
    console.error(`      upstream ${shortObservation(row.upstream)}`);
    console.error(`      PSFlow   ${shortObservation(row.psflow)}`);
  }
  console.error(
    "Cross the export in the boundary module, or add its `<export>.<difference-class>`\n" +
      "id under `behavior` with a reason naming the boundary stage that retires it."
  );
  process.exitCode = 1;
}

if (propFailures.length > 0) {
  console.error(`\n[diff] FAIL: prop-member divergence not allowlisted in ${propFailures.length} record(s):`);
  for (const name of propFailures) {
    const r = propResults[name];
    for (const m of r.missing.unclaimed) console.error(`  - ${name}: missing in PSFlow: ${m}`);
    for (const e of r.extra.unclaimed) console.error(`  - ${name}: extra in PSFlow: ${e}`);
  }
  console.error(
    "Add the member to the PS record, or declare it in allowlist.json under\n" +
      "props.<Type>.rename (upstream name → PSFlow name) or props.<Type>.{missing,extra}."
  );
  process.exitCode = 1;
}

if (malformed.length > 0) {
  console.error(`\n[diff] FAIL: ${malformed.length} allowlist register(s) hold an entry nobody can act on:`);
  for (const message of malformed) console.error(`  - ${message}`);
  process.exitCode = 1;
}

if (staleEntries.length > 0) {
  console.error(`\n[diff] FAIL: ${staleEntries.length} allowlist entr(y|ies) claim nothing — stale:`);
  for (const [path, why] of staleEntries) console.error(`  - ${path}: ${why}`);
  console.error(
    "Delete them. An entry outlives its cause by exactly one run: a fix that leaves\n" +
      "its entry behind leaves the allowlist covering a difference that no longer\n" +
      "exists, so the next real one lands on a live entry and passes."
  );
  process.exitCode = 1;
}

if (
  !missing.unclaimed.length &&
  !shapeDiff.unclaimed.length &&
  !behaviorEnums.unclaimed.length &&
  !behaviorFunctions.unclaimed.length &&
  !propFailures.length &&
  !staleEntries.length &&
  !malformed.length
) {
  console.log(
    "[diff] OK: no un-allowlisted missing exports, shape, behavior or prop divergence,\n" +
      "       and every allowlist entry claims something."
  );
}
