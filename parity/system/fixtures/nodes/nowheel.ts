// A node marked `nowheel`, big enough to pinch on (#5512, #5148).
//
// Both rows are a browser default that must *not* happen: a pinch over an
// element the flow has opted out of zooming must not fall through to the page's
// own zoom either. There is no element and no attribute recording that, which
// is why the `dom` section carries enumerated page-level state — here
// `visualViewport.scale`, whose staying at 1 is the whole observation.
//
// The node is sized well beyond a default node's box because a two-finger pinch
// spreads its fingers apart from the centre: fingers that land outside the
// `nowheel` element are a pinch over the pane, which is a different gesture
// with a different correct answer.
//
// `nowheel` is a class the *stylesheet* and the wheel handler both key on, and
// both sides load the same stylesheet, so the class attribute reaching the
// element is equality of behaviour as well as of markup.

export default {
  flowProps: {
    fitView: true,
    nodes: [
      {
        id: 'nowheel',
        data: { label: 'nowheel' },
        position: { x: 0, y: 0 },
        className: 'nowheel',
        style: { width: 400, height: 320 },
      },
      { id: 'plain', data: { label: 'plain' }, position: { x: 460, y: 0 } },
    ],
    edges: [{ id: 'nowheel-plain', source: 'nowheel', target: 'plain' }],
  },
};
