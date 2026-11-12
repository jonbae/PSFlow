// Read-only partial progress; never substitutes for the completed full wave.
import{readFileSync,writeFileSync}from'node:fs';
import{readRun}from'../../../parity/system/net/traces.mjs';
import{compareRun}from'../../../parity/system/compare/run.mjs';
const read=p=>JSON.parse(readFileSync(p));
const options={rules:read('parity/system/normalization.json').rules,regions:read('parity/system/regions.json').regions,weakenings:read('parity/system/weakenings.json').weakenings};
const ids=[...readFileSync(new URL('./full-system-final.log',import.meta.url),'utf8').matchAll(/^captured (.+)$/gm)].map(m=>m[1]);
const rows=ids.map(id=>{const r=compareRun(readRun('parity/system/traces',id),options);return{scenario:id,passed:r.ok,classes:r.failures.map(f=>f.class)};});
const result={interim:true,at:new Date().toISOString(),completed:rows.length,passed:rows.filter(r=>r.passed).length,failures:rows.filter(r=>r.passed===false)};
writeFileSync(new URL('./interim-wave-summary.json',import.meta.url),JSON.stringify(result,null,2)+'\n');console.log(result);
