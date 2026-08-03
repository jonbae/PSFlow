// Layer 0 — diff + report generator. Compares the upstream and PSFlow API
// surfaces extracted by the sibling scripts, subtracts the documented
// divergence allowlist, and writes `report.md` (a committed parity snapshot).
//
// Gates (all accumulate into `process.exitCode`, so one pass reports every
// failing bucket rather than stopping at the first):
//
//   * a non-empty "missing in PSFlow" *export* bucket after allowlisting;
//   * a non-empty missing/extra *prop-member* bucket after allowlisting.
//
// The prop buckets used to be informational — they printed divergence while
// the script still exited 0, which is exactly how the xPos/yPos rename
// (ticket 069) survived for months. They now gate. Legitimate divergence is
// expressed in allowlist.json rather than tolerated silently.

import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { PROP_TYPES } from "./prop-types.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const load = (name) => JSON.parse(readFileSync(join(here, name), "utf8"));

const upstream = load("upstream.json");
const psflow = load("psflow.json");
const allowPath = join(here, "allowlist.json");
const allow = existsSync(allowPath)
  ? load("allowlist.json")
  : { exports: { missing: {}, extra: {} }, props: {} };

const allowMissing = allow.exports?.missing ?? {};
const allowExtra = allow.exports?.extra ?? {};

const setOf = (xs) => new Set(xs);
const diff = (a, b) => [...a].filter((x) => !b.has(x)).sort();

// Unified name set per side. PSFlow models several TS enums (MarkerType,
// Position, …) as PureScript *types* where TS exports them as runtime
// *values*; comparing the union of value+type names sidesteps that
// value/type-classification mismatch and keeps the diff focused on genuinely
// absent/extra symbols.
const upstreamAll = setOf([...upstream.valueExports, ...upstream.typeExports]);
const psflowAll = setOf([...psflow.valueExports, ...psflow.typeExports]);

const missingRaw = diff(upstreamAll, psflowAll);
const extraRaw = diff(psflowAll, upstreamAll);

const partition = (names, allowMap) => {
  const known = [];
  const unexpected = [];
  for (const n of names) {
    if (Object.prototype.hasOwnProperty.call(allowMap, n)) known.push(n);
    else unexpected.push(n);
  }
  return { known, unexpected };
};

const missing = partition(missingRaw, allowMissing);
const extra = partition(extraRaw, allowExtra);

// ─── Prop diffs (gated) ───────────────────────────────────────────────────
// `props.<Type>.rename` maps an upstream member name to the PSFlow name that
// stands in for it. It is applied to the *upstream* set before diffing, so an
// intentional rename cancels on both sides from a single entry instead of
// surfacing as two rows (one missing, one extra) that can drift apart later.
// This is how 069's xPos → positionAbsoluteX should have been expressible.
const propDiff = (name) => {
  const cfg = allow.props?.[name] ?? {};
  const renames = cfg.rename ?? {};
  const up = setOf((upstream.props[name] ?? []).map((m) => renames[m] ?? m));
  const ps = setOf(psflow.props[name] ?? []);
  const rawMissing = diff(up, ps);
  const rawExtra = diff(ps, up);
  return {
    missing: partition(rawMissing, cfg.missing ?? {}),
    extra: partition(rawExtra, cfg.extra ?? {}),
    renames,
  };
};
const propResults = Object.fromEntries(PROP_TYPES.map((p) => [p.name, propDiff(p.name)]));

const propFailures = PROP_TYPES.filter(
  (p) =>
    propResults[p.name].missing.unexpected.length > 0 ||
    propResults[p.name].extra.unexpected.length > 0
).map((p) => p.name);

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
  const renameRows = Object.entries(r.renames);
  return [
    `### ${name}`,
    "",
    `- upstream members: ${(upstream.props[name] ?? []).length}, PSFlow members: ${(psflow.props[name] ?? []).length}`,
    `- **missing in PSFlow** (${r.missing.unexpected.length}): ${
      r.missing.unexpected.length ? r.missing.unexpected.map(annotate).join(", ") : "_none_"
    }`,
    `- **extra in PSFlow** (${r.extra.unexpected.length}): ${list(r.extra.unexpected)}`,
    renameRows.length
      ? `- allowlisted renames: ${renameRows.map(([u, p]) => `\`${u}\` → \`${p}\``).join(", ")}`
      : null,
    r.missing.known.length
      ? `- allowlisted missing: ${r.missing.known.map((n) => `\`${n}\` _(${cfg.missing[n]})_`).join(", ")}`
      : null,
    r.extra.known.length
      ? `- allowlisted extra: ${r.extra.known.map((n) => `\`${n}\` _(${cfg.extra[n]})_`).join(", ")}`
      : null,
    "",
  ]
    .filter((l) => l !== null)
    .join("\n");
};

const report = `# Layer 0 — API-surface parity report

_Generated by \`npm run parity:api\` — do not edit by hand. Last run: ${now}._

Upstream: \`@xyflow/react\` **${upstream.reactVersion}** / \`@xyflow/system\` **${upstream.systemVersion}**.
PSFlow was originally ported against \`@xyflow/react@^12.3.5\`. Every changelog
entry between that floor and the baseline above has since been bucketed by the
12.3.5→12.11.0 drift audit (ticket 071), so a divergence below is a genuine
port gap, not unclassified version drift — see
[\`parity/changelog-audit/report.md\`](../changelog-audit/report.md).

Method: top-level exports are extracted from upstream via the TypeScript
compiler API (resolves \`export *\`, renames, type-only exports) and from
PSFlow via \`index.js\` (values) + \`src/React.purs\` (types). Names are compared
as a value∪type union to neutralise the enum-as-value (TS) vs
sum-type-as-type (PS) modelling difference.

## Top-level exports

- upstream: ${upstreamAll.size} names (${upstream.valueExports.length} value + ${upstream.typeExports.length} type)
- PSFlow: ${psflowAll.size} names (${psflow.valueExports.length} value + ${psflow.typeExports.length} type)

### ❌ Missing in PSFlow (parity gaps — gates CI)

${missing.unexpected.length ? missing.unexpected.map((x) => `- \`${x}\``).join("\n") : "_none — full parity (modulo the allowlist below)._"}

### ➕ Extra in PSFlow (extensions / PS-idiom — informational)

${extra.unexpected.length ? extra.unexpected.map((x) => `- \`${x}\``).join("\n") : "_none._"}

### 📋 Known divergences (allowlisted)

**Intentionally absent from PSFlow:**

| Symbol | Rationale |
|--------|-----------|
${knownTable(missing.known, allowMissing)}

**PSFlow-only, intentional:**

| Symbol | Rationale |
|--------|-----------|
${knownTable(extra.known, allowExtra)}

## Prop-member parity (gates CI)

Members are restricted to those declared in the xyflow sources (inherited React
DOM attributes are excluded on both sides). Divergence must be declared in
\`allowlist.json\` under \`props.<Type>\` — as a \`rename\` (an upstream member
PSFlow surfaces under another name, cancelled on both sides by one entry) or as
a \`missing\`/\`extra\` entry with a rationale. Anything else fails the gate. The
\`xPos\`/\`yPos\` → \`positionAbsoluteX\`/\`positionAbsoluteY\` rename that this
section once merely printed was closed by ticket 069.

**Limit of this comparison: it is name-only.** Neither \`upstream.json\` nor
\`psflow.json\` carries member *types*, so a member whose type or arity changed
upstream while keeping its name still passes. That is an accepted limit, not an
oversight — making it type-aware needs a PureScript type printer, since today's
PS extraction is a brace-depth scan over \`type X = { … }\` synonyms. Tracked
separately; do not read a passing prop gate as a guarantee of type parity.

${PROP_TYPES.map((p) => propSection(p.name, propResults[p.name])).join("\n")}`;

writeFileSync(join(here, "report.md"), report);

// ─── Console summary + gates ──────────────────────────────────────────────
console.log(`[diff] missing(gap)=${missing.unexpected.length} extra=${extra.unexpected.length} ` +
  `allowlisted(missing)=${missing.known.length} allowlisted(extra)=${extra.known.length}`);
console.log(
  `[diff] props ` +
    PROP_TYPES.map(
      (p) =>
        `${p.name}=${propResults[p.name].missing.unexpected.length}/${propResults[p.name].extra.unexpected.length}`
    ).join(" ") +
    " (missing/extra, after allowlist)"
);
console.log(`[diff] report → ${join(here, "report.md")}`);

if (missing.unexpected.length > 0) {
  console.error(`\n[diff] FAIL: ${missing.unexpected.length} upstream export(s) missing from PSFlow and not allowlisted:`);
  for (const n of missing.unexpected) console.error(`  - ${n}`);
  console.error("Triage into a ticket and add to allowlist.json, or surface the gap.");
  process.exitCode = 1;
}

if (propFailures.length > 0) {
  console.error(`\n[diff] FAIL: prop-member divergence not allowlisted in ${propFailures.length} record(s):`);
  for (const name of propFailures) {
    const r = propResults[name];
    for (const m of r.missing.unexpected) console.error(`  - ${name}: missing in PSFlow: ${m}`);
    for (const e of r.extra.unexpected) console.error(`  - ${name}: extra in PSFlow: ${e}`);
  }
  console.error(
    "Add the member to the PS record, or declare it in allowlist.json under\n" +
      "props.<Type>.rename (upstream name → PSFlow name) or props.<Type>.{missing,extra}."
  );
  process.exitCode = 1;
}

if (!missing.unexpected.length && !propFailures.length) {
  console.log("[diff] OK: no un-allowlisted missing exports, no un-allowlisted prop divergence.");
}
