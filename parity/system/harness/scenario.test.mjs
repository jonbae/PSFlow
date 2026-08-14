import { test } from "node:test";
import assert from "node:assert/strict";

import { validateTrace } from "../trace-format.mjs";
import { EMPTY_DOM, createFakePort } from "./fake-port.mjs";
import { SettleError } from "./settle.mjs";
import { VOCABULARY } from "./vocabulary.mjs";
import { ScenarioError, defineScenario, driverUrl, runScenario } from "./scenario.mjs";

const FLOW = { x: 0, y: 0, width: 800, height: 600 };
const NODE = { x: 75, y: 25, width: 150, height: 36 };

const flow = (label) => ({ page: EMPTY_DOM.page, root: { tag: "div", attrs: { "data-x": label }, children: [] } });

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

const capture = async (run, { boxes = { ".react-flow": FLOW, ".node": NODE }, dom, ...options } = {}) => {
  const page = fakePage();
  const { port, sent } = createFakePort({ boxes, ...(dom === undefined ? {} : { dom }) });
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

  // Two navigations: the blank document each capture starts from, then the
  // driver. Emulation has to precede both — applied after a document has loaded
  // it leaves every dispatched touch inert.
  assert.deepEqual(order, ["enableTouch", "goto", "goto"]);
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
  assert.deepEqual(page.visited, ["about:blank", "/parity/driver/index.html?side=psflow#/tests/generic/nodes/general"]);
  assert.equal(validateTrace(trace, "in-memory"), trace);
});

// Found by self-consistency against a real page (#43): a capture reuses the
// page, so the second capture of a scenario navigates to the URL the page is
// already on. That is a same-document navigation — nothing reloads, and capture
// 2 opens on the flow capture 1 left behind, a hundred pixels along.
test("every capture starts on a document of its own, not on the one before it", async () => {
  const page = fakePage();
  const { port } = createFakePort({ boxes: { ".react-flow": FLOW } });
  const run = { side: "psflow", baseline: "12.11.0", port };

  await runScenario(page, scenario(), { ...run, capture: 1 });
  await runScenario(page, scenario(), { ...run, capture: 2 });

  assert.deepEqual(page.visited.filter((url) => url === "about:blank").length, 2);
  assert.equal(page.visited[2], "about:blank", "the second capture blanks before it navigates, not after");
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
  const { trace } = await capture(undefined, {
    dom: { page: { scrollX: 0, scrollY: 40, visualViewportScale: 2 }, root: null },
  });

  assert.deepEqual(trace.sections.dom.page, { scrollX: 0, scrollY: 40, visualViewportScale: 2 });
});

// The section that makes the two halves a gate: two traces whose `dom` is null
// on both sides compare clean and mean nothing.
test("the dom section is the settled snapshot, element tree and all", async () => {
  const settled = { page: EMPTY_DOM.page, root: { tag: "div", attrs: { class: "react-flow" }, children: [] } };
  const { trace } = await capture(undefined, { dom: [flow("mounting"), settled, settled] });

  assert.deepEqual(trace.sections.dom, settled);
});

// Selectors resolve against each side's own render, so an action driven at a
// flow that is still mounting aims at a layout about to move — and the box it
// resolves lands in the one section that carries no tolerance.
test("the page is settled before the scenario is allowed to act", async () => {
  const seen = [];
  const { port } = createFakePort({ boxes: { ".react-flow": FLOW, ".node": NODE }, dom: [flow("a"), flow("a")] });
  const watched = {
    ...port,
    async dom(selector) {
      const snapshot = await port.dom(selector);
      seen.push("dom");
      return snapshot;
    },
    async box(selector, options) {
      seen.push(`box:${selector}`);
      return port.box(selector, options);
    },
  };

  await runScenario(
    fakePage(),
    scenario(async (actions) => {
      await actions.pointerDown(".node");
    }),
    { side: "psflow", capture: 1, baseline: "12.11.0", port: watched }
  );

  // Mount, then settle, then the action resolves its own target — never the
  // other way round.
  assert.deepEqual(seen.slice(0, 4), ["box:.react-flow", "dom", "dom", "box:.node"]);
});

// A page that never stops changing is a question for a person: capturing anyway
// would record a snapshot known to be mid-flight, and the run would report a
// divergence in every section at once.
test("a page that never settles fails the capture rather than being read mid-flight", async () => {
  let poll = 0;
  const { port } = createFakePort({ boxes: { ".react-flow": FLOW } });
  const restless = { ...port, async dom() { return flow(`poll-${poll++}`); } };

  await assert.rejects(
    () =>
      runScenario(fakePage(), scenario(), {
        side: "psflow",
        capture: 1,
        baseline: "12.11.0",
        port: restless,
        settle: { polls: 3 },
      }),
    SettleError
  );
});

test("the envelope refuses a run it could not identify", async () => {
  const page = fakePage();
  const { port } = createFakePort({ boxes: { ".react-flow": FLOW } });
  const run = (options) => runScenario(page, scenario(), { side: "psflow", capture: 1, baseline: "12.11.0", port, ...options });

  await assert.rejects(() => run({ side: "psflwo" }), ScenarioError);
  await assert.rejects(() => run({ capture: 0 }), ScenarioError);
  await assert.rejects(() => run({ baseline: "" }), ScenarioError);
});
