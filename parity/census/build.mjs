// Census generator — ticket #15 on wayfinder map #14.
//
// Joins the hand-curated `classification.json` against the machine-extracted
// surface (`../surface/upstream.json`, `psflow.json`) and the `@psflow/oracle`
// bundle (`../../oracle/index.js`), and writes `report.md`.
//
// The point of generating rather than hand-writing the table: on a baseline
// bump, `npm run parity:surface` refreshes upstream.json, and this script then
// *fails* on any export that appeared or vanished without being classified.
// A census that silently goes stale is worse than none.
//
//   node parity/census/build.mjs
//
// Exit 1 = the classification no longer matches the surface. Fix
// classification.json, don't loosen this script.

import { readFileSync, writeFileSync, existsSync, readdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { manifest } from "../../src/Boundary.js";
import { ENUM_EXPORTS, PURE_FUNCTION_CALLS } from "../surface/behavior.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const read = (p) => JSON.parse(readFileSync(join(here, p), "utf8"));

const upstream = read("../surface/upstream.json");
const psflow = read("../surface/psflow.json");
const classification = read("./classification.json");

const oracleSrc = readFileSync(join(here, "../../oracle/index.js"), "utf8");
const oracleExports = new Set(
  (oracleSrc.match(/export \{([\s\S]*?)\};/)?.[1] ?? "")
    .split(",")
    .map((s) => s.trim())
    // Two of the entry list's names exist in both upstream packages — the
    // React `addEdge` wraps the system one — so esbuild renames the local and
    // re-exports it as `addEdge2 as addEdge`. The half after `as` is the name
    // an importer writes, which is what a function-parity claim is about.
    .map((s) => s.split(/\s+as\s+/).pop())
    .filter(Boolean)
);

const upstreamValues = new Set(upstream.valueExports);
const upstreamNames = [...upstream.valueExports, ...upstream.typeExports];
const psValues = new Set(psflow.valueExports);
const psTypes = new Set(psflow.typeExports);
const crossed = new Set(manifest.crossed);
const passthrough = new Set(manifest.passthrough);
const behaviorExports = new Set([
  ...ENUM_EXPORTS,
  ...PURE_FUNCTION_CALLS.map(({ name }) => name),
]);
const BOUNDARY_STATUS = Object.freeze({
  crossed: Object.freeze({ label: "crossed", isCrossed: true }),
  passthrough: Object.freeze({ label: "passthrough", isCrossed: false }),
  absent: Object.freeze({ label: "no runtime value", isCrossed: false }),
});

// ── Gate vocabulary ────────────────────────────────────────────────────────
// A gate token is either a bare name (a gate with no per-row spec) or
// `<suite>:<spec file>` / `<suite>-indirect:<spec file>`. The suffix is what
// separates "a spec asserts this" from "a fixture happens to mount it".
const SPEC_DIR = join(here, "../../examples/react-smoke/tests");

// Which surface a bare gate proves. Both read below the JS surface: function
// parity imports `System.Utils.*` and the prop-member diff reads the records
// in `src/React/Types/*.purs`. Neither loads `index.js`.
const FLAT_GATES = {
  boundary: "js",
  function: "ps",
  "surface-props": "ps",
};

// The suites a `<suite>:<spec>` token may name. Closed, because the whole
// point of this ticket is that the retired names must not survive anywhere:
// without this, `L2:generic-edges.spec.ts` would parse, print, and keep the
// numbering alive in the register that is supposed to have shed it.
const SPEC_SUITES = new Set(["conformance", "smoke", "node-props"]);

// Every browser spec enters through the driver page, which is bundled with
// `@xyflow/react` aliased to `index.js`. The compiled `Example.Main` page was
// retired by ticket 050; naming its old URL is now a contract violation rather
// than a second surface the census will classify.
const JS_SURFACE_PAGE = "/parity/driver/index.html";
const RETIRED_PS_SURFACE_PAGE = "/examples/react-smoke/index.html";

const specSurfaces = new Map();
const specErrors = [];

const surfaceOfSpec = (spec) => {
  if (specSurfaces.has(spec)) return specSurfaces.get(spec);
  let surface = null;
  const path = join(SPEC_DIR, spec);
  if (!existsSync(path)) {
    specErrors.push(`named spec does not exist: examples/react-smoke/tests/${spec}`);
  } else {
    const src = readFileSync(path, "utf8");
    const js = src.includes(JS_SURFACE_PAGE);
    const retired = src.includes(RETIRED_PS_SURFACE_PAGE);
    if (retired) {
      specErrors.push(
        `${spec} enters through the retired Example.Main page ` +
          `(${RETIRED_PS_SURFACE_PAGE}); every browser spec must use ${JS_SURFACE_PAGE}.`
      );
    } else if (js) surface = "js";
    else {
      specErrors.push(
        `${spec} does not load ${JS_SURFACE_PAGE}; every browser spec must enter ` +
          `through the JS surface.`
      );
    }
  }
  specSurfaces.set(spec, surface);
  return surface;
};

// The contract applies to every executable browser spec, not only specs that
// happen to be cited by an export's hand-maintained gate attribution.
for (const spec of readdirSync(SPEC_DIR).filter((name) => name.endsWith(".spec.ts"))) {
  surfaceOfSpec(spec);
}

// { suite, spec, indirect, surface } — surface is null when unresolvable.
const parseGate = (name, token) => {
  const colon = token.indexOf(":");
  if (colon === -1) {
    const surface = FLAT_GATES[token];
    if (!surface) {
      specErrors.push(`${name}: unknown gate \`${token}\``);
      return { suite: token, spec: null, indirect: false, surface: null };
    }
    return { suite: token, spec: null, indirect: false, surface };
  }
  const tagged = token.slice(0, colon);
  const spec = token.slice(colon + 1);
  const indirect = tagged.endsWith("-indirect");
  const suite = indirect ? tagged.slice(0, -"-indirect".length) : tagged;
  if (!SPEC_SUITES.has(suite)) {
    specErrors.push(
      `${name}: unknown suite \`${suite}\` in gate \`${token}\` ` +
        `(known: ${[...SPEC_SUITES].join(", ")})`
    );
    return { suite, spec, indirect, surface: null };
  }
  return { suite, spec, indirect, surface: surfaceOfSpec(spec) };
};

// ── Consistency gates ──────────────────────────────────────────────────────
const classified = Object.keys(classification).filter((k) => !k.startsWith("_"));
const errors = [];

const unclassified = upstreamNames.filter((n) => !(n in classification));
if (unclassified.length) {
  errors.push(`Unclassified upstream exports (${unclassified.length}): ${unclassified.join(", ")}`);
}
const stale = classified.filter((n) => !upstreamNames.includes(n));
if (stale.length) {
  errors.push(`Classified names no longer in the upstream surface (${stale.length}): ${stale.join(", ")}`);
}

const manifestNames = [...manifest.crossed, ...manifest.passthrough];
const ambiguousManifestNames = manifest.crossed.filter((name) => passthrough.has(name));
const absentFromManifest = [...psValues].filter((name) => !crossed.has(name) && !passthrough.has(name));
const staleInManifest = manifestNames.filter((name) => !psValues.has(name));
if (ambiguousManifestNames.length) {
  errors.push(
    `Boundary manifest names marked both crossed and passthrough (${ambiguousManifestNames.length}): ` +
      ambiguousManifestNames.join(", ")
  );
}
if (absentFromManifest.length) {
  errors.push(
    `PSFlow runtime exports absent from the boundary manifest (${absentFromManifest.length}): ` +
      absentFromManifest.join(", ")
  );
}
if (staleInManifest.length) {
  errors.push(
    `Boundary manifest names with no PSFlow runtime export (${staleInManifest.length}): ` +
      staleInManifest.join(", ")
  );
}

// A function-parity claim on a pure function must be backed by the oracle
// bundle actually exporting it — one of the two gate claims verifiable
// mechanically. The other is that every named spec file exists and says which
// door it entered through, checked by parseGate below.
for (const name of upstreamNames) {
  const entry = classification[name];
  if (!entry) continue;
  const [kind, , gates] = entry;
  if (kind !== "pure-fn") continue;
  const claimsFunction = gates.includes("function");
  const inOracle = oracleExports.has(name);
  if (claimsFunction && !inOracle) {
    errors.push(`${name} claims function parity but oracle/index.js does not export it.`);
  }
  if (!claimsFunction && inOracle) {
    errors.push(`${name} is in the oracle bundle but does not claim function parity.`);
  }
}

const parsedGates = new Map(classified.map((name) => {
  const attributed = classification[name][2].map((g) => parseGate(name, g));
  const surfaceBehavior = behaviorExports.has(name)
    ? [{ suite: "surface", spec: "behavior", indirect: false, surface: "js" }]
    : [];
  return [name, [...surfaceBehavior, ...attributed]];
}));
errors.push(...specErrors);

if (errors.length) {
  console.error("Census is out of date:\n" + errors.map((e) => "  - " + e).join("\n"));
  process.exit(1);
}

// ── Report ─────────────────────────────────────────────────────────────────
const KIND_ORDER = [
  "component", "hook", "pure-fn", "enum-value",
  "props", "callback", "change", "data", "options",
  "instance-api", "store", "internal-type",
];

const rows = upstreamNames
  .map((name) => {
    const [kind, mechanism, , note] = classification[name];
    return {
      name,
      kind,
      mechanism,
      gates: parsedGates.get(name),
      note,
      upstreamValue: upstreamValues.has(name),
      psValue: psValues.has(name),
      psType: psTypes.has(name),
      boundaryStatus: crossed.has(name)
        ? BOUNDARY_STATUS.crossed
        : passthrough.has(name)
          ? BOUNDARY_STATUS.passthrough
          : BOUNDARY_STATUS.absent,
    };
  })
  .sort((a, b) => {
    const k = KIND_ORDER.indexOf(a.kind) - KIND_ORDER.indexOf(b.kind);
    return k !== 0 ? k : a.name.localeCompare(b.name);
  });

// "Gated" is always relative to one surface — a row can be gated on one and
// not the other, and the two counts are never summed.
const gatedOn = (r, surface) => r.gates.some((g) => !g.indirect && g.surface === surface);
const anyGated = (r) => gatedOn(r, "ps") || gatedOn(r, "js");
const indirectOnly = (r) => r.gates.length > 0 && !anyGated(r);
const provenByNothing = (r) => r.gates.length === 0;
const crossedAndUngatedOnJs = (r) => r.boundaryStatus.isCrossed && !gatedOn(r, "js");

const tally = (pred) => rows.filter(pred).length;
const crossedUngatedCount = tally(crossedAndUngatedOnJs);
const byKind = KIND_ORDER.map((kind) => {
  const ks = rows.filter((r) => r.kind === kind);
  return {
    kind,
    total: ks.length,
    ps: ks.filter((r) => gatedOn(r, "ps")).length,
    js: ks.filter((r) => gatedOn(r, "js")).length,
    crossedUngatedJs: ks.filter(crossedAndUngatedOnJs).length,
    indirect: ks.filter(indirectOnly).length,
    nothing: ks.filter(provenByNothing).length,
  };
}).filter((r) => r.total > 0);

// A gate reads as its suite plus the spec that would go red; a bare gate has
// no spec to name, and a single-spec suite would only repeat itself. `~` marks
// indirect.
const gateLabel = (g) => {
  const spec = g.spec?.replace(/\.spec\.ts$/, "");
  const body = !spec || spec === g.suite ? g.suite : `${g.suite} (${spec})`;
  return body + (g.indirect ? " ~" : "");
};
const gateCell = (r, surface) => {
  const gs = r.gates.filter((g) => g.surface === surface);
  return gs.length ? gs.map(gateLabel).join(" + ") : "—";
};
const jsStatusCell = (r) => {
  const gates = gateCell(r, "js");
  const status = `${r.boundaryStatus.label}, ${gatedOn(r, "js") ? "gated" : "ungated"}`;
  return gates === "—" ? status : `${status} — ${gates}`;
};
const allGatesCell = (r) => (r.gates.length ? r.gates.map(gateLabel).join(" + ") : "—");

const out = [];
out.push("# Export census — which gate can prove which public export?");
out.push("");
out.push("_Generated by `node parity/census/build.mjs` — edit `classification.json`, not this file._");
out.push("");
out.push(`Surface: \`@xyflow/react\` **${upstream.reactVersion}** / \`@xyflow/system\` **${upstream.systemVersion}** — ` +
  `${upstreamNames.length} top-level exports (${upstream.valueExports.length} value + ${upstream.typeExports.length} type), ` +
  "as enumerated by `parity/surface/upstream.json`.");
out.push("");
out.push("Surface parity (`npm run parity:surface`) checks **name presence** for every row.");
out.push("The `Gates today` columns list only what reaches further than that, and a trailing");
out.push("`~` marks a gate that mounts or traverses the export without asserting anything");
out.push("specific to it — it would not fail if the behaviour diverged.");
out.push("");
out.push("**Gated is always relative to one surface**, so the question is asked twice and");
out.push("the two counts are never summed. Which column a browser gate lands in is derived,");
out.push("not declared: every browser spec must load `parity/driver/index.html`, which enters");
out.push("through `index.js` — the **JS surface** — or the census fails. Function parity and");
out.push("the prop-member diff read below `index.js` and are therefore PureScript-surface");
out.push("gates, which is why the gate whose name sounds closest to the JS surface is among");
out.push("the furthest from it.");
out.push("");
out.push("The JS-surface status joins the boundary manifest to gates that enter through");
out.push("`index.js`. Browser-spec and boundary-check attribution is hand-maintained in");
out.push("`classification.json`; surface parity's enum and function attribution comes from");
out.push("its own behavior registry. `crossed` means a JS-shaped wrapper exists; `passthrough`");
out.push("means `index.js` still publishes the PureScript value unchanged. A crossed export");
out.push("with no direct JS-surface gate is displayed as `crossed, ungated`, rather than");
out.push("being counted as gated on the JS surface merely because its wrapper exists.");
out.push(`At boundary stage ${manifest.stage}, ${manifest.crossed.length} exports have crossed; ` +
  `${crossedUngatedCount} ${crossedUngatedCount === 1 ? "is" : "are"} crossed but ungated on`);
out.push("the JS surface. Stage 1 is self-covering; later stages deliberately populate");
out.push("that window until system parity gates their converters.");
out.push("");
out.push("The `Mechanism` column is about the **implementation**, not the JS-facing");
out.push("property: `oracle` calls PureScript functions from PureScript, where currying");
out.push("and record returns are correct by construction, so it can never prove anything");
out.push("about the shape a JavaScript caller receives.");
out.push("");
out.push("**Which exports the net actually drove is not a column here.** That number is");
out.push("derived from traces that ran rather than from this file's static");
out.push("classification, and it lives in its own artifact:");
out.push("[`parity/system/coverage.md`](../system/coverage.md), generated by");
out.push("`npm run parity:coverage` and by every system-parity run. A column would make");
out.push("this generator unbuildable until someone had run the entire net — a far heavier");
out.push("prerequisite than the `spago build` surface parity already reluctantly took on —");
out.push("so the census carries the pointer and nothing else. The join runs the other way:");
out.push("the coverage artifact reads the `Mechanism` column here to decide which 156 of");
out.push("these entries the net can observe at all.");
out.push("");

out.push("## Summary by kind");
out.push("");
out.push("| Kind | Total | Gated — PureScript surface | Gated — JS surface | Crossed, ungated — JS surface | Indirect only | Nothing but the name |");
out.push("|---|---:|---:|---:|---:|---:|---:|");
for (const r of byKind) {
  out.push(
    `| \`${r.kind}\` | ${r.total} | ${r.ps} | ${r.js} | ${r.crossedUngatedJs} | ` +
      `${r.indirect} | ${r.nothing} |`
  );
}
out.push(`| **total** | **${rows.length}** | **${tally((r) => gatedOn(r, "ps"))}** | ` +
  `**${tally((r) => gatedOn(r, "js"))}** | **${crossedUngatedCount}** | ` +
  `**${tally(indirectOnly)}** | **${tally(provenByNothing)}** |`);
out.push("");

out.push("## Summary by mechanism");
out.push("");
out.push("What *could* prove each export's implementation, if the dual-run net were built");
out.push("to reach it.");
out.push("");
out.push("| Mechanism | Exports | Of which gated on either surface |");
out.push("|---|---:|---:|");
const mechs = [...new Set(rows.map((r) => r.mechanism))].sort();
for (const m of mechs) {
  const ms = rows.filter((r) => r.mechanism === m);
  out.push(`| \`${m}\` | ${ms.length} | ${ms.filter(anyGated).length} |`);
}
out.push("");

const jsUnreachable = rows.filter((r) => r.upstreamValue && !r.psValue);
out.push("## Upstream values with no PSFlow runtime counterpart");
out.push("");
out.push("Surface parity compares names as a value-union-type set, so an upstream **runtime");
out.push("object** that PSFlow surfaces only as a PureScript **type** passes the gate. For a");
out.push("JS/TS consumer — the audience this repo exists for — the import is `undefined`.");
out.push("");
out.push("| Export | PSFlow surfaces | Reachable by |");
out.push("|---|---|---|");
for (const r of jsUnreachable) {
  out.push(`| \`${r.name}\` | ${r.psType ? "PureScript type only" : "nothing"} | ${allGatesCell(r)} |`);
}
out.push("");

out.push("## Full census");
out.push("");
out.push("| Export | Kind | Mechanism that could prove it | Gates today (PureScript surface) | JS-surface status | Notes |");
out.push("|---|---|---|---|---|---|");
for (const r of rows) {
  out.push(
    `| \`${r.name}\` | ${r.kind} | \`${r.mechanism}\` | ` +
      `${gateCell(r, "ps")} | ${jsStatusCell(r)} | ${r.note} |`
  );
}
out.push("");

writeFileSync(join(here, "report.md"), out.join("\n"));
console.log(
  `Census OK — ${rows.length} exports classified; ` +
    `${tally((r) => gatedOn(r, "ps"))} gated beyond name presence on the PureScript surface, ` +
    `${tally((r) => gatedOn(r, "js"))} on the JS surface, ` +
    `${crossedUngatedCount} crossed but ungated on the JS surface, ` +
    `${tally(provenByNothing)} proven by nothing.`
);
