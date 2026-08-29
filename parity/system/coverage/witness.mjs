// Witnesses — the rule joining a captured trace back to an export it proves was
// driven (#57).
//
// Coverage here is **derived from runs that actually happened**, never
// declared. That is the whole choice this file implements, and it costs about
// what declaring would: roughly one hand-written line per export either way.
// What the line buys is trustworthiness — a derived number can be *wrong* (a
// selector matches something the scenario did not really drive), where a
// declared number can be *fiction* and stay green forever. Something has to
// have appeared in a captured trace.
//
// There are two kinds of witness, and which kind an export takes is decided by
// the section it lands in rather than by the entry:
//
//   * **a selector**, for `dom`'s 64 — `MiniMap` is driven if the section holds
//     an element matching `.react-flow__minimap`
//   * **a name mapping**, for `callbacks` / `hooks` / `api` / `props` — a list
//     of the runtime names that would prove the export. Many-to-one in places:
//     `NodeMouseHandler` is the type behind `onNodeClick`, `onNodeMouseEnter`
//     and several more, and any one of them witnesses it.
//
// ## The names a section offers
//
// A **name** is what the runtime called something the section recorded, which
// is not always a handler's name. Twelve of the `callbacks` exports are members
// of the `NodeChange` / `EdgeChange` unions, and every one of them rides on
// `onNodesChange` or `onEdgesChange`: witnessing them by the handler alone
// would count `NodeAddChange` as driven the moment a mount fired one dimension
// change, which is exactly the fiction deriving is meant to rule out. So a
// change's own `type` discriminant is a name too, written `onNodesChange:add`.
//
// The index is deliberately generous — a payload array of nodes contributes
// `onNodeDrag:input` for a node whose type is `input`, which no witness names
// and which harmlessly goes unread. Deciding is the *witness's* job; the index
// only says what was recorded.

export class WitnessError extends Error {
  constructor(message) {
    super(message);
    this.name = "WitnessError";
  }
}

// ── Selectors ──────────────────────────────────────────────────────────────
// A closed, tiny subset of CSS: compounds separated by whitespace, where a
// compound is `*` or an optional tag with any number of `.class`, `[attr]`,
// `[attr=value]`, `[attr~=value]` and `[attr*=value]`. Whitespace is the
// descendant combinator and it is the only one — a child or sibling relation is
// a claim about structure the `dom` comparison already makes far better than a
// coverage rule could.
//
// The descendant combinator earns its place on one recurring shape rather than
// on generality: the renderer draws `.react-flow__viewport-portal` and
// `.react-flow__edgelabel-renderer` whether or not anything is portaled into
// them, so a selector on the container would witness `ViewportPortal` for every
// fixture that mounts a flow at all. `.react-flow__viewport-portal *` asks the
// question the export is actually about.

const SELECTOR_PART = /^(?:([a-zA-Z][\w-]*)|\.([\w-]+)|\[([\w:-]+)(?:([~*]?=)"?([^\]"]*)"?)?\])/;

const ATTR_TESTS = {
  "=": (value, want) => value === want,
  "~=": (value, want) => value.split(/\s+/).includes(want),
  "*=": (value, want) => value.includes(want),
};

const ANY = () => true;

/** One compound — everything asked of a single element — as a predicate. */
const compileCompound = (selector, compound) => {
  if (compound === "*") return ANY;

  let rest = compound;
  let tag = null;
  const classes = [];
  const attrs = [];

  while (rest !== "") {
    const part = SELECTOR_PART.exec(rest);
    if (!part) {
      throw new WitnessError(
        `${JSON.stringify(selector)} is not a witness selector at ${JSON.stringify(rest)}. The language is ` +
          `compounds separated by whitespace, where a compound is \`*\` or a tag with any number of ` +
          `\`.class\`, \`[attr]\`, \`[attr=value]\`, \`[attr~=value]\` and \`[attr*=value]\`. Whitespace is ` +
          `the descendant combinator and it is the only one.`
      );
    }
    const [matched, name, klass, attr, op, want] = part;
    if (name !== undefined) {
      if (tag !== null) throw new WitnessError(`${JSON.stringify(selector)} names two tags in one compound`);
      tag = name;
    } else if (klass !== undefined) classes.push(klass);
    else attrs.push({ attr, op: op ?? null, want: want ?? null });
    rest = rest.slice(matched.length);
  }

  return (element) => {
    if (tag !== null && element.tag !== tag) return false;
    const carried = element.attrs ?? {};
    const tokens = String(carried.class ?? "").split(/\s+/);
    if (!classes.every((klass) => tokens.includes(klass))) return false;
    return attrs.every(({ attr, op, want }) => {
      if (!(attr in carried)) return false;
      return op === null || ATTR_TESTS[op](String(carried[attr]), want);
    });
  };
};

/**
 * `selector` as a predicate over a recorded subtree: does anything under this
 * element — the element itself included — match?
 *
 * Compiled once and applied to every element of every trace, which is why this
 * returns a function rather than taking the tree too: the corpus is a hundred
 * and twenty traces deep and the register holds sixty-four of these.
 */
export const compileSelector = (selector) => {
  if (typeof selector !== "string" || selector.trim() === "") {
    throw new WitnessError("a dom witness needs a selector");
  }

  const compounds = selector.trim().split(/\s+/).map((compound) => compileCompound(selector, compound));
  const last = compounds.length - 1;

  // Descendant is transitive, so satisfying a compound as early as possible can
  // never cost a later one a match: search greedily from here, and independently
  // keep looking deeper for a *first* match at the same compound.
  const search = (element, at) => {
    if (!element || typeof element !== "object") return false;
    const children = element.children ?? [];
    if (compounds[at](element)) {
      if (at === last) return true;
      if (children.some((child) => search(child, at + 1))) return true;
    }
    return children.some((child) => search(child, at));
  };

  return (element) => search(element, 0);
};

/**
 * Whether any element of a recorded `dom` section matches.
 *
 * `root` is null when the flow selector did not resolve — a side that never
 * rendered. That is a finding the comparison reads; here it witnesses nothing,
 * because one failed capture must not take the whole artifact down with it.
 */
export const holdsInDom = (dom, matches) => {
  const root = dom?.root ?? null;
  return root !== null && matches(root);
};

// ── The names each section offers ──────────────────────────────────────────
// One reading per section, and each is a reading of the shape the trace format
// already fixes rather than an invention: `callbacks` is a list of `{ name,
// args }`, `api` is `{ queries, calls }`, and `hooks` and `props` are keyed by
// probe id. Issue #59's probes now fill those sections selectively; an empty
// reading remains meaningful for plain scenarios and direct component routes.

const changeNames = (name, args, into) => {
  for (const arg of args ?? []) {
    if (!Array.isArray(arg)) continue;
    for (const element of arg) {
      if (element && typeof element === "object" && typeof element.type === "string") {
        into.add(`${name}:${element.type}`);
      }
    }
  }
};

const probeNames = (section, into) => {
  for (const [probe, reported] of Object.entries(section ?? {})) {
    into.add(probe);
    if (reported && typeof reported === "object" && !Array.isArray(reported)) {
      for (const key of Object.keys(reported)) into.add(key);
    }
  }
};

const NAMES_IN = {
  callbacks: (section, into) => {
    for (const { name, args } of section ?? []) {
      into.add(name);
      changeNames(name, args, into);
    }
  },
  api: (section, into) => {
    for (const key of Object.keys(section?.queries ?? {})) into.add(key);
    for (const { method } of section?.calls ?? []) into.add(method);
  },
  hooks: probeNames,
  props: probeNames,
};

/** Every name one recorded section offers a witness. */
export const namesIn = (section, value) => {
  const read = NAMES_IN[section];
  if (!read) throw new WitnessError(`the ${section} section offers no names to witness with`);
  const names = new Set();
  read(value, names);
  return names;
};

// ── The register ───────────────────────────────────────────────────────────

/**
 * The five sections that carry exports, in the order a report reads them.
 *
 * Not a count of anything: how many of the 156 land in each is the census's
 * answer and is derived, never written here.
 */
export const SECTIONS_WITH_EXPORTS = Object.freeze(["dom", "callbacks", "hooks", "api", "props"]);

/**
 * One register entry, against the section its export lands in, as something
 * that can be asked of a trace.
 *
 * The section is not the entry's to declare — it is derived from the census,
 * which is what makes a witness naming an export the surface no longer holds
 * fail rather than quietly describing a section that does not exist. An entry
 * whose kind does not suit its section is a mis-edit and throws here; an entry
 * naming an export the census does not carry is *stale*, which is a finding and
 * belongs to the join.
 */
export const compileWitness = (entry, section) => {
  const at = `witness for ${entry?.export ?? "no export"}`;
  const names = entry?.names;
  const selector = entry?.selector;

  if (section === "dom") {
    if (names !== undefined) throw new WitnessError(`${at}: lands in dom and so needs a selector, not a name mapping`);
    const matches = compileSelector(selector);
    return {
      export: entry.export,
      section,
      kind: "selector",
      describe: selector,
      note: entry.note ?? null,
      holdsIn: (sections) => holdsInDom(sections?.dom, matches),
    };
  }

  if (selector !== undefined) {
    throw new WitnessError(`${at}: lands in ${section} and so needs a name mapping, not a selector`);
  }
  if (!Array.isArray(names) || names.length === 0 || names.some((n) => typeof n !== "string" || n === "")) {
    throw new WitnessError(
      `${at}: needs a name mapping — a non-empty list of the runtime names that would prove it. An entry ` +
        `naming nothing could never witness anything, and would report the export as a hole forever.`
    );
  }

  return {
    export: entry.export,
    section,
    kind: "names",
    names: [...names],
    describe: names.join(", "),
    note: entry.note ?? null,
    holdsIn: (sections) => {
      const offered = namesIn(section, sections?.[section]);
      return names.some((name) => offered.has(name));
    },
  };
};
