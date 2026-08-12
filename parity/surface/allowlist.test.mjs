import { test } from "node:test";
import assert from "node:assert/strict";

import { AllowlistError, claim, liveRenames, validateReasons, RETIRING_EVENT } from "./allowlist.mjs";

const renamesOf = (result) => result.live.map(([from, to]) => `${from}→${to}`);

test("a difference with an entry is claimed; one without is not", () => {
  const { claimed, unclaimed } = claim(["MiniMapNode", "SomethingNew"], { MiniMapNode: "ticket 058" });
  assert.deepEqual(claimed, ["MiniMapNode"]);
  assert.deepEqual(unclaimed, ["SomethingNew"]);
});

test("an entry that claims nothing is stale — that is the whole point of the register", () => {
  const { claimed, stale } = claim(["MiniMapNode"], { MiniMapNode: "ticket 058", Position: "crossed in stage 1" });
  assert.deepEqual(claimed, ["MiniMapNode"]);
  assert.deepEqual(stale, ["Position"]);
});

test("stale is reported for permanent-looking entries too — nothing is exempt", () => {
  const { stale } = claim([], { NodeTypes: "renamed NodeTypesMap in PSFlow (intentional, permanent)" });
  assert.deepEqual(stale, ["NodeTypes"]);
});

test("an empty register claims nothing and goes stale over nothing", () => {
  assert.deepEqual(claim(["A"], {}), { claimed: [], unclaimed: ["A"], stale: [] });
  assert.deepEqual(claim([], undefined), { claimed: [], unclaimed: [], stale: [] });
});

test("claimed and stale are sorted, so the report does not churn on key order", () => {
  const { claimed, stale } = claim(["b", "a"], { b: "r", a: "r", z: "r", y: "r" });
  assert.deepEqual(claimed, ["a", "b"]);
  assert.deepEqual(stale, ["y", "z"]);
});

test("an entry needs a written reason — an unexplained entry is a dumping ground", () => {
  assert.throws(() => validateReasons("exports.missing", { A: "" }), AllowlistError);
  assert.throws(() => validateReasons("exports.missing", { A: null }), AllowlistError);
  assert.doesNotThrow(() => validateReasons("exports.missing", { A: "not modelled — ticket 058" }));
});

test("a shape entry must name the event that retires it: a boundary stage or a ticket", () => {
  assert.throws(
    () => validateReasons("shapes", { ReactFlow: "upstream memoizes and PSFlow does not" }, RETIRING_EVENT),
    AllowlistError
  );
  assert.doesNotThrow(() =>
    validateReasons("shapes", { ReactFlow: "curried; uncurries in boundary stage 3" }, RETIRING_EVENT)
  );
  assert.doesNotThrow(() =>
    validateReasons("shapes", { ReactFlow: "no ref — ticket #27" }, RETIRING_EVENT)
  );
});

test("the failure message names the register and the key, so a stale entry is one edit away", () => {
  assert.throws(() => validateReasons("props.NodeProps.extra", { xPos: "" }), (e) => {
    assert.match(e.message, /props\.NodeProps\.extra/);
    assert.match(e.message, /xPos/);
    return true;
  });
});

test("a rename is live only when it still cancels a real difference", () => {
  const upstream = ["xPos", "id"];
  const psflow = ["positionAbsoluteX", "id"];

  const live = liveRenames({ xPos: "positionAbsoluteX" }, upstream, psflow);
  // The pair survives whole, so a caller reporting it never goes back to the
  // register for the half this function already had.
  assert.deepEqual(renamesOf(live), ["xPos→positionAbsoluteX"]);
  assert.deepEqual(live.stale, []);
  // upstream dropped the member the rename translates from
  assert.deepEqual(liveRenames({ gone: "positionAbsoluteX" }, upstream, psflow).stale, ["gone"]);
  // PSFlow does not have the member the rename translates to
  assert.deepEqual(liveRenames({ xPos: "absent" }, upstream, psflow).stale, ["xPos"]);
  // PSFlow surfaces upstream's own name, so the rename cancels nothing
  assert.deepEqual(liveRenames({ id: "positionAbsoluteX" }, upstream, psflow).stale, ["id"]);
});
