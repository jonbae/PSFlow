from pathlib import Path
import json,hashlib,subprocess,tarfile,datetime
p=Path('aamf/step3/shared-handle-timing');digest=lambda q:hashlib.sha256(q.read_bytes()).hexdigest()
before=json.loads((p/'before-inputs.json').read_text());task=json.loads((p/'task.json').read_text());owned=task['allowedOutputs']
allows=lambda f:any(f==x or (x.endswith('/') and f.startswith(x)) for x in owned)
generated=lambda f:f.startswith('test-results/')
changed=[f for f,h in before.items() if not Path(f).is_file() or digest(Path(f))!=h]
files=set(subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z']).decode().split('\0'))
new=sorted(f for f in files if f and Path(f).is_file() and f not in before)
frozen=json.loads((p/'validation-inputs.json').read_text());runtime={**frozen['inputs'],**frozen['compiledJs']}
runtime_changes=[f for f,h in runtime.items() if not Path(f).is_file() or digest(Path(f))!=h]
vendor=json.loads(Path('aamf/step1/inventory.json').read_text());vendor_changes=[r['path'] for r in vendor if digest(Path('xyflow')/r['path'])!=r['sha256']]
canonical={f:h for f,h in before.items() if f.startswith('parity/system/traces/') or f in ['parity/system/report.md','parity/system/coverage.md']}
archived={}
with tarfile.open(p/'before-canonical-checkpoint.tar.gz','r|gz') as archive:
 for info in archive:
  if info.isfile():archived[info.name]=hashlib.sha256(archive.extractfile(info).read()).hexdigest()
assert archived==canonical,'prior 430-file checkpoint must match its original input hashes'
prior_evidence=[f for f in changed if f.startswith('aamf/step3/') and f not in ['aamf/step3/README.md','aamf/step3/SHA256SUMS']]
result={'verifiedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'changedExistingInputs':changed,'newOwnedInputs':[f for f in new if allows(f)],'generatedBrowserOutputs':[f for f in new+changed if generated(f)],'unexpectedChanges':[f for f in changed if not allows(f) and not generated(f)],'unexpectedNewInputs':[f for f in new if not allows(f) and not generated(f)],'frozenRuntimeChanges':runtime_changes,'certifiedVendoredFiles':len(vendor),'vendoredChanges':vendor_changes,'priorCanonicalArchiveFilesVerified':len(archived),'priorEvidenceChanges':prior_evidence}
(p/'source-audit.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:len(v) if isinstance(v,list) else v for k,v in result.items()},indent=2))
assert not any(result[k] for k in ['unexpectedChanges','unexpectedNewInputs','frozenRuntimeChanges','vendoredChanges','priorEvidenceChanges'])
