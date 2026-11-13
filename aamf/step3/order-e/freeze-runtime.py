from pathlib import Path
import json,hashlib,datetime
p=Path('aamf/step3/order-e')
old=json.loads(Path('aamf/step3/shared-handle-timing/validation-inputs.json').read_text())
files=set(old['inputs']);files.add('parity/system/linux.mjs')
for folder in ['src','test','parity/system/harness']:
 for f in Path(folder).rglob('*'):
  if f.is_file() and f.suffix in ['.purs','.js','.mjs','.json']:files.add(str(f))
digest=lambda f:hashlib.sha256(Path(f).read_bytes()).hexdigest()
compiled={str(f):digest(f) for f in sorted(Path('output').rglob('*.js'))}
r={'frozenAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'inputs':{f:digest(f) for f in sorted(files)},'compiledJs':compiled,'vendoredFiles':old['vendoredFiles']}
(p/'validation-inputs.json').write_text(json.dumps(r,indent=2)+'\n')
print('Frozen',len(files),'source/apparatus inputs and',len(compiled),'compiled JS files')
