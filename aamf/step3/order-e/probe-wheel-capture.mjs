// Official corpus and complete comparator; no alternate port or filtering.
import{createPagePort}from'./probe-wheel-port.mjs';
import{chromium}from'@playwright/test';
import{readFileSync,writeFileSync,mkdirSync}from'node:fs';
import{routeSpace}from'../../../parity/driver/registry.mjs';
import{buildCorpus}from'../../../parity/system/corpus/index.mjs';
import{runScenario}from'../../../parity/system/harness/scenario.mjs';
import{compareRun}from'../../../parity/system/compare/run.mjs';
import{serveDirectory}from'../../../parity/system/net/server.mjs';
const[phase='candidate',count='2',...ids]=process.argv.slice(2);
if(!['wheel-drain'].includes(phase))throw Error('unknown phase');
const{fixtures,components}=routeSpace(process.cwd());const corpus=buildCorpus(fixtures,components);
const read=n=>JSON.parse(readFileSync(`parity/system/${n}.json`));
const options={rules:read('normalization').rules,regions:read('regions').regions,weakenings:read('weakenings').weakenings};
const server=await serveDirectory(process.cwd());const browser=await chromium.launch();const rows=[];
try{
 for(const id of ids){const scenario=corpus.find(s=>s.id===id);if(!scenario)throw Error(`unknown scenario ${id}`);
  for(let round=1;round<=Number(count);round++){
   const dir=new URL(`./${phase}/round${round}/`,import.meta.url);mkdirSync(dir,{recursive:true});const traces=[];
   for(const side of ['upstream','psflow']){
    const context=await browser.newContext({baseURL:server.origin,viewport:{width:1280,height:720}});const page=await context.newPage();
    try{for(const capture of[1,2]){const started=Date.now();const trace=await runScenario(page,scenario,{side,capture,baseline:'12.11.0',port:createPagePort(page)});traces.push(trace);writeFileSync(new URL(`${id}.${side}.capture${capture}.json`,dir),JSON.stringify(trace,null,2)+'\n');console.log(JSON.stringify({phase,scenario:id,round,side,capture,elapsedMs:Date.now()-started}));}}
    finally{await context.close();}
   }
   const result=compareRun(traces,options);const interpretable=result.consistency.every(s=>s.consistent)&&!result.failures.some(f=>f.class==='driving-divergence');
   const row={scenario:id,round,interpretable,fullGatePassed:result.ok,consistency:result.consistency,classes:[...new Set(result.failures.map(f=>f.class))],differences:interpretable?result.comparison.unclaimed:null};rows.push(row);writeFileSync(new URL(`./${phase}-summary.json`,import.meta.url),JSON.stringify(rows,null,2)+'\n');console.log(JSON.stringify({...row,consistency:row.consistency.map(s=>({side:s.side,consistent:s.consistent})),differences:row.differences?.length??null}));
  }
 }
}finally{await browser.close();await server.close();}
process.exitCode=rows.every(r=>r.interpretable)?0:1;
