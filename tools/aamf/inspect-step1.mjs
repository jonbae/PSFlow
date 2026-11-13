import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { copyFile, mkdir, readFile, readdir, writeFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const workspace = process.argv[2] && resolve(process.argv[2]);
const destination = process.argv[3] && resolve(process.argv[3]);
assert.ok(workspace && destination, 'Usage: node tools/aamf/inspect-step1.mjs <workspace> <artifact directory>');
const repo = fileURLToPath(new URL('../../', import.meta.url));
const config = JSON.parse(await readFile(join(workspace, 'analysis.json'), 'utf8'));
const source = config.source.path;
const target = config.target.outputPath;
const aamf = join(workspace, 'AAMF');
const require = createRequire(join(aamf, 'package.json'));
const Database = require('better-sqlite3');
const glob = require('fast-glob');
const ts = createRequire(require.resolve('@sourcegraph/scip-typescript/package.json'))('typescript');
const { validateIndex } = await import(pathToFileURL(join(aamf, 'node_modules/@jafreck/lore/dist/index.js')));
const state = join(workspace, '.aamf/migration', config.projectName);
const planning = join(state, 'artifacts/planning');
const json = async path => JSON.parse(await readFile(path, 'utf8'));
const hash = data => createHash('sha256').update(data).digest('hex');
const selected = glob.sync(config.source.includePatterns, { cwd: source, absolute: true, onlyFiles: true, ignore: config.source.excludePatterns }).sort();
const selectedSet = new Set(selected);
const tasks = await json(join(planning, 'tasks-merged.json'));
const sccs = await json(join(planning, 'sccs.json'));
const units = await json(join(planning, 'compilation-units.json'));
const dependencies = await json(join(planning, 'dependency-summary.json'));
const checkpoint = await json(join(state, 'state/checkpoint.json'));
assert.deepEqual(checkpoint.completedPhases, [0, 1]);
assert.equal(checkpoint.currentPhase, 2);
assert.equal(checkpoint.tokenUsage.total, 0);
for (const [container, key] of [['outputs', 'task-graph-construction'], ['executionOutputs', 'aamf-migration/task-graph-construction']]) {
  const output = checkpoint.__flowCheckpoint[container][key];
  assert.equal(output.success, true);
  assert.deepEqual(output.tasks, tasks);
  assert.deepEqual(output.sccs, sccs);
  assert.deepEqual(output.compilationUnits, units);
}

const policy = {
  profile: 'migration-grade', thresholds: { minCallRefs: 1, maxSymbolLessFiles: 0 },
  requireStructuralIndex: true, requireValidSpans: true,
  requireIndexerSuccess: true, requireProvenance: true,
};
const dbPath = join(state, 'kb.db');
const inspection = validateIndex(dbPath, { rootDir: source, policy });
const health = validateIndex(dbPath, { rootDir: source, scipScope: inspection.provenance.scipScope.requested, policy, maxSamples: 10000 });
assert.equal(health.ok, true, JSON.stringify(health.errors));
assert.equal(health.spans.invalid, 0);
assert.equal(health.symbolLessFiles.unexpectedTotal, 0);
await writeFile(join(workspace, 'step1-index-health.json'), `${JSON.stringify(health, null, 2)}\n`);
const db = new Database(dbPath, { readonly: true });
assert.equal(db.pragma('integrity_check', { simple: true }), 'ok');
const files = db.prepare('SELECT * FROM files ORDER BY path').all();
assert.deepEqual(files.map(file => file.path).sort(), selected);
const direct = new Set(tasks.flatMap(task => task.sourceFiles));
const references = new Set(tasks.flatMap(task => [...task.knowledgeBaseRef.matchAll(/kb\/(.*?)#L/gu)].map(match => match[1])));
const reexports = new Set(health.symbolLessFiles.reexportOnly.files.map(file => file.path));
const accounted = new Set([...direct, ...references, ...reexports]);
assert.deepEqual([...accounted].sort(), selected);
const ids = new Set(tasks.map(task => task.id));
assert.equal(ids.size, tasks.length);
for (const task of tasks) {
  assert.ok(task.symbols.length, `File-only fallback task: ${task.id}`);
  for (const dependency of task.dependencies) assert.ok(ids.has(dependency), `Unknown dependency ${dependency}`);
}

// Verify persisted SCCs against an independent traversal of the actual edges.
const edges = new Map(tasks.map(task => [task.id, task.dependencies]));
const order = new Map(), low = new Map(), active = [], onStack = new Set(), cycles = [];
let sequence = 0;
function visit(node) {
  order.set(node, sequence); low.set(node, sequence++); active.push(node); onStack.add(node);
  for (const dependency of edges.get(node)) {
    if (!order.has(dependency)) { visit(dependency); low.set(node, Math.min(low.get(node), low.get(dependency))); }
    else if (onStack.has(dependency)) low.set(node, Math.min(low.get(node), order.get(dependency)));
  }
  if (low.get(node) === order.get(node)) {
    const component = [];
    let value;
    do { value = active.pop(); onStack.delete(value); component.push(value); } while (value !== node);
    if (component.length > 1 || edges.get(node).includes(node)) cycles.push(component.sort());
  }
}
for (const id of ids) if (!order.has(id)) visit(id);
const sortedGroups = groups => groups.map(group => [...group].sort()).sort((a, b) => JSON.stringify(a).localeCompare(JSON.stringify(b)));
assert.deepEqual(sortedGroups(cycles), sortedGroups(sccs));

const sourceRelative = path => relative(source, path);
const inventory = [];
for (const file of files) {
  const contents = await readFile(file.path);
  assert.equal(hash(contents), file.last_hash);
  assert.equal(hash(await readFile(join(repo, 'xyflow', sourceRelative(file.path)))), file.last_hash);
  inventory.push({
    path: sourceRelative(file.path), sha256: file.last_hash, language: file.language,
    symbols: db.prepare('SELECT COUNT(*) AS n FROM symbols WHERE file_id = ?').get(file.id).n,
    calls: db.prepare('SELECT COUNT(*) AS n FROM symbol_refs WHERE file_id = ?').get(file.id).n,
    types: db.prepare('SELECT COUNT(*) AS n FROM type_refs WHERE file_id = ?').get(file.id).n,
    accounting: direct.has(file.path) ? 'task' : references.has(file.path) ? 'reference' : 'reexport-only',
  });
}

// Audit actual source module specifiers; Lore's empty import table cannot do this.
const parsed = ts.parseJsonConfigFileContent(ts.readConfigFile(join(source, 'tsconfig.json'), ts.sys.readFile).config, ts.sys, source);
assert.equal(parsed.errors.length, 0);
const cache = ts.createModuleResolutionCache(source, path => path, parsed.options);
const imports = [];
for (const path of selected) {
  const text = await readFile(path, 'utf8');
  const ast = ts.createSourceFile(path, text, ts.ScriptTarget.Latest, true);
  assert.equal(ast.parseDiagnostics.length, 0, path);
  function record(node, literal, kind) {
    const location = ast.getLineAndCharacterOfPosition(node.getStart(ast));
    const specifier = literal && ts.isStringLiteralLike(literal) ? literal.text : null;
    const resolved = specifier && ts.resolveModuleName(specifier, path, parsed.options, ts.sys, cache).resolvedModule;
    let status = 'unresolved', to = null;
    if (!specifier) status = 'nonliteral';
    else if (resolved) {
      const absolute = resolve(resolved.resolvedFileName);
      if (selectedSet.has(absolute)) { status = 'scoped'; to = sourceRelative(absolute); }
      else if (absolute.includes('/node_modules/')) {
        status = 'external'; to = `node_modules/${absolute.slice(absolute.lastIndexOf('/node_modules/') + 14)}`;
      } else { status = 'outside-scope'; to = sourceRelative(absolute); }
    } else if (specifier.startsWith('.') && /\.(css|svg|png|jpg|json)$/u.test(specifier) && ts.sys.fileExists(resolve(dirname(path), specifier))) {
      status = 'asset'; to = sourceRelative(resolve(dirname(path), specifier));
    }
    imports.push({ from: sourceRelative(path), line: location.line + 1, kind, specifier, status, to });
  }
  function inspect(node) {
    if (ts.isImportDeclaration(node)) record(node, node.moduleSpecifier, 'import');
    else if (ts.isExportDeclaration(node) && node.moduleSpecifier) record(node, node.moduleSpecifier, 'reexport');
    else if (ts.isImportEqualsDeclaration(node) && ts.isExternalModuleReference(node.moduleReference)) record(node, node.moduleReference.expression, 'import-equals');
    else if (ts.isImportTypeNode(node)) record(node, ts.isLiteralTypeNode(node.argument) ? node.argument.literal : null, 'type-import');
    else if (ts.isCallExpression(node) && (node.expression.kind === ts.SyntaxKind.ImportKeyword || (ts.isIdentifier(node.expression) && node.expression.text === 'require'))) record(node, node.arguments[0], 'dynamic-import');
    ts.forEachChild(node, inspect);
  }
  inspect(ast);
}
const counts = (rows, field) => Object.fromEntries([...new Set(rows.map(row => row[field]))].sort().map(value => [value, rows.filter(row => row[field] === value).length]));
const importAudit = {
  method: 'TypeScript source AST plus resolveModuleName using the isolated source tsconfig and installed source dependencies',
  parserVersion: ts.version, counts: counts(imports, 'status'), kinds: counts(imports, 'kind'),
  unresolved: imports.filter(edge => edge.status === 'unresolved' || edge.status === 'nonliteral'),
  outsideScope: imports.filter(edge => edge.status === 'outside-scope'),
  reactToSystem: imports.filter(edge => edge.from.startsWith('packages/react/') && edge.to?.startsWith('packages/system/')).length,
  records: imports,
};
const scalar = query => db.prepare(query).get().n;
const byTask = new Map(tasks.map(task => [task.id, task]));
const targetPaths = new Set(tasks.flatMap(task => task.targetFiles));
const javascript = glob.sync(['packages/system/src/**/*.{js,jsx,mjs,cjs}', 'packages/react/src/**/*.{js,jsx,mjs,cjs}'], { cwd: source });
const review = {
  sourceFiles: selected.length, packages: { system: inventory.filter(file => file.path.startsWith('packages/system/')).length, react: inventory.filter(file => file.path.startsWith('packages/react/')).length },
  javascriptFiles: javascript, sourceFilesOmitted: [], tasks: tasks.length,
  dependencyEdges: tasks.reduce((total, task) => total + task.dependencies.length, 0),
  cycles: sccs.map(group => ({ tasks: group, sourceFiles: [...new Set(group.flatMap(id => byTask.get(id).sourceFiles.map(sourceRelative)))].sort() })),
  compilationUnits: units.length, directTaskFiles: direct.size,
  additionalReferenceFiles: [...references].filter(path => !direct.has(path)).length,
  reexportOnlyFiles: reexports.size, fileOnlyFallbackTasks: 0, danglingDependencies: 0,
  complexity: counts(tasks, 'complexity'), maxTaskLines: Math.max(...tasks.map(task => task.totalLines)),
  dependencySummary: { files: dependencies.fileCount, modules: dependencies.modules.length, connectedComponents: dependencies.connectedComponents.length, largestConnectedComponent: Math.max(...dependencies.connectedComponents.map(group => group.moduleIds.length)) },
  importAudit: { total: imports.length, counts: importAudit.counts, unresolved: importAudit.unresolved.length, outsideScope: importAudit.outsideScope.length, reactToSystem: importAudit.reactToSystem },
  crossPackageCalls: scalar("SELECT COUNT(*) AS n FROM symbol_refs r JOIN files f ON f.id=r.file_id JOIN symbols s ON s.id=r.callee_id JOIN files t ON t.id=s.file_id WHERE f.path LIKE '%/packages/react/src/%' AND t.path LIKE '%/packages/system/src/%'"),
  crossPackageTypes: scalar("SELECT COUNT(*) AS n FROM type_refs r JOIN files f ON f.id=r.file_id JOIN symbols s ON s.id=r.type_id JOIN files t ON t.id=s.file_id WHERE f.path LIKE '%/packages/react/src/%' AND t.path LIKE '%/packages/system/src/%'"),
  generatedTargets: targetPaths.size, targetExtensions: [...new Set([...targetPaths].map(path => path.slice(path.lastIndexOf('.'))))],
  checkpoint: { completedPhases: checkpoint.completedPhases, currentPhase: checkpoint.currentPhase, structuredGraphMatchesArtifacts: true, tokens: checkpoint.tokenUsage.total },
};
async function snapshot(root) {
  const result = [];
  async function walk(directory) {
    for (const item of await readdir(directory, { withFileTypes: true })) {
      if (['node_modules', '.git', '.DS_Store'].includes(item.name)) continue;
      const path = join(directory, item.name);
      if (item.isDirectory()) await walk(path);
      else if (item.isFile()) result.push({ path: relative(root, path), sha256: hash(await readFile(path)) });
    }
  }
  await walk(root); return result.sort((a, b) => a.path.localeCompare(b.path));
}
const integrity = {};
for (const [label, root] of [['source', source], ['target', target]]) {
  const before = await json(join(workspace, `${label}-before.json`));
  const after = await snapshot(root);
  const a = new Map(before.map(file => [file.path, file.sha256])), b = new Map(after.map(file => [file.path, file.sha256]));
  const changed = before.filter(file => b.has(file.path) && b.get(file.path) !== file.sha256).map(file => file.path);
  const removed = before.filter(file => !b.has(file.path)).map(file => file.path);
  const added = after.filter(file => !a.has(file.path)).map(file => file.path);
  assert.deepEqual(changed, []); assert.deepEqual(removed, []);
  assert.deepEqual(added, label === 'source' ? ['tsconfig.json'] : []);
  integrity[label] = { beforeFiles: before.length, afterFiles: after.length, changed, removed, added, beforeDigest: hash(JSON.stringify([...a].sort())), afterDigest: hash(JSON.stringify([...b].sort())) };
}
integrity.originalScopedFilesMatch = true;
integrity.certifiedDatabaseSha256 = hash(await readFile(dbPath));
db.close();

// Keep public JSON portable; raw runtime paths are retained inside the archive.
function portable(value) {
  if (typeof value === 'string') return value.replaceAll(source, 'xyflow').replaceAll(target, 'PSFlow').replaceAll(workspace, '<workspace>');
  if (Array.isArray(value)) return value.map(portable);
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, portable(item)]));
  return value;
}
await mkdir(destination, { recursive: true });
for (const [name, value] of Object.entries({
  'inventory.json': inventory, 'task-graph.json': { tasks, sccs, compilationUnits: units },
  'dependency-summary.json': dependencies, 'index-health.json': health,
  'imports.json': importAudit, 'review.json': review, 'integrity.json': integrity,
  'execution.json': await json(join(workspace, 'run-result.json')),
  'compatibility-patches.json': await json(join(workspace, 'compatibility-patches.json')),
})) await writeFile(join(destination, name), `${JSON.stringify(portable(value), null, 2)}\n`);
for (const name of ['migrate.log', 'status.txt', 'tests.log']) await copyFile(join(workspace, name), join(destination, name));
console.log(JSON.stringify({ destination, review, warnings: health.warnings, importExceptions: importAudit.unresolved }, null, 2));
