import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';

// Use the parser shipped with the pinned SCIP indexer, not AAMF's TS 7 CLI.
const require = createRequire(import.meta.url);
const ts = createRequire(require.resolve('@sourcegraph/scip-typescript/package.json'))('typescript');

/**
 * Recognize definition-free TS modules from stored source and current SCIP
 * evidence. Raw coverage remains unchanged. Never exempt an empty module,
 * missed declaration, side effect, parse error, unresolved target, or a cycle
 * without definitions. This checks local-definition coverage, not API parity.
 */
export function findReexportOnlyFiles(db, filesRelation, rows, provenance, scope) {
  if (!scope || !provenance.latestBaselineRun) return [];
  const baseline = provenance.latestBaselineRun;
  const covered = new Set(provenance.indexers
    .filter(run => run.runId === baseline.id && run.provider === 'scip' && run.status === 'succeeded')
    .flatMap(run => run.details?.coveredFiles ?? [])
    .map(path => resolve(scope.rootDir, path)));
  const byPath = new Map(rows.map(row => [resolve(row.path), row]));
  const readSnapshot = db.prepare(`SELECT source, last_hash FROM ${filesRelation} WHERE id = ?`);
  const targets = new Map();
  const current = row => covered.has(resolve(row.path))
    && row.layer === 'baseline' && row.generation === baseline.generation;

  for (const row of rows) {
    if (row.symbols !== 0 || !current(row) || !/\.tsx?$/u.test(row.path)) continue;
    const snapshot = readSnapshot.get(row.id);
    if (!snapshot || typeof snapshot.source !== 'string'
      || createHash('sha256').update(snapshot.source).digest('hex') !== snapshot.last_hash) continue;
    const source = ts.createSourceFile(row.path, snapshot.source, ts.ScriptTarget.Latest, true);
    if (source.parseDiagnostics.length || !source.statements.length) continue;
    const dependencies = [];
    for (const statement of source.statements) {
      if (!ts.isExportDeclaration(statement) || !statement.moduleSpecifier
        || !ts.isStringLiteral(statement.moduleSpecifier) || !statement.moduleSpecifier.text.startsWith('.')) break;
      const module = ts.resolveModuleName(statement.moduleSpecifier.text, row.path, {
        module: ts.ModuleKind.ESNext, moduleResolution: ts.ModuleResolutionKind.Bundler,
      }, {
        fileExists: path => byPath.has(resolve(path)),
        readFile: () => undefined,
      }).resolvedModule;
      const target = module && byPath.get(resolve(module.resolvedFileName));
      if (!target || !current(target)) break;
      dependencies.push(resolve(target.path));
    }
    if (dependencies.length === source.statements.length) targets.set(resolve(row.path), dependencies);
  }

  // Every branch must terminate at current indexed definitions. Be conservative
  // about re-export cycles instead of treating a self-reference as coverage.
  function reachesDefinitions(path, visiting) {
    const row = byPath.get(path);
    if (!row || !current(row)) return false;
    if (row.symbols > 0) return true;
    if (visiting.has(path) || !targets.has(path)) return false;
    const next = new Set(visiting).add(path);
    return targets.get(path).every(target => reachesDefinitions(target, next));
  }
  return rows.filter(row => targets.has(resolve(row.path)) && reachesDefinitions(resolve(row.path), new Set()));
}
