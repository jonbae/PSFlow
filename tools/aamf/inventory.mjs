// Recreate plan Step 1 from a committed target and the current vendored baseline.
// Only internal phases 0/1 run. No runtime adapter or migration agent is enabled.
import assert from 'node:assert/strict';
import { spawn, execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { cp, lstat, mkdir, open, readFile, readdir, realpath, rm, writeFile } from 'node:fs/promises';
import { delimiter, dirname, isAbsolute, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { assertVendoredVersions, baselinePins } from '../../.github/scripts/vendor-baseline.mjs';

const repo = fileURLToPath(new URL('../../', import.meta.url));
const [workspaceArg, artifactsArg, projectName] = process.argv.slice(2);
assert.ok(process.argv.length === 5 && workspaceArg && artifactsArg && /^[a-z0-9-]+$/.test(projectName),
  'Usage: node tools/aamf/inventory.mjs <new workspace> <new artifact directory> <unique project name>');
const [nodeMajor, nodeMinor] = process.versions.node.split('.').map(Number);
assert.ok(nodeMajor > 22 || (nodeMajor === 22 && nodeMinor >= 18), 'Use Node >=22.18');
const aamfCommit = '7dc475d81ef9796b5b90f57a29475eaafa375753';
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const json = async path => JSON.parse(await readFile(path, 'utf8'));
const save = (path, value) => writeFile(path, `${JSON.stringify(value, null, 2)}\n`);
const inside = (parent, child) => {
  const path = relative(parent, child);
  return path === '' || (!isAbsolute(path) && path !== '..' && !path.startsWith('../'));
};
async function absent(path) {
  try { await lstat(path); } catch (error) { if (error.code === 'ENOENT') return; throw error; }
  throw Error(`Refusing to overwrite existing path: ${path}`);
}
// Resolve existing ancestors too, so a symlink cannot put state in the checkout.
async function physical(path) {
  try { return await realpath(path); } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    return join(await physical(dirname(path)), relative(dirname(path), path));
  }
}
const workspace = await physical(resolve(workspaceArg));
const artifacts = await physical(resolve(artifactsArg));
assert.ok(!inside(await realpath(repo), workspace), 'Workspace must be outside the PSFlow checkout');
assert.ok(!inside(workspace, artifacts) && !inside(artifacts, workspace), 'Workspace and artifacts must be separate');
await absent(workspace);
await absent(artifacts);
const pins = baselinePins(await json(join(repo, 'package.json')));
assertVendoredVersions(join(repo, 'xyflow'), pins);
const psflowCommit = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: repo, encoding: 'utf8' }).trim();
const committedPins = baselinePins(JSON.parse(execFileSync('git', ['show', 'HEAD:package.json'], { cwd: repo, encoding: 'utf8' })));
assert.deepEqual(pins, committedPins, 'Commit the candidate baseline pins before inventorying its target');
await absent(join(repo, 'xyflow/tsconfig.json'));

const source = join(workspace, 'source/xyflow');
const target = join(workspace, 'target/PSFlow');
const aamf = join(workspace, 'AAMF');
await mkdir(workspace); // the caller supplies an existing parent; never reuse state
await mkdir(dirname(source));
await mkdir(target, { recursive: true });
await cp(join(repo, 'xyflow'), source, {
  recursive: true,
  filter: path => !['.git', 'node_modules', '.DS_Store'].includes(path.split(/[\\/]/).at(-1)),
});
execFileSync('git', ['archive', '--format=tar', '-o', join(workspace, 'target.tar'), psflowCommit], { cwd: repo });
execFileSync('tar', ['-xf', join(workspace, 'target.tar'), '-C', target]);
await rm(join(workspace, 'target.tar'));

// Keep the exact snapshot protocol used by inspect-step1.mjs.
async function snapshot(root) {
  const files = [];
  async function walk(dir) {
    for (const entry of await readdir(dir, { withFileTypes: true })) {
      if (['node_modules', '.git', '.DS_Store'].includes(entry.name)) continue;
      const path = join(dir, entry.name);
      if (entry.isDirectory()) await walk(path);
      else if (entry.isFile()) files.push({ path: relative(root, path), sha256: hash(await readFile(path)) });
    }
  }
  await walk(root);
  return files.sort((a, b) => a.path.localeCompare(b.path));
}
const sourceBefore = await snapshot(source);
assert.ok(!sourceBefore.some(f => /^packages\/(react|system)\/src\/.*\.(js|jsx|mjs|cjs)$/.test(f.path)),
  'New JavaScript source requires an explicit scope/indexer review before using this TypeScript recipe');
await save(join(workspace, 'source-before.json'), sourceBefore);
await save(join(workspace, 'target-before.json'), await snapshot(target));

const includePatterns = ['packages/system/src/**/*.ts', 'packages/system/src/**/*.tsx',
  'packages/react/src/**/*.ts', 'packages/react/src/**/*.tsx'];
await save(join(source, 'tsconfig.json'), {
  compilerOptions: {
    target: 'ESNext', module: 'ESNext', moduleResolution: 'bundler', jsx: 'react-jsx',
    lib: ['DOM', 'ESNext'], strict: true, esModuleInterop: true, skipLibCheck: true, noEmit: true,
    baseUrl: source, paths: {
      '@xyflow/system': [join(source, 'packages/system/src/index.ts')],
      '@xyflow/react': [join(source, 'packages/react/src/index.ts')],
    },
  },
  include: includePatterns, exclude: ['node_modules', '**/*.test.ts', '**/*.test.tsx', '**/*.spec.ts', '**/*.spec.tsx'],
});
const config = {
  projectName,
  source: { path: source, language: 'typescript', languages: ['typescript'], includePatterns,
    excludePatterns: ['node_modules', '.git', 'dist', 'build', '**/*.test.ts', '**/*.test.tsx', '**/*.spec.ts', '**/*.spec.tsx'] },
  target: { language: 'purescript', outputPath: target },
  options: {
    maxParallelAgents: 1, git: { enabled: false, autoInit: false, commitPerTask: false },
    kbIndex: { execution: { allowSubprocessExecution: true }, lsp: { enabled: false }, embeddings: { enabled: false } },
  },
  agentBackend: { runtime: 'claude-code', cliCommand: 'claude' },
  guidance: ['Inventory only. Stop after internal phase 1; do not scaffold or migrate.',
    'Existing PureScript modules are the destination; generated .purescript paths are provisional.',
    'Read PORTING.md, CONTEXT.md and README.md before any later reconciliation.'],
};
await save(join(workspace, 'analysis.json'), config);
const environment = { ...process.env, PSFLOW_AAMF_ROOT: aamf,
  PATH: [dirname(process.execPath), join(aamf, 'node_modules/.bin'), process.env.PATH].join(delimiter) };
// An inherited Step 2 opt-in would replace the source graph with the old pilot.
delete environment.PSFLOW_AAMF_RECONCILIATION;
async function run(command, args, cwd, log) {
  console.log(`${log}: ${command} ${args.join(' ')}`);
  const output = await open(join(workspace, log), 'w');
  try {
    const code = await new Promise((resolveCode, reject) => {
      const child = spawn(command, args, { cwd, env: environment, stdio: ['ignore', output.fd, output.fd] });
      child.on('error', reject);
      child.on('close', code => resolveCode(code ?? 1));
    });
    return code;
  } finally { await output.close(); }
}
async function checked(command, args, cwd, log) {
  assert.equal(await run(command, args, cwd, log), 0, `Command failed; inspect ${join(workspace, log)}`);
}
await checked('git', ['clone', '--no-checkout', 'https://github.com/jafreck/AAMF.git', aamf], workspace, 'clone.log');
await checked('git', ['checkout', '--detach', aamfCommit], aamf, 'checkout.log');
await checked('npm', ['ci'], aamf, 'aamf-install.log');
await checked('npm', ['run', 'build'], aamf, 'aamf-build.log');
await checked(process.execPath, [join(repo, 'tools/aamf/apply-phase0-fixes.mjs'), aamf], repo, 'compatibility-patches.json');
await checked(process.execPath, ['--test', join(repo, 'tools/aamf/phase0.test.mjs')], repo, 'tests.log');
const packageManager = (await json(join(source, 'package.json'))).packageManager;
assert.match(packageManager, /^pnpm@\d+\.\d+\.\d+$/, 'Review the new source package manager and frozen dependency installation');
await checked('npx', ['--yes', packageManager, '--filter', '@xyflow/react...', '--filter', '@xyflow/system...',
  'install', '--frozen-lockfile', '--ignore-scripts', '--store-dir', join(workspace, 'pnpm-store')], source, 'source-install.log');

const command = [process.execPath, join(aamf, 'dist/index.js'), 'migrate', '-c', join(workspace, 'analysis.json'), '--phase', '1'];
const started = Date.now();
const exitCode = await run(command[0], command.slice(1), workspace, 'migrate.log');
const statusExitCode = await run(process.execPath,
  [join(aamf, 'dist/index.js'), 'status', '-c', join(workspace, 'analysis.json')], workspace, 'status.txt');
await save(join(workspace, 'run-result.json'), {
  startedAt: new Date(started).toISOString(), elapsedSeconds: (Date.now() - started) / 1000,
  command, exitCode, statusExitCode, psflowCommit, aamfCommit, nodeVersion: process.version,
  packages: pins, sourcePackageManager: packageManager,
  analysisConfigSha256: hash(await readFile(join(workspace, 'analysis.json'))),
  analysisTsconfigSha256: hash(await readFile(join(source, 'tsconfig.json'))),
  inventoryToolSha256: hash(await readFile(fileURLToPath(import.meta.url))),
});
assert.equal(exitCode, 0, `Inventory failed; retain ${workspace} and read migrate.log`);
assert.equal(statusExitCode, 0, 'Status failed; read status.txt');
await checked(process.execPath, [join(repo, 'tools/aamf/inspect-step1.mjs'), workspace, artifacts], repo, 'inspection.log');
// Archive raw state before judging new import exceptions; a failed review is still evidence.
await checked('tar', ['-czf', join(artifacts, 'runtime.tar.gz'), '-C', workspace,
  '.aamf', 'source-before.json', 'target-before.json', 'run-result.json', 'step1-index-health.json'], workspace, 'archive.log');
for (const name of ['clone.log', 'checkout.log', 'aamf-install.log', 'aamf-build.log', 'source-install.log', 'inspection.log']) {
  await cp(join(workspace, name), join(artifacts, name));
}
const checksums = [];
for (const name of (await readdir(artifacts)).sort()) checksums.push(`${hash(await readFile(join(artifacts, name)))}  ${name}`);
await writeFile(join(artifacts, 'SHA256SUMS'), `${checksums.join('\n')}\n`);
const imports = await json(join(artifacts, 'imports.json'));
assert.deepEqual(imports.unresolved, [], 'Review unresolved/nonliteral imports; inventory is not accepted yet');
assert.deepEqual(imports.outsideScope, [], 'Review imports outside the selected scope; inventory is not accepted yet');
console.log(JSON.stringify({ workspace, artifacts, projectName, packages: pins,
  review: await json(join(artifacts, 'review.json')) }, null, 2));
