from pathlib import Path
import json, hashlib, tarfile, subprocess, datetime

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
p=Path('aamf/step3/initialization-driving')
snapshot=json.loads((p/'validation-snapshot.json').read_text())
runtime_changes=[f for f,h in snapshot['sha256'].items() if not Path(f).is_file() or digest(Path(f))!=h]
certified=json.loads(Path('aamf/step1/inventory.json').read_text())
vendored_changes=[r['path'] for r in certified if digest(Path('xyflow')/r['path'])!=r['sha256']]
before=json.loads(Path('aamf/step3/initialization-driving/before-inputs.json').read_text())
changes=[f for f,h in before.items() if not Path(f).is_file() or digest(Path(f))!=h]
allowed={'AAMF_PORTING_PLAN.md','AAMF_STEP3_RESULTS.md','aamf/step3/README.md','aamf/step3/SHA256SUMS','parity/system/harness/port.mjs','parity/system/harness/port.test.mjs','parity/system/harness/live.spec.mjs','parity/system/harness/scenario.mjs','parity/system/harness/scenario.test.mjs','parity/system/harness/fake-port.mjs','parity/system/README.md','parity/driver/dist/psflow.js','parity/system/report.md','parity/system/coverage.md','parity/surface/report.md','parity/changelog-audit/report.md'}
unexpected=[f for f in changes if f not in allowed and not f.startswith('parity/system/traces/')]
files=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z']).decode().split('\0')
new=[f for f in files if f and Path(f).is_file() and f not in before]
unexpected_new=[f for f in new if not f.startswith(('aamf/step3/initialization-driving/',))]
with tarfile.open(p/'before-canonical-checkpoint.tar.gz') as archive:
 archived={m.name:hashlib.sha256(archive.extractfile(m).read()).hexdigest() for m in archive.getmembers() if m.isfile()}
 old_checkpoint={f:h for f,h in before.items() if f.startswith('parity/system/traces/') or f in ['parity/system/report.md','parity/system/coverage.md']}
 assert archived==old_checkpoint,'prior canonical checkpoint must be exactly preserved'
result={'verifiedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'changedExistingInputs':changes,'newOwnedInputs':new,'unexpectedChanges':unexpected,'unexpectedNewInputs':unexpected_new,'frozenRuntimeChanges':runtime_changes,'certifiedVendoredFiles':len(certified),'vendoredChanges':vendored_changes,'priorCheckpointFilesVerified':len(archived),'priorEvidenceChanges':[f for f in changes if f.startswith('aamf/step3/') and f not in allowed]}
(p/'source-audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:(len(v) if isinstance(v,list) else v) for k,v in result.items()},indent=2))
assert not unexpected and not unexpected_new and not runtime_changes and not vendored_changes and not result['priorEvidenceChanges']
