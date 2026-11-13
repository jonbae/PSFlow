import assert from 'node:assert/strict';
import {readFileSync,writeFileSync} from 'node:fs';
import {readRun} from '../../../parity/system/net/traces.mjs';
import {checkSelfConsistency} from '../../../parity/system/compare/consistency.mjs';
const id='pan-after-controlled-viewport-change';
const rules=JSON.parse(readFileSync('parity/system/normalization.json')).rules;
const traces=[];
for(const round of[1,2,3])for(const t of readRun(`aamf/step3/shared-handle-timing/controlled-order/round${round}`,id)){
 const n=t.sections.callbacks.findIndex(e=>e.name==='onNodesChange'),m=t.sections.callbacks.findIndex(e=>e.name==='onMoveEnd');
 traces.push({round,side:t.side,capture:t.capture,firstMeasurementBeforeFirstEnd:n<m,trace:t});
}
const sides=['upstream','psflow'].map(side=>{
 const ts=traces.filter(t=>t.side===side);
 const pairs=[1,2,3].map(round=>{const pair=ts.filter(t=>t.round===round);const result=checkSelfConsistency(pair[0].trace,pair[1].trace,{rules});return{round,consistent:result.consistent,differences:result.differences};});
 return{side,measurementBeforeEnd:ts.filter(t=>t.firstMeasurementBeforeFirstEnd).length,endBeforeMeasurement:ts.filter(t=>!t.firstMeasurementBeforeFirstEnd).length,pairs};
});
const source=sides.find(s=>s.side==='upstream');
assert.ok(source.measurementBeforeEnd>0&&source.endBeforeMeasurement>0,'unchanged upstream itself produces both orders');
writeFileSync(new URL('./controlled-order-diagnosis.json',import.meta.url),JSON.stringify({scenario:id,rawTraces:traces.length,sides,conclusion:'The full-wave pair happened to reproduce one upstream order. Independent source captures reproduce both orders; no deterministic cross-side order claim is supported for this scenario. Full-wave raw traces/report remain unchanged.'},null,2)+'\n');
console.log(JSON.stringify(sides.map(s=>({...s,pairs:s.pairs.map(p=>({round:p.round,consistent:p.consistent,differences:p.differences.length}))})),null,2));
