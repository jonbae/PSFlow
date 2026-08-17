import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";

import { baselinePins, tarballUrl, assertVendoredVersions } from "./vendor-baseline.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

const pkg = (devDependencies) => ({ devDependencies });

// A vendored tree, as far as this script is concerned: the two package.json
// files whose `version` fields are the baseline.
function vendoredTree(reactVersion, systemVersion) {
  const dir = mkdtempSync(join(tmpdir(), "psflow-vendor-"));
  for (const [name, version] of [
    ["react", reactVersion],
    ["system", systemVersion],
  ]) {
    mkdirSync(join(dir, "packages", name), { recursive: true });
    writeFileSync(join(dir, "packages", name, "package.json"), JSON.stringify({ version }));
  }
  return dir;
}

test("the pins come from the exact-pinned devDependencies", () => {
  const pins = baselinePins(pkg({ "@xyflow/react": "12.11.0", "@xyflow/system": "0.0.77" }));

  assert.deepEqual(pins, { react: "12.11.0", system: "0.0.77" });
});

// README's baseline section: "Do not add a caret: a floating range would let
// `npm install` drift the declared baseline away from the vendored one without
// any gate noticing." Here the range is worse than a drift — it is what CI
// would resolve the tag from, so a range would make the vendored tree
// unreproducible run to run.
test("a range where an exact pin belongs fails rather than resolving", () => {
  for (const range of ["^12.11.0", "~12.11.0", ">=12.11.0", "12.x", "latest", "*"]) {
    assert.throws(
      () => baselinePins(pkg({ "@xyflow/react": range, "@xyflow/system": "0.0.77" })),
      /exact/i,
      `${range} is not an exact pin`
    );
  }
});

test("a missing pin fails rather than vendoring some default", () => {
  assert.throws(() => baselinePins(pkg({ "@xyflow/system": "0.0.77" })), /@xyflow\/react/);
  assert.throws(() => baselinePins(pkg({ "@xyflow/react": "12.11.0" })), /@xyflow\/system/);
});

// The two `@` and the `/` inside the tag are all path-significant to codeload,
// so the tag is one percent-encoded segment. Asserted as a literal string
// because it is the one line in this script that a typo makes into a 404 at
// exactly the moment CI needs the tree.
test("the tarball URL is the release tag for the pinned react version", () => {
  assert.equal(
    tarballUrl("12.11.0"),
    "https://codeload.github.com/xyflow/xyflow/tar.gz/refs/tags/%40xyflow%2Freact%4012.11.0"
  );
});

// The tag names the react version only. The system version rides along on
// whatever commit that tag points at, and the baseline is *both* — so the tree
// is checked against both pins after it lands rather than trusted because the
// download succeeded.
test("a vendored tree matching both pins is accepted", () => {
  const dir = vendoredTree("12.11.0", "0.0.77");

  assert.deepEqual(assertVendoredVersions(dir, { react: "12.11.0", system: "0.0.77" }), {
    react: "12.11.0",
    system: "0.0.77",
  });
});

test("a vendored tree disagreeing with either pin fails, naming both versions", () => {
  const pins = { react: "12.11.0", system: "0.0.77" };

  assert.throws(() => assertVendoredVersions(vendoredTree("12.11.1", "0.0.77"), pins), /12\.11\.1/);
  assert.throws(() => assertVendoredVersions(vendoredTree("12.11.0", "0.0.78"), pins), /0\.0\.78/);
});

test("a tree that is not there at all fails as loudly as a wrong one", () => {
  const absent = join(tmpdir(), "psflow-vendor-absent");

  assert.throws(() => assertVendoredVersions(absent, { react: "12.11.0", system: "0.0.77" }));
});

// The tests above run against fixtures; this one runs against the repo. It is
// what catches a baseline bump that edited `package.json` into a shape this
// script cannot read — the failure would otherwise wait for CI's next run.
test("the repo's own pins parse", () => {
  const pins = baselinePins(JSON.parse(readFileSync(join(repoRoot, "package.json"), "utf8")));

  assert.match(pins.react, /^\d+\.\d+\.\d+$/);
  assert.match(pins.system, /^\d+\.\d+\.\d+$/);
});
