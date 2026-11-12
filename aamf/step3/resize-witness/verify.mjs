// Targeted witness check alongside, never in place of, the unchanged full gate.
import assert from 'node:assert/strict';
import {readFileSync,writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {readRun} from '../../../parity/system/net/traces.mjs';
import {compareRun} from '../../../parity/system/compare/run.mjs';
const folder=process.argv[2]??'captures';
const read=name=>JSON.parse(readFileSync(new URL(name,import.meta.url)));
const options={rules:read('./comparison/normalization.json').rules,regions:read('./comparison/regions.json').regions,weakenings:read('./comparison/weakenings.json').weakenings};
const ids=process.argv.length>3?process.argv.slice(3):['resize-node-with-direct-control','resize-node-with-resizer','resize-node-after-active-limit-change'];
const receipt=trace=>{
 let history;
 const walk=e=>{if(e.attrs?.['data-resize-history'])history=JSON.parse(e.attrs['data-resize-history']);e.children?.forEach(walk);};
 walk(trace.sections.dom.root);assert.ok(history,'consumer-rendered callback receipts exist');
 const [start,...rest]=history;const end=rest.at(-1);const during=rest.slice(0,-1);
 assert.ok(start.name.endsWith(':start'));assert.ok(end.name.endsWith(':end'));assert.ok(during.length>0);
 assert.ok(during.every(value=>value.name.endsWith(':resize')));
 assert.ok(during.some(({values})=>values.width!==start.values.width||values.height!==start.values.height),'the node was actually resized');
 const node=trace.sections.api.queries.getNodes.find(n=>n.id==='resize');
 assert.equal(node.width,end.values.width);assert.equal(node.height,end.values.height);
 return {history,node:{width:node.width,height:node.height}};
};
const summary=[];
const failures=[];
for(const id of ids){
 const traces=readRun(fileURLToPath(new URL(`./${folder}/`,import.meta.url)),id);
 const full=compareRun(traces,options);
 const interpretable=full.consistency.every(side=>side.consistent)&&!full.failures.some(f=>f.class==='driving-divergence');
 const row={scenario:id,interpretable,selfConsistency:full.consistency.map(side=>({side:side.side,consistent:side.consistent})),fullGatePassed:full.ok,remainingDifferences:interpretable?full.comparison.unclaimed:null};
 summary.push(row);
 try {
  assert.ok(interpretable,`${id}: selected experiment must reproduce before interpretation`);
  const values=traces.map(trace=>({side:trace.side,capture:trace.capture,...receipt(trace)}));
  const oracle=values.find(value=>value.side==='upstream');
  for(const value of values){assert.deepEqual(value.history,oracle.history,`${id}: lifecycle receipts`);assert.deepEqual(value.node,oracle.node,`${id}: changed dimensions`);}
  row.resize=oracle.node;row.callbacks=oracle.history.map(r=>r.name);row.witnessPassed=true;
  const corrupt=structuredClone(traces);
  for(const trace of corrupt)if(trace.side==='psflow'){
   const walk=e=>{if(e.attrs?.['data-resize-history'])e.attrs['data-resize-history']='[]';e.children?.forEach(walk);};walk(trace.sections.dom.root);
  }
  const rejected=compareRun(corrupt,options);
  assert.ok(rejected.comparison.unclaimed.some(d=>d.path.includes('data-resize-history')),'official comparator must reject a corrupted consumer receipt');
 } catch(error) {row.witnessPassed=false;row.failure=error.message;failures.push(error);}
}
writeFileSync(new URL(`./${folder}-summary.json`,import.meta.url),JSON.stringify(summary,null,2)+'\n');
console.log(JSON.stringify(summary.map(({scenario,interpretable,resize,callbacks,fullGatePassed,witnessPassed,remainingDifferences})=>({scenario,interpretable,resize,callbacks,fullGatePassed,witnessPassed,remainingDifferences:remainingDifferences?.length??null})),null,2));
assert.equal(failures.length,0,'all selected witness experiments must reproduce and match');
