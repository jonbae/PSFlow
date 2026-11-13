import {spawnSync} from 'node:child_process';
const checks=[
 ['linux-driver-final','node','parity/driver/build.mjs'],
 ['linux-function-unit-final','node','--input-type=module','-e',"const m=await import('./output/Test.Main/index.js');m.main();"],
 ['live-harness-paced-final','npm','run','test:harness:live'],
 ['harness-unit-final','npm','run','test:harness'],
 ['comparison-coverage-final','sh','-c','npm run test:compare && npm run test:coverage'],
 ['conformance-final','npm','run','test:conformance'],
 ['smoke-final','npm','run','test:smoke'],
 ['changelog-final','npm','run','parity:changelog'],
];
for(const [name,...command] of checks){
 const result=spawnSync(process.execPath,['/private/tmp/psflow-step3-check.mjs',name,process.execPath,'parity/system/linux.mjs',...command],{env:{...process.env,PSFLOW_CHECK_DIR:'aamf/step3/order-e'},stdio:'inherit'});
 if(result.status!==0)process.exit(result.status??1);
 if(name==='linux-driver-final'){
  const freeze=spawnSync('python3',['aamf/step3/order-e/freeze-runtime.py'],{stdio:'inherit'});
  if(freeze.status!==0)process.exit(freeze.status??1);
 }
}
