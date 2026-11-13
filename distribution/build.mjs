// Builds the package a JavaScript or TypeScript consumer installs, into `dist/`.
//
//   dist/index.js       `index.js` and the compiled PureScript it reaches, as one
//                       ES module. Its dependencies stay imports.
//   dist/index.d.ts     the entry declaration: ps-flow's notes, then upstream's
//   dist/types/         declarations with `gaps.mjs`' overlays applied
//   dist/style.css      upstream's stylesheets, byte for byte: the files the
//   dist/base.css       driver page loads on both sides of every net run
//   dist/xyflow-LICENSE upstream's license, which covers the copied declarations
//                       and stylesheets
//
// What the package must then do is `check.mjs`'s to prove, and `README.md`,
// next to this file, says why each piece is built the way it is.
//
// Usage: npm run build:package   (`spago build` first, then this file)

import { build } from 'esbuild';
import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { emit, link, overlay, reachable, relayout, samePublished } from './declarations.mjs';
import { NOTES, OVERLAYS } from './gaps.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '..');
const dist = join(repoRoot, 'dist');
const readJson = (path) => JSON.parse(readFileSync(join(repoRoot, path), 'utf8'));

const fail = (message) => {
  console.error(`build:package: ${message}`);
  process.exit(1);
};

// ── Preconditions ──────────────────────────────────────────────────────

const pkg = readJson('package.json');

if (!existsSync(join(repoRoot, 'output/Boundary/index.js'))) {
  fail('output/Boundary/index.js is missing; run `spago build` first.');
}

// The vendored source, the pinned published package and the pin itself must
// all name the same baseline: the declarations come from the first, the
// stylesheets from the second.
const baseline = {};
for (const name of ['react', 'system']) {
  const pinned = pkg.devDependencies[`@xyflow/${name}`];
  const vendored = readJson(`xyflow/packages/${name}/package.json`).version;
  const installed = readJson(`node_modules/@xyflow/${name}/package.json`).version;
  if (vendored !== pinned || installed !== pinned) {
    fail(`@xyflow/${name}: pinned ${pinned}, vendored ${vendored}, installed ${installed}; they must agree.`);
  }
  baseline[name] = pinned;
}

rmSync(dist, { recursive: true, force: true });
mkdirSync(dist);

// ── The module ─────────────────────────────────────────────────────────

// What the bundle may import: every runtime dependency and peer, and nothing
// else. Type packages supply declarations only.
const runtime = [...Object.keys(pkg.dependencies ?? {}), ...Object.keys(pkg.peerDependencies ?? {})].filter(
  (name) => !name.startsWith('@types/')
);

const bundled = await build({
  entryPoints: [join(repoRoot, 'index.js')],
  bundle: true,
  format: 'esm',
  platform: 'neutral',
  external: runtime.flatMap((name) => [name, `${name}/*`]),
  outfile: join(dist, 'index.js'),
  metafile: true,
  banner: {
    js:
      `// ps-flow: the JavaScript surface of a PureScript port of @xyflow/react ${baseline.react}.\n` +
      '// Built by distribution/build.mjs from index.js and the compiled PureScript it reaches.',
  },
  logLevel: 'warning',
});

// Everything inlined is ps-flow's own: `index.js` or compiled PureScript and its
// foreign modules. A dependency inlined by mistake would ship a second copy.
const inputs = Object.keys(bundled.metafile.inputs);
const foreign = inputs.filter((path) => path !== 'index.js' && !path.startsWith('output/'));
if (foreign.length) fail(`the bundle inlined files outside index.js and output/: ${foreign.join(', ')}`);

// The imports left are exactly the runtime dependencies. One missing from
// `package.json` would fail at a consumer's first import; one never imported
// would install for nothing.
const imported = new Set();
for (const output of Object.values(bundled.metafile.outputs)) {
  for (const { path, external } of output.imports) if (external) imported.add(path);
}
const packageOf = (specifier) => specifier.split('/').slice(0, specifier.startsWith('@') ? 2 : 1).join('/');
const importedPackages = [...new Set([...imported].map(packageOf))].sort();
if (JSON.stringify(importedPackages) !== JSON.stringify([...runtime].sort())) {
  fail(`the bundle imports ${importedPackages.join(', ')}; package.json declares ${runtime.sort().join(', ')}.`);
}

// ── The declarations ───────────────────────────────────────────────────

const emitted = emit(repoRoot);
const differ = samePublished(emitted, {
  react: join(repoRoot, 'node_modules/@xyflow/react/dist/esm'),
  system: join(repoRoot, 'node_modules/@xyflow/system/dist/esm'),
});
if (differ.length) {
  fail(`declarations emitted from the vendored source differ from the published package's: ${differ.join(', ')}`);
}

const { files: linked, external } = link(relayout(emitted));
const kept = reachable(linked, 'react/index.d.ts');

// A bare specifier left in a published declaration must resolve for the
// consumer: through a types package the manifest names.
const declared = new Set([...Object.keys(pkg.dependencies ?? {}), ...Object.keys(pkg.peerDependencies ?? {})]);
const typesFor = (specifier) => {
  const name = packageOf(specifier);
  return name.startsWith('@types/') ? name : `@types/${name.replace(/^@(.*)\/(.*)$/, '$1__$2')}`;
};
const typeSources = new Set();
for (const key of kept) {
  for (const specifier of external.get(key)) {
    const types = typesFor(specifier);
    if (!declared.has(types)) fail(`${key} imports ${specifier}, and package.json does not name ${types}.`);
    typeSources.add(types);
  }
}

const published = overlay(new Map([...linked].filter(([key]) => kept.has(key))), OVERLAYS);
for (const [key, text] of published) {
  const path = join(dist, 'types', key);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, text);
}

// Words never split: a word longer than the width gets a line of its own.
const wrap = (text, width) => {
  const lines = [];
  let line = '';
  for (const word of text.split(/\s+/)) {
    if (line && line.length + 1 + word.length > width) {
      lines.push(line);
      line = word;
    } else {
      line = line ? `${line} ${word}` : word;
    }
  }
  return line ? [...lines, line] : lines;
};
const comment = (text) => wrap(text, 76).map((line) => ` * ${line}`).join('\n');
const bullet = (text) =>
  wrap(`- ${text}`, 74)
    .map((line, i) => (i ? ` *   ${line}` : ` * ${line}`))
    .join('\n');

writeFileSync(
  join(dist, 'index.d.ts'),
  [
    '/**',
    comment(
      `ps-flow: TypeScript declarations for its JavaScript surface. Generated by distribution/build.mjs; ` +
        `do not edit. They are upstream's declarations for @xyflow/react ${baseline.react} and ` +
        `@xyflow/system ${baseline.system}, generated from the vendored source.`
    ),
    ' *',
    comment(
      "The documentation comments are upstream's, and so is the behavior they describe. ps-flow matches it " +
        'where its parity gates say so. It differs in these ways:'
    ),
    ' *',
    ...NOTES.map(({ text }) => bullet(text)),
    ' *',
    ' * @packageDocumentation',
    ' */',
    "export * from './types/react/index.js';",
    '',
  ].join('\n')
);

// ── Stylesheets and license ────────────────────────────────────────────

for (const sheet of ['style.css', 'base.css']) {
  copyFileSync(join(repoRoot, 'node_modules/@xyflow/react/dist', sheet), join(dist, sheet));
}
copyFileSync(join(repoRoot, 'xyflow/LICENSE'), join(dist, 'xyflow-LICENSE'));

console.log(
  [
    `build:package: dist/index.js bundles ${inputs.length} modules and imports ${importedPackages.join(', ')}.`,
    `  declarations: ${emitted.size} emitted from xyflow/ (all equal the published package's), ` +
      `${published.size} reachable and published, ${OVERLAYS.length} overlays, ${NOTES.length} notes.`,
    `  declarations reach ${[...typeSources].sort().join(', ')}.`,
    '  stylesheets: style.css and base.css copied from the pinned @xyflow/react.',
  ].join('\n')
);
