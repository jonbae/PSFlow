// Direct exported pure-helper call, compared with the pinned source.
import assert from 'node:assert/strict';
import {buildSync} from 'esbuild';
import {getResizeDirection} from '../../../output/System.XYResizer.Utils/index.js';
const result=buildSync({entryPoints:['xyflow/packages/system/src/xyresizer/utils.ts'],bundle:true,write:false,format:'cjs',platform:'node',logLevel:'silent'});
const module={exports:{}};
new Function('module','exports',result.outputFiles[0].text)(module,module.exports);
const input={width:NaN,prevWidth:1,height:2,prevHeight:1,affectsX:true,affectsY:false};
const actual=getResizeDirection(input);
assert.deepStrictEqual([actual.dx,actual.dy],module.exports.getResizeDirection(input),'NaN is falsy and must not invert a zero direction');
console.log('NaN resize direction agrees with source');
