from pathlib import Path
import tarfile,json,hashlib,datetime
p=Path('aamf/step3/initialization-driving');rows=[]
for archive_name,snapshot_name,prefixes in [
 ('diagnostic-runtime.tar.gz','diagnostic-snapshot.json',None),
 ('mount-only-checkpoint.tar.gz','mount-only-validation-snapshot.json',('src/','output/','parity/system/harness/','parity/driver/')),
 ('validation-runtime.tar.gz','validation-snapshot.json',None),
]:
 snapshot=json.loads((p/snapshot_name).read_text());expected={f:h for f,h in snapshot['sha256'].items() if not prefixes or f.startswith(prefixes)}
 if archive_name=='validation-runtime.tar.gz':expected |= snapshot['vendoredSha256']
 found={};canonical={}
 with tarfile.open(p/archive_name,'r|gz') as source:
  for member in source:
   if not member.isfile():continue
   if member.name in expected or member.name.startswith('parity/system/traces/') or member.name in ['parity/system/report.md','parity/system/coverage.md']:
    h=hashlib.sha256(source.extractfile(member).read()).hexdigest()
    if member.name in expected:found[member.name]=h
    if archive_name=='validation-runtime.tar.gz' and (member.name.startswith('parity/system/traces/') or member.name in ['parity/system/report.md','parity/system/coverage.md']):canonical[member.name]=h
 mismatches=[f for f,h in expected.items() if found.get(f)!=h];assert not mismatches,(archive_name,mismatches[:10])
 if canonical:
  assert len(canonical)==430
  assert all(hashlib.sha256(Path(f).read_bytes()).hexdigest()==h for f,h in canonical.items())
 rows.append({'archive':archive_name,'verifiedInputs':len(expected),'mismatches':mismatches,'currentCheckpointFiles':len(canonical)})
(p/'archive-integrity.json').write_text(json.dumps({'verifiedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'archives':rows},indent=2)+'\n');print(json.dumps(rows,indent=2))
