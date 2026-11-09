// Materialize the reviewed Markdown mapping against the certified inventory.
// This is adapter data, not a stock AAMF configuration extension.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { digest, json, save, snapshot, validateMapping } from './psflow-integration.mjs';

const root = resolve(process.argv[2] ?? '.');
const destination = resolve(process.argv[3] ?? 'aamf/step2/reconciliation.json');
const { manifest } = await import(pathToFileURL(join(root, 'src/Boundary.js')));
assert.ok(manifest.passthrough.includes('getViewportForBounds'),
  'W01 is already crossed; retain it as context instead of creating another write task');
const mapText = await readFile(join(root, 'AAMF_STEP2_MAPPING.md'), 'utf8');
const results = await readFile(join(root, 'AAMF_STEP2_RESULTS.md'), 'utf8');
const inventory = await json(join(root, 'aamf/step1/inventory.json'));
const imports = (await json(join(root, 'aamf/step1/imports.json'))).records;
const profiles = new Map();
for (const line of mapText.split('\n').filter(l => /^\| E\d+ \|/.test(l))) {
  const fields = line.split(' | ').map(p => p.replace(/^\| | \|$/g, ''));
  profiles.set(fields[0], { disposition: fields[1], evidence: fields[2], work: fields[3] });
}
const units = [];
const rows = mapText.split('## Complete unit map')[1].split('## Recorded caller context')[0];
for (const line of rows.split('\n').filter(l => /^\| \[(react|system)\//.test(l))) {
  const fields = line.split(' | ');
  const source = fields[0].match(/\]\(xyflow\/(.*?)\)/)[1];
  const indexed = inventory.find(u => u.path === source);
  assert.ok(indexed, `Not in certified inventory: ${source}`);
  const links = text => [...text.matchAll(/\]\((src\/[^)]+)\)/g)].map(m => m[1]);
  const profile = fields.at(-1).replace(/ \|$/, '');
  const callerRow = mapText.split('\n').find(l => l.startsWith(`| \`${source.replace(/^packages\//, '')}\` |`));
  units.push({ source, package: source.split('/')[1], sha256: indexed.sha256, accounting: indexed.accounting,
    symbols: [...fields[0].matchAll(/`([^`]+)`/g)].map(m => m[1]),
    targets: links(fields[1]), converters: links(fields[2]),
    callers: callerRow?.split(' | ').slice(1).join(' | '),
    imports: imports.filter(r => r.from === source),
    importedBy: imports.filter(r => r.to === source), profile, ...profiles.get(profile),
  });
}
assert.equal(units.length, 171);
const task = {
  id: 'psflow-w01-viewport', name: 'Cross getViewportForBounds at the JS entry',
  sourceFiles: ['packages/system/src/utils/general.ts'],
  sourceReferenceFiles: ['packages/system/src/utils/graph.ts', 'packages/react/src/store/initialState.ts',
    'packages/react/src/hooks/useViewportHelper.ts'],
  referenceFiles: ['src/System/Utils/General.purs', 'src/System/Types/Geometry.purs',
    'src/System/Types/Connection.purs', 'src/Boundary/Elements.purs', 'src/Boundary/FitView.purs',
    'src/Boundary/FitView.js', 'src/Boundary/Untagged.purs', 'src/Boundary/Undefined.purs',
    'index.js', 'PORTING.md', 'CONTEXT.md', 'README.md', 'test/Test/Parity/Geometry.purs'],
  targetFiles: ['src/Boundary/Utils.purs', 'src/Boundary/Utils.js', 'src/Boundary.purs', 'src/Boundary.js',
    'parity/boundary/viewport.test.mjs', 'parity/surface/allowlist.json',
    'parity/surface/upstream.json', 'parity/surface/psflow.json', 'parity/surface/upstream-bundle.mjs',
    'parity/surface/report.md'],
  dependencies: [],
  description: 'Implement only W01. Retain System.Utils.General geometry. Accept six arguments in a JS call and return a JS viewport. Padding has NO default: undefined means zero; null throws upstream TypeError. Match padding parsing, malformed-value console errors and return/error behavior against the provided JS-entry regression. Runtime FFI is limited to JS property access, type tests, parseFloat and native error semantics. Keep all geometry math in PureScript. Move only this export into crossed ownership, remove exactly its two surface exceptions, and keep stage 4 and seven raw exports. Existing viewport.test.mjs is the red regression and must remain intact; do not weaken it. No other work or scaffold is authorized.',
  acceptanceCriteria: ['node --test parity/boundary/viewport.test.mjs passes all cases against pinned @xyflow/system',
    'spago build succeeds; npm run parity:surface then spago test succeed',
    'npm run parity:boundary succeeds',
    'Only declared outputs change; core geometry, project setup, entry point, tests and comparator rules are preserved',
    'Only viewport arity and call-convention exceptions are retired; stage 4 has seven passthrough exports'],
};
const mapping = {
  version: 1, existingProject: true, targetContext: 'files',
  aamfCommit: '7dc475d81ef9796b5b90f57a29475eaafa375753',
  psflowCommit: execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim(),
  packages: { react: '12.11.0', system: '0.0.77' },
  review: { mappingSha256: digest(mapText), workContractsSha256: digest(results),
    inventorySha256: digest(await readFile(join(root, 'aamf/step1/inventory.json'))) },
  units, tasks: [task],
  // The artifact is outside the copied runtime target. Omit its own output
  // directory so regeneration does not give the manifest a recursive digest.
  targetSnapshot: Object.fromEntries(Object.entries(await snapshot(root)).filter(([p]) => !p.startsWith('aamf/step2/'))),
};
await validateMapping(mapping, join(root, 'xyflow'), root);
await save(destination, mapping);
console.log(JSON.stringify({ units: units.length, tasks: mapping.tasks.map(t => t.id), output: destination, sha256: digest(await readFile(destination)) }));
