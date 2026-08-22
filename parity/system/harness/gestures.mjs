// The gesture tier — the open half of the action vocabulary (#26, #35).
//
// A gesture is a *named composition of primitives*: written once and reused, so
// that no scenario re-encodes how a drag works. This tier is open by addition —
// adding one is a reviewable act — where the primitive tier below it is closed.
// That is the settlement of the question the observation ticket left open:
// keyboard input, selection boxes and viewport gestures are neither separate
// kinds nor bare compositions, they are **compositions promoted to named
// kinds**.
//
// Everything here goes through `primitives`, and nothing here touches the port,
// the driving log or the page. A gesture is therefore readable as the sequence
// of actions it produces, which is exactly what the driving log records and what
// coverage derivation reads.
//
// Scenarios reach for this tier by default, and drop to primitives only when
// the scenario is *about* an unusual input sequence — a gesture interrupted
// mid-flight, most often, which by construction no gesture can express.

export const GESTURES = ["click", "dragNode", "selectionBox", "connect", "pan", "pinch", "arrowKeyNudge"];

const ARROWS = { up: "ArrowUp", down: "ArrowDown", left: "ArrowLeft", right: "ArrowRight" };

const DEFAULT_PANE = ".react-flow__pane";

// Counts, all of which have to be at least one: zero steps is a press and a
// release with no gesture between them, and would record as one.
const atLeastOnce = (what, n) => {
  if (!Number.isInteger(n) || n < 1) throw new Error(`${what}, got ${JSON.stringify(n)}`);
  return n;
};

// A **point** is `{ target, dx, dy, origin }`, or a bare selector when the
// centre will do. The primitives take the target and the aim separately, so
// these two split one apart; passing the whole point as the options would leave
// a stray `target` key in it.
const targetOf = (point) => (typeof point === "string" ? point : point.target);
const aimOf = (point) => {
  if (typeof point === "string") return {};
  const { target, ...aim } = point;
  return aim;
};

export const createGestures = (primitives) => {
  // Press, walk, release. The walk is **pointer-relative**, because mid-drag the
  // thing being dragged follows the pointer — a target-relative move would chase
  // what it is dragging.
  //
  // Each step asks for the delta from where the pointer *actually is* to where
  // the walk intends it to be, rather than issuing `d / steps` repeatedly.
  // Accumulating a third of a pixel three times lands at 249.99999999999994
  // instead of 250, and `steps` is a harness knob: it may not move the endpoint,
  // least of all across a pixel boundary and into a different element. The
  // driving log has no tolerance applied to it either, so a step count would
  // otherwise be visible in a comparison as a fractional coordinate.
  const drag = async (from, { dx = 0, dy = 0, steps = 5 }) => {
    atLeastOnce("a drag needs at least one step", steps);

    const down = await primitives.pointerDown(targetOf(from), aimOf(from));
    const entries = [down];

    // Null when the press did not resolve. The walk then has no point to be
    // measured from, and falls back to even steps — a gesture whose press was
    // skipped is already recorded as a divergence, and where its moves land is
    // the consequence rather than the finding.
    const start = down.dispatched;
    let at = start;

    for (let i = 1; i <= steps; i++) {
      const step = at
        ? { dx: start.x + (dx * i) / steps - at.x, dy: start.y + (dy * i) / steps - at.y }
        : { dx: (dx * i) / steps - (dx * (i - 1)) / steps, dy: (dy * i) / steps - (dy * (i - 1)) / steps };
      const move = await primitives.pointerMove(null, step);
      entries.push(move);
      if (at) at = move.dispatched;
    }

    entries.push(await primitives.pointerUp(null));
    return entries;
  };

  return {
    /**
     * Press and release without moving — eleven of the conformance seed's
     * twenty-five scenarios open with one, since Playwright's own
     * `locator.click()` is exactly this.
     *
     * The release is **pointer-relative**, so the point is resolved once. An
     * element that moved out from under the press between the two is a
     * divergence worth seeing, and re-resolving would follow it there and
     * record a clean pair of actions instead.
     *
     * `modifier` is held across the press and released after it, the same shape
     * `selectionBox` gives Shift. It is `null` by default, where a selection
     * box's is not: a bare click is the common case and a modified one is the
     * exception, and upstream's own multi-selection specs press `s` rather than
     * Meta because that is what the fixtures set `multiSelectionKeyCode` to.
     */
    async click(point, { modifier = null } = {}) {
      const entries = [];
      if (modifier !== null) entries.push(await primitives.key(modifier, { action: "down" }));

      entries.push(await primitives.pointerDown(targetOf(point), aimOf(point)));
      entries.push(await primitives.pointerUp(null));

      if (modifier !== null) entries.push(await primitives.key(modifier, { action: "up" }));
      return entries;
    },

    /**
     * `dragNode('.react-flow__node[data-id="1"]', { dx: 100, dy: 40 })`.
     * `origin` and an initial `dx`/`dy` grab offset are not the same thing as
     * the drag distance, so the grab point is `{ target, dx, dy, origin }` when
     * a scenario needs one and a bare selector otherwise.
     */
    dragNode(target, options = {}) {
      return drag(target, options);
    },

    /**
     * `from` and `to` are `{ target, dx, dy, origin }` points, each resolved
     * against the side's own render. One move, not a walk: a selection box is
     * about where the pointer ends up, and interpolating between two
     * independently resolved points is not something the vocabulary can express
     * without inventing absolute coordinates.
     *
     * `modifier` defaults to Shift and is held across the drag; `null` draws the
     * box with no modifier at all, which is what a `selectionOnDrag` flow needs.
     */
    async selectionBox(from, to, { modifier = "Shift" } = {}) {
      const entries = [];
      if (modifier !== null) entries.push(await primitives.key(modifier, { action: "down" }));

      entries.push(await primitives.pointerDown(targetOf(from), aimOf(from)));
      entries.push(await primitives.pointerMove(targetOf(to), aimOf(to)));
      entries.push(await primitives.pointerUp(null));

      if (modifier !== null) entries.push(await primitives.key(modifier, { action: "up" }));
      return entries;
    },

    /**
     * Handle to handle. The release lands **on the target handle**, resolved
     * again at release time rather than assumed to be where the last move put
     * the pointer.
     *
     * `nudge` is a small move away from the press, which is what starts a
     * connection line in a browser. It is expressed target-relative rather than
     * pointer-relative so that setting it to `null` changes only whether the
     * move happens, never where the gesture lands — and it is added to the grab
     * offset rather than replacing it, so that a scenario grabbing a handle
     * off-centre still nudges by the distance it asked for. Overwriting would
     * make the nudge silently shrink as the grab offset grew: a source point of
     * `{ dx: 3 }` under a 5-pixel nudge would move the pointer 2.
     */
    async connect(source, target, { nudge = { dx: 5, dy: 5 } } = {}) {
      const aim = aimOf(source);
      const entries = [await primitives.pointerDown(targetOf(source), aim)];
      if (nudge !== null) {
        const nudged = { ...aim, dx: (aim.dx ?? 0) + (nudge.dx ?? 0), dy: (aim.dy ?? 0) + (nudge.dy ?? 0) };
        entries.push(await primitives.pointerMove(targetOf(source), nudged));
      }
      entries.push(await primitives.pointerMove(targetOf(target), aimOf(target)));
      entries.push(await primitives.pointerUp(targetOf(target), aimOf(target)));
      return entries;
    },

    /** Drags the pane. Same shape as `dragNode`, and deliberately so. */
    pan({ target = DEFAULT_PANE, ...options } = {}) {
      return drag(target, options);
    },

    /**
     * Two fingers, spreading from `spread` to `spread × scale` about the
     * target's centre. `scale` below one closes the pinch instead of opening it;
     * there is no second gesture for that.
     *
     * Every point is resolved against the target on every step, which is right
     * here in a way it would not be for a drag: a pinch does not move what it is
     * over, and a page that zooms under the fingers is the divergence being
     * looked for rather than something to chase.
     */
    async pinch(target, { spread = 40, scale = 2, steps = 4, origin = "center" } = {}) {
      atLeastOnce("a pinch needs at least one step", steps);

      const points = (at) => [
        { target, dx: -at, origin, id: 1 },
        { target, dx: at, origin, id: 2 },
      ];

      const entries = [await primitives.touch("start", points(spread))];
      for (let i = 1; i <= steps; i++) {
        entries.push(await primitives.touch("move", points(spread + (spread * scale - spread) * (i / steps))));
      }
      entries.push(await primitives.touch("end", []));
      return entries;
    },

    /**
     * `arrowKeyNudge('right', { target: '.react-flow__node[data-id="1"]' })`.
     * The target is focused on the **first** press only: focus persists, and
     * re-focusing between presses would put a DOM interaction in the middle of a
     * key repeat that a user's would not have.
     */
    async arrowKeyNudge(direction, { target = null, times = 1 } = {}) {
      const key = ARROWS[direction];
      if (!key) {
        throw new Error(`unknown direction ${JSON.stringify(direction)} — expected ${Object.keys(ARROWS).join(", ")}`);
      }
      atLeastOnce("a nudge presses at least once", times);

      const entries = [];
      for (let i = 0; i < times; i++) {
        entries.push(await primitives.key(key, { target: i === 0 ? target : null }));
      }
      return entries;
    },
  };
};
