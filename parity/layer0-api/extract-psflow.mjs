// Layer 0 — PSFlow extractor. No new dependency: PSFlow's surfaced API is
// already written down in two hand-maintained barrels, so we read those
// directly rather than compile PureScript.
//
//   * value names  ← `index.js` (the JS surface). It re-exports the compiled
//     boundary module under TS-identical PascalCase names (`ReactFlow`,
//     `MiniMap`, …), so it already encodes the camelCase↔PascalCase mapping
//     the diff needs. Cross-checked against the boundary manifest, below.
//   * type names   ← `src/React.purs` re-export groups (`import … ( … ) as
//     ReExport*`). PureScript types are PascalCase; values are lowercase.
//     We keep the PascalCase tokens (stripping any `(..)` constructor marker).
//   * prop members ← the `ReactFlowProps` / `NodeProps` / `EdgeProps` record
//     definitions in `src/React/Types/{Component,Nodes,Edges}.purs`.
//
// Emits `psflow.json` with the same shape as `upstream.json`.

import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, resolve, join } from "node:path";
import { readFileSync, writeFileSync } from "node:fs";
import { PROP_TYPES } from "./prop-types.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");
const read = (p) => readFileSync(join(repoRoot, p), "utf8");

// ─── Value names from index.js ────────────────────────────────────────────
// `index.js` is a bare `export { … } from "./output/Boundary/index.js"`, so
// each entry is either `local as Public` or a bare name that needs no rename.
// The *public* name is what upstream is compared against.
const indexJs = read("index.js");
const exportBlocks = [
  ...indexJs.matchAll(/export\s*\{([\s\S]*?)\}\s*from\s*["'][^"']+["']/g),
];
const valueExports = exportBlocks.flatMap((block) =>
  block[1]
    .replace(/\/\/[^\n]*/g, "") // section comments
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean)
    .map((entry) => {
      const m = /^(\w+)(?:\s+as\s+(\w+))?$/.exec(entry);
      if (!m) {
        throw new Error(
          `[extract-psflow] unparsable export specifier in index.js: \`${entry}\`. ` +
            `index.js must stay a bare re-export — \`name\` or \`name as Public\`, nothing else.`
        );
      }
      return m[2] ?? m[1];
    })
);

if (valueExports.length === 0) {
  throw new Error(
    "[extract-psflow] index.js yielded no value exports. Either the file stopped " +
      "being a bare `export { … } from …` re-export, or this extractor no longer " +
      "matches its shape — reporting the whole surface as missing would bury that."
  );
}

// ─── Cross-check against the boundary manifest ────────────────────────────
// The manifest (`src/Boundary.js`) is what other gates scope themselves to, so
// it has to name the same surface index.js publishes. Read from the FFI file
// directly: it is dependency-free data, so this needs no `spago build`.
const { manifest } = await import(
  pathToFileURL(join(repoRoot, "src", "Boundary.js")).href
);
const manifestNames = new Set([...manifest.crossed, ...manifest.passthrough]);
const published = new Set(valueExports);
const notInManifest = [...published].filter((n) => !manifestNames.has(n)).sort();
const notInIndex = [...manifestNames].filter((n) => !published.has(n)).sort();
if (notInManifest.length || notInIndex.length) {
  throw new Error(
    `[extract-psflow] boundary manifest is out of step with index.js.` +
      (notInManifest.length
        ? `\n  exported but not in the manifest: ${notInManifest.join(", ")}`
        : "") +
      (notInIndex.length
        ? `\n  in the manifest but not exported: ${notInIndex.join(", ")}`
        : "") +
      `\nUpdate \`manifest.crossed\` / \`manifest.passthrough\` in src/Boundary.js.`
  );
}

// ─── Type names from React.purs re-export groups ──────────────────────────
const reactPurs = read("src/React.purs");

// Match each `import <Module> ( <names> ) as ReExport<Alias>` block. The
// `\)\s*as\s+ReExport` anchor lets the non-greedy body skip over inner `(..)`
// constructor markers (a bare `)` is only the list terminator when followed
// by ` as ReExport…`).
const reExportBlocks = [
  ...reactPurs.matchAll(/import\s+[\w.]+\s*\(([\s\S]*?)\)\s*as\s+ReExport\w+/g),
];

const typeSet = new Set();
const psValueLower = new Set();
for (const block of reExportBlocks) {
  const names = block[1]
    .split(/[\n,]/)
    .map((s) => s.trim().replace(/\(\.\.\)\s*$/, "").trim())
    .filter((s) => /^[A-Za-z]\w*'?$/.test(s));
  for (const n of names) {
    if (/^[A-Z]/.test(n)) typeSet.add(n);
    else psValueLower.add(n);
  }
}
const typeExports = [...typeSet];

// ─── Record-field extraction (PureScript) ─────────────────────────────────
// Walk the record body tracking brace/paren depth; a `<ident> ::` at the
// outer record level (braceDepth === 1, parenDepth === 0) is a field. This
// skips identifiers inside nested record/function types.
function recordFields(src, typeName, pursFile) {
  const headerRe = new RegExp(`type\\s+${typeName}\\b[^=]*=`);
  const hm = headerRe.exec(src);
  // Hard failure, not a warning. With the props gate on, returning [] for a
  // renamed or moved PureScript record would report that record's *entire*
  // member set as missing from PSFlow — a wall of false gaps that buries the
  // real cause (the record is no longer where prop-types.mjs says it is).
  if (!hm) {
    throw new Error(
      `[extract-psflow] record type not found: \`type ${typeName} = { … }\` in ${pursFile}. ` +
        `If the record was renamed or moved, update parity/layer0-api/prop-types.mjs.`
    );
  }
  let i = src.indexOf("{", hm.index + hm[0].length);
  if (i < 0) {
    throw new Error(
      `[extract-psflow] found \`type ${typeName}\` in ${pursFile} but no record body \`{ … }\` follows it.`
    );
  }

  // Strip line comments so a stray `name ::` in prose can't be picked up.
  const region = src.slice(i).replace(/--[^\n]*/g, "");

  const fields = [];
  let braceDepth = 0;
  let parenDepth = 0;
  let lastIdent = null;
  let lastBrace = 0;
  let lastParen = 0;
  let started = false;

  const tok = /\{|\}|\(|\)|::|[A-Za-z_][A-Za-z0-9_']*/g;
  let m;
  while ((m = tok.exec(region)) !== null) {
    const t = m[0];
    if (t === "{") {
      braceDepth++;
      started = true;
    } else if (t === "}") {
      braceDepth--;
      if (started && braceDepth === 0) break;
    } else if (t === "(") {
      parenDepth++;
    } else if (t === ")") {
      parenDepth--;
    } else if (t === "::") {
      if (lastIdent !== null && lastBrace === 1 && lastParen === 0) {
        fields.push(lastIdent);
      }
    } else {
      lastIdent = t;
      lastBrace = braceDepth;
      lastParen = parenDepth;
    }
  }
  return [...new Set(fields)];
}

const props = Object.fromEntries(
  PROP_TYPES.map((p) => [
    p.name,
    recordFields(read(p.pursFile), p.name, p.pursFile).sort(),
  ])
);

const output = {
  valueExports: [...new Set(valueExports)].sort(),
  typeExports: [...new Set(typeExports)].sort(),
  // camelCase re-exports (PSFlow-only helpers like `useConnectionWith`); kept
  // for context, not used by the gate.
  psValueLower: [...psValueLower].sort(),
  props,
};

const outPath = join(here, "psflow.json");
writeFileSync(outPath, JSON.stringify(output, null, 2) + "\n");

const propSummary = PROP_TYPES.map((p) => `${p.name}=${props[p.name].length}`).join(" ");

console.log(
  `[extract-psflow] ${output.valueExports.length} value ` +
    `(${manifest.crossed.length} crossed, ${manifest.passthrough.length} passthrough — boundary stage ${manifest.stage}) ` +
    `+ ${output.typeExports.length} type exports, props ${propSummary} → ${outPath}`
);
