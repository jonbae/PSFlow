// FFI bridge to the XYFlow oracle bundle (`@psflow/oracle`, built by
// `oracle/esbuild.mjs` from the vendored upstream sources). This file and
// `Test.Oracle.purs` are the ONLY place in the test suite that knows XYFlow's
// shapes; every parity property calls `Oracle.*` exclusively. An upstream
// bump touches this file + the esbuild entry list and nothing else.
//
// Two adaptations live here:
//   * tuple → record: XYFlow's path/center fns return positional tuples
//     (`[path, labelX, labelY, offsetX, offsetY]`); PSFlow uses records.
//   * null → undefined: PSFlow `Maybe` arrives as `Nullable` (null); a couple
//     of upstream params (`centerX`/`centerY`) are read with `?? default`, so
//     we normalise null to undefined to match "argument omitted" exactly.
//
// (`Position` sum-type → lowercase string is adapted on the PureScript side in
// Oracle.purs, since that is the only XYFlow-shape knowledge expressible there.)

import {
  getEdgeCenter,
  getStraightPath,
  getBezierPath,
  getBezierEdgeCenter,
  getSmoothStepPath,
  getSimpleBezierPath,
  clamp,
  clampPosition,
  getBoundsOfBoxes,
  rectToBox,
  boxToRect,
  getBoundsOfRects,
  getOverlappingArea,
  snapPosition,
  pointToRendererPoint,
  rendererPointToPoint,
  getViewportForBounds,
  getNodeToolbarTransform,
  getEdgeToolbarTransform,
  getMarkerId,
  getConnectionStatus,
  getOutgoers,
  getIncomers,
  getConnectedEdges,
} from "@psflow/oracle";

const pathResult = (t) => ({ path: t[0], labelX: t[1], labelY: t[2], offsetX: t[3], offsetY: t[4] });
const centerResult = (t) => ({ centerX: t[0], centerY: t[1], offsetX: t[2], offsetY: t[3] });

// ─── Edge paths (record in, EdgePathResult/EdgeCenter out) ────────────────
export const getEdgeCenterImpl = (p) => centerResult(getEdgeCenter(p));
export const getBezierEdgeCenterImpl = (p) => centerResult(getBezierEdgeCenter(p));
export const getStraightPathImpl = (p) => pathResult(getStraightPath(p));
export const getBezierPathImpl = (p) => pathResult(getBezierPath(p));
export const getSimpleBezierPathImpl = (p) => pathResult(getSimpleBezierPath(p));
export const getSmoothStepPathImpl = (p) =>
  pathResult(
    getSmoothStepPath({
      sourceX: p.sourceX,
      sourceY: p.sourceY,
      sourcePosition: p.sourcePosition,
      targetX: p.targetX,
      targetY: p.targetY,
      targetPosition: p.targetPosition,
      borderRadius: p.borderRadius,
      centerX: p.centerX == null ? undefined : p.centerX,
      centerY: p.centerY == null ? undefined : p.centerY,
      offset: p.offset,
      stepPosition: p.stepPosition,
    })
  );

// ─── Geometry (curried scalars / records / arrays) ────────────────────────
export const clampImpl = (val) => (mn) => (mx) => clamp(val, mn, mx);
export const getBoundsOfBoxesImpl = (a) => (b) => getBoundsOfBoxes(a, b);
export const rectToBoxImpl = (r) => rectToBox(r);
export const boxToRectImpl = (b) => boxToRect(b);
export const getBoundsOfRectsImpl = (a) => (b) => getBoundsOfRects(a, b);
export const getOverlappingAreaImpl = (a) => (b) => getOverlappingArea(a, b);
export const snapPositionImpl = (pos) => (grid) => snapPosition(pos, grid);
export const clampPositionImpl = (pos) => (extent) => (dims) => clampPosition(pos, extent, dims);
export const pointToRendererPointImpl = (pos) => (transform) => (snapToGrid) => (grid) =>
  pointToRendererPoint(pos, transform, snapToGrid, grid);
export const rendererPointToPointImpl = (pos) => (transform) => rendererPointToPoint(pos, transform);

// ─── fitView viewport (Padding ADT → upstream's `Padding` union) ──────────
// PSFlow models padding as a sum type; upstream models it as
// `PaddingWithUnit | { top?, right?, bottom?, left?, x?, y? }` where
// `PaddingWithUnit = \`${number}${'px' | '%'}\` | number`. The unit forms are
// built here with the same template interpolation upstream's own type is
// written in, so no PureScript number formatting sits in the round-trip —
// upstream recovers the double with `parseFloat`.
export const paddingValueImpl = (unit) => (n) => (unit === "" ? n : `${n}${unit}`);
// A bare `PaddingWithUnit` *is* a `Padding`; the lift is upstream's union, not
// a conversion.
export const uniformPaddingImpl = (value) => value;
// Absent sides arrive as `null`. Upstream reads them with `??`
// (`padding.top ?? padding.y ?? 0`), which treats null exactly as absent, so
// the record passes through unchanged.
export const directionalPaddingImpl = (sides) => sides;

export const getViewportForBoundsImpl =
  (bounds) => (width) => (height) => (minZoom) => (maxZoom) => (padding) =>
    getViewportForBounds(bounds, width, height, minZoom, maxZoom, padding);

// ─── Toolbar transforms (curried scalars/records, string out) ─────────────
export const getNodeToolbarTransformImpl =
  (rect) => (viewport) => (position) => (offset) => (align) =>
    getNodeToolbarTransform(rect, viewport, position, offset, align);
export const getEdgeToolbarTransformImpl =
  (x) => (y) => (zoom) => (alignX) => (alignY) =>
    getEdgeToolbarTransform(x, y, zoom, alignX, alignY);

// ─── Markers ──────────────────────────────────────────────────────────────
// Rebuild upstream's EdgeMarkerType from the tagged MarkerArg: a bare string
// for a named marker, or an EdgeMarker object whose Nothing (null) fields are
// OMITTED — `getMarkerId` enumerates `Object.keys(marker).sort()`, so a present
// key with a null value would wrongly emit `key=null`.
const buildMarker = (a) => {
  const o = {};
  if (a.color != null) o.color = a.color;
  if (a.height != null) o.height = a.height;
  if (a.markerUnits != null) o.markerUnits = a.markerUnits;
  if (a.orient != null) o.orient = a.orient;
  if (a.strokeWidth != null) o.strokeWidth = a.strokeWidth;
  if (a.markerType != null) o.type = a.markerType;
  if (a.width != null) o.width = a.width;
  return o;
};
export const getMarkerIdImpl = (markerArg) => (id) => {
  const marker =
    markerArg == null ? undefined : markerArg.tag === "named" ? markerArg.named : buildMarker(markerArg);
  return getMarkerId(marker, id == null ? undefined : id);
};

// ─── Connections ──────────────────────────────────────────────────────────
export const getConnectionStatusImpl = (isValid) => getConnectionStatus(isValid == null ? null : isValid);

// ─── Graph traversal (return only the matched ids) ────────────────────────
export const getOutgoersImpl = (node) => (nodes) => (edges) =>
  getOutgoers(node, nodes, edges).map((n) => n.id);
export const getIncomersImpl = (node) => (nodes) => (edges) =>
  getIncomers(node, nodes, edges).map((n) => n.id);
export const getConnectedEdgesImpl = (nodes) => (edges) =>
  getConnectedEdges(nodes, edges).map((e) => e.id);
