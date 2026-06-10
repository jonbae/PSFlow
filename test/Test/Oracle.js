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
