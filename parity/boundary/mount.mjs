// The boundary module, mounted through `index.js`.
//
// The boundary module is gated on the JS surface only — never through the
// PureScript module it wraps — because `index.js` is the door the audience
// comes through and the whole point of this apparatus is that no gate should
// enter by a different one. That normally means a browser, but the claims this
// ticket has to stand behind are reachable from a server render:
//
//   1. **Every deferred prop throws at mount.** A prop the boundary has not
//      converted must fail loudly rather than be ignored, because a prop that
//      is silently dropped is indistinguishable from a prop the consumer never
//      set — the exact failure shape of the unrun `Effect` thunk that produced
//      this whole effort. `Nothing` compiles perfectly, so nothing but a gate
//      can hold this.
//
//   2. **A converted prop set mounts clean and arrives JS-shaped.** This is
//      the falsification half of (1): without it, a `ReactFlow` that threw on
//      *everything* would pass the deferred check. It also exercises every
//      converter that does not need layout — enums, key codes, the untagged
//      unions, the node and edge records, and the node-type wrapping — and
//      then reads the props a consumer's own node component actually received.
//
//   3. **The graph utilities are callable, and their round trip closes.** A
//      controlled flow's own change handlers call `applyNodeChanges`,
//      `applyEdgeChanges` and `addEdge` with every argument at once and put
//      what comes back into `nodes` / `edges`. What that section claims is the
//      calling convention and the branches the crossing itself introduces —
//      never upstream's semantics, which is call-and-compare's to prove.
//
// The deferred list is read live out of `src/Boundary/Flow.purs` rather than
// restated here. A second copy of that list is a second thing to go stale, and
// this file checks the one copy against `JsFlowProps` instead.
//
// Usage: node parity/boundary/mount.mjs   (requires `spago build`)

import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { fail, recordFields } from "./purs.mjs";

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
const psflow = await import(join(repoRoot, "index.js"));

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

let customNodeProps = null;

function CustomNode(props) {
  customNodeProps = props;
  return createElement("div", { className: "probe-node" }, "node");
}

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
  assert(markup.includes("probe-node"), "the custom node type did not render");
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

// ── 2. Every deferred prop throws ───────────────────────────────────────

const flowText = readFileSync(flowSource, "utf8");
const flowFields = new Set(recordFields(flowSource, "JsFlowProps"));
const deferredPattern = /^\s*[[,]?\s*(?:callbackProp|componentProp)\s+"([^"]+)"/gm;
const deferred = [...flowText.matchAll(deferredPattern)].map((m) => m[1]);

// The list is read, not restated, so an empty read is a broken parser rather
// than a boundary with nothing left to defer — and a broken parser here would
// turn the whole section green.
if (deferred.length < 40) {
  fail(`read only ${deferred.length} deferred props from ${flowSource} — the parse is wrong`);
}

check("every deferred prop is a real JsFlowProps field", () => {
  const unknown = deferred.filter((name) => !flowFields.has(name));
  assert(
    unknown.length === 0,
    `deferred entries naming no such prop: ${unknown.join(", ")} — stale entries in Boundary.Flow`
  );
});

// The other direction, and the one that can go wrong quietly. `convertProps`
// hands the PureScript component a literal `Nothing` for every prop that has
// not crossed; the deferred table is what turns that into an error. A prop
// wired to `Nothing` with no table entry is ignored in silence — the exact
// failure the table exists to prevent, one field along.
check("every prop wired to `Nothing` has a deferred entry", () => {
  const convertProps = /^convertProps p =\n([\s\S]*?)\n  \}$/m.exec(flowText);
  assert(convertProps !== null, "cannot find `convertProps` in Boundary.Flow — the parse is wrong");
  const wiredToNothing = [...convertProps[1].matchAll(/^\s*[,{]\s*(\w+): Nothing$/gm)].map(
    (m) => m[1]
  );
  assert(
    wiredToNothing.length > 0,
    "found no props wired to `Nothing` — the parse is wrong, and it would pass anything"
  );
  const deferredSet = new Set(deferred);
  const unguarded = wiredToNothing.filter((name) => !deferredSet.has(name));
  assert(
    unguarded.length === 0,
    `props wired to \`Nothing\` with no deferred entry, so they are silently ignored: ${unguarded.join(", ")}`
  );
});

for (const name of deferred) {
  check(`\`${name}\` is refused at mount`, () => {
    let threw = null;
    try {
      renderToStaticMarkup(createElement(ReactFlow, { ...convertedProps, [name]: () => {} }));
    } catch (e) {
      threw = e;
    }
    assert(threw !== null, "mounted without complaint — the prop is being silently ignored");
    assert(
      threw.message.includes(`\`${name}\``),
      `threw, but the message does not name the prop: ${threw.message}`
    );
    assert(
      /boundary stage \d/.test(threw.message),
      `threw, but the message does not name the stage that lands it: ${threw.message}`
    );
  });
}

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
const jsEdges = [{ id: "a-b", source: "a", target: "b" }];

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
// the array it was given. With `onError` refused there is nobody to report to,
// so this path returns the caller's own array — the identity is the claim, and
// it is this module's decision rather than upstream's behaviour.
check("a connection with no endpoints hands the caller's own array back", () => {
  const out = addEdge({ source: "", target: "a" }, jsEdges);
  assert(out === jsEdges, "returned a copy — the untouched array should come back as it was");
});

throws(
  "`addEdge` refuses `options.onError`",
  () => addEdge({ source: "b", target: "a" }, jsEdges, { onError: () => {} }),
  "onError",
  "boundary stage 2"
);

// ── Report ──────────────────────────────────────────────────────────────

if (failures > 0) {
  console.error(`\n${failures} boundary mount failure(s).\n`);
  process.exit(1);
}

console.log(`boundary mount: ${notes.length} checks, ${deferred.length} deferred props refused.`);
console.log(notes.slice(0, 5).join("\n"));
console.log(`  ✓ … and ${notes.length - 5} more`);
