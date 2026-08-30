// The thirty test-debt scenarios — the corpus's third source (#60).
//
// Forty-two rows of the changelog audit are bound for the net, and they collapse
// onto these thirty scenarios. `tickets/080-test-debt-dispositions.md` decided
// the fates and `tickets/081-interaction-corpus.md` gave them the semantic ids
// `reserved.mjs` has been holding ever since; this file is where the names stop
// being a promise. A `gate-pending` row cites one by name and fails when the
// name resolves to neither a written scenario nor a reserved id, so until now
// all forty-two read as *reserved* — waiting on somebody to write the scenario
// at all — and after this they read as driven.
//
// ## The currency these are counted in
//
// Not exports. The census counts exports and this counts **conditional
// behaviours within** an export: driving `onNodeDrag` once does not cover
// "call `onNodeDrag` while autopan is ongoing", so export coverage can go green
// with most of these unexercised. That is why behaviour coverage stays
// hand-declared while export coverage is derived — "drag while autopan is
// ongoing" appears as no token in any trace, and no selector matches a
// condition.
//
// **What the net removes is the expected values, never the stimulus.** Each
// scenario below still has to do the thing; what it never has to do is say what
// should come out of it, because upstream is running beside it.
//
// ## Where the actions come from
//
// The closed primitive tier and the open gesture tier, and nothing else — a
// scenario is handed the vocabulary and no way to learn which side it drives.
// Scenarios reach for a gesture by default and drop to primitives when the
// scenario is *about* an unusual input sequence, which here is most often a
// gesture deliberately left unfinished.
//
// ## Ending mid-gesture
//
// Four of these settle with the pointer or a finger still down, and it is the
// only way transient state is observable at all: a selection rectangle exists
// only while the pointer is held, an aborted drag has nothing to say once the
// drag is over, and a connection line is gone the moment it lands.
// `runScenario` settles after the last action rather than after the last
// *gesture*, which is what makes that legal — and the next capture is given a
// pointer-up on `about:blank`, so a held button never leaks into the run after.
//
// ## Concentration risk
//
// Four scenarios carry three or four rows each and are the ones to review if the
// corpus is ever trimmed: `connect-handle-to-handle` (4),
// `flow-props-change-after-mount`, `viewport-helpers-with-options` and
// `fitview-onnodeschange-variants` (3 each). `flow-props-change-after-mount` is
// the sharpest — its three StoreUpdater rows are reachable **only** because
// callbacks compare as an exact sequence of order, count and interleaving. A
// weakening in `../weakenings.json` against any handler it fires would make all
// three invisible at once, which is why that file's own header says to check
// these first.

import { AFTER_MOUNT } from "../../driver/controls.mjs";
import { defineScenario } from "../harness/scenario.mjs";
import { RESERVED } from "./reserved.mjs";
import { CorpusError, routeOf } from "./routes.mjs";

// Upstream's, which the lifted scenarios already aim at.
const NODES = routeOf("./nodes/general.ts");
const PANE = routeOf("./pane/general.ts");

// ps-flow's own, named for the condition each one sets. `fixtures/README.md`
// says why they live in this repo's tree rather than in the vendored one.
const AUTOPAN = routeOf("./nodes/autopan.ts");
const BACKGROUND = routeOf("./chrome/background.ts");
const BASE_EDGE_PATH = routeOf("./edges/base-edge-path.ts");
const CONNECTIONS = routeOf("./nodes/connections.ts");
const CONTROLS = routeOf("./chrome/controls.ts");
const CUSTOM_TESTID = routeOf("./flow/custom-testid.ts");
const DISPLAY_NONE = routeOf("./flow/display-none.ts");
const EXPAND_PARENT = routeOf("./nodes/expand-parent.ts");
const MINIMAP_COLORS = routeOf("./chrome/minimap-colors.ts");
const MINIMAP_HIDDEN = routeOf("./chrome/minimap-hidden-nodes.ts");
const NOWHEEL = routeOf("./nodes/nowheel.ts");
const NO_SELECT_ON_DRAG = routeOf("./nodes/no-select-on-drag.ts");
const PANELS = routeOf("./chrome/panels.ts");
const PROPS_CHANGE = routeOf("./flow/props-change.ts");
const TALL = routeOf("./nodes/tall.ts");
const UNCONTROLLED = routeOf("./fitview/uncontrolled.ts");
const VIEWPORT_HELPERS = routeOf("./viewport/helpers.ts");
const UNMEASURED = routeOf("./nodes/unmeasured.ts");

const PANE_SELECTOR = ".react-flow__pane";
const MINIMAP = ".react-flow__minimap";

const node = (id) => `.react-flow__node[data-id="${id}"]`;
const handle = (nodeId, handleId) =>
  handleId === undefined
    ? `.react-flow__handle[data-nodeid="${nodeId}"]`
    : `.react-flow__handle[data-nodeid="${nodeId}"][data-handleid="${handleId}"]`;
const control = (name) => `[data-testid="${name}"]`;

// Upstream's fixtures set `multiSelectionKeyCode: 's'` — Meta does not survive
// their runner — so a scenario driving one presses what it listens for. Spelled
// out here rather than imported from `seed.mjs`: that module is a transcription
// of upstream's suite and this one is not, and a change to what upstream's
// fixtures set must not silently re-aim a scenario written against a ps-flow
// fixture that never had the setting.
const MULTI_SELECT = "s";

const testDebt = [
  // ── drag ────────────────────────────────────────────────────────────────

  // #5684 — consolidating the drag handler's effects, which had broken
  // programmatic selection. So a selection is made *first* and the drag has to
  // leave it alone; a drag on a pristine flow could not have shown the bug. Two
  // drags, because what was consolidated is the effect that re-subscribes
  // between them.
  {
    id: "drag-node-release",
    route: NODES,
    async run(a) {
      await a.click(node("Node-2"));
      await a.dragNode(node("Node-1"), { dx: 120, dy: 80 });
      await a.dragNode(node("Node-1"), { dx: -60, dy: -40 });
    },
  },

  // #5803 — the drag state is reset when the drag is aborted. **Ends with the
  // pointer down**, and has to: once the button is released the state has been
  // reset either way, and the two implementations would be agreeing about the
  // aftermath of something neither is still doing. What is compared is a flow
  // *while* it holds a drag it has been told to abandon.
  {
    id: "drag-node-escape-mid-gesture",
    route: NODES,
    async run(a) {
      await a.pointerDown(node("Node-1"));
      await a.pointerMove(null, { dx: 60, dy: 40 });
      await a.pointerMove(null, { dx: 60, dy: 40 });
      await a.key("Escape");
      await a.pointerMove(null, { dx: 60, dy: 40 });
    },
  },

  // #5450 — `onNodeDrag` keeps firing while autopan is ongoing. The pointer is
  // walked into the pane's top-left corner, the region `calcAutoPan` reads as
  // "pan this way", and held there across four moves before it is released.
  //
  // The **dwell is spelled as moves rather than as a wait**, which is the whole
  // of what ticket 081 left open when it said this scenario needs a way to
  // express one. The vocabulary has no duration in it and the trace records no
  // time anywhere, so a scenario that held the pointer for 500ms — which is
  // what upstream's own two autoPan specs do, and why the conformance seed
  // declined to lift them — would settle at a position that was a function of
  // elapsed frames and could not reproduce itself across its own two captures.
  // Four moves are four events, on both sides, and autopan's frames run between
  // them.
  //
  // And it **releases**, where the other mid-gesture scenarios do not. Autopan
  // runs on `requestAnimationFrame` for as long as the pointer is held, so a
  // scenario that ended holding it would never settle — the page would still be
  // changing when the poll ceiling ran out, and the run would abort rather than
  // record anything. Releasing stops the loop, and what it was doing while it
  // ran is in the callback log either way, which is where this row lives.
  {
    id: "drag-node-autopan",
    route: AUTOPAN,
    async run(a) {
      await a.pointerDown(node("Node-1"));
      await a.pointerMove(PANE_SELECTOR, { origin: "topLeft", dx: 6, dy: 6 });
      await a.pointerMove(PANE_SELECTOR, { origin: "topLeft", dx: 5, dy: 6 });
      await a.pointerMove(PANE_SELECTOR, { origin: "topLeft", dx: 6, dy: 5 });
      await a.pointerMove(PANE_SELECTOR, { origin: "topLeft", dx: 5, dy: 5 });
      await a.pointerUp(null);
    },
  },

  // #5682 — no unnecessary updates when `selectNodesOnDrag` is off. An update
  // that does not happen leaves no DOM residue, so the witness is the exact
  // callback sequence: a superfluous selection change is a call one side made
  // and the other did not.
  {
    id: "drag-node-no-select-on-drag",
    route: NO_SELECT_ON_DRAG,
    async run(a) {
      await a.dragNode(node("Node-1"), { dx: 120, dy: 80 });
      await a.dragNode(node("Node-3"), { dx: -80, dy: 60 });
    },
  },

  // #5043 — the *current* `expandParent` is read on every drag step rather than
  // once at the start. The child is walked out past its parent's corner in eight
  // steps, so the parent has to grow repeatedly during the gesture: a value read
  // once and a value read every step reach the same end position, and only the
  // steps between them tell the two apart.
  {
    id: "drag-child-expand-parent",
    route: EXPAND_PARENT,
    async run(a) {
      await a.dragNode(node("child"), { dx: 280, dy: 200, steps: 8 });
    },
  },

  // #5052 — the error printed when an uninitialized node is dragged. The fixture
  // never applies a dimension change, so every node stays unmeasured for as long
  // as the page lives and the observation is in `console`.
  {
    id: "drag-unmeasured-node",
    route: UNMEASURED,
    async run(a) {
      await a.dragNode(node("Node-1"), { dx: 100, dy: 60 });
    },
  },

  // ── selection ───────────────────────────────────────────────────────────

  // #5551 — a selection may start above a node. The box therefore begins on a
  // node's own centre, which is the press that used to grab the node instead.
  {
    id: "selection-box-from-node",
    route: NODES,
    async run(a) {
      await a.selectionBox(node("Node-1"), { target: node("Node-4"), origin: "topLeft", dx: 140, dy: 120 });
    },
  },

  // #5593 and #5727 — the box is reset when a node is selected, and the visual
  // selection is cleared when nothing is left selected. Three acts in order:
  // draw a box over several nodes, click one node, click the pane. The last is
  // what #5727 is about, and it means nothing except after the second.
  {
    id: "selection-box-then-click-node",
    route: NODES,
    async run(a) {
      await a.selectionBox(
        { target: node("Node-1"), origin: "topLeft", dx: -150, dy: -40 },
        { target: node("Node-3"), origin: "topLeft", dx: 170, dy: 130 }
      );
      await a.click(node("Node-4"));
      await a.click(PANE_SELECTOR);
    },
  },

  // #5362 — a Panel's pointer events while a selection is being dragged. **Ends
  // mid-gesture**, with the pointer and Shift both still down: the rule applies
  // only while the drag is in flight, and so does the selection rectangle it
  // applies around. This is also the corpus's only witness for `SelectionRect`,
  // which every completed selection box destroys before the trace is read.
  {
    id: "selection-box-mid-gesture",
    route: PANELS,
    async run(a) {
      await a.key("Shift", { action: "down" });
      await a.pointerDown(PANE_SELECTOR);
      await a.pointerMove(null, { dx: 180, dy: 140 });
      await a.pointerMove(null, { dx: 60, dy: 40 });
    },
  },

  // #5638 — the selection box under touch input, which needs `touch-action:
  // none` on the pane. Shift is held from the keyboard while the finger draws,
  // because the fixture's selection key is Shift and a finger cannot press one.
  {
    id: "selection-box-touch",
    route: NODES,
    touch: true,
    async run(a) {
      await a.key("Shift", { action: "down" });
      await a.touch("start", [{ target: PANE_SELECTOR }]);
      await a.touch("move", [{ target: PANE_SELECTOR, dx: 120, dy: 90 }]);
      await a.touch("move", [{ target: PANE_SELECTOR, dx: 220, dy: 160 }]);
      await a.touch("end", []);
      await a.key("Shift", { action: "up" });
    },
  },

  // ── keyboard ────────────────────────────────────────────────────────────

  // #4862 — an arrow key that moves a node must not also scroll the page. The
  // fixture is taller than the window precisely so the page *can* scroll, which
  // makes `dom.page.scrollY` the witness; on a page that cannot scroll, both
  // sides record zero and agree about nothing.
  {
    id: "arrow-key-selected-node",
    route: TALL,
    async run(a) {
      await a.click(node("Node-1"));
      await a.arrowKeyNudge("down", { times: 4 });
      await a.arrowKeyNudge("right", { times: 2 });
    },
  },

  // #4991 — focusing a node must not shift the viewport, which the browser would
  // do by scrolling the focused element into view. The same fixture and the same
  // reason: the scroll has to be possible for its absence to be a finding.
  // Tabbed into rather than clicked, because a click focuses an element without
  // the browser's scroll-into-view ever being asked for.
  {
    id: "keyboard-focus-node",
    route: TALL,
    async run(a) {
      await a.key("Tab");
      await a.key("Tab");
      await a.key("Tab");
      await a.key("Tab");
      await a.key("Enter");
    },
  },

  // ── connections ─────────────────────────────────────────────────────────

  // Four rows, the heaviest concentration in the corpus. #5578 (the current
  // pointer position reaches the connection) and #5704 (`onConnectEnd` and
  // `isValidConnection` stay current through the gesture) ride on the dragged
  // connection; #5042 (a click connection when the target sets
  // `isConnectableStart`) and #5428 (clicking a detached handle starts one) ride
  // on the click connection after it — a different way into the same code, which
  // is why both are here rather than in two scenarios.
  {
    id: "connect-handle-to-handle",
    route: NODES,
    probeCapabilities: ["connection"],
    async run(a) {
      await a.connect(handle("Node-1"), handle("Node-4"));
      await a.click(`${handle("Node-3")}.source`);
      await a.click(handle("Node-2"));
    },
  },

  // #5635 — an ongoing connection follows a node the keyboard moves. **Ends
  // mid-gesture**: the connection line is the thing that updates, and it does
  // not survive the release. The node is selected first so the arrow keys have
  // something to move.
  {
    id: "connect-then-keyboard-move",
    route: NODES,
    async run(a) {
      await a.click(node("Node-3"));
      await a.pointerDown(handle("Node-1"));
      await a.pointerMove(handle("Node-1"), { dx: 20, dy: 20 });
      await a.arrowKeyNudge("right", { times: 3 });
      await a.arrowKeyNudge("down", { times: 2 });
    },
  },

  // #5480 — a second finger during an active connection is ignored. **Ends
  // mid-gesture**, and multi-touch by construction: the first finger opens the
  // connection, the second arrives while it is open, and both then move. A
  // gesture that released first would compare two flows with no connection in
  // progress, which is the one state this row says nothing about.
  {
    id: "connect-second-touch-point",
    route: NODES,
    touch: true,
    async run(a) {
      await a.touch("start", [{ target: handle("Node-1"), id: 1 }]);
      await a.touch("move", [{ target: handle("Node-1"), dx: 30, dy: 40, id: 1 }]);
      await a.touch("start", [
        { target: handle("Node-1"), dx: 30, dy: 40, id: 1 },
        { target: node("Node-3"), id: 2 },
      ]);
      await a.touch("move", [
        { target: handle("Node-1"), dx: 60, dy: 80, id: 1 },
        { target: node("Node-3"), dx: 40, dy: 0, id: 2 },
      ]);
    },
  },

  // #4949 — `useNodeConnections` reports every connected edge, not one per
  // handle. The fixture's node renders its own reading into the DOM, so this is
  // a **plain scenario compared at full scope** rather than a probe variant: a
  // probe changes what the page renders and is therefore compared only at its
  // own observation level, which is the wrong instrument for a claim about a
  // graph the fixture set up. The connection is drawn so the reading is captured
  // after the graph moved under the hook as well as at the mount.
  {
    id: "probe-node-connections",
    route: CONNECTIONS,
    async run(a) {
      await a.connect(handle("down-1", "out"), handle("hub", "in"));
    },
  },

  // ── viewport and the imperative surface ─────────────────────────────────

  // #5723 — the helpers pass their options on. The corpus's only imperative
  // calls, and every option is non-default: a helper that ignored its options
  // entirely would answer a default one identically, so a default option is no
  // observation at all. `deleteElements` is last, because it changes the graph
  // the calls before it were measured against.
  //
  // #5722 and #5012 are about `screenToFlowPosition`'s own `snapGrid` option
  // and its `snapToGrid` default, and neither is called from here — `call`
  // drives mutators only, since a query through it would become an intermediate
  // checkpoint. They ride on the settled `api.queries` snapshot instead, against
  // a fixture that snaps: `viewport/helpers.ts` says why the default is only
  // observable against a flow whose own setting is the opposite.
  {
    id: "viewport-helpers-with-options",
    route: VIEWPORT_HELPERS,
    probeCapabilities: ["viewport"],
    async run(a) {
      await a.call("setViewport", [{ x: 40, y: -20, zoom: 1.5 }, { duration: 0 }]);
      await a.call("zoomTo", [1.25, { duration: 0 }]);
      await a.call("zoomIn", [{ duration: 0 }]);
      await a.call("zoomOut", [{ duration: 0 }]);
      await a.call("fitView", [{ padding: 0.4, includeHiddenNodes: false, minZoom: 0.2, maxZoom: 3, duration: 0 }]);
      await a.call("setCenter", [120, 80, { zoom: 2, duration: 0 }]);
      await a.call("fitBounds", [{ x: -100, y: -100, width: 400, height: 300 }, { padding: 0.2, duration: 0 }]);
      await a.call("deleteElements", [{ nodes: [{ id: "3" }], edges: [{ id: "second-edge" }] }]);
    },
  },

  // #5547 — `onMoveEnd` is always called when `onMoveStart` was. Two complete
  // pans, because "always" is a claim about every gesture and one pan cannot
  // tell a handler that fires once from one that fires per gesture.
  {
    id: "pan-gesture-complete",
    route: PANE,
    async run(a) {
      await a.pan({ dx: 140, dy: 90 });
      await a.pan({ dx: -70, dy: 110 });
    },
  },

  // #5120, #5127 and #5132 — a queued `fitView` that has to resolve without the
  // consumer feeding any change back. One fixture is all three conditions at
  // once, and `fitview/uncontrolled.ts` says why. The mount does the first fit;
  // the calls after it ask the same question again once the graph has moved.
  {
    id: "fitview-onnodeschange-variants",
    route: UNCONTROLLED,
    async run(a) {
      await a.call("fitView", [{ padding: 0.3, duration: 0 }]);
      await a.dragNode(node("Node-1"), { dx: 160, dy: 120 });
      await a.call("fitView", [{ padding: 0.1, duration: 0 }]);
    },
  },

  // #5249 — `onNodesChange` is raised for an uncontrolled flow mutated through
  // `updateNode`. There is no prop the caller could have changed, so the store
  // has to report the change itself. These five mutators are also the corpus's
  // only source of `add` and `replace` node and edge changes: every other
  // scenario produces `dimensions`, `position`, `select` and `remove`.
  {
    id: "uncontrolled-update-node",
    route: UNCONTROLLED,
    async run(a) {
      await a.call("updateNode", ["Node-1", { data: { label: "updated" } }]);
      await a.call("updateNodeData", ["Node-2", { label: "data updated" }]);
      await a.call("addNodes", [{ id: "added", data: { label: "added" }, position: { x: 240, y: 240 } }]);
      await a.call("addEdges", [{ id: "added-edge", source: "Node-1", target: "added" }]);
      await a.call("updateEdge", ["1-2", { label: "updated edge" }]);
    },
  },

  // ── props that change after the mount ───────────────────────────────────

  // #5769, #5733 and #5368 — the StoreUpdater rows, and the sharpest
  // concentration in the corpus. ps-flow runs one effect per tracked prop where
  // upstream runs one over a field list, so what these are about is *ordering*,
  // and the fixture changes a dozen tracked fields at once because a single
  // field has nothing to be ordered against. Driving before and after the change
  // is what makes the new values observable at all: with `elementsSelectable`
  // and `nodesDraggable` both turned off, the click and the drag after the
  // change are supposed to do nothing.
  {
    id: "flow-props-change-after-mount",
    route: PROPS_CHANGE,
    async run(a) {
      await a.click(node("Node-1"));
      await a.click(control(AFTER_MOUNT));
      await a.click(node("Node-3"), { modifier: MULTI_SELECT });
      await a.dragNode(node("Node-3"), { dx: 60, dy: 40 });
    },
  },

  // #5455 — the warning that must *not* be printed when the container is hidden.
  // Mounted visible and then hidden, so the resize handler is on the path the
  // fix guards; `flow/display-none.ts` says why starting hidden would have
  // measured nothing to begin with.
  {
    id: "mount-in-display-none",
    route: DISPLAY_NONE,
    async run(a) {
      await a.click(control(AFTER_MOUNT));
    },
  },

  // ── the chrome components ───────────────────────────────────────────────

  // #5546 and #5692 — a minimap over a flow with nothing to show. Both rows are
  // crashes rather than differences, so what carries them is `console`, through
  // Playwright's page-error capture. Driven as well as mounted: a minimap that
  // survives its first paint can still throw when panned over an empty bounds.
  {
    id: "minimap-all-nodes-hidden",
    route: MINIMAP_HIDDEN,
    async run(a) {
      await a.click(MINIMAP);
      await a.wheel(MINIMAP, { deltaY: -120 });
    },
  },

  // #5139 — `rgba` rather than `rgb` for a mask colour carrying opacity. A node
  // is selected first because the minimap colours a selected node differently,
  // so the second reading is of a minimap that has had to recompute rather than
  // of the one the mount painted.
  {
    id: "minimap-custom-mask-colors",
    route: MINIMAP_COLORS,
    async run(a) {
      await a.click(node("Node-1"));
      await a.click(MINIMAP);
    },
  },

  // #5153 — separators between horizontally laid-out control buttons. Every
  // button is pressed, so the row is not merely that they rendered: a separator
  // inserted at the wrong point in the list is a button that has stopped being
  // where it was.
  {
    id: "controls-horizontal",
    route: CONTROLS,
    async run(a) {
      await a.click(".react-flow__controls-zoomin");
      await a.click(".react-flow__controls-zoomout");
      await a.click(".react-flow__controls-fitview");
      await a.click(".react-flow__controls-interactive");
    },
  },

  // #5252 — a panel centred at `top-center` and at `bottom-center`. Each is
  // aimed at **by its own position classes**, which makes the driving log the
  // witness: a panel that was not placed where it said resolves to nothing and
  // is recorded as an unresolved action, rather than as a quietly different
  // offset in an attribute nobody was reading.
  {
    id: "panel-center-positions",
    route: PANELS,
    async run(a) {
      await a.click(".react-flow__panel.top.center");
      await a.click(".react-flow__panel.bottom.center");
    },
  },

  // #5259 — the background colour's CSS variable fallback, emitted inline by
  // `Background.purs` and therefore plain text in the `dom` section. The pane is
  // clicked so the background is captured under an interaction as well as at
  // rest.
  {
    id: "background-custom-bgcolor",
    route: BACKGROUND,
    async run(a) {
      await a.click(PANE_SELECTOR);
    },
  },

  // #4844 — a custom `data-testid` on `<ReactFlow>`. The action **aims at the
  // custom id**, which makes the driving log the witness: an implementation that
  // dropped the attribute records an unresolved action instead of a DOM that
  // differs by one attribute nobody was looking at.
  {
    id: "flow-custom-testid",
    route: CUSTOM_TESTID,
    async run(a) {
      await a.click({ target: '[data-testid="psflow-custom-flow"]', origin: "topLeft", dx: 8, dy: 8 });
    },
  },

  // #4855 — `BaseEdge` forwards `<path>` attributes it does not itself name.
  // Aimed at one of the forwarded attributes, for the same reason as the
  // scenario above: the target resolves only if the pass-through happened.
  {
    id: "custom-edge-baseedge-path",
    route: BASE_EDGE_PATH,
    async run(a) {
      await a.click('[data-psflow-edge="base-edge-path"]');
      await a.click('[data-id="custom-2"]', { modifier: MULTI_SELECT });
    },
  },

  // #5512 and #5148 — a pinch over a `nowheel` node must zoom neither the flow
  // nor the page. What is observed is a browser default that did not happen, and
  // `dom.page.visualViewportScale` is the only place that is visible at all.
  {
    id: "pinch-over-nowheel-node",
    route: NOWHEEL,
    touch: true,
    async run(a) {
      await a.pinch(node("nowheel"), { spread: 60, scale: 2.5, steps: 4 });
    },
  },
];

// This source **claims** the reserved ids, where every other source is forbidden
// them. Exactly the thirty, and each exactly once: a name the register holds and
// nothing here writes leaves its rows reading as reserved forever, and a name
// written here the register does not hold is one no `gate-pending` row can
// resolve to. Both failures are silent, and both are why `reserved.mjs` exists.
const claimed = testDebt.map(({ id }) => id);
const missing = Object.keys(RESERVED).filter((id) => !claimed.includes(id));
const unreserved = claimed.filter((id) => !(id in RESERVED));
const duplicated = claimed.filter((id, i) => claimed.indexOf(id) !== i);

if (missing.length || unreserved.length || duplicated.length) {
  throw new CorpusError(
    `the test-debt scenarios do not match the thirty ids reserved for them:\n` +
      (missing.length ? `  reserved and unwritten: ${missing.join(", ")}\n` : "") +
      (unreserved.length ? `  written and not reserved: ${unreserved.join(", ")}\n` : "") +
      (duplicated.length ? `  written twice: ${duplicated.join(", ")}\n` : "") +
      `\`reserved.mjs\` is the register a \`gate-pending\` row resolves against, and a row naming ` +
      `something in neither it nor the corpus is a typo that reads as a plan.`
  );
}

/** The thirty, grouped as `tickets/081-interaction-corpus.md` groups them. */
export const testDebtScenarios = testDebt.map(defineScenario);
