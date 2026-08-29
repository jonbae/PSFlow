import { test } from "node:test";
import assert from "node:assert/strict";

import { CALL_LOG, CallLogError, OBSERVE, callbacksSection, createCallLog, installCallLog } from "./call-log.mjs";

// The log runs in the page but is plain composition over `serialize.mjs`, so it
// is tested where everything else above the port is: in node, with no browser.
// What only a browser can say — that a real library firing a real handler
// reaches this log — is `live.spec.mjs`.

test("calls land in the order they were made, with their arguments serialized", () => {
  const log = createCallLog();

  log.wrap("onNodesChange", () => {})([{ id: "1", type: "dimensions" }]);
  log.wrap("onNodeDrag", () => {})({ type: "pointermove" }, { id: "1" }, []);

  assert.deepEqual(log.read().entries, [
    { name: "onNodesChange", args: [[{ id: "1", type: "dimensions" }]] },
    { name: "onNodeDrag", args: [{ type: "pointermove" }, { id: "1" }, []] },
  ]);
});

test("hook callbacks keep their exact count, order, and interleaving", () => {
  const log = createCallLog();
  log.record("onMove", [{ zoom: 2 }]);

  const viewport = log.wrapProbe("useOnViewportChange");
  const selection = log.wrapProbe("useOnSelectionChange");
  viewport({ zoom: 1 });
  selection({ nodes: [] });
  viewport({ zoom: 3 });

  assert.deepEqual(log.read().entries, [
    { name: "onMove", args: [{ zoom: 2 }] },
    { name: "useOnViewportChange", args: [{ zoom: 1 }], probe: true },
    { name: "useOnSelectionChange", args: [{ nodes: [] }], probe: true },
    { name: "useOnViewportChange", args: [{ zoom: 3 }], probe: true },
  ]);
});

// The whole point of the wrapper: what the fixture asked for still happens, and
// still answers. A driver that observed a handler by replacing it would change
// what the page does, and the two runs would no longer be one experiment.
test("the handler beneath still runs, with its arguments, and its answer is returned", () => {
  const log = createCallLog();
  const seen = [];

  const observed = log.wrap("isValidConnection", (connection) => {
    seen.push(connection);
    return false;
  });

  assert.equal(observed({ source: "1" }), false);
  assert.deepEqual(seen, [{ source: "1" }]);
});

// The driver installs every callback prop upstream declares, including the ones
// no fixture sets. For two of them the library reads the *return value*, so an
// installed handler answering `undefined` is a different instruction from an
// absent prop: `onBeforeDelete` cancels the deletion, `isValidConnection`
// refuses the connection.
test("a prop nobody set is still recorded, and answers what the register says", () => {
  const log = createCallLog();

  assert.equal(log.wrap("onBeforeDelete", undefined, true)({ nodes: [], edges: [] }), true);
  assert.equal(log.wrap("onPaneClick", undefined)({ type: "click" }), undefined);

  assert.deepEqual(
    log.read().entries.map((e) => e.name),
    ["onBeforeDelete", "onPaneClick"]
  );
});

// Recording happens before the handler beneath runs, which is what keeps the
// sequence the library's rather than the driver's: a handler whose own work
// fires a second call must not have that call recorded first.
test("a handler that causes another call leaves the two in the library's order", () => {
  const log = createCallLog();

  const inner = log.wrap("onNodesChange", () => {});
  log.wrap("onNodeDragStop", () => inner([{ id: "1", type: "position" }]))({}, { id: "1" }, []);

  assert.deepEqual(
    log.read().entries.map((e) => e.name),
    ["onNodeDragStop", "onNodesChange"]
  );
});

// xyflow hands a handler objects it goes on to mutate — a node's position
// during a drag, most of all. A log holding references would record where every
// node ended up, which is what the `dom` section already says, and would report
// two identical drags as one.
test("an argument mutated after the call is recorded as it was at the call", () => {
  const log = createCallLog();
  const node = { id: "1", position: { x: 0, y: 0 } };

  log.wrap("onNodeDragStart", () => {})({}, node, [node]);
  node.position.x = 100;
  log.wrap("onNodeDragStop", () => {})({}, node, [node]);

  const [start, stop] = log.read().entries;
  assert.equal(start.args[1].position.x, 0);
  assert.equal(stop.args[1].position.x, 100);
});

// The ceiling is `serializeValue`'s, and reaching it is a question for a person.
// What must not happen is the throw escaping into the library's own event
// dispatch, where it would change what the page does.
test("a value the serializer refuses is recorded as a failure, and the handler still runs", () => {
  const log = createCallLog({ maxDepth: 3 });
  let ran = false;

  const deep = { a: { b: { c: { d: { e: 1 } } } } };
  log.wrap("onConnectEnd", () => {
    ran = true;
  })(deep);

  assert.equal(ran, true);
  const { entries, failures } = log.read();
  assert.deepEqual(entries, []);
  assert.equal(failures.length, 1);
  assert.equal(failures[0].name, "onConnectEnd");
  assert.match(failures[0].error, /deep/);
});

test("the harness raises what the page could not serialize, naming where it would have been", () => {
  const log = createCallLog({ maxDepth: 2 });
  log.wrap("onNodesChange", () => {})([{ id: "1" }]);
  log.wrap("onConnectEnd", () => {})({ a: { b: { c: 1 } } });

  assert.throws(() => callbacksSection({ installed: true, ...log.read() }), {
    name: "CallLogError",
    message: /onConnectEnd \(would have been callbacks\/1\)/,
  });
});

// An absent log is not an empty section. Two empty sections compare clean, which
// is exactly the silent pass the net exists to remove — so this is the one place
// capture refuses to produce a trace at all.
test("a page with no log is a stale bundle, and fails rather than capturing nothing", () => {
  assert.throws(() => callbacksSection({ installed: false, entries: [], failures: [] }), {
    name: "CallLogError",
    message: /build:driver/,
  });
});

test("a log that recorded nothing is a section with no calls in it, which is a finding and not a failure", () => {
  const log = createCallLog();
  log.observe(["onNodesChange", "onPaneClick"]);

  assert.deepEqual(callbacksSection({ installed: true, ...log.read() }), []);
});

// The other way an empty section can happen, and the one that is a fault: the
// page mounted a fixture driver and it wrapped nothing, because the URL never
// asked. Installing a callback prop changes what the page renders, so the net
// asks explicitly — and a run that forgot would otherwise record an empty
// section on both sides and compare clean.
test("a fixture driver that wrapped nothing fails, naming the parameter the URL was missing", () => {
  const log = createCallLog();
  log.observe([]);

  assert.throws(() => callbacksSection({ installed: true, ...log.read() }), {
    name: "CallLogError",
    message: new RegExp(`${OBSERVE.param}=${OBSERVE.callbacks}`),
  });
});

// Three states, and only the middle one is a fault. A route with no fixture
// driver on it — a directly-mounted component — has no props to wrap and says
// so by never reporting at all.
test("a route with no fixture driver on it observes nothing legitimately", () => {
  const log = createCallLog();

  assert.equal(log.read().observing, null);
  assert.deepEqual(callbacksSection({ installed: true, ...log.read() }), []);
});

test("what a driver reported it wrapped is a copy, so the page cannot edit the harness's answer", () => {
  const log = createCallLog();
  const names = ["onNodesChange"];
  log.observe(names);
  names.push("onPaneClick");

  assert.deepEqual(log.read().observing, ["onNodesChange"]);
  log.read().observing.push("onEdgesChange");
  assert.deepEqual(log.read().observing, ["onNodesChange"]);
});

test("installing twice hands back the same log, so the page and the driver share one", () => {
  const page = {};

  const first = installCallLog(page);
  first.wrap("onInit", () => {})();
  const second = installCallLog(page);

  assert.equal(second, first);
  assert.equal(page[CALL_LOG], first);
  assert.equal(second.read().entries.length, 1);
});

test("CallLogError is what both refusals throw", () => {
  assert.throws(() => callbacksSection({ installed: false, entries: [], failures: [] }), CallLogError);
});
