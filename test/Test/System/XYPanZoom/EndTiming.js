import assert from 'node:assert/strict';
import { buildSync } from 'esbuild';
import { fileURLToPath } from 'node:url';
import { select } from 'd3-selection';
import { zoom, zoomIdentity } from 'd3-zoom';

const loadSource = () => {
  const result = buildSync({
    entryPoints: [fileURLToPath(new URL('../../xyflow/packages/system/src/xypanzoom/eventhandler.ts', import.meta.url))],
    bundle: true, write: false, format: 'cjs', platform: 'node', logLevel: 'silent',
  });
  const module = { exports: {} };
  new Function('module', 'exports', result.outputFiles[0].text)(module, module.exports);
  return (panOnScroll, callback) => module.exports.createPanZoomEndHandler({
    panOnScroll, panOnDrag: true, onDraggingChange: () => {}, onPanZoomEnd: callback,
    zoomPanValues: { isZoomingOrPanning: true, usedRightMouseButton: false, prevViewport: {x:0,y:0,zoom:1}, mouseButton: 0 },
  });
};

const nextTask = () => new Promise(resolve => setTimeout(resolve, 0));

export const checkEndTiming = (create, done) => {
  (async () => {
    const source = loadSource();
    const drive = async factory => {
      const receipts = [];
      const callback = (event, viewport) => receipts.push(['onMoveEnd', event, viewport]);
      const end = factory(false, callback);
      end({ transform: {x:10,y:20,k:2}, sourceEvent: null });
      receipts.push('onNodesChange');
      await Promise.resolve();
      receipts.push('microtask');
      await nextTask();
      return receipts;
    };
    const expected = await drive(source);
    assert.deepStrictEqual(expected.map(r => Array.isArray(r) ? r[0] : r), ['onNodesChange','microtask','onMoveEnd']);
    assert.deepStrictEqual(await drive(create), expected, 'measurement callback precedes the queued viewport-end callback');

    // Actual d3 transforms call end before updateNodeInternals reports its
    // measurement. Only the public end callback is deferred by upstream.
    const driveD3 = async factory => {
      const receipts = [];
      const node = { addEventListener() {}, removeEventListener() {} };
      const selection = select(node);
      const behavior = zoom().extent([[0,0],[640,480]]).touchable(false);
      behavior.on('start', () => receipts.push('onMoveStart'));
      behavior.on('zoom', () => receipts.push('onMove'));
      behavior.on('end', factory(false, (event, viewport) => receipts.push(['onMoveEnd',event,viewport])));
      selection.call(behavior);
      behavior.transform(selection, zoomIdentity.translate(10,20).scale(2));
      receipts.push('onNodesChange');
      await Promise.resolve();
      receipts.push('microtask');
      await nextTask();
      return receipts;
    };
    const sourceD3 = await driveD3(source);
    assert.deepStrictEqual(sourceD3.map(r => Array.isArray(r) ? r[0] : r),
      ['onMoveStart','onMove','onNodesChange','microtask','onMoveEnd']);
    assert.deepStrictEqual(await driveD3(create), sourceD3, 'native d3 lifecycle matches source around measurement');

    const consecutiveEnds = async (factory, panOnScroll) => {
      const receipts = [];
      let finished;
      const completion = new Promise(resolve => { finished = resolve; });
      const events = [{type:'wheel',tag:'first'}, {type:'wheel',tag:'second'}];
      const end = factory(panOnScroll, (event, viewport) => { receipts.push([event,viewport]); finished(); });
      end({transform:{x:1,y:2,k:1},sourceEvent:events[0]});
      end({transform:{x:3,y:4,k:2},sourceEvent:events[1]});
      assert.equal(receipts.length, 0, 'an end is never inline');
      await Promise.resolve();
      assert.equal(receipts.length, 0, 'an end is a task, not a microtask');
      await completion;
      await nextTask();
      assert.equal(receipts.length, 1, 'a later end cancels the earlier pending end');
      assert.equal(receipts[0][0], events[1], 'the original latest event reaches the consumer');
      return receipts;
    };
    for (const panOnScroll of [false,true]) {
      assert.deepStrictEqual(await consecutiveEnds(create, panOnScroll), await consecutiveEnds(source, panOnScroll),
        `latest end wins with panOnScroll=${panOnScroll}`);
    }
    const corrupt = structuredClone(expected);
    [corrupt[0],corrupt[2]] = [corrupt[2],corrupt[0]];
    assert.throws(() => assert.deepStrictEqual(corrupt, expected), assert.AssertionError, 'callback order fault rejected');
    console.log('viewport-end: native task order, real d3 measurement order, 0/150 ms coalescing and event identity match source; order fault rejected');
  })().then(() => done(null), error => done(error.stack));
};
