// A JS-entry regression: the existing geometry properties call below the
// boundary and cannot catch a function returned by a six-argument JS call.
import assert from 'node:assert/strict';
import test from 'node:test';
// Rebuild with npm run build:oracle so the witness is the vendored source.
import { getViewportForBounds as upstream } from '../../oracle/index.js';
import { getViewportForBounds as psflow } from '../../index.js';

const bounds = { x: -120, y: 35, width: 400, height: 180 };
const base = [bounds, 800, 600, 0.1, 4];
const observe = (fn, args) => {
  const messages = [];
  const error = console.error;
  console.error = (...args) => messages.push(args);
  try {
    return { value: fn(...args), messages };
  } catch (error) {
    return { error: { name: error.name, message: error.message }, messages };
  } finally {
    console.error = error;
  }
};

test('getViewportForBounds accepts all six JS arguments', () => {
  assert.equal(psflow.length, upstream.length);
  assert.equal(psflow.length, 6);
  assert.deepEqual(psflow(...base, 0.1), upstream(...base, 0.1));
});

const paddings = [
  ['ratio', 0.1], ['zero', 0], ['pixels', '31.5px'], ['percent', '12.5%'],
  ['directional', { top: '40px', right: '15%', bottom: 0.2, left: '5px' }],
  ['axis fallback', { x: '20px', y: '10%', top: null, right: undefined }],
  ['asymmetric', { left: '250px', bottom: '240px' }], ['empty', {}],
  ['explicit undefined', undefined], ['null', null], ['boolean', false],
  ['function', () => {}], ['array', []], ['invalid scalar', 'bad'],
  ['invalid side', { top: 'bad', bottom: true, x: 'also bad' }],
  ['parseFloat suffix', '12garbagepx'], ['negative pixels', '-7.9px'],
  ['infinite pixels', 'Infinitypx'], ['NaN', NaN], ['infinity', Infinity],
  ['NaN horizontal padding', { left: NaN }], ['NaN vertical padding', { top: NaN }],
];
for (const [name, padding] of paddings) {
  test(`getViewportForBounds matches upstream: ${name}`, () => {
    assert.deepEqual(observe(psflow, [...base, padding]), observe(upstream, [...base, padding]));
  });
}
test('omitted padding has no caller-specific default', () => {
  assert.deepEqual(observe(psflow, base), observe(upstream, base));
});
for (const [name, min, max] of [['min clamp', 3, 4], ['max clamp', 0.1, 0.5]]) {
  test(`getViewportForBounds respects ${name}`, () => {
    const args = [bounds, 800, 600, min, max, { left: '200px' }];
    assert.deepEqual(observe(psflow, args), observe(upstream, args));
  });
}
for (const [name, min, max] of [['NaN minZoom', NaN, 4], ['NaN maxZoom', 0.1, NaN]]) {
  test(`getViewportForBounds propagates ${name}`, () => {
    const args = [bounds, 800, 600, min, max, 0.1];
    assert.deepEqual(observe(psflow, args), observe(upstream, args));
  });
}
