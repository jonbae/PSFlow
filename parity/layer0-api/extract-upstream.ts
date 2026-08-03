// Layer 0 — upstream extractor. Uses the TypeScript compiler API (the
// authoritative source: it resolves `export *`, renamed re-exports, and
// type-only exports that a regex would miss) to read the full public API
// surface of the vendored `@xyflow/react` entry point.
//
// Emits `upstream.json`:
//   { reactVersion, systemVersion,
//     valueExports: [...], typeExports: [...],
//     props: { ReactFlowProps: [...], NodeProps: [...], EdgeProps: [...] } }
//
// Run with plain `node` (Node strips the TS types). Requires the dev-only
// `typescript` dependency.

import ts from "typescript";
import { fileURLToPath } from "node:url";
import { dirname, resolve, join } from "node:path";
import { readFileSync, writeFileSync } from "node:fs";
import { PROP_TYPES } from "./prop-types.mjs";

const here: string = dirname(fileURLToPath(import.meta.url));
const repoRoot: string = resolve(here, "..", "..");
const xyflow = (p: string): string => join(repoRoot, "xyflow", p);
const readJson = (p: string) => JSON.parse(readFileSync(p, "utf8"));

const reactVersion: string = readJson(xyflow("packages/react/package.json")).version;
const systemVersion: string = readJson(xyflow("packages/system/package.json")).version;

const entry: string = xyflow("packages/react/src/index.ts");

const options: ts.CompilerOptions = {
  target: ts.ScriptTarget.ESNext,
  module: ts.ModuleKind.ESNext,
  moduleResolution: ts.ModuleResolutionKind.Bundler,
  jsx: ts.JsxEmit.ReactJSX,
  allowJs: true,
  checkJs: false,
  noEmit: true,
  skipLibCheck: true,
  skipDefaultLibCheck: true,
  strict: false,
  esModuleInterop: true,
  baseUrl: repoRoot,
  paths: {
    // The react package imports the system package by its published name.
    "@xyflow/system": ["xyflow/packages/system/src/index.ts"],
    "@xyflow/system/*": ["xyflow/packages/system/src/*"],
  },
};

const program: ts.Program = ts.createProgram([entry], options);
const checker: ts.TypeChecker = program.getTypeChecker();

const sourceFile = program.getSourceFile(entry);
if (!sourceFile) {
  throw new Error(`Could not load entry source file: ${entry}`);
}

const moduleSymbol = checker.getSymbolAtLocation(sourceFile);
if (!moduleSymbol) {
  throw new Error("Entry file is not a module (no module symbol).");
}

const isAlias = (s: ts.Symbol): boolean => (s.flags & ts.SymbolFlags.Alias) !== 0;
const deAlias = (s: ts.Symbol): ts.Symbol => (isAlias(s) ? checker.getAliasedSymbol(s) : s);

// A symbol is a "value" export if its resolved declaration carries runtime
// meaning (function / class / variable / enum). Everything else (interfaces,
// type aliases) is type-only. Enums and classes are both — they count as
// values, which is what the JS shim re-exports.
const isValueSymbol = (s: ts.Symbol): boolean => (deAlias(s).flags & ts.SymbolFlags.Value) !== 0;

const exportSymbols: ts.Symbol[] = checker.getExportsOfModule(moduleSymbol);

const valueExports: string[] = [];
const typeExports: string[] = [];
for (const sym of exportSymbols) {
  if (isValueSymbol(sym)) valueExports.push(sym.getName());
  else typeExports.push(sym.getName());
}

// ─── Prop-member sets ─────────────────────────────────────────────────────
// Flatten a prop type into its field-name set, keeping only members *declared
// in the xyflow sources* — this drops the hundreds of inherited React DOM
// attributes (HTMLAttributes<…>) that PSFlow deliberately does not mirror.
const byName: Map<string, ts.Symbol> = new Map(exportSymbols.map((s) => [s.getName(), s]));

const declaredInXyflow = (prop: ts.Symbol): boolean => {
  const decls = prop.getDeclarations() ?? [];
  return decls.some((d) => {
    const f = d.getSourceFile().fileName.replace(/\\/g, "/");
    return f.includes("/xyflow/") && !f.includes("/node_modules/");
  });
};

const propMembers = (typeName: string): string[] => {
  const sym = byName.get(typeName);
  // Hard failure, not a warning. Returning [] here would make the type look
  // like it has no members, so the diff would report the *entire* PSFlow
  // record as "extra" (and, with the gate on, fail for the wrong reason).
  // A prop type vanishing from the upstream exports is itself a finding.
  if (!sym) {
    throw new Error(
      `[extract-upstream] prop type not found in upstream exports: ${typeName}. ` +
        `Either upstream renamed/removed it (a genuine parity finding) or ` +
        `parity/layer0-api/prop-types.mjs is stale.`
    );
  }
  const type = checker.getDeclaredTypeOfSymbol(deAlias(sym));
  const members = checker
    .getPropertiesOfType(type)
    .filter(declaredInXyflow)
    .map((p) => p.getName());
  return Array.from(new Set(members)).sort();
};

const props: Record<string, string[]> = Object.fromEntries(
  PROP_TYPES.map((p) => [p.name, propMembers(p.name)])
);

const output = {
  reactVersion,
  systemVersion,
  valueExports: Array.from(new Set(valueExports)).sort(),
  typeExports: Array.from(new Set(typeExports)).sort(),
  props,
};

const outPath: string = join(here, "upstream.json");
writeFileSync(outPath, JSON.stringify(output, null, 2) + "\n");

const propSummary: string = PROP_TYPES.map((p) => `${p.name}=${props[p.name].length}`).join(" ");

console.log(
  `[extract-upstream] react ${reactVersion} / system ${systemVersion}: ` +
    `${output.valueExports.length} value + ${output.typeExports.length} type exports, ` +
    `props ${propSummary} → ${outPath}`
);
