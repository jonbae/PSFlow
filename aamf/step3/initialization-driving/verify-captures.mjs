// Literal public-API receipts from the original upstream fixture and the
// unchanged full comparator guard against stable but starved captures.
import assert from 'node:assert/strict';
import{readFileSync,writeFileSync}from'node:fs';
import{fileURLToPath}from'node:url';
import{readRun}from'../../../parity/system/net/traces.mjs';
import{compareRun}from'../../../parity/system/compare/run.mjs';
const read=p=>JSON.parse(readFileSync(new URL(p,import.meta.url)));
const baseline=read('./baseline/round1.capture1.json');
const opts={rules:read('../../../parity/system/normalization.json').rules,regions:read('../../../parity/system/regions.json').regions,weakenings:read('../../../parity/system/weakenings.json').weakenings};
const rows=[];
for(const phase of (process.argv.length>2?process.argv.slice(2):['candidate','repeat']))for(let round=1;round<=5;round++){
 const traces=readRun(fileURLToPath(new URL(`./${phase}/round${round}/`,import.meta.url)),'mount-baseline--edges-general');
 const result=compareRun(traces,opts);assert.ok(result.consistency.every(s=>s.consistent));
 for(const t of traces){
  assert.deepEqual(t.sections.api.queries.getViewport,baseline.sections.api.queries.getViewport,'viewport geometry retains the original source answer');
  assert.deepEqual(t.sections.api.queries.getNodes,baseline.sections.api.queries.getNodes,'node receipts retain the original source answer');
  for(const name of ['onInit','onMoveEnd'])assert.equal(t.sections.callbacks.filter(e=>e.name===name).length,1);
 }
 const corrupt=structuredClone(traces);
 for(const t of corrupt)if(t.side==='psflow')t.sections.callbacks=t.sections.callbacks.filter(e=>e.name!=='onInit');
 const rejected=compareRun(corrupt,opts);assert.ok(rejected.comparison.unclaimed.some(d=>d.path[0]==='callbacks'),'the official comparator rejects a missing initialization callback');
 rows.push({phase,round,preservedGeometry:true,missingCallbackRejected:true,fullGatePassed:result.ok,unclaimed:result.comparison.unclaimed.length});
}
writeFileSync(new URL('./capture-verification.json',import.meta.url),JSON.stringify(rows,null,2)+'\n');console.log(JSON.stringify(rows,null,2));
