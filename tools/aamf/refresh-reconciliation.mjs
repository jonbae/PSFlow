// Refresh reviewed dispositions, never the historical AAMF execution state.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile, readdir, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { canonical, digest, json } from './psflow-integration.mjs';

const pilotPath = 'aamf/step2/pilot-reconciliation.json';
const pilotDigest = 'c3f6e1349865e8289755a588a8b5f5e6a0b4f371f48d28e0b7a2a24c649c1539';
const reviewPath = 'aamf/step4/order-11/profiles.json';
const mappingPath = 'AAMF_STEP2_MAPPING.md';
const outputPath = 'aamf/step2/reconciliation.json';
const inventoryPath = 'aamf/step1/inventory.json';
const importsPath = 'aamf/step1/imports.json';
const encode = value => `${JSON.stringify(value, null, 2)}\n`;
const slug = heading => heading.toLowerCase().replace(/[^\p{L}\p{N}_\- ]/gu, '').replace(/ /g, '-');

async function filesUnder(root, dir) {
  const files = [];
  for (const entry of await readdir(join(root, dir), { withFileTypes: true })) {
    const path = `${dir}/${entry.name}`;
    if (entry.isDirectory()) files.push(...await filesUnder(root, path));
    else if (entry.isFile()) files.push(path);
  }
  return files.sort();
}

export async function renderReconciliation(root) {
  const pilotBytes = await readFile(join(root, pilotPath));
  assert.equal(digest(pilotBytes), pilotDigest, 'Historical pilot input changed');
  const pilot = JSON.parse(pilotBytes);
  const review = await json(join(root, reviewPath));
  assert.match(review.psflowCommit, /^[0-9a-f]{40}$/);
  execFileSync('git', ['merge-base', '--is-ancestor', review.psflowCommit, 'HEAD'], { cwd: root });
  const inventory = await json(join(root, inventoryPath));
  const imports = (await json(join(root, importsPath))).records;
  const sourcePaths = pilot.units.map(u => u.source).sort();
  assert.equal(sourcePaths.length, 171);
  assert.equal(new Set(sourcePaths).size, 171);
  assert.deepEqual(inventory.map(u => u.path).sort(), sourcePaths, 'Certified scope changed');
  const scoped = [];
  const pkg = await json(join(root, 'package.json'));
  for (const [name, version] of Object.entries(pilot.packages)) {
    assert.equal(pkg.devDependencies[`@xyflow/${name}`], version);
    assert.equal((await json(join(root, 'xyflow/packages', name, 'package.json'))).version, version);
    scoped.push(...(await filesUnder(root, `xyflow/packages/${name}/src`))
      .filter(p => /\.tsx?$/.test(p) && !/\.(test|spec)\.ts$/.test(p)).map(p => p.slice(7)));
  }
  assert.deepEqual(scoped.sort(), sourcePaths, 'Vendored source scope changed');
  assert.deepEqual(Object.keys(review.profiles).sort(), [...new Set(pilot.units.map(u => u.profile))].sort());
  for (const source of Object.keys(review.unitUpdates)) assert.ok(sourcePaths.includes(source), `Unknown unit override: ${source}`);
  for (const issue of review.remainingIssues) {
    assert.match(issue.issue, /^https:\/\/github\.com\/jonbae\/PSFlow\/issues\/\d+$/);
    assert.ok(issue.reason && issue.sources.length && issue.evidenceRefs.length);
    for (const source of issue.sources) assert.ok(sourcePaths.includes(source), `Unknown issue unit: ${source}`);
  }

  const targetHashes = {};
  const evidenceHashes = {};
  async function hashPath(path, hashes) {
    if (Object.hasOwn(hashes, path)) return hashes[path];
    hashes[path] = digest(await readFile(await canonical(root, path)));
    return hashes[path];
  }
  // Resolve file references and Markdown anchors; a plausible-looking link is
  // not enough to support a completed profile.
  const validatedRefs = new Set();
  async function validateRef(ref) {
    if (validatedRefs.has(ref)) return;
    const [path, anchor] = ref.split('#');
    await hashPath(path, evidenceHashes);
    if (anchor) {
      const text = await readFile(join(root, path), 'utf8');
      const headings = [...text.matchAll(/^#{1,6} (.+)$/gm)].map(m => slug(m[1]));
      assert.ok(headings.includes(anchor), `Missing evidence anchor: ${ref}`);
    }
    validatedRefs.add(ref);
  }
  const srcFiles = await filesUnder(root, 'src');
  const srcSet = new Set(srcFiles);
  const modules = new Map();
  for (const path of srcFiles.filter(p => p.endsWith('.purs'))) {
    const text = await readFile(join(root, path), 'utf8');
    const module = text.match(/^module ([\w.]+)/m)?.[1];
    assert.ok(module, `Missing module header: ${path}`);
    assert.ok(!modules.has(module), `Duplicate module: ${module}`);
    modules.set(module, { path, text });
  }
  const units = [];
  for (const original of pilot.units) {
    const profile = review.profiles[original.profile];
    assert.ok(['Reuse', 'Accepted difference'].includes(profile.disposition), `Unowned work: ${original.profile}`);
    assert.ok(profile.evidence && profile.work && profile.evidenceRefs.length);
    assert.equal(digest(await readFile(join(root, 'xyflow', original.source))), original.sha256, `Stale source: ${original.source}`);
    assert.equal(inventory.find(u => u.path === original.source).sha256, original.sha256);
    assert.deepEqual(original.imports, imports.filter(r => r.from === original.source));
    assert.deepEqual(original.importedBy, imports.filter(r => r.to === original.source));
    const update = review.unitUpdates[original.source] ?? {};
    const targets = [...new Set([...original.targets, ...(update.targets ?? [])])];
    const converters = [...new Set([...original.converters.filter(p => p.endsWith('.purs')), ...(update.converters ?? [])])];
    assert.ok(targets.some(p => p.endsWith('.purs')), `Missing PureScript destination: ${original.source}`);
    // Recompute paired and directly imported FFI context from current modules.
    const ffi = new Set();
    for (const path of [...targets, ...converters]) {
      await hashPath(path, targetHashes);
      const module = [...modules.values()].find(m => m.path === path);
      assert.ok(module, `Missing mapped module: ${path}`);
      const candidates = [path, ...[...module.text.matchAll(/^import ([\w.]+)/gm)]
        .map(m => modules.get(m[1])?.path).filter(Boolean)];
      for (const candidate of candidates) {
        const js = candidate.replace(/\.purs$/, '.js');
        if (srcSet.has(js)) ffi.add(js);
      }
    }
    for (const path of [...ffi].sort()) { converters.push(path); await hashPath(path, targetHashes); }
    const knownIssues = review.remainingIssues.filter(i => i.sources.includes(original.source)).map(i => i.issue);
    const evidenceRefs = [...new Set([...profile.evidenceRefs,
      ...review.remainingIssues.filter(i => i.sources.includes(original.source)).flatMap(i => i.evidenceRefs)])];
    for (const ref of evidenceRefs) await validateRef(ref);
    units.push({ ...original, targets, converters, disposition: profile.disposition,
      evidence: profile.evidence, work: profile.work, evidenceRefs, knownIssues });
  }
  for (const limit of review.compatibilityLimits) for (const ref of limit.evidenceRefs) await validateRef(ref);
  // Include the whole runtime, not only the mapped modules, so a dependency
  // change cannot leave a current-code review silently passing --check.
  for (const path of ['index.js', 'src/Boundary.js', ...srcFiles]) await hashPath(path, targetHashes);

  const currentMarkdown = await readFile(join(root, mappingPath), 'utf8');
  const bodyStart = currentMarkdown.indexOf('## Complete unit map\n');
  assert.ok(bodyStart >= 0, 'Missing unit table');
  const seen = new Set();
  const body = currentMarkdown.slice(bodyStart).split('\n').map(line => {
    if (!/^\| \[(react|system)\//.test(line)) return line;
    const fields = line.split(' | ');
    const source = fields[0].match(/\]\(xyflow\/(.*?)\)/)?.[1];
    const unit = units.find(u => u.source === source);
    assert.ok(unit && !seen.has(source), `Unknown/duplicate Markdown unit: ${source}`);
    seen.add(source);
    assert.equal(fields.at(-1).replace(/ \|$/, ''), unit.profile, `Profile mismatch: ${source}`);
    const links = text => [...text.matchAll(/\]\((src\/[^)]+)\)/g)].map(m => m[1]);
    assert.deepEqual(links(fields[1]), unit.targets, `Target mismatch: ${source}`);
    const link = path => `[${path.slice(4)}](${path})`;
    const purs = unit.converters.filter(p => p.endsWith('.purs')).map(link).join('<br>');
    const ffi = unit.converters.filter(p => p.endsWith('.js')).map(link).join(', ');
    fields[2] = [purs, ffi && `FFI: ${ffi}`].filter(Boolean).join('<br>') || '—';
    return fields.join(' | ');
  }).join('\n');
  assert.equal(seen.size, 171, 'Incomplete Markdown unit map');
  const counts = {};
  for (const unit of units) counts[unit.disposition] = (counts[unit.disposition] ?? 0) + 1;
  assert.deepEqual(counts, { Reuse: 170, 'Accepted difference': 1 });
  const profileRows = Object.entries(review.profiles).map(([id, p]) => {
    const refs = p.evidenceRefs.map(ref => `[${ref.split('#')[0]}](${ref})`).join(', ');
    return `| ${id} | ${units.filter(u => u.profile === id).length} | ${p.disposition} | ${p.evidence}<br>${refs} | ${p.work} |`;
  }).join('\n');
  const markdown = `# Source-to-target reconciliation map (Step 4 order 11)

**Current review: ${review.dateUTC}, against PSFlow \`${review.psflowCommit}\`.**
The baseline remains \`@xyflow/react\` 12.11.0 / \`@xyflow/system\` 0.0.77.
All **171** certified Step 1 units retain existing PureScript destinations:
**170 Reuse, 1 Accepted difference, 0 Add evidence, 0 Fix behavior, 0 Finish conversion**.
The 18 profiles below incorporate Steps 3 and 4 through order 10.

The [JSON review](${outputPath}) and this table are refreshed by
\`node tools/aamf/refresh-reconciliation.mjs\`; \`--check\` detects stale inputs
and output. [Reviewed profiles](${reviewPath}) provide the dispositions,
evidence links, compatibility limits and separately owned issues. The
[order 11 record](aamf/step4/order-11/README.md) explains validation.

The [original pilot input](${pilotPath}) remains byte-identical and
checksum-verified. The current JSON is version 2, review-only, with no runtime
tasks. It cannot replace the version-1 input of the completed AAMF checkpoint.
Historical W cards in [Step 2 results](AAMF_STEP2_RESULTS.md) describe the
starting gaps; their completions and later checks are linked below.

**Reuse** means retain the completed implementation and its cited evidence;
it does not assert exhaustive equivalence of every branch. The extra custom-node
mount render ([207](https://github.com/jonbae/PSFlow/issues/207)) and the later
render after in-place selection ([208](https://github.com/jonbae/PSFlow/issues/208))
remain separately owned, with affected units marked in the JSON. Four browser
cases hold issue 207's exact difference. Neither issue is silently accepted or
closed by this refresh. Store writes, untyped default-edge keys, rebuilt
uncontrolled-node handler keys and package limits retain the explicit scope in
[the declarations](distribution/gaps.mjs). The one declared coverage hole is
\`UnselectNodesAndEdgesParams\`; it is not a missing component implementation.

Source paths below are relative to \`xyflow/packages/\`, target paths to \`src/\`.
Primary ownership and certified source symbols/import consumers are retained.
Converter context adds the current store/flow-member modules, and paired and
directly imported FFI are recomputed from current imports. This remains file
context, not a claim of PureScript symbol indexing.

The caller appendix preserves **historical diagnostic** cross-file symbol-call
observations. Those observations are partial; empty rows never mean unused.
The JSON separately retains all certified import/re-export consumers.

## Disposition and evidence profiles

| Profile | Units | Disposition | Evidence / interpretation | Completed work / remaining owner |
|---|---|---|---|---|
${profileRows}

` + body;
  const sorted = object => Object.fromEntries(Object.entries(object).sort(([a], [b]) => a.localeCompare(b)));
  const mapping = {
    version: 2, purpose: 'current-review-only', existingProject: true, targetContext: 'files',
    aamfCommit: pilot.aamfCommit, psflowCommit: review.psflowCommit, packages: pilot.packages,
    review: { dateUTC: review.dateUTC, profiles: reviewPath, profilesSha256: digest(await readFile(join(root, reviewPath))),
      mappingSha256: digest(markdown), inventorySha256: digest(await readFile(join(root, inventoryPath))),
      importsSha256: digest(await readFile(join(root, importsPath))) },
    historicalPilot: { mapping: pilotPath, sha256: pilotDigest, psflowCommit: pilot.psflowCommit,
      tasks: pilot.tasks.map(t => t.id), checkpoint: 'aamf/step2/checkpoint.json' },
    counts, profiles: review.profiles, units, tasks: [],
    remainingIssues: review.remainingIssues, compatibilityLimits: review.compatibilityLimits,
    targetHashes: sorted(targetHashes), evidenceHashes: sorted(evidenceHashes),
  };
  return { [mappingPath]: markdown, [outputPath]: encode(mapping) };
}

export async function refreshReconciliation(root, check = false) {
  const rendered = await renderReconciliation(root);
  // Validate everything before either output is written.
  for (const [path, bytes] of Object.entries(rendered)) {
    if (check) assert.ok(await readFile(join(root, path), 'utf8') === bytes, `Stale reconciliation: ${path}`);
    else await writeFile(join(root, path), bytes);
  }
  return { units: 171, profiles: 18, dispositions: { Reuse: 170, 'Accepted difference': 1 }, tasks: 0, check };
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  assert.ok(process.argv.slice(2).every(arg => arg === '--check'), 'Usage: node tools/aamf/refresh-reconciliation.mjs [--check]');
  const root = fileURLToPath(new URL('../../', import.meta.url));
  console.log(JSON.stringify(await refreshReconciliation(root, process.argv.includes('--check'))));
}
