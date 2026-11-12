// Diagnostic only until a tested protocol is explicitly adopted. The mounted
// library, fixture, callback set and official comparison policy never vary.
import { chromium } from '@playwright/test';
import { readFileSync,writeFileSync,mkdirSync } from 'node:fs';
import { runScenario,defineScenario } from '../../../parity/system/harness/scenario.mjs';
import { createPagePort } from '../../../parity/system/harness/port.mjs';
import { checkSelfConsistency } from '../../../parity/system/compare/consistency.mjs';
import { serveDirectory } from '../../../parity/system/net/server.mjs';
import { settleDom } from '../../../parity/system/harness/settle.mjs';
import { createHash } from 'node:crypto';
const [mode='baseline',count='5']=process.argv.slice(2);
if(!['baseline','clock-running','clock-paused','clock-paused-native','clock-paused-native-32','clock-layout','fresh-page'].includes(mode))throw Error('unscoped experiment');
// These are historical probes of the original driver, not a switch that can
// turn the adopted protocol off. Restore the diagnostic archive in a separate
// checkout to replay them; reject an accidental run against changed machinery.
const diagnostic=JSON.parse(readFileSync(new URL('./diagnostic-snapshot.json',import.meta.url)));
for(const path of ['parity/system/harness/port.mjs','parity/system/harness/scenario.mjs']){
 const hash=createHash('sha256').update(readFileSync(path)).digest('hex');
 if(hash!==diagnostic.sha256[path])throw Error(`Restore the diagnostic runtime in a separate checkout before replaying ${path}`);
}
const server=await serveDirectory(process.cwd());const browser=await chromium.launch();
const directory=new URL(`./${mode}/`,import.meta.url);mkdirSync(directory,{recursive:true});
const rules=JSON.parse(readFileSync('parity/system/normalization.json')).rules;
const scenario=defineScenario({id:'init-order-mount',route:'/tests/generic/edges/general',run:async()=>{}});
const results=[];
try{
 const context=await browser.newContext({baseURL:server.origin,viewport:{width:1280,height:720}});let page=await context.newPage();
 if(mode.startsWith('clock-'))await page.clock.install({time:Date.UTC(2026,0,1)});
 if(mode.startsWith('clock-paused')||mode==='clock-layout')await page.clock.pauseAt(Date.UTC(2026,0,1)+1000);
 const cdp=mode.startsWith('clock-paused-native')||mode==='clock-layout'?await context.newCDPSession(page):null;
 const nativeFrame=async()=>{
  if(!cdp)return;
  const {frameTree}=await cdp.send('Page.getFrameTree');
  const {executionContextId}=await cdp.send('Page.createIsolatedWorld',{frameId:frameTree.frame.id,worldName:'psflow-native-frame-probe'});
  await cdp.send('Runtime.evaluate',{contextId:executionContextId,expression:'new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(() => resolve())))',awaitPromise:true,returnByValue:true});
 };
 for(let round=1;round<=Number(count);round++){
  const traces=[];
  for(const capture of [1,2]){
   if(mode==='fresh-page'){await page.close();page=await context.newPage();}
   const port=createPagePort(page);
   if(mode.startsWith('clock-paused')||mode==='clock-layout'){
    let first=true;
    port.tick=async()=>{
     if(first&&mode==='clock-layout'){first=false;await settleDom({...port,tick:nativeFrame},'.react-flow');}
     await nativeFrame();await page.clock.runFor(mode.endsWith('-32')||mode==='clock-layout'?32:50);
    };
    const box=port.box;
    port.box=async(...args)=>{
     let done=false;const pending=box(...args).finally(()=>{done=true;});
     for(let frame=0;!done&&frame<200;frame++){await nativeFrame();if(mode!=='clock-layout')await page.clock.runFor(16);}
     return pending;
    };
   }
   const trace=await runScenario(page,scenario,{side:'upstream',capture,baseline:'12.11.0',port});
   traces.push(trace);writeFileSync(new URL(`round${round}.capture${capture}.json`,directory),JSON.stringify(trace,null,2)+'\n');
  }
  const result=checkSelfConsistency(...traces,{rules});results.push({round,...result,callbackSequences:traces.map(t=>t.sections.callbacks.map(e=>e.name))});
  console.log(JSON.stringify({mode,round,consistent:result.consistent,callbackSequences:results.at(-1).callbackSequences}));
 }
 await context.close();
}finally{await browser.close();await server.close();}
writeFileSync(new URL('results.json',directory),JSON.stringify(results,null,2)+'\n');process.exitCode=results.every(r=>r.consistent)?0:1;
