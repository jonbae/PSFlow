// ps-flow's TypeScript declarations: upstream's, generated from the vendored
// source, made into a self-contained tree, with ps-flow's gaps applied.
//
// The steps, each a function below so `declarations.test.mjs` can hold them:
//
//   1. `emit` compiles the vendored `@xyflow/react` source with upstream's own
//      compiler options and keeps only the declarations. It refuses any
//      diagnostic. The output is upstream's published declarations: the build
//      compares the two (`samePublished`).
//   2. `relayout` moves each file from `<package>/src/` to `<package>/`.
//   3. `link` rewrites every module specifier. `@xyflow/system` becomes a
//      relative path into the system tree, and every relative specifier names
//      its file, `.js` included, because a package whose `type` is `module`
//      is read as ES modules and Node's resolution adds no extensions. Any
//      other bare specifier must be one the package's dependencies supply.
//   4. `reachable` keeps only the files the entry reaches. The rest describe
//      upstream internals, and some import `zustand`, which ps-flow does not
//      depend on.
//   5. `overlay` applies `gaps.mjs`' overlays.
//
// Comments in the declarations are upstream's. Their usage examples import from
// `@xyflow/react`; `link` rewrites that name to `ps-flow` so an example in an
// editor tooltip runs as written. Nothing else in a comment changes.

import ts from 'typescript';
import { readFileSync } from 'node:fs';
import { join, posix } from 'node:path';

// The vendored source reads `process.env.NODE_ENV`, which upstream's build
// types through `@types/node`. Declaring it here keeps the compile free of
// diagnostics without adding Node's types to the program; it reaches no
// emitted declaration.
const PROCESS = 'declare const process: { env: Record<string, string | undefined> };\n';
const PROCESS_FILE = '__process.d.ts';

// Upstream's `tooling/tsconfig/react.json` and `base.json`, minus what concerns
// JavaScript output and source maps.
const compilerOptions = (repoRoot, outDir) => ({
  allowSyntheticDefaultImports: true,
  declaration: true,
  emitDeclarationOnly: true,
  esModuleInterop: true,
  forceConsistentCasingInFileNames: true,
  isolatedModules: true,
  jsx: ts.JsxEmit.ReactJSX,
  lib: ['lib.dom.d.ts', 'lib.esnext.d.ts'],
  module: ts.ModuleKind.ESNext,
  moduleResolution: ts.ModuleResolutionKind.Bundler,
  noImplicitAny: true,
  noImplicitThis: true,
  skipLibCheck: true,
  strict: true,
  strictNullChecks: true,
  target: ts.ScriptTarget.ESNext,
  rootDir: join(repoRoot, 'xyflow/packages'),
  outDir,
  baseUrl: repoRoot,
  paths: { '@xyflow/system': ['xyflow/packages/system/src/index.ts'] },
  types: [],
});

const format = (diagnostics, repoRoot) =>
  ts.formatDiagnostics(diagnostics, {
    getCanonicalFileName: (f) => f,
    getCurrentDirectory: () => repoRoot,
    getNewLine: () => '\n',
  });

// 1. Upstream's declarations, keyed `react/src/…d.ts` and `system/src/…d.ts`.
export function emit(repoRoot) {
  const outDir = join(repoRoot, '.distribution-emit');
  const options = compilerOptions(repoRoot, outDir);
  const host = ts.createCompilerHost(options);
  const getSourceFile = host.getSourceFile.bind(host);
  host.getSourceFile = (name, version, ...rest) =>
    name.endsWith(PROCESS_FILE)
      ? ts.createSourceFile(name, PROCESS, version)
      : getSourceFile(name, version, ...rest);
  const fileExists = host.fileExists.bind(host);
  host.fileExists = (name) => name.endsWith(PROCESS_FILE) || fileExists(name);

  const roots = [
    join(repoRoot, 'xyflow/packages/react/src/index.ts'),
    join(repoRoot, 'xyflow/packages/react/src/custom.d.ts'),
    join(repoRoot, PROCESS_FILE),
  ];
  const program = ts.createProgram(roots, options, host);
  const diagnostics = ts.getPreEmitDiagnostics(program);
  if (diagnostics.length) {
    throw new Error(`the vendored source does not compile cleanly:\n${format(diagnostics, repoRoot)}`);
  }

  const files = new Map();
  const result = program.emit(undefined, (name, text) => {
    const key = posix.relative(outDir.split('\\').join('/'), name.split('\\').join('/'));
    files.set(key, text);
  });
  if (result.emitSkipped || result.diagnostics.length) {
    throw new Error(`declaration emit failed:\n${format(result.diagnostics, repoRoot)}`);
  }
  return files;
}

// Each emitted file equals the published package's, apart from the source-map
// comment the published build appends. Returns the keys that differ or that
// the published package lacks.
export function samePublished(files, publishedRoots) {
  const differ = [];
  for (const [key, text] of files) {
    const [pkg, , ...rest] = key.split('/');
    const published = join(publishedRoots[pkg], ...rest);
    let other;
    try {
      other = readFileSync(published, 'utf8');
    } catch {
      differ.push(key);
      continue;
    }
    if (other.replace(/\n?\/\/# sourceMappingURL=.*$/, '\n') !== text) differ.push(key);
  }
  return differ;
}

// 2. `react/src/hooks/useStore.d.ts` → `react/hooks/useStore.d.ts`.
export function relayout(files) {
  const out = new Map();
  for (const [key, text] of files) {
    const [pkg, src, ...rest] = key.split('/');
    if (src !== 'src') throw new Error(`unexpected emitted path ${key}`);
    out.set([pkg, ...rest].join('/'), text);
  }
  return out;
}

// Every module specifier in one declaration file, with where its quoted text
// sits. Declarations reach a module three ways: `import … from`,
// `export … from`, and an `import("…")` type.
export function specifiers(key, text) {
  const source = ts.createSourceFile(key, text, ts.ScriptTarget.ESNext, true);
  const found = [];
  const visit = (node) => {
    let literal;
    if ((ts.isImportDeclaration(node) || ts.isExportDeclaration(node)) && node.moduleSpecifier) {
      literal = node.moduleSpecifier;
    } else if (ts.isImportTypeNode(node) && ts.isLiteralTypeNode(node.argument)) {
      literal = node.argument.literal;
    }
    if (literal && ts.isStringLiteral(literal)) {
      found.push({ text: literal.text, start: literal.getStart(source) + 1, end: literal.getEnd() - 1 });
    }
    ts.forEachChild(node, visit);
  };
  visit(source);
  return found;
}

const relativeTo = (from, to) => {
  const path = posix.relative(posix.dirname(from), to);
  return path.startsWith('.') ? path : `./${path}`;
};

// The file a specifier names, or `null` for a bare specifier that is not
// upstream's system package.
const target = (key, specifier, files) => {
  if (specifier === '@xyflow/system') return 'system/index.d.ts';
  if (!specifier.startsWith('.')) return null;
  // `'./'` and `'..'` name a directory's index; `join` keeps the first's slash.
  const base = posix.join(posix.dirname(key), specifier).replace(/\/$/, '');
  for (const candidate of [`${base}.d.ts`, posix.join(base, 'index.d.ts')]) {
    if (files.has(candidate)) return candidate;
  }
  throw new Error(`${key}: ${JSON.stringify(specifier)} names no emitted declaration`);
};

// 3. Specifiers rewritten, and the bare ones that remain, per file.
export function link(files) {
  const out = new Map();
  const external = new Map();
  for (const [key, text] of files) {
    let rewritten = text;
    const bare = new Set();
    for (const { text: specifier, start, end } of specifiers(key, text).reverse()) {
      const file = target(key, specifier, files);
      if (file === null) {
        bare.add(specifier);
        continue;
      }
      const path = relativeTo(key, file).replace(/\.d\.ts$/, '.js');
      rewritten = rewritten.slice(0, start) + path + rewritten.slice(end);
    }
    // The react package never imports itself, so what remains of its name is
    // in comments: usage examples and the styles hint.
    out.set(key, rewritten.replaceAll('@xyflow/react', 'ps-flow'));
    external.set(key, bare);
  }
  return { files: out, external };
}

// 4. The files the entry reaches, following the rewritten specifiers.
export function reachable(files, entry) {
  const seen = new Set();
  const queue = [entry];
  while (queue.length) {
    const key = queue.pop();
    if (seen.has(key)) continue;
    if (!files.has(key)) throw new Error(`reached ${key}, which was not emitted`);
    seen.add(key);
    for (const { text } of specifiers(key, files.get(key))) {
      if (text.startsWith('.')) queue.push(posix.join(posix.dirname(key), text).replace(/\.js$/, '.d.ts'));
    }
  }
  return seen;
}

// 5. Each overlay edits its file once. A `find` that occurs zero times or more
// than once is stale or ambiguous, and fails the build.
export function overlay(files, overlays) {
  const out = new Map(files);
  for (const { id, file, find, replace } of overlays) {
    const text = out.get(file);
    if (text === undefined) throw new Error(`overlay ${id}: ${file} is not in the published declarations`);
    const count = text.split(find).length - 1;
    if (count !== 1) {
      throw new Error(`overlay ${id}: expected its text once in ${file}, found it ${count} times; it is stale`);
    }
    out.set(file, text.replace(find, () => replace));
  }
  return out;
}
