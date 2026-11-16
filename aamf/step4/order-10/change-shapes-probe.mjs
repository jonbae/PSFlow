import * as upstream from '@xyflow/react';
import * as psflow from '../../../index.js';
const nodes = () => [{ id: 'a', position: { x: 0, y: 0 }, data: {} }, { id: 'b', position: { x: 1, y: 1 }, data: {} }, { id: 'c', position: { x: 2, y: 2 }, data: {} }];
const edges = () => [{ id: 'a', source: 'x', target: 'y' }, { id: 'b', source: 'x', target: 'y' }, { id: 'c', source: 'x', target: 'y' }];
const run = (label, changes, kind = 'node') => {
  const out = [upstream, psflow].map((lib) => {
    try { return JSON.stringify(kind === 'node' ? lib.applyNodeChanges(changes(), nodes()) : lib.applyEdgeChanges(changes(), edges())); }
    catch (e) { return 'THREW ' + e.message; }
  });
  console.log(out[0] === out[1] ? 'ok  ' : 'DIFF', label, out[0] === out[1] ? '' : `\n  UP ${out[0]}\n  PS ${out[1]}`);
};
for (const kind of ['node', 'edge']) {
  const item = kind === 'node' ? { id: 'n', position: { x: 9, y: 9 }, data: {} } : { id: 'n', source: 'p', target: 'q' };
  for (const index of [0, 1, 1.5, 2.5, 0.5, -1, -1.5, NaN, 10, Infinity, -Infinity, undefined, 1e10, -0])
    run(`${kind} add index ${index}`, () => [{ type: 'add', item, index }], kind);
  run(`${kind} add no index key`, () => [{ type: 'add', item }], kind);
  run(`${kind} two adds`, () => [{ type: 'add', item, index: 1 }, { type: 'add', item: { ...item, id: 'm' }, index: 1 }], kind);
  run(`${kind} select undefined`, () => [{ type: 'select', id: 'a' }], kind);
  run(`${kind} remove then select`, () => [{ type: 'remove', id: 'a' }, { type: 'select', id: 'a', selected: true }], kind);
  run(`${kind} select then remove`, () => [{ type: 'select', id: 'a', selected: true }, { type: 'remove', id: 'a' }], kind);
  run(`${kind} replace then select`, () => [{ type: 'replace', id: 'a', item: { ...item, id: 'a' } }, { type: 'select', id: 'a', selected: true }], kind);
  run(`${kind} change missing id`, () => [{ type: 'select', id: 'zz', selected: true }], kind);
}
for (const sa of [true, false, 'width', 'height', undefined]) run(`dimensions setAttributes ${sa}`, () => [{ type: 'dimensions', id: 'a', dimensions: { width: 5, height: 6 }, setAttributes: sa }]);
run('dimensions no dimensions, resizing', () => [{ type: 'dimensions', id: 'a', resizing: true }]);
run('dimensions resizing non-boolean', () => [{ type: 'dimensions', id: 'a', dimensions: { width: 1, height: 2 }, resizing: undefined }]);
run('dimensions setAttributes w/o dimensions', () => [{ type: 'dimensions', id: 'a', setAttributes: true }]);
run('position only dragging', () => [{ type: 'position', id: 'a', dragging: true }]);
run('position positionAbsolute only', () => [{ type: 'position', id: 'a', positionAbsolute: { x: 3, y: 3 } }]);
run('position undefined position', () => [{ type: 'position', id: 'a', position: undefined, dragging: false }]);
