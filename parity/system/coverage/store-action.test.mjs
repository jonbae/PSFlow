import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import { readRun } from "../net/traces.mjs";
import { OUTCOME, coverageOutcomes, exportEntries } from "./coverage.mjs";

const read = (path) => JSON.parse(readFileSync(new URL(path, import.meta.url), "utf8"));
const traceDir = fileURLToPath(new URL("../traces/", import.meta.url));
const name = "UnselectNodesAndEdgesParams";
const entries = exportEntries(read("../../census/classification.json")).filter(entry => entry.export === name);
const witnesses = read("./witnesses.json").witnesses.filter(entry => entry.export === name);
const holes = read("./holes.json").holes.filter(hole => hole.exports.includes(name));
const rules = read("../normalization.json").rules;
const kinds = ["no-argument", "empty-options", "nodes", "edges"];
const scenarios = kinds.map(kind => `store-unselect-${kind}`);
const baseline = "mount-baseline--flow-unselect";
const selected = (elements) => elements.filter(element => element.selected).map(element => element.id);
const changes = (trace, handler) => trace.sections.callbacks
  .filter(call => call.name === handler)
  .flatMap(call => call.args[0])
  .filter(change => change.type === "select");
const outcomes = (traces, over = {}) => coverageOutcomes(entries, { witnesses, holes, rules, traces, ...over });

test("the mounted store controls preserve selection without witnessing an action", () => {
  const traces = readRun(traceDir, baseline);
  for (const trace of traces) {
    assert.equal(trace.sections.api.storeCalls, undefined);
    assert.deepEqual(selected(trace.sections.api.queries.getNodes), ["Node-1", "Node-2", "Node-3"]);
    assert.deepEqual(selected(trace.sections.api.queries.getEdges), ["1-2", "1-3"]);
  }
  assert.equal(outcomes(traces).exports[0].outcome, OUTCOME.undeclared);
});

for (const kind of kinds) {
  test(`store unselect ${kind} records its invocation and resulting selection on both sides and captures`, () => {
    for (const trace of readRun(traceDir, `store-unselect-${kind}`)) {
      const { api } = trace.sections;
      assert.equal(api.storeCalls.length, 1);
      const [call] = api.storeCalls;
      assert.equal(call.method, "unselectNodesAndEdges");
      assert.deepEqual(call.result, { "@undefined": true });
      assert.deepEqual(api.calls, [], "the action was reached through the store, not an instance method");
      if (kind === "no-argument") assert.deepEqual(call.args, []);
      else if (kind === "empty-options") assert.deepEqual(call.args, [{}]);
      else {
        assert.deepEqual(Object.keys(call.args[0]), [kind]);
        assert.equal(call.args[0][kind].length, 1);
        assert.equal(call.args[0][kind][0].id, kind === "nodes" ? "Node-1" : "1-2");
        assert.equal(call.args[0][kind][0].selected, true, "arguments were captured before deselection");
      }
      const nodeIds = kind === "nodes" ? ["Node-1"] : ["Node-1", "Node-2", "Node-3"];
      const edgeIds = kind === "edges" ? ["1-2"] : ["1-2", "1-3"];
      assert.deepEqual(changes(trace, "onNodesChange"), nodeIds.map(id => ({ id, type: "select", selected: false })));
      assert.deepEqual(changes(trace, "onEdgesChange"), edgeIds.map(id => ({ id, type: "select", selected: false })));
      assert.deepEqual(selected(api.queries.getNodes), kind === "nodes" ? ["Node-2", "Node-3"] : []);
      assert.deepEqual(selected(api.queries.getEdges), kind === "edges" ? ["1-3"] : []);
    }
  });
}

test("real store-call receipts retire the hole and removing the observation reopens it", () => {
  const traces = [baseline, ...scenarios].flatMap(scenario => readRun(traceDir, scenario));
  const driven = outcomes(traces);
  assert.equal(driven.ok, true);
  assert.equal(driven.exports[0].outcome, OUTCOME.driven);
  assert.deepEqual(driven.exports[0].drivenBy, [...scenarios].sort());
  assert.deepEqual(holes, [], "the now-stale hole declaration must be retired");

  const missing = structuredClone(traces);
  for (const trace of missing) delete trace.sections.api.storeCalls;
  assert.equal(outcomes(missing).exports[0].outcome, OUTCOME.undeclared);
  assert.equal(outcomes(missing).ok, false);
  const unobserved = outcomes(traces, { rules: [...rules, { kind: "delete", at: "api/storeCalls", reason: "falsification: remove store observations" }] });
  assert.equal(unobserved.exports[0].outcome, OUTCOME.undeclared);
  assert.equal(unobserved.ok, false);
  const stale = outcomes(traces, { holes: [{ exports: [name], reason: "former store observation hole" }] });
  assert.equal(stale.ok, false);
  assert.deepEqual(stale.staleHoles[0].exports, [name]);
});
