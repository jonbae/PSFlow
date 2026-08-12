import { test } from "node:test";
import assert from "node:assert/strict";

import { DisagreementError, mustAgree } from "./agreement.mjs";

const readings = (leftNames, rightNames) => ({
  about: "index.js and the boundary manifest name different surfaces.",
  left: { label: "exported", names: leftNames },
  right: { label: "in the manifest", names: rightNames },
  remedy: "Update `manifest.crossed` in src/Boundary.js.",
});

test("two readings that name the same surface agree, whatever the order", () => {
  assert.doesNotThrow(() => mustAgree(readings(["b", "a"], ["a", "b"])));
  assert.doesNotThrow(() => mustAgree(readings([], [])));
});

test("a name on one side only is a disagreement", () => {
  assert.throws(() => mustAgree(readings(["a", "b"], ["a"])), DisagreementError);
  assert.throws(() => mustAgree(readings(["a"], ["a", "b"])), DisagreementError);
});

test("the message names both sides, so it says which reading to go and fix", () => {
  assert.throws(
    () => mustAgree(readings(["a", "gone"], ["a", "surplus"])),
    (e) => {
      assert.match(e.message, /index\.js and the boundary manifest name different surfaces\./);
      assert.match(e.message, /exported but not in the manifest: gone/);
      assert.match(e.message, /in the manifest but not exported: surplus/);
      assert.match(e.message, /Update `manifest\.crossed` in src\/Boundary\.js\./);
      return true;
    }
  );
});

test("a side that agrees is left out of the message rather than printed empty", () => {
  assert.throws(
    () => mustAgree(readings(["a", "gone"], ["a"])),
    (e) => {
      assert.match(e.message, /exported but not in the manifest: gone/);
      assert.doesNotMatch(e.message, /in the manifest but not exported/);
      return true;
    }
  );
});

test("names are listed sorted, so the same disagreement reads the same way twice", () => {
  assert.throws(
    () => mustAgree(readings(["b", "a", "c"], [])),
    (e) => {
      assert.match(e.message, /exported but not in the manifest: a, b, c/);
      return true;
    }
  );
});
