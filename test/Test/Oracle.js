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
  getNodesBounds,
  isNode,
  isEdge,
  addEdge,
  reconnectEdge,
  applyNodeChanges,
  applyEdgeChanges,
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

// ─── Node bounds ──────────────────────────────────────────────────────────
// The nodes arrive already shaped like upstream's `NodeBase`: `measured` is
// always present (its two fields may be null) and `width`/`height`/
// `initialWidth`/`initialHeight`/`origin` may be null. Upstream reads every one
// of them with `??`, which treats null exactly as absent, so nothing needs
// converting. No `nodeLookup` is passed — the sub-flow resolution it enables is
// a store concern, not arithmetic, and this property's claim is the bounds math.
export const getNodesBoundsImpl = (nodes) => (nodeOrigin) => getNodesBounds(nodes, { nodeOrigin });

// ─── Shape guards ─────────────────────────────────────────────────────────
// Both take the candidate straight through: the value the property builds is
// the value both sides see.
export const isNodeImpl = (element) => isNode(element);
export const isEdgeImpl = (element) => isEdge(element);

// ─── Edge list mutation ───────────────────────────────────────────────────
// `addEdge` and `reconnectEdge` report a rejected input by *calling* `onError`
// and returning the input array; PSFlow reports it by returning `Left`. Passing
// our own `onError` both silences upstream's console warning and turns that
// channel into a value the property can compare against `isLeft`.
const edgeOut = (e) => ({
  id: e.id,
  source: e.source,
  target: e.target,
  // Upstream *deletes* a null handle rather than keeping it; `toMaybe` reads
  // deleted and null alike as `Nothing`, which is what PSFlow's `Maybe` holds.
  sourceHandle: e.sourceHandle ?? null,
  targetHandle: e.targetHandle ?? null,
  // Carried through untouched by both sides, so a rebuild that dropped the
  // rest of the edge record would show up in the comparison.
  animated: e.animated,
});

export const addEdgeImpl = (edgeParams) => (edges) => {
  let errored = false;
  const result = addEdge(edgeParams, edges, { onError: () => (errored = true) });
  return { edges: result.map(edgeOut), errored };
};

export const reconnectEdgeImpl = (oldEdge) => (newConnection) => (edges) => (shouldReplaceId) => {
  let errored = false;
  const result = reconnectEdge(oldEdge, newConnection, edges, {
    shouldReplaceId,
    onError: () => (errored = true),
  });
  return { edges: result.map(edgeOut), errored };
};

// ─── Changes ──────────────────────────────────────────────────────────────
// Rebuild upstream's `NodeChange` / `EdgeChange` from the tagged carrier. Every
// optional field is OMITTED rather than set to null: `applyChange` guards on
// `typeof change.position !== 'undefined'`, and a present-but-null field would
// pass that guard and overwrite with null.
//
// `setAttributes` is upstream's `boolean | 'width' | 'height'`, which PSFlow
// models as `Maybe { width :: Boolean, height :: Boolean }`. The carrier names
// the upstream value directly so the mapping is written once, on the PureScript
// side, where the `Maybe` lives.
const setAttributesOut = (s) => (s === "true" ? true : s === "false" ? false : s);

const nodeChangeOut = (c) => {
  switch (c.tag) {
    case "select":
      return { type: "select", id: c.id, selected: c.selected };
    case "position": {
      const change = { type: "position", id: c.id, dragging: c.dragging };
      if (c.position != null) change.position = c.position;
      return change;
    }
    case "dimensions": {
      const change = { type: "dimensions", id: c.id, resizing: c.resizing };
      if (c.dimensions != null) change.dimensions = c.dimensions;
      if (c.setAttributes != null) change.setAttributes = setAttributesOut(c.setAttributes);
      return change;
    }
    case "remove":
      return { type: "remove", id: c.id };
    case "replace":
      return { type: "replace", id: c.id, item: c.item };
    case "add": {
      const change = { type: "add", item: c.item };
      if (c.index != null) change.index = c.index;
      return change;
    }
    default:
      throw new Error(`Test.Oracle: unknown node change tag ${c.tag}`);
  }
};

const edgeChangeOut = (c) => {
  switch (c.tag) {
    case "select":
      return { type: "select", id: c.id, selected: c.selected };
    case "remove":
      return { type: "remove", id: c.id };
    case "replace":
      return { type: "replace", id: c.id, item: c.item };
    case "add": {
      const change = { type: "add", item: c.item };
      if (c.index != null) change.index = c.index;
      return change;
    }
    default:
      throw new Error(`Test.Oracle: unknown edge change tag ${c.tag}`);
  }
};

// `resizing` is set by upstream's dimensions branch and dropped by PSFlow's —
// `NodeBase` has no such field (React.Store.Changes says so). It is therefore
// absent from what comes back, and unobserved rather than passing.
const appliedNodeOut = (n) => ({
  id: n.id,
  position: n.position,
  selected: n.selected,
  dragging: n.dragging,
  width: n.width ?? null,
  height: n.height ?? null,
  measured: { width: n.measured?.width ?? null, height: n.measured?.height ?? null },
});

const appliedEdgeOut = (e) => ({ id: e.id, selected: e.selected, animated: e.animated });

export const applyNodeChangesImpl = (changes) => (nodes) =>
  applyNodeChanges(changes.map(nodeChangeOut), nodes).map(appliedNodeOut);

export const applyEdgeChangesImpl = (changes) => (edges) =>
  applyEdgeChanges(changes.map(edgeChangeOut), edges).map(appliedEdgeOut);
