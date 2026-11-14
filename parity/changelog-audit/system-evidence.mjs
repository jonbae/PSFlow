// Branch receipts for Step 4, order 8. The net remains the differential oracle;
// this register checks that the traces used to close a row contain its witness.
// A green mount or an unrelated callback cannot satisfy one of these claims.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
export const SYSTEM_EVIDENCE = JSON.parse(readFileSync(new URL('../../aamf/step4/order-8/rows.json', import.meta.url)));
const elements = node => node ? [node, ...(node.children ?? []).flatMap(elements)] : [];
const calls = (s, name) => s.callbacks.filter(c => c.name === name);
const changes = (s, type) => calls(s, 'onNodesChange').flatMap(c => c.args[0]).filter(c => c.type === type);
const attr = (s, key) => elements(s.dom.root).filter(n => key in n.attrs).map(n => n.attrs[key]);
const hasClass = (s, name) => elements(s.dom.root).some(n => n.attrs.class?.split(' ').includes(name));
const connection = s => JSON.parse(attr(s, 'data-connection-state')[0] ?? '{}');
const css = (s, selector) => s.api.queries.getComputedStyle?.[selector] ?? [];
const isGrid = (n, step) => Math.abs(n / step - Math.round(n / step)) < 1e-9;

export function assertSystemEvidence(pr, sections) {
  const row = SYSTEM_EVIDENCE[pr];
  assert.ok(row, `#${pr}: no branch receipt registered`);
  const all = row.scenarios.map(id => {
    assert.ok(sections[id], `#${pr}: missing trace ${id}`);
    return sections[id];
  });
  const s = all[0];
  const need = (condition, detail) => assert.ok(condition, `#${pr}: ${detail}`);
  for (const one of all) {
    need(one.dom.root, 'flow did not mount');
    need(one.driving.every(action => action.resolved), 'an input did not resolve');
    need(!one.console.some(e => e.level === 'pageerror'), 'consumer threw');
  }
  switch (String(pr)) {
    case '4844': need(attr(s, 'data-testid').includes('psflow-custom-flow'), 'custom wrapper id absent'); break;
    case '4855': need(attr(s, 'data-psflow-edge').includes('base-edge-path'), 'forwarded SVG attribute absent'); break;
    case '4862':
      for (const one of all) {
        const keys = calls(one, 'consumerKey');
        need(keys.length > 0 && keys.every(c => c.args[0].defaultPrevented), 'arrow default prevention unobserved');
        need(changes(one, 'position').length > 0, 'no node moved');
      }
      break;
    case '4949':
      need(attr(s, 'data-psflow-connections').some(value => {
        const edges = JSON.parse(value);
        return edges.length >= 5 && edges.some(e => e[1] === 'hub') && edges.some(e => e[2] === 'hub');
      }), 'all incident edges not rendered');
      break;
    case '4991':
      need(calls(s, 'wrapperScroll').length > 0, 'wrapper never scrolled');
      need(calls(s, 'wrapperScroll').every(c => c.args[0] === 0 && c.args[1] === 0), 'post-reset callback offsets differ');
      need(s.api.queries.wrapperScroll.top === 0 && s.api.queries.wrapperScroll.left === 0, 'wrapper scroll remains');
      break;
    case '5012': case '5722': {
      const q = s.api.queries.screenToFlowPositionOptions;
      need(q && JSON.stringify(q.inherited) !== JSON.stringify(q.unsnapped), 'store-grid default indistinguishable');
      need(JSON.stringify(q.custom) !== JSON.stringify(q.inherited), 'custom grid indistinguishable');
      need(isGrid(q.custom.x, 17) && isGrid(q.custom.y, 23), 'explicit snapGrid not observed');
      break;
    }
    case '5042':
      need(elements(s.dom.root).some(n => n.attrs['data-nodeid'] === 'target' && n.attrs.class?.includes('target') && !n.attrs.class?.includes('connectablestart')), 'end-only handle absent');
      need(calls(s, 'onConnect').some(c => c.args[0].target === 'target'), 'click connection did not complete');
      break;
    case '5043': {
      const toggle = s.driving.findIndex(e => e.dispatched?.key === 'e');
      need(toggle > s.driving.findIndex(e => e.action === 'pointerDown') && toggle < s.driving.findIndex(e => e.action === 'pointerUp'), 'expandParent did not change mid-drag');
      need(changes(s, 'replace').some(c => c.item.expandParent === false), 'current expandParent replacement absent');
      need(changes(s, 'position').length > 1, 'no drag movement around toggle');
      break;
    }
    case '5052': need(calls(s, 'onError').some(c => c.args[0] === '015' && c.args[1].includes('not initialized')), 'uninitialized error absent'); break;
    case '5120': {
      const move = s.callbacks.findIndex(c => c.name === 'onMove');
      need(move >= 0 && move < s.callbacks.findIndex(c => c.name === 'onInit'), 'initial fit without resolver unobserved');
      need(s.api.calls.filter(c => c.method === 'fitView').length === 2, 'uncontrolled refits absent');
      break;
    }
    case '5127': case '5132':
      need(s.api.calls.some(c => c.method === 'fitView' && c.result === true), 'queued fit did not settle');
      need(s.api.queries.getViewport.zoom !== 0.8, 'queued fit did not move viewport');
      if (String(pr) === '5132') need(calls(s, 'onNodesChange').length === 0, 'onNodesChange was present');
      else need(calls(s, 'onNodesChange').length > 0, 'early-return handler was absent');
      break;
    case '5139':
      need(css(s, '.react-flow')[0]?.['--xy-minimap-mask-background-color-default'].startsWith('rgba('), 'raw default rgba token absent');
      need(css(s, '.react-flow__minimap-mask')[0]?.fill.includes('0.6'), 'mask alpha absent');
      break;
    case '5148': case '5512': {
      const wheel = calls(s, 'consumerWheel');
      need(wheel.length > 0 && wheel.every(c => c.args[0].ctrlKey && c.args[0].defaultPrevented), 'ctrl-wheel prevention unobserved');
      break;
    }
    case '5153': {
      const buttons = css(s, '.react-flow__controls-button');
      need(buttons.length >= 3 && buttons.slice(0, -1).every(b => b['border-right-width'] === '1px' && b['border-bottom-width'] === '0px') && buttons.at(-1)['border-right-width'] === '0px', 'horizontal separator branch unobserved');
      break;
    }
    case '5249': need(changes(s, 'replace').length >= 2 && changes(s, 'add').length > 0, 'uncontrolled imperative change receipts absent'); break;
    case '5252': need(css(s, '.react-flow__panel').filter(p => p.transform.startsWith('matrix(')).length >= 4, 'both panel centering axes unobserved'); break;
    case '5259':
      need(attr(s, 'style').some(v => v.includes('--xy-background-color: #dd0000')), 'general background candidate absent');
      need(css(s, '.react-flow__background')[0]?.['background-color'] === 'rgb(16, 24, 32)', 'prop fallback precedence unobserved');
      break;
    case '5362':
      need(hasClass(s, 'selection'), 'no active selection');
      need(elements(s.dom.root).filter(n => n.attrs.class?.split(' ').includes('react-flow__panel')).every(n => !n.attrs.style?.includes('pointer-events')), 'Panel still sets inline pointer events');
      need(css(s, '[data-testid="nested-selection-panel"]')[0]?.['pointer-events'] === 'none', 'selection ancestor CSS branch unobserved');
      break;
    case '5368': {
      const config = s.api.queries.ariaLabelConfig;
      need(config?.['controls.zoomOut.ariaLabel'] === 'changed zoom' && config['controls.zoomIn.ariaLabel'] === 'Zoom In' && typeof config['minimap.ariaLabel'] === 'string', 'partial config merge/defaults absent');
      break;
    }
    case '5428':
      need(s.driving.some(e => e.action === 'pointerDown' && e.target === '[data-detached-hit="source"]'), 'detached child never pressed');
      need(calls(s, 'onConnectStart').length > 0 && calls(s, 'onConnect').length > 0, 'detached handle connection absent');
      break;
    case '5450': need(calls(s, 'onNodeDrag').length > s.driving.filter(e => e.action === 'pointerMove').length, 'autopan produced no extra drag receipts'); break;
    case '5455':
      need(attr(s, 'style').some(v => v.includes('display: none')), 'wrapper never hidden');
      need(s.api.queries.storeState.width === 1280 && s.api.queries.storeState.height === 720, 'hidden resize changed dimensions');
      need(!calls(s, 'onError').some(c => c.args[0] === '004'), 'hidden resize reported error004');
      break;
    case '5480':
      need(s.driving.some(e => e.dispatched?.type === 'touchEnd' && e.dispatched.points?.length === 1), 'no partial touchend');
      need(connection(s).inProgress === true, 'partial touchend cancelled connection');
      break;
    case '5546':
      need(s.api.queries.getNodes.length > 0 && s.api.queries.getNodes.every(n => n.hidden === true), 'not all nodes hidden');
      need(attr(s, 'viewBox').some(v => !/NaN|Infinity/.test(v)), 'finite minimap bounds absent');
      break;
    case '5547':
      need(calls(s, 'onMoveStart').length >= 2 && calls(s, 'onMoveStart').length === calls(s, 'onMoveEnd').length, 'unmoved pan lifecycle unpaired');
      need(s.driving.at(-1).action === 'pointerUp' && s.driving.at(-2).action === 'pointerDown', 'last gesture moved');
      break;
    case '5551': need(calls(s, 'onSelectionStart').length > 0 && calls(s, 'onSelectionEnd').length > 0 && s.driving.some(e => e.action === 'pointerDown' && e.target?.includes('node')), 'selection over node never began'); break;
    case '5578': {
      const c = connection(s);
      need(c.inProgress === true && c.pointer && c.to && JSON.stringify(c.pointer) !== JSON.stringify(c.to), 'raw pointer is not distinct from snapped handle');
      break;
    }
    case '5593':
      need(calls(s, 'onSelectionStart').length === 1 && calls(s, 'onNodeClick').length > 0, 'box plus node click absent');
      need(!hasClass(s, 'react-flow__nodesselection-rect'), 'stale group rectangle remains');
      break;
    case '5635': {
      const c = connection(s);
      need(c.fromId === 'source' && c.from?.x > 260 && c.from?.y > 160, 'connection source did not follow keyboard movement');
      need(s.driving.at(-1).action === 'pointerMove', 'post-keyboard pointer move absent');
      break;
    }
    case '5638': need(all[0].driving.some(e => e.action === 'touch') && css(all[1], '.react-flow__pane')[0]?.['touch-action'] === 'none', 'touch selection/pane style absent'); break;
    case '5682': need(changes(s, 'position').length > 0 && changes(s, 'select').length === 0, 'no-op deselection branch not observed'); break;
    case '5684':
      need(s.api.calls.some(c => c.method === 'addNodes'), 'no programmatic selection');
      need(calls(s, 'onSelectionDrag').some(c => c.args[1].some(n => n.id === 'added-1')), 'programmatically selected node not dragged');
      need(calls(s, 'onNodeClick').some(c => c.args[1].id === 'Node-4'), 'binding did not adopt the changed nodeClickDistance');
      break;
    case '5692': need(s.driving.some(e => e.dispatched?.key === 'm') && hasClass(s, 'react-flow__minimap'), 'missing-entry render not driven; see reversion receipt'); break;
    case '5704':
      need(calls(s, 'currentIsValidConnection').some(c => c.args[0] === false), 'replacement validator not called');
      need(calls(s, 'currentOnConnectEnd').some(c => c.args[0] === false && c.args[2].isValid === false), 'replacement end handler absent');
      need(calls(s, 'onConnect').length === 0, 'stale validator allowed connection');
      break;
    case '5723':
      need(['zoomIn', 'zoomOut', 'zoomTo'].every(method => s.api.calls.some(c => c.method === method && c.args.at(-1)?.interpolate === 'linear')), 'full options never supplied to all zoom methods');
      need(calls(s, 'onMove').length > s.api.calls.length, 'zoom options produced no transition frames');
      break;
    case '5727': need(s.api.queries.storeState.nodesSelectionActive === false && !hasClass(s, 'react-flow__nodesselection-rect'), 'zero-selected group state remains'); break;
    case '5733': {
      const mounted = calls(s, 'nodeConsumerEffect');
      need(mounted.length === 8 && mounted.every(c => c.args[0].nodes.length === 4 && c.args[0].lookupSize === 4), 'GraphView child effect read empty store on remount');
      break;
    }
    case '5769':
      need(calls(s, 'consumerLayoutEffect').some(c => c.args[0].changed && c.args[0].minZoom === 0.5), 'layout effect did not read pre-update state');
      need(calls(s, 'consumerEffect').some(c => c.args[0].changed && c.args[0].minZoom === 0.2), 'passive effect did not read updated state');
      break;
    case '5803':
      need(s.driving.some(e => e.dispatched?.points?.length === 2), 'no multitouch abort');
      need(changes(s, 'position').some(c => c.dragging === false), 'abort never cleared dragging');
      need(s.api.queries.getNodes.every(n => n.dragging !== true), 'a node remains dragging');
      break;
    default: assert.fail(`#${pr}: branch checker missing`);
  }
}

// Only covered rows activate these receipts. The old gate-pending rows can be
// reviewed incrementally, but graduating one requires both sides and captures.
export function systemEvidenceProblems(verdicts, { scenarioIds, readSections }) {
  const problems = [];
  for (const [pr, row] of Object.entries(SYSTEM_EVIDENCE)) {
    if (verdicts[pr]?.bucket !== 'system') continue;
    if (row.scenarios.some(id => !scenarioIds.includes(id))) {
      problems.push(`#${pr}: its recorded branch scenario is no longer in the corpus`);
      continue;
    }
    for (const side of ['upstream', 'psflow']) for (const capture of [1, 2]) {
      try {
        assertSystemEvidence(pr, Object.fromEntries(row.scenarios.map(id => [id, readSections(id, side, capture)])));
      } catch (error) {
        problems.push(`#${pr} (${side}, capture ${capture}): ${error.message}`);
      }
    }
  }
  return problems;
}
