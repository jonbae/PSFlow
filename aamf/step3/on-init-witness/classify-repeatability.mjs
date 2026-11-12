// Evidence only: exact callback sequences and official self-differences.
// No callbacks are removed and no alternate consistency verdict is computed.
import{readFileSync,writeFileSync}from'node:fs';
import{readRun}from'../../../parity/system/net/traces.mjs';
import{checkSelfConsistency}from'../../../parity/system/compare/consistency.mjs';
const wave=JSON.parse(readFileSync(new URL('./wave-summary.json',import.meta.url)));
const rules=JSON.parse(readFileSync('parity/system/normalization.json')).rules;
const rows=[];
for(const id of wave.selfInconsistent){
 const traces=readRun('parity/system/traces',id);
 for(const side of ['upstream','psflow']){
  const pair=traces.filter(t=>t.side===side).sort((a,b)=>a.capture-b.capture);
  const result=checkSelfConsistency(...pair,{rules});
  if(!result.consistent)rows.push({scenario:id,side,differences:result.differences,callbackSequences:pair.map(t=>t.sections.callbacks.map(e=>e.name))});
 }
}
const summary={unstableScenarios:wave.selfInconsistent.length,unstableSides:Object.fromEntries(['upstream','psflow'].map(side=>[side,rows.filter(r=>r.side===side).length])),rows};
writeFileSync(new URL('./repeatability-details.json',import.meta.url),JSON.stringify(summary,null,2)+'\n');
console.log(JSON.stringify({...summary,rows:undefined},null,2));
console.log(JSON.stringify(rows.slice(0,4).map(r=>({scenario:r.scenario,side:r.side,paths:r.differences.map(d=>d.path),callbackSequences:r.callbackSequences})),null,2));
