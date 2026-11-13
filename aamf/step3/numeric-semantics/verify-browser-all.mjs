// Reuse the official full comparator for both checkpoints and all raw captures.
// This is a regression check; known cross-side differences remain failures.
import assert from 'node:assert/strict';
import {readFileSync,writeFileSync} from 'node:fs';
import {readRun} from '../../../parity/system/net/traces.mjs';
import {compareRun} from '../../../parity/system/compare/run.mjs';
const read=n=>JSON.parse(readFileSync(`parity/system/${n}.json`));
const options={rules:read('normalization').rules,regions:read('regions').regions,weakenings:read('weakenings').weakenings};
const ids=['resize-node-after-active-limit-change','viewport-helpers-with-options','wheel-zooms-to-changed-limits'];
const rows=[];
for(const id of ids){
 const previous=compareRun(readRun('parity/system/traces',id),options);
 for(const round of[1,2]){
  const current=compareRun(readRun(`aamf/step3/numeric-semantics/final/round${round}`,id),options);
  assert.ok(current.consistency.every(s=>s.consistent),`${id}: each side reproduces`);
  assert.ok(!current.failures.some(f=>f.class==='driving-divergence'),`${id}: same driving`);
  assert.deepStrictEqual(current.comparison.unclaimed,previous.comparison.unclaimed,`${id}: no change to full cross-side findings`);
  rows.push({scenario:id,round,fullGatePassed:current.ok,unclaimedDifferences:current.comparison.unclaimed.length,unchangedFromPriorCheckpoint:true});
 }
}
writeFileSync(new URL('./browser-verification.json',import.meta.url),JSON.stringify(rows,null,2)+'\n');
console.log(JSON.stringify(rows,null,2));
