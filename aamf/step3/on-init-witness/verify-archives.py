from pathlib import Path
import tarfile,json,hashlib,datetime
rows=[]
for name in ['keyboard-driving','on-init-witness']:
 folder=Path('aamf/step3')/name;s=json.loads((folder/'validation-snapshot.json').read_text())
 # Runtime archives intentionally contain compiled JS, not compiler caches,
 # generated documentation, source maps or externs. All originals remain in
 # the complete frozen-input integrity check; none is silently reclassified.
 all_inputs=s['sha256']|s['vendoredSha256']
 expected={p:h for p,h in all_inputs.items() if not p.startswith('output/') or p.endswith('.js')}
 with tarfile.open(folder/'validation-runtime.tar.gz') as t:
  members={m.name:m for m in t.getmembers() if m.isfile()}
  mismatches=[p for p,h in expected.items() if p not in members or hashlib.sha256(t.extractfile(members[p]).read()).hexdigest()!=h]
  assert not mismatches,{'task':name,'mismatches':mismatches[:10]}
  if name=='on-init-witness':
   checkpoint=[p for p in members if p.startswith('parity/system/traces/') or p in ['parity/system/report.md','parity/system/coverage.md']]
   assert len(checkpoint)==430
   assert all(hashlib.sha256(t.extractfile(members[p]).read()).hexdigest()==hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in checkpoint)
  rows.append({'task':name,'verifiedSourceAndCompiledJsInputs':len(expected),'compilerCacheArtifactsDeliberatelyNotArchived':len(all_inputs)-len(expected),'mismatches':mismatches})
Path('aamf/step3/on-init-witness/archive-integrity.json').write_text(json.dumps({'verifiedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'archives':rows,'freshCanonicalCheckpointFiles':430},indent=2)+'\n')
print(json.dumps(rows,indent=2))
