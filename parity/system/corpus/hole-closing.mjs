// Scenarios written to make a divergence class observable (#93).
//
// The index anticipated this source: the seed is lifted from upstream's suite,
// the thirty are lifted from the test-debt ticket, the retirement debt is lifted
// from two browser specs, and "the hole-closing scenarios after them will arrive
// the same way" — written by someone reading a fix ticket rather than a register.
//
// ## What belongs here
//
// A scenario whose reason to exist is that the corpus could not see a class the
// port was found to diverge on. That absence takes two shapes, and a scenario
// here may close either.
//
//   * An **export with no witness at all**, which `coverage/holes.json` declares
//     and `parity:coverage` counts. Closing one retires its entry.
//   * A **condition inside a driven export** that no scenario reaches. Coverage
//     is derived per export, so it counts the export as driven and says nothing
//     about the branch. Nothing fails, and the class is unobserved anyway.
//
// The second shape is the one that keeps arriving. Three fix tickets in a row
// (#103, #99, #100) closed with the net unable to move by a single row, because
// the corpus drove the export and never the condition.
//
// ## What does not belong here
//
// A scenario lifted from an upstream spec belongs in the **conformance seed**,
// where `fork.mjs` can register the spec it came from and notice a bump that
// rewrites it. Nothing here is lifted, so nothing here owes that register an
// entry; what it owes instead is a written reason, per scenario, naming the class
// and the ticket.
//
// A test-debt id belongs in `test-debt.mjs`, which is the only source allowed to
// take one — it checks itself against `reserved.mjs` in both directions. So an id
// here must be in neither, and `assertDistinctIds` in `index.mjs` is what catches
// a collision with the three hand-named sources.

import { AFTER_MOUNT } from "../../driver/controls.mjs";
import { defineScenario } from "../harness/scenario.mjs";
import { routeOf } from "./routes.mjs";

const LIMITS_CHANGE = routeOf("./flow/limits-change.ts");
const PROPS_CHANGE = routeOf("./flow/props-change.ts");
const CONTROLLED_VIEWPORT = routeOf("./viewport/controlled.ts");
const PAN_ON_SCROLL = routeOf("./viewport/pan-on-scroll.ts");
const NOT_SELECTABLE = routeOf("./flow/not-selectable.ts");

const control = (name) => `[data-testid="${name}"]`;

const holeClosing = [
  // The class: a zoom limit changed after mount, then a gesture against the new
  // bound. Ticket #105, off #103.
  //
  // #103 found that `SetMinZoom`, `SetMaxZoom` and `SetTranslateExtent` wrote
  // store state and never reached the pan-zoom instance, so a flow that changed
  // one after mount kept the pair `createXYPanZoom` was seeded with. The net
  // could not see it, and the two halves of the question were each covered
  // alone: `wheel-zooms-out-to-min` and `wheel-zooms-in-to-max` set their limits
  // as mount props, where the `useEffectOnce` path was always correct, and
  // `flow-props-change-after-mount` moves `minZoom` 0.5 -> 0.1 and `maxZoom`
  // 2 -> 8 and then never zooms.
  //
  // This is both halves at once, on the same route and the same control, so the
  // fixture is unchanged and `flow-props-change-after-mount`'s rows — the
  // sharpest StoreUpdater concentration in the corpus — are not re-baselined.
  // A separate scenario costs one more capture and leaves that reading alone,
  // which is what #105's scope note asked for.
  //
  // Both directions, because the two bounds reach d3 through one call:
  // `setScaleExtent` takes the pair, so a reducer that pushed only the changed
  // half would clamp correctly one way and not the other. Out first, since
  // `fitView: true` starts this fixture below 1.
  {
    id: "wheel-zooms-to-changed-limits",
    route: PROPS_CHANGE,
    probeCapabilities: ["viewport"],
    async run(a) {
      await a.click(control(AFTER_MOUNT));
      await a.wheel(".react-flow__pane", { deltaX: 5000, deltaY: 5000 });
      await a.wheel(".react-flow__pane", { deltaX: -5000, deltaY: -5000 });
    },
  },

  // The other half of the same class: a pan limit changed after mount, then a
  // pan into the new bound. Ticket #105, off #103.
  //
  // `translateExtent` had no coverage anywhere in the corpus, at mount or after
  // it, so `RunSetTranslateExtent` was the one of #103's three effects with no
  // scenario at all. `nodes/autopan.ts` sets an extent, but the auto-pan loop is
  // what drives it and that is a different question — #108 owns making a refused
  // auto-pan frame observable.
  //
  // `flow/limits-change.ts` says why the extent narrows rather than widens, and
  // why the after-mount extent is smaller than the window: there is then exactly
  // one transform that satisfies it, so the end state is the extent rather than
  // the length of the drag. A viewport still holding the mount extent pans
  // straight past.
  {
    id: "drag-pans-into-changed-extent",
    route: LIMITS_CHANGE,
    probeCapabilities: ["viewport"],
    async run(a) {
      await a.click(control(AFTER_MOUNT));
      await a.pointerDown(".react-flow__pane");
      await a.pointerMove(null, { dx: 400, dy: 300 });
      await a.pointerMove(null, { dx: 400, dy: 300 });
      await a.pointerUp();
    },
  },

  // A changed controlled viewport, then a pan. Ticket #128, off #124.
  //
  // #124 made `syncViewport` skip an unchanged transform and mark its d3 event
  // as a sync, and found nothing called it: `useViewportSync` wrote the store
  // and never reached the instance, and no fixture passed a controlled
  // `viewport` at all. `viewport/controlled.ts` says why its viewport is never
  // fed back, which is what lets the `callbacks` section read d3's own
  // transform.
  //
  // The instance has two syncs to make, and both are observed. The mount sync
  // moves d3 off `defaultViewport` once `<ZoomPane />` has created the
  // instance; the control's moves it to the changed viewport. Each reaches d3
  // as a transform, which upstream reports through `onMoveStart`, `onMove` and
  // `onMoveEnd` carrying d3's own value, and the pan then starts from wherever
  // d3 was left. A port that missed either sync shows a missing callback or a
  // pan from the wrong transform.
  //
  // The control is pressed before the pan and not between two of them. d3 eats
  // the first click after a drag that moved, through a capture-phase listener
  // on `window` that it removes on a zero-delay timer, and Chrome runs input
  // ahead of timers. A click straight after a pan therefore landed or did not
  // by scheduling, on either side, which is a race in the scenario rather than
  // a difference between the two implementations.
  {
    id: "pan-after-controlled-viewport-change",
    route: CONTROLLED_VIEWPORT,
    probeCapabilities: ["viewport"],
    async run(a) {
      await a.click(control(AFTER_MOUNT));
      await a.pointerDown(".react-flow__pane");
      await a.pointerMove(null, { dx: 40, dy: 20 });
      await a.pointerMove(null, { dx: 40, dy: 20 });
      await a.pointerUp();
    },
  },

  // A Ctrl-wheel over an off-centre point, with `panOnScroll` on. Ticket #129,
  // off #124.
  //
  // The pan-on-scroll handler reads a wheel with `ctrlKey` as a pinch and
  // scales about the pointer, handing d3 the point and the wheel event. #124
  // fixed both arguments against a local proxy, and the corpus could not see
  // the branch: `wheel-pans-with-panonscroll` never holds Control.
  // `viewport/pan-on-scroll.ts` says why it moves the zoom activation key off
  // Control, without which this wheel would reach the zoom handler instead.
  //
  // Off-centre, because a zoom about the pane's centre and a zoom about the
  // pointer differ only when the two are apart: the viewport's translation is
  // what shows which point d3 scaled about. Over empty pane up and to the left,
  // so the wheel lands on the pane and not on a node. One notch up, which
  // zooms in by 2^0.2 off macOS and stays inside the default zoom limits.
  //
  // The viewport alone cannot say which handler ran, since d3's own wheel
  // handler also zooms about the pointer. What can is #124's bug: with its
  // fix reverted, this scenario put ps-flow at the centre-anchored
  // (-95.17, -53.53) with a null source event, against upstream's
  // (-50.56, -31.23) with the wheel event, so the wheel reaches the branch.
  {
    id: "ctrl-wheel-pinches-with-panonscroll",
    route: PAN_ON_SCROLL,
    probeCapabilities: ["viewport"],
    async run(a) {
      await a.key("Control", { action: "down" });
      await a.wheel(".react-flow__pane", { dx: -300, dy: -150, deltaY: -100 });
      await a.key("Control", { action: "up" });
    },
  },

  // A pane click on a flow whose elements are not selectable, with a node and
  // an edge the consumer passed in selected. Ticket #141, off #139.
  //
  // Upstream's `resetSelectedElements` returns early when `elementsSelectable`
  // is false, and ps-flow's reducer had no guard. The corpus could not see it:
  // `flow-props-change-after-mount` is the one scenario that turns the flag
  // off, and it never clicks the pane after the change.
  // `flow/not-selectable.ts` says why the class has a fixture of its own.
  //
  // Near the pane's top-left corner, which `fitView` leaves empty, so the
  // click lands on the pane and not on a node or an edge. With the guard
  // removed, ps-flow calls `onNodesChange` and `onEdgesChange` with a
  // deselection each, and the node and the edge render unselected.
  {
    id: "pane-click-keeps-selection-when-not-selectable",
    route: NOT_SELECTABLE,
    async run(a) {
      await a.click({ target: ".react-flow__pane", origin: "topLeft", dx: 40, dy: 40 });
    },
  },
];

export const holeClosingScenarios = holeClosing.map(defineScenario);
