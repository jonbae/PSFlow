import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { SYSTEM_EVIDENCE, assertSystemEvidence, systemEvidenceProblems } from './system-evidence.mjs';

const readSections = (id, side = 'upstream', capture = 1) => JSON.parse(readFileSync(
  new URL(`../system/traces/${id}.${side}.capture${capture}.json`, import.meta.url)
)).sections;
const sectionsFor = row => Object.fromEntries(row.scenarios.map(id => [id, readSections(id)]));
const walk = node => node ? [node, ...(node.children ?? []).flatMap(walk)] : [];
const removeCalls = (s, name) => { s.callbacks = s.callbacks.filter(c => c.name !== name); };
const eraseAttr = (s, key) => { for (const node of walk(s.dom.root)) delete node.attrs[key]; };
const eraseCss = s => { s.api.queries.getComputedStyle = {}; };
const eraseQuery = s => { delete s.api.queries.screenToFlowPositionOptions; };
const faults = {
  4844: s => eraseAttr(s, 'data-testid'),
  4855: s => eraseAttr(s, 'data-psflow-edge'),
  4862: s => removeCalls(s, 'consumerKey'),
  4949: s => eraseAttr(s, 'data-psflow-connections'),
  4991: s => removeCalls(s, 'wrapperScroll'),
  5012: eraseQuery,
  5042: s => removeCalls(s, 'onConnect'),
  5043: s => { s.driving = s.driving.filter(e => e.dispatched?.key !== 'e'); },
  5052: s => removeCalls(s, 'onError'),
  5120: s => removeCalls(s, 'onMove'),
  5127: s => { s.api.calls = []; },
  5132: s => { s.api.calls = []; },
  5139: eraseCss,
  5148: s => removeCalls(s, 'consumerWheel'),
  5153: eraseCss,
  5249: s => removeCalls(s, 'onNodesChange'),
  5252: eraseCss,
  5259: eraseCss,
  5362: eraseCss,
  5368: s => { s.api.queries.ariaLabelConfig = {}; },
  5428: s => removeCalls(s, 'onConnectStart'),
  5450: s => removeCalls(s, 'onNodeDrag'),
  5455: s => { s.api.queries.storeState.width = 500; },
  5480: s => { s.driving = s.driving.filter(e => e.dispatched?.type !== 'touchEnd'); },
  5512: s => removeCalls(s, 'consumerWheel'),
  5546: s => { s.api.queries.getNodes = []; },
  5547: s => removeCalls(s, 'onMoveEnd'),
  5551: s => removeCalls(s, 'onSelectionStart'),
  5578: s => eraseAttr(s, 'data-connection-state'),
  5593: s => removeCalls(s, 'onNodeClick'),
  5635: s => eraseAttr(s, 'data-connection-state'),
  5638: (_s, all) => eraseCss(Object.values(all)[1]),
  5682: s => removeCalls(s, 'onNodesChange'),
  5684: s => removeCalls(s, 'onSelectionDrag'),
  5692: s => { s.driving = s.driving.filter(e => e.dispatched?.key !== 'm'); },
  5704: s => removeCalls(s, 'currentIsValidConnection'),
  5722: eraseQuery,
  5723: s => removeCalls(s, 'onMove'),
  5727: s => { s.api.queries.storeState.nodesSelectionActive = true; },
  5733: s => removeCalls(s, 'nodeConsumerEffect'),
  5769: s => removeCalls(s, 'consumerLayoutEffect'),
  5803: s => { s.driving = s.driving.filter(e => e.dispatched?.points?.length !== 2); },
};

test('the 42 retired system rows each retain a distinct branch receipt', () => {
  assert.equal(Object.keys(SYSTEM_EVIDENCE).length, 42);
  assert.deepEqual(Object.keys(faults), Object.keys(SYSTEM_EVIDENCE));
  const verdicts = JSON.parse(readFileSync(new URL('./verdicts.json', import.meta.url)));
  for (const pr of Object.keys(SYSTEM_EVIDENCE)) assert.equal(verdicts[pr].bucket, 'system', `#${pr}`);
});

for (const [pr, row] of Object.entries(SYSTEM_EVIDENCE)) {
  test(`#${pr}: both sides and captures contain the changed branch's observable`, () => {
    for (const side of ['upstream', 'psflow']) for (const capture of [1, 2]) {
      assertSystemEvidence(pr, Object.fromEntries(row.scenarios.map(id => [id, readSections(id, side, capture)])));
    }
  });
  test(`#${pr}: removing its branch observable rejects an otherwise passing trace`, () => {
    const sections = sectionsFor(row);
    faults[pr](sections[row.scenarios[0]], sections);
    assert.throws(() => assertSystemEvidence(pr, sections));
  });
}

test('a retired row cannot silently outlive its scenario or a capture', () => {
  const verdicts = { 4844: { bucket: 'system' } };
  assert.match(systemEvidenceProblems(verdicts, { scenarioIds: [], readSections })[0], /no longer in the corpus/);
  assert.equal(systemEvidenceProblems(verdicts, { scenarioIds: ['flow-custom-testid'], readSections: () => { throw Error('capture missing'); } }).length, 4);
});
