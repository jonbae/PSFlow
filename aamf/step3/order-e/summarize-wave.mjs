// Read-only classification of old and fresh raw traces with the official comparator.
import {readFileSync,writeFileSync,mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {spawnSync} from 'node:child_process';
import {routeSpace} from '../../../parity/driver/registry.mjs';
import {buildCorpus} from '../../../parity/system/corpus/index.mjs';
import {readRun} from '../../../parity/system/net/traces.mjs';
import {compareRun} from '../../../parity/system/compare/run.mjs';
const read=p=>JSON.parse(readFileSync(p));
const options={rules:read('parity/system/normalization.json').rules,regions:read('parity/system/regions.json').regions,weakenings:read('parity/system/weakenings.json').weakenings};
const {fixtures,components}=routeSpace(process.cwd());
const ids=buildCorpus(fixtures,components).map(s=>s.id);
const classify=dir=>{
 const rows=ids.map(scenario=>{
  const r=compareRun(readRun(dir,scenario),options);
  const interpretable=r.consistency.every(s=>s.consistent)&&!r.failures.some(f=>f.class==='driving-divergence');
  const diffs=r.comparison.unclaimed;
  const handles=diffs.filter(d=>d.path.includes('handleBounds'));
  const orders=diffs.filter(d=>d.kind==='order'&&d.path.length===1&&d.path[0]==='callbacks');
  const initialOrders=orders.filter(d=>d.left.indexOf('onNodesChange#1')<d.left.indexOf('onMoveEnd#1')&&d.right.indexOf('onNodesChange#1')>d.right.indexOf('onMoveEnd#1'));
  return {scenario,passed:r.ok,interpretable,consistency:r.consistency.map(s=>({side:s.side,consistent:s.consistent,differences:s.differences})),classes:[...new Set(r.failures.map(f=>f.class))],unclaimed:interpretable?diffs:null,handleDifferences:interpretable?handles.length:null,callbackOrderDifferences:interpretable?orders.length:null,initialMeasurementOrderDifferences:interpretable?initialOrders.length:null};
 });
 const stable=rows.filter(r=>r.interpretable);
 return {scenarios:rows.length,passed:rows.filter(r=>r.passed).length,failed:rows.filter(r=>!r.passed).length,selfInconsistent:rows.filter(r=>r.classes.includes('self-inconsistent')).map(r=>r.scenario),drivingDivergence:rows.filter(r=>r.classes.includes('driving-divergence')).map(r=>r.scenario),reproducibleFailed:stable.filter(r=>!r.passed).length,handleScenarios:stable.filter(r=>r.handleDifferences).length,handleDifferences:stable.reduce((n,r)=>n+r.handleDifferences,0),callbackOrderScenarios:stable.filter(r=>r.callbackOrderDifferences).length,initialMeasurementOrderScenarios:stable.filter(r=>r.initialMeasurementOrderDifferences).length,rows};
};
const directory=mkdtempSync(join(tmpdir(),'psflow-order-e-before-'));
try {
 const extract=spawnSync('tar',['-xzf','aamf/step3/order-e/before-canonical-checkpoint.tar.gz','-C',directory]);
 if(extract.status!==0)throw Error(extract.stderr.toString());
 const previous=classify(join(directory,'parity/system/traces'));
 const current=classify('parity/system/traces');
 const changed=current.rows.filter((r,i)=>r.passed!==previous.rows[i].passed).map((r)=>({scenario:r.scenario,passed:r.passed,interpretable:r.interpretable,classes:r.classes}));
 const retirements={previous:Object.fromEntries(Object.entries(previous).filter(([k])=>k!=='rows')),current:Object.fromEntries(Object.entries(current).filter(([k])=>k!=='rows')),changed,remainingStableFailures:current.rows.filter(r=>r.interpretable&&!r.passed)};
 writeFileSync(new URL('./wave-summary.json',import.meta.url),JSON.stringify(current,null,2)+'\n');
 writeFileSync(new URL('./case-retirement.json',import.meta.url),JSON.stringify(retirements,null,2)+'\n');
 console.log(JSON.stringify({...retirements,changed:changed.length,remainingStableFailures:retirements.remainingStableFailures.map(r=>({scenario:r.scenario,unclaimed:r.unclaimed.length,handleDifferences:r.handleDifferences,callbackOrderDifferences:r.callbackOrderDifferences}))},null,2));
}finally{rmSync(directory,{recursive:true,force:true});}
