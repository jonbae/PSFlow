// The declaration pipeline's steps, on small inputs. `check.mjs` holds the
// built package; this file holds the rules it was built by.
import assert from 'node:assert/strict';
import test from 'node:test';

import { link, overlay, reachable, relayout, specifiers } from './declarations.mjs';
import { NOTES, OVERLAYS } from './gaps.mjs';

const tree = (entries) => new Map(Object.entries(entries));

test('relayout drops each package\'s src directory', () => {
  const out = relayout(tree({ 'react/src/index.d.ts': 'a', 'system/src/types/edges.d.ts': 'b' }));
  assert.deepEqual([...out.keys()], ['react/index.d.ts', 'system/types/edges.d.ts']);
  assert.throws(() => relayout(tree({ 'react/lib/index.d.ts': '' })), /unexpected emitted path/);
});

test('specifiers finds import, export and import-type specifiers with their positions', () => {
  const text = [
    "import { A } from './a';",
    "export { B } from '../b';",
    'export * from "./c";',
    "declare const d: import('react').ReactNode;",
    "/** import { X } from 'ignored'; */",
  ].join('\n');
  const found = specifiers('x/y.d.ts', text);
  assert.deepEqual(
    found.map((s) => s.text),
    ['./a', '../b', './c', 'react']
  );
  for (const { text: specifier, start, end } of found) assert.equal(text.slice(start, end), specifier);
});

test('link names every file, maps the system package, and keeps other bare specifiers', () => {
  const { files, external } = link(
    tree({
      'react/index.d.ts': [
        "export * from './types';",
        "export { Hook } from './hooks/useStore';",
        "export { type Viewport } from '@xyflow/system';",
        "import type { ReactNode } from 'react';",
        '/** import { ReactFlow } from \'@xyflow/react\'; */',
      ].join('\n'),
      'react/types/index.d.ts': "export * from './store';",
      'react/types/store.d.ts': "export * from './'; declare const s: import('..').State;",
      'react/hooks/useStore.d.ts': "export * from '../types/index';",
      'system/index.d.ts': '',
    })
  );
  assert.equal(
    files.get('react/index.d.ts'),
    [
      "export * from './types/index.js';",
      "export { Hook } from './hooks/useStore.js';",
      "export { type Viewport } from '../system/index.js';",
      "import type { ReactNode } from 'react';",
      "/** import { ReactFlow } from 'ps-flow'; */",
    ].join('\n')
  );
  assert.equal(
    files.get('react/types/store.d.ts'),
    "export * from './index.js'; declare const s: import('../index.js').State;"
  );
  assert.equal(files.get('react/hooks/useStore.d.ts'), "export * from '../types/index.js';");
  assert.deepEqual([...external.get('react/index.d.ts')], ['react']);
});

test('link refuses a relative specifier that names no emitted file', () => {
  assert.throws(() => link(tree({ 'react/index.d.ts': "export * from './missing';" })), /names no emitted declaration/);
});

test('reachable follows rewritten specifiers from the entry and nothing else', () => {
  const files = tree({
    'react/index.d.ts': "export * from './a.js';",
    'react/a.d.ts': "import type { S } from '../system/index.js';",
    'react/internal.d.ts': "import type { StoreApi } from 'zustand';",
    'system/index.d.ts': '',
  });
  assert.deepEqual([...reachable(files, 'react/index.d.ts')].sort(), [
    'react/a.d.ts',
    'react/index.d.ts',
    'system/index.d.ts',
  ]);
});

test('an overlay applies once, and fails as stale or ambiguous otherwise', () => {
  const files = tree({ 'f.d.ts': 'replace?: boolean;' });
  const edit = { id: 'x', file: 'f.d.ts', find: 'boolean', replace: 'false' };
  assert.equal(overlay(files, [edit]).get('f.d.ts'), 'replace?: false;');
  assert.equal(files.get('f.d.ts'), 'replace?: boolean;', 'the input is left as it was');
  assert.throws(() => overlay(files, [{ ...edit, find: 'number' }]), /found it 0 times; it is stale/);
  assert.throws(() => overlay(tree({ 'f.d.ts': 'boolean boolean' }), [edit]), /found it 2 times/);
  assert.throws(() => overlay(files, [{ ...edit, file: 'g.d.ts' }]), /not in the published declarations/);
});

test('an overlay replacement is inserted literally', () => {
  const files = tree({ 'f.d.ts': 'a' });
  assert.equal(overlay(files, [{ id: 'x', file: 'f.d.ts', find: 'a', replace: "$& $' $$" }]).get('f.d.ts'), "$& $' $$");
});

test('every gap names the work that accepted it, and ids are unique', () => {
  const ids = [...OVERLAYS, ...NOTES].map(({ id }) => id);
  assert.equal(new Set(ids).size, ids.length);
  for (const gap of [...OVERLAYS, ...NOTES]) assert.match(gap.accepted, /^Step 3 [A-I]/, gap.id);
  for (const { id, file, find, replace, reason } of OVERLAYS) {
    for (const [field, value] of Object.entries({ file, find, replace, reason })) {
      assert.equal(typeof value, 'string', `${id}.${field}`);
    }
  }
  for (const { id, text } of NOTES) assert.equal(typeof text, 'string', id);
});
