// Surface parity — PSFlow extractor.
//
//   * values       ← **imported** from `index.js`, the JS surface. Not read:
//     the extractor used to scrape `/export const (\w+)\s*=/` over the file,
//     which proves a line of text exists and not that the binding resolves.
//     Importing gets the resolved value, which is also what makes shape
//     comparison possible at all. Cost, accepted: this needs `spago build`
//     first, so surface parity is no longer standalone. Deliberately *not*
//     hedged with a fall back to the regex when `output/` is missing — a gate
//     that goes quiet exactly when it is least able to check is the documented
//     mechanism by which the `NodeProps` gap survived a version bump.
//   * shapes       ← `typeof`, arity and React wrapper kind of each imported
//     value (`shape.mjs`), for the diff to compare against upstream's.
//   * type names   ← `src/React.purs` re-export groups (`import … ( … ) as
//     ReExport*`). PureScript types are PascalCase; values are lowercase.
//     We keep the PascalCase tokens (stripping any `(..)` constructor marker).
//     Still textual: types have no runtime existence to import.
//   * prop members ← the `ReactFlowProps` / `NodeProps` / `EdgeProps` record
//     definitions in `src/React/Types/{Component,Nodes,Edges}.purs`.
//
// Emits `psflow.json` with the same shape as `upstream.json`.

import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, resolve, join } from "node:path";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { PROP_TYPES } from "./prop-types.mjs";
import { mustAgree } from "./agreement.mjs";
import { shapeOf } from "./shape.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");
const read = (p) => readFileSync(join(repoRoot, p), "utf8");

// ─── Values, by importing the JS surface ──────────────────────────────────
const compiled = join(repoRoot, "output", "Boundary", "index.js");
if (!existsSync(compiled)) {
  throw new Error(
    `[extract-psflow] no compiled boundary module at ${compiled}. Surface parity ` +
      `imports \`index.js\` rather than reading it, so it needs the PureScript ` +
      `output: run \`spago build\` and try again.\n` +
      `There is no fallback on purpose — a gate that degrades to a weaker check ` +
      `when the build is missing reports green about a surface it never saw.`
  );
}

let surface;
try {
  surface = await import(pathToFileURL(join(repoRoot, "index.js")).href);
} catch (cause) {
  // An ESM link error here is the failure that put `Position` and `MarkerType`
  // out of the audience's reach in the first place: index.js names a binding
  // the boundary module does not export, and every consumer's import of the
  // whole package fails. The import is what proves it cannot recur.
  throw new Error(
    `[extract-psflow] importing index.js failed, so PSFlow's JS surface does not ` +
      `load at all — this is what a consumer's \`import … from "ps-flow"\` would do.\n` +
      `  ${cause.message}\n` +
      `If a name is missing, add it to src/Boundary.purs's export list (or to one ` +
      `of its \`module <Alias>\` re-export groups). If the output is stale, rebuild ` +
      `with \`spago build\`.`,
    { cause }
  );
}

const valueExports = Object.keys(surface);
const shapes = Object.fromEntries(valueExports.map((name) => [name, shapeOf(surface[name])]));

// ─── index.js stays a bare re-export ──────────────────────────────────────
// The import above settles what the surface *is*; this settles what the file
// is allowed to be. `index.js` carries no logic — every conversion lives in
// PureScript where the compiler checks it — so each specifier is either a bare
// name or `local as Public`, and the parsed public names must be exactly the
// names that arrived on import.
const indexJs = read("index.js");
const exportBlocks = [
  ...indexJs.matchAll(/export\s*\{([\s\S]*?)\}\s*from\s*["'][^"']+["']/g),
];
const specifiers = exportBlocks.flatMap((block) =>
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
      return { local: m[1], public: m[2] ?? m[1] };
    })
);

mustAgree({
  about: `[extract-psflow] index.js's export list does not match what importing it yields.`,
  left: { label: "imported", names: valueExports },
  right: { label: "declared", names: specifiers.map((s) => s.public) },
  remedy:
    `index.js must stay a single bare \`export { … } from "./output/Boundary/index.js"\`; ` +
    `anything the parser above cannot see is surface nobody is reviewing.`,
});

// ─── Cross-check against the boundary manifest ────────────────────────────
// The manifest (`src/Boundary.js`) is what other gates scope themselves to, so
// it has to name the same surface index.js publishes. Read from the FFI file
// directly: it is dependency-free data, so this needs no `spago build`.
const { manifest } = await import(
  pathToFileURL(join(repoRoot, "src", "Boundary.js")).href
);
mustAgree({
  about: `[extract-psflow] boundary manifest is out of step with index.js.`,
  left: { label: "exported", names: valueExports },
  right: { label: "in the manifest", names: [...manifest.crossed, ...manifest.passthrough] },
  remedy: `Update \`manifest.crossed\` / \`manifest.passthrough\` in src/Boundary.js.`,
});

// The third list — `src/Boundary.purs`'s own export list — used to be checked
// here textually, because nothing imported index.js and a name the boundary
// module does not export is an ESM link error. The import above supersedes it:
// a name that does not link now fails the import outright, which is a stronger
// claim than any reading of the source could make.

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
        `If the record was renamed or moved, update parity/surface/prop-types.mjs.`
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
  shapes,
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
