import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { SIDES } from "./sides.mjs";

const here = dirname(fileURLToPath(import.meta.url));

// `index.html` is the one place a side is named that cannot import the list —
// it is a browser page, and its `?side=` switch is a literal object. So the
// list is held to it from here instead.
//
// The two ways they can disagree are both recoverable but neither is obvious
// from a failing run: a side the page does not know renders an error page, and
// a side only the page knows asks for a bundle nothing builds.
test("the driver page imports a bundle for each side, and for no other", () => {
  const html = readFileSync(join(here, "index.html"), "utf8");
  const imported = [...html.matchAll(/\.\/dist\/([\w-]+)\.js/g)].map((m) => m[1]);

  assert.deepEqual([...new Set(imported)].sort(), [...SIDES].sort());
});

test("the page defaults to a side that exists", () => {
  const html = readFileSync(join(here, "index.html"), "utf8");
  const [, fallback] = html.match(/get\("side"\) \?\? "([\w-]+)"/) ?? [];

  assert.ok(SIDES.includes(fallback), `the page falls back to ${JSON.stringify(fallback)}`);
});
