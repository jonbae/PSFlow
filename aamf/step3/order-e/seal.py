from pathlib import Path
import hashlib,json
p=Path('aamf/step3/order-e')
previous={line.split('  ',1)[1] for line in (p/'before-SHA256SUMS').read_text().splitlines() if line}
paths=set(previous)
for name in json.loads((p/'task.json').read_text())['allowedOutputs']:
 q=Path(name)
 if q.is_dir():paths.update(str(f) for f in q.rglob('*') if f.is_file())
 elif q.is_file():paths.add(str(q))
paths.discard('aamf/step3/SHA256SUMS')
assert previous<=paths
missing=[f for f in paths if not Path(f).is_file()];assert not missing,missing
manifest=''.join(hashlib.sha256(Path(f).read_bytes()).hexdigest()+'  '+f+'\n' for f in sorted(paths))
Path('aamf/step3/SHA256SUMS').write_text(manifest)
print('Sealed',len(paths),'files; retained all',len(previous),'prior paths')
