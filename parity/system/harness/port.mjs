// The page port — the only file in the harness that knows what a browser is.
//
// Everything above it (the vocabulary, the gestures, the driving log) is plain
// composition over this interface, which is why all of it is tested without a
// browser against `fake-port.mjs`. Keep the two in step: `port.test.mjs` checks
// they still answer the same method names, so a double that drifts is caught
// by a node test rather than by a browser run failing strangely.
//
// The port resolves and dispatches. It decides nothing: what to aim at, what to
// record, and whether a miss is a failure all belong upstairs.

import { domSection } from "./dom.mjs";

const CDP_TOUCH = { touchStart: 1, touchMove: 1, touchEnd: 1, touchCancel: 1 };

/**
 * `resolveTimeout` bounds how long a selector is given before it counts as
 * unresolved. It exists because an element that appears a moment after the
 * action asks for it is not a divergence, and an element that never appears
 * must not cost the whole run: past this, the miss is **recorded and skipped**
 * by the vocabulary above, never thrown. Left alone, that miss would surface as
 * a Playwright timeout, which reads as a flake.
 */
export const createPagePort = (page, { resolveTimeout = 1_000 } = {}) => {
  // Where the mouse actually is, so that a press does not emit a redundant
  // mousemove first. An explicit `pointerMove` always dispatches — a scenario
  // asking for a move is asking for the event, even a zero-length one.
  let at = { x: 0, y: 0 };

  // `Input.dispatchTouchEvent` reaches a page reporting no touch support and is
  // ignored there, so emulation has to be on — and it has to be on **before the
  // document loads**. Turning it on afterwards leaves `ontouchstart in window`
  // false and every dispatched touch inert, which was measured rather than
  // assumed: the same touch drag that moves a node with emulation enabled
  // before `goto` moves nothing when it is enabled after.
  //
  // So it is a scenario's declared capability, not something a `touch` call can
  // turn on for itself. Enabling it everywhere would be symmetric across the
  // sides and therefore sound, but it would quietly narrow the whole net to a
  // touch-capable browser — every scenario taking xyflow's touch code paths
  // because two scenarios needed them.
  //
  // The CDP session is what the corpus ticket bought by specifying
  // `Input.dispatchTouchEvent`: no new browser target, no second Playwright
  // project, no config change.
  let cdp = null;

  const moveTo = async ({ x, y }) => {
    await page.mouse.move(x, y);
    at = { x, y };
  };

  return {
    /**
     * Turns on touch emulation, and must be called **before the page is
     * navigated**. `runScenario` does it for a scenario declaring `touch: true`.
     */
    async enableTouch() {
      cdp ??= await page.context().newCDPSession(page);
      await cdp.send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 10 });
    },

    /**
     * The box, or null when the selector does not resolve. Never throws.
     * `timeout` overrides the default for the one case that is not an action —
     * the mount, which waits on a bundle downloading and a flow rendering.
     */
    async box(selector, { timeout = resolveTimeout } = {}) {
      try {
        // `.first()`: a selector matching several elements resolves to one, the
        // same one on both sides, rather than being a strict-mode error that
        // would read as an infrastructure fault instead of a target choice.
        return await page.locator(selector).first().boundingBox({ timeout });
      } catch {
        // Not attached, not visible, or gone before it could be measured. All
        // three are "did not resolve", and the difference between them is not
        // something the driving log claims to record.
        return null;
      }
    },

    async mouse(type, { x, y, button = "left" }) {
      if (type === "move") return moveTo({ x, y });
      if (x !== at.x || y !== at.y) await moveTo({ x, y });
      if (type === "down") return page.mouse.down({ button });
      if (type === "up") return page.mouse.up({ button });
      throw new Error(`unknown mouse action ${JSON.stringify(type)}`);
    },

    async keyboard(action, key) {
      if (action === "press") return page.keyboard.press(key);
      if (action === "down") return page.keyboard.down(key);
      if (action === "up") return page.keyboard.up(key);
      throw new Error(`unknown key action ${JSON.stringify(action)}`);
    },

    async focus(selector) {
      await page.locator(selector).first().focus({ timeout: resolveTimeout });
    },

    async wheel(point, { deltaX, deltaY }) {
      if (point.x !== at.x || point.y !== at.y) await moveTo(point);
      await page.mouse.wheel(deltaX, deltaY);
    },

    async touch(type, points) {
      if (!CDP_TOUCH[type]) throw new Error(`unknown touch event ${JSON.stringify(type)}`);
      // Loud, because the alternative is silent: an inert touch dispatches
      // without error and produces a driving log full of perfectly-shaped
      // actions that did nothing, on both sides, comparing clean.
      if (!cdp) {
        throw new Error(
          `this scenario dispatches touch without declaring \`touch: true\`. Emulation has to be ` +
            `on before the document loads, so it cannot be turned on now — the events would be ` +
            `accepted and ignored.`
        );
      }
      await cdp.send("Input.dispatchTouchEvent", {
        type,
        touchPoints: points.map(({ x, y, id }) => ({ x, y, id })),
      });
    },

    /**
     * The imperative bridge. `window.__psflowNet` is installed by the driver
     * page and hands the flow instance to the harness; it does not exist yet,
     * because the instance does not cross the boundary until stage 3 (#56).
     * A page without one answers `installed: false`, which the `call` primitive
     * records as an unresolved action rather than throwing — the same treatment
     * a missing element gets, for the same reason.
     */
    async call(method, args) {
      return page.evaluate(
        ([m, a]) => {
          const bridge = window.__psflowNet;
          if (!bridge || typeof bridge.call !== "function") return { installed: false, result: null };
          return { installed: true, result: bridge.call(m, a) };
        },
        [method, args]
      );
    },

    /**
     * The `dom` section — the subtree under `selector`, plus page-level state.
     * What it records is `dom.mjs`'s, which runs *in* the page; this is only
     * the door it goes through.
     */
    async dom(selector) {
      return page.evaluate(domSection, selector);
    },

    /**
     * Yields until the page's own frame loop has come round — which is what
     * `settle.mjs` puts between two polls.
     *
     * Two frames and then a turn of the task queue, in that order, because that
     * is the order the work lands in: a rendering frame runs its animation
     * callbacks, lays out, and *then* runs the resize observers that xyflow
     * measures nodes with, so the second frame is the first one that can see
     * what the first one caused. The trailing `setTimeout` is a yield to the
     * task queue rather than a wait — zero delay, and what it collects is the
     * continuation a `then` or a timer scheduled during those frames.
     *
     * None of that is a duration. Waiting a fixed number of milliseconds is a
     * bet that neither implementation is slower than the number, and the harness
     * makes no such bet: each side settles when it has stopped changing, on its
     * own clock.
     */
    async tick() {
      await page.evaluate(
        () =>
          new Promise((resolve) => {
            requestAnimationFrame(() => requestAnimationFrame(() => setTimeout(resolve, 0)));
          })
      );
    },
  };
};
