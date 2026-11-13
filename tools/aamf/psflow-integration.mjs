// Opt-in integration for the pinned AAMF build. Target context is files, never
// a claim that Lore resolves PureScript symbols. All state lives outside target.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFile } from 'node:child_process';
import { mkdir, readFile, readdir, readlink, realpath, rm, writeFile } from 'node:fs/promises';
import { dirname, isAbsolute, join, relative, resolve } from 'node:path';
import { promisify } from 'node:util';

export const digest = value => createHash('sha256').update(value).digest('hex');
export const json = async path => JSON.parse(await readFile(path, 'utf8'));
export async function save(path, value) {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, `${JSON.stringify(value, null, 2)}\n`);
}

// Existing files only: no invented targets, aliases, or symlink escapes.
export async function canonical(root, path, mustExist = true) {
  const base = await realpath(root);
  let full;
  try { full = await realpath(resolve(base, path)); }
  catch (error) {
    if (mustExist || error.code !== 'ENOENT') throw error;
    const requested = resolve(base, path);
    const parent = await realpath(dirname(requested));
    full = join(parent, relative(dirname(requested), requested));
  }
  const rel = relative(base, full);
  assert.ok(rel && !rel.startsWith('..') && !isAbsolute(rel), `Path escapes root: ${path}`);
  return full;
}

const excluded = new Set(['.git', '.aamf', 'node_modules', 'output', '.spago', 'xyflow', 'test-results']);
export async function snapshot(root) {
  const files = {};
  async function visit(dir) {
    for (const entry of (await readdir(join(root, dir), { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name))) {
      if (excluded.has(entry.name) || entry.name === '.DS_Store') continue;
      const path = join(dir, entry.name);
      if (entry.isDirectory()) await visit(path);
      else if (entry.isFile()) files[path] = digest(await readFile(join(root, path)));
      else if (entry.isSymbolicLink()) {
        // fs.cp may spell the same link absolutely on rollback. Record the
        // destination relative to the target so its meaning remains stable.
        const link = await readlink(join(root, path));
        files[path] = `symlink:${relative(root, resolve(dirname(join(root, path)), link))}`;
      }
    }
  }
  await visit('');
  return files;
}

export async function validateMapping(mapping, sourceRoot, targetRoot, checkTargets = true) {
  assert.equal(mapping.version, 1);
  assert.equal(mapping.targetContext, 'files');
  assert.equal(mapping.existingProject, true);
  assert.equal(mapping.units.length, 171, 'Every scoped source file needs a disposition');
  assert.equal(new Set(mapping.units.map(u => u.source)).size, 171);
  const scoped = [];
  async function visitSource(dir) {
    for (const entry of await readdir(join(sourceRoot, dir), { withFileTypes: true })) {
      const path = join(dir, entry.name);
      if (entry.isDirectory()) await visitSource(path);
      else if (/\.tsx?$/.test(path) && !/\.(test|spec)\.ts$/.test(path)) scoped.push(path);
    }
  }
  for (const [pkg, version] of Object.entries(mapping.packages)) {
    assert.equal((await json(join(sourceRoot, 'packages', pkg, 'package.json'))).version, version);
    await visitSource(`packages/${pkg}/src`);
  }
  assert.deepEqual(scoped.sort(), mapping.units.map(u => u.source).sort(), 'Source scope changed');
  const outputs = new Set();
  for (const task of mapping.tasks) {
    assert.ok(task.id && task.acceptanceCriteria.length && task.targetFiles.length);
    if (checkTargets) for (const path of task.targetFiles) outputs.add(await canonical(targetRoot, path, false));
  }
  for (const unit of mapping.units) {
    assert.equal(digest(await readFile(await canonical(sourceRoot, unit.source))), unit.sha256, `Stale source: ${unit.source}`);
    assert.ok(unit.symbols.length || unit.accounting === 'reexport-only');
    assert.ok(unit.disposition && unit.evidence && unit.work);
    assert.ok(unit.targets.some(p => p.endsWith('.purs')), `Missing PureScript destination: ${unit.source}`);
    if (checkTargets) for (const path of [...unit.targets, ...unit.converters]) await canonical(targetRoot, path);
  }
  for (const task of mapping.tasks) {
    assert.ok(task.sourceFiles.every(path => mapping.units.some(u => u.source === path)));
    assert.ok(task.dependencies.every(id => mapping.tasks.some(t => t.id === id)), 'Dangling task dependency');
    if (checkTargets) for (const path of task.referenceFiles) await canonical(targetRoot, path);
    // Reused implementations can be read, but cannot enter the pilot write queue.
    if (checkTargets) for (const path of task.referenceFiles) assert.ok(!outputs.has(await canonical(targetRoot, path)), `Reused file scheduled for writing: ${path}`);
  }
  return mapping;
}

async function load(ctx, checkTargets = true) {
  const path = process.env.PSFLOW_AAMF_RECONCILIATION;
  if (!path) {
    try {
      await readFile(join(ctx.paths.artifactsPlanningDir, 'psflow-reconciliation.json'));
    } catch (error) { if (error.code === 'ENOENT') return null; throw error; }
    throw new Error('Reconciled checkpoint requires PSFLOW_AAMF_RECONCILIATION');
  }
  const bytes = await readFile(path);
  const mapping = await validateMapping(JSON.parse(bytes), ctx.config.source.path, ctx.config.target.outputPath, checkTargets);
  assert.equal(ctx.config.target.language, 'purescript');
  assert.equal(ctx.config.options.maxParallelAgents, 1);
  assert.equal(ctx.config.options.executionMode, 'per-task');
  assert.equal(ctx.config.options.qualityPolicy, 'strict');
  assert.equal(ctx.config.options.git.enabled, false);
  assert.ok(ctx.maxPhase <= 4, 'This integration stops at the pilot; later phases are outside Step 2');
  const stateFile = join(ctx.paths.artifactsPlanningDir, 'psflow-reconciliation.json');
  let previous;
  try { previous = await json(stateFile); } catch (error) { if (error.code !== 'ENOENT') throw error; }
  const mappingDigest = digest(bytes);
  if (previous) assert.equal(previous.mappingDigest, mappingDigest, 'Mapping changed: use a new project, never reuse completion state');
  return { mapping, mappingDigest, stateFile };
}

export async function assertOwnedChanges(ctx, task) {
  const loaded = await load(ctx);
  if (!loaded) return;
  const { mapping } = loaded;
  const allowed = new Set((task ? task.targetFiles : mapping.tasks.flatMap(t => t.targetFiles))
    .map(p => relative(ctx.config.target.outputPath, resolve(ctx.config.target.outputPath, p))));
  const current = await snapshot(ctx.config.target.outputPath);
  const before = mapping.targetSnapshot;
  const changed = [...new Set([...Object.keys(before), ...Object.keys(current)])]
    .filter(path => before[path] !== current[path]);
  assert.deepEqual(changed.filter(path => !allowed.has(path)), [], 'Target changed outside reviewed outputs');
  return changed;
}

export async function selectGraph(ctx, original) {
  const loaded = await load(ctx);
  if (!loaded) return original;
  const { mapping, mappingDigest, stateFile } = loaded;
  await assertOwnedChanges(ctx);
  const tasks = [];
  for (const task of mapping.tasks) {
    tasks.push({
      ...task,
      sourceFiles: await Promise.all(task.sourceFiles.map(p => canonical(ctx.config.source.path, p))),
      targetFiles: [...new Set(await Promise.all(task.targetFiles.map(p => canonical(ctx.config.target.outputPath, p, false))))],
      knowledgeBaseRef: 'PSFlow reviewed source-to-existing-target reconciliation',
      complexity: 'simple',
      parityChecks: task.acceptanceCriteria,
    });
  }
  const graph = { tasks, sccs: [], compilationUnits: [] };
  // Preserve the entire source graph, including reused dependencies and cycles.
  await save(join(ctx.paths.artifactsPlanningDir, 'psflow-source-context.json'), original);
  await save(stateFile, { mappingDigest, sourceCommit: mapping.aamfCommit, targetCommit: mapping.psflowCommit, graph });
  return graph;
}

// Called by actual phase-4 discovery on fresh and resumed executions, before
// normalization could drop dependencies. Disk-only substitutions are rejected.
export async function discoverGraph(ctx, input) {
  const loaded = await load(ctx);
  if (!loaded) return null;
  const state = await json(loaded.stateFile);
  assert.ok(input, 'Reconciled structured step output is required');
  for (const key of ['tasks', 'sccs', 'compilationUnits']) assert.deepEqual(input[key], state.graph[key], `Checkpoint graph mismatch: ${key}`);
  assert.deepEqual(await json(join(ctx.paths.artifactsPlanningDir, 'tasks-merged.json')), state.graph.tasks);
  await assertOwnedChanges(ctx);
  await save(join(ctx.paths.artifactsPlanningDir, 'psflow-phase4-discovery.json'), {
    mappingDigest: loaded.mappingDigest,
    taskIds: state.graph.tasks.map(t => t.id),
    completedTasks: ctx.checkpoint.getState().completedTasks,
    targetContext: 'files',
  });
  return state.graph.tasks;
}

export async function existingProjectPhase(ctx, phase) {
  const loaded = await load(ctx);
  if (!loaded) return null;
  await assertOwnedChanges(ctx);
  const path = phase === 2 ? join(ctx.paths.knowledgeBaseDir, 'index.md') : ctx.paths.migrationPlanFile;
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, `# Reviewed PSFlow ${phase === 2 ? 'knowledge' : 'existing-project plan'}\n\nMapping: ${loaded.mappingDigest}\n\nUse existing Spago and npm project. No scaffold generation.\n\n${loaded.mapping.tasks.map(t => `${t.id}: ${t.description}\n${t.acceptanceCriteria.join('\n')}`).join('\n\n')}\n`);
  return { phase, name: phase === 2 ? 'Reviewed source knowledge' : 'Preserve existing project', success: true, duration: 0, outputPath: path };
}

export async function addFileContext(config, context) {
  if (!process.env.PSFLOW_AAMF_RECONCILIATION) return context;
  const mapping = await json(process.env.PSFLOW_AAMF_RECONCILIATION);
  const task = mapping.tasks.find(t => t.id === context.taskId);
  const paths = task?.referenceFiles ?? [];
  const files = await Promise.all(paths.map(p => canonical(config.target.outputPath, p)));
  const sourceFiles = await Promise.all((task?.sourceReferenceFiles ?? []).map(p => canonical(config.source.path, p)));
  const hashes = await Promise.all(files.map(async path => ({ path, sha256: digest(await readFile(path)) })));
  return { ...context, inputFiles: [...new Set([...context.inputFiles, ...files, ...sourceFiles])], guidance: [
    ...(context.guidance ?? []),
    'Target context is explicit file content, not a resolved PureScript symbol index. Read every provided target reference before editing. Reuse core geometry unchanged. Only the task targetFiles may change. Do not scaffold, change comparator rules, broaden exceptions, or start any other task.',
    `Current target file snapshots (refresh on every invocation): ${JSON.stringify(hashes)}`,
  ] };
}

export class FileTargetContext {
  constructor(ctx) { this.ctx = ctx; this.isBuilt = false; }
  setOnFirstBuild() {} // No Lore DB or target MCP symbol server is advertised.
  markBuilt() {} // A leftover JS-only index does not establish PureScript coverage.
  async build() {
    const loaded = await load(this.ctx);
    const paths = [...new Set(loaded.mapping.tasks.flatMap(t => [...t.referenceFiles, ...t.targetFiles]))];
    const files = [];
    for (const path of paths) {
      const full = await canonical(this.ctx.config.target.outputPath, path, false);
      try { await readFile(full); } catch (error) { if (error.code === 'ENOENT') continue; throw error; }
      const text = await readFile(full, 'utf8');
      files.push({ path, sha256: digest(text),
        ...(path.endsWith('.purs') ? { module: text.match(/^module\s+([\w.]+)/m)?.[1], imports: [...text.matchAll(/^import\s+([\w.]+)/gm)].map(m => m[1]) } : {}) });
    }
    await save(join(this.ctx.paths.artifactsPlanningDir, 'psflow-target-files.json'), { mode: 'files', symbolCoverage: null, files });
    this.isBuilt = true;
  }
  async updateForFiles() { await this.build(); }
  async invalidate() {
    this.isBuilt = false;
    await rm(join(this.ctx.paths.artifactsPlanningDir, 'psflow-target-files.json'), { force: true });
  }
}

export async function beforeRun(ctx) {
  let pending = [];
  try { pending = await readdir(join(ctx.paths.stateDir, 'target-change-sets')); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  // An interrupted full rollback can leave the target temporarily incomplete.
  // Validate source/mapping identity before recovery, then let AAMF restore its
  // durable snapshot before requiring target files and their hashes again.
  const loaded = await load(ctx, pending.length === 0);
  if (!loaded) return;
  if (pending.length === 0) {
    await assertOwnedChanges(ctx);
    let state = ctx.checkpoint?.getState();
    if (!state) {
      try { state = await json(join(ctx.paths.stateDir, 'checkpoint.json')); }
      catch (error) { if (error.code !== 'ENOENT') throw error; }
    }
    const completed = loaded.mapping.tasks.filter(t => state?.completedTasks.includes(t.id));
    if (completed.length) {
      const context = await json(join(ctx.paths.artifactsPlanningDir, 'psflow-target-files.json'));
      for (const task of completed) for (const path of task.targetFiles) {
        const accepted = context.files.find(file => file.path === path);
        assert.ok(accepted, `Completed task has no accepted file context: ${path}`);
        assert.equal(digest(await readFile(await canonical(ctx.config.target.outputPath, path))), accepted.sha256,
          `Completed task output changed: ${path}; create a new reviewed project`);
      }
    }
  }
}

// Stock test-writer attribution requires a changed test file. In an existing
// project, an unchanged, reviewed regression can be adopted instead. Produce
// runtime evidence by executing that exact pinned file; never manufacture a
// test edit or treat an agent's green verdict as the command result.
export async function adoptExistingTests(config, paths, invocation, result, parsed) {
  if (!process.env.PSFLOW_AAMF_RECONCILIATION || invocation.agent !== 'test-writer'
    || !result.success || result.extensions.outputFiles.length || !parsed.parsed
    || parsed.data.status !== 'completed') return;
  const loaded = await load({ config, paths, maxPhase: 4 });
  const task = loaded.mapping.tasks.find(t => t.id === invocation.workItemId);
  assert.ok(task, 'Unknown test adoption task');
  const tests = task.targetFiles.filter(p => p.endsWith('.test.mjs'));
  assert.ok(tests.length, 'No reviewed Node regression is available for adoption');
  const evidence = [];
  for (const path of tests) {
    const full = await canonical(config.target.outputPath, path);
    const sha256 = digest(await readFile(full));
    assert.equal(sha256, loaded.mapping.targetSnapshot[path], `Changed test cannot be adopted: ${path}`);
    const args = ['--test', '--test-reporter=tap', full];
    const env = { ...process.env };
    delete env.NODE_TEST_CONTEXT; // A nested Node test must run as its own test process.
    const { stdout, stderr } = await promisify(execFile)(process.execPath, args, {
      cwd: config.target.outputPath, env, maxBuffer: 4 * 1024 * 1024, timeout: 300000,
    });
    assert.match(stdout, /# tests [1-9][0-9]*\b/, 'Adoption did not execute a test');
    assert.match(stdout, /# fail 0\b/, 'Adoption did not report zero failures');
    assert.equal(digest(await readFile(full)), sha256, 'Test changed during adoption');
    evidence.push({ path, sha256, command: [process.execPath, ...args], exitCode: 0, stdout, stderr });
  }
  const report = join(paths.artifactsPlanningDir, 'psflow-adopted-tests.json');
  await save(report, { taskId: task.id, mappingDigest: loaded.mappingDigest, adoptedExistingTests: evidence });
  result.extensions.psflowAdoptedTestReport = report;
}
