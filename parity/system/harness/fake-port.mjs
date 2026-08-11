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

export const createFakePort = ({ boxes = {}, bridge = null, page: pageState = null } = {}) => {
  const sent = [];

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
    async pageState() {
      return pageState ?? { scrollX: 0, scrollY: 0, visualViewportScale: 1 };
    },
  };

  return { port, sent };
};
