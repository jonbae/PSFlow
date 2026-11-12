import {spawnSync} from 'node:child_process';
const checks=[
 ['surface','npm','run','parity:surface'],
 ['function-and-unit','npm','exec','--yes','--package=purescript@0.15.16','--','spago','test'],
 ['boundary','npm','run','parity:boundary'],
 ['boundary-tests','npm','run','test:boundary'],
 ['driver','node','parity/driver/build.mjs'],
];
for(const args of checks){
 const result=spawnSync(process.execPath,['/private/tmp/psflow-step3-check.mjs',...args],{env:{...process.env,PSFLOW_CHECK_DIR:'aamf/step3/shared-handle-timing'},stdio:'inherit'});
 if(result.status!==0)process.exit(result.status??1);
}
