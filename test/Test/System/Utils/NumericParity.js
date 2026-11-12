import assert from 'node:assert/strict';
import { buildSync } from 'esbuild';
import { fileURLToPath } from 'node:url';
import { clamp, clampPosition, getBoundsOfBoxes, getBoundsOfRects, getOverlappingArea, getViewportForBounds } from '@psflow/oracle';

// Exact Object.is semantics: NaN agrees with itself; +0 differs from -0.
const same = (actual, expected, label) => assert.deepStrictEqual(actual, expected, label);
const numbers = [-Infinity, -Number.MAX_VALUE, -100, -1, -Number.MIN_VALUE, -0, 0,
  Number.MIN_VALUE, 0.1, 1, 100, Number.MAX_VALUE, Infinity, NaN];

export const checkClamp = actual => {
  assert.equal(actual(NaN, 0, 1), clamp(NaN, 0, 1), 'clamp propagates a NaN input');
  let count = 0;
  for (const value of numbers) for (const min of numbers) for (const max of numbers) {
    same(actual(value, min, max), clamp(value, min, max), `clamp case ${++count}`);
  }
  assert.throws(() => same(Math.abs(actual(-0, -1, 1)), clamp(-0, -1, 1), 'signed-zero fault'), assert.AssertionError);
  const invalid = actual(NaN, 0, 1);
  assert.throws(() => same(Number.isNaN(invalid) ? 1 : invalid, clamp(NaN, 0, 1), 'discarded-NaN fault'), assert.AssertionError);
  console.log(`numeric clamp: ${count} exact source comparisons; zero/NaN faults rejected`);
};

export const checkBounds = actual => {
  const a = { x: NaN, y: 0, x2: 5, y2: 10 };
  const b = { x: 3, y: 4, x2: 8, y2: 12 };
  same(actual(a, b), getBoundsOfBoxes(a, b), 'box union propagates NaN in either operand');
  let count = 0;
  for (const key of ['x', 'y', 'x2', 'y2']) for (const first of numbers) for (const second of numbers) {
    const a = { x: 1, y: 2, x2: 8, y2: 12, [key]: first };
    const b = { x: 3, y: 4, x2: 5, y2: 10, [key]: second };
    same(actual(a, b), getBoundsOfBoxes(a, b), `box union ${key} case ${++count}`);
  }
  console.log(`numeric bounds: ${count} exact source comparisons`);
};

export const checkGeometry = actual => {
  let rectangles = 0;
  for (const aKey of ['x', 'y', 'width', 'height']) for (const bKey of ['x', 'y', 'width', 'height']) {
    for (const first of numbers) for (const second of numbers) {
      const a = { x: -3, y: 2, width: 20, height: 10, [aKey]: first };
      const b = { x: 7, y: -4, width: 15, height: 12, [bKey]: second };
      same(actual.rectangles(a, b), getBoundsOfRects(a, b), `rectangle union ${++rectangles}`);
      same(actual.overlap(a, b), getOverlappingArea(a, b), `rectangle overlap ${rectangles}`);
    }
  }
  let positions = 0;
  for (const key of ['minX', 'minY', 'maxX', 'maxY']) for (const value of numbers) {
    for (const dimension of [undefined, ...numbers]) {
      const extent = { minX: -5, minY: -10, maxX: 100, maxY: 80, [key]: value };
      const point = { x: value, y: -value };
      const dimensions = { width: dimension, height: dimension };
      same(actual.position(point, extent, dimensions),
        clampPosition(point, [[extent.minX, extent.minY], [extent.maxX, extent.maxY]], dimensions),
        `clamp position ${++positions}`);
    }
  }
  const base = { bounds: { x: 10, y: 20, width: 100, height: 80 },
    width: 640, height: 480, minZoom: 0.1, maxZoom: 4, padding: 0.2 };
  let viewports = 0;
  for (const key of ['x', 'y', 'width', 'height']) for (const value of numbers) {
    const p = { ...base, bounds: { ...base.bounds, [key]: value } };
    same(actual.viewport(p), getViewportForBounds(p.bounds, p.width, p.height, p.minZoom, p.maxZoom, p.padding),
      `viewport bounds ${++viewports}`);
  }
  for (const key of ['width', 'height', 'minZoom', 'maxZoom', 'padding']) for (const value of numbers) {
    const p = { ...base, [key]: value };
    same(actual.viewport(p), getViewportForBounds(p.bounds, p.width, p.height, p.minZoom, p.maxZoom, p.padding),
      `viewport ${++viewports}`);
  }
  console.log(`numeric geometry: ${rectangles} rectangle pairs (union and overlap), ${positions} positions, ${viewports} viewports`);
};

const loadResizeOracle = () => {
  const result = buildSync({
    entryPoints: [fileURLToPath(new URL('../../xyflow/packages/system/src/xyresizer/utils.ts', import.meta.url))],
    bundle: true, write: false, format: 'cjs', platform: 'node', logLevel: 'silent',
  });
  const module = { exports: {} };
  new Function('module', 'exports', result.outputFiles[0].text)(module, module.exports);
  return module.exports;
};

export const checkResize = actual => {
  const source = loadResizeOracle();
  const p = {
    start: { x: 10, y: 20, width: 100, height: 80, pointerX: 0, pointerY: 0, aspectRatio: 1.25 },
    direction: source.getControlDirection('bottom-right'),
    pointer: { x: 20, y: 30, xSnapped: 20, ySnapped: 30 },
    boundaries: { minWidth: NaN, maxWidth: 500, minHeight: 10, maxHeight: 500 },
    keepAspectRatio: false, origin: { ox: 0, oy: 0 },
  };
  same(actual(p), source.getDimensionsAfterResize(p.start, p.direction, p.pointer, p.boundaries,
    p.keepAspectRatio, [p.origin.ox, p.origin.oy]), 'resize propagates a NaN size boundary');
  const base = { ...p, boundaries: { minWidth: 10, maxWidth: 500, minHeight: 10, maxHeight: 500 } };
  const extent = { minX: -20, minY: -30, maxX: 300, maxY: 250 };
  const asExtent = e => e && [[e.minX, e.minY], [e.maxX, e.maxY]];
  let count = 0;
  const compare = p => {
    same(actual(p), source.getDimensionsAfterResize(p.start, p.direction, p.pointer, p.boundaries,
      p.keepAspectRatio, [p.origin.ox, p.origin.oy], asExtent(p.extent), asExtent(p.childExtent)),
      `resize numeric case ${++count}`);
  };
  for (const control of ['top', 'bottom', 'left', 'right', 'top-left', 'top-right', 'bottom-left', 'bottom-right']) {
    for (const keepAspectRatio of [false, true]) {
      const defaults = { ...base, direction: source.getControlDirection(control), keepAspectRatio };
      for (const key of ['minWidth', 'maxWidth', 'minHeight', 'maxHeight']) for (const value of numbers) {
        compare({ ...defaults, boundaries: { ...defaults.boundaries, [key]: value } });
      }
      for (const field of ['extent', 'childExtent']) for (const key of ['minX', 'minY', 'maxX', 'maxY']) {
        for (const value of numbers) compare({ ...defaults, [field]: { ...extent, [key]: value } });
      }
      for (const key of ['x', 'y', 'width', 'height', 'pointerX', 'pointerY', 'aspectRatio']) for (const value of numbers) {
        compare({ ...defaults, start: { ...defaults.start, [key]: value } });
      }
      for (const key of ['xSnapped', 'ySnapped']) for (const value of numbers) {
        compare({ ...defaults, pointer: { ...defaults.pointer, [key]: value } });
      }
      for (const key of ['ox', 'oy']) for (const value of numbers) {
        compare({ ...defaults, origin: { ...defaults.origin, [key]: value } });
      }
      compare({ ...defaults, extent, childExtent: { minX: 20, minY: 30, maxX: 100, maxY: 90 } });
    }
  }
  const expected = source.getDimensionsAfterResize(base.start, base.direction, base.pointer, base.boundaries,
    base.keepAspectRatio, [base.origin.ox, base.origin.oy]);
  assert.throws(() => same({ ...actual(base), width: -1 }, expected, 'resize width fault'), assert.AssertionError);
  console.log(`numeric resize: ${count} exact vendored-source comparisons; width fault rejected`);
};
