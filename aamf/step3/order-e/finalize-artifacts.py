from pathlib import Path
import json,hashlib
p=Path('aamf/step3/order-e');digest=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
traces=sorted(Path('parity/system/traces').glob('*.json'));assert len(traces)==428
paths=traces+[Path(f) for f in ['parity/system/report.md','parity/system/coverage.md','parity/changelog-audit/report.md']]
(p/'validation-outputs.json').write_text(json.dumps({str(f):digest(f) for f in paths},indent=2)+'\n')
print('Recorded',len(paths),'canonical output hashes')
