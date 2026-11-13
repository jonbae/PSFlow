// Packs the package, installs the tarball into a scratch consumer, and checks
// that what a consumer gets is ps-flow's JavaScript surface, its declarations
// and its stylesheets.
//
// The consumer is a directory with the extracted tarball and links to the
// package's declared dependencies and peers, and nothing else, so an import
// the manifest does not declare fails here as it would for a consumer. The
// checks, in order:
//
//   1. **Contents.** The tarball holds `package.json`, the README npm always
//      adds, and `dist/`. Every path the manifest's `main`, `types` and
//      `exports` name is in it.
//   2. **The module.** `import 'ps-flow'` publishes the names `index.js`
//      publishes, each with the same shape: `typeof`, arity and React wrapper
//      kind, which is what surface parity compares against upstream. `require`
//      reaches the same names.
//   3. **A render.** A flow with the chrome components renders to the same
//      markup through the package as through `index.js`, and logs nothing.
//      So does a consumer's bundle of the package and its stylesheet.
//   4. **The stylesheets** are the bytes the driver page loads on both sides of
//      every net run: upstream's, from the pinned package.
//   5. **The declarations** type-check a consumer (`consumer/consumer.tsx`)
//      under bundler and Node 16 resolution, with `skipLibCheck` off, so every
//      published declaration is checked too. They declare exactly upstream's
//      export names, value and type, and their values are the runtime's.
//
// Usage: npm run parity:package   (after npm run build:package)
//        node distribution/check.mjs --keep   (leave the consumer directory)

import { build } from 'esbuild';
import ts from 'typescript';
import { spawnSync } from 'node:child_process';
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { isDeepStrictEqual } from 'node:util';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '..');
const readJson = (path) => JSON.parse(readFileSync(path, 'utf8'));
const pkg = readJson(join(repoRoot, 'package.json'));

if (!existsSync(join(repoRoot, 'dist/index.js')) || !existsSync(join(repoRoot, 'dist/index.d.ts'))) {
  console.error('parity:package: dist/ is missing; run `npm run build:package` first.');
  process.exit(2);
}

const results = [];
const check = (what, fn) => {
  try {
    const detail = fn();
    results.push({ what, ok: true, detail });
  } catch (error) {
    results.push({ what, ok: false, error });
  }
};
const fail = (message) => {
  throw new Error(message);
};

const run = (command, args, cwd) => {
  const result = spawnSync(command, args, { cwd, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  if (result.status !== 0) {
    fail(`${command} ${args.join(' ')} exited ${result.status}:\n${result.stdout}${result.stderr}`);
  }
  return result;
};

// ── The consumer ───────────────────────────────────────────────────────

const work = mkdtempSync(join(tmpdir(), 'psflow-package-'));
const keep = process.argv.includes('--keep');
// On every exit, including a probe that fails outside a check.
process.on('exit', () => {
  if (!keep) rmSync(work, { recursive: true, force: true });
});
const consumer = join(work, 'consumer');
const modules = join(consumer, 'node_modules');
mkdirSync(join(modules, 'ps-flow'), { recursive: true });

const [packed] = JSON.parse(
  run('npm', ['pack', '--ignore-scripts', '--json', '--pack-destination', work], repoRoot).stdout
);
const tarball = join(work, packed.filename);
run('tar', ['-xzf', tarball, '-C', join(modules, 'ps-flow'), '--strip-components=1'], work);

writeFileSync(join(consumer, 'package.json'), JSON.stringify({ name: 'consumer', private: true, type: 'module' }));
const linked = [...Object.keys(pkg.dependencies ?? {}), ...Object.keys(pkg.peerDependencies ?? {})];
for (const name of linked) {
  const destination = join(modules, name);
  mkdirSync(dirname(destination), { recursive: true });
  symlinkSync(join(repoRoot, 'node_modules', name), destination, 'dir');
}

// ── 1. Contents ────────────────────────────────────────────────────────

const packedFiles = packed.files.map(({ path }) => path).sort();

check('the tarball holds package.json, README.md and dist/ only', () => {
  const stray = packedFiles.filter((path) => !['package.json', 'README.md'].includes(path) && !path.startsWith('dist/'));
  if (stray.length) fail(`unexpected files: ${stray.join(', ')}`);
});

check('every entry point the manifest names is in the tarball', () => {
  const targets = (value) =>
    typeof value === 'string' ? [value] : Object.values(value).flatMap((inner) => targets(inner));
  const named = new Set([pkg.main, pkg.types, ...targets(pkg.exports)].map((path) => path.replace(/^\.\//, '')));
  const missing = [...named].filter((path) => !packedFiles.includes(path));
  if (missing.length) fail(`named but not packed: ${missing.join(', ')}`);
  for (const path of ['dist/xyflow-LICENSE', 'dist/types/react/index.d.ts']) {
    if (!packedFiles.includes(path)) fail(`${path} is not packed`);
  }
});

// ── 2. The module ──────────────────────────────────────────────────────

const shapeModule = pathToFileURL(join(repoRoot, 'parity/surface/shape.mjs')).href;

// What a consumer's process observes, written into the consumer so that its
// bare imports resolve from the consumer's `node_modules`.
writeFileSync(
  join(consumer, 'render.mjs'),
  `import { createElement as h } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';

globalThis.ResizeObserver ??= class { observe() {} unobserve() {} disconnect() {} };

const handles = (type) => [
  { id: null, type, position: type === 'source' ? 'bottom' : 'top', x: 20, y: 0, width: 6, height: 6 },
];

export function render(library) {
  const logged = [];
  const { error, warn } = console;
  console.error = (...args) => logged.push(['error', String(args[0])]);
  console.warn = (...args) => logged.push(['warn', String(args[0])]);
  try {
    const nodes = [
      { id: 'a', position: { x: 0, y: 0 }, data: { label: 'a' }, width: 50, height: 20, handles: handles('source') },
      { id: 'b', position: { x: 0, y: 120 }, data: { label: 'b' }, width: 50, height: 20, handles: handles('target') },
    ];
    const edges = [{ id: 'a-b', source: 'a', target: 'b', label: 'edge' }];
    const html = renderToStaticMarkup(
      h(library.ReactFlow, { nodes, edges, fitView: true },
        h(library.Background), h(library.Controls), h(library.MiniMap), h(library.Panel, null, 'panel'))
    );
    return { html, logged };
  } finally {
    Object.assign(console, { error, warn });
  }
}
`
);

writeFileSync(
  join(consumer, 'probe.mjs'),
  `import { shapeOf } from ${JSON.stringify(shapeModule)};
import { render } from './render.mjs';

const [mode, specifier] = process.argv.slice(2);
const library = await import(specifier);
const names = Object.keys(library).sort();
const out =
  mode === 'surface'
    ? { names, shapes: Object.fromEntries(names.map((name) => [name, shapeOf(library[name])])) }
    : render(library);
process.stdout.write(JSON.stringify(out));
`
);

writeFileSync(
  join(consumer, 'require.cjs'),
  `const library = require('ps-flow');
process.stdout.write(JSON.stringify(Object.keys(library).filter((key) => key !== '__esModule').sort()));
`
);

const probe = (mode, specifier) => JSON.parse(run(process.execPath, ['probe.mjs', mode, specifier], consumer).stdout);
const indexUrl = pathToFileURL(join(repoRoot, 'index.js')).href;

const packedSurface = probe('surface', 'ps-flow');
const indexSurface = probe('surface', indexUrl);

check("import 'ps-flow' publishes index.js's names, each in the same shape", () => {
  if (!isDeepStrictEqual(packedSurface.names, indexSurface.names)) {
    fail(`names differ:\npacked ${packedSurface.names.join(', ')}\nindex.js ${indexSurface.names.join(', ')}`);
  }
  const differ = packedSurface.names.filter(
    (name) => !isDeepStrictEqual(packedSurface.shapes[name], indexSurface.shapes[name])
  );
  if (differ.length) fail(`shapes differ: ${differ.join(', ')}`);
});

check("require('ps-flow') reaches the same names", () => {
  const names = JSON.parse(run(process.execPath, ['require.cjs'], consumer).stdout);
  if (!isDeepStrictEqual(names, indexSurface.names)) fail(`require reaches ${names.join(', ')}`);
});

// ── 3. A render ────────────────────────────────────────────────────────

const packedRender = probe('render', 'ps-flow');
const indexRender = probe('render', indexUrl);

check('a flow renders the same markup through the package as through index.js, and logs nothing', () => {
  if (packedRender.html !== indexRender.html) fail('the markup differs');
  if (!packedRender.html.includes('react-flow__panel top left')) fail('the panel did not render');
  if (packedRender.logged.length) fail(`the render logged ${JSON.stringify(packedRender.logged)}`);
});

writeFileSync(
  join(consumer, 'app.mjs'),
  `import 'ps-flow/dist/style.css';
import * as library from 'ps-flow';
import { render } from './render.mjs';

process.stdout.write(JSON.stringify(render(library)));
`
);

const bundled = await build({
  entryPoints: [join(consumer, 'app.mjs')],
  absWorkingDir: consumer,
  bundle: true,
  format: 'esm',
  platform: 'node',
  external: ['react', 'react-dom', 'react/*', 'react-dom/*'],
  outdir: join(consumer, 'out'),
  metafile: true,
  logLevel: 'silent',
});

check("a consumer's bundle resolves the package and its stylesheet, and renders the same markup", () => {
  const inputs = Object.keys(bundled.metafile.inputs);
  if (!inputs.some((path) => path.endsWith('ps-flow/dist/index.js'))) fail('the bundle did not include dist/index.js');
  if (!inputs.some((path) => path.endsWith('ps-flow/dist/style.css'))) fail('the bundle did not include style.css');
  const css = readFileSync(join(consumer, 'out/app.css'), 'utf8');
  if (!css.includes('.react-flow__node')) fail('the bundled stylesheet has no node rule');
  const rendered = JSON.parse(run(process.execPath, ['out/app.js'], consumer).stdout);
  if (rendered.html !== indexRender.html) fail('the bundled markup differs');
  if (rendered.logged.length) fail(`the bundled render logged ${JSON.stringify(rendered.logged)}`);
});

// ── 4. The stylesheets ─────────────────────────────────────────────────

check("the stylesheets are the bytes the driver page loads: upstream's, from the pinned package", () => {
  const page = readFileSync(join(repoRoot, 'parity/driver/index.html'), 'utf8');
  const loaded = [...page.matchAll(/<link rel="stylesheet" href="([^"]+)"/g)]
    .map(([, href]) => resolve(repoRoot, 'parity/driver', href))
    .sort();
  const pinned = ['base.css', 'style.css'].map((sheet) => join(repoRoot, 'node_modules/@xyflow/react/dist', sheet));
  if (!isDeepStrictEqual(loaded, pinned)) fail(`the driver page loads ${loaded.join(', ')}`);
  if (readJson(join(repoRoot, 'node_modules/@xyflow/react/package.json')).version !== pkg.devDependencies['@xyflow/react']) {
    fail('the installed @xyflow/react is not the pinned one');
  }
  for (const sheet of ['style.css', 'base.css']) {
    const published = readFileSync(join(modules, 'ps-flow/dist', sheet));
    const upstream = readFileSync(join(repoRoot, 'node_modules/@xyflow/react/dist', sheet));
    if (!published.equals(upstream)) fail(`${sheet} differs from upstream's`);
  }
});

// ── 5. The declarations ────────────────────────────────────────────────

copyFileSync(join(here, 'consumer/consumer.tsx'), join(consumer, 'consumer.tsx'));
const tsc = join(repoRoot, 'node_modules/typescript/bin/tsc');

for (const [label, module, moduleResolution] of [
  ['bundler', 'esnext', 'bundler'],
  ['Node 16', 'node16', 'node16'],
]) {
  check(`a TypeScript consumer type-checks under ${label} resolution, with skipLibCheck off`, () => {
    const config = `tsconfig.${module}.json`;
    writeFileSync(
      join(consumer, config),
      JSON.stringify({
        compilerOptions: {
          strict: true,
          noEmit: true,
          skipLibCheck: false,
          jsx: 'react-jsx',
          lib: ['dom', 'esnext'],
          target: 'es2022',
          module,
          moduleResolution,
          types: [],
        },
        files: ['consumer.tsx'],
      })
    );
    run(process.execPath, [tsc, '-p', config], consumer);
  });
}

const exportsOf = (file) => {
  const program = ts.createProgram([file], {
    module: ts.ModuleKind.ESNext,
    moduleResolution: ts.ModuleResolutionKind.Bundler,
    target: ts.ScriptTarget.ESNext,
    jsx: ts.JsxEmit.ReactJSX,
    strict: true,
    noEmit: true,
    skipLibCheck: true,
    types: [],
  });
  const checker = program.getTypeChecker();
  const source = program.getSourceFile(file);
  const values = [];
  const types = [];
  for (const exported of checker.getExportsOfModule(checker.getSymbolAtLocation(source))) {
    const symbol = exported.flags & ts.SymbolFlags.Alias ? checker.getAliasedSymbol(exported) : exported;
    (symbol.flags & ts.SymbolFlags.Value ? values : types).push(exported.name);
  }
  return { values: values.sort(), types: types.sort() };
};

check("the declarations name upstream's exports, and their values are the runtime's", () => {
  const published = exportsOf(join(modules, 'ps-flow/dist/index.d.ts'));
  const upstream = exportsOf(join(repoRoot, 'node_modules/@xyflow/react/dist/esm/index.d.ts'));
  if (!isDeepStrictEqual(published, upstream)) fail("the declared exports are not upstream's");
  if (!isDeepStrictEqual(published.values, indexSurface.names)) {
    fail(`declared values ${published.values.join(', ')}\nruntime ${indexSurface.names.join(', ')}`);
  }
  return `${published.values.length} values and ${published.types.length} types`;
});

// ── Report ─────────────────────────────────────────────────────────────

if (keep) console.log(`consumer left at ${consumer}`);

const failed = results.filter(({ ok }) => !ok);
console.log(
  `parity:package: ${results.length} checks against ${packed.filename} ` +
    `(${packedFiles.length} files, ${(packed.unpackedSize / 1024 / 1024).toFixed(1)} MB unpacked).`
);
for (const { what, ok, error, detail } of results) {
  console.log(`  ${ok ? '✓' : '✗'} ${what}${detail ? ` (${detail})` : ''}`);
  if (!ok) console.log(`      ${String(error.message).split('\n').join('\n      ')}`);
}
process.exit(failed.length ? 1 : 0);
