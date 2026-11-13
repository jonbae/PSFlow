import {spawnSync} from 'node:child_process';
const checks=[
 ['build-final','npm','exec','--yes','--package=purescript@0.15.16','--','spago','build'],
 ['function-unit-final','npm','exec','--yes','--package=purescript@0.15.16','--','spago','test'],
 ['surface-final','npm','run','parity:surface'],
 ['boundary-final','npm','run','parity:boundary'],
 ['boundary-tests-final','npm','run','test:boundary'],
 ['driver-final','node','parity/driver/build.mjs'],
 ['live-harness-final','npm','run','test:harness:live'],
 ['harness-unit-final','npm','run','test:harness'],
 ['comparison-coverage-final','sh','-c','npm run test:compare && npm run test:coverage'],
 ['conformance-final','npm','run','test:conformance'],
 ['smoke-final','npm','run','test:smoke'],
 ['changelog-final','npm','run','parity:changelog'],
];
for(const args of checks){
 const result=spawnSync(process.execPath,['/private/tmp/psflow-step3-check.mjs',...args],{env:{...process.env,PSFLOW_CHECK_DIR:'aamf/step3/order-e'},stdio:'inherit'});
 if(result.status!==0)process.exit(result.status??1);
}
