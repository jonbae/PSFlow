// A flow whose edge type spreads path attributes through `BaseEdge` (#4855).
//
// Two edges of the same custom type, and one of upstream's default type beside
// them: the default is the control. Without it, an implementation that ignored
// the custom type entirely and rendered every edge the built-in way would look
// like one that forwarded no attributes, and the two are different bugs.
//
// **ps-flow cannot mount this fixture yet**, and that is recorded rather than
// worked around: `edgeTypes` has not crossed the JavaScript boundary — it lands
// in stage 4 (#62) — so the ps-flow side throws before the flow renders and its
// trace carries a null root and the thrown message. There is no way to ask about
// `BaseEdge` forwarding path attributes without a custom edge component, and no
// way to register one without `edgeTypes`, so the scenario's honest answer today
// is that the row is blocked on stage 4. It is written now so that the day
// `edgeTypes` crosses, the row is already driven — and until then the trace says
// exactly which prop is in the way.

import PathAttributeEdge from './components/PathAttributeEdge';

export default {
  flowProps: {
    fitView: true,
    edgeTypes: { pathAttributes: PathAttributeEdge },
    nodes: [
      { id: 'Node-1', data: { label: 'Node-1' }, position: { x: 0, y: 0 }, type: 'input' },
      { id: 'Node-2', data: { label: 'Node-2' }, position: { x: -140, y: 140 } },
      { id: 'Node-3', data: { label: 'Node-3' }, position: { x: 140, y: 140 } },
    ],
    edges: [
      { id: 'custom-1', type: 'pathAttributes', source: 'Node-1', target: 'Node-2' },
      { id: 'custom-2', type: 'pathAttributes', source: 'Node-1', target: 'Node-3', label: 'custom' },
      { id: 'default-1', type: 'default', source: 'Node-2', target: 'Node-3' },
    ],
  },
};
