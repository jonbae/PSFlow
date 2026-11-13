// Reuse the completed resize family's official comparator, actual consumer
// receipts and corruption check, unchanged, on every new stable capture pair.
import { spawnSync } from 'node:child_process';
for (const phase of ['candidate','repeat']) for (let round=1;round<=5;round++) {
 const result=spawnSync(process.execPath,['aamf/step3/resize-witness/verify.mjs',`../keyboard-driving/${phase}/round${round}`,'resize-node-after-active-limit-change'],{encoding:'utf8'});
 process.stdout.write(result.stdout); process.stderr.write(result.stderr);
 if(result.status!==0) process.exit(result.status??1);
}
