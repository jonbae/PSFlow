// Run only after remaining-checks passes. Every command retains its raw output.
import {spawnSync} from 'node:child_process';
const ids=['arrow-key-selected-node','drag-moves-node','drag-node-autopan','drag-node-reports-changes','pan-after-controlled-viewport-change','pan-gesture-complete','wheel-zoom-from-identity-viewport','ctrl-wheel-pinches-with-panonscroll','mount-baseline--viewport-controlled'];
const checks=[
 ['final-focused-captures','node','parity/system/linux.mjs','node','aamf/step3/order-e/capture.mjs','final','5',...ids],
 ['verify-focused','node','aamf/step3/order-e/verify-candidates.mjs'],
 ['full-system-final','node','parity/system/linux.mjs','npm','run','parity:system'],
 ['summarize-wave','node','aamf/step3/order-e/summarize-wave.mjs'],
];
for(const args of checks){
 const result=spawnSync(process.execPath,['/private/tmp/psflow-step3-check.mjs',...args],{env:{...process.env,PSFLOW_CHECK_DIR:'aamf/step3/order-e'},stdio:'inherit'});
 if(result.status!==0&&args[0]!=='full-system-final')process.exit(result.status??1);
 if(args[0]==='full-system-final'&&result.status!==1&&result.status!==0)process.exit(result.status??1);
}
