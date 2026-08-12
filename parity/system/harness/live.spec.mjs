// The harness against a real browser.
//
// Everything above the port is tested without one, against `fake-port.mjs`.
// That leaves exactly one claim untested: that the port's four dispatch paths
// reach a real renderer, and that a selector resolves to a box a real gesture
// can act on. A helper module shipped without ever having driven a page is the
// failure this repo names most often — a check that cannot see the thing it is
// checking — and the driving log would record a beautifully-shaped sequence of
// actions that did nothing at all.
//
// It asserts nothing about ps-flow against upstream. That is `parity:system`,
// which arrives with `dom` capture (#51).

import { test, expect } from "@playwright/test";
import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

import { defineScenario, runScenario } from "./scenario.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..", "..");

// The ps-flow side of this file runs off `dist/psflow.js`, which is committed —
// fixtures bundled in — so seven of these nine tests are meant to run on a clean
// clone, and the two that need the other side skip themselves below. Reading the
// vendored version at module load would undo all of that: an absent `xyflow/`
// would throw during collection and take the seven with it. README lists the
// scripts that hard-fail without the checkout and this is deliberately not one.
//
// A trace's `baseline` says which vendored upstream it was captured against, so
// with no checkout there is no honest version to name. These traces are the
// harness testing itself — never persisted, never compared, no parity claim —
// so the field is envelope-only here and says plainly that nothing was vendored.
const vendored = resolve(repoRoot, "xyflow/packages/react/package.json");
const baseline = existsSync(vendored) ? JSON.parse(readFileSync(vendored, "utf8")).version : "no-vendored-checkout";

const NODES_GENERAL = "/tests/generic/nodes/general";
const NODE = '.react-flow__node[data-id="Node-1"]';

const drive = (page, scenario, side = "psflow") => runScenario(page, scenario, { side, capture: 1, baseline });

const entriesOf = (trace, action) => trace.sections.driving.filter((e) => e.action === action);

test("a mount resolves the container, and the trace it produces is a valid trace", async ({ page }) => {
  const trace = await drive(
    page,
    defineScenario({ id: "live--mount-only", route: NODES_GENERAL, run: async () => {} })
  );

  const [mount] = trace.sections.driving;
  expect(mount.action).toBe("mount");
  expect(mount.resolved).toBe(true);
  expect(mount.box.width).toBeGreaterThan(0);
  expect(mount.box.height).toBeGreaterThan(0);
  expect(trace.sections.dom.page).toEqual({ scrollX: 0, scrollY: 0, visualViewportScale: 1 });
});

// The one claim the fake port cannot make: that a gesture composed of pointer
// primitives moves the thing it grabbed.
test("dragNode moves the node it grabbed, by the distance it was told", async ({ page }) => {
  const trace = await drive(
    page,
    defineScenario({
      id: "live--drag-node",
      route: NODES_GENERAL,
      run: (actions) => actions.dragNode(NODE, { dx: 100, dy: 40, steps: 4 }),
    })
  );

  const [press] = entriesOf(trace, "pointerDown");
  expect(press.resolved).toBe(true);

  const after = await page.locator(NODE).boundingBox();
  expect(after.x - press.box.x).toBeCloseTo(100, 0);
  expect(after.y - press.box.y).toBeCloseTo(40, 0);
});

test("an unresolved target is recorded and driving continues — never a timeout", async ({ page }) => {
  const trace = await drive(
    page,
    defineScenario({
      id: "live--unresolved-target",
      route: NODES_GENERAL,
      run: async (actions) => {
        await actions.pointerDown('.react-flow__node[data-id="no-such-node"]');
        await actions.pointerUp(null);
      },
    })
  );

  expect(trace.sections.driving.map((e) => [e.action, e.resolved])).toEqual([
    ["mount", true],
    ["pointerDown", false],
    ["pointerUp", true],
  ]);
});

test("a key reaches the page, and a targeted one focuses first", async ({ page }) => {
  await drive(
    page,
    defineScenario({
      id: "live--keyboard-focus",
      route: NODES_GENERAL,
      run: (actions) => actions.arrowKeyNudge("right", { target: NODE, times: 2 }),
    })
  );

  await expect(page.locator(NODE)).toBeFocused();
});

// Touch is the only primitive that does not go through Playwright's input API,
// and the only one with a precondition: `Input.dispatchTouchEvent` reaches a
// page reporting no touch support and is ignored there, so emulation has to be
// on *before the document loads*. Which scenarios pay for that is declared, so
// the rest of the corpus keeps measuring a browser without it.
test("a scenario that does not declare touch runs on a page without it", async ({ page }) => {
  await drive(page, defineScenario({ id: "live--no-touch", route: NODES_GENERAL, run: async () => {} }));

  expect(await page.evaluate(() => "ontouchstart" in window)).toBe(false);
});

test("declaring touch puts emulation on, and the pinch gesture completes", async ({ page }) => {
  const trace = await drive(
    page,
    defineScenario({
      id: "live--pinch",
      route: NODES_GENERAL,
      touch: true,
      run: (actions) => actions.pinch(".react-flow__pane", { spread: 60, scale: 2, steps: 3 }),
    })
  );

  expect(await page.evaluate(() => "ontouchstart" in window)).toBe(true);
  expect(entriesOf(trace, "touch").map((e) => [e.dispatched.type, e.resolved])).toEqual([
    ["touchStart", true],
    ["touchMove", true],
    ["touchMove", true],
    ["touchMove", true],
    ["touchEnd", true],
  ]);
});

test("reaching for touch without declaring it fails loudly rather than dispatching nothing", async ({ page }) => {
  await expect(
    drive(
      page,
      defineScenario({
        id: "live--undeclared-touch",
        route: NODES_GENERAL,
        run: (actions) => actions.touch("start", [{ target: NODE, id: 1 }]),
      })
    )
  ).rejects.toThrow(/touch: true/);
});

// That the events *arrive* is a claim about the port, and upstream is where it
// can be made: it is the reference implementation, so a touch drag that moves
// its node proves the dispatch path end to end.
//
// The same scenario moves nothing on the ps-flow side — measured, not assumed.
// That is a library divergence of exactly the kind the net exists to find, and
// asserting it either way here would be this file making a parity claim, which
// is not its job. It belongs on the divergence backlog (#22).
test("a touch drag moves upstream's node, which is what proves the events arrive", async ({ page }) => {
  test.skip(
    !existsSync(resolve(repoRoot, "parity/driver/dist/upstream.js")),
    "the upstream bundle is built beside a vendored xyflow/ and is not committed"
  );

  const trace = await drive(
    page,
    defineScenario({
      id: "live--touch-drag",
      route: NODES_GENERAL,
      touch: true,
      // Every point is resolved afresh, so a step's offset is from where its
      // target is *now* — two moves of 40 walk the node 80, not 40. That is
      // right for the gesture `touch` exists for, a pinch, which does not move
      // what it is over; a touch drag pays for it, and that is why the gesture
      // tier is open by addition rather than this being spelled out per
      // scenario.
      run: async (actions) => {
        await actions.touch("start", [{ target: NODE, id: 1 }]);
        await actions.touch("move", [{ target: NODE, dx: 40, dy: 20, id: 1 }]);
        await actions.touch("move", [{ target: NODE, dx: 40, dy: 20, id: 1 }]);
        await actions.touch("end", []);
      },
    }),
    "upstream"
  );

  const start = entriesOf(trace, "touch")[0].dispatched.points[0];
  const after = await page.locator(NODE).boundingBox();
  expect(after.x - start.box.x).toBeCloseTo(80, 0);
  expect(after.y - start.box.y).toBeCloseTo(40, 0);
});

// One driver, bundled twice, one scenario. This is the property the whole
// harness exists for; the *comparison* of the two traces is #51's.
test("the same scenario drives the upstream bundle through the same page", async ({ page }) => {
  test.skip(
    !existsSync(resolve(repoRoot, "parity/driver/dist/upstream.js")),
    "the upstream bundle is built beside a vendored xyflow/ and is not committed"
  );

  const scenario = defineScenario({
    id: "live--drag-node",
    route: NODES_GENERAL,
    run: (actions) => actions.dragNode(NODE, { dx: 100, dy: 40, steps: 4 }),
  });
  const trace = await drive(page, scenario, "upstream");

  expect(trace.side).toBe("upstream");
  expect(trace.sections.driving.map((e) => [e.action, e.resolved])).toEqual([
    ["mount", true],
    ["pointerDown", true],
    ["pointerMove", true],
    ["pointerMove", true],
    ["pointerMove", true],
    ["pointerMove", true],
    ["pointerUp", true],
  ]);
});
