// Run only in an explicit disposable copy. Every port mutation is recorded,
// rebuilt, captured with the real net, and restored even on failure.
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { resolve, relative } from 'node:path';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';

const scratch = resolve(process.argv[2] ?? '');
if (!existsSync(resolve(scratch, '.order8-probe-scratch'))) throw Error('Expected an explicitly marked disposable copy');
const group = process.argv[3] ?? 'reverts';
const out = group === 'reverts' ? 'aamf/step4/order-8/probes' : `aamf/step4/order-8/probes-${group}`;
mkdirSync(resolve(scratch, out), { recursive: true });
const originals = new Map();
const mutations = [];
const mutate = (pr, file, before, after, scenario) => {
  const path = resolve(scratch, file);
  const source = readFileSync(path, 'utf8');
  if (!originals.has(path)) originals.set(path, source);
  if (source.split(before).length !== 2) throw Error(`#${pr}: expected exactly one match in ${file}`);
  writeFileSync(path, source.replace(before, after));
  mutations.push({ pr, file, before, after, scenario });
};
const run = (cmd, args) => {
  const child = spawnSync(cmd, args, { cwd: scratch, stdio: 'inherit', env: process.env });
  if (child.error) throw child.error;
  return child.status;
};
try {
  if (group === 'reverts') {
  mutate(4991, 'src/React/FFI/DOM.js',
    'event.currentTarget.scrollTo({ top: 0, left: 0, behavior: "instant" });',
    '/* reverted wrapper scroll reset */', 'debt-focus-wrapper-scroll');
  mutate(5043, 'src/React/Store/Reduce.purs',
    'Just node | node.expandParent == Just true -> node.parentId',
    'Just node | item.expandParent == Just true -> node.parentId', 'debt-live-expand-parent');
  mutate(5428, 'src/System/XYHandle.purs',
    'hType <- getHandleType params.edgeUpdaterType (Just params.handleDomNode)',
    'clicked <- elementFromPointOnDoc doc evPos.x evPos.y\n  hType <- getHandleType params.edgeUpdaterType clicked', 'debt-detached-handle');
  mutate(5455, 'src/React/Hook/ResizeHandler.js',
    'element.checkVisibility?.() ?? true', 'true', 'mount-in-display-none');
  mutate(5635, 'src/System/XYHandle.purs',
    'nodeLookup <- params.getNodeLookup', 'let nodeLookup = params.nodeLookup', 'debt-keyboard-connection-origin');
  mutate(5692, 'src/React/Additional/MiniMap/Nodes.purs',
    'import Prelude', 'import Prelude\nimport Partial.Unsafe (unsafePartial)\nimport Data.Maybe (fromJust)', 'debt-minimap-missing-node');
  mutate(5692, 'src/React/Additional/MiniMap/Nodes.purs',
    'mapMaybe (\\node -> Map.lookup node.id s.nodeLookup) s.nodes',
    'map (\\node -> unsafePartial (fromJust (Map.lookup node.id s.nodeLookup))) s.nodes', 'debt-minimap-missing-node');
  for (const [fragment, replacement] of [
    ['current <- store.getState\n                for_ current.onConnectEnd', 'let current = state\n                for_ current.onConnectEnd'],
    ['current <- store.getState\n                  pure case current.isValidConnection', 'let current = state\n                  pure case current.isValidConnection'],
  ]) mutate(5704, 'src/React/Handle.purs', fragment, replacement, 'debt-live-connection-handlers');
  mutate(5727, 'src/React/Store/Reduce.purs',
    'nodesSelectionActive = state.nodesSelectionActive && r.hasSelectedNodes',
    'nodesSelectionActive = state.nodesSelectionActive', 'debt-selection-cleared-by-nodes');
  mutate(5803, 'src/System/XYDrag.purs',
    '  when (s0.abortDrag && Array.length s0.dragItems > 0) do\n    store <- liftEffect params.getStoreItems\n    liftEffect (store.updateNodePositions s0.dragItems false)\n',
    '', 'debt-abort-touch-drag');
  } else if (group === 'branches') {
    mutate(5042, 'src/React/Handle.purs', 'when (canStart || haveStart) do', 'when canStart do', 'debt-click-connect-end-only');
    mutate(5127, 'src/React/Provider/Batch.purs',
      'refitNextFrame: Array.null changes && s.fitViewQueued', 'refitNextFrame: false', 'debt-fitview-ignored-changes');
    // Same no-change path, now with the literal absent-handler condition.
    mutations.push({ pr: 5132, scenario: 'debt-fitview-absent-handler', sharedWith: 5127 });
    mutate(5148, 'src/System/XYPanZoom/EventHandler.purs',
      'when (ctrl && isWheel && insideNoWheel) (sourceEventPreventDefault event)', 'pure unit', 'debt-ctrl-wheel-nowheel');
    mutate(5480, 'src/System/XYHandle.purs',
      'unless multi $ runOnRef stateRef do', 'unless false $ runOnRef stateRef do', 'debt-connection-partial-touch-end');
    mutate(5512, 'src/System/XYPanZoom/EventHandler.purs',
      'when ctrl (sourceEventPreventDefault event)', 'pure unit', 'debt-ctrl-wheel-nowheel-pan-on-scroll');
    mutate(5578, 'src/System/XYHandle.purs', ', pointer = curPos', ', pointer = prev.pointer', 'debt-connection-pointer');
    mutate(5733, 'src/React/Container/ReactFlow.purs',
      '[ storeUpdaterEl\n          , graphViewEl', '[ graphViewEl\n          , storeUpdaterEl', 'debt-store-remount');
  } else if (group === 'drag-distance') {
    mutate(5684, 'src/React/Hook/Drag.purs',
      ', nodeClickDistance: opts.nodeClickDistance\n  }', ', nodeClickDistance: 0.0\n  }', 'debt-programmatic-selection-drag');
  } else if (group === 'timing') {
    const file = 'src/React/Provider/StoreUpdater.purs';
    const path = resolve(scratch, file);
    const source = readFileSync(path, 'utf8');
    originals.set(path, source);
    const changed = source.replaceAll('useEffect', 'useLayoutEffect').replaceAll('UseEffect', 'UseLayoutEffect');
    writeFileSync(path, changed);
    mutations.push({ pr: 5769, file, before: 'useEffect / useEffectOnce / UseEffect', after: 'useLayoutEffect / useLayoutEffectOnce / UseLayoutEffect', scenario: 'debt-store-effect-timing' });
  } else throw Error(`Unknown probe group: ${group}`);
  writeFileSync(resolve(scratch, out, 'mutations.json'), JSON.stringify({
    sources: [...originals].map(([file, source]) => ({ file: relative(scratch, file), sha256: createHash('sha256').update(source).digest('hex') })),
    mutations,
  }, null, 2) + '\n');
  if (run('spago', ['build'])) throw Error('The mutant failed to compile; no behavior claim is possible');
  const scenarios = [...new Set(mutations.map(m => m.scenario))];
  run(process.execPath, ['parity/system/linux.mjs', 'node', 'aamf/step4/order-8/capture.mjs', `${out}/red`, ...scenarios]);
  const results = JSON.parse(readFileSync(resolve(scratch, out, 'red/results.json')));
  const survivors = results.filter(r => r.ok);
  writeFileSync(resolve(scratch, out, 'summary.json'), JSON.stringify({
    probes: scenarios.length, rejected: results.filter(r => !r.ok).length, survivors,
    results: results.map(r => ({ scenario: r.scenario, ok: r.ok, failures: r.failures?.map(f => f.class), error: r.error })),
  }, null, 2) + '\n');
  if (survivors.length) throw Error(`Probe survived: ${survivors.map(r => r.scenario).join(', ')}`);
} finally {
  for (const [file, source] of originals) writeFileSync(file, source);
}
