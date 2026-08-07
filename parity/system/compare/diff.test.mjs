import { test } from "node:test";
import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { readTrace } from "../trace-format.mjs";
import { diffValues, formatPath } from "./diff.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const fixture = (name) => readTrace(join(here, "fixtures", name));

const upstream = () => fixture("baseline.upstream.json");
const reordered = () => fixture("reordered.psflow.json");

const domOf = (trace) => trace.sections.dom;

test("two identical traces produce no differences", () => {
  assert.deepEqual(diffValues(domOf(upstream()), domOf(fixture("baseline.psflow.json")), ["dom"]), []);
});

test("reordering nodes yields one keyed order difference, not a positional shift", () => {
  const differences = diffValues(domOf(upstream()), domOf(reordered()), ["dom"]);

  assert.equal(differences.length, 1, `expected one difference, got ${differences.length}`);
  const [only] = differences;
  assert.equal(only.kind, "order");
  assert.deepEqual(only.left, ["1", "2"]);
  assert.deepEqual(only.right, ["2", "1"]);
  assert.equal(formatPath(only.path), "dom/root/children/div[0]/children");
});

test("positional comparison of the same pair shifts — the reason keying exists", () => {
  const positional = diffValues(domOf(upstream()), domOf(reordered()), ["dom"], { keyed: false });
  assert.ok(positional.length >= 6, `expected a positional shift, got ${positional.length} differences`);
});

test("a real change under a reorder still goes red", () => {
  const perturbed = reordered();
  perturbed.sections.dom.root.children[0].children[0].attrs.style =
    "z-index: 0; transform: translate(100px, 126px); pointer-events: all; visibility: visible;";

  const differences = diffValues(domOf(upstream()), domOf(perturbed), ["dom"]);
  const changed = differences.filter((d) => d.kind === "changed");

  assert.equal(differences.length, 2);
  assert.equal(changed.length, 1);
  assert.equal(formatPath(changed[0].path), "dom/root/children/div[0]/children/2/attrs/style");
});

test("an element present on one side only is reported as one difference, keyed", () => {
  const extra = reordered();
  extra.sections.dom.root.children[0].children.push({
    tag: "div",
    attrs: { class: "react-flow__node", "data-id": "3" },
    children: [],
  });

  const differences = diffValues(domOf(upstream()), domOf(extra), ["dom"]);
  const rightOnly = differences.filter((d) => d.kind === "right-only");

  assert.equal(rightOnly.length, 1);
  assert.equal(formatPath(rightOnly[0].path), "dom/root/children/div[0]/children/3");
});

test("callbacks compare as a sequence — position is the identity there", () => {
  const swapped = fixture("baseline.psflow.json");
  swapped.sections.callbacks.reverse();

  const differences = diffValues(upstream().sections.callbacks, swapped.sections.callbacks, ["callbacks"]);

  assert.ok(differences.length > 0, "a reordered callback log must not compare equal");
  assert.ok(differences.every((d) => d.kind !== "order"));
});

test("a missing object member and an extra one are distinct kinds", () => {
  const left = { a: 1, b: 2 };
  const right = { a: 1, c: 3 };
  const differences = diffValues(left, right, ["props"]);

  assert.deepEqual(
    differences.map((d) => [formatPath(d.path), d.kind]),
    [
      ["props/b", "left-only"],
      ["props/c", "right-only"],
    ]
  );
});

test("path segments carrying a slash survive rendering", () => {
  const differences = diffValues({ "a/b": 1 }, { "a/b": 2 }, ["api", "queries"]);
  assert.equal(formatPath(differences[0].path), "api/queries/a~1b");
});
