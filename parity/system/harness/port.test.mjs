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

test("the port is only ever the fourteen the harness above it uses", () => {
  assert.deepEqual(Object.keys(createPagePort({})).sort(), [
    "box",
    "call",
    "callbacks",
    "dom",
    "enableTouch",
    "finishMount",
    "focus",
    "keyboard",
    "mouse",
    "observations",
    "prepareMount",
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

// A resolved input command says the event was dispatched, not that the frame
// work it scheduled ran. The next action must not race that work. These are
// platform promises, not replacements for any part of the harness.
for (const action of ["press", "down", "up"]) {
  test(`keyboard ${action} completes after dispatch and the browser frame cycle`, async () => {
    const dispatch = Promise.withResolvers();
    const frame = Promise.withResolvers();
    const sent = [];
    let frames = 0;
    let completed = false;
    const port = createPagePort({
      keyboard: {
        [action]: (key) => {
          sent.push([action, key]);
          return dispatch.promise;
        },
      },
      evaluate: () => {
        frames++;
        return frame.promise;
      },
    });
    const done = port.keyboard(action, "Shift").then(() => { completed = true; });
    await new Promise(setImmediate);
    assert.deepEqual(sent, [[action, "Shift"]]);
    assert.equal(frames, 0, "the frame cycle follows the input dispatch");
    assert.equal(completed, false);

    dispatch.resolve();
    await new Promise(setImmediate);
    assert.equal(completed, false, "the next action waits for browser frame work");
    assert.equal(frames, 1);

    frame.resolve();
    await done;
    assert.equal(completed, true);
  });
}
