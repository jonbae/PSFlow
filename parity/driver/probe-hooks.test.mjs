import { test } from "node:test";
import assert from "node:assert/strict";

import { selectProbeHooks } from "./probe-hooks.mjs";

test("a flow variant installs only its selected callback hook without dropping ordinary hooks", () => {
  const names = ["useEdges", "useOnSelectionChange", "useOnViewportChange", "useViewport"];

  assert.deepEqual(selectProbeHooks(names, "useOnSelectionChange"), [
    "useEdges",
    "useOnSelectionChange",
    "useViewport",
  ]);
  assert.deepEqual(selectProbeHooks(names, "useOnViewportChange"), [
    "useEdges",
    "useOnViewportChange",
    "useViewport",
  ]);
});

test("a flow variant with no callback experiment installs no callback hooks", () => {
  assert.deepEqual(selectProbeHooks(["useEdges", "useOnSelectionChange", "useOnViewportChange"], null), ["useEdges"]);
});
