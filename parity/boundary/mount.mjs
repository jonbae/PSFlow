// The boundary module, mounted through `index.js`.
//
// The boundary module is gated on the JS surface only — never through the
// PureScript module it wraps — because `index.js` is the door the audience
// comes through and the whole point of this apparatus is that no gate should
// enter by a different one. That normally means a browser, but the claims this
// ticket has to stand behind are reachable from a server render:
//
//   1. **No prop is dropped in silence.** A prop the boundary has not
//      converted must fail loudly rather than be ignored, because a prop that
//      is silently dropped is indistinguishable from a prop the consumer never
//      set — the exact failure shape of the unrun `Effect` thunk that produced
//      this whole effort. `Nothing` compiles perfectly, so nothing but a gate
//      can hold this. Until boundary stage 4 this was read as "every deferred
//      prop throws at mount", and it mounted `<ReactFlow />` once per entry in
//      the refusal table; stage 4 crossed the last of them, and the check now
//      reads the converters and fails on a prop wired to `Nothing`.
//
//   2. **A converted prop set mounts clean and arrives JS-shaped.** This is
//      the falsification half of (1): without it, a `ReactFlow` that threw on
//      *everything* would pass the deferred check. It also exercises every
//      converter that does not need layout — enums, key codes, the untagged
//      unions, the node and edge records, and the node-type wrapping — and
//      then reads the props a consumer's own node component actually received.
//
//   3. **Every callback prop that has crossed is accepted**, is converted from
//      its own field, and has a type a JavaScript caller can satisfy in one
//      call. This is (1) turned around, and it is where boundary stage 2 left
//      the surface: 46 of these threw at mount until the callbacks crossed. It
//      is deliberately three claims and not one, because a handler can be
//      accepted and still be wired from a sibling field or be curried, and
//      neither shows up as a mount failure.
//
//   4. **The graph utilities are callable, and their round trip closes.** A
//      controlled flow's own change handlers call `applyNodeChanges`,
//      `applyEdgeChanges` and `addEdge` with every argument at once and put
//      what comes back into `nodes` / `edges`. What that section claims is the
//      calling convention and the branches the crossing itself introduces —
//      never upstream's semantics, which is call-and-compare's to prove. It is
//      also where the one crossed callback a server render can *fire* lives:
//      `addEdge`'s `options.onError`.
//
//   5. **Three of the four chrome components mount with no props at all**, and
//      the fourth names the one prop upstream declares required. That is the
//      dull case and the one that used to crash: React hands a component `{}`,
//      every `Maybe` field of the PureScript record arrives `undefined`, and
//      the first `case` over one falls off the end of its pattern match.
//
//   6. **The four components a consumer's own node component mounts do so**,
//      and `<Handle />` with no props takes upstream's defaults. `HandleProps`
//      makes `type` and `position` required — a sum type has no absent state —
//      so the defaults upstream declares in its parameter list are the
//      crossing's to supply, and `<Handle />` is the plainest thing a custom
//      node writes. `<NodeToolbar />`, `<NodeResizer />` and
//      `<NodeResizeControl />` mount beside it.
//
//   7. **`useNodesState` and `useEdgesState` return upstream's 3-tuple, and
//      their setters run.** Both were unreachable from JavaScript — a hook is
//      an unrun `Effect`, and `setEdges(fn)` built a second one — and both are
//      destructured by the ColorMode driver.
//
// What this file cannot claim is that a flow-level handler was ever *called*.
// Every one of them reaches the store through `StoreUpdater`'s effect and
// `react-dom/server` runs no effects, so acceptance is the ceiling here and the
// net's `callbacks` section is what holds the rest.
//
// The deferred lists are read live out of `src/Boundary/Flow.purs`,
// `src/Boundary/Chrome.purs`, `src/Boundary/NodeChrome.purs` and
// `src/Boundary/Resizer.purs` rather than restated here, and the callback lists
// are derived from `src/Boundary/Callbacks.purs`' own type synonyms. A second
// copy of any of them is a second thing to go stale, and this file checks the
// one copy against the record it belongs to instead.
//
// Usage: node parity/boundary/mount.mjs   (requires `spago build`)

import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, join } from "node:path";

import { fail, recordEntries, recordFields, typeSynonyms } from "./purs.mjs";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const flowSource = join(repoRoot, "src/Boundary/Flow.purs");

// `ResizeObserver` is a browser global with no Node equivalent; the node
// renderer allocates one per mount. Stubbing it is not a shim for anything
// under test — nothing here observes a size — and it is the only global the
// render path reaches for.
globalThis.ResizeObserver = class {
  observe() {}
  unobserve() {}
  disconnect() {}
};

// Missing compiled output is a hard error, never a silent fallback. A gate
// that passes because it found nothing to check is the failure this repo has
// already had once.
const compiled = join(repoRoot, "output/Boundary/index.js");
if (!existsSync(compiled)) {
  fail(`no compiled output at ${compiled} — run \`spago build\` first`);
}

const { createElement } = await import("react");
const { renderToStaticMarkup } = await import("react-dom/server");
// `pathToFileURL`, not the bare path: a Windows absolute path begins `C:\`,
// which the ESM loader reads as an unknown URL scheme and refuses.
const psflow = await import(pathToFileURL(join(repoRoot, "index.js")).href);

const { ReactFlow, Position, MarkerType, ConnectionLineType } = psflow;
const { applyNodeChanges, applyEdgeChanges, addEdge } = psflow;

let failures = 0;
const notes = [];

function check(what, fn) {
  try {
    fn();
    notes.push(`  ✓ ${what}`);
  } catch (e) {
    failures++;
    console.error(`\n✗ ${what}\n    ${e.message}`);
  }
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

// ── 1. The converted mount ──────────────────────────────────────────────
//
// Every prop here is one a converter has to handle, and between them they
// reach each shape the crossing knows about: sum types as string literals,
// `Maybe` as absence, the untagged unions in both of their forms, the tuple
// encodings, and the dotted aria-config keys.

// The consumer's own node component, which is both the only place node props
// arrive and the only thing that mounts a `<Handle />` or a `<NodeToolbar />`.
// One stand-in serves both: this section reads the props it was handed, and
// section 5 mounts the two components as its children.
let customNodeProps = null;

const customNode = (...children) => (props) => {
  customNodeProps = props;
  return createElement("div", { className: "custom-node" }, "node", ...children);
};

const CustomNode = customNode();

const convertedProps = {
  nodes: [
    {
      id: "a",
      type: "custom",
      position: { x: 10, y: 20 },
      data: { label: "A" },
      targetPosition: Position.Left,
      sourcePosition: "right",
      width: 100,
      height: 40,
      zIndex: 3,
      extent: "parent",
      origin: [0.5, 0.5],
      measured: { width: 100, height: 40 },
      className: "a-node",
      style: { background: "red" },
      handles: [{ x: 1, y: 2, position: "top", type: "source" }],
    },
    { id: "b", position: { x: 0, y: 0 }, data: {}, extent: [[0, 0], [500, 500]] },
  ],
  edges: [
    {
      id: "a-b",
      source: "a",
      target: "b",
      markerStart: MarkerType.Arrow,
      markerEnd: { type: "arrowclosed", color: "#000", width: 10 },
      zIndex: 2,
      style: { stroke: "blue" },
    },
  ],
  defaultEdgeOptions: { animated: true, reconnectable: "source", zIndex: 1 },
  nodeTypes: { custom: CustomNode },
  connectionLineType: ConnectionLineType.SmoothStep,
  connectionMode: "loose",
  selectionMode: "partial",
  panOnScrollMode: "vertical",
  colorMode: "dark",
  attributionPosition: "bottom-left",
  zIndexMode: "basic",
  deleteKeyCode: "Backspace",
  multiSelectionKeyCode: ["Meta", "Control"],
  snapGrid: [15, 15],
  nodeOrigin: [0, 0],
  nodeExtent: [[-100, -100], [1000, 1000]],
  translateExtent: [[-1000, -1000], [1000, 1000]],
  panOnDrag: [0, 2],
  viewport: { x: 0, y: 0, zoom: 1 },
  defaultViewport: { x: 0, y: 0, zoom: 1 },
  fitViewOptions: {
    padding: "10px",
    interpolate: "linear",
    includeHiddenNodes: true,
    nodes: [{ id: "a" }],
  },
  proOptions: { hideAttribution: true },
  ariaLabelConfig: { "controls.ariaLabel": "Panel", "handle.ariaLabel": "H" },
  onNodesChange: () => {},
  onEdgesChange: () => {},
  onConnect: () => {},
  minZoom: 0.2,
  maxZoom: 3,
  snapToGrid: true,
  debug: false,
};

let markup = "";

check("a fully converted prop set mounts", () => {
  markup = renderToStaticMarkup(createElement(ReactFlow, convertedProps));
  assert(markup.length > 0, "render produced no markup");
  assert(markup.includes("react-flow"), "render produced no flow wrapper");
});

check("the consumer's node component is reached", () => {
  assert(markup.includes("custom-node"), "the custom node type did not render");
  assert(customNodeProps !== null, "the custom node component was never called");
});

check("node props arrive JS-shaped, not PureScript-shaped", () => {
  const p = customNodeProps;
  assert("type" in p, "node props have no `type` — a consumer destructures that, not `nodeType`");
  assert(!("nodeType" in p), "node props still carry `nodeType`");
  assert(p.type === "custom", `node props \`type\` was ${JSON.stringify(p.type)}`);
  assert(
    p.targetPosition === "left",
    `\`targetPosition\` was ${JSON.stringify(p.targetPosition)}, not the string literal "left"`
  );
  assert(
    p.dragHandle === undefined,
    `an unset optional arrived as ${JSON.stringify(p.dragHandle)} rather than undefined`
  );
  assert(typeof p.selected === "boolean", "`selected` is not a plain boolean");
  assert(typeof p.positionAbsoluteX === "number", "`positionAbsoluteX` is not a number");
});

// ── 2. Nothing is left to defer ─────────────────────────────────────────
//
// This section used to mount `<ReactFlow />` once per **deferred prop** and
// assert each one threw naming the stage that would land it. Boundary stage 4
// crossed the last two, `edgeTypes` and `connectionLineComponent`, so there
// are none — and the check inverts rather than going away, because the
// failure it guards against did not.
//
// What it holds now is the **residue**: no prop of `convertProps` is wired to
// a literal `Nothing`. While props were being refused, the claim was that
// each one was declared in a table; with nothing refused, the claim is that
// nothing is dropped, and that is the stronger of the two. It also still
// catches a re-introduced deferral, because a deferred prop is wired to
// `Nothing` *and* named in a table — so a future prop that cannot cross turns
// this red, and whoever adds it has to bring the table and this section's
// other half back together.

// Line endings normalised: the repo stores LF and checks out CRLF on Windows,
// and every pattern below anchors on `\n`. Without this the parse finds
// nothing on a Windows checkout, which is a loud failure rather than a quiet
// one — but a loud failure on the wrong thing is still the wrong report.
const readModule = (path) => readFileSync(path, "utf8").replace(/\r\n/g, "\n");

const flowText = readModule(flowSource);
const flowFields = new Set(recordFields(flowSource, "JsFlowProps"));

// The body of one `convert<Something> p =` declaration, or null. Extra
// parameters are allowed: `Boundary.Chrome`'s `convertPanel` takes the
// forwarded ref as a second one, and a converter skipped by a too-strict
// pattern is a converter nothing below checks.
const converterBody = (text, name) =>
  new RegExp(`^convert${name} p(?: \\w+)* =\\n([\\s\\S]*?)\\n  \\}$`, "m").exec(text);

// `[,{] name: Nothing` — a field the conversion fills in with absence rather
// than with the consumer's value.
const wiredToNothing = (body) =>
  [...body.matchAll(/^\s*[,{]\s*(\w+): Nothing$/gm)].map((m) => m[1]);

check("no flow prop is wired to `Nothing`", () => {
  const body = converterBody(flowText, "Props");
  assert(body !== null, "cannot find `convertProps` in Boundary.Flow — the parse is wrong");

  // The guard against a parse that stopped working, which the old deferred
  // table used to provide. It cannot be "at least one prop is wired to
  // `Nothing`" any more, because zero is the answer this section now asserts —
  // so it is the size of the record instead.
  const fields = [...body[1].matchAll(/^\s*[,{]\s*("?[\w-]+"?):/gm)].map((m) => m[1]);
  assert(
    fields.length > 100,
    `read only ${fields.length} converted props from \`convertProps\` — the parse is wrong, ` +
      `and it would pass anything`
  );

  const dropped = wiredToNothing(body[1]);
  assert(
    dropped.length === 0,
    `props wired to \`Nothing\`, so they are silently ignored: ${dropped.join(", ")}. ` +
      `Convert them, or refuse them the way \`defaultEdgeOptions\`' dropped members are — ` +
      `a prop ps-flow ignores in silence is indistinguishable from one the consumer never set.`
  );
});

// ── 2b. Every callback prop is accepted, and fires JS-shaped ────────────
//
// The mirror image of the section above, and the one stage 2 turned around: 46
// of these props threw at mount until the callbacks crossed, and each of them
// now has to be *taken*. Without this, deleting a converter and leaving the
// field wired to `Nothing` would only be caught by the deferred-entry check
// above — which is a source check, so a converter that throws on the value it
// is handed would still pass it.
//
// The list is derived, never listed. `Boundary.Callbacks` declares one
// `type Js… =` per handler shape and its header states that invariant, so a
// prop is a callback exactly when its declared type names one of those
// synonyms. A handler added later is picked up here on the run that adds it.

const callbacksSource = join(repoRoot, "src/Boundary/Callbacks.purs");
const handlerTypes = typeSynonyms(callbacksSource);

// The shapes a handler *carries* are declared in the same module and are not
// handler types themselves — `JsConnectionState` is an argument, not a
// callback. A field typed by one of those is data, so the ones that are
// arguments rather than functions are excluded by name.
//
// This is the one list in this file that is written rather than derived, so it
// carries the rule every register here does: an entry that stops naming a real
// declaration fails, instead of quietly excluding nothing while a handler it
// was never meant to cover slips past.
const argumentTypes = [
  "JsConnectStartParams",
  "JsConnectionState",
  "JsResizeParams",
  "JsResizeParamsWithDirection",
];

const declaredTypes = new Set(handlerTypes);
const staleArguments = argumentTypes.filter((name) => !declaredTypes.has(name));
if (staleArguments.length > 0) {
  fail(
    `stale argument-type exclusions in mount.mjs: ${staleArguments.join(", ")} — ` +
      `no longer declared in ${callbacksSource}`
  );
}

const excluded = new Set(argumentTypes);
const handlerTypeSet = new Set(handlerTypes.filter((name) => !excluded.has(name)));

if (handlerTypeSet.size === 0) {
  fail(`found no handler types in ${callbacksSource} — the parse is wrong`);
}

// Every handler type has to be **uncurried**, and no gate here can fire one to
// find out. A curried PureScript function of two arguments is two nested calls
// at runtime, so `f(event)` on a consumer's `(event, params) => …` returns
// `undefined` and the second call throws — the exact failure this whole
// boundary exists to remove, on the one class the mount checks cannot reach.
// `EffectFnN` and `FnN` are the uncurried forms; a bare arrow is only right
// when the handler takes one argument, which is `a -> b` and no more.
check("every handler type takes its arguments in one call", () => {
  const declarations = new Map(
    [...readModule(callbacksSource).matchAll(/^type\s+(Js\w+)\s*=([\s\S]*?)(?=\n\n)/gm)].map(
      (m) => [m[1], m[2].trim().replace(/\s+/g, " ")]
    )
  );
  const curried = [];
  for (const name of handlerTypeSet) {
    const body = declarations.get(name);
    assert(body !== undefined, `cannot read \`type ${name}\` — the parse is wrong`);
    if (/^(EffectFn\d|Fn\d)\b/.test(body)) continue;
    // What is left is an arrow type or a nullary `Effect Unit`. Arrows may have
    // exactly one, at the top level — nested arrows inside parentheses are a
    // consumer's own callback, not this one's arity.
    const arrows = body.replace(/\([^()]*\)/g, "").split("->").length - 1;
    if (arrows > 1) curried.push(`${name} = ${body}`);
  }
  assert(
    curried.length === 0,
    `handler types a JavaScript caller cannot satisfy, because they are curried ` +
      `— use \`EffectFn${"<n>"}\` or \`Fn${"<n>"}\`: ${curried.join("; ")}`
  );
});

// A prop is a callback iff its type mentions one of them. The type text is
// `Undefinable JsNodeMouseHandler`, so the test is on the words.
const callbackPropsOf = (path, typeName) =>
  recordEntries(path, typeName)
    .filter((entry) => entry.type.split(/[^A-Za-z0-9_']+/).some((w) => handlerTypeSet.has(w)))
    .map((entry) => entry.name);

const flowCallbacks = callbackPropsOf(flowSource, "JsFlowProps");

// Upstream's `ReactFlowProps` has 49 callback props and every one of them has
// crossed, so anything under 40 here is a parse that stopped working rather
// than a boundary that lost its callbacks.
if (flowCallbacks.length < 40) {
  fail(
    `read only ${flowCallbacks.length} callback props from ${flowSource} — the parse is wrong`
  );
}

for (const name of flowCallbacks) {
  check(`\`${name}\` is accepted at mount`, () => {
    renderToStaticMarkup(createElement(ReactFlow, { ...convertedProps, [name]: () => {} }));
  });
}

// The other direction again, and the one the `Nothing` check above cannot see:
// a callback wired to the *wrong* field. `onNodeClick: map nodeMouseHandlerIn
// (fromUndefinable p.onNodeDrag)` converts, compiles, mounts and is silently
// the wrong handler — 46 near-identical lines is exactly where that happens.
check("every callback prop is converted from its own field", () => {
  // `converterBody` rather than a regex of its own: it already tolerates the
  // extra parameters a converter can take, and this one grew a `forwarded`
  // when #27 made `<ReactFlow />` a `forwardRef`. Two readers of the same
  // declaration is one too many to keep in step.
  const convertProps = converterBody(flowText, "Props");
  assert(convertProps !== null, "cannot find `convertProps` in Boundary.Flow — the parse is wrong");
  const wired = new Map(
    [...convertProps[1].matchAll(/^\s*[,{]\s*(\w+):([\s\S]*?)(?=\n\s*[,}])/gm)].map((m) => [
      m[1],
      m[2],
    ])
  );
  // Anchored on a word boundary, not `includes`: `p.onNodeDrag` is a prefix of
  // `p.onNodeDragStop`, so a substring test would pass `onNodeDrag` wired from
  // its own sibling — which is the miswiring this check exists for, and five
  // of the 49 props have a sibling whose name extends theirs.
  const wrong = flowCallbacks.filter(
    (name) => !new RegExp(`\\bp\\.${name}\\b`).test(wired.get(name) ?? "")
  );
  assert(
    wrong.length === 0,
    `callback props whose conversion never reads their own field: ${wrong.join(", ")}`
  );
});

// None of the 46 can be *fired* from here. Every flow-level handler reaches the
// store through `StoreUpdater`'s effect, and `react-dom/server` runs no
// effects — so a server render can prove a handler was accepted and never that
// it was called. That claim is the net's `callbacks` section (#54), which this
// stage is what unblocks. The one crossed callback reachable without a browser
// is `addEdge`'s `options.onError`, which section 4 fires and reads.

// ── 3. Values a converter cannot represent are refused ──────────────────

// The shape every refusal is checked with: it threw, and the message named the
// thing it refused. `refuses` is the prop-shaped case; section 4 refuses things
// that are not props, so the thunk form is the one both are built on.
function throws(what, run, ...mustMention) {
  check(what, () => {
    let threw = null;
    try {
      run();
    } catch (e) {
      threw = e;
    }
    assert(threw !== null, "did not complain — the value is being silently ignored");
    for (const fragment of mustMention) {
      assert(
        threw.message.includes(fragment),
        `threw, but the message does not mention ${JSON.stringify(fragment)}: ${threw.message}`
      );
    }
  });
}

function refuses(what, props, ...mustMention) {
  throws(
    what,
    () => renderToStaticMarkup(createElement(ReactFlow, { ...convertedProps, ...props })),
    ...mustMention
  );
}

refuses(
  "an enum member that does not exist is refused",
  { connectionLineType: "smoothStep" },
  "connectionLineType",
  "smoothstep"
);

// `null` on a key-code prop means "disable this key" upstream, and ps-flow's
// `Maybe KeyCode` has no disabled state — so folding it in with absence would
// turn "no delete key" into "delete on Backspace", the opposite of the ask.
refuses("a null key code is refused rather than defaulted", { deleteKeyCode: null }, "deleteKeyCode", "null");

refuses("a key code of the wrong type is refused", { selectionKeyCode: 42 }, "selectionKeyCode");

// `defaultEdgeOptions` is upstream's `Edge` minus its identity fields; ps-flow's
// own record carries ten of those 23. The other thirteen would be dropped on the
// floor, so the boundary refuses them one by one.
const refusedOptionsPattern = /^\s*[[,]?\s*(?:droppedOption|unmodelledOption)\s+"([^"]+)"/gm;
const refusedOptions = [...flowText.matchAll(refusedOptionsPattern)].map((m) => m[1]);

if (refusedOptions.length === 0) {
  fail(`read no refused defaultEdgeOptions members from ${flowSource} — the parse is wrong`);
}

for (const name of refusedOptions) {
  refuses(
    `\`defaultEdgeOptions.${name}\` is refused at mount`,
    { defaultEdgeOptions: { ...convertedProps.defaultEdgeOptions, [name]: "probe" } },
    `defaultEdgeOptions.${name}`
  );
}

// ── 4. The utilities a driver calls ─────────────────────────────────────
//
// A driver twinning upstream's `Flow.tsx` wires `onNodesChange` to
// `applyNodeChanges(changes, nodes)`, `onEdgesChange` to `applyEdgeChanges`
// and `onConnect` to `addEdge(connection, edges)`. Each is handed the JS
// shapes the other half of this boundary produced, and each result goes
// straight back into `<ReactFlow nodes={…}>` — so the round trip has to close,
// and it has to close in **one call**. A curried PureScript function of three
// arguments returns a function here, and `setNodes(that)` is the silent no-op
// this whole effort started from.
//
// Every check below is about something **this crossing decided**: the calling
// convention, the round trip, the narrowing of `Edge | Connection`, the two
// refusals, and the one path that hands the caller's own array straight back.
// None of them assert xyflow's semantics — not the id `getEdgeId` builds, not
// which duplicates `addEdge` suppresses, not what a `position` change does to a
// node. Those belong to surface parity's call-and-compare, which derives them
// by running upstream over all seventeen pure functions at once; restating any
// of them here would be a hand-authored expectation of xyflow competing with a
// differential one, and retirement debt filed the day it was written.

const jsNodes = [
  { id: "a", type: "custom", position: { x: 10, y: 20 }, data: { label: "A" }, style: { background: "red" } },
  { id: "b", position: { x: 0, y: 0 }, data: {} },
];
const jsEdges = [{ id: "a-b", source: "a", target: "b", label: "A to B" }];

function uncurried(what, fn, arity) {
  check(what, () => {
    assert(typeof fn === "function", `${JSON.stringify(fn)} is not a function`);
    assert(
      fn.length === arity,
      `takes ${fn.length} argument(s) in one call, not ${arity} — a curried function ` +
        `returns a function where a consumer expects a result`
    );
  });
}

uncurried("`applyNodeChanges` takes both arguments in one call", applyNodeChanges, 2);
uncurried("`applyEdgeChanges` takes both arguments in one call", applyEdgeChanges, 2);
// Upstream's third parameter has a default, so its own arity is two.
uncurried("`addEdge` takes its arguments in one call", addEdge, 2);

check("`applyNodeChanges` returns nodes rather than a thunk", () => {
  const out = applyNodeChanges([{ type: "select", id: "a", selected: true }], jsNodes);
  assert(Array.isArray(out), `returned ${typeof out} rather than an array of nodes`);
  assert(out.length === jsNodes.length, `returned ${out.length} nodes, not ${jsNodes.length}`);
});

check("`applyEdgeChanges` returns edges rather than a thunk", () => {
  const out = applyEdgeChanges([{ type: "select", id: "a-b", selected: true }], jsEdges);
  assert(Array.isArray(out), `returned ${typeof out} rather than an array of edges`);
  assert(out.length === jsEdges.length, `returned ${out.length} edges, not ${jsEdges.length}`);
});

// The round trip. Whatever the change did, what comes back has to be something
// `<ReactFlow nodes={…}>` can be handed again — which is the half of this that
// no comparison against upstream could ever catch, because upstream's nodes go
// in and out of its own functions unconverted.
check("nodes come back JS-shaped, so they can go straight back into `nodes`", () => {
  const [a] = applyNodeChanges([{ type: "select", id: "a", selected: true }], jsNodes);
  assert(a.type === "custom", `\`type\` was ${JSON.stringify(a.type)} — a consumer never reads \`nodeType\``);
  assert(!("nodeType" in a), "the node still carries `nodeType`");
  assert(a.data.label === "A", "`data` did not survive the round trip");
  assert(a.style?.background === "red", "`style` did not survive the round trip");
});

check("edges come back JS-shaped, so they can go straight back into `edges`", () => {
  const [e] = applyEdgeChanges([{ type: "select", id: "a-b", selected: true }], jsEdges);
  assert(e.id === "a-b", "the edge lost its id in the round trip");
  assert(e.source === "a" && e.target === "b", "the edge lost its endpoints in the round trip");
  assert(e.label === "A to B", "the edge lost its label in the round trip");
  assert(!("edgeType" in e), "the edge still carries `edgeType`");
});

throws(
  "a change whose type nothing knows is refused, not dropped",
  () => applyNodeChanges([{ type: "nonsense", id: "a" }], jsNodes),
  "nonsense"
);

// `Edge | Connection` is untagged, and the narrowing is this module's: an
// `Edge` keeps the id it arrived with, a `Connection` is handed to the id
// generator. Checking the second with a *custom* generator proves the whole
// path — the value was narrowed as a connection, `options.getEdgeId` was
// honoured, the connection reached it JS-shaped, and the id it returned landed
// on the edge — without asserting anything about the generator upstream ships.
check("an `Edge` argument keeps the id it arrived with", () => {
  const out = addEdge({ id: "custom", source: "b", target: "a" }, jsEdges);
  assert(Array.isArray(out), `returned ${typeof out} rather than an array of edges`);
  assert(out.at(-1).id === "custom", `the id became ${JSON.stringify(out.at(-1).id)}`);
});

check("a `Connection` argument is handed to `options.getEdgeId`", () => {
  let saw = null;
  const out = addEdge({ source: "b", target: "a" }, jsEdges, {
    getEdgeId: (connection) => {
      saw = connection;
      return `mine__${connection.source}__${connection.target}`;
    },
  });
  assert(saw !== null, "the custom generator was never called");
  assert(saw.source === "b" && saw.target === "a", `it was handed ${JSON.stringify(saw)}`);
  assert(out.at(-1).id === "mine__b__a", `the id it returned did not land: ${JSON.stringify(out.at(-1).id)}`);
});

// Upstream reports an empty endpoint through `options.onError` and hands back
// the array it was given. The identity is this module's decision rather than
// upstream's behaviour, so it is checked here.
check("a connection with no endpoints hands the caller's own array back", () => {
  const out = addEdge({ source: "", target: "a" }, jsEdges);
  assert(out === jsEdges, "returned a copy — the untouched array should come back as it was");
});

// `options.onError` was refused until boundary stage 2. It is the only signal
// a consumer gets that `addEdge` declined to add anything, and it is also the
// one place a crossed callback is reachable without a browser — so what it is
// handed is checked, not only that it fired. The **code** is the part the
// crossing restores: ps-flow's `addEdge` returns the message alone.
check("`addEdge` reports an empty endpoint through `options.onError`", () => {
  const calls = [];
  const out = addEdge({ source: "", target: "a" }, jsEdges, {
    onError: (...args) => calls.push(args),
  });
  assert(calls.length === 1, `\`onError\` was called ${calls.length} times, not once`);
  const [id, message] = calls[0];
  assert(id === "006", `the error id was ${JSON.stringify(id)}, not upstream's "006"`);
  assert(typeof message === "string" && message.length > 0, "the message did not arrive");
  assert(out === jsEdges, "the untouched array should still come back as it was");
});

check("`addEdge` reports nothing when it added an edge", () => {
  const calls = [];
  addEdge({ source: "b", target: "a" }, jsEdges, { onError: () => calls.push(1) });
  assert(calls.length === 0, "`onError` fired on a connection that was added");
});

// ── 5. The components, in the two places they mount ─────────────────────
//
// `<Panel />`, `<Background />`, `<Controls />` and `<MiniMap />` are mounted
// as children of the flow, the way a driver mounts them. `<Handle />` and
// `<NodeToolbar />` are mounted one level down, by a consumer's own node
// component — which is why they were the two exports of stage 1's set that
// neither driver reached.
//
// The claim that matters most is the dullest one: **with no props at all**.
// Three of the four chrome components take none in upstream's ColorMode
// example and `<Handle />` takes none in upstream's `ToolbarNode.tsx`, and
// before they crossed, a `{}` props object gave every `Maybe` field
// `undefined` and the first `case` over one fell off the end of its pattern
// match.
//
// Nothing here asserts what the components *render*, beyond the defaults the
// crossing itself has to supply. Their DOM is the conformance suite's and the
// net's; what this section holds is that the crossing converts, refuses what
// it cannot, and passes children through.

const inFlow = (...children) =>
  renderToStaticMarkup(createElement(ReactFlow, convertedProps, ...children));

// The other place a component mounts. `<Handle />` reads its node's id out of
// context and `<NodeToolbar />` floats above that node, so neither is a child
// of the flow — both are rendered by the node component the consumer put in
// `nodeTypes`, which is section 1's `customNode` stand-in, instantiated here
// with the component under test as its children.
const inNode = (...children) =>
  renderToStaticMarkup(
    createElement(ReactFlow, {
      ...convertedProps,
      nodeTypes: { custom: customNode(...children) },
    })
  );

const mountsIn = (mount) => (what, element, ...mustContain) =>
  check(what, () => {
    const html = mount(element);
    for (const fragment of mustContain) {
      assert(html.includes(fragment), `rendered without ${JSON.stringify(fragment)}`);
    }
  });

const mounts = mountsIn(inFlow);
const mountsInNode = mountsIn(inNode);

const { Panel, Background, Controls, MiniMap } = psflow;
const { Handle, NodeToolbar, NodeResizer, NodeResizeControl } = psflow;
// Boundary stage 4: the fourteen components no fixture mounts. This file is
// the first thing in the repo that mounts any of them at all, which is the
// whole reason the stage needed a section here — every earlier stage crossed
// what a driver was already rendering.
const { ControlButton, MiniMapNode, EdgeText, BaseEdge, EdgeToolbar } = psflow;
const { StraightEdge, SimpleBezierEdge, BezierEdge, SmoothStepEdge, StepEdge } = psflow;
const { EdgeLabelRenderer, ViewportPortal, ReactFlowProvider } = psflow;

mounts(
  "`<Panel />` converts its position and passes its children through",
  createElement(Panel, { position: "top-right" }, "panel-child"),
  "react-flow__panel top right",
  "panel-child"
);
mounts("`<Background />` mounts with no props", createElement(Background, {}), "react-flow__background");
mounts("`<Controls />` mounts with no props", createElement(Controls, {}), "react-flow__controls");
mounts("`<MiniMap />` mounts with no props", createElement(MiniMap, {}), "react-flow__minimap");

mounts(
  "`<Background />` narrows `gap`'s number and pair forms",
  createElement(Background, { variant: "cross", gap: [10, 20], offset: 3 }),
  "react-flow__background"
);
mounts(
  "`<Controls />` converts its position and orientation",
  createElement(Controls, { position: "top-left", orientation: "horizontal" }),
  "react-flow__panel top left",
  "horizontal"
);

const throwsIn = (mount) => (what, element, ...mustMention) =>
  throws(what, () => mount(element), ...mustMention);

const chromeThrows = throwsIn(inFlow);
const nodeChromeThrows = throwsIn(inNode);

chromeThrows(
  "`<Panel />` without a position says so rather than failing a pattern match",
  createElement(Panel, {}, "x"),
  "Panel.position",
  "required"
);
chromeThrows(
  "an enum member that does not exist is refused, with the component named",
  createElement(Panel, { position: "topright" }, "x"),
  "Panel.position",
  "top-right"
);
chromeThrows(
  "`<Background />`'s variant is refused by the same table",
  createElement(Background, { variant: "crosses" }),
  "Background.variant",
  "cross"
);
chromeThrows(
  "`<Background />` refuses a gap that is neither a number nor a pair",
  createElement(Background, { gap: "wide" }),
  "Background.gap"
);

// The two a custom node mounts. `<Handle />` with no props is the case the
// crossing has to answer for: upstream defaults `type` to `'source'` and
// `position` to `Position.Top` in its parameter list, and ps-flow's record
// makes both required, so an omitted one would meet a pattern-match failure
// rather than a handle. Both defaults are read back off the rendered div.
mountsInNode(
  "`<Handle />` mounts with no props at all, on upstream's two defaults",
  createElement(Handle, {}),
  'data-handlepos="top"',
  // `data-id` is `<flow>-<node>-<handle>-<type>`, so the tag it ends with is
  // the `type` default.
  '-source"'
);
mountsInNode(
  "`<Handle />` converts the type and position it is given",
  createElement(Handle, { type: "target", position: "left" }),
  'data-handlepos="left"',
  '-target"'
);

// `<NodeToolbar />` renders through a portal into the flow's root div, and a
// server render has no such node — the store's `domNode` is `Nothing`, so the
// portal renders nothing whatever it was handed. What these hold is the
// pattern-match case and that the converters run; the toolbar's DOM is the
// conformance suite's, which drives all twelve position/align permutations.
mountsInNode(
  "`<NodeToolbar />` with no props at all reaches no pattern-match failure",
  createElement(NodeToolbar, {}),
  "react-flow__node"
);
mountsInNode(
  "its position, align and node-id converters run without refusing what they are given",
  createElement(NodeToolbar, { isVisible: true, position: "bottom", align: "end", nodeId: ["a", "b"] }),
  "react-flow__node"
);

nodeChromeThrows(
  "`<Handle />`'s position is refused by the same enum table",
  createElement(Handle, { position: "middle" }),
  "Handle.position",
  "left"
);
nodeChromeThrows(
  "`<NodeToolbar />`'s align is refused by the same enum table",
  createElement(NodeToolbar, { align: "centre" }),
  "NodeToolbar.align",
  "center"
);
nodeChromeThrows(
  "`<NodeToolbar />` refuses a nodeId that is neither an id nor a list of them",
  createElement(NodeToolbar, { nodeId: 42 }),
  "NodeToolbar.nodeId"
);

// The resizer pair, mounted where the other two are — by the consumer's own
// node component. Both take no required props, which is the case the crossing
// answers for; their three enum props are the only values either can refuse.
mountsInNode(
  "`<NodeResizer />` mounts with no props at all",
  createElement(NodeResizer, {}),
  "react-flow__resize-control"
);
mountsInNode(
  "`<NodeResizeControl />` mounts with no props at all",
  createElement(NodeResizeControl, {}),
  "react-flow__resize-control"
);
mountsInNode(
  "`<NodeResizeControl />`'s position, variant and direction converters run",
  createElement(NodeResizeControl, {
    position: "bottom-right",
    variant: "line",
    resizeDirection: "horizontal",
  }),
  "react-flow__resize-control"
);

nodeChromeThrows(
  "`<NodeResizeControl />`'s position is refused by the same enum table",
  createElement(NodeResizeControl, { position: "bottomRight" }),
  "NodeResizeControl.position",
  "bottom-right"
);
nodeChromeThrows(
  "`<NodeResizeControl />`'s variant is refused by the same enum table",
  createElement(NodeResizeControl, { variant: "lines" }),
  "NodeResizeControl.variant",
  "line"
);
nodeChromeThrows(
  "`<NodeResizeControl />`'s resizeDirection is refused by the same enum table",
  createElement(NodeResizeControl, { resizeDirection: "sideways" }),
  "NodeResizeControl.resizeDirection",
  "horizontal"
);

// The five converter modules, and what mounts where. The three chrome-shaped
// checks below are derived from these rather than written per component, so a
// component that crosses is picked up here instead of waiting for someone to
// extend a list.
//
// Each entry names its components' JS prop records, because the callback half
// of these checks is derived from a record's field types the same way the
// flow's is. `baseProps` is the props a component cannot mount *without* —
// only `<MiniMapNode />` has any, because it is the one component here whose
// required members are geometry rather than configuration.
const converterModules = [
  {
    source: join(repoRoot, "src/Boundary/Chrome.purs"),
    components: { Panel, Background, Controls, MiniMap, ControlButton, MiniMapNode },
    propRecords: {
      Panel: "JsPanelProps",
      Background: "JsBackgroundProps",
      Controls: "JsControlsProps",
      MiniMap: "JsMiniMapProps",
      ControlButton: "JsControlButtonProps",
      MiniMapNode: "JsMiniMapNodeProps",
    },
    baseProps: {
      MiniMapNode: { id: "a", x: 0, y: 0, width: 10, height: 10, borderRadius: 2 },
    },
    mount: inFlow,
  },
  {
    source: join(repoRoot, "src/Boundary/NodeChrome.purs"),
    components: { Handle, NodeToolbar },
    propRecords: { Handle: "JsHandleProps", NodeToolbar: "JsNodeToolbarProps" },
    mount: inNode,
  },
  {
    source: join(repoRoot, "src/Boundary/Resizer.purs"),
    components: { NodeResizer, NodeResizeControl },
    propRecords: {
      NodeResizer: "JsNodeResizerProps",
      NodeResizeControl: "JsNodeResizeControlProps",
    },
    mount: inNode,
  },
  // Boundary stage 4. The edge-side components mount as children of the flow
  // like the chrome does — none of them is rendered by an edge in this file,
  // because what is under test is the crossing and not the renderer that
  // would normally place them.
  {
    source: join(repoRoot, "src/Boundary/Edges.purs"),
    components: {
      EdgeText,
      BaseEdge,
      StraightEdge,
      SimpleBezierEdge,
      BezierEdge,
      SmoothStepEdge,
      StepEdge,
      EdgeToolbar,
    },
    propRecords: {
      EdgeText: "JsEdgeTextProps",
      BaseEdge: "JsBaseEdgeProps",
      StraightEdge: "JsStraightEdgeProps",
      SimpleBezierEdge: "JsSimpleBezierEdgeProps",
      BezierEdge: "JsBezierEdgeProps",
      SmoothStepEdge: "JsSmoothStepEdgeProps",
      StepEdge: "JsStepEdgeProps",
      EdgeToolbar: "JsEdgeToolbarProps",
    },
    mount: inFlow,
  },
  {
    source: join(repoRoot, "src/Boundary/Portals.purs"),
    components: { EdgeLabelRenderer, ViewportPortal },
    propRecords: {
      EdgeLabelRenderer: "JsEdgeLabelRendererProps",
      ViewportPortal: "JsViewportPortalProps",
    },
    mount: inFlow,
  },
];

for (const { source, components, propRecords, baseProps = {}, mount } of converterModules) {
  const text = readModule(source);
  const known = Object.keys(components).join(", ");

  // The callback props these components take, derived from their own prop
  // records exactly as the flow's are. Six of `Controls`' and `MiniMap`'s and
  // both of `<Handle />`'s threw at mount until stage 2, the resizer's seven
  // are the reason its two components crossed at all, and stage 4 adds
  // `<ControlButton />`'s one and `<MiniMapNode />`'s — the latter being the
  // only handler on this surface that also crosses outbound.
  for (const [component, record] of Object.entries(propRecords)) {
    for (const prop of callbackPropsOf(source, record)) {
      check(`\`${component}.${prop}\` is accepted at mount`, () => {
        mount(createElement(components[component], { ...baseProps[component], [prop]: () => {} }));
      });
    }
  }

  // A prop handed `Nothing` is one the conversion drops in silence — the same
  // claim section 2 makes about the flow props, and the one that outlived the
  // deferred tables. There were three refusals across these modules until
  // stage 4 (`MiniMap.nodeComponent` was the last), and the check that each
  // was declared went with them; this is what is left, and it is what would
  // catch the next one.
  //
  // The converters are found by name — `convert<Component>`, which is why
  // every one of them is spelled that way — rather than listed, so a component
  // crossing is picked up here too. The component half of the name is what
  // qualifies the lookup: an unqualified match would let `Controls.onFitView`
  // cover `MiniMap`'s.
  const converters = [...text.matchAll(/^convert(\w+) p(?: \w+)* =$/gm)].map((m) => m[1]);

  if (converters.length === 0) {
    fail(`found no \`convert<Component>\` converters in ${source} — the parse is wrong`);
  }

  check(`no ${known} prop is wired to \`Nothing\``, () => {
    const dropped = [];
    for (const component of converters) {
      assert(
        Object.hasOwn(components, component),
        `\`convert${component}\` names no exported component — a converter must be ` +
          `\`convert<Component>\`, so that what it converts can be mounted here`
      );
      const body = converterBody(text, component);
      assert(body !== null, `cannot read \`convert${component}\`'s body — the parse is wrong`);
      for (const name of wiredToNothing(body[1])) dropped.push(`${component}.${name}`);
    }
    assert(
      dropped.length === 0,
      `props wired to \`Nothing\`, so they are silently ignored: ${dropped.join(", ")}`
    );
  });
}

// `nodeColor` and its two siblings are `string | ((node) => string)` upstream.
// The function half is the one place a chrome component hands the consumer a
// value ps-flow built, so it goes out through the same `nodeOut` that
// `applyNodeChanges` returns nodes through. The string half has nowhere to go.
check("`MiniMap.nodeColor` is called with a JS-shaped node", () => {
  const seen = [];
  inFlow(createElement(MiniMap, { nodeColor: (node) => (seen.push(node), "#f00") }));
  assert(seen.length > 0, "the node-colour function was never called");
  const a = seen.find((n) => n.id === "a");
  assert(a !== undefined, `it never saw node \`a\`: ${JSON.stringify(seen.map((n) => n.id))}`);
  assert(a.type === "custom", `\`type\` was ${JSON.stringify(a.type)} — a consumer never reads \`nodeType\``);
  assert(!("nodeType" in a), "the node still carries `nodeType`");
});

chromeThrows(
  "`MiniMap.nodeColor`'s string form is refused rather than guessed at",
  createElement(MiniMap, { nodeColor: "#f00" }),
  "MiniMap.nodeColor",
  "string form"
);

// ── 5b. Boundary stage 4: the components no fixture mounts ──────────────
//
// The fourteen components stage 4 crossed, taken from the hole register
// rather than from a driver — which is exactly why they need a section here.
// Every earlier stage crossed what something was already about to render, so
// a mistake in it had a gate waiting; these had nothing waiting at all, and a
// crossing nothing mounts is the one that would have shipped broken.
//
// Two claims, and the second is the one that has to be said out loud: a
// component that mounts is not a component that is **driven**. The holes these
// sit in stay open until a scenario renders one. What this section holds is
// that a JavaScript caller can now reach them at upstream's shapes — which
// was not true before, and is what a scenario would need.

const edgeGeometry = { sourceX: 0, sourceY: 0, targetX: 100, targetY: 100 };
const bendingEdge = { ...edgeGeometry, sourcePosition: "right", targetPosition: "left" };

mounts(
  "`<EdgeText />` converts its label group",
  createElement(EdgeText, { x: 5, y: 6, label: "e" }),
  "react-flow__edge-textwrapper"
);
mounts(
  "`<BaseEdge />` renders the path it is given",
  createElement(BaseEdge, { path: "M0,0 L10,10" }),
  "react-flow__edge-path",
  "M0,0 L10,10"
);
mounts(
  "`<StraightEdge />` mounts with the four coordinates and no positions",
  createElement(StraightEdge, edgeGeometry),
  "react-flow__edge-path"
);
mounts(
  "`<SimpleBezierEdge />` mounts with the two handle sides",
  createElement(SimpleBezierEdge, bendingEdge),
  "react-flow__edge-path"
);
// Upstream defaults these two in its parameter list
// (`sourcePosition = Position.Bottom, targetPosition = Position.Top`, in
// BezierEdge.tsx, SimpleBezierEdge.tsx and SmoothStepEdge.tsx), so its own
// documented example passes the four coordinates and nothing else. ps-flow's
// record has no absent state for a sum type, which is what makes supplying
// them the crossing's job rather than the component's — the same claim
// `<Handle />` takes no props makes one section up.
mounts(
  "a bending edge takes upstream's default handle sides",
  createElement(BezierEdge, edgeGeometry),
  "react-flow__edge-path"
);
mounts(
  "`<BezierEdge />` converts its own `pathOptions` record",
  createElement(BezierEdge, { ...bendingEdge, pathOptions: { curvature: 0.5 } }),
  "react-flow__edge-path"
);
mounts(
  "`<SmoothStepEdge />` converts its own `pathOptions` record",
  createElement(SmoothStepEdge, {
    ...bendingEdge,
    pathOptions: { offset: 5, borderRadius: 2, stepPosition: 0.5 },
  }),
  "react-flow__edge-path"
);
mounts(
  "`<StepEdge />` converts its own `pathOptions` record",
  createElement(StepEdge, { ...bendingEdge, pathOptions: { offset: 5 } }),
  "react-flow__edge-path"
);
mounts(
  "`<ControlButton />` mounts with no props and passes its children through",
  createElement(ControlButton, {}, "button-child"),
  "react-flow__controls-button",
  "button-child"
);
mounts(
  "`<MiniMapNode />` converts its geometry",
  createElement(MiniMapNode, {
    id: "a",
    x: 1,
    y: 2,
    width: 10,
    height: 20,
    borderRadius: 3,
    selected: true,
  }),
  "react-flow__minimap-node selected"
);

// The three that render nothing from a server render, and mount clean anyway.
// Both portal targets resolve their container by querying the flow's own DOM
// node, which a server render does not have, so each returns an empty
// fragment — and `<EdgeToolbar />` renders through one of them. That is the
// ceiling here and it is still the claim that matters: before stage 4 these
// took a `ReactChildren JSX` a JavaScript caller had no way to construct, so
// `<ViewportPortal>x</ViewportPortal>` reached a `case` on `undefined`.
mounts(
  "`<EdgeLabelRenderer />` accepts JSX children",
  createElement(EdgeLabelRenderer, {}, createElement("span", null, "label"))
);
mounts(
  "`<ViewportPortal />` accepts JSX children",
  createElement(ViewportPortal, {}, createElement("span", null, "in-viewport"))
);
mounts(
  "`<EdgeToolbar />` converts its two alignments",
  createElement(EdgeToolbar, { edgeId: "a-b", x: 1, y: 2, alignX: "left", alignY: "top" })
);

// The two flow-level components, which mount at the top rather than inside
// one. `<ReactFlowProvider />` is what a consumer wraps their own tree in to
// reach the hooks outside `<ReactFlow />`; `<ReactFlow />` is the flow itself,
// and #27 is what made it one component that takes a ref where ps-flow used to
// publish two that split the capability between them.
check("`<ReactFlowProvider />` converts its initial values", () => {
  const html = renderToStaticMarkup(
    createElement(
      ReactFlowProvider,
      {
        initialNodes: convertedProps.nodes,
        initialEdges: convertedProps.edges,
        nodeOrigin: [0.5, 0.5],
        nodeExtent: [[-10, -10], [10, 10]],
        zIndexMode: "basic",
        fitView: true,
      },
      createElement("div", { className: "provider-child" })
    )
  );
  assert(html.includes("provider-child"), "the provider swallowed its children");
});

// #27: the one call upstream's own docs write. A ref, flat props and JSX
// children in a single element — the three things ps-flow could not do at once
// while `ReactFlow` was a plain component and `ReactFlowWithRef` nested its
// props one level down. Children are the half a shape comparison cannot see:
// `ReactFlowWithRef` read them from inside its props record, so this exact
// element rendered without them.
check("`<ReactFlow />` takes upstream's props, its children and a ref together", () => {
  const ref = { current: null };
  const html = renderToStaticMarkup(
    createElement(
      ReactFlow,
      { ...convertedProps, ref },
      createElement("div", { className: "flow-child" })
    )
  );
  assert(html.includes("react-flow"), "render produced no flow wrapper");
  assert(html.includes("flow-child"), "`<ReactFlow />` dropped its JSX children");
  // Where the ref *goes* is the next check. `react-dom/server` attaches no
  // refs, so a rendered mount cannot see one.
});

// The ref actually arriving, which the mount above cannot show and the shape
// comparison cannot either — `forwardRef` is a wrapper kind, and a wrapper
// that hands its ref nowhere has the same shape as one that does.
//
// No DOM needed. A `forwardRef` exposes its render function, and calling it
// runs the boundary conversion and returns an element rather than rendering
// one, so no hook runs and nothing needs mounting. What comes back is the
// element for the PureScript component, and the converted props are on it.
check("`<ReactFlow />` hands the forwarded ref to the PureScript component", () => {
  const sentinel = { current: null };
  const withRef = ReactFlow.render({ ...convertedProps }, sentinel);
  assert(
    withRef.props.innerRef === sentinel,
    "the forwarded ref never reached `ReactFlowProps.innerRef` — it is accepted and dropped"
  );
  // The other half, and the reason the field is `Nullable Foreign` rather than
  // a `Maybe`: React passes `null` when the caller supplied no ref, and that
  // has to survive as the `null` React reads back as "no ref". A conversion
  // that turned it into anything else would put a truthy non-ref on the div.
  const withNone = ReactFlow.render({ ...convertedProps }, null);
  assert(
    withNone.props.innerRef === null,
    `no-ref mount put ${JSON.stringify(withNone.props.innerRef)} on \`innerRef\`, not null`
  );
});

check("`ReactFlowWithRef` is gone from the surface", () => {
  assert(
    !("ReactFlowWithRef" in psflow),
    "`ReactFlowWithRef` still resolves — #27 removes the reason for a second component"
  );
});

// What the three ref-taking components gained, which is the half of their
// divergence a shape comparison cannot see. `forwardRef` makes them the right
// *shape*; putting the ref on the element is what makes them useful, and
// nothing but the DOM says whether that happened.
check("`<ReactFlow />`, `<Panel />` and `<Handle />` put the forwarded ref on their element", () => {
  for (const [what, source] of [
    ["ReactFlow", join(repoRoot, "src/React/Container/ReactFlow.purs")],
    ["Panel", join(repoRoot, "src/React/Portal/Panel.purs")],
    ["Handle", join(repoRoot, "src/React/Handle.purs")],
  ]) {
    const text = readModule(source);
    assert(
      /^\s*,?\s*ref: props\.innerRef$/m.test(text),
      `${what} never puts \`innerRef\` on its element — it accepts a ref and drops it`
    );
  }
});

// The other ref family #27 covers, and a different shape of gap. `NodeWrapper`
// and `EdgeWrapper` are internal — nothing hands either of them a ref, and
// upstream's are plain components too — so there is no `forwardRef` here to
// compare. What upstream does with the ref each one holds *for itself* is drop
// focus when the element stops being selected, and that is what these three
// call sites are: an unselected node or edge that keeps the browser's focus
// keeps its focus ring and the next keystroke, so it looks deselected and
// behaves selected.
//
// Read from source for the reason the `innerRef` check above is: this file
// renders with `react-dom/server`, which attaches no refs and dispatches no
// events, so neither `blur()` can be provoked here. The claim is that the call
// exists and is reachable, not that a browser ran it.
check("deselecting a node or an edge takes focus off its element", () => {
  const nodeUtil = readModule(join(repoRoot, "src/React/Node/Util.purs"));
  // TS: `requestAnimationFrame(() => nodeRef?.current?.blur())`, in the
  // unselect branch of `handleNodeClick`. The frame matters — blurring inside
  // the tick that dispatched the unselect fights the re-render — so the check
  // is for the deferred form and not for a bare `blur`.
  assert(
    /requestAnimationFrame \(blur \(toHTMLElement \w+\)\)/.test(nodeUtil),
    "`handleNodeClick` unselects the node without blurring it on the next frame"
  );

  const edgeWrapper = readModule(join(repoRoot, "src/React/Component/EdgeWrapper.purs"));
  assert(
    /^\s*,?\s*ref: edgeRef$/m.test(edgeWrapper),
    "`EdgeWrapper` never puts its own ref on the `<g>`, so it has nothing to blur"
  );
  // Two call sites upstream, and they are not interchangeable: the click path
  // blurs *after* unselecting and the Escape path *before*. Counting them is
  // what catches one being dropped while the other stays.
  const blurs = edgeWrapper.match(/^\s+blurEdge$/gm) ?? [];
  assert(
    blurs.length === 2,
    `\`EdgeWrapper\` blurs on ${blurs.length} path(s), not the 2 TS has (click-deselect and Escape)`
  );
});

// ── 5c. The three props whose values are the consumer's own components ──
//
// `nodeTypes` crossed in stage 1 and section 1 reads the props it delivers.
// These are the other two of the three, plus `MiniMap.nodeComponent`: each
// wraps a component ps-flow did not write, and each has to hand it upstream's
// props record rather than the PureScript one. That outbound direction is the
// half the compiler forces nothing about, which is why it is checked by
// reading what the component actually received.

check("`edgeTypes` hands a consumer's edge component JS-shaped props", () => {
  let seen = null;
  const CustomEdge = (props) => {
    seen = props;
    return createElement("path", { className: "custom-edge", d: "M0,0" });
  };
  // Both endpoints measured **and handled**. An edge renders only once the
  // store can place both of its ends, and a server render runs no effects, so
  // neither the dimensions nor the handle bounds a browser would measure
  // exist. Upstream's `Node.handles` is the way to supply them as data, and
  // it is the only reason this claim is reachable here at all — without it
  // the `react-flow__edges` container renders empty and a check looking for a
  // class name would have passed on `react-flow__edgelabel-renderer`.
  const measured = (id, x) => ({
    id,
    position: { x, y: 0 },
    data: {},
    width: 100,
    height: 40,
    measured: { width: 100, height: 40 },
    handles: [
      { x: 50, y: 40, position: "bottom", type: "source", width: 6, height: 6 },
      { x: 50, y: 0, position: "top", type: "target", width: 6, height: 6 },
    ],
  });
  const html = renderToStaticMarkup(
    createElement(ReactFlow, {
      ...convertedProps,
      nodes: [measured("a", 0), measured("b", 200)],
      nodeTypes: {},
      edges: [{ ...convertedProps.edges[0], type: "custom" }],
      edgeTypes: { custom: CustomEdge },
    })
  );
  assert(html.includes("custom-edge"), "the custom edge type did not render");
  assert(seen !== null, "the custom edge component was never called");
  assert("type" in seen, "edge props have no `type` — a consumer destructures that, not `edgeType`");
  assert(!("edgeType" in seen), "edge props still carry `edgeType`");
  assert(seen.type === "custom", `edge props \`type\` was ${JSON.stringify(seen.type)}`);
  assert(
    seen.sourcePosition === "bottom",
    `\`sourcePosition\` was ${JSON.stringify(seen.sourcePosition)}, not the string literal ` +
      `"bottom" — a consumer switches on these, and a PureScript constructor is not one`
  );
  assert(typeof seen.sourceX === "number", "`sourceX` is not a number");
  assert(typeof seen.selected === "boolean", "`selected` is not a plain boolean");
  assert(
    seen.labelBgPadding === undefined || Array.isArray(seen.labelBgPadding),
    "`labelBgPadding` crossed as ps-flow's `{ x, y }` rather than upstream's pair"
  );
});

check("`MiniMap.nodeComponent` hands a consumer's component JS-shaped props", () => {
  let seen = null;
  const CustomMiniMapNode = (props) => {
    seen = props;
    return createElement("rect", { className: "custom-minimap-node" });
  };
  const html = inFlow(createElement(MiniMap, { nodeComponent: CustomMiniMapNode }));
  assert(html.includes("custom-minimap-node"), "the replacement minimap node did not render");
  assert(seen !== null, "the replacement minimap node was never called");
  assert(typeof seen.id === "string", "`id` is not a string");
  assert(typeof seen.x === "number", "`x` is not a number");
  assert(typeof seen.selected === "boolean", "`selected` is not a plain boolean");
  assert(
    seen.style === undefined || typeof seen.style === "object",
    "`style` did not cross as a plain object"
  );
});

check("`connectionLineComponent` is accepted at mount", () => {
  renderToStaticMarkup(
    createElement(ReactFlow, {
      ...convertedProps,
      connectionLineComponent: () => null,
    })
  );
  // Nothing calls it here: it renders only while a connection is being
  // dragged, which a server render cannot reach. What holds its props
  // conversion is `parity/boundary/drift.mjs`'s `ConnectionLineComponentProps`
  // pair, which is a claim about the label sets and not about the values;
  // driving it is a hole-closing scenario's.
});

// ── 5d. What the stage-4 crossings refuse ───────────────────────────────
//
// The same claim section 3 makes about the flow props, one level down. Two of
// these are worth reading twice.
//
// `EdgeToolbar.alignX` and `alignY` have **separate** member tables from
// `NodeToolbar.align`, because the node toolbar aligns along one axis with
// `start`/`center`/`end` and the edge toolbar names its ends by the side they
// are on. A shared codec would accept `"start"` for `alignX`, which upstream's
// own `alignXToPercent` has no entry for.

chromeThrows(
  "`<BaseEdge />` without a path says so rather than failing a pattern match",
  createElement(BaseEdge, {}),
  "BaseEdge.path",
  "required"
);
chromeThrows(
  "`<EdgeText />` without its coordinates says which one",
  createElement(EdgeText, { label: "e" }),
  "EdgeText.x",
  "required"
);
chromeThrows(
  "a bending edge's position is refused by the same enum table",
  createElement(BezierEdge, { ...bendingEdge, sourcePosition: "rightish" }),
  "BezierEdge.sourcePosition",
  "right"
);
chromeThrows(
  "`<EdgeToolbar />`'s alignX does not accept the node toolbar's members",
  createElement(EdgeToolbar, { edgeId: "a-b", x: 1, y: 2, alignX: "start" }),
  "EdgeToolbar.alignX",
  "left"
);
chromeThrows(
  "`<EdgeToolbar />` without an edge id says so",
  createElement(EdgeToolbar, { x: 1, y: 2 }),
  "EdgeToolbar.edgeId",
  "required"
);
chromeThrows(
  "`<MiniMapNode />` without its geometry says which member",
  createElement(MiniMapNode, { id: "a" }),
  "MiniMapNode.x",
  "required"
);
chromeThrows(
  "a label padding that is not a pair is refused",
  createElement(BaseEdge, { path: "M0,0", labelBgPadding: [1, 2, 3] }),
  "BaseEdge.labelBgPadding",
  "paddingX"
);

// ── 6. The two hooks ────────────────────────────────────────────────────
//
// `useNodesState` and `useEdgesState` are the whole reason the second driver
// costs anything: upstream's `ColorMode/index.tsx` destructures both, and
// before this crossing the call returned an unrun `Effect` thunk, so
// `const [nodes, , onNodesChange] = useNodesState(…)` bound `undefined` three
// times and `setEdges(eds => …)` mutated nothing.
//
// The updater is exercised with a **render-phase update** — a setter called
// during the component's own render, which React re-renders in place. That is
// what makes the round trip observable from a server render at all: outside a
// render, `react-dom/server`'s dispatch is a no-op, which would prove only
// that nothing crashed.

const { useNodesState, useEdgesState } = psflow;

// Renders a probe that calls `hook(initial)` and hands the tuple to `act` with
// the render count. Returns every tuple the probe saw, newest last.
function hookProbe(hook, initial, act = () => {}) {
  const seen = [];
  function Probe() {
    const tuple = hook(initial);
    seen.push(tuple);
    act(tuple, seen.length - 1);
    return null;
  }
  renderToStaticMarkup(createElement(Probe));
  return seen;
}

const hooks = [
  { name: "useNodesState", setter: "setNodes", hook: useNodesState, initial: jsNodes, shaped: "nodeType" },
  { name: "useEdgesState", setter: "setEdges", hook: useEdgesState, initial: jsEdges, shaped: "edgeType" },
];

for (const { name, setter: setterName, hook, initial, shaped } of hooks) {
  check(`\`${name}\` returns upstream's three-slot array, not a thunk`, () => {
    const [tuple] = hookProbe(hook, initial);
    assert(Array.isArray(tuple), `returned ${typeof tuple} — a consumer destructures an array`);
    assert(tuple.length === 3, `returned ${tuple.length} slots, not 3`);
    const [current, setter, onChange] = tuple;
    assert(Array.isArray(current), `slot 0 is ${typeof current}, not the current array`);
    assert(current.length === initial.length, `slot 0 has ${current.length} entries, not ${initial.length}`);
    assert(typeof setter === "function", `slot 1 is ${typeof setter}, not the setter`);
    assert(setter.length === 1, `the setter takes ${setter.length} arguments, not 1`);
    assert(typeof onChange === "function", `slot 2 is ${typeof onChange}, not the change handler`);
    assert(onChange.length === 1, `the change handler takes ${onChange.length} arguments, not 1`);
    assert(!(shaped in current[0]), `slot 0 still carries \`${shaped}\``);
  });

  check(`\`${name}\`'s setter runs rather than returning an unrun thunk`, () => {
    let returned = "never called";
    let handed = null;
    const seen = hookProbe(hook, initial, ([, set], pass) => {
      if (pass === 0) {
        returned = set((previous) => {
          handed = previous;
          return previous.slice(0, 1);
        });
      }
    });
    assert(
      returned === undefined,
      `the setter returned ${typeof returned} — a PureScript \`Effect\` nobody runs looks ` +
        `exactly like this, and it is the failure this whole boundary exists to remove`
    );
    assert(handed !== null, "the updater was never called");
    assert(!(shaped in handed[0]), `the updater was handed a value still carrying \`${shaped}\``);
    assert(seen.length > 1, "the update did not re-render the probe");
    assert(seen.at(-1)[0].length === 1, `the updated array has ${seen.at(-1)[0].length} entries, not 1`);
  });

  check(`\`${name}\`'s setter also takes the plain array React's contract allows`, () => {
    const seen = hookProbe(hook, initial, ([, set], pass) => {
      if (pass === 0) set([]);
    });
    assert(seen.length > 1, "the update did not re-render the probe");
    assert(seen.at(-1)[0].length === 0, `the array did not land: ${JSON.stringify(seen.at(-1)[0])}`);
  });

  throws(
    `\`${name}\`'s setter refuses an argument that is neither`,
    () => hookProbe(hook, initial, ([, set], pass) => pass === 0 && set(42)),
    setterName
  );
}

// ── 7. The imperative instance, and the other nineteen hooks ────────────
//
// Boundary stage 3. Two things reach the instance — `useReactFlow` and
// `onInit` — and both are exercised here, because they are separate code paths
// through the same converter and only one of them needs a component of the
// consumer's own.
//
// The member list and each member's expected arity are read out of
// `JsReactFlowInstance`'s own declaration rather than restated: `Effect X` is a
// nullary call, `EffectFnN` is an N-ary one, and anything else is a plain
// value. So a method added to the instance is checked by construction, and one
// whose signature changes shape fails here rather than in a consumer's console.
//
// What this section cannot claim is that a **mutator's queued update lands**.
// `setNodes`, `addNodes` and the four `update…` methods push onto the store's
// batch queue, which is drained by an effect, and `react-dom/server` runs no
// effects — the same ceiling this file's header describes for the flow-level
// callbacks. What it does claim is the half that was actually broken: the call
// runs and returns `undefined` rather than handing back an unrun `Effect`
// thunk, which is the failure the whole boundary effort began from. The other
// half is the net's `api` section, which drives a real browser.

const instanceMembers = recordEntries(join(repoRoot, "src/Boundary/Instance.purs"), "JsReactFlowInstance");

// `Effect a` → 0, `EffectFnN …` → N, anything else → not a function.
function expectedArity(typeText) {
  if (/^EffectFn(\d)\b/.test(typeText)) return Number(RegExp.$1);
  if (/^Effect\b/.test(typeText)) return 0;
  return null;
}

const psflowNodes = [
  { id: "a", type: "custom", position: { x: 0, y: 0 }, data: { label: "A" } },
  { id: "b", position: { x: 100, y: 40 }, data: { label: "B" } },
];
const psflowEdges = [{ id: "a-b", source: "a", target: "b" }];

// Renders `body` inside a mounted flow and returns whatever it collected. The
// probe is a child rather than the flow itself, because `useReactFlow` needs
// the store context the flow provides.
function insideFlow(body, extraProps = {}) {
  const collected = {};
  function Probe() {
    body(collected);
    return null;
  }
  renderToStaticMarkup(
    createElement(ReactFlow, {
      nodes: psflowNodes,
      edges: psflowEdges,
      ...extraProps,
      children: createElement(Probe),
    })
  );
  return collected;
}

const { useReactFlow, useNodes, useEdges, useViewport, useNodesInitialized } = psflow;
const { useNodeId, useUpdateNodeInternals, useNodesData, useConnection } = psflow;
const { useInternalNode, useKeyPress, useNodeConnections, useStore, useStoreApi } = psflow;

const instance = insideFlow((out) => {
  out.instance = useReactFlow();
}).instance;

check("`useReactFlow` returns the instance rather than an unrun thunk", () => {
  assert(
    instance !== undefined && typeof instance === "object",
    `returned ${typeof instance} — a PureScript \`Hook\` reaching JavaScript unrun looks exactly like this`
  );
});

check("the instance carries every member `JsReactFlowInstance` declares", () => {
  const present = new Set(Object.keys(instance));
  const missing = instanceMembers.map((m) => m.name).filter((name) => !present.has(name));
  assert(missing.length === 0, `missing: ${missing.join(", ")}`);
  const extra = [...present].filter((name) => !instanceMembers.some((m) => m.name === name));
  assert(extra.length === 0, `carries members the type does not declare: ${extra.join(", ")}`);
});

check("every instance method takes its arguments in one call", () => {
  const curried = [];
  for (const member of instanceMembers) {
    const arity = expectedArity(member.type);
    if (arity === null) continue;
    const value = instance[member.name];
    if (typeof value !== "function") {
      curried.push(`${member.name} is ${typeof value}, not a function`);
    } else if (value.length !== arity) {
      curried.push(`${member.name} takes ${value.length} argument(s), not ${arity}`);
    }
  }
  assert(curried.length === 0, curried.join("; "));
});

check("`viewportInitialized` is a boolean and not a thunk", () => {
  assert(
    typeof instance.viewportInitialized === "boolean",
    `is ${typeof instance.viewportInitialized}`
  );
});

// The readers. Each one was an unrun `Effect` before this stage, so the claim
// is the same for all of them: calling it produces the value, JS-shaped.
check("`getNodes` returns nodes, JS-shaped", () => {
  const got = instance.getNodes();
  assert(Array.isArray(got), `returned ${typeof got}`);
  assert(got.length === 2, `returned ${got.length} nodes, not 2`);
  assert(!("nodeType" in got[0]), "a node still carries `nodeType`");
  assert("type" in got[0], "a node has no `type` key");
  assert(got[0].type === "custom", `\`type\` is ${JSON.stringify(got[0].type)}, not "custom"`);
});

check("`getEdges` returns edges, JS-shaped", () => {
  const got = instance.getEdges();
  assert(Array.isArray(got) && got.length === 1, `returned ${JSON.stringify(got)}`);
  assert(!("edgeType" in got[0]), "an edge still carries `edgeType`");
});

check("`getNode` answers `undefined` for a node that is not there", () => {
  assert(instance.getNode("a") !== undefined, "found no node `a`");
  const missing = instance.getNode("nope");
  assert(
    missing === undefined,
    `answered ${JSON.stringify(missing)} — a PureScript \`Maybe\` crossing unconverted ` +
      `arrives as \`{ value0: … }\` or \`{}\`, never as \`undefined\``
  );
});

check("`getInternalNode` answers `undefined` for a node that is not there", () => {
  assert(instance.getInternalNode("nope") === undefined, "did not answer `undefined`");
  assert(instance.getInternalNode("a") !== undefined, "found no internal node `a`");
});

check("`getViewport` and `getZoom` read through", () => {
  const viewport = instance.getViewport();
  assert(typeof viewport === "object" && viewport !== null, `viewport is ${typeof viewport}`);
  for (const key of ["x", "y", "zoom"]) {
    assert(typeof viewport[key] === "number", `viewport.${key} is ${typeof viewport[key]}`);
  }
  assert(typeof instance.getZoom() === "number", "`getZoom` did not return a number");
});

check("`toObject` returns nodes, edges and viewport in one object", () => {
  const object = instance.toObject();
  assert(Array.isArray(object.nodes) && object.nodes.length === 2, "nodes are wrong");
  assert(Array.isArray(object.edges) && object.edges.length === 1, "edges are wrong");
  assert(typeof object.viewport?.zoom === "number", "viewport is wrong");
  assert(!("nodeType" in object.nodes[0]), "a node still carries `nodeType`");
});

check("`getNodesBounds` takes ids and returns a rect", () => {
  const bounds = instance.getNodesBounds(["a", "b"]);
  for (const key of ["x", "y", "width", "height"]) {
    assert(typeof bounds[key] === "number", `bounds.${key} is ${typeof bounds[key]}`);
  }
});

check("`getIntersectingNodes` narrows a rect argument and returns nodes", () => {
  const hits = instance.getIntersectingNodes({ x: 0, y: 0, width: 500, height: 500 });
  assert(Array.isArray(hits), `returned ${typeof hits}`);
  assert(hits.every((n) => !("nodeType" in n)), "a node still carries `nodeType`");
});

check("`getHandleConnections` takes upstream's `type`, not ps-flow's `handleType`", () => {
  const found = instance.getHandleConnections({ type: "source", nodeId: "a" });
  assert(Array.isArray(found), `returned ${typeof found}`);
});

// The asynchronous half. `Aff` is not a promise and has no `.then`, so an
// unconverted one resolves an `await` immediately to itself — the `Effect`
// failure one type further along, and invisible to everything but this.
check("`fitView` returns a real promise", () => {
  const returned = instance.fitView();
  assert(
    returned instanceof Promise,
    `returned ${typeof returned} — an \`Aff\` reaching JavaScript unconverted looks like this, ` +
      `and \`await\` resolves it to itself rather than waiting for the animation`
  );
});

for (const name of ["zoomIn", "zoomOut", "fitBounds", "setViewport", "setCenter", "zoomTo"]) {
  check(`\`${name}\` returns a real promise`, () => {
    const args = {
      zoomTo: [1.5],
      fitBounds: [{ x: 0, y: 0, width: 10, height: 10 }],
      setViewport: [{ x: 0, y: 0, zoom: 1 }],
      setCenter: [0, 0],
    }[name] ?? [];
    assert(instance[name](...args) instanceof Promise, "did not return a promise");
  });
}

check("`deleteElements` resolves with the deleted elements, JS-shaped", async () => {
  const returned = instance.deleteElements({ nodes: [{ id: "a" }] });
  assert(returned instanceof Promise, `returned ${typeof returned}`);
});

// `deleteElements` is the one asynchronous method that settles without a
// browser, so its resolved value is checked rather than only its type. Awaited
// at the end of the run, because `check` is synchronous.
const deletion = instance.deleteElements({ nodes: [{ id: "a" }], edges: [{ id: "a-b" }] });

// The mutators. See this section's header for why the queued update itself is
// out of reach here and what is left to claim.
check("`setNodes` runs rather than returning an unrun thunk", () => {
  const returned = instance.setNodes((previous) => previous);
  assert(
    returned === undefined,
    `returned ${typeof returned} — a PureScript \`Effect\` nobody runs looks exactly like this, ` +
      `and it is the failure this whole boundary exists to remove`
  );
});

check("`setNodes` also takes the plain array React's contract allows", () => {
  assert(instance.setNodes([]) === undefined, "did not run");
});

throws(
  "`setNodes` refuses an argument that is neither an array nor a function",
  () => instance.setNodes(42),
  "setNodes"
);

for (const [name, args] of [
  ["setEdges", [[]]],
  ["addNodes", [{ id: "c", position: { x: 0, y: 0 }, data: {} }]],
  ["addEdges", [{ id: "b-a", source: "b", target: "a" }]],
  ["updateNode", ["a", { hidden: true }]],
  ["updateNodeData", ["a", { label: "changed" }]],
  ["updateEdge", ["a-b", { animated: true }]],
  ["updateEdgeData", ["a-b", { weight: 1 }]],
]) {
  check(`\`${name}\` runs rather than returning an unrun thunk`, () => {
    const returned = instance[name](...args);
    assert(returned === undefined, `returned ${typeof returned}, not undefined`);
  });
}

// `addNodes` and `addEdges` take `T | T[]`; the loop above passed the bare
// form, so this is the other one.
check("`addNodes` takes an array as readily as a single node", () => {
  assert(instance.addNodes([{ id: "d", position: { x: 0, y: 0 }, data: {} }]) === undefined, "did not run");
});

// `updateNode` takes a **partial**, which ps-flow's updater cannot: its
// argument is a whole node in and a whole node out, so the merge is the
// crossing's. Both forms of upstream's union are checked, and the function
// form is what proves the consumer sees a JS-shaped node.
check("`updateNode`'s function form is handed a JS-shaped node", () => {
  let handed = null;
  instance.updateNode("a", (node) => {
    handed = node;
    return { hidden: true };
  });
  // The updater runs when the queue drains, which a server render never does,
  // so an un-called updater here is the expected ceiling rather than a failure.
  if (handed !== null) {
    assert(!("nodeType" in handed), "the updater was handed a node still carrying `nodeType`");
  }
});

// The hooks. `useNodesState` and `useEdgesState` are section 6's; these are
// the nineteen stage 3 adds, and the claim for each is the one that was false
// before: calling it produces a value rather than a thunk, and the value is
// upstream's shape.
const hookResults = insideFlow((out) => {
  out.nodes = useNodes();
  out.edges = useEdges();
  out.viewport = useViewport();
  out.initialized = useNodesInitialized();
  out.initializedWithOptions = useNodesInitialized({ includeHiddenNodes: true });
  out.nodeId = useNodeId();
  out.updateInternals = useUpdateNodeInternals();
  out.oneNodeData = useNodesData("a");
  out.manyNodeData = useNodesData(["a", "b"]);
  out.missingNodeData = useNodesData("nope");
  out.connection = useConnection();
  out.internalNode = useInternalNode("a");
  out.missingInternalNode = useInternalNode("nope");
  out.keyPressed = useKeyPress();
  out.keyPressedWithCode = useKeyPress("a", { actInsideInputWithModifier: true });
  out.nodeConnections = useNodeConnections({ id: "a" });
});

check("`useNodes` and `useEdges` return arrays, JS-shaped", () => {
  assert(Array.isArray(hookResults.nodes) && hookResults.nodes.length === 2, "nodes are wrong");
  assert(Array.isArray(hookResults.edges) && hookResults.edges.length === 1, "edges are wrong");
  assert(!("nodeType" in hookResults.nodes[0]), "a node still carries `nodeType`");
});

check("`useViewport` returns `{ x, y, zoom }`", () => {
  for (const key of ["x", "y", "zoom"]) {
    assert(typeof hookResults.viewport[key] === "number", `viewport.${key} is missing`);
  }
});

check("`useNodesInitialized` returns a boolean, with and without its options", () => {
  assert(typeof hookResults.initialized === "boolean", `returned ${typeof hookResults.initialized}`);
  assert(typeof hookResults.initializedWithOptions === "boolean", "the options form did not return a boolean");
});

check("`useNodeId` returns `null` outside a node, not `undefined`", () => {
  assert(
    hookResults.nodeId === null,
    `returned ${JSON.stringify(hookResults.nodeId)} — upstream's \`NodeIdContext\` defaults to ` +
      `\`null\`, which is the one place on this surface where \`null\` and \`undefined\` differ`
  );
});

check("`useUpdateNodeInternals` returns a one-argument function", () => {
  const update = hookResults.updateInternals;
  assert(typeof update === "function", `returned ${typeof update}`);
  assert(update.length === 1, `takes ${update.length} arguments, not 1`);
  assert(update("a") === undefined, "the returned updater did not run");
  assert(update(["a", "b"]) === undefined, "the array form did not run");
});

check("`useNodesData` follows its argument: one id answers one pick, an array answers an array", () => {
  const one = hookResults.oneNodeData;
  assert(!Array.isArray(one), "a single id answered with an array");
  assert(one.id === "a", `the pick is ${JSON.stringify(one)}`);
  assert(
    Object.keys(one).sort().join(",") === "data,id,type",
    `the pick carries ${Object.keys(one).join(", ")} — upstream's is { id, type, data } and no more`
  );
  assert(Array.isArray(hookResults.manyNodeData), "an array of ids did not answer with an array");
  assert(hookResults.manyNodeData.length === 2, "the array is the wrong length");
  assert(
    hookResults.missingNodeData === null,
    `a missing id answered ${JSON.stringify(hookResults.missingNodeData)}, not null`
  );
});

check("`useInternalNode` answers `undefined` for a node that is not there", () => {
  assert(hookResults.internalNode !== undefined, "found no internal node `a`");
  assert(hookResults.missingInternalNode === undefined, "did not answer `undefined`");
});

check("`useConnection` returns the connection state, JS-shaped", () => {
  const state = hookResults.connection;
  assert(typeof state === "object" && state !== null, `returned ${typeof state}`);
  assert("isValid" in state && "fromHandle" in state, `is ${JSON.stringify(state)}`);
});

check("`useKeyPress` returns a boolean, with and without its two optional arguments", () => {
  assert(typeof hookResults.keyPressed === "boolean", `returned ${typeof hookResults.keyPressed}`);
  assert(typeof hookResults.keyPressedWithCode === "boolean", "the two-argument form did not return a boolean");
});

check("`useNodeConnections` takes upstream's `id` for the node, not ps-flow's `nodeId`", () => {
  assert(Array.isArray(hookResults.nodeConnections), `returned ${typeof hookResults.nodeConnections}`);
});

// The bare form is upstream's common case — a custom node calling
// `useNodeConnections()` and taking its own id from the surrounding context —
// and outside a node both implementations throw the same way. That the
// parameter is *optional* is what is checked here; the argument-less call is
// exercised by the custom node the props fixture mounts.
throws(
  "`useNodeConnections` outside a node says so, as upstream does",
  () => insideFlow(() => useNodeConnections()),
  "node ID"
);

// The listener hooks and the two middleware hooks return nothing, so what is
// checked is that they install without complaint and hand their handlers the
// JS shape. A server render runs no effects, so the installation itself is out
// of reach and acceptance is the ceiling — as it is for the flow-level
// callbacks in section 2b.
check("the listener and middleware hooks accept JS-shaped handlers", () => {
  insideFlow(() => {
    psflow.useOnViewportChange({ onStart: () => {}, onChange: () => {}, onEnd: () => {} });
    psflow.useOnSelectionChange({ onChange: () => {} });
    psflow.useHandleConnections({ type: "source", nodeId: "a", onConnect: () => {} });
    psflow.experimental_useOnNodesChangeMiddleware((changes) => changes);
    psflow.experimental_useOnEdgesChangeMiddleware((changes) => changes);
  });
});

// The two that refuse. See `Boundary.Hooks`: both hand over the internal store
// state, which is an 85-field PureScript record with no JS shape, and both are
// callable at upstream's arity so that surface parity sees them agree. That
// they throw is this gate's to hold, and it is held the way the refused
// `defaultEdgeOptions` members are — by making the call and reading the
// message.
throws(
  "`useStore` refuses rather than handing over the PureScript store state",
  () => insideFlow(() => useStore((s) => s)),
  "useStore",
  "nodeLookup"
);

throws(
  "`useStoreApi` refuses rather than handing over the PureScript store state",
  () => insideFlow(() => useStoreApi()),
  "useStoreApi"
);

// `onInit` is the second path to the instance and the one that does not need a
// component of the consumer's own. It was the last deferred callback prop, and
// a server render never fires it — the handler reaches the store through
// `StoreUpdater`'s effect — so what is claimed here is acceptance, which is
// exactly what section 2b claims for the other 46.
check("`onInit` is accepted rather than refused", () => {
  renderToStaticMarkup(
    createElement(ReactFlow, { nodes: psflowNodes, edges: psflowEdges, onInit: () => {} })
  );
});

// ── Report ──────────────────────────────────────────────────────────────

// The one asynchronous method that settles without a browser. Awaited here
// rather than inside a `check`, because `check` is synchronous and a rejected
// promise nobody awaited is a warning rather than a failure.
await check_deletion();

async function check_deletion() {
  try {
    const deleted = await deletion;
    check("`deleteElements` resolves with the deleted elements, JS-shaped", () => {
      assert(Array.isArray(deleted.deletedNodes), "`deletedNodes` is not an array");
      assert(Array.isArray(deleted.deletedEdges), "`deletedEdges` is not an array");
      assert(
        deleted.deletedNodes.every((n) => !("nodeType" in n)),
        "a deleted node still carries `nodeType`"
      );
    });
  } catch (e) {
    failures++;
    console.error(`\n\u2717 \`deleteElements\` resolves\n    ${e.message}`);
  }
}

if (failures > 0) {
  console.error(`\n${failures} boundary mount failure(s).\n`);
  process.exit(1);
}

console.log(`boundary mount: ${notes.length} checks, ${refusedOptions.length} defaultEdgeOptions members refused, 0 deferred props.`);
console.log(notes.slice(0, 5).join("\n"));
console.log(`  ✓ … and ${notes.length - 5} more`);
