// Stronger bounded-experiment check using the same official self-comparator.
// Round 1/capture 1 is compared to capture 2 in every independently run round;
// together with each pair's existing check this covers every original trace.
import assert from 'node:assert/strict';
import{readFileSync,writeFileSync}from'node:fs';
import{fileURLToPath}from'node:url';
import{readRun}from'../../../parity/system/net/traces.mjs';
import{checkSelfConsistency}from'../../../parity/system/compare/consistency.mjs';
const[phase,id,count='5']=process.argv.slice(2);const rules=JSON.parse(readFileSync('parity/system/normalization.json')).rules;
const read=round=>readRun(fileURLToPath(new URL(`./${phase}/round${round}/`,import.meta.url)),id);
const anchor=read(1);const rows=[];
for(let round=1;round<=Number(count);round++){
 const traces=read(round);
 for(const side of ['upstream','psflow']){
  const pair=traces.filter(t=>t.side===side);const within=checkSelfConsistency(...pair,{rules});
  const across=checkSelfConsistency(anchor.find(t=>t.side===side&&t.capture===1),pair.find(t=>t.capture===2),{rules});
  rows.push({round,side,within:within.consistent,across:across.consistent,differences:across.differences});
 }
}
writeFileSync(new URL(`./${phase}-${id}-repeatability.json`,import.meta.url),JSON.stringify(rows,null,2)+'\n');
console.log(JSON.stringify(rows.map(({differences,...r})=>({...r,differences:differences.length})),null,2));
assert.ok(rows.every(r=>r.within&&r.across),'all original captures must reproduce across independent rounds');
