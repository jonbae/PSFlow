// The bucket table's own tests. Nothing here mounts a page or reads the
// vendored tree: the rules are a function of one row and the corpus's name
// space, which is what makes them testable at all.
//
// The falsification the file is really for is the third one down. `gate-pending`
// exists so a row can say "a gate is coming" without counting as covered, and
// the way that degrades into fiction is a row naming a scenario nobody will ever
// write. A check that only looked for the field's presence would pass on a typo.

import { test } from "node:test";
import assert from "node:assert/strict";

import { BUCKETS, rowProblems } from "./buckets.mjs";

const names = { written: ["drag-node-release"], reserved: ["drag-node-autopan"] };

const problems = (row, space = names) => rowProblems("5684", row, { scenarios: space });

const netRow = (over = {}) => ({
  bucket: "gate-pending",
  gate: "system",
  scenario: "drag-node-release",
  stage: 2,
  note: "src/React/Hook/Drag.purs; untested.",
  ...over,
});

test("the three kinds each demand their own evidence of not being fiction", () => {
  assert.deepEqual(problems({ bucket: "system", evidence: "the net drives it" }), []);
  assert.match(problems({ bucket: "system", evidence: "  " })[0], /requires non-empty evidence/);

  assert.deepEqual(problems({ bucket: "ported-ungated", ticket: "079" }), []);
  assert.match(problems({ bucket: "ported-ungated" })[0], /ticket or a note/);

  assert.deepEqual(problems({ bucket: "accepted-ungated", reason: "the net is blind to render counts" }), []);
  assert.match(problems({ bucket: "accepted-ungated" })[0], /written reason/);
});

test("an unknown bucket is reported once and nothing else is guessed at", () => {
  assert.deepEqual(problems({ bucket: "layer2", evidence: "" }), ['#5684: unknown bucket "layer2"']);
});

test("a gate-pending row naming a scenario the corpus neither holds nor reserves fails", () => {
  // The rule ticket 080 wrote down: a planned gate is a gap, and the plan means
  // nothing until the name resolves to something someone will drive.
  const said = problems(netRow({ scenario: "drag-node-somersault" }));

  assert.equal(said.length, 1);
  assert.match(said[0], /drag-node-somersault/);
  assert.match(said[0], /neither holds nor reserves/);
});

test("a reserved id is a name the corpus has committed to, and passes", () => {
  assert.deepEqual(problems(netRow({ scenario: "drag-node-autopan" })), []);
});

test("a net-bound row missing any of gate, scenario or stage fails", () => {
  assert.match(problems(netRow({ gate: undefined }))[0], /names no target gate/);
  assert.match(problems(netRow({ scenario: undefined }))[0], /names no scenario/);
  assert.match(problems(netRow({ stage: undefined }))[0], /names no boundary stage/);
  assert.match(problems(netRow({ stage: 5 }))[0], /boundary stage/);
});

test("only a bucket a row could graduate into may be named as the target gate", () => {
  assert.match(problems(netRow({ gate: "docs" }))[0], /cannot be a gate-pending row's target/);
  assert.match(problems(netRow({ gate: "not-ported" }))[0], /cannot be a gate-pending row's target/);
});

test("a gate-pending row that is not net-bound names a test and no stage", () => {
  const unit = { bucket: "gate-pending", gate: "unit", test: "a predicate test over isInputDOMNode", note: "x" };

  assert.deepEqual(problems(unit), []);
  assert.match(problems({ ...unit, test: undefined })[0], /names no test/);
  assert.match(problems({ ...unit, stage: 1 })[0], /boundary stage/);
  assert.match(problems({ ...unit, scenario: "drag-node-release" })[0], /scenario/);
});

test("a bucket-specific field on the wrong bucket is a half-edited row, not a silent extra", () => {
  // The failure this catches: a row rebucketed away from gate-pending that kept
  // its scenario. Nothing would read it, and it would read as a plan forever.
  assert.match(problems({ bucket: "ported-ungated", ticket: "079", scenario: "drag-node-release" })[0], /scenario/);
  assert.match(problems({ bucket: "unit", evidence: "a test", reason: "because" })[0], /reason/);
});

test("every bucket declares one of the four kinds, and every target is a covered one", () => {
  for (const [bucket, meta] of Object.entries(BUCKETS)) {
    assert.ok(["covered", "gap", "accepted", "na"].includes(meta.kind), `${bucket} declares a known kind`);
    assert.ok(meta.label.trim(), `${bucket} carries a label`);
    if (meta.target) assert.equal(meta.kind, "covered", `${bucket} is a covered bucket to graduate into`);
  }
});
