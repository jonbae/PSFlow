import assert from 'node:assert/strict';
import test from 'node:test';
import { mkdtemp, mkdir, readFile, realpath, rm, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { canonical, digest, discoverGraph, existingProjectPhase, FileTargetContext,
  adoptExistingTests, assertOwnedChanges, beforeRun, json, save, selectGraph, snapshot, validateMapping, addFileContext } from './psflow-integration.mjs';

const aamf = process.env.PSFLOW_AAMF_ROOT;
assert.ok(aamf, 'Set PSFLOW_AAMF_ROOT to the installed pinned AAMF checkout');
const { buildPhase4Subflow } = await import(pathToFileURL(join(aamf, 'dist/flow/steps/migration.js')));
const { AamfFlowCheckpointAdapter } = await import(pathToFileURL(join(aamf, 'dist/flow/checkpoint-adapter.js')));
const { CheckpointManager } = await import(pathToFileURL(join(aamf, 'dist/core/checkpoint.js')));

async function fixture(t) {
  const dir = await realpath(await mkdtemp(join(tmpdir(), 'psflow-integration-test-')));
  t.after(async () => { delete process.env.PSFLOW_AAMF_RECONCILIATION; await rm(dir, { recursive: true, force: true }); });
  const source = join(dir, 'source');
  const target = join(dir, 'target');
  const planning = join(dir, 'planning');
  await mkdir(join(source, 'packages/system/src'), { recursive: true });
  await mkdir(target);
  await writeFile(join(source, 'packages/system/package.json'), '{"version":"0.0.77"}');
  await writeFile(join(target, 'Geometry.purs'), 'module Geometry where\nimport Prelude\nvalue = 1\n');
  await writeFile(join(target, 'Boundary.purs'), 'module Boundary where\n');
  const units = [];
  for (let n = 0; n < 171; n++) {
    const path = `packages/system/src/unit${n}.ts`;
    const text = `export const unit${n} = ${n};`;
    await writeFile(join(source, path), text);
    units.push({ source: path, sha256: digest(text), symbols: [`unit${n}`], targets: ['Geometry.purs'],
      converters: ['Boundary.purs'], disposition: 'Reuse', evidence: 'fixture value', work: 'context' });
  }
  const task = { id: 'pilot', name: 'pilot', description: 'Cross only the boundary', sourceFiles: [units[0].source],
    targetFiles: ['Boundary.purs'], referenceFiles: ['Geometry.purs'], dependencies: [], acceptanceCriteria: ['entry returns JS'] };
  const mapping = { version: 1, targetContext: 'files', existingProject: true,
    packages: { system: '0.0.77' }, units, tasks: [task], targetSnapshot: await snapshot(target) };
  const path = join(dir, 'mapping.json');
  await save(path, mapping);
  process.env.PSFLOW_AAMF_RECONCILIATION = path;
  const logger = { info() {}, warn() {}, error() {}, event() {}, debug() {} };
  const checkpoint = new CheckpointManager(join(dir, 'checkpoint'), logger);
  await checkpoint.load('psflow-integration-test', { fresh: true });
  const ctx = { config: { source: { path: source }, target: { outputPath: target, language: 'purescript' },
    models: {}, options: { maxParallelAgents: 1, executionMode: 'per-task', git: { enabled: false }, maxLinesPerTask: 1000, qualityPolicy: 'strict' } },
    maxPhase: 4, paths: { stateDir: join(dir, 'state'), artifactsPlanningDir: planning, migrationPlanFile: join(planning, 'plan.md'), knowledgeBaseDir: join(dir, 'kb') },
    checkpoint, logger, costEstimator: { estimateFromTotal: () => ({ total: 0 }) },
    progress: { appendEvent: async () => {}, setTotalTasks: async () => {} }, targetChanges: { bindTask() {} }, tokenTracker: { getTotal: () => 0 } };
  const original = { tasks: [{ id: 'original-core-write', targetFiles: ['Geometry.purescript'] }], sccs: [['cycle-a', 'cycle-b']], compilationUnits: [] };
  async function publish() {
    const graph = await selectGraph(ctx, original);
    await save(join(planning, 'tasks-merged.json'), graph.tasks);
    await save(join(planning, 'sccs.json'), graph.sccs);
    return graph;
  }
  return { dir, source, target, mapping, path, ctx, original, publish };
}

test('selects only the gap; retains source graph/cycles and existing PureScript context', async t => {
  const f = await fixture(t);
  const graph = await f.publish();
  assert.deepEqual(graph.tasks.map(t => t.id), ['pilot']);
  assert.deepEqual(await json(join(f.ctx.paths.artifactsPlanningDir, 'psflow-source-context.json')), f.original);
  const context = await addFileContext(f.ctx.config, { taskId: 'pilot', inputFiles: [] });
  assert.ok(context.inputFiles.includes(join(f.target, 'Geometry.purs')));
  const index = new FileTargetContext(f.ctx);
  await index.build();
  let files = await json(join(f.ctx.paths.artifactsPlanningDir, 'psflow-target-files.json'));
  assert.equal(files.symbolCoverage, null);
  assert.equal(files.files.find(f => f.path === 'Geometry.purs').module, 'Geometry');
  await writeFile(join(f.target, 'Boundary.purs'), 'module Boundary where\nvalue = 2\n');
  await index.updateForFiles(['Boundary.purs']);
  files = await json(join(f.ctx.paths.artifactsPlanningDir, 'psflow-target-files.json'));
  assert.equal(files.files.find(f => f.path === 'Boundary.purs').sha256, digest(await readFile(join(f.target, 'Boundary.purs'))));
  await index.invalidate();
  await assert.rejects(readFile(join(f.ctx.paths.artifactsPlanningDir, 'psflow-target-files.json')), /ENOENT/);
});

test('real phase-4 discovery uses identical tasks after checkpoint reload; rejects disk-only substitution', async t => {
  const f = await fixture(t);
  const graph = await f.publish();
  const adapter = new AamfFlowCheckpointAdapter(f.ctx.checkpoint);
  assert.ok(adapter);
  const flowCtx = { context: f.ctx, executionPath: ['aamf-migration', 'iterative-migration'] };
  const fresh = await buildPhase4Subflow(flowCtx, graph);
  assert.ok(fresh.nodes.some(n => n.id === 'pilot/migrate'));
  assert.ok(fresh.nodes.every(n => n.id.startsWith('pilot/')));
  // The real checkpoint serializes and reloads the same structured phase-1 output.
  await adapter.save({ flowId: 'aamf-migration', status: 'cancelled', startedAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(), completedExecutionIds: ['aamf-migration/task-graph-construction'],
    outputs: { 'task-graph-construction': graph }, executionOutputs: {} });
  const reloaded = new CheckpointManager(join(f.dir, 'checkpoint'), f.ctx.logger);
  await reloaded.load('psflow-integration-test');
  f.ctx.checkpoint = reloaded;
  const stored = await new AamfFlowCheckpointAdapter(reloaded).load('aamf-migration');
  assert.deepEqual(stored.outputs['task-graph-construction'], graph);
  const resumed = await buildPhase4Subflow(flowCtx, stored.outputs['task-graph-construction']);
  assert.deepEqual(resumed.nodes.map(n => n.id), fresh.nodes.map(n => n.id));
  await reloaded.completeTasks([{ taskId: 'pilot' }]);
  f.ctx.launcher = { launchAgent() { throw new Error('Completed task must not launch an agent'); } };
  for (const node of resumed.nodes) await node.run({ ...flowCtx, signal: new AbortController().signal, executionPath: [node.id] });
  await save(join(f.ctx.paths.artifactsPlanningDir, 'tasks-merged.json'), []);
  await assert.rejects(buildPhase4Subflow(flowCtx, graph));
});

test('rejects stale mapping, changed source, dangling dependencies and reused writers', async t => {
  const f = await fixture(t);
  const graph = await f.publish();
  delete process.env.PSFLOW_AAMF_RECONCILIATION;
  await assert.rejects(discoverGraph(f.ctx, graph), /requires PSFLOW_AAMF_RECONCILIATION/);
  process.env.PSFLOW_AAMF_RECONCILIATION = f.path;
  await save(f.path, { ...f.mapping, note: 'changed after checkpoint' });
  await assert.rejects(discoverGraph(f.ctx, graph), /Mapping changed/);
  await save(f.path, f.mapping);
  await writeFile(join(f.source, f.mapping.units[0].source), 'changed');
  await assert.rejects(discoverGraph(f.ctx, graph), /Stale source/);
  await writeFile(join(f.source, f.mapping.units[0].source), 'export const unit0 = 0;');
  const bad = structuredClone(f.mapping);
  bad.tasks[0].dependencies = ['missing'];
  await assert.rejects(validateMapping(bad, f.source, f.target), /Dangling/);
  bad.tasks[0].dependencies = [];
  bad.tasks[0].targetFiles = ['Geometry.purs'];
  await assert.rejects(validateMapping(bad, f.source, f.target), /Reused file/);
});

test('existing-project phases preserve every file; out-of-scope edits and symlink escapes fail', async t => {
  const f = await fixture(t);
  await f.publish();
  const before = await snapshot(f.target);
  assert.equal((await existingProjectPhase(f.ctx, 2)).success, true);
  assert.equal((await existingProjectPhase(f.ctx, 3)).success, true);
  assert.deepEqual(await snapshot(f.target), before);
  await writeFile(join(f.target, 'new-scaffold.purs'), 'wrong');
  await assert.rejects(assertOwnedChanges(f.ctx), /outside reviewed outputs/);
  await symlink(f.source, join(f.target, 'escape'));
  await assert.rejects(canonical(f.target, 'escape/packages/system/src/unit0.ts'), /escapes root/);
});

test('canonical shared output aliases impose a predecessor in the real phase-4 flow', async t => {
  const f = await fixture(t);
  f.mapping.tasks.push({ ...f.mapping.tasks[0], id: 'second', targetFiles: ['./Boundary.purs'] });
  await save(f.path, f.mapping);
  const graph = await f.publish();
  assert.equal(graph.tasks[0].targetFiles[0], graph.tasks[1].targetFiles[0]);
  const flow = await buildPhase4Subflow({ context: f.ctx, executionPath: ['iterative-migration'] }, graph);
  assert.ok(flow.nodes.find(n => n.id === 'second/migrate').dependsOn.includes('pilot/complete'));
});

test('interrupted rollback can recover missing target files; a changed mapping still fails before recovery', async t => {
  const f = await fixture(t);
  await f.publish();
  await mkdir(join(f.ctx.paths.stateDir, 'target-change-sets/pending'), { recursive: true });
  await rm(join(f.target, 'Boundary.purs'));
  await beforeRun(f.ctx);
  await save(f.path, { ...f.mapping, changed: true });
  await assert.rejects(beforeRun(f.ctx), /Mapping changed/);
});

test('adopts unchanged reviewed tests only after a real successful run', async t => {
  const f = await fixture(t);
  const text = "import test from 'node:test'; import assert from 'node:assert/strict'; test('witness', () => assert.equal(process.env.PSFLOW_ADOPTION_FAIL ?? '0', '0'));\n";
  const path = join(f.target, 'witness.test.mjs');
  await writeFile(path, text);
  f.mapping.tasks[0].targetFiles.push('witness.test.mjs');
  f.mapping.targetSnapshot['witness.test.mjs'] = digest(text);
  await save(f.path, f.mapping);
  await f.publish();
  const result = () => ({ success: true, extensions: { outputFiles: [] } });
  const invocation = { agent: 'test-writer', workItemId: 'pilot' };
  const parsed = { parsed: true, data: { status: 'completed' } };
  const adopted = result();
  await adoptExistingTests(f.ctx.config, f.ctx.paths, invocation, adopted, parsed);
  const report = await json(adopted.extensions.psflowAdoptedTestReport);
  assert.equal(report.adoptedExistingTests[0].sha256, digest(text));
  assert.equal(report.adoptedExistingTests[0].exitCode, 0);
  await writeFile(path, `${text}\n// unreviewed change\n`);
  await assert.rejects(adoptExistingTests(f.ctx.config, f.ctx.paths, invocation, result(), parsed), /Changed test cannot be adopted/);
  await writeFile(path, text);
  process.env.PSFLOW_ADOPTION_FAIL = '1';
  try {
    await assert.rejects(adoptExistingTests(f.ctx.config, f.ctx.paths, invocation, result(), parsed), /Command failed/);
  } finally { delete process.env.PSFLOW_ADOPTION_FAIL; }
});

test('completed-task resume rejects changed accepted outputs', async t => {
  const f = await fixture(t);
  await f.publish();
  await new FileTargetContext(f.ctx).build();
  await f.ctx.checkpoint.completeTasks([{ taskId: 'pilot' }]);
  await beforeRun(f.ctx);
  await writeFile(join(f.target, 'Boundary.purs'), 'module Boundary where\nchanged = true\n');
  await assert.rejects(beforeRun(f.ctx), /Completed task output changed/);
});
