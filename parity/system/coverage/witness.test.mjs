import { test } from "node:test";
import assert from "node:assert/strict";

import { compileSelector, compileWitness, holdsInDom, namesIn } from "./witness.mjs";

const element = (over = {}) => ({ tag: "div", attrs: {}, children: [], ...over });

test("a class selector matches an element carrying that class token", () => {
  const matches = compileSelector(".react-flow__minimap");

  assert.equal(matches(element({ attrs: { class: "react-flow__minimap" } })), true);
  assert.equal(matches(element({ attrs: { class: "react-flow__panel react-flow__minimap" } })), true);
  assert.equal(matches(element({ attrs: { class: "react-flow__minimap-mask" } })), false);
  assert.equal(matches(element()), false);
});

test("a compound selector asks about the tag and every attribute at once", () => {
  const matches = compileSelector("path.react-flow__edge-path[marker-end*=url(#]");
  const path = (attrs) => element({ tag: "path", attrs });

  assert.equal(matches(path({ class: "react-flow__edge-path", "marker-end": "url(#arrow)" })), true);
  assert.equal(matches(path({ class: "react-flow__edge-path" })), false, "no marker-end");
  assert.equal(matches(path({ class: "react-flow__edge-path", "marker-end": "none" })), false);
  assert.equal(
    matches(element({ tag: "g", attrs: { class: "react-flow__edge-path", "marker-end": "url(#arrow)" } })),
    false,
    "wrong tag"
  );
});

test("attribute presence, exact, token and substring are four different questions", () => {
  const el = element({ attrs: { "data-id": "Node-1", class: "react-flow__node react-flow__node-input" } });

  assert.equal(compileSelector("[data-id]")(el), true);
  assert.equal(compileSelector("[data-id=Node-1]")(el), true);
  assert.equal(compileSelector("[data-id=Node-2]")(el), false);
  assert.equal(compileSelector("[class~=react-flow__node]")(el), true);
  assert.equal(compileSelector("[class~=react-flow__nod]")(el), false, "a token is not a prefix");
  assert.equal(compileSelector("[class*=react-flow__nod]")(el), true);
});

test("a selector the language cannot express fails rather than matching nothing", () => {
  // The failure mode this rules out: a witness that quietly matches nothing
  // reads as an undriven export, and the export then wants a hole declared for
  // a reason that is not true.
  assert.throws(() => compileSelector(".react-flow__node > .react-flow__handle"), /not a witness selector/);
  assert.throws(() => compileSelector(""), /needs a selector/);
});

test("a dom witness searches the whole recorded subtree, root included", () => {
  const dom = {
    page: { scrollX: 0, scrollY: 0, visualViewportScale: 1 },
    root: element({
      attrs: { class: "react-flow" },
      children: [element({ attrs: { class: "react-flow__viewport" }, children: [element({ tag: "svg" })] })],
    }),
  };

  assert.equal(holdsInDom(dom, compileSelector(".react-flow")), true, "the root counts");
  assert.equal(holdsInDom(dom, compileSelector("svg")), true, "and so does a grandchild");
  assert.equal(holdsInDom(dom, compileSelector(".react-flow__minimap")), false);
});

test("a side that rendered no flow at all witnesses nothing", () => {
  // `root: null` is what a capture records when the selector does not resolve.
  // It is a finding the comparison reads; here it must simply witness nothing
  // rather than throw, or one failed capture would take the artifact down.
  assert.equal(holdsInDom({ page: {}, root: null }, compileSelector(".react-flow")), false);
});

test("the callbacks section offers a handler's name, and its changes' discriminants", () => {
  const names = namesIn("callbacks", [
    { name: "onNodeClick", args: [{ "@class": "MouseEvent" }, { id: "Node-1", type: "input" }] },
    { name: "onNodesChange", args: [[{ id: "Node-1", type: "position" }, { id: "Node-2", type: "select" }]] },
  ]);

  assert.equal(names.has("onNodeClick"), true);
  assert.equal(names.has("onNodesChange"), true);
  assert.equal(names.has("onNodesChange:position"), true, "a change union member is named by its discriminant");
  assert.equal(names.has("onNodesChange:select"), true);
  assert.equal(names.has("onNodesChange:add"), false, "and nothing names one that did not fire");
});

test("the api section offers its query keys and the names of the calls that were made", () => {
  const names = namesIn("api", { queries: { getNodes: [] }, calls: [{ name: "fitView", args: [], returned: true }] });

  assert.deepEqual([...names].sort(), ["fitView", "getNodes"]);
});

test("hooks and props are offered by probe id and by what the probe reported", () => {
  const names = namesIn("hooks", { "node-probe": { useNodeId: "Node-1", useViewport: { x: 0, y: 0, zoom: 1 } } });

  assert.deepEqual([...names].sort(), ["node-probe", "useNodeId", "useViewport"]);
});

test("an empty section offers nothing, which is what makes its exports holes", () => {
  // The three probe-fed sections are empty until #59 builds the probes, and
  // every export landing in them is a declared hole until then. That has to
  // read as "nothing was recorded", never as an error.
  assert.equal(namesIn("hooks", {}).size, 0);
  assert.equal(namesIn("api", { queries: {}, calls: [] }).size, 0);
  assert.equal(namesIn("callbacks", []).size, 0);
});

test("a compiled witness answers one question: did this trace's sections hold it?", () => {
  const minimap = compileWitness({ export: "MiniMap", selector: ".react-flow__minimap" }, "dom");
  const drag = compileWitness({ export: "OnNodeDrag", names: ["onNodeDrag", "onNodeDragStart"] }, "callbacks");

  const sections = {
    dom: { page: {}, root: { tag: "div", attrs: { class: "react-flow__minimap" }, children: [] } },
    callbacks: [{ name: "onNodeDragStart", args: [] }],
  };

  assert.equal(minimap.holdsIn(sections), true);
  assert.equal(drag.holdsIn(sections), true, "any one name of a many-to-one mapping is enough");
  assert.equal(compileWitness({ export: "OnConnect", names: ["onConnect"] }, "callbacks").holdsIn(sections), false);
});

test("a witness whose kind does not suit its section is a mis-edit, not a finding", () => {
  // `dom` is witnessed by a selector and the other four by names, and which
  // one an export takes is decided by the census. A register that says
  // otherwise is describing a trace shape that does not exist.
  assert.throws(() => compileWitness({ export: "MiniMap", names: ["minimap"] }, "dom"), /needs a selector/);
  assert.throws(
    () => compileWitness({ export: "OnConnect", selector: ".react-flow__connection" }, "callbacks"),
    /needs a name mapping/
  );
});

test("a witness that names nothing is refused, because it could never witness anything", () => {
  assert.throws(() => compileWitness({ export: "OnConnect", names: [] }, "callbacks"), /needs a name mapping/);
});

test("a descendant chain asks about content inside a container, not the container", () => {
  // The case that forced the combinator into the language: `.react-flow__viewport-portal`
  // and `.react-flow__edgelabel-renderer` are rendered by the renderer whether
  // or not anything is portaled into them, so a selector on the container
  // witnesses `ViewportPortal` for every fixture that mounts a flow at all.
  const portal = (children) => ({
    tag: "div",
    attrs: { class: "react-flow__viewport-portal" },
    children,
  });
  const matches = compileSelector(".react-flow__viewport-portal *");

  assert.equal(matches(portal([])), false, "an empty container is nobody using the export");
  assert.equal(matches(portal([{ tag: "span", attrs: {}, children: [] }])), true);
  assert.equal(
    matches(portal([{ tag: "div", attrs: {}, children: [{ tag: "span", attrs: {}, children: [] }] }])),
    true,
    "and a descendant is a descendant however deep"
  );
});

test("a chain matches across generations, not only parent and child", () => {
  const tree = {
    tag: "div",
    attrs: { class: "react-flow__controls" },
    children: [
      { tag: "div", attrs: {}, children: [{ tag: "button", attrs: { class: "react-flow__controls-button" }, children: [] }] },
    ],
  };

  assert.equal(compileSelector(".react-flow__controls button.react-flow__controls-button")(tree), true);
  assert.equal(compileSelector(".react-flow__minimap button")(tree), false);
});
