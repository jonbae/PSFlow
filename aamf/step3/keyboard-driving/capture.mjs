// Bounded W11 experiment. Only the browser port varies; runtime, actions,
// observations and the full official comparator are identical in both modes.
import { chromium } from '@playwright/test';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { routeSpace } from '../../../parity/driver/registry.mjs';
import { buildCorpus } from '../../../parity/system/corpus/index.mjs';
import { runScenario } from '../../../parity/system/harness/scenario.mjs';
import { compareRun } from '../../../parity/system/compare/run.mjs';
import { serveDirectory } from '../../../parity/system/net/server.mjs';
const [phase, count = '5', ...ids] = process.argv.slice(2);
if (!['before', 'candidate', 'repeat', 'controls'].includes(phase)) throw Error('unknown phase');
const here = new URL('./', import.meta.url);
const read = name => JSON.parse(readFileSync(new URL(name, here)));
const { mirror } = read('validation-snapshot.json');
const { createPagePort } = await import(pathToFileURL(resolve(mirror, 'parity/system/harness', phase === 'before' ? 'port.before.mjs' : 'port.mjs')));
const { fixtures, components } = routeSpace(mirror);
const corpus = buildCorpus(fixtures, components);
const options = Object.fromEntries([['rules','normalization','rules'],['regions','regions','regions'],['weakenings','weakenings','weakenings']].map(([key,file,field]) => [key, JSON.parse(readFileSync(resolve(mirror, `parity/system/${file}.json`)))[field]]));
const server = await serveDirectory(mirror);
const browser = await chromium.launch();
const rows = [];
try {
 for (const id of ids) {
  const scenario = corpus.find(s => s.id === id);
  if (!scenario) throw Error(`unknown scenario ${id}`);
  for (let round = 1; round <= Number(count); round++) {
   const directory = new URL(`${phase}/round${round}/`, here); mkdirSync(directory, { recursive: true });
   const traces = [];
   for (const side of ['upstream', 'psflow']) {
    const context = await browser.newContext({ baseURL: server.origin, viewport: {width:1280,height:720} });
    const page = await context.newPage();
    try {
     for (const capture of [1,2]) {
      const trace = await runScenario(page, scenario, { side, capture, baseline:'12.11.0', port:createPagePort(page) });
      traces.push(trace);
      writeFileSync(new URL(`${id}.${side}.capture${capture}.json`, directory), JSON.stringify(trace,null,2)+'\n');
     }
    } finally { await context.close(); }
   }
   const result = compareRun(traces, options);
   const interpretable = result.consistency.every(s => s.consistent) && !result.failures.some(f => f.class === 'driving-divergence');
   const row = {scenario:id, round, interpretable, fullGatePassed:result.ok, consistency:result.consistency, failureClasses:[...new Set(result.failures.map(f=>f.class))], differences:interpretable?result.comparison.unclaimed:null};
   rows.push(row);
   writeFileSync(new URL(`${phase}-summary.json`, here), JSON.stringify(rows,null,2)+'\n');
   console.log(JSON.stringify({phase,scenario:id,round,interpretable,fullGatePassed:result.ok,sides:result.consistency.map(s=>({side:s.side,consistent:s.consistent,differences:s.differences.length})),unclaimed:row.differences?.length??null}));
  }
 }
} finally { await browser.close(); await server.close(); }
process.exitCode = rows.every(r => r.interpretable) ? 0 : 1;
