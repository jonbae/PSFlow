// The viewport an initial `fitView` gives a server render, against upstream's.
//
// Upstream's `getInitialState` fits the view when `fitView && width && height`,
// as JavaScript reads them. It fits only the nodes whose own sizes are
// truthy: `(node.width || node.initialWidth) && (node.height ||
// node.initialHeight)`. A node with no such size, one with only a `measured`
// size, or one whose sizes are zero is left out, and a flow with no sized
// node fits the zero rect.
//
// A server render runs no effects, so the store's initial transform is what
// the viewport draws. Each case compares that transform with upstream's, and
// checks that upstream's side reaches the branch the case is named for.
import assert from 'node:assert/strict';
import test from 'node:test';
import { createElement } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import * as upstream from '@xyflow/react';
import * as psflow from '../../index.js';

globalThis.ResizeObserver = class { observe() {} unobserve() {} disconnect() {} };

const sized = { id: 'a', position: { x: 0, y: 0 }, data: {}, width: 100, height: 50 };
const at500 = (extra) => ({ id: 'b', position: { x: 500, y: 400 }, data: {}, ...extra });

const transform = (library, props) => {
  const markup = renderToStaticMarkup(
    createElement(library.ReactFlow, { edges: [], fitView: true, width: 400, height: 300, ...props })
  );
  const tag = markup.match(/<div[^>]*class="react-flow__viewport[^"]*"[^>]*>/);
  assert.ok(tag, 'the render has a viewport');
  const style = tag[0].match(/style="([^"]*)"/);
  assert.ok(style, 'the viewport has a style');
  return style[1];
};

const matchesUpstream = (props) => {
  const expected = transform(upstream, props);
  assert.equal(transform(psflow, props), expected);
  return expected;
};

const withoutB = transform(upstream, { nodes: [sized] });

test('two sized nodes are both fitted', () => {
  const both = matchesUpstream({ nodes: [sized, at500({ width: 100, height: 50 })] });
  assert.notEqual(both, withoutB);
});

test('a node with no size is left out', () => {
  assert.equal(matchesUpstream({ nodes: [sized, at500({})] }), withoutB);
});

test('a node sized only by measured is left out', () => {
  assert.equal(matchesUpstream({ nodes: [sized, at500({ measured: { width: 100, height: 50 } })] }), withoutB);
});

test('a node sized by initialWidth and initialHeight is fitted', () => {
  assert.notEqual(matchesUpstream({ nodes: [sized, at500({ initialWidth: 100, initialHeight: 50 })] }), withoutB);
});

test('a zero width falls back to initialWidth', () => {
  assert.notEqual(matchesUpstream({ nodes: [sized, at500({ width: 0, initialWidth: 100, height: 50 })] }), withoutB);
});

test('a zero width with no initialWidth is left out', () => {
  assert.equal(matchesUpstream({ nodes: [sized, at500({ width: 0, height: 50 })] }), withoutB);
});

test('a flow with no sized node fits the zero rect', () => {
  const fitted = matchesUpstream({ nodes: [{ ...sized, width: undefined, height: undefined }, at500({})] });
  assert.equal(fitted, transform(upstream, { nodes: [] }));
});

test('a negative container width still fits, as JavaScript reads it as true', () => {
  const props = { nodes: [sized], width: -400 };
  assert.notEqual(matchesUpstream(props), transform(upstream, { ...props, fitView: false }));
});
