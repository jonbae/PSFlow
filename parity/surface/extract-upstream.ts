// Surface parity — upstream extractor. Reads the vendored `@xyflow/react` two
// ways, because the two questions have different authorities.
//
//   * **names and prop members** ← the TypeScript compiler API. It resolves
//     `export *`, renamed re-exports, and the type-only exports that have no
//     runtime existence to read.
//   * **shapes** ← the *values*, by bundling the same entry point with esbuild
//     and importing it. `typeof`, arity and React wrapper kind cannot be had
//     from a declaration: `forwardRef` and `memo` are calls, not types.
//
// The bundle is built from `xyflow/` and never from `node_modules/@xyflow/`.
// The parity baseline is the vendored checkout — the published package is not
// an acceptable stand-in for it, which is the same invariant
// `parity/driver/build.mjs` enforces on its bundles. The two extraction paths
// are cross-checked against each other below, so a bundle that silently picked
// up a different build would fail rather than quietly reshape the gate.
//
// Emits `upstream.json`:
//   { reactVersion, systemVersion,
//     valueExports: [...], typeExports: [...],
//     shapes: { <name>: { kind, wrappers, arity } },
//     props: { ReactFlowProps: [...], NodeProps: [...], EdgeProps: [...] } }
//
// Run with plain `node` (Node strips the TS types). Requires the dev-only
// `typescript` and `esbuild` dependencies.

import ts from "typescript";
import { build } from "esbuild";
import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, resolve, join } from "node:path";
import { readFileSync, writeFileSync } from "node:fs";
import { PROP_TYPES } from "./prop-types.mjs";
import { mustAgree } from "./agreement.mjs";
import { shapeOf } from "./shape.mjs";

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
        `parity/surface/prop-types.mjs is stale.`
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

// ─── Shapes, from the bundled vendored sources ────────────────────────────
// The bundle is a build artifact of a gitignored tree, so it is gitignored too
// and rebuilt on every run — it costs about a second and can never be stale.
const bundlePath: string = join(here, "upstream-bundle.mjs");

await build({
  entryPoints: [entry],
  bundle: true,
  format: "esm",
  platform: "neutral",
  // React stays out: it is a real dependency of this repo, both sides resolve
  // the same copy, and `Symbol.for("react.memo")` is registry-global anyway.
  external: ["react", "react-dom", "react/jsx-runtime", "react-dom/client"],
  alias: { "@xyflow/system": xyflow("packages/system/src/index.ts") },
  jsx: "automatic",
  // The vendored tsconfigs extend a workspace package that is not vendored
  // with them; every option this bundle needs is set explicitly above.
  tsconfigRaw: {},
  // `getNodesBounds` branches on it, and a neutral bundle has no `process` —
  // the same substitution `oracle/esbuild.mjs` makes, for the same reason.
  define: { "process.env.NODE_ENV": '"production"' },
  // One transitive CommonJS dependency (`use-sync-external-store`) requires
  // React dynamically, which an ESM bundle has no `require` for.
  banner: { js: `import { createRequire as __cr } from "node:module";\nconst require = __cr(import.meta.url);` },
  outfile: bundlePath,
  logLevel: "warning",
});

const runtime: Record<string, unknown> = await import(pathToFileURL(bundlePath).href);

// The compiler read declarations; the bundle ran code. They must describe the
// same surface — if they diverge, one of the two is looking at something else,
// and a shape comparison built on the wrong build is worse than none.
const runtimeNames: string[] = Object.keys(runtime);

mustAgree({
  about:
    `[extract-upstream] the vendored sources' value exports disagree with what the ` +
    `bundle of the same entry point yields.`,
  left: { label: "in the bundle", names: runtimeNames },
  right: { label: "in the declarations", names: valueExports },
  remedy: "One of the two is reading a different upstream than the other.",
});

const shapes = Object.fromEntries(
  [...runtimeNames].sort().map((name) => [name, shapeOf(runtime[name])])
);

const output = {
  reactVersion,
  systemVersion,
  valueExports: Array.from(new Set(valueExports)).sort(),
  typeExports: Array.from(new Set(typeExports)).sort(),
  shapes,
  props,
};

const outPath: string = join(here, "upstream.json");
writeFileSync(outPath, JSON.stringify(output, null, 2) + "\n");

const propSummary: string = PROP_TYPES.map((p) => `${p.name}=${props[p.name].length}`).join(" ");

console.log(
  `[extract-upstream] react ${reactVersion} / system ${systemVersion}: ` +
    `${output.valueExports.length} value (shapes from the vendored bundle) + ` +
    `${output.typeExports.length} type exports, props ${propSummary} → ${outPath}`
);
