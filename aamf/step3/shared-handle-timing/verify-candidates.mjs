import assert from 'node:assert/strict';
import {readFileSync,writeFileSync} from 'node:fs';
import {readRun} from '../../../parity/system/net/traces.mjs';
import {compareRun} from '../../../parity/system/compare/run.mjs';
import {checkSelfConsistency} from '../../../parity/system/compare/consistency.mjs';
const read=n=>JSON.parse(readFileSync(`parity/system/${n}.json`));
const options={rules:read('normalization').rules,regions:read('regions').regions,weakenings:read('weakenings').weakenings};
const ids=['mount-baseline--edges-general','mount-baseline--pane-non-defaults','mount-baseline--node-toolbar-general'];
const rows=[];
for(const id of ids){
 const anchor=readRun('aamf/step3/shared-handle-timing/candidate/round1',id);
 for(const round of[1,2]){
  const traces=readRun(`aamf/step3/shared-handle-timing/candidate/round${round}`,id);
  const full=compareRun(traces,options);assert.ok(full.ok,`${id} round${round}: full comparison must pass`);
  for(const side of ['upstream','psflow']){
   const across=checkSelfConsistency(anchor.find(t=>t.side===side&&t.capture===1),traces.find(t=>t.side===side&&t.capture===2),{rules:options.rules});
   assert.ok(across.consistent,`${id} ${side}: captures must agree across independent rounds`);
  }
  rows.push({scenario:id,round,fullGatePassed:true,acrossRoundsStable:true});
 }
}
const traces=readRun('aamf/step3/shared-handle-timing/candidate/round1','mount-baseline--edges-general');
const handles=structuredClone(traces);
for(const trace of handles)if(trace.side==='psflow')trace.sections.api.queries.getInternalNode.internals.handleBounds.target=[];
assert.ok(compareRun(handles,options).comparison.unclaimed.some(d=>d.path.includes('handleBounds')),'official comparator rejects restoring [] for null');
const order=structuredClone(traces);
for(const trace of order)if(trace.side==='psflow'){
 const c=trace.sections.callbacks,n=c.findIndex(e=>e.name==='onNodesChange'),m=c.findIndex(e=>e.name==='onMoveEnd');
 assert.ok(n>=0&&m>n);[c[n],c[m]]=[c[m],c[n]];
}
assert.ok(compareRun(order,options).comparison.unclaimed.some(d=>d.kind==='order'&&d.path[0]==='callbacks'),'official comparator rejects restoring inline end order');
writeFileSync(new URL('./candidate-verification.json',import.meta.url),JSON.stringify({rows,handleFaultRejected:true,callbackOrderFaultRejected:true},null,2)+'\n');
console.log('All six complete candidate runs pass; both sides reproduce across rounds; both restored-defect faults rejected');
