// Focused receipts use the real net's capture and comparison, with its fixed
// policy. The final acceptance run remains parity/system/net.mjs's full wave.
import { chromium } from '@playwright/test';
import { spawnSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { routeSpace } from '../../../parity/driver/registry.mjs';
import { buildCorpus } from '../../../parity/system/corpus/index.mjs';
import { runScenario } from '../../../parity/system/harness/scenario.mjs';
import { serveDirectory } from '../../../parity/system/net/server.mjs';
import { writeTrace, readRun } from '../../../parity/system/net/traces.mjs';
import { compareRun } from '../../../parity/system/compare/run.mjs';
import { renderRunReport } from '../../../parity/system/compare/report.mjs';

const root = fileURLToPath(new URL('../../../', import.meta.url));
const args = process.argv.slice(2);
const out = resolve(root, args.shift() ?? 'aamf/step4/order-8/focused');
// The canonical store accepts trace JSON only. Keep focused-run metadata and
// Markdown receipts beside the task evidence when refreshing that store.
const receipts = out === resolve(root, 'parity/system/traces')
  ? resolve(root, 'aamf/step4/order-8/final') : out;
const { fixtures, components } = routeSpace(root);
const corpus = buildCorpus(fixtures, components);
const selected = args.length ? args.map(id => {
  const found = corpus.find(s => s.id === id);
  if (!found) throw Error(`Unknown scenario: ${id}`);
  return found;
}) : corpus.filter(s => s.id.startsWith('debt-'));
for (const side of ['psflow', 'upstream']) {
  const built = spawnSync(process.execPath, ['parity/driver/build.mjs', '--side', side], { cwd: root, stdio: 'inherit' });
  if (built.status) process.exit(built.status);
}
const json = path => JSON.parse(readFileSync(resolve(root, path)));
const policy = {
  rules: json('parity/system/normalization.json').rules,
  regions: json('parity/system/regions.json').regions,
  weakenings: json('parity/system/weakenings.json').weakenings,
};
const baseline = json('xyflow/packages/react/package.json').version;
mkdirSync(out, { recursive: true });
mkdirSync(receipts, { recursive: true });
const server = await serveDirectory(root);
const browser = await chromium.launch();
const results = [];
try {
  for (const scenario of selected) {
    try {
      for (const side of ['psflow', 'upstream']) {
        const context = await browser.newContext({ baseURL: server.origin, viewport: { width: 1280, height: 720 } });
        try {
          const page = await context.newPage();
          for (const capture of [1, 2]) writeTrace(out, await runScenario(page, scenario, { side, capture, baseline }));
        } finally { await context.close(); }
      }
      const run = compareRun(readRun(out, scenario.id), policy);
      writeFileSync(resolve(receipts, `${scenario.id}.md`), renderRunReport(run));
      results.push({ scenario: scenario.id, ok: run.ok, failures: run.failures });
      console.log(`${scenario.id}: ${run.ok ? 'PASS' : 'FAIL'} ${run.failures.map(f => f.class).join(', ')}`);
    } catch (error) {
      results.push({ scenario: scenario.id, ok: false, error: String(error.stack ?? error) });
      console.log(`${scenario.id}: ERROR ${error.message}`);
    }
    writeFileSync(resolve(receipts, 'results.json'), JSON.stringify(results, null, 2) + '\n');
  }
} finally { await browser.close(); await server.close(); }
if (results.some(r => !r.ok)) process.exitCode = 1;
