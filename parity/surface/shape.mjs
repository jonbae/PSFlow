// Surface parity — the shape of one exported binding.
//
// A name that resolves on both sides can still be uncallable from JavaScript:
// `getIncomers` takes three arguments upstream and one here, `ReactFlow` is a
// `forwardRef` upstream and a bare function here. Neither is visible to a name
// comparison, and neither needs a browser to see — `typeof`, arity and React
// wrapper kind are all readable from the imported value.
//
// Three fields, deliberately no more:
//
//   kind      the `typeof` of the innermost value, or `"absent"` for a name the
//             module does not export at all. `absent` and `undefined` are
//             distinct: the first is a name that was never published, the
//             second is a published name whose binding did not resolve.
//   wrappers  the React wrapper chain, outermost first (`["memo",
//             "forwardRef"]`). An unrecognised `$$typeof` is recorded under its
//             own description rather than flattened into `"object"`, so a
//             wrapper nobody anticipated reads as a difference instead of
//             passing as plain data.
//   arity     `Function.length` of the innermost function, else `null`.
//
// What it deliberately does not look at: an object's contents. Deep-equalling
// the frozen enum objects and calling the pure functions are worth doing and
// are ticket 45's; this module stops at the outside of the value so it stays
// total — it must be safe to apply to all 68 exports without invoking any.
//
// Sharp edge, accepted: `Function.length` ignores default and rest parameters,
// so an arity difference is occasionally a legitimate difference in how the
// two sides declare their parameters rather than a currying gap. Those become
// permanent allowlist entries.

/** A name the module does not export. Distinct from an unresolved binding. */
export const ABSENT = Object.freeze({ kind: "absent", wrappers: Object.freeze([]), arity: null });

// Matched on the global symbol registry rather than on the description string:
// `Symbol.for("react.memo")` is the same symbol whichever copy of React built
// the element, which is what lets an upstream bundle and PSFlow's compiled
// output be compared at all.
const WRAPPERS = [
  { tag: Symbol.for("react.memo"), name: "memo", inner: (v) => v.type },
  { tag: Symbol.for("react.forward_ref"), name: "forwardRef", inner: (v) => v.render },
];

/** The shape of an imported value. Never calls it, never enumerates it. */
export const shapeOf = (value) => {
  const wrappers = [];
  let core = value;

  // Bounded by the chain it walks: every step unwraps one React wrapper, and a
  // wrapper it does not recognise terminates the walk.
  for (;;) {
    if (core === null || typeof core !== "object") break;
    const tag = core.$$typeof;
    if (typeof tag !== "symbol") break;
    const wrapper = WRAPPERS.find((w) => w.tag === tag);
    if (!wrapper) {
      wrappers.push(tag.description ?? String(tag));
      break;
    }
    wrappers.push(wrapper.name);
    core = wrapper.inner(core);
  }

  const kind = core === null ? "null" : typeof core;
  return { kind, wrappers, arity: kind === "function" ? core.length : null };
};

/** The one-line form used in the report and in failure output. */
export const formatShape = (shape) => {
  const core = shape.kind === "function" ? `fn/${shape.arity}` : shape.kind;
  return shape.wrappers.reduceRight((inner, wrapper) => `${wrapper}(${inner})`, core);
};

export const sameShape = (a, b) =>
  a.kind === b.kind &&
  a.arity === b.arity &&
  a.wrappers.length === b.wrappers.length &&
  a.wrappers.every((w, i) => w === b.wrappers[i]);

/**
 * One row per name whose two shapes disagree, in the order the names are given.
 * A name missing from either side is `absent` there, which is itself a
 * difference — a PSFlow-only export has no upstream shape to agree with.
 */
export const shapeDifferences = (upstreamShapes, psflowShapes, names) =>
  names
    .map((name) => ({
      name,
      upstreamShape: upstreamShapes[name] ?? ABSENT,
      psflowShape: psflowShapes[name] ?? ABSENT,
    }))
    .filter((row) => !sameShape(row.upstreamShape, row.psflowShape))
    .map((row) => ({
      name: row.name,
      upstream: formatShape(row.upstreamShape),
      psflow: formatShape(row.psflowShape),
    }));
