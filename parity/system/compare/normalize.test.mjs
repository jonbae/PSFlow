import { test } from "node:test";
import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { readTrace } from "../trace-format.mjs";
import { diffValues, formatPath } from "./diff.mjs";
import { assertNoCollapse, normalize, validateRules } from "./normalize.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const fixture = (name) => readTrace(join(here, "fixtures", name));

const SORT_RULES = [
  { kind: "sort", at: "dom/**/attrs/class", as: "tokens", reason: "class token order is not semantic" },
  { kind: "sort", at: "dom/**/attrs/style", as: "declarations", reason: "declaration order is not semantic" },
];

const sectionsOf = (trace) => trace.sections;

test("delete-by-name removes a field from a side regardless of its value", () => {
  const rules = [{ kind: "delete", at: "dom/**/attrs/data-testid", reason: "harness-injected" }];
  const { value, deleted } = normalize(sectionsOf(fixture("baseline.upstream.json")), rules);

  assert.equal("data-testid" in value.dom.root.attrs, false);
  assert.deepEqual(
    deleted.map((d) => formatPath(d.path)),
    ["dom/root/attrs/data-testid"]
  );
  assert.equal(deleted[0].rule.reason, "harness-injected");
});

test("a deleted field is recorded as unobserved rather than silently dropped", () => {
  const rules = [{ kind: "delete", at: "dom/**/attrs/style", reason: "not today" }];
  const { deleted } = normalize(sectionsOf(fixture("baseline.upstream.json")), rules);

  assert.equal(deleted.length, 3, "every occurrence is recorded, not just the first");
  assert.ok(deleted.every((d) => d.rule.reason === "not today"));
});

test("sorting reorders class tokens and style declarations without touching anything else", () => {
  const { value } = normalize(sectionsOf(fixture("precise-coordinate.psflow.json")), SORT_RULES);
  const nodes = value.dom.root.children[0].children;

  assert.equal(nodes[1].attrs.class, "react-flow__node react-flow__node-default");
  assert.match(nodes[0].attrs.style, /^pointer-events: all; transform:/);
  assert.deepEqual(value.callbacks, sectionsOf(fixture("baseline.upstream.json")).callbacks);
});

test("normalization cannot collapse two distinct values into one", () => {
  const upstream = normalize(sectionsOf(fixture("baseline.upstream.json")), SORT_RULES).value;
  const psflow = normalize(sectionsOf(fixture("precise-coordinate.psflow.json")), SORT_RULES).value;

  const differences = diffValues(upstream.dom, psflow.dom, ["dom"]);

  // The class-token and declaration-order noise is gone; the layout number the
  // two implementations genuinely disagree about is still here.
  assert.equal(differences.length, 1);
  assert.equal(formatPath(differences[0].path), "dom/root/children/div[0]/children/1/attrs/style");
  assert.match(differences[0].right, /75\.00017302302994px/);
});

test("a duplicated token is not deduplicated away by sorting", () => {
  const rules = [{ kind: "sort", at: "props/**/class", as: "tokens", reason: "test" }];
  const left = normalize({ props: { p: { class: "a a b" } } }, rules).value;
  const right = normalize({ props: { p: { class: "a b" } } }, rules).value;

  assert.notEqual(left.props.p.class, right.props.p.class);
});

test("declarations are left unsorted when a property repeats, because order decides there", () => {
  const rules = [{ kind: "sort", at: "props/**/style", as: "declarations", reason: "test" }];
  const { value } = normalize({ props: { p: { style: "color: red; color: blue;" } } }, rules);

  assert.equal(value.props.p.style, "color: red; color: blue;");
});

test("a rule kind outside delete and sort is a hard error", () => {
  assert.throws(
    () => validateRules([{ kind: "round", at: "dom/**/attrs/style", digits: 3, reason: "float noise" }]),
    /round/
  );
  assert.throws(() => validateRules([{ kind: "sort", at: "dom/**", as: "numerically", reason: "x" }]), /numerically/);
});

test("a rule without a written reason is a hard error", () => {
  assert.throws(() => validateRules([{ kind: "delete", at: "dom/**/attrs/style" }]), /reason/);
});

test("the collapse guard rejects a normalizer that made two distinct values agree", () => {
  const before = { left: { api: { queries: { zoom: 1.03145 } } }, right: { api: { queries: { zoom: 1.05466 } } } };
  const after = { left: { api: { queries: { zoom: 1.03 } } }, right: { api: { queries: { zoom: 1.03 } } } };

  assert.throws(() => assertNoCollapse(before, after), /api\/queries\/zoom/);
});

test("the collapse guard accepts a reorder, which is what makes it a permutation and not a collapse", () => {
  const before = { left: { props: { p: { class: "a b" } } }, right: { props: { p: { class: "b a" } } } };
  const after = { left: { props: { p: { class: "a b" } } }, right: { props: { p: { class: "a b" } } } };

  assert.doesNotThrow(() => assertNoCollapse(before, after));
});
