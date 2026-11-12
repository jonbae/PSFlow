// Read the complete fresh wave with the unchanged comparison policy. Unstable
// experiments retain their consistency differences and have no triage diff.
import {readFileSync,writeFileSync} from 'node:fs';
import {storedScenarios,readRun} from '../../../parity/system/net/traces.mjs';
import {compareRun} from '../../../parity/system/compare/run.mjs';
const read=path=>JSON.parse(readFileSync(path));
const options={rules:read('parity/system/normalization.json').rules,regions:read('parity/system/regions.json').regions,weakenings:read('parity/system/weakenings.json').weakenings};
const rows=storedScenarios('parity/system/traces').map(scenario=>{
 const run=compareRun(readRun('parity/system/traces',scenario),options);
 const interpretable=run.consistency.every(s=>s.consistent)&&!run.failures.some(f=>f.class==='driving-divergence');
 return {scenario,passed:run.ok,interpretable,consistency:run.consistency.map(s=>({side:s.side,consistent:s.consistent,differences:s.differences})),classes:[...new Set(run.failures.map(f=>f.class))],unclaimed:interpretable?run.comparison.unclaimed:null};
});
const summary={scenarios:rows.length,passed:rows.filter(r=>r.passed).length,failed:rows.filter(r=>!r.passed).length,selfInconsistent:rows.filter(r=>r.consistency.some(s=>!s.consistent)).map(r=>r.scenario),drivingDivergence:rows.filter(r=>r.classes.includes('driving-divergence')).map(r=>r.scenario),interpretable:rows.filter(r=>r.interpretable).length,rows};
writeFileSync(new URL('./wave-summary.json',import.meta.url),JSON.stringify(summary,null,2)+'\n');
console.log(JSON.stringify({...summary,rows:undefined},null,2));
