// A consumer's own edge type that mounts the three edge-scoped exports no other
// fixture mounts: `EdgeLabelRenderer`, `EdgeToolbar` and `ViewportPortal`.
//
// Each container is drawn by `GraphView` for every flow, so only content inside
// one says the export ran; that content is what the witnesses look for. The
// toolbar takes upstream's default visibility, which follows the edge's
// selection, so a mount shows the label and the portal and a click on the edge
// adds the toolbar. The label sits above the path's midpoint rather than on it,
// so a click at the midpoint lands on the edge and not on the label.

import {
  BaseEdge,
  EdgeLabelRenderer,
  EdgeToolbar,
  ViewportPortal,
  getBezierPath,
  type EdgeProps,
} from '@xyflow/react';

export default function PortalEdge({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  sourcePosition,
  targetPosition,
  markerEnd,
  data,
}: EdgeProps) {
  const [path, labelX, labelY] = getBezierPath({
    sourceX,
    sourceY,
    sourcePosition,
    targetX,
    targetY,
    targetPosition,
  });

  return (
    <>
      <BaseEdge id={id} path={path} markerEnd={markerEnd} />
      <EdgeLabelRenderer>
        <div
          className="portal-edge-label nodrag nopan"
          style={{
            position: 'absolute',
            transform: `translate(-50%, -50%) translate(${labelX}px,${labelY - 40}px)`,
            pointerEvents: 'all',
          }}
        >
          {String((data as { label?: unknown } | undefined)?.label ?? id)}
        </div>
      </EdgeLabelRenderer>
      <EdgeToolbar edgeId={id} x={labelX} y={labelY} alignY="top">
        <button type="button" className="portal-edge-toolbar-button">
          toolbar
        </button>
      </EdgeToolbar>
      <ViewportPortal>
        <div
          className="portal-edge-viewport-content"
          style={{ position: 'absolute', transform: `translate(${targetX}px,${targetY + 24}px)` }}
        >
          portal
        </div>
      </ViewportPortal>
    </>
  );
}
