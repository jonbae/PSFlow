import { test } from "node:test";
import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { readTrace } from "../trace-format.mjs";
import { diffValues } from "./diff.mjs";
import { formatPath } from "./paths.mjs";
import { claimDifferences, recordRegions, validateRegions } from "./regions.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const fixture = (name) => readTrace(join(here, "fixtures", name));

// Two differences, deliberately of different kinds: a style value the two sides
// genuinely disagree about, and a class-token ordering.
const differences = () =>
  diffValues(fixture("baseline.upstream.json").sections.dom, fixture("precise-coordinate.psflow.json").sections.dom, [
    "dom",
  ]);

const region = (over) => ({
  id: "layout-float-drift",
  kind: "known-divergence",
  reason: "PSFlow's layout math accumulates 1.7e-4 where upstream lands on whole pixels",
  ticket: "https://github.com/jonbae/PSFlow/issues/22",
  affirmedAgainst: "12.11.0",
  scenario: "*",
  path: "dom/**/attrs/style",
  recorded: [],
  ...over,
});

const recordingOf = (differences) =>
  differences.map((d) => ({ path: formatPath(d.path), kind: d.kind, left: d.left, right: d.right }));

test("a region claims what its pattern says and no more", () => {
  const all = differences();
  const styleDifferences = all.filter((d) => d.path.at(-1) === "style");
  const { claims, unclaimed } = claimDifferences(all, [region({ recorded: recordingOf(styleDifferences) })], {
    scenario: "mount-baseline--nodes-general",
  });

  assert.equal(claims.get("layout-float-drift").length, styleDifferences.length);
  assert.deepEqual(
    unclaimed.map((d) => d.path.at(-1)),
    ["class"]
  );
});

test("an empty region fails as stale", () => {
  const { outcomes } = claimDifferences(differences(), [region({ path: "dom/**/attrs/data-nothing" })], {
    scenario: "mount-baseline--nodes-general",
  });

  assert.equal(outcomes[0].status, "stale");
});

test("a region scoped to another scenario claims nothing here", () => {
  const { outcomes, unclaimed } = claimDifferences(differences(), [region({ scenario: "drag-node-release" })], {
    scenario: "mount-baseline--nodes-general",
  });

  assert.equal(outcomes[0].status, "stale");
  assert.equal(unclaimed.length, 2);
});

test("a region whose content moved fails, so the bump has to re-affirm it", () => {
  const all = differences();
  const stale = recordingOf(all.filter((d) => d.path.at(-1) === "style")).map((r) => ({ ...r, right: "something else" }));
  const { outcomes } = claimDifferences(all, [region({ recorded: stale })], {
    scenario: "mount-baseline--nodes-general",
  });

  assert.equal(outcomes[0].status, "moved");
});

test("a region whose recording still matches rides free", () => {
  const all = differences();
  const { outcomes } = claimDifferences(all, [region({ recorded: recordingOf(all.filter((d) => d.path.at(-1) === "style")) })], {
    scenario: "mount-baseline--nodes-general",
  });

  assert.equal(outcomes[0].status, "rides-free");
});

test("a difference is claimed by exactly one region — the first whose pattern matches", () => {
  const all = differences();
  const first = region({ id: "first", path: "dom/**/attrs/*" });
  const second = region({ id: "second", path: "dom/**/attrs/style" });
  const { claims, outcomes } = claimDifferences(all, [first, second], { scenario: "mount-baseline--nodes-general" });

  assert.equal(claims.get("first").length, 2);
  assert.equal(claims.get("second").length, 0);
  assert.equal(outcomes.find((o) => o.region.id === "second").status, "stale");
});

test("re-recording cannot create a region", () => {
  const all = differences();
  const regions = [region({ path: "dom/**/attrs/style", recorded: [] })];
  const claimed = claimDifferences(all, regions, { scenario: "mount-baseline--nodes-general" });

  const rerecorded = recordRegions(regions, claimed, { baseline: "12.11.0" });

  assert.equal(rerecorded.length, 1, "the class difference must not have become a region");
  const after = claimDifferences(all, rerecorded, { scenario: "mount-baseline--nodes-general" });
  assert.equal(after.unclaimed.length, 1);
  assert.equal(after.unclaimed[0].path.at(-1), "class");
});

test("re-recording refreshes a moved region's values and the baseline it was affirmed against", () => {
  const all = differences();
  const regions = [region({ recorded: [{ path: "dom/x", kind: "changed", left: "a", right: "b" }] })];
  const claimed = claimDifferences(all, regions, { scenario: "mount-baseline--nodes-general" });

  const rerecorded = recordRegions(regions, claimed, { baseline: "12.12.0" });

  assert.equal(rerecorded[0].affirmedAgainst, "12.12.0");
  assert.deepEqual(rerecorded[0].recorded, recordingOf(all.filter((d) => d.path.at(-1) === "style")));
  assert.equal(claimDifferences(all, rerecorded, { scenario: "mount-baseline--nodes-general" }).outcomes[0].status, "rides-free");
});

test("a known divergence without a ticket is a hard error", () => {
  assert.throws(() => validateRegions([region({ ticket: undefined })]), /ticket/);
});

test("an intentional region needs no ticket but still needs a reason", () => {
  assert.doesNotThrow(() => validateRegions([region({ kind: "intentional", ticket: undefined })]));
  assert.throws(() => validateRegions([region({ kind: "intentional", ticket: undefined, reason: "" })]), /reason/);
});

test("a region kind outside the two is a hard error, and so is a duplicate id", () => {
  assert.throws(() => validateRegions([region({ kind: "temporary" })]), /temporary/);
  assert.throws(() => validateRegions([region(), region()]), /layout-float-drift/);
});
