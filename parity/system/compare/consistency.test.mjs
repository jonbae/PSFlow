import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { readTrace } from "../trace-format.mjs";
import { checkSelfConsistency, ConsistencyError } from "./consistency.mjs";
import { formatPath } from "./paths.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const fixture = (name) => readTrace(join(here, "fixtures", name));
const SORT_RULES = JSON.parse(readFileSync(join(here, "..", "normalization.json"), "utf8")).rules;

test("two captures of one side that agree are self-consistent", () => {
  const result = checkSelfConsistency(fixture("baseline.psflow.json"), fixture("baseline.psflow.capture2.json"), {
    rules: SORT_RULES,
  });

  assert.equal(result.consistent, true);
  assert.deepEqual(result.differences, []);
  assert.equal(result.side, "psflow");
  assert.deepEqual(result.captures, [1, 2]);
});

test("sub-pixel box variation between one side's two captures fails", () => {
  const result = checkSelfConsistency(fixture("baseline.psflow.json"), fixture("wobbling-box.psflow.capture2.json"), {
    rules: SORT_RULES,
  });

  assert.equal(result.consistent, false);
  assert.deepEqual(
    result.differences.map((d) => formatPath(d.path)),
    ["driving/1/box/width"]
  );
  assert.deepEqual(result.differences[0].left, 150);
  assert.deepEqual(result.differences[0].right, 150.00001);
});

test("no rule can be written that would forgive a driving difference", () => {
  const tolerant = [
    ...SORT_RULES,
    { kind: "delete", at: "driving/**/box", reason: "boxes wobble, apparently" },
    { kind: "delete", at: "**/width", reason: "a rule broad enough to reach driving by accident" },
  ];

  const result = checkSelfConsistency(fixture("baseline.psflow.json"), fixture("wobbling-box.psflow.capture2.json"), {
    rules: tolerant,
  });

  // The log never reaches the normalizer, so neither the rule aimed at it nor
  // the one that would have swept it up on the way past can touch the wobble.
  assert.equal(result.consistent, false);
  assert.deepEqual(
    result.differences.map((d) => formatPath(d.path)),
    ["driving/1/box/width"]
  );
});

test("every other section normalizes exactly as it does across the sides", () => {
  const restyled = fixture("baseline.psflow.capture2.json");
  const node = restyled.sections.dom.root.children[0].children[0];
  node.attrs.class = node.attrs.class.split(" ").reverse().join(" ");

  const forgiven = checkSelfConsistency(fixture("baseline.psflow.json"), restyled, { rules: SORT_RULES });
  const unforgiven = checkSelfConsistency(fixture("baseline.psflow.json"), restyled, { rules: [] });

  assert.equal(forgiven.consistent, true, "class token order is noise within a side as much as across two");
  assert.equal(unforgiven.consistent, false, "and it is the ruleset doing the forgiving, not the check");
});

test("a rule broad enough to reach the driving log still normalizes the sections it may touch", () => {
  const restyled = fixture("baseline.psflow.capture2.json");
  const node = restyled.sections.dom.root.children[0].children[0];
  node.attrs.class = node.attrs.class.split(" ").reverse().join(" ");

  // `**`-rooted, so under a withhold-the-rule reading of "no tolerance" this
  // sort would be dropped from the whole check and the side would fail against
  // itself for token order the noise policy settled long ago. Only the driving
  // log is untouchable; the ruleset applies everywhere else in full.
  const result = checkSelfConsistency(fixture("baseline.psflow.json"), restyled, {
    rules: [{ kind: "sort", at: "**/attrs/class", as: "tokens", reason: "the same rule, written broadly" }],
  });

  assert.equal(result.consistent, true);
});

test("a side compared against the other side is a mistake, not an inconsistency", () => {
  assert.throws(
    () => checkSelfConsistency(fixture("baseline.psflow.json"), fixture("baseline.upstream.capture2.json"), {}),
    (e) => e instanceof ConsistencyError && /side/.test(e.message)
  );
});

test("a trace checked against itself is a check that cannot go red", () => {
  assert.throws(
    () => checkSelfConsistency(fixture("baseline.psflow.json"), fixture("baseline.psflow.json"), {}),
    (e) => e instanceof ConsistencyError && /capture/.test(e.message)
  );
});

test("two captures of different scenarios are not two captures of one run", () => {
  const other = fixture("baseline.psflow.capture2.json");
  other.scenario = "drag-node-release";

  assert.throws(
    () => checkSelfConsistency(fixture("baseline.psflow.json"), other, {}),
    (e) => e instanceof ConsistencyError && /scenario/.test(e.message)
  );
});

test("two captures against different baselines are not two captures of one run", () => {
  const other = fixture("baseline.psflow.capture2.json");
  other.baseline = "12.10.0";

  assert.throws(
    () => checkSelfConsistency(fixture("baseline.psflow.json"), other, {}),
    (e) => e instanceof ConsistencyError && /baseline/.test(e.message)
  );
});

test("an illegal rule fails the check rather than being quietly skipped", () => {
  assert.throws(
    () =>
      checkSelfConsistency(fixture("baseline.psflow.json"), fixture("baseline.psflow.capture2.json"), {
        rules: [{ kind: "round", at: "dom/**/attrs/style", reason: "a kind that does not exist" }],
      }),
    /kind "round" is not one of/
  );
});

test("a malformed capture fails as a malformed trace rather than as an inconsistency", () => {
  const broken = fixture("baseline.psflow.capture2.json");
  delete broken.sections.driving;

  assert.throws(() => checkSelfConsistency(fixture("baseline.psflow.json"), broken, {}), /driving is missing/);
});
