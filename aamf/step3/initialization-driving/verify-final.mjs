import{spawnSync}from'node:child_process';
const calls=[
 ['aamf/step3/initialization-driving/verify-captures.mjs','final'],
 ...['arrow-key-selected-node','resize-node-after-active-limit-change','mount-baseline--edges-general'].map(id=>['aamf/step3/initialization-driving/verify-repeatability.mjs','final',id]),
 ...[1,2,3,4,5].map(round=>['aamf/step3/resize-witness/verify.mjs',`../initialization-driving/final/round${round}`,'resize-node-after-active-limit-change']),
];
for(const args of calls){const r=spawnSync(process.execPath,args,{encoding:'utf8'});process.stdout.write(r.stdout);process.stderr.write(r.stderr);if(r.status!==0)process.exit(r.status??1);}
