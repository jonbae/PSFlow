// The primitive tier — the closed half of the action vocabulary (#26, #35).
//
// Seven primitives, and the set is **fixed**: extending it is a decision, not a
// scenario detail. Everything else a scenario does is a **gesture**, composed
// from these in `gestures.mjs`, which is open by addition. Closing the bottom
// tier is what makes a scenario's actions statically readable, which is what
// coverage derivation depends on.
//
// Each primitive does four things, in this order:
//
//   1. **Resolve its target against the page's own render.** Selector-relative,
//      never absolute coordinates: any `fitView` or layout divergence would
//      otherwise make one side miss the node entirely, turning a 2e-2 zoom gap
//      into a total-miss cascade across every scenario at once.
//   2. **Record the resolution in the driving log**, box and all.
//   3. **Dispatch**, through the port — the only thing here that knows what a
//      browser is.
//   4. **Return the entry it recorded**, and nothing else. Notably `call` does
//      not hand back the library's answer: the scenario is given the vocabulary
//      and never the side's identity, and a return value is the one remaining
//      aperture through which it could learn which implementation it is driving.
//
// A target that does not resolve is **recorded and skipped, never thrown**, and
// driving continues — downstream actions may fail to resolve too, and the trace
// keeps recording. A missing element is one of the most interesting divergences
// available; left alone it would surface as a Playwright timeout, which reads as
// a flake.

export const PRIMITIVES = ["pointerDown", "pointerMove", "pointerUp", "key", "wheel", "touch", "call"];

const ORIGINS = ["center", "topLeft"];
const KEY_ACTIONS = ["press", "down", "up"];
// The vocabulary says `start`; the trace records what the browser was actually
// asked for, which is CDP's own event name.
const TOUCH_PHASES = { start: "touchStart", move: "touchMove", end: "touchEnd", cancel: "touchCancel" };

const checkOrigin = (origin) => {
  if (!ORIGINS.includes(origin)) {
    throw new Error(`unknown origin ${JSON.stringify(origin)} — expected ${ORIGINS.join(" or ")}`);
  }
  return origin;
};

const anchor = (box, origin) =>
  checkOrigin(origin) === "topLeft"
    ? { x: box.x, y: box.y }
    : { x: box.x + box.width / 2, y: box.y + box.height / 2 };

/**
 * `log` is the driving log; `apiCalls` is the trace's `api.calls`, which a
 * mutator's return value lands in. Both belong to the harness, not to the
 * scenario, which never sees either.
 */
export const createPrimitives = (port, log, apiCalls = []) => {
  // Playwright's mouse starts at the origin, and so does this. It is tracked
  // here rather than in the port because a null-target move is defined
  // *relative to the last dispatched point* — including the one an unresolved
  // action never moved from.
  let pointer = { x: 0, y: 0 };

  // Resolves a target to the point an action would land on. Either
  // `{ ok: true, box, at }` or `{ ok: false, entry }` — the skip is recorded
  // here, so every caller's not-resolved branch is one line and cannot forget.
  const aim = async (action, target, { dx = 0, dy = 0, origin = "center" } = {}) => {
    checkOrigin(origin);

    if (target === null) {
      // Nothing to resolve: the offset is from wherever the pointer is. Not a
      // failure, so `resolved` stays true — `resolved: false` means a *named*
      // target was looked for and not found.
      return { ok: true, box: null, at: { x: pointer.x + dx, y: pointer.y + dy } };
    }

    const box = await port.box(target);
    if (!box) return { ok: false, entry: log.record({ action, target, resolved: false }) };

    const from = anchor(box, origin);
    return { ok: true, box, at: { x: from.x + dx, y: from.y + dy } };
  };

  const pointerAction = (action, type) => async (target = null, options = {}) => {
    const { button = "left" } = options;
    const aimed = await aim(action, target, options);
    if (!aimed.ok) return aimed.entry;

    const dispatched = type === "move" ? { ...aimed.at } : { ...aimed.at, button };
    const entry = log.record({ action, target, resolved: true, box: aimed.box, dispatched });
    pointer = aimed.at;
    await port.mouse(type, dispatched);
    return entry;
  };

  const primitives = {
    pointerDown: pointerAction("pointerDown", "down"),
    pointerMove: pointerAction("pointerMove", "move"),
    pointerUp: pointerAction("pointerUp", "up"),

    /**
     * `action` is `press` (the default), `down` or `up` — the last two are how
     * a modifier is held across a gesture. A `target` focuses that element
     * first, and records the box it focused, which is what makes keyboard
     * scenarios comparable at all.
     */
    async key(key, options = {}) {
      const { action = "press", target = null } = options;
      if (!KEY_ACTIONS.includes(action)) {
        throw new Error(`unknown key action ${JSON.stringify(action)} — expected ${KEY_ACTIONS.join(", ")}`);
      }

      const aimed = await aim("key", target, options);
      if (!aimed.ok) return aimed.entry;

      const entry = log.record({ action: "key", target, resolved: true, box: aimed.box, dispatched: { key, action } });
      if (target !== null) await port.focus(target);
      await port.keyboard(action, key);
      return entry;
    },

    /**
     * Dispatched over the target's box, because what a wheel does depends
     * entirely on what is under the pointer — `nowheel` is a class of behaviour
     * whose only observable is a browser default *not* happening.
     */
    async wheel(target = null, options = {}) {
      const { deltaX = 0, deltaY = 0 } = options;
      const aimed = await aim("wheel", target, options);
      if (!aimed.ok) return aimed.entry;

      const dispatched = { ...aimed.at, deltaX, deltaY };
      const entry = log.record({ action: "wheel", target, resolved: true, box: aimed.box, dispatched });
      pointer = aimed.at;
      await port.wheel(aimed.at, { deltaX, deltaY });
      return entry;
    },

    /**
     * Multi-point by construction, since the gesture it exists for is a pinch.
     * Every point names a target — there is no pointer-like cursor to offset
     * from, so a point without one has no base at all.
     *
     * Consequently **every point is resolved afresh on every call**: an offset
     * is from where its target is *now*, not from where the gesture started.
     * That is right for a pinch, which does not move what it is over, and it is
     * a trap for a touch drag, where two moves of 40 walk the target 80.
     *
     * The entry's `target` is the points' selectors as a list (which is a valid
     * selector in its own right) and its `box` is null: one box could not stand
     * for several. Each point's own resolution rides in `dispatched`, where the
     * self-consistency check still sees it.
     */
    async touch(phase, points = []) {
      const type = TOUCH_PHASES[phase];
      if (!type) {
        throw new Error(
          `unknown touch phase ${JSON.stringify(phase)} — expected ${Object.keys(TOUCH_PHASES).join(", ")}`
        );
      }

      const targets = points.map((point) => {
        if (typeof point.target !== "string" || point.target === "") {
          throw new Error(`touch ${phase}: every point names a target — there is nothing else to offset from`);
        }
        return point.target;
      });
      const target = targets.length ? targets.join(", ") : null;

      const resolvedPoints = [];
      for (const [i, point] of points.entries()) {
        const box = await port.box(point.target);
        // One point short is not a partial touch: a two-finger pinch missing a
        // finger is a different gesture, so the whole action is skipped.
        if (!box) return log.record({ action: "touch", target, resolved: false });
        const from = anchor(box, point.origin ?? "center");
        resolvedPoints.push({
          target: point.target,
          box,
          x: from.x + (point.dx ?? 0),
          y: from.y + (point.dy ?? 0),
          id: point.id ?? i + 1,
        });
      }

      const entry = log.record({
        action: "touch",
        target,
        resolved: true,
        box: null,
        dispatched: { type, points: resolvedPoints },
      });
      await port.touch(
        type,
        resolvedPoints.map(({ x, y, id }) => ({ x, y, id }))
      );
      return entry;
    },

    /**
     * The imperative half: a query or a mutator on the flow instance, reached
     * through the page's bridge. The bridge does not exist until the instance
     * crosses (boundary stage 3, #56), and a page without one is a page that
     * cannot answer — which is the same thing as a target that did not resolve,
     * and recorded the same way rather than thrown.
     */
    async call(method, args = []) {
      const { installed, result } = await port.call(method, args);
      if (!installed) return log.record({ action: "call", target: null, resolved: false });

      apiCalls.push({ method, args, result });
      return log.record({ action: "call", target: null, resolved: true, box: null, dispatched: { method, args } });
    },
  };

  return primitives;
};
