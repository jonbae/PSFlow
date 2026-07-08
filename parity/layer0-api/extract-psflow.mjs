// Layer 0 — PSFlow extractor. No new dependency: PSFlow's surfaced API is
// already written down in two hand-maintained barrels, so we read those
// directly rather than compile PureScript.
//
//   * value names  ← `index.js` (the JS shim). It re-exports every PS value
//     under its TS-identical PascalCase name (`ReactFlow`, `MiniMap`, …), so
//     it already encodes the camelCase↔PascalCase mapping the diff needs.
//   * type names   ← `src/React.purs` re-export groups (`import … ( … ) as
//     ReExport*`). PureScript types are PascalCase; values are lowercase.
//     We keep the PascalCase tokens (stripping any `(..)` constructor marker).
//   * prop members ← the `ReactFlowProps` / `NodeProps` / `EdgeProps` record
//     definitions in `src/React/Types/{Component,Nodes,Edges}.purs`.
//
// Emits `psflow.json` with the same shape as `upstream.json`.

import { fileURLToPath } from "node:url";
import { dirname, resolve, join } from "node:path";
import { readFileSync, writeFileSync } from "node:fs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");
const read = (p) => readFileSync(join(repoRoot, p), "utf8");

// ─── Value names from index.js ────────────────────────────────────────────
const indexJs = read("index.js");
const valueExports = [...indexJs.matchAll(/export const (\w+)\s*=/g)].map((m) => m[1]);

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
function recordFields(src, typeName) {
  const headerRe = new RegExp(`type\\s+${typeName}\\b[^=]*=`);
  const hm = headerRe.exec(src);
  if (!hm) {
    console.warn(`[extract-psflow] record type not found: ${typeName}`);
    return [];
  }
  let i = src.indexOf("{", hm.index + hm[0].length);
  if (i < 0) return [];

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

const props = {
  ReactFlowProps: recordFields(read("src/React/Types/Component.purs"), "ReactFlowProps").sort(),
  NodeProps: recordFields(read("src/React/Types/Nodes.purs"), "NodeProps").sort(),
  EdgeProps: recordFields(read("src/React/Types/Edges.purs"), "EdgeProps").sort(),
};

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

console.log(
  `[extract-psflow] ${output.valueExports.length} value + ${output.typeExports.length} type exports, ` +
    `props RF=${props.ReactFlowProps.length} Node=${props.NodeProps.length} Edge=${props.EdgeProps.length} → ${outPath}`
);
