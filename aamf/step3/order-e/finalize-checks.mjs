// After capture-checks completes: freeze outputs and verify runtime before docs.
// Seal/checksum verification runs separately so no receipt mutates after sealing.
import {spawnSync} from 'node:child_process';
const checks=[
 ['record-outputs','python3','aamf/step3/order-e/finalize-artifacts.py'],
 ['archive-runtime','python3','aamf/step3/order-e/archive-runtime.py'],
 ['verify-runtime','python3','aamf/step3/order-e/verify-runtime.py'],
 ['record-completion','python3','aamf/step3/order-e/write-results.py'],
 ['source-audit-final','python3','aamf/step3/order-e/audit.py'],
 ['diff-check-final','git','diff','--check'],
];
for(const args of checks){
 const result=spawnSync(process.execPath,['/private/tmp/psflow-step3-check.mjs',...args],{env:{...process.env,PSFLOW_CHECK_DIR:'aamf/step3/order-e'},stdio:'inherit'});
 if(result.status!==0)process.exit(result.status??1);
}
