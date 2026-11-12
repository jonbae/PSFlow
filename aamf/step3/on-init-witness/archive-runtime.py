from pathlib import Path
import json, tarfile
root=Path.cwd()
def archive(source,target):
 with tarfile.open(target,'w:gz') as output:
  def include(info):
   parts=Path(info.name).parts
   if any(p in ['node_modules','.git','.turbo','test-results','playwright-report'] for p in parts):return None
   if parts and parts[0]=='output' and info.isfile() and Path(info.name).suffix!='.js':return None
   if parts and parts[0]=='xyflow' and 'dist' in parts:return None
   return info
  for name in ['src','output','parity','examples','oracle','xyflow','index.js','package.json','package-lock.json','spago.yaml','spago.lock']:
   path=source/name
   if path.exists():output.add(path,arcname=name,filter=include)
  if not (source/'package-lock.json').exists():output.add(root/'package-lock.json',arcname='package-lock.json')
  for name in ['style.css','base.css']:
   file=root/f'node_modules/@xyflow/react/dist/{name}'
   output.add(file,arcname=f'node_modules/@xyflow/react/dist/{name}')
 print(target)
archive(root,root/'aamf/step3/on-init-witness/validation-runtime.tar.gz')
snapshot=json.loads((root/'aamf/step3/keyboard-driving/validation-snapshot.json').read_text())
archive(Path(snapshot['mirror']),root/'aamf/step3/keyboard-driving/validation-runtime.tar.gz')
