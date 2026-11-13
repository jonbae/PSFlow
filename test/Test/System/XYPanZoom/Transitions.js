// Animated viewport changes on native timers, beside upstream's `XYPanZoom`
// compiled from the vendored source (upstream #5276).
//
// Upstream hands d3 a transition whenever `duration` is a positive number, and
// its promises settle on the transition's `end`. So the observable is a
// sequence: one `onPanZoom` per animation frame, then the settled promise. The
// two sides can only be compared frame by frame if their frames are the same
// frames, so the oracle's d3 imports resolve to the very modules the port's
// FFI loaded, and each case starts both transitions in one synchronous turn.
// d3-timer then ticks both in the same flush at the same elapsed time, on
// Node's real `setTimeout`, and any difference in ease, interpolation,
// duration or settling shows up as a different log.
import assert from 'node:assert/strict';
import { buildSync } from 'esbuild';
import { fileURLToPath } from 'node:url';
import * as d3Drag from 'd3-drag';
import * as d3Interpolate from 'd3-interpolate';
import * as d3Selection from 'd3-selection';
import * as d3Transition from 'd3-transition';
import * as d3Zoom from 'd3-zoom';

const shared = {
  'd3-drag': d3Drag,
  'd3-interpolate': d3Interpolate,
  'd3-selection': d3Selection,
  'd3-transition': d3Transition,
  'd3-zoom': d3Zoom,
};

const loadSource = () => {
  const result = buildSync({
    entryPoints: [fileURLToPath(new URL('../../xyflow/packages/system/src/xypanzoom/XYPanZoom.ts', import.meta.url))],
    bundle: true, write: false, format: 'cjs', platform: 'node', logLevel: 'silent',
    external: ['d3-*'],
  });
  const require = (name) => {
    if (!(name in shared)) throw new Error(`the vendored XYPanZoom imports ${name}, which this test does not share`);
    return shared[name];
  };
  const module = { exports: {} };
  new Function('module', 'exports', 'require', result.outputFiles[0].text)(module, module.exports, require);
  return module.exports.XYPanZoom;
};

// What d3-zoom, d3-transition and both controllers read off their host
// element, and the listeners d3 installs on it.
const element = () => {
  const listeners = {};
  return {
    clientWidth: 800, clientHeight: 600, clientLeft: 0, clientTop: 0,
    getBoundingClientRect: () => ({ left: 0, top: 0, x: 0, y: 0, width: 800, height: 600, right: 800, bottom: 600 }),
    addEventListener(type, listener) { listeners[type] = listener; },
    removeEventListener(type) { delete listeners[type]; },
    style: { setProperty() {}, removeProperty() {} },
    listeners,
  };
};

const updateOptions = (onTransformChange) => ({
  noWheelClassName: 'nowheel', noPanClassName: 'nopan', onPaneContextMenu: undefined,
  preventScrolling: true, panOnScroll: false, panOnDrag: true, panOnScrollMode: 'free', panOnScrollSpeed: 0.5,
  userSelectionActive: false, zoomOnPinch: true, zoomOnScroll: true, zoomOnDoubleClick: true,
  zoomActivationKeyPressed: false, lib: 'react', onTransformChange, connectionInProgress: false,
  paneClickDistance: 0, selectionOnDrag: false,
});

const mount = (factory) => {
  const log = [];
  const domNode = element();
  const record = (name) => (event, viewport) => log.push([name, event ?? null, viewport]);
  const instance = factory({
    domNode, minZoom: 0.25, maxZoom: 4, viewport: { x: 0, y: 0, zoom: 1 },
    translateExtent: [[-Infinity, -Infinity], [Infinity, Infinity]],
    onDraggingChange: (dragging) => log.push(['onDraggingChange', dragging]),
    onPanZoomStart: record('onPanZoomStart'), onPanZoom: record('onPanZoom'), onPanZoomEnd: record('onPanZoomEnd'),
  });
  instance.update(updateOptions((transform) => log.push(['onTransformChange', transform])));
  return { instance, domNode, log };
};

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const settled = (value) =>
  value && typeof value === 'object' ? { x: value.x, y: value.y, k: value.k } : value;

// Runs `act` on every side in one turn, so their transitions share a start
// time, and returns each side's log from the call on.
const drive = async (sides, act, wait) => {
  for (const side of sides) side.log.length = 0;
  for (const side of sides) {
    const promise = act(side);
    side.log.push(['returned']);
    promise.then((value) => side.log.push(['resolved', settled(value)]));
  }
  await sleep(wait);
  return sides.map((side) => side.log.slice());
};

const count = (log, name) => log.filter(([entry]) => entry === name).length;
const at = (log, name) => log.findIndex(([entry]) => entry === name);
const lastAt = (log, name) => log.findLastIndex(([entry]) => entry === name);

// The controller's own double-click zoom: d3 animates it with whatever
// interpolator the controller's last call left on the behavior. The event's
// members are shared, so each side's log holds equal events.
const eventTarget = { closest: () => null };
const ignore = () => {};
const doubleClick = ({ domNode }) =>
  domNode.listeners.dblclick.call(domNode, {
    type: 'dblclick', button: 0, ctrlKey: false, shiftKey: false, clientX: 600, clientY: 200,
    target: eventTarget, preventDefault: ignore, stopImmediatePropagation: ignore,
  });

export const checkTransitions = (create, done) => {
  (async () => {
    // After the suite's synchronous tests, so a frame is a frame.
    await sleep(0);
    // d3-zoom's default extent asks `instanceof SVGElement`, which Node lacks.
    const ownsSVGElement = !('SVGElement' in globalThis);
    if (ownsSVGElement) globalThis.SVGElement = class SVGElement {};
    try {
      const XYPanZoom = loadSource();
      const target = { x: 120, y: -80, zoom: 2 };
      const cases = [
        ['default ease, smooth', (s) => s.instance.setViewport(target, { duration: 180 }), 'animated'],
        ['custom ease, linear', (s) => s.instance.setViewport(target, { duration: 180, ease: (t) => t * t, interpolate: 'linear' }), 'animated'],
        ['scaleTo', (s) => s.instance.scaleTo(3, { duration: 180 }), 'animated'],
        ['scaleBy, linear', (s) => s.instance.scaleBy(0.5, { duration: 180, interpolate: 'linear', ease: (t) => t }), 'animated'],
        ['fractional duration', (s) => s.instance.setViewport(target, { duration: 0.4 }), 'animated'],
        ['zero duration', (s) => s.instance.setViewport(target, { duration: 0 }), 'immediate'],
        ['no options', (s) => s.instance.setViewport(target), 'immediate'],
        ['negative duration', (s) => s.instance.setViewport(target, { duration: -50 }), 'immediate'],
        ['NaN duration', (s) => s.instance.setViewport(target, { duration: NaN }), 'immediate'],
        ['null duration', (s) => s.instance.setViewport(target, { duration: null }), 'immediate'],
        ['string duration', (s) => s.instance.setViewport(target, { duration: '180' }), 'immediate'],
      ];

      for (const [name, act, kind] of cases) {
        const sides = [mount(XYPanZoom), mount(create)];
        const [source, port] = await drive(sides, act, 400);
        const frames = count(source, 'onPanZoom');
        if (kind === 'animated') {
          // The case reaches the branch it is named for, upstream first.
          assert.ok(at(source, 'returned') < at(source, 'onPanZoom'), `${name}: upstream animates after the call returns`);
          if (name !== 'fractional duration') assert.ok(frames >= 3, `${name}: upstream drew ${frames} frames`);
          assert.ok(lastAt(source, 'onPanZoom') < at(source, 'resolved'), `${name}: upstream settles after its last frame`);
        } else {
          assert.equal(frames, 1, `${name}: upstream applies the viewport at once`);
          assert.ok(at(source, 'onPanZoom') < at(source, 'returned'), `${name}: upstream applies it before returning`);
        }
        assert.deepStrictEqual(port, source, `${name}: the port's frames and settling match upstream's`);
      }

      // A second change interrupts a running transition. d3 never ends the
      // first, so its promise never settles, on either side.
      {
        const sides = [mount(XYPanZoom), mount(create)];
        const firsts = sides.map((side) => {
          const outcome = { settled: false };
          side.instance.setViewport(target, { duration: 240 }).then(() => { outcome.settled = true; });
          return outcome;
        });
        await sleep(90);
        const [source, port] = await drive(sides, (s) => s.instance.setViewport({ x: -40, y: 30, zoom: 0.5 }), 400);
        assert.deepEqual(firsts.map((first) => first.settled), [false, false], 'an interrupted transition never settles');
        assert.equal(count(source, 'onPanZoom'), 1, 'interrupt: the interrupting change is immediate');
        assert.deepStrictEqual(port, source, 'interrupt: the port matches upstream');
      }

      // Every change picks the behavior's interpolator, a change made without
      // options included. Upstream's constrained setter puts back d3's smooth
      // zoom, and the double-click animation after it uses that.
      {
        const sides = [mount(XYPanZoom), mount(create)];
        for (const side of sides) await side.instance.setViewport({ x: 10, y: 10, zoom: 1 }, { duration: 0, interpolate: 'linear' });
        for (const side of sides) await side.instance.setViewportConstrained({ x: 0, y: 0, zoom: 1 }, [[0, 0], [800, 600]], [[-Infinity, -Infinity], [Infinity, Infinity]]);
        const [source, port] = await drive(sides, (s) => { doubleClick(s); return Promise.resolve(); }, 450);
        assert.ok(count(source, 'onPanZoom') >= 3, 'double-click: upstream animates');
        assert.deepStrictEqual(port, source, 'double-click after a constrained change: the port interpolates as upstream does');
      }

      // A falsification probe: the comparison sees one frame's difference.
      {
        const sides = [mount(XYPanZoom), mount(XYPanZoom)];
        const [one, other] = await drive(sides, (s) => s.instance.setViewport(target, { duration: 180 }), 400);
        assert.deepStrictEqual(other, one, 'two upstream controllers started together agree');
        const corrupt = structuredClone(other);
        const frames = corrupt.flatMap(([entry], index) => (entry === 'onPanZoom' ? [index] : []));
        corrupt[frames[1]][2].x += 1e-6;
        assert.throws(() => assert.deepStrictEqual(corrupt, one), assert.AssertionError, 'a one-frame fault is rejected');
      }

      console.log(`viewport transitions: ${cases.length + 2} cases match upstream frame by frame on native timers; a one-frame fault is rejected`);
    } finally {
      if (ownsSVGElement) delete globalThis.SVGElement;
    }
  })().then(() => done(null), (error) => done(error.stack));
};
