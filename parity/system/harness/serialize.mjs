// The argument serializer — what a callback was handed, as trace content (#44).
//
// The one harness module that runs **in the page** rather than in node: it is
// handed live JavaScript values by the in-page callback log (#54) and turns them
// into the JSON the `callbacks` section carries. Everything else under
// `harness/` drives a browser from outside one; this is the piece that has to be
// bundled into the driver alongside it. It imports nothing, for that reason.
//
// The rule, from the noise policy (#19 §6):
//
//   > Serialize every **enumerable own property**. Blacklist only
//   > **reference-typed** fields.
//
// Both halves are load-bearing, and the second half's word *only* is the sharper
// one. A whitelist — "record `type`, `clientX`, `button`" — is a hand-authored
// reading of what xyflow passes, which is the failure mode this whole effort
// exists to avoid: a field nobody thought to ask for is a field that can differ
// forever. So every own property is taken, and the only thing dropped is a
// value that *is* an identity — a DOM node, a function, a React fiber — where
// the two sides could not agree even in principle, since each rendered its own.
//
// ## Why this catches a synthetic event where a native one is expected
//
// A React synthetic event carries its fields as enumerable own properties. A
// native event carries them on `Event.prototype`, as accessors — so it has
// **no own enumerable properties at all**. Serialize by own property and the
// two are wildly different objects, which no shape check and no DOM diff can
// see: both are `object`, and neither leaves a mark on the page.
//
// That is also why the class name is recorded. Without it two native events of
// different kinds — a `MouseEvent` where a `PointerEvent` belongs — both
// serialize to `{}` and compare **clean**, which is the silent pass this repo
// keeps paying for. `@class` appears only when a value's prototype is not
// `Object.prototype`, so the marker's presence is itself information.
//
// ## The bound worth knowing
//
// A value whose content lives on its prototype records its class and nothing
// else. That is the rule applied honestly rather than a gap — but it means a
// `Date`, a `Map` or a `RegExp` reaching a callback argument would be observed
// as its kind alone. xyflow passes none today; a scenario that makes one reach
// here needs a decision, not a quiet special case.

/**
 * The reserved keys. Each is either the whole of a serialized value — `@ref`,
 * `@cycle`, `@number` — or, in `@class`'s case, sits alongside the value's own
 * properties. They lead with `@` because no JavaScript identifier does, and an
 * object that owns one anyway is a hard error below rather than a value
 * indistinguishable from a marker.
 */
export const MARKER = Object.freeze({
  class: "@class",
  ref: "@ref",
  cycle: "@cycle",
  depth: "@depth",
  threw: "@threw",
  number: "@number",
  undefined: "@undefined",
  bigint: "@bigint",
  symbol: "@symbol",
});

const RESERVED = new Set(Object.values(MARKER));

export class SerializationError extends Error {
  constructor(message) {
    super(message);
    this.name = "SerializationError";
  }
}

// A path renders the way `compare/paths.mjs` renders one, so a `@cycle` points
// at something a reader can find in the report's own address language. The two
// halves of the net never import each other, which is what the duplication buys.
const formatPath = (path) => path.map((s) => String(s).replace(/~/g, "~0").replace(/\//g, "~1")).join("/");

// ── Reference-typed values ─────────────────────────────────────────────────
// Closed, and each entry is a value whose whole content is its identity. Every
// one is duck-typed rather than tested with `instanceof`, because this module
// runs in the page and its tests run in node, where `Element` and `Window` do
// not exist — and a check that silently stopped recognising DOM nodes outside a
// browser would make the tests prove something else.

const referenceKind = (value) => {
  if (typeof value === "function") return "function";
  if (typeof value !== "object" || value === null) return null;

  // A DOM node. `nodeName` is the kind — `DIV`, `BUTTON` — which both sides can
  // agree on; *which* div it was is the `dom` section's question, and one this
  // section could not answer without recording an identity neither side shares.
  if (typeof value.nodeType === "number" && typeof value.nodeName === "string") return value.nodeName;

  // The global, reached through `event.view`.
  if (value.window === value || value.self === value) return "Window";

  // A React fiber — `_targetInst` on every synthetic event. It is a reference
  // into React's internals, and it is also the whole component tree: left in,
  // one pointer event would serialize thousands of fields that say nothing
  // about either library.
  if (typeof value.tag === "number" && "stateNode" in value && "return" in value) return "React fiber";
  if (typeof value.$$typeof === "symbol") return "React element";

  return null;
};

// ── Primitives JSON cannot carry ───────────────────────────────────────────
// A callback called with `undefined` and one called with `null` are different
// calls, and `JSON.stringify` renders both as `null`. `-0` is the same case one
// step further on: `diff.mjs` compares with `Object.is`, so it would see the
// difference the file no longer carried.

const NUMBER_MARKERS = new Map([
  [Infinity, "Infinity"],
  [-Infinity, "-Infinity"],
]);

const primitive = (value) => {
  if (value === undefined) return { [MARKER.undefined]: true };
  if (typeof value === "bigint") return { [MARKER.bigint]: String(value) };
  if (typeof value === "symbol") return { [MARKER.symbol]: String(value) };
  if (typeof value === "number") {
    if (Number.isNaN(value)) return { [MARKER.number]: "NaN" };
    if (NUMBER_MARKERS.has(value)) return { [MARKER.number]: NUMBER_MARKERS.get(value) };
    if (Object.is(value, -0)) return { [MARKER.number]: "-0" };
  }
  return value;
};

const className = (value) => {
  const prototype = Object.getPrototypeOf(value);
  if (prototype === null || prototype === Object.prototype) return null;
  const name = prototype.constructor?.name;
  return typeof name === "string" && name !== "" && name !== "Object" ? name : null;
};

// `Object.keys` reads accessors, and an accessor on a detached node throws. One
// hostile field costs its own value here; unguarded it would cost the trace,
// and a scenario that captured nothing is not a finding about either library.
const read = (object, key) => {
  try {
    return { value: object[key] };
  } catch (e) {
    return { threw: e?.constructor?.name ?? "Error" };
  }
};

/**
 * Serializes one value.
 *
 * `path` is where the value sits in the trace, used to address a cycle back to
 * the occurrence it returned to. `maxDepth` bounds a graph that is deep rather
 * than cyclic; the marker it leaves says the depth was reached, because a
 * quietly truncated branch is unobserved rather than agreeing.
 */
export const serializeValue = (value, { path = [], maxDepth = 16 } = {}) => {
  // Ancestors only, so a value that appears twice side by side is serialized
  // twice — that is two observations, not a cycle.
  const ancestors = new Map();

  const walk = (node, at, depth) => {
    // The reference check leads, because a function is not an object and would
    // otherwise reach `primitive` and be recorded as itself.
    const kind = referenceKind(node);
    if (kind !== null) return { [MARKER.ref]: kind };

    if (typeof node !== "object" || node === null) return primitive(node);

    if (ancestors.has(node)) return { [MARKER.cycle]: formatPath(ancestors.get(node)) };
    if (depth >= maxDepth) return { [MARKER.depth]: maxDepth };

    ancestors.set(node, at);
    try {
      if (Array.isArray(node)) return node.map((item, i) => walk(item, [...at, i], depth + 1));

      const out = {};
      const type = className(node);
      if (type !== null) out[MARKER.class] = type;

      for (const key of Object.keys(node)) {
        if (RESERVED.has(key)) {
          throw new SerializationError(
            `${formatPath([...at, key])} is an own property named ${JSON.stringify(key)}, which is a ` +
              `reserved marker key. Serialized that way it would be indistinguishable from the marker, ` +
              `so the marker set needs changing rather than the value hiding.`
          );
        }
        const field = read(node, key);
        out[key] = "threw" in field ? { [MARKER.threw]: field.threw } : walk(field.value, [...at, key], depth + 1);
      }
      return out;
    } finally {
      ancestors.delete(node);
    }
  };

  return walk(value, path, 0);
};

/**
 * One entry of the `callbacks` section: the handler's name and what it was
 * handed. The name is the trace's identity for the call, and the arguments are
 * addressed beneath it — `callbacks/3/args/0/dimensions/width` — so a region
 * can point at one field of one argument of one call.
 */
export const serializeCall = (name, args, { maxDepth } = {}) => ({
  name,
  args: [...args].map((argument, i) => serializeValue(argument, { path: ["args", i], maxDepth })),
});
