from pathlib import Path
import tarfile
root=Path.cwd();target=root/'aamf/step3/initialization-driving/validation-runtime.tar.gz'
with tarfile.open(target,'w:gz') as archive:
 def include(info):
  parts=Path(info.name).parts
  if any(p in ['node_modules','.git','.turbo','test-results','playwright-report'] for p in parts):return None
  if parts and parts[0]=='output' and info.isfile() and Path(info.name).suffix!='.js':return None
  if parts and parts[0]=='xyflow' and 'dist' in parts:return None
  return info
 for name in ['src','output','parity','examples','oracle','xyflow','index.js','package.json','package-lock.json','spago.yaml','spago.lock']:
  if (root/name).exists():archive.add(root/name,arcname=name,filter=include)
 for name in ['style.css','base.css']:
  path=root/f'node_modules/@xyflow/react/dist/{name}';archive.add(path,arcname=f'node_modules/@xyflow/react/dist/{name}')
print(target)
