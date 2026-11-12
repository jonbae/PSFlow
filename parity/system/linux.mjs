// Run the existing gates in Linux Chromium. On macOS, Chromium's native hover
// recomputation reads physical host modifiers, outside CDP's input state.
// No trace fields, assertions, fixtures or comparator rules change here.
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {spawn} from 'node:child_process';
const root=fileURLToPath(new URL('../../',import.meta.url));
const lock=readFileSync(new URL('../../package-lock.json',import.meta.url));
const version=JSON.parse(lock).packages['node_modules/@playwright/test'].version;
if(!/^\d+\.\d+\.\d+$/.test(version))throw Error('Expected an exact Playwright version in package-lock.json');
const image=`mcr.microsoft.com/playwright:v${version}-noble`;
const cache=`psflow-parity-linux-${createHash('sha256').update(lock).digest('hex').slice(0,16)}`;
let command=process.argv.slice(2);
if(command[0]==='--')command.shift();
if(!command.length)command=['npm','run','parity:system'];
const child=spawn('docker',[
 'run','--rm','--init','--ipc=host',
 '--mount',`type=bind,source=${root},target=/work`,
 '--mount',`type=volume,source=${cache},target=/work/node_modules`,
 '--workdir','/work',image,'sh','-c',
 'if [ ! -f node_modules/.psflow-linux-ready ]; then npm ci --ignore-scripts && touch node_modules/.psflow-linux-ready || exit; fi\nexec "$@"',
 'psflow-linux',...command,
],{stdio:'inherit'});
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>child.kill(signal));
child.on('error',error=>{console.error(error.message);process.exitCode=1;});
child.on('exit',(code)=>{process.exitCode=code??1;});
