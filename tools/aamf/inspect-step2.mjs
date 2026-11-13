// Inspect the completed isolated pilot, without launching any migration phase.
import assert from 'node:assert/strict';
import { copyFile, mkdir, readFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { digest, json, save, snapshot, validateMapping } from './psflow-integration.mjs';

const workspace = resolve(process.argv[2]);
const output = resolve(process.argv[3] ?? 'aamf/step2');
const config = await json(join(workspace, 'pilot.json'));
const mapping = await json(join(workspace, 'reconciliation.json'));
await validateMapping(mapping, config.source.path, config.target.outputPath);
const runtime = join(workspace, '.aamf/migration', config.projectName);
const planning = join(runtime, 'artifacts/planning');
const checkpoint = await json(join(runtime, 'state/checkpoint.json'));
const tasks = await json(join(planning, 'tasks-merged.json'));
const graph = await json(join(planning, 'psflow-reconciliation.json'));
assert.equal(graph.mappingDigest, digest(await readFile(join(workspace, 'reconciliation.json'))));
assert.deepEqual(tasks.map(t => t.id), ['psflow-w01-viewport']);
assert.deepEqual(checkpoint.completedTasks, ['psflow-w01-viewport']);
assert.deepEqual(checkpoint.completedPhases, [0, 1, 2, 3, 4]);
for (const [container, key] of [['outputs', 'task-graph-construction'], ['executionOutputs', 'aamf-migration/task-graph-construction']]) {
  const structured = checkpoint.__flowCheckpoint[container][key];
  assert.deepEqual(structured.tasks, tasks);
  assert.deepEqual(structured.sccs, graph.graph.sccs);
  assert.deepEqual(structured.compilationUnits, graph.graph.compilationUnits);
}
const current = await snapshot(config.target.outputPath);
const changed = [...new Set([...Object.keys(mapping.targetSnapshot), ...Object.keys(current)])]
  .filter(path => mapping.targetSnapshot[path] !== current[path]).sort();
assert.deepEqual(changed.filter(path => !mapping.tasks[0].targetFiles.includes(path)), []);
const { manifest } = await import(pathToFileURL(join(config.target.outputPath, 'src/Boundary.js')));
assert.equal(manifest.stage, 4);
assert.equal(manifest.passthrough.length, 7);
assert.ok(!manifest.passthrough.includes('getViewportForBounds'));
const allowlist = await json(join(config.target.outputPath, 'parity/surface/allowlist.json'));
assert.ok(!Object.hasOwn(allowlist.shapes, 'getViewportForBounds'));
assert.ok(!Object.hasOwn(allowlist.behavior.functions, 'getViewportForBounds.call-convention'));
const targetContext = await json(join(planning, 'psflow-target-files.json'));
assert.equal(targetContext.mode, 'files');
assert.equal(targetContext.symbolCoverage, null);
for (const file of targetContext.files) {
  assert.equal(file.sha256, digest(await readFile(join(config.target.outputPath, file.path))), `Stale target file context: ${file.path}`);
}
await assert.rejects(readFile(join(runtime, 'kb-target.db')), error => error.code === 'ENOENT');
const adoption = await json(join(planning, 'psflow-adopted-tests.json'));
assert.equal(adoption.mappingDigest, graph.mappingDigest);
assert.equal(adoption.taskId, 'psflow-w01-viewport');
for (const test of adoption.adoptedExistingTests) {
  assert.equal(test.exitCode, 0);
  assert.equal(test.sha256, mapping.targetSnapshot[test.path]);
  assert.equal(test.sha256, digest(await readFile(join(config.target.outputPath, test.path))));
}
const sourceGraph = await json(join(planning, 'psflow-source-context.json'));
assert.equal(sourceGraph.tasks.length, 120);
assert.equal(sourceGraph.sccs.length, 4);
const reused = mapping.tasks[0].referenceFiles;
for (const path of reused) assert.equal(current[path], mapping.targetSnapshot[path], `Reused target changed: ${path}`);
await mkdir(output, { recursive: true });
for (const file of ['reconciliation.json', 'prepare-run.log', 'pilot-run.log', 'pre-pilot-checkpoint.json']) {
  await copyFile(join(workspace, file), join(output, file));
}
for (const file of ['psflow-reconciliation.json', 'psflow-phase4-discovery.json', 'psflow-target-files.json', 'psflow-adopted-tests.json']) {
  await copyFile(join(planning, file), join(output, file));
}
await copyFile(join(runtime, 'state/checkpoint.json'), join(output, 'checkpoint.json'));
await save(join(output, 'review.json'), {
  sourceFiles: mapping.units.length, sourceHashesMatch: true,
  psflowCommit: mapping.psflowCommit, aamfCommit: mapping.aamfCommit, packages: mapping.packages,
  mappingDigest: graph.mappingDigest,
  selectedTasks: tasks.map(t => t.id), completedTasks: checkpoint.completedTasks,
  completedPhases: checkpoint.completedPhases, resumeCount: checkpoint.resumeCount,
  sourceContext: { tasks: sourceGraph.tasks.length, cyclicGroups: sourceGraph.sccs.length },
  targetContext: { mode: 'files', symbolCoverage: null, files: targetContext.files.length },
  changed, reusedTargetsUnchanged: true, scaffoldChanged: false,
  boundary: { stage: manifest.stage, passthrough: manifest.passthrough },
  tokenUsage: checkpoint.tokenUsage,
});
console.log(JSON.stringify({ changed, completedPhases: checkpoint.completedPhases, output }, null, 2));
