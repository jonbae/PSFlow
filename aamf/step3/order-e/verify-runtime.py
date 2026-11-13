from pathlib import Path
import json,hashlib,tarfile,datetime
p=Path('aamf/step3/order-e');digest=lambda q:hashlib.sha256(q.read_bytes()).hexdigest()
frozen=json.loads((p/'validation-inputs.json').read_text())
expected={**frozen['inputs'],**frozen['compiledJs'],**json.loads((p/'validation-outputs.json').read_text())}
for row in json.loads(Path('aamf/step1/inventory.json').read_text()):expected['xyflow/'+row['path']]=row['sha256']
for name in ['index.js','package.json','package-lock.json','spago.yaml','spago.lock','node_modules/@xyflow/react/dist/style.css','node_modules/@xyflow/react/dist/base.css']:expected[name]=digest(Path(name))
changes=[f for f,h in expected.items() if not Path(f).is_file() or digest(Path(f))!=h]
archived={}
with tarfile.open(p/'validation-runtime.tar.gz','r|gz') as archive:
 for info in archive:
  if info.isfile() and info.name in expected:archived[info.name]=hashlib.sha256(archive.extractfile(info).read()).hexdigest()
missing=[f for f in expected if f not in archived];wrong=[f for f,h in archived.items() if h!=expected[f]]
result={'verifiedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'frozenInputsAndOutputs':len(expected),'runtimeChanges':changes,'missingArchiveInputs':missing,'wrongArchiveHashes':wrong}
(p/'runtime-integrity.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2));assert not changes and not missing and not wrong
