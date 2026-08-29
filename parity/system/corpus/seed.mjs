// The conformance seed — the corpus's second source (#55).
//
// Upstream's own end-to-end suite, transcribed. Forty-one `generic-*` tests
// drive the four vendored fixtures and two more drive the **example driver**;
// what is lifted here is their **interaction sequences**, with every assertion
// dropped. The net observes far more per interaction than any of those specs
// assert, so the assertions were never the valuable half — the sequences are,
// because they are known-drivable against fixtures that already exist.
//
// **Not one scenario per test.** Many of the forty-one mount the same fixture
// and check an attribute of a *static* render — "classes get applied", "styles
// get applied", "hidden=true hides edge", "aria-label is working" — and one
// mount-and-settle against `edges/general.ts` compares the entire DOM, covering
// all of them at once plus everything nobody thought to assert. So the rule is
// **one mount-only baseline per fixture** (`mount-baselines.mjs`, derived) plus
// **one scenario per distinct interaction sequence**, which is what is here.
//
// ## A one-time fork, explicitly not a mirror
//
// A spec asserts upstream's expectations against ps-flow alone; a scenario
// drives both sides and asserts nothing. Drift between the two is legitimate
// and is not a defect. **Silent** drift is not: a baseline bump that rewrites
// one of these specs leaves the scenario lifted from it untouched, and it goes
// stale with nothing to notice. `fork.mjs` is the detector — every test in
// those five spec files is registered against the scenarios lifted from it and
// a hash of its own source, and a bump that changes one **fails**, asking for
// the affected scenarios to be re-affirmed rather than re-synced.
//
// ## Two transpositions every lift makes
//
// **Absolute destinations become offsets.** Upstream drags to `(500, 500)` and
// `(2000, 2000)` — window coordinates. Targeting here is selector-relative by
// design (a `fitView` divergence would otherwise make one side miss its target
// entirely, turning a 2e-2 zoom gap into a total-miss cascade), so a move to a
// window coordinate becomes a delta of comparable size. What is preserved is
// the *shape* of the gesture, which is what the scenario is for.
//
// **The waits go too, not only the assertions.** Several upstream tests
// interleave `expect(...)` with the driving, waiting for an element to be
// attached before pressing on it. Those waits are the harness's job here:
// `runScenario` settles before the scenario acts, on the page's own clock, and
// an element that still does not resolve is **recorded and driven past** rather
// than thrown.
//
// Ids avoid the thirty `reserved.mjs` holds for #60's scenarios, and say what
// the lifted spec was about rather than which fixture they run against — the
// route beside each already says that.

import { componentRoute } from "../../driver/registry.mjs";
import { defineScenario } from "../harness/scenario.mjs";
import { RESERVED } from "./reserved.mjs";
import { CorpusError, routeOf } from "./routes.mjs";

const EDGES = routeOf("./edges/general.ts");
const NODES = routeOf("./nodes/general.ts");
const NODE_TOOLBAR = routeOf("./node-toolbar/general.ts");
const PANE = routeOf("./pane/general.ts");
const PANE_NON_DEFAULTS = routeOf("./pane/non-defaults.ts");
const COLOR_MODE = componentRoute("color-mode");

// Upstream's fixtures set `deleteKeyCode: 'd'` and `multiSelectionKeyCode: 's'`
// — Backspace breaks WebKit and Meta does not survive their runner — so the
// lifted scenarios press what the fixtures actually listen for.
const DELETE = "d";
const MULTI_SELECT = "s";

// Upstream's node drags all move to a window coordinate far from where they
// started. Named once so the size is one decision rather than a dozen
// independent guesses, and so a scenario that means something different by its
// distance has to say so.
const FAR = { dx: 200, dy: 200 };

const seed = [
  // ── edges/general ──────────────────────────────────────────────────────

  // 'selection > selecting an edge by click'
  { id: "click-selects-edge", route: EDGES, run: (a) => a.click('[data-id="edge-with-class"]') },

  // 'selection > selecting multiple edges by meta-click'. The comment upstream
  // left on that modifier is why `MULTI_SELECT` is `s`.
  {
    id: "multi-select-edges-with-modifier",
    route: EDGES,
    async run(a) {
      await a.click('[data-id="edge-with-class"]');
      await a.click('[data-id="edge-with-style"]', { modifier: MULTI_SELECT });
    },
  },

  // 'properties > selectable=false prevents selecting of edges'
  { id: "click-unselectable-edge", route: EDGES, run: (a) => a.click('[data-id="not-selectable-edge"]') },

  // 'properties > deleting edges is possible'
  {
    id: "delete-key-removes-edge",
    route: EDGES,
    async run(a) {
      await a.click('[data-id="edge-with-class"]');
      await a.key(DELETE);
    },
  },

  // 'properties > deletable=false prevents deleting of edges'
  {
    id: "delete-key-spares-undeletable-edge",
    route: EDGES,
    async run(a) {
      await a.click('[data-id="not-deletable"]');
      await a.key(DELETE);
    },
  },

  // 'properties > interactionWidth is working' — the press lands 21px to the
  // side of the edge's centre, inside the fixture's `interactionWidth: 42` and
  // well outside the stroke. That offset is the whole scenario, so it is
  // upstream's own number rather than `FAR`.
  {
    id: "click-inside-interaction-width",
    route: EDGES,
    run: (a) => a.click({ target: '[data-id="interaction-width"]', dx: 21 }),
  },

  // ── nodes/general ──────────────────────────────────────────────────────

  // 'selection > selecting a node by click'. A bare class resolves to the first
  // match on both sides, which is what upstream's `.first()` asks for.
  {
    id: "click-selects-node",
    route: NODES,
    probeCapabilities: ["selection"],
    run: (a) => a.click(".react-flow__node"),
  },

  // 'selection > selecting multiple nodes with shift drag'. Both corners are
  // measured from the first node's **top left**, which is the form upstream
  // wrote it in and the reason the vocabulary carries a second origin at all.
  {
    id: "shift-drag-selects-nodes",
    route: NODES,
    run: (a) =>
      a.selectionBox(
        { target: ".react-flow__node", origin: "topLeft", dx: -150, dy: -25 },
        { target: ".react-flow__node", origin: "topLeft", dx: 275, dy: 200 }
      ),
  },

  // 'selection > selectable=false prevents selection'
  { id: "click-unselectable-node", route: NODES, run: (a) => a.click('.react-flow__node[data-id="notSelectable"]') },

  // 'dragging > dragging a node'
  { id: "drag-moves-node", route: NODES, run: (a) => a.dragNode(".react-flow__node", FAR) },

  // 'dragging > draggable=false prevents dragging'
  {
    id: "drag-does-not-move-undraggable-node",
    route: NODES,
    run: (a) => a.dragNode('.react-flow__node[data-id="notDraggable"]', FAR),
  },

  // 'dragging > custom drag handle works' — two drags in one scenario, and both
  // are the scenario. The first grabs the node's body just inside its top left
  // corner, which `dragHandle: '.custom-drag-handle'` should refuse; the second
  // grabs the handle, which should not.
  {
    id: "drag-by-custom-drag-handle",
    route: NODES,
    async run(a) {
      await a.dragNode({ target: '.react-flow__node[data-id="drag-handle"]', origin: "topLeft", dx: 10, dy: 10 }, FAR);
      await a.dragNode(".custom-drag-handle", FAR);
    },
  },

  // 'deleting > deleting a node and its edges'
  {
    id: "delete-key-removes-node-and-edges",
    route: NODES,
    async run(a) {
      await a.click('.react-flow__node[data-id="Node-1"]');
      await a.key(DELETE);
    },
  },

  // 'deleting > deletable=false prevents deletion'
  {
    id: "delete-key-spares-undeletable-node",
    route: NODES,
    async run(a) {
      await a.click('.react-flow__node[data-id="notDeletable"]');
      await a.key(DELETE);
    },
  },

  // 'connecting > connecting two nodes'
  {
    id: "connect-source-handle-to-target-handle",
    route: NODES,
    probeCapabilities: ["connection"],
    run: (a) => a.connect('.react-flow__handle[data-nodeid="Node-1"]', '.react-flow__handle[data-nodeid="Node-4"]'),
  },

  // 'connecting > connecting two output handles does not work'. Upstream
  // releases two pixels inside the target handle's top left rather than on its
  // centre, having found that hovering it did not work in their Svelte runner;
  // the offset is kept, because it is what was measured to reach the handle.
  {
    id: "connect-output-to-output-handle",
    route: NODES,
    run: (a) =>
      a.connect('.react-flow__handle[data-nodeid="Node-2"]', {
        target: '.react-flow__handle[data-nodeid="Node-4"]',
        origin: "topLeft",
        dx: 2,
        dy: 2,
      }),
  },

  // 'connecting > connecting two input handles does not work'
  {
    id: "connect-input-to-input-handle",
    route: NODES,
    run: (a) =>
      a.connect('.react-flow__handle[data-nodeid="Node-1"]', {
        target: '.react-flow__handle[data-nodeid="Node-3"].source',
        origin: "topLeft",
        dx: 2,
        dy: 2,
      }),
  },

  // 'connecting > connectable=false prevents connections'
  {
    id: "connect-to-unconnectable-handle",
    route: NODES,
    run: (a) =>
      a.connect('.react-flow__handle[data-nodeid="Node-1"]', {
        target: '.react-flow__handle[data-nodeid="notConnectable"]',
        origin: "topLeft",
        dx: 2,
        dy: 2,
      }),
  },

  // ── pane/general ───────────────────────────────────────────────────────

  // 'pan & zoom > panning the pane moves it'. **Deliberately not `pan()`**:
  // upstream never releases, and what is lifted is the sequence rather than the
  // gesture, so this drops to primitives and settles mid-gesture. That is the
  // only way transient state — a pane mid-pan — is observable at all, and it is
  // exactly the case no gesture can express.
  {
    id: "drag-pans-the-pane",
    route: PANE,
    async run(a) {
      await a.pointerDown(".react-flow__pane");
      await a.pointerMove(null, { dx: 100, dy: 100 });
    },
  },

  // 'pan & zoom > scrolling the default pane zooms it'
  {
    id: "wheel-zooms-the-pane",
    route: PANE,
    probeCapabilities: ["viewport"],
    run: (a) => a.wheel(".react-flow__pane", { deltaY: 100 }),
  },

  // 'minZoom & maxZoom > minZoom' — one wheel far past the fixture's floor of
  // 0.25, so what is observed is the clamp rather than the step.
  {
    id: "wheel-zooms-out-to-min",
    route: PANE,
    run: (a) => a.wheel(".react-flow__pane", { deltaX: 5000, deltaY: 5000 }),
  },

  // 'minZoom & maxZoom > maxZoom'
  {
    id: "wheel-zooms-in-to-max",
    route: PANE,
    run: (a) => a.wheel(".react-flow__pane", { deltaX: -5000, deltaY: -5000 }),
  },

  // ── pane/non-defaults ──────────────────────────────────────────────────

  // 'pan & zoom > panOnScroll pans the pane on scrolling'. The same wheel the
  // default pane zooms under; the fixture's `panOnScroll` is what makes these
  // two scenarios rather than one.
  {
    id: "wheel-pans-with-panonscroll",
    route: PANE_NON_DEFAULTS,
    run: (a) => a.wheel(".react-flow__pane", { deltaX: 100, deltaY: 100 }),
  },

  // ── node-toolbar/general ───────────────────────────────────────────────

  // 'toolbar default behaviour' — a toolbar with no `toolbarVisible` is only
  // attached while its node is selected, so the click is the whole scenario.
  {
    id: "click-reveals-default-toolbar",
    route: NODE_TOOLBAR,
    run: (a) => a.click('.react-flow__node[data-id="default-node"]'),
  },

  // ── the example driver ─────────────────────────────────────────────────

  // props.spec's 'colorMode > render dark color mode'. Upstream reaches for
  // Playwright's `selectOption`, which is not an input event and has no place
  // in the primitive tier. Native-select typeahead chooses the option whose
  // label starts with `d` and fires `change` exactly as a chosen option does.
  // Staying inside the closed tier is the point — extending it is a decision,
  // and one scenario is not a reason.
  {
    id: "select-dark-color-mode",
    route: COLOR_MODE,
    run: (a) => a.key("d", { target: '[data-testid="colormode-select"]' }),
  },
];

// The seed may not take a name #60's scenarios have already been promised. See
// `reserved.mjs`: several of these transcriptions land close enough to a
// reserved scenario that the collision would be easy to make and invisible
// afterwards, since `gate-pending` only ever asks whether the *name* is in the
// corpus.
const claimed = seed.filter(({ id }) => id in RESERVED);
if (claimed.length) {
  throw new CorpusError(
    `the conformance seed claims ${claimed.length} scenario id(s) reserved for the test-debt scenarios (#60):\n` +
      claimed.map(({ id }) => `  ${id} (was ${RESERVED[id]})`).join("\n") +
      `\nThe pending gate cites those by name and would be satisfied by a scenario written for something ` +
      `else. Rename the seed scenario; #60 decides whether one of these already covers the row.`
  );
}

/** The lifted scenarios, in the order the specs they came from are read. */
export const seedScenarios = seed.map(defineScenario);
