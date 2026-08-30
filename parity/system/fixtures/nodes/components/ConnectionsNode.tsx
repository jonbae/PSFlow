// A node that renders what `useNodeConnections` told it (#4949).
//
// The row is that the hook must report **all** the edges connected to a node,
// not the first per handle. A hook's return value has no DOM residue of its own
// — that is what the net's `hooks` section exists for — but the `hooks` section
// is written by the probe components, and a probe changes what the page renders,
// so a probed run is compared only at its own observation level. This row needs
// the ordinary comparison, because "all the edges" is a claim about a graph the
// fixture sets up.
//
// So the reading is rendered instead. Every attribute reaches the `dom` section
// verbatim, and a hook that returned two connections where the other side saw
// three is then a plain text difference in an element the capture already
// records — no probe, no assertion, and full comparison scope.
//
// Three readings rather than one, because the row is about the *filters*: the
// unfiltered call is what must return everything, and the two filtered calls
// are what it must be consistent with. A single unfiltered reading could not
// tell a hook that over-reports from one that ignores its filter.
//
// Not sorted, deliberately. The order a hook answers in is part of what the two
// implementations either agree about or do not, and sorting here would hide a
// real difference behind the fixture's own tidying.

import { Handle, Position, useNodeConnections } from '@xyflow/react';

const say = (connections: unknown[]) =>
  JSON.stringify(
    (connections as { edgeId?: string; source?: string; target?: string; sourceHandle?: string | null; targetHandle?: string | null }[]).map(
      (c) => [c.edgeId, c.source, c.target, c.sourceHandle ?? null, c.targetHandle ?? null]
    )
  );

export default function ConnectionsNode({ data }: { data: { label?: string } }) {
  const all = useNodeConnections();
  const asSource = useNodeConnections({ handleType: 'source' });
  const asTarget = useNodeConnections({ handleType: 'target' });

  return (
    <div
      data-psflow-connections={say(all)}
      data-psflow-connections-source={say(asSource)}
      data-psflow-connections-target={say(asTarget)}
      data-psflow-connections-count={String(all.length)}
    >
      <Handle type="target" position={Position.Top} id="in" />
      {data?.label}
      <Handle type="source" position={Position.Bottom} id="out" />
    </div>
  );
}
