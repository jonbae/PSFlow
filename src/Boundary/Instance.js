// FFI for `Boundary.Instance`. Everything here is a type test upstream makes
// inline, or an object operation JavaScript spells with syntax PureScript has
// no equivalent for. Nothing here decides anything: the branches these feed
// are all in the PureScript module, where the reasoning can be read beside the
// method it belongs to.
//
// The three untagged unions the instance accepts each need one test:
//
//   * `getIntersectingNodes` / `isNodeIntersecting` take `Node | { id } | Rect`
//     — `isRectObject` and `positionField`.
//   * `getNodesBounds` takes `Node | InternalNode | string` — `internalsField`
//     alongside `positionField`.
//   * `updateNode`'s `replace` branch takes a whole element or nothing —
//     `wholeElement`.

// Upstream's own `isRectObject`, in `@xyflow/system`'s `utils/general.ts`. The
// finiteness test is upstream's `isNumeric` and matters: a rect whose width is
// `NaN` is not a rect, and reading it as one would send a garbage bound into
// `fitBounds` instead of reporting the argument.
const numeric = (n) => typeof n === "number" && !isNaN(n) && isFinite(n);

export const isRectObject = (value) =>
  value !== null &&
  typeof value === "object" &&
  numeric(value.width) &&
  numeric(value.height) &&
  numeric(value.x) &&
  numeric(value.y);

const object = (value) => value !== null && typeof value === "object";

// Upstream's `isNodeBase` is `'id' in element && 'position' in element`, minus
// the edge exclusions it needs and this does not — the caller has already
// ruled out a rect, and an `{ id }` reference has no `position`.
export const positionField = (value) => object(value) && "position" in value;

export const wholeElement = (value) =>
  object(value) && ("position" in value || "source" in value);

export const internalsField = (value) => object(value) && "internals" in value;

// Deliberately total: a caller who passed a string, a number or `null` gets
// `undefined` here and a named error from the PureScript side, rather than a
// `TypeError` naming neither the method nor the argument.
export const identityField = (value) => (object(value) ? value.id : undefined);

export const dataField = (value) => (object(value) ? value.data : undefined);

export const asDataField = (value) => ({ data: value });

// `{ ...target, ...source }`. A fresh object, never a mutation of either side:
// the consumer is holding `target` — it is the element we just handed their
// updater — and upstream's spread does not write to it either.
//
// Curried, because its PureScript type is: `Fn2` would be the alternative and
// buys nothing for two arguments neither side ever partially applies.
export const mergeInto = (target) => (source) => Object.assign({}, target, source);
