// The test double for the page port.
//
// The vocabulary is a pure composition over the port — resolving a selector to
// a box, turning a box and an offset into coordinates, and deciding what to
// dispatch — and none of that needs a browser to be wrong. This is the seam
// where it is tested: canned boxes in, a list of what was sent out.
//
// It is a double for `port.mjs` and has to keep its shape; `port.test.mjs`
// checks the two agree on the method set rather than leaving that to a browser
// run to discover.

/** What a page with no flow on it and nothing scrolled answers. */
export const EMPTY_DOM = Object.freeze({
  page: Object.freeze({ scrollX: 0, scrollY: 0, visualViewportScale: 1 }),
  root: null,
});

/**
 * `dom` is what the page answers when asked for the `dom` section. Give it a
 * **list** to script a page that is still changing: each poll takes the next
 * entry and the last one repeats forever, which is what a page that eventually
 * settles looks like from up here.
 */
export const createFakePort = ({ boxes = {}, bridge = null, dom = EMPTY_DOM, callLog = null, observations = null } = {}) => {
  const sent = [];
  const snapshots = Array.isArray(dom) ? [...dom] : [dom];
  let ticks = 0;

  const port = {
    // The real port refuses to dispatch touch until this has been called, and
    // it has to be called before the page loads. The double has no page to
    // load, so it records the call for the ordering test and enforces nothing:
    // the precondition is a browser capability, and a scenario that forgets to
    // declare it fails loudly in the browser rather than silently anywhere.
    async enableTouch() {
      sent.push({ kind: "enableTouch" });
    },
    async box(selector) {
      return boxes[selector] ?? null;
    },
    async mouse(type, at) {
      sent.push({ kind: "mouse", type, ...at });
    },
    async keyboard(action, key) {
      sent.push({ kind: "keyboard", action, key });
    },
    async focus(selector) {
      sent.push({ kind: "focus", selector });
    },
    async wheel(at, deltas) {
      sent.push({ kind: "wheel", ...at, ...deltas });
    },
    async touch(type, points) {
      sent.push({ kind: "touch", type, points });
    },
    async call(method, args) {
      // The imperative bridge is not installed until the instance crosses
      // (#56). A port whose page has no bridge answers `installed: false`, and
      // the `call` primitive records that as an unresolved action.
      if (!bridge) return { installed: false, result: null };
      sent.push({ kind: "call", method, args });
      return { installed: true, result: bridge(method, args) };
    },
    // A page with a driver on it publishes a call log; `callLog` is what it
    // holds by the time the section is read. The default is a page whose log is
    // there, whose fixture driver wrapped its props, and which recorded nothing
    // — a scenario that drove nothing. The two failures, a page with no log and
    // a fixture driver that wrapped nothing, have to be asked for explicitly.
    async callbacks() {
      return callLog ?? { installed: true, entries: [], failures: [], observing: ["onNodesChange"] };
    },
    async observations() {
      return observations ?? { installed: true, hooks: {}, api: { queries: {} }, props: {}, failures: [] };
    },
    async dom() {
      // The last snapshot repeats: a page settles and then stays settled, and a
      // double that ran out of answers would fail as an undefined rather than
      // as whatever the test was actually about.
      return snapshots.length > 1 ? snapshots.shift() : snapshots[0];
    },

    // The real one yields to the page's frame loop. There is no page here, so
    // it counts the yield instead — and counts it apart from `sent`, which is
    // what was *dispatched*: a tick sends nothing, and a scenario that only
    // settled has driven nothing.
    async tick() {
      ticks++;
    },
  };

  return { port, sent, ticks: () => ticks };
};
