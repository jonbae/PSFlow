import {spawnSync} from 'node:child_process';
const checks=[
 ['live-harness-deadline-final','npm','run','test:harness:live','--','--grep','psflow reproduces the complete drag-node-reports-changes'],
 ['harness-unit-final','npm','run','test:harness'],
 ['comparison-coverage-final','sh','-c','npm run test:compare && npm run test:coverage'],
 ['conformance-final','npm','run','test:conformance'],
 ['smoke-final','npm','run','test:smoke'],
 ['changelog-final','npm','run','parity:changelog'],
];
for(const [name,...command] of checks){
 const result=spawnSync(process.execPath,['/private/tmp/psflow-step3-check.mjs',name,process.execPath,'parity/system/linux.mjs',...command],{env:{...process.env,PSFLOW_CHECK_DIR:'aamf/step3/order-e'},stdio:'inherit'});
 if(result.status!==0)process.exit(result.status??1);
 if(name==='live-harness-deadline-final'){
  const freeze=spawnSync('python3',['aamf/step3/order-e/freeze-runtime.py'],{stdio:'inherit'});
  if(freeze.status!==0)process.exit(freeze.status??1);
 }
}
