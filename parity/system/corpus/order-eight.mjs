// Step 4, order 8 owns these corpus additions. Each supplies a condition the
// older test-debt scenario did not actually drive. Expectations remain in the
// other running library, and comparison policy is unchanged.
import { AFTER_MOUNT } from '../../driver/controls.mjs';
import { defineScenario } from '../harness/scenario.mjs';
import { routeOf } from './routes.mjs';

const node = id => `.react-flow__node[data-id="${id}"]`;
const handle = (id, type) => `${node(id)} .react-flow__handle.${type}`;
const pane = '.react-flow__pane';
const applyProps = `[data-testid="${AFTER_MOUNT}"]`;
const scenario = (id, fixture, run, extras = {}) => defineScenario({ id, route: routeOf(`./${fixture}.ts`), run, ...extras });

export const orderEightScenarios = [
  scenario('debt-css-defaults', 'chrome/debt-styles', async a => { await a.click('.react-flow__controls-zoomout'); }),
  scenario('debt-css-selection', 'chrome/debt-styles', async a => {
    await a.key('Shift', { action: 'down' });
    await a.pointerDown(pane);
    await a.pointerMove(null, { dx: 180, dy: 140 });
  }),
  scenario('debt-store-effect-timing', 'flow/store-timing', async a => { await a.click(applyProps); }),
  scenario('debt-store-remount', 'flow/remount', async a => { await a.click(applyProps); }),
  ...['ignored-changes', 'absent-handler'].map(mode =>
    scenario(`debt-fitview-${mode}`, `fitview/${mode}`, async a => {
      await a.call('setViewport', [{ x: 100, y: 100, zoom: 0.8 }]);
      await a.call('fitView', [{ padding: 0.3 }]);
    })),
  scenario('debt-focus-wrapper-scroll', 'nodes/focus-overflow', async a => {
    await a.key('Tab');
    await a.key('Tab');
  }),
  scenario('debt-viewport-option-interpolation', 'viewport/helpers', async a => {
    await a.call('setViewport', [{ x: 40, y: -20, zoom: 1.5 }]);
    await a.call('zoomIn', [{ duration: 64, interpolate: 'linear' }]);
    await a.call('zoomOut', [{ duration: 64, interpolate: 'linear' }]);
    await a.call('zoomTo', [0.7, { duration: 80, interpolate: 'linear' }]);
  }),
  scenario('debt-live-expand-parent', 'nodes/expand-parent', async a => {
    await a.pointerDown(node('child'));
    await a.pointerMove(null, { dx: 120, dy: 80 });
    await a.key('e');
    await a.pointerMove(null, { dx: 200, dy: 160 });
    await a.pointerUp(null);
  }),
  scenario('debt-click-connect-end-only', 'nodes/live-connection', async a => {
    await a.click(handle('source', 'source'));
    await a.click(handle('target', 'target'));
  }),
  scenario('debt-detached-handle', 'nodes/live-connection', async a => {
    await a.connect('[data-detached-hit="source"]', handle('target', 'target'));
  }),
  scenario('debt-live-connection-handlers', 'nodes/live-connection', async a => {
    await a.pointerDown(handle('source', 'source'));
    await a.pointerMove(null, { dx: 20, dy: 20 });
    await a.key('v');
    await a.pointerMove(handle('target', 'target'));
    await a.pointerUp(null);
  }),
  scenario('debt-connection-pointer', 'nodes/live-connection', async a => {
    await a.pointerDown(handle('source', 'source'));
    await a.pointerMove(handle('target', 'target'), { dx: 1 });
    // Same snapped handle, a different raw pointer: the old early return lost it.
    await a.pointerMove(handle('target', 'target'), { dx: 2 });
  }),
  scenario('debt-keyboard-connection-origin', 'nodes/live-connection', async a => {
    await a.click(node('source'));
    await a.pointerDown(handle('source', 'source'));
    await a.pointerMove(null, { dx: 20, dy: 20 });
    await a.arrowKeyNudge('right', { target: node('source'), times: 3 });
    await a.arrowKeyNudge('down', { times: 2 });
    // Also exercise XYHandle's refresh of the source on the next pointer move.
    await a.pointerMove(null, { dx: 5, dy: 5 });
  }),
  scenario('debt-connection-partial-touch-end', 'nodes/live-connection', async a => {
    await a.touch('start', [{ target: handle('source', 'source'), id: 1 }]);
    await a.touch('move', [{ target: handle('source', 'source'), dx: 20, dy: 30, id: 1 }]);
    await a.touch('start', [
      { target: handle('source', 'source'), dx: 20, dy: 30, id: 1 },
      { target: pane, id: 2 },
    ]);
    await a.touch('move', [
      { target: handle('source', 'source'), dx: 30, dy: 40, id: 1 },
      { target: pane, dx: 20, dy: 20, id: 2 },
    ]);
    await a.touch('end', [{ target: handle('source', 'source'), dx: 30, dy: 40, id: 1 }]);
    await a.touch('move', [{ target: handle('source', 'source'), dx: 40, dy: 50, id: 1 }]);
  }, { touch: true }),
  ...['nowheel', 'nowheel-pan-on-scroll'].map(mode =>
    scenario(`debt-ctrl-wheel-${mode}`, `nodes/${mode}`, async a => {
      await a.key('Control', { action: 'down' });
      await a.wheel(node('nowheel'), { deltaY: -120 });
      await a.key('Control', { action: 'up' });
    })),
  scenario('debt-pan-without-movement', 'pane/general', async a => {
    await a.pan({ dx: 80, dy: 60 });
    await a.pointerDown(pane);
    await a.pointerUp(null);
  }),
  scenario('debt-minimap-missing-node', 'chrome/minimap-missing', async a => { await a.key('m'); }),
  scenario('debt-selection-cleared-by-nodes', 'nodes/selection-state', async a => {
    await a.selectionBox(
      { target: node('Node-1'), origin: 'topLeft', dx: -30, dy: -30 },
      { target: node('Node-3'), origin: 'topLeft', dx: 180, dy: 130 });
    for (const id of ['Node-1', 'Node-2', 'Node-3', 'Node-4']) await a.call('updateNode', [id, { selected: false }]);
  }),
  scenario('debt-selection-keyboard', 'nodes/selection-state', async a => {
    await a.selectionBox(
      { target: node('Node-1'), origin: 'topLeft', dx: -30, dy: -30 },
      { target: node('Node-3'), origin: 'topLeft', dx: 180, dy: 130 });
    await a.arrowKeyNudge('down', { times: 2 });
  }),
  scenario('debt-selection-click-node', 'nodes/selection-on-drag', async a => {
    await a.selectionBox(
      { target: node('Node-1'), origin: 'topLeft', dx: -30, dy: -30 },
      { target: node('Node-3'), origin: 'topLeft', dx: 180, dy: 130 }, { modifier: null });
    await a.click(node('Node-4'));
  }),
  scenario('debt-programmatic-selection-drag', 'nodes/selection-state', async a => {
    await a.selectionBox(
      { target: node('Node-1'), origin: 'topLeft', dx: -30, dy: -30 },
      { target: node('Node-3'), origin: 'topLeft', dx: 180, dy: 130 });
    await a.call('addNodes', [[
      { id: 'added-1', data: { label: 'added 1' }, position: { x: 200, y: 220 }, selected: true },
      { id: 'added-2', data: { label: 'added 2' }, position: { x: 300, y: 280 }, selected: true },
    ]]);
    await a.dragNode('.react-flow__nodesselection-rect', { dx: 50, dy: 20 });
    await a.click({ target: pane, origin: 'topLeft', dx: 20, dy: 20 });
    await a.click(applyProps);
    // #5684 also added nodeClickDistance to the binding effect's dependencies.
    // A short drag now retains its native click; the old d3 binding suppressed it.
    await a.dragNode(node('Node-4'), { dx: 8, dy: 0, steps: 2 });
  }),
  scenario('debt-abort-touch-drag', 'nodes/selection-state', async a => {
    await a.touch('start', [{ target: node('Node-1'), id: 1 }]);
    await a.touch('move', [{ target: node('Node-1'), dx: 20, dy: 20, id: 1 }]);
    await a.touch('start', [
      { target: node('Node-1'), id: 1 }, { target: node('Node-3'), id: 2 },
    ]);
    await a.touch('move', [
      { target: node('Node-1'), dx: 20, dy: 20, id: 1 }, { target: node('Node-3'), dx: 20, dy: 20, id: 2 },
    ]);
    await a.touch('end', []);
  }, { touch: true }),
];
