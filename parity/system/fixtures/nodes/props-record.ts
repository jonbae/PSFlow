// A child parented to a node that sits somewhere else (#61).
//
// The graph the retired `node-props.spec.ts` mounted, as data. Its two tests
// were about the two branches of the record ps-flow hands a consumer's node
// component, and one fixture holds both because both nodes render their own
// reading:
//
//   * `props-child` sets `selectable`, `draggable` and `deletable` explicitly to
//     `false` and parents itself to `props-parent`. Its own `position` is
//     (50, 25) and its parent's is (100, 200), so `positionAbsoluteX/Y` must
//     read (150, 225) — wiring raw `position` through instead is the failure the
//     retired spec's expected strings existed to catch, and it is a real
//     divergence here rather than an assertion, because upstream is answering
//     the same question in the trace beside it.
//   * `props-parent` leaves all three flags unset, so it is the defaulted
//     branch: `selectable` and `draggable` fall through to the flow-level
//     `elementsSelectable` / `nodesDraggable` and `deletable` to `true`.
//
// Both are measured in the fixture rather than left to the resize observer:
// `width` and `height` on the record are the measured pair, and a scenario that
// had to wait for a measurement would compare a settled page on one side
// against a settling one on the other.

import PropsRecordNode from './components/PropsRecordNode';

export default {
  flowProps: {
    fitView: true,
    nodeTypes: { propsRecord: PropsRecordNode },
    nodes: [
      {
        id: 'props-parent',
        type: 'propsRecord',
        data: { label: 'props-parent' },
        position: { x: 100, y: 200 },
        width: 300,
        height: 200,
        measured: { width: 300, height: 200 },
      },
      {
        id: 'props-child',
        type: 'propsRecord',
        data: { label: 'props-child' },
        position: { x: 50, y: 25 },
        parentId: 'props-parent',
        selectable: false,
        draggable: false,
        deletable: false,
        width: 120,
        height: 40,
        measured: { width: 120, height: 40 },
      },
    ],
    edges: [],
  },
};
