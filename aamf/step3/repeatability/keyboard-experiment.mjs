// Diagnostic runner only. Uses the official scenario, port, capture and consistency check.
// One controlled variable per mode; this file does not change gate behavior.
import { chromium } from '@playwright/test';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { routeSpace } from '../../../parity/driver/registry.mjs';
import { buildCorpus } from '../../../parity/system/corpus/index.mjs';
import { runScenario } from '../../../parity/system/harness/scenario.mjs';
import { createPagePort } from '../../../parity/system/harness/port.mjs';
import { settleDom } from '../../../parity/system/harness/settle.mjs';
import { checkSelfConsistency } from '../../../parity/system/compare/consistency.mjs';
import { serveDirectory } from '../../../parity/system/net/server.mjs';
const [mode = 'baseline', rounds = '3'] = process.argv.slice(2);
if (!['baseline','key-frame','after-click'].includes(mode)) throw Error('unknown experiment');
const snapshot = JSON.parse(readFileSync(new URL('./validation-snapshot.json', import.meta.url)));
const {fixtures, components} = routeSpace(snapshot.mirror);
const scenario = buildCorpus(fixtures, components).find(s => s.id === 'arrow-key-selected-node');
const rules = JSON.parse(readFileSync(new URL('./comparison/normalization.json', import.meta.url))).rules;
const server = await serveDirectory(snapshot.mirror);
const browser = await chromium.launch({headless:true});
const results = [];
const directory = new URL(`./keyboard-${mode}/`, import.meta.url); mkdirSync(directory,{recursive:true});
try {
 const context = await browser.newContext({baseURL:server.origin,viewport:{width:1280,height:720}});
 const page = await context.newPage();
 for(let round=1;round<=Number(rounds);round++) {
  const traces = [];
  for(const capture of [1,2]) {
   const port = createPagePort(page);
   if(mode === 'key-frame') {
    const keyboard = port.keyboard;
    port.keyboard = async (...args) => { await keyboard(...args); await port.tick(); };
   }
   if(mode === 'after-click') {
    const mouse = port.mouse;
    port.mouse = async (action, ...args) => { await mouse(action,...args); if(action === 'up') await settleDom(port,'.react-flow'); };
   }
   const trace = await runScenario(page, scenario, {side:'upstream',capture,baseline:'12.11.0',port});
   traces.push(trace); writeFileSync(new URL(`round${round}.capture${capture}.json`,directory),JSON.stringify(trace,null,2)+'\n');
  }
  const consistency = checkSelfConsistency(...traces,{rules});
  results.push({round,...consistency});
  console.log(JSON.stringify({mode,round,consistent:consistency.consistent,differences:consistency.differences.map(d=>({kind:d.kind,path:d.path}))}));
 }
 await context.close();
} finally { await browser.close(); await server.close(); }
writeFileSync(new URL('results.json',directory),JSON.stringify(results,null,2)+'\n');
process.exitCode = results.every(r=>r.consistent) ? 0 : 1;
