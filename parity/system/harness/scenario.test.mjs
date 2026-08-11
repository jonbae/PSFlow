import { test } from "node:test";
import assert from "node:assert/strict";

import { validateTrace } from "../trace-format.mjs";
import { createFakePort } from "./fake-port.mjs";
import { VOCABULARY } from "./vocabulary.mjs";
import { ScenarioError, defineScenario, driverUrl, runScenario } from "./scenario.mjs";

const FLOW = { x: 0, y: 0, width: 800, height: 600 };
const NODE = { x: 75, y: 25, width: 150, height: 36 };

// Only `on`, `off` and `goto` are reached directly; everything else is the
// port, which is the whole point of there being a port.
const fakePage = () => {
  const listeners = new Map();
  const visited = [];
  return {
    visited,
    emit(event, payload) {
      for (const listener of listeners.get(event) ?? []) listener(payload);
    },
    on(event, listener) {
      if (!listeners.has(event)) listeners.set(event, new Set());
      listeners.get(event).add(listener);
    },
    off(event, listener) {
      listeners.get(event)?.delete(listener);
    },
    async goto(url) {
      visited.push(url);
    },
    listenerCount: (event) => listeners.get(event)?.size ?? 0,
  };
};

const scenario = (run = async () => {}) =>
  defineScenario({ id: "mount-baseline--nodes-general", route: "/tests/generic/nodes/general", run });

const capture = async (run, { boxes = { ".react-flow": FLOW, ".node": NODE }, ...options } = {}) => {
  const page = fakePage();
  const { port, sent } = createFakePort({ boxes });
  const trace = await runScenario(page, scenario(run), {
    side: "psflow",
    capture: 1,
    baseline: "12.11.0",
    port,
    ...options,
  });
  return { trace, page, sent };
};

test("a scenario id is semantic, never a sequence number", () => {
  assert.equal(defineScenario({ id: "drag-node-release", route: "/x", run() {} }).id, "drag-node-release");
  assert.equal(defineScenario({ id: "mount-baseline--nodes-general", route: "/x", run() {} }).id, "mount-baseline--nodes-general");

  for (const id of ["S7", "s7", "12", "Drag_Node", "drag node", ""]) {
    assert.throws(() => defineScenario({ id, route: "/x", run() {} }), ScenarioError, `${JSON.stringify(id)} was accepted`);
  }
});

test("a scenario needs a driver route and something to run", () => {
  assert.throws(() => defineScenario({ id: "a-b", route: "tests/x", run() {} }), ScenarioError);
  assert.throws(() => defineScenario({ id: "a-b", route: "/x" }), ScenarioError);
  assert.throws(() => defineScenario({ id: "a-b", route: "/x", run() {}, touch: "yes" }), ScenarioError);
});

// Emulation applied after the document has loaded leaves every touch inert, so
// the order is the whole point of the flag existing.
test("a scenario declaring touch has emulation on before the page is navigated", async () => {
  const page = fakePage();
  const { port, sent } = createFakePort({ boxes: { ".react-flow": FLOW } });
  const order = [];
  const watched = { ...port, async enableTouch() { order.push("enableTouch"); } };
  const gotoWatched = { ...page, async goto(url) { order.push("goto"); return page.goto(url); } };

  await runScenario(
    gotoWatched,
    defineScenario({ id: "live--touching", route: "/tests/generic/nodes/general", run: async () => {}, touch: true }),
    { side: "psflow", capture: 1, baseline: "12.11.0", port: watched }
  );

  assert.deepEqual(order, ["enableTouch", "goto"]);
  assert.deepEqual(sent, [], "the double records nothing for a scenario that never touched");
});

test("a scenario that does not declare touch never turns emulation on", async () => {
  const { sent } = await capture();

  assert.deepEqual(sent.filter((s) => s.kind === "enableTouch"), []);
});

test("both sides load the same page, differing only in which bundle it imports", () => {
  assert.equal(driverUrl("/tests/generic/nodes/general", "psflow"), "/parity/driver/index.html?side=psflow#/tests/generic/nodes/general");
  assert.equal(driverUrl("/tests/generic/nodes/general", "upstream"), "/parity/driver/index.html?side=upstream#/tests/generic/nodes/general");
  assert.equal(driverUrl("/examples/color-mode", "psflow"), "/parity/driver/index.html?side=psflow#/examples/color-mode");
});

test("the run is the envelope's, and the trace validates", async () => {
  const { trace, page } = await capture();

  assert.equal(trace.scenario, "mount-baseline--nodes-general");
  assert.equal(trace.side, "psflow");
  assert.equal(trace.capture, 1);
  assert.equal(trace.baseline, "12.11.0");
  assert.deepEqual(page.visited, ["/parity/driver/index.html?side=psflow#/tests/generic/nodes/general"]);
  assert.equal(validateTrace(trace, "in-memory"), trace);
});

// The side lives in the URL and in nothing else. A trace carrying it in a
// compared section would differ on every scenario at once, for a reason that
// has nothing to do with the library.
test("no section mentions which side ran", async () => {
  const { trace } = await capture(async (actions) => {
    await actions.dragNode(".node", { dx: 10, dy: 10, steps: 1 });
  });

  assert.doesNotMatch(JSON.stringify(trace.sections), /psflow|upstream|side=/i);
});

test("the mount is the first driving action, carrying the container's box", async () => {
  const { trace } = await capture();

  assert.deepEqual(trace.sections.driving, [
    {
      index: 0,
      action: "mount",
      target: ".react-flow",
      resolved: true,
      box: FLOW,
      dispatched: { route: "/tests/generic/nodes/general" },
    },
  ]);
});

// A side that never renders reads as an unresolved first action followed by a
// scenario whose every action is also unresolved — a finding — rather than as a
// thrown timeout, which reads as a flake.
test("a side that never mounts is recorded, and its scenario still drives", async () => {
  const { trace } = await capture(
    async (actions) => {
      await actions.pointerDown(".node");
    },
    { boxes: {} }
  );

  assert.deepEqual(
    trace.sections.driving.map((e) => [e.action, e.resolved]),
    [
      ["mount", false],
      ["pointerDown", false],
    ]
  );
});

test("the scenario is handed the vocabulary and nothing else", async () => {
  let handed;
  let arity;
  await capture(async function (...args) {
    arity = args.length;
    handed = args[0];
  });

  assert.equal(arity, 1);
  assert.deepEqual(Object.keys(handed).sort(), [...VOCABULARY].sort());
});

test("what the page printed is captured, uncaught errors included", async () => {
  const page = fakePage();
  const { port } = createFakePort({ boxes: { ".react-flow": FLOW } });
  const trace = await runScenario(
    page,
    scenario(async () => {
      page.emit("console", { type: () => "warn", text: () => "[React Flow]: 002" });
      page.emit("pageerror", new Error("boom"));
    }),
    { side: "psflow", capture: 1, baseline: "12.11.0", port }
  );

  assert.deepEqual(trace.sections.console, [
    { level: "warn", text: "[React Flow]: 002" },
    { level: "pageerror", text: "boom" },
  ]);
});

test("listeners are removed afterwards, so a second capture is not handed the first's output", async () => {
  const { page } = await capture();

  assert.equal(page.listenerCount("console"), 0);
  assert.equal(page.listenerCount("pageerror"), 0);
});

test("a scenario that throws still lets go of the page", async () => {
  const page = fakePage();
  const { port } = createFakePort({ boxes: { ".react-flow": FLOW } });

  await assert.rejects(
    () =>
      runScenario(
        page,
        scenario(() => {
          throw new Error("scenario blew up");
        }),
        { side: "psflow", capture: 1, baseline: "12.11.0", port }
      ),
    /scenario blew up/
  );
  assert.equal(page.listenerCount("console"), 0);
});

test("page-level state is captured, since two behaviours turn on a default not happening", async () => {
  const page = fakePage();
  const { port } = createFakePort({
    boxes: { ".react-flow": FLOW },
    page: { scrollX: 0, scrollY: 40, visualViewportScale: 2 },
  });
  const trace = await runScenario(page, scenario(), { side: "psflow", capture: 1, baseline: "12.11.0", port });

  assert.deepEqual(trace.sections.dom.page, { scrollX: 0, scrollY: 40, visualViewportScale: 2 });
});

test("the envelope refuses a run it could not identify", async () => {
  const page = fakePage();
  const { port } = createFakePort({ boxes: { ".react-flow": FLOW } });
  const run = (options) => runScenario(page, scenario(), { side: "psflow", capture: 1, baseline: "12.11.0", port, ...options });

  await assert.rejects(() => run({ side: "psflwo" }), ScenarioError);
  await assert.rejects(() => run({ capture: 0 }), ScenarioError);
  await assert.rejects(() => run({ baseline: "" }), ScenarioError);
});
