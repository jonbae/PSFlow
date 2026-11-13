// Read-only summary of the final full wave, using its unchanged comparator.
import {readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {routeSpace} from '../../../parity/driver/registry.mjs';
import {buildCorpus} from '../../../parity/system/corpus/index.mjs';
import {readRun} from '../../../parity/system/net/traces.mjs';
import {compareRun} from '../../../parity/system/compare/run.mjs';
const read=name=>JSON.parse(readFileSync(resolve('parity/system',name)));
const options={rules:read('normalization.json').rules,regions:read('regions.json').regions,weakenings:read('weakenings.json').weakenings};
const {fixtures,components}=routeSpace(process.cwd());
const rows=buildCorpus(fixtures,components).map(({id})=>{
 const traces=readRun(resolve('parity/system/traces'),id);
 const result=compareRun(traces,options);
 const interpretable=result.consistency.every(side=>side.consistent)&&!result.failures.some(f=>f.class==='driving-divergence');
 return {scenario:id,passed:result.ok,interpretable,consistency:result.consistency.map(s=>({side:s.side,consistent:s.consistent,differences:s.differences.length})),classes:[...new Set(result.failures.map(f=>f.class))],unclaimed:interpretable?result.comparison.unclaimed.length:null,onInit:traces.map(t=>({side:t.side,capture:t.capture,calls:t.sections.callbacks.filter(e=>e.name==='onInit').length}))};
});
const summary={scenarios:rows.length,passed:rows.filter(r=>r.passed).length,failed:rows.filter(r=>!r.passed).length,selfInconsistent:rows.filter(r=>r.classes.includes('self-inconsistent')).map(r=>r.scenario),drivingDivergence:rows.filter(r=>r.classes.includes('driving-divergence')).map(r=>r.scenario),rows};
writeFileSync(new URL('./wave-summary.json',import.meta.url),JSON.stringify(summary,null,2)+'\n');
console.log(JSON.stringify({...summary,rows:undefined},null,2));
