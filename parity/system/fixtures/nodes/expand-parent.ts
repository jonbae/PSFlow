// A child that pushes its parent open as it is dragged (#5043 — read the
// *current* `expandParent`, so it can be changed mid-drag).
//
// The child starts well inside the parent and the scenario drags it out past
// one corner, which is the only way `expandParent` does anything at all: a
// child that stays within its parent's box never asks the parent to grow. The
// parent's own measured size then changes during the gesture, so the row lands
// in `dom` — and it lands there *repeatedly*, once per drag step, which is what
// makes "current value" rather than "value at drag start" observable.
//
// `extent: 'parent'` is deliberately **not** set. The two are alternatives in
// upstream's own position code: an extent clamps the child inside the parent,
// which would stop it ever reaching the edge this row is about.

export default {
  flowProps: {
    fitView: true,
    nodeDragThreshold: 0,
    nodes: [
      {
        id: 'parent',
        data: { label: 'parent' },
        position: { x: 0, y: 0 },
        style: { width: 320, height: 220, backgroundColor: 'rgba(80, 120, 200, 0.12)' },
      },
      {
        id: 'child',
        data: { label: 'child' },
        position: { x: 40, y: 40 },
        parentId: 'parent',
        expandParent: true,
      },
      { id: 'outside', data: { label: 'outside' }, position: { x: 420, y: 0 } },
    ],
    edges: [{ id: 'child-outside', source: 'child', target: 'outside' }],
  },
};
