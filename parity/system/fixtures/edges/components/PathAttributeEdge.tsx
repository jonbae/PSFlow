// A custom edge that hands `<BaseEdge>` path attributes of its own (#4855).
//
// The row is that `BaseEdge` forwards arbitrary `<path>` attributes rather than
// only the ones it names. Every attribute reaches the `dom` section verbatim,
// so an implementation that dropped the pass-through is a set of missing
// attributes on an element the capture already records in full — no assertion
// needed, which is the property the whole net is built on.
//
// The attributes are chosen to be plainly *not* ones `BaseEdge` sets itself:
// `stroke-dasharray` and `stroke-linecap` are presentational, `data-*` is not a
// path attribute at all, and `pathLength` is an SVG geometry attribute that a
// naive whitelist would never think to allow.

import { BaseEdge, getSmoothStepPath, type EdgeProps } from '@xyflow/react';

export default function PathAttributeEdge({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  sourcePosition,
  targetPosition,
  markerEnd,
}: EdgeProps) {
  const [path] = getSmoothStepPath({ sourceX, sourceY, targetX, targetY, sourcePosition, targetPosition });

  return (
    <BaseEdge
      id={id}
      path={path}
      markerEnd={markerEnd}
      strokeDasharray="6 3"
      strokeLinecap="round"
      strokeWidth={3}
      pathLength={100}
      data-psflow-edge="base-edge-path"
      aria-label="edge with path attributes"
    />
  );
}
