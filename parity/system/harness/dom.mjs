// The `dom` section — the subtree under `.react-flow`, plus page-level state (#51).
//
// The richest section the net has: 64 of the trace's 156 exports land here, and
// for a mount-only scenario it is very nearly the whole observation. It is also
// what makes the net's two halves a gate at all — two traces whose `dom` is
// `null` on both sides compare clean and mean nothing.
//
// This module runs **in the page**, like `serialize.mjs` and for the same
// reason: it reads live DOM nodes, so it has to be where they are. Playwright
// hands `page.evaluate` a function by its *source*, which is the constraint
// that shapes the file — `domSection` closes over nothing, imports nothing and
// defines everything it needs inside itself. A helper lifted to module scope
// would serialize into a `ReferenceError` in the page.
//
// It is still a plain function over duck-typed nodes, so `dom.test.mjs` calls
// it in node against a hand-built document. That is the seam the rest of the
// harness is tested at: everything except what only a browser can answer.
//
// **Capture records; it does not decide.** Every attribute is kept, values as
// strings, and whitespace inside a text node is content like any other. What is
// noise is `normalization.json`'s to say — downstream, where a revised policy
// re-diffs every trace ever captured instead of needing a second browser run.

/**
 * The whole `dom` section, in the shape the trace format carries:
 * `{ page: { scrollX, scrollY, visualViewportScale }, root: element | null }`,
 * where an element is `{ tag, attrs, text?, children }`.
 *
 * `root` is null when the selector does not resolve. A side that never rendered
 * a flow is a finding the comparison can read, not a capture that threw.
 *
 * **Runs in the page.** Everything it uses is defined inside it.
 */
export const domSection = (selector) => {
  const ELEMENT_NODE = 1;
  const TEXT_NODE = 3;

  const element = (el) => {
    // Every attribute, never a chosen few: a whitelist would be a hand-authored
    // reading of what xyflow renders, and an attribute nobody thought to ask for
    // is one that can differ forever.
    const attrs = {};
    for (const attr of el.attributes) attrs[attr.name] = attr.value;

    // `localName` rather than a lowercased `tagName`, so SVG keeps its casing:
    // `linearGradient` is not `lineargradient`, and a capture that flattened the
    // two would be deciding something.
    const snapshot = { tag: el.localName, attrs };

    // This element's *own* text: its direct text-node children, concatenated in
    // order. Absent when it has none — which is a different observation from
    // having an empty one.
    let text = null;
    for (const child of el.childNodes) {
      if (child.nodeType === TEXT_NODE) text = (text ?? "") + child.nodeValue;
    }
    if (text !== null) snapshot.text = text;

    const children = [];
    for (const child of el.childNodes) {
      if (child.nodeType === ELEMENT_NODE) children.push(element(child));
    }
    snapshot.children = children;
    return snapshot;
  };

  const root = document.querySelector(selector);

  return {
    // Enumerated rather than open: two upstream behaviours turn on a browser
    // default — a scroll, a pinch-zoom — *not* happening, and the page is the
    // only place that is observable. An open bag would also carry whatever the
    // browser started reporting between two baselines.
    page: {
      scrollX: window.scrollX,
      scrollY: window.scrollY,
      visualViewportScale: window.visualViewport?.scale ?? 1,
    },
    root: root ? element(root) : null,
  };
};
