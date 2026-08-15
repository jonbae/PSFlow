import { test } from "node:test";
import assert from "node:assert/strict";

import { createFakePort } from "./fake-port.mjs";
import { createPagePort } from "./port.mjs";

// The vocabulary is tested entirely against the double, so the double drifting
// away from the real port would take every one of those tests with it — green
// against an interface nothing implements. This is the one check that holds
// them together, and it is a node test rather than something a browser run
// eventually fails at strangely.
//
// `createPagePort` touches nothing at construction — the CDP session is opened
// on the first touch — so a stub with no methods is enough to build one.
test("the real port and its double answer the same methods", () => {
  const real = createPagePort({});
  const { port: fake } = createFakePort();

  assert.deepEqual(Object.keys(real).sort(), Object.keys(fake).sort());
});

test("the port is only ever the ten the harness above it uses", () => {
  assert.deepEqual(Object.keys(createPagePort({})).sort(), [
    "box",
    "call",
    "dom",
    "enableTouch",
    "focus",
    "keyboard",
    "mouse",
    "tick",
    "touch",
    "wheel",
  ]);
});

// Emulation applied after the document has loaded leaves every dispatched touch
// inert — accepted and ignored. A scenario that reaches for touch without
// declaring it must therefore fail rather than record a beautifully-shaped
// sequence of actions that did nothing.
test("the real port refuses to dispatch touch before emulation is on", async () => {
  const port = createPagePort({});

  await assert.rejects(() => port.touch("touchStart", [{ x: 1, y: 2, id: 1 }]), /touch: true/);
});
