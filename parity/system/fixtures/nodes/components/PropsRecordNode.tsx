// A node that renders the `NodeProps` record it was handed (#61).
//
// This is `parity/driver/src/NodePropsGuard.tsx` turned into a fixture
// component. The guard was a ps-flow **contract** page: it mounted a custom node
// through `index.js`, rendered eight fields of the record as `data-*`
// attributes, and a browser spec asserted the eight strings by hand. Upstream
// was never mounted beside it, so what the spec proved was a *reading* of
// xyflow's `NodeProps` written down in 2024 — which is exactly how the
// `xPos`/`yPos` rename survived from 12.3.5 as a printed-not-failed diff in the
// first place.
//
// Rendered rather than probed, for the reason `ConnectionsNode.tsx` gives: the
// `props` section is written by the probe components, and a probed run is
// compared only at its own observation level, so the graph a probe replaced is
// not compared at all. This claim is *about* the graph — a child parented to a
// node that sits elsewhere — so the reading goes into the DOM, where it reaches
// the `dom` section verbatim and is compared at full scope against upstream's
// own answer.
//
// Every value is stringified the same way on both sides, including the absent
// case: `parentId` is `undefined` on a root node and `String(undefined)` would
// put the word "undefined" in an attribute, which reads as a value rather than
// as an absence.

const say = (value: unknown) => (value === undefined || value === null ? '' : String(value));

export default function PropsRecordNode(props: Record<string, unknown>) {
  return (
    <div
      className="props-record-node"
      style={{
        width: props.width == null ? '100px' : `${props.width}px`,
        height: props.height == null ? '40px' : `${props.height}px`,
        border: '1px solid #222',
        background: '#eee',
        fontSize: '10px',
      }}
      data-psflow-selectable={say(props.selectable)}
      data-psflow-draggable={say(props.draggable)}
      data-psflow-deletable={say(props.deletable)}
      data-psflow-width={say(props.width)}
      data-psflow-height={say(props.height)}
      data-psflow-parent-id={say(props.parentId)}
      data-psflow-pos-x={say(props.positionAbsoluteX)}
      data-psflow-pos-y={say(props.positionAbsoluteY)}
      data-psflow-type={say(props.type)}
    >
      {say(props.id)}
    </div>
  );
}
