// Browser-port regressions: native input/rendering and controlled app time must
// produce the complete original trace, including every callback and its order.
import { test, expect } from '@playwright/test';
import { readFileSync, existsSync } from 'node:fs';
import { routeSpace } from '../../driver/registry.mjs';
import { buildCorpus } from '../corpus/index.mjs';
import { checkSelfConsistency } from '../compare/consistency.mjs';
import { runScenario } from './scenario.mjs';
import { createPagePort } from './port.mjs';

const {fixtures, components} = routeSpace(process.cwd());
const corpus = buildCorpus(fixtures, components);
const rules = JSON.parse(readFileSync('parity/system/normalization.json')).rules;
const baseline = JSON.parse(readFileSync('xyflow/packages/react/package.json')).version;
const cases = [
  ['drag-node-autopan', 'onNodeDragStop'],
  ['drag-node-reports-changes', 'onNodeDragStop'],
  ['wheel-zoom-from-identity-viewport', 'onMoveEnd'],
  ['ctrl-wheel-pinches-with-panonscroll', 'onMoveEnd'],
  ['pan-after-controlled-viewport-change', 'onMoveEnd'],
  ['arrow-key-selected-node', 'onNodesChange'],
];

for (const side of ['upstream', 'psflow']) {
  for (const [id, witness] of cases) {
    test(`${side} reproduces the complete ${id} trace across independent captures`, async ({page}) => {
      test.setTimeout(120_000); // Three complete captures, including VM browser tracing.
      test.skip(!existsSync(`parity/driver/dist/${side}.js`), 'bundle not built');
      const scenario = corpus.find(s => s.id === id);
      const traces = [];
      for (const capture of [1, 2, 3]) {
        const trace = await runScenario(page, scenario, {side, capture, baseline});
        expect(trace.sections.callbacks.some(c => c.name === witness)).toBe(true);
        traces.push(trace);
      }
      for (const trace of traces.slice(1)) {
        expect(checkSelfConsistency(traces[0], trace, {rules}).differences).toEqual([]);
      }
    });
  }
}

test('wheel dispatch completes its finite timeout chain before returning', async ({page}) => {
  const port = createPagePort(page);
  await port.prepareMount();
  await page.setContent(`<div style="width:500px;height:500px"></div><script>
    window.receipts = [];
    document.addEventListener('wheel', () => {
      receipts.push('wheel');
      setTimeout(() => {
        receipts.push('idle');
        setTimeout(() => receipts.push('end'), 150);
      }, 150);
    });
  </script>`);
  await port.finishMount();
  await port.wheel({x:100, y:100}, {deltaX:0, deltaY:-100});
  // No retry: returning before the chain completes is the defect.
  expect(await page.evaluate(() => window.receipts)).toEqual(['wheel', 'idle', 'end']);
});

test('a navigation holds zero-delay timers until application frames advance', async ({page}) => {
  // Real navigation is load-bearing: setContent does not replay clock logs.
  await page.route('**/clock-probe.html', route => route.fulfill({
    contentType:'text/html',body:`<div id="target" style="width:10px;height:10px"></div>
      <script src="/parity/system/harness/fixtures/navigation-timers.js"></script>`,
  }));
  const port=createPagePort(page);
  const advance=await port.prepareMount();
  await page.goto('/clock-probe.html');
  for(let frame=0;frame<8;frame++) await port.tick();
  expect(await page.evaluate(()=>window.receipts)).toEqual(['resize']);
  await advance();
  await port.tick();
  expect(await page.evaluate(()=>window.receipts)).toEqual(['resize','timer']);
  await port.finishMount();
});

for(const side of ['upstream','psflow']) {
  test(`${side} completes an animated imperative call with time held between actions`,async({page})=>{
    const {defineScenario}=await import('./scenario.mjs');
    const {routeOf}=await import('../corpus/routes.mjs');
    const scenario=defineScenario({id:'live--animated-viewport',route:routeOf('./flow/chrome-defaults.ts'),
      run:async a=>{await a.call('setViewport',[{x:25,y:10,zoom:1.2},{duration:96}]);}});
    const trace=await runScenario(page,scenario,{side,capture:1,baseline});
    expect(trace.sections.api.calls[0].result).toBe(true);
    expect(trace.sections.callbacks.some(c=>c.name==='onMoveEnd')).toBe(true);
    expect(await page.locator('.react-flow__viewport').getAttribute('style')).toContain('translate(25px, 10px) scale(1.2)');
  });
}

for(const side of ['upstream','psflow']) {
  test(`${side} resets held keyboard modifiers on the blank document between captures`,async({page})=>{
    const {defineScenario}=await import('./scenario.mjs');
    const held=defineScenario({id:'live--held-shift',route:'/tests/generic/nodes/general',
      run:async a=>{await a.key('Shift',{action:'down'});}});
    const click=defineScenario({id:'live--plain-click',route:'/tests/generic/nodes/general',
      run:async a=>{await a.click('.react-flow__node[data-id="Node-1"]');}});
    await runScenario(page,held,{side,capture:1,baseline});
    const trace=await runScenario(page,click,{side,capture:2,baseline});
    const events=trace.sections.callbacks.flatMap(c=>c.args).filter(a=>a&&Object.hasOwn(a,'shiftKey'));
    expect(events.length).toBeGreaterThan(0);
    expect(events.every(e=>!e.shiftKey&&!e.altKey&&!e.ctrlKey&&!e.metaKey)).toBe(true);
  });
}
