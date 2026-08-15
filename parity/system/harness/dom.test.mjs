import { test } from "node:test";
import assert from "node:assert/strict";
import vm from "node:vm";

import { domSection } from "./dom.mjs";

// Every test here runs `domSection` **the way the page does**: Playwright hands
// `page.evaluate` the function's source, so the page compiles that text in a
// scope holding nothing but its own globals. `vm` is that scope. A helper
// lifted to module scope — or an import, or a shared constant — would arrive
// there as a `ReferenceError`, and nothing short of a browser run would
// otherwise notice, and then only as a capture that failed strangely.
//
// What is left is a plain function over duck-typed nodes, which is why the rest
// of these are questions about what capture keeps rather than about a browser.
// The JSON round trip is Playwright's too — an `evaluate` result crosses back
// as data, not as objects — and it is what brings the vm's values into this
// realm so `deepEqual` compares contents rather than prototypes.
const evaluate = (document, window, selector) =>
  JSON.parse(
    JSON.stringify(vm.runInContext(`(${domSection.toString()})`, vm.createContext({ document, window }))(selector))
  );

const el = (tag, attrs = {}, children = []) => ({
  localName: tag,
  attributes: Object.entries(attrs).map(([name, value]) => ({ name, value })),
  childNodes: children,
  nodeType: 1,
});

const text = (value) => ({ nodeType: 3, nodeValue: value });

const ROOT = ".react-flow";

const inPage = (root, page = {}, selector = ROOT) =>
  evaluate(
    { querySelector: (s) => (s === ROOT ? root : null) },
    { scrollX: 0, scrollY: 0, visualViewport: { scale: 1 }, ...page },
    selector
  );

test("an element becomes tag, every attribute, and its children", () => {
  const root = el("div", { class: "react-flow", "data-id": "flow" }, [
    el("div", { class: "react-flow__pane" }, [el("div", { class: "react-flow__node", "data-id": "Node-1" })]),
  ]);

  assert.deepEqual(inPage(root).root, {
    tag: "div",
    attrs: { class: "react-flow", "data-id": "flow" },
    children: [
      {
        tag: "div",
        attrs: { class: "react-flow__pane" },
        children: [{ tag: "div", attrs: { class: "react-flow__node", "data-id": "Node-1" }, children: [] }],
      },
    ],
  });
});

// A whitelist of interesting attributes would be a hand-authored reading of
// what xyflow renders, and two of the spike's findings were `aria-describedby`
// and a `data-id` composed differently — attributes nobody would have listed.
test("nothing is filtered: an attribute nobody would think to ask for is still recorded", () => {
  const root = el("div", { "aria-describedby": "react-flow__node-desc-1", tabindex: "0", style: "" });

  assert.deepEqual(inPage(root).root.attrs, {
    "aria-describedby": "react-flow__node-desc-1",
    tabindex: "0",
    style: "",
  });
});

test("an element's own text is its direct text nodes, concatenated in order", () => {
  const captured = inPage(el("div", {}, [text("Node "), el("span", {}, [text("inner")]), text("1")])).root;

  assert.equal(captured.text, "Node 1");
  assert.equal(captured.children[0].text, "inner");
});

// Whitespace is content: collapsing it here would be the noise policy deciding
// something *inside* capture, where no revision downstream could take it back.
test("text is recorded verbatim, whitespace included", () => {
  assert.equal(inPage(el("div", {}, [text("  two  spaces\n")])).root.text, "  two  spaces\n");
});

test("an element with no text node has no text field at all", () => {
  const captured = inPage(el("div", {}, [el("span")])).root;

  assert.ok(!("text" in captured));
  assert.ok(!("text" in captured.children[0]));
});

// An empty text node and no text node are two different renders, and a capture
// reporting both as "no text" would put them under one value.
test("an empty text node is not the same observation as no text node", () => {
  assert.equal(inPage(el("div", {}, [text("")])).root.text, "");
});

test("only element children become children, and a comment is not one", () => {
  const root = el("div", {}, [{ nodeType: 8, nodeValue: " a comment " }, text("x"), el("span")]);

  assert.deepEqual(
    inPage(root).root.children.map((c) => c.tag),
    ["span"]
  );
});

test("SVG keeps its casing, because localName is not a lowercased tagName", () => {
  assert.equal(inPage(el("linearGradient")).root.tag, "linearGradient");
});

// Two upstream behaviours turn on a browser default *not* happening — a scroll
// and a pinch-zoom — and the page is the only place either is observable.
test("page-level state is enumerated, and a browser without a visual viewport still answers", () => {
  assert.deepEqual(inPage(el("div"), { scrollX: 12, scrollY: 40, visualViewport: { scale: 2 } }).page, {
    scrollX: 12,
    scrollY: 40,
    visualViewportScale: 2,
  });
  assert.equal(inPage(el("div"), { visualViewport: undefined }).page.visualViewportScale, 1);
});

// A side that never rendered a flow is a finding the comparison reads, not a
// capture that threw. The page state is still recorded — it is the half of the
// section that does not depend on the flow existing.
test("a selector that does not resolve gives a null root and still records the page", () => {
  const captured = inPage(el("div"), {}, ".no-such-thing");

  assert.equal(captured.root, null);
  assert.deepEqual(captured.page, { scrollX: 0, scrollY: 0, visualViewportScale: 1 });
});
