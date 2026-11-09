import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdtemp, realpath, rm, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { delimiter, dirname, join, resolve } from 'node:path';
import { after, before, test } from 'node:test';
import { pathToFileURL } from 'node:url';

const aamfRoot = resolve(process.env.PSFLOW_AAMF_ROOT ?? '/private/tmp/psflow-aamf/AAMF');
const loreRoot = join(aamfRoot, 'node_modules/@jafreck/lore');
const { IndexBuilder, validateIndex } = await import(pathToFileURL(join(loreRoot, 'dist/index.js')));
const Database = createRequire(join(loreRoot, 'package.json'))('better-sqlite3');
process.env.PATH = [dirname(process.execPath), join(aamfRoot, 'node_modules/.bin'), process.env.PATH].join(delimiter);

const policy = {
  profile: 'migration-grade',
  thresholds: { minCallRefs: 1, maxSymbolLessFiles: 0 },
  requireStructuralIndex: true,
  requireValidSpans: true,
  requireIndexerSuccess: true,
  requireProvenance: true,
};
let rootDir;
let dbPath;
let options;

before(async () => {
  rootDir = await realpath(await mkdtemp(join(tmpdir(), 'psflow-phase0-test-')));
  dbPath = join(rootDir, 'index.db');
  const sources = {
    'package.json': JSON.stringify({ name: 'psflow-phase0-test', version: '1.0.0', private: true }),
    'tsconfig.json': JSON.stringify({ compilerOptions: { target: 'ESNext', module: 'ESNext', moduleResolution: 'bundler', strict: true, noEmit: true }, include: ['*.ts'] }),
    'value.ts': 'export const positive = (value: number) => Math.abs(value) > 0;\n',
    'multiline.ts': 'export const\n  magnitude =\n    (value: number) => Math.abs(value);\n',
    'unicode.ts': '/* 🐈 */ export const identity = (value: number) => Math.abs(value);\n',
    'types.ts': 'export interface Input { value: number }\n',
    'index.ts': "export { positive } from './nested';\nexport type { Input } from './types';\n",
    'nested.ts': "export { positive } from './value';\n",
  };
  await Promise.all(Object.entries(sources).map(([name, source]) => writeFile(join(rootDir, name), source)));
  const walkerConfig = { rootDir, includeGlobs: ['*.ts'], excludeGlobs: [] };
  const scipScope = { languages: ['typescript'], includeGlobs: ['*.ts'], excludeGlobs: [] };
  options = { rootDir, walkerConfig, scipScope, policy, maxSamples: 1000 };
  await new IndexBuilder(dbPath, walkerConfig, undefined, {
    scip: true, scipScope, lsp: false, embeddings: false,
    execution: { allowSubprocessExecution: true }, validation: false,
  }).build();
  const report = validateIndex(dbPath, options);
  assert.ok(report.coverage.overall.symbols > 0, JSON.stringify(report.errors));
});

after(async () => {
  if (rootDir) await rm(rootDir, { recursive: true, force: true });
});

test('SCIP initializer spans include the actual identifier, including multiline and Unicode source', () => {
  const report = validateIndex(dbPath, options);
  assert.equal(report.spans.invalid, 0, JSON.stringify(report.spans.samples));
  const db = new Database(dbPath, { readonly: true });
  try {
    for (const row of db.prepare('SELECT s.name, s.selection_line, s.selection_character, f.source FROM symbols s JOIN files f ON f.id = s.file_id').all()) {
      const line = row.source.split(/\r?\n/u)[row.selection_line];
      assert.equal(line.slice(row.selection_character, row.selection_character + row.name.length), row.name);
    }
  } finally { db.close(); }
});

test('migration-grade validation accepts covered re-exports and preserves honest raw coverage', () => {
  const report = validateIndex(dbPath, options);
  assert.equal(report.ok, true, JSON.stringify(report.errors));
  assert.equal(report.coverage.overall.files, 6);
  assert.equal(report.coverage.overall.symbolLessFiles, 2);
  assert.equal(report.symbolLessFiles.reexportOnly.total, 2);
  assert.equal(report.symbolLessFiles.unexpectedTotal, 0);
  assert.ok(report.coverage.overall.calls.total >= 1);
});

test('language-specific symbol-less-file thresholds also distinguish covered re-exports', () => {
  const report = validateIndex(dbPath, {
    ...options,
    policy: { ...policy, languages: { typescript: { maxSymbolLessFiles: 0 } } },
  });
  assert.equal(report.ok, true, JSON.stringify(report.errors));
});

async function alteredIndex(name, change) {
  const destination = join(rootDir, `${name}.db`);
  const original = new Database(dbPath, { readonly: true });
  try { await original.backup(destination); } finally { original.close(); }
  const db = new Database(destination);
  try { change(db); } finally { db.close(); }
  return validateIndex(destination, options);
}

function replaceSnapshot(db, file, source) {
  db.prepare('UPDATE files SET source = ?, last_hash = ? WHERE path = ?').run(
    source, createHash('sha256').update(source).digest('hex'), join(rootDir, file),
  );
}

test('a genuinely missing definition still fails the zero symbol-less-file threshold', async () => {
  const report = await alteredIndex('missing-definition', db => {
    db.prepare('DELETE FROM symbols WHERE file_id = (SELECT id FROM files WHERE path = ?)').run(join(rootDir, 'value.ts'));
  });
  assert.equal(report.ok, false);
  assert.ok(report.errors.some(error => error.code === 'THRESHOLD_MAX_SYMBOL_LESS_FILES'));
});

test('invalid spans are still rejected', async () => {
  const report = await alteredIndex('invalid-span', db => {
    db.prepare("UPDATE symbols SET start_character = 100000 WHERE name = 'positive'").run();
  });
  assert.equal(report.ok, false);
  assert.ok(report.errors.some(error => error.code === 'INVALID_SPANS'));
});

for (const [name, source] of [
  ['empty', '// no definitions or exports\n'],
  ['side-effect', "export { positive } from './value';\nconsole.log('side effect');\n"],
  ['declaration', 'export const missed = 1;\n'],
  ['unresolved-export', "export { missing } from './missing';\n"],
  ['parse-error', "export { from './value';\n"],
]) {
  test(`${name} source is not exempted as a re-export-only file`, async () => {
    const report = await alteredIndex(name, db => replaceSnapshot(db, 'index.ts', source));
    assert.equal(report.ok, false);
    assert.ok(report.errors.some(error => error.code === 'THRESHOLD_MAX_SYMBOL_LESS_FILES'));
  });
}

test('a cycle of re-exports with no indexed definitions is not exempted', async () => {
  const report = await alteredIndex('barrel-cycle', db => {
    replaceSnapshot(db, 'index.ts', "export * from './nested';\n");
    replaceSnapshot(db, 'nested.ts', "export * from './index';\n");
  });
  assert.equal(report.ok, false);
  assert.ok(report.errors.some(error => error.code === 'THRESHOLD_MAX_SYMBOL_LESS_FILES'));
});

test('a source snapshot with a stale hash cannot earn a re-export exemption', async () => {
  const report = await alteredIndex('stale-hash', db => {
    db.prepare('UPDATE files SET last_hash = ? WHERE path = ?').run('0'.repeat(64), join(rootDir, 'index.ts'));
  });
  assert.equal(report.ok, false);
  assert.ok(report.errors.some(error => error.code === 'THRESHOLD_MAX_SYMBOL_LESS_FILES'));
});

test('a re-export file without current SCIP document coverage is rejected', async () => {
  const report = await alteredIndex('missing-scip-coverage', db => {
    const run = db.prepare("SELECT id, details_json FROM indexer_runs WHERE provider = 'scip' AND status = 'succeeded'").get();
    const details = JSON.parse(run.details_json);
    details.coveredFiles = details.coveredFiles.filter(path => path !== 'index.ts');
    db.prepare('UPDATE indexer_runs SET details_json = ? WHERE id = ?').run(JSON.stringify(details), run.id);
  });
  assert.equal(report.ok, false);
  assert.ok(report.errors.some(error => error.code === 'SCIP_SCOPE_UNCOVERED_FILES'));
  assert.ok(report.errors.some(error => error.code === 'THRESHOLD_MAX_SYMBOL_LESS_FILES'));
});
