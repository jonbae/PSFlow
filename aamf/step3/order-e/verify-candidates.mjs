import assert from 'node:assert/strict';
import {readFileSync,writeFileSync} from 'node:fs';
import {readRun} from '../../../parity/system/net/traces.mjs';
import {compareRun} from '../../../parity/system/compare/run.mjs';
import {checkSelfConsistency} from '../../../parity/system/compare/consistency.mjs';
const read=n=>JSON.parse(readFileSync(`parity/system/${n}.json`));
const options={rules:read('normalization').rules,regions:read('regions').regions,weakenings:read('weakenings').weakenings};
const ids=['arrow-key-selected-node','drag-moves-node','drag-node-autopan','drag-node-reports-changes','pan-after-controlled-viewport-change','pan-gesture-complete','wheel-zoom-from-identity-viewport','ctrl-wheel-pinches-with-panonscroll','mount-baseline--viewport-controlled'];
const root='aamf/step3/order-e/final';const rows=[];
for(const id of ids){
 const anchor=readRun(`${root}/round1`,id);
 for(let round=1;round<=5;round++){
  const traces=readRun(`${root}/round${round}`,id);const full=compareRun(traces,options);
  assert.ok(full.ok,`${id} round${round}: complete comparison must pass`);
  for(const side of ['upstream','psflow']){
   for(const capture of [1,2]){
    const first=anchor.find(t=>t.side===side&&t.capture===1);
    const current=traces.find(t=>t.side===side&&t.capture===capture);
    if(round===1&&capture===1)continue;
    // Different envelope capture numbers are required by the official check.
    const other={...current,capture:2};
    assert.ok(checkSelfConsistency(first,other,{rules:options.rules}).consistent,`${id} ${side} round${round} capture${capture}: across-round stability`);
   }
  }
  rows.push({scenario:id,round,fullGatePassed:true,acrossRoundsStable:true});
 }
}
const reject=(id,change,label)=>{
 const traces=structuredClone(readRun(`${root}/round1`,id));
 for(const t of traces)if(t.side==='psflow')change(t);
 assert.ok(!compareRun(traces,options).ok,label);return true;
};
const walk=(el,predicate)=>predicate(el)?el:el.children?.map(c=>walk(c,predicate)).find(Boolean);
const faults={
 missingAnnouncementRejected:reject('arrow-key-selected-node',t=>{
  const el=walk(t.sections.dom.root,e=>e.attrs?.id?.startsWith('react-flow__aria-live-'));
  assert.ok(el?.text);delete el.text;
 },'official comparator must reject removing the announcement'),
 missingWheelEndRejected:reject('wheel-zoom-from-identity-viewport',t=>{
  const i=t.sections.callbacks.findIndex(c=>c.name==='onMoveEnd');assert.ok(i>=0);t.sections.callbacks.splice(i,1);
 },'official comparator must reject a missing wheel end'),
 missingAutoPanFrameRejected:reject('drag-node-autopan',t=>{
  const i=t.sections.callbacks.findIndex(c=>c.name==='onNodeDrag');assert.ok(i>=0);t.sections.callbacks.splice(i,1);
 },'official comparator must reject a missing auto-pan receipt'),
 initialOrderFaultRejected:reject('pan-after-controlled-viewport-change',t=>{
  const c=t.sections.callbacks,n=c.findIndex(e=>e.name==='onNodesChange'),m=c.findIndex(e=>e.name==='onMoveEnd');
  assert.ok(n>=0&&m>n);[c[n],c[m]]=[c[m],c[n]];
 },'official comparator must reject a restored initialization order defect'),
};
writeFileSync(new URL('./candidate-verification.json',import.meta.url),JSON.stringify({rows,rawTraces:rows.length*4,faults},null,2)+'\n');
console.log(`${rows.length} complete comparisons pass; every capture reproduces across rounds; four deliberate faults rejected`);
