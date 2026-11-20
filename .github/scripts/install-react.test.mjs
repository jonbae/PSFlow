import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";

import { assertAdmitted, assertInstalled, caretFloor, satisfiesCaret } from "./install-react.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

const peers = (range) => ({ peerDependencies: { react: range, "react-dom": range } });

// An install, as far as this script reads one: the two installed manifests and
// the lockfile's entries for them.
function installTree({ react, reactDom, lockedReact = react, lockedReactDom = reactDom }) {
  const dir = mkdtempSync(join(tmpdir(), "psflow-react-"));
  for (const [name, version] of [
    ["react", react],
    ["react-dom", reactDom],
  ]) {
    mkdirSync(join(dir, "node_modules", name), { recursive: true });
    writeFileSync(join(dir, "node_modules", name, "package.json"), JSON.stringify({ version }));
  }
  writeFileSync(
    join(dir, "package-lock.json"),
    JSON.stringify({
      packages: {
        "node_modules/react": { version: lockedReact },
        "node_modules/react-dom": { version: lockedReactDom },
      },
    })
  );
  return dir;
}

test("a caret range's floor is the release it names", () => {
  assert.equal(caretFloor("^18.3.0"), "18.3.0");
  assert.equal(caretFloor("^0.0.77"), "0.0.77");
});

// The CI matrix is built from the floor, so a range this script would have to
// interpret is a range whose legs nobody chose.
test("a range of any other shape is refused rather than interpreted", () => {
  for (const range of [
    "~18.3.0",
    ">=18.3.0",
    "18.3.0",
    "18.x",
    "^18.3",
    "^18",
    "^18.3.0-rc.1",
    "^18.3.0 || ^19.0.0",
    ">=17",
    "*",
    "latest",
    undefined,
  ]) {
    assert.throws(() => caretFloor(range), /\^X\.Y\.Z/, `${range} is not read`);
  }
});

test("the caret admits the floor and later releases of the same major", () => {
  for (const version of ["18.3.0", "18.3.1", "18.4.0", "18.99.99"]) {
    assert.ok(satisfiesCaret(version, "^18.3.0"), `${version} is within ^18.3.0`);
  }
  for (const version of ["18.2.0", "18.0.0", "17.0.2", "19.0.0"]) {
    assert.ok(!satisfiesCaret(version, "^18.3.0"), `${version} is outside ^18.3.0`);
  }
});

test("below 1.0.0 the caret holds the leftmost nonzero part fixed, as npm's does", () => {
  assert.ok(satisfiesCaret("0.3.9", "^0.3.1"));
  assert.ok(!satisfiesCaret("0.4.0", "^0.3.1"));
  assert.ok(satisfiesCaret("0.0.3", "^0.0.3"));
  assert.ok(!satisfiesCaret("0.0.4", "^0.0.3"));
});

test("a release both peer ranges admit is accepted", () => {
  assert.deepEqual(assertAdmitted(peers("^18.3.0"), "18.3.0"), { react: "^18.3.0", "react-dom": "^18.3.0" });
  assert.doesNotThrow(() => assertAdmitted(peers("^18.3.0"), "18.3.1"));
});

test("a release outside a peer range is refused, before anything installs", () => {
  assert.throws(() => assertAdmitted(peers("^18.3.0"), "17.0.2"), /react 17\.0\.2 is outside/);
  assert.throws(() => assertAdmitted(peers("^18.3.0"), "19.0.0"), /react 19\.0\.0 is outside/);
  assert.throws(() => assertAdmitted(peers("^18.3.0"), "18.2.0"), /outside/);
  assert.throws(
    () => assertAdmitted({ peerDependencies: { react: "^18.3.0", "react-dom": "^18.3.1" } }, "18.3.0"),
    /react-dom 18\.3\.0 is outside the declared peer range \^18\.3\.1/
  );
});

test("a version that is not one exact release is refused", () => {
  for (const version of ["18.3", "^18.3.0", "18.3.0-rc.1", "latest", "", undefined]) {
    assert.throws(() => assertAdmitted(peers("^18.3.0"), version), /exact/, `${version} is refused`);
  }
});

test("a missing peer is refused rather than taken as unconstrained", () => {
  assert.throws(() => assertAdmitted({ peerDependencies: { react: "^18.3.0" } }, "18.3.0"), /react-dom/);
  assert.throws(() => assertAdmitted({}, "18.3.0"), /react/);
});

test("an install where all four places report the release is accepted", () => {
  const found = assertInstalled(installTree({ react: "18.3.0", reactDom: "18.3.0" }), "18.3.0");

  assert.equal(found.length, 4);
  assert.ok(found.every(([, version]) => version === "18.3.0"));
});

// The read-back is the evidence that the leg ran the release it is named for,
// so each place it reads must be able to fail it on its own.
test("an install where any one place reports another release fails, naming it", () => {
  const cases = [
    [{ react: "18.3.1", reactDom: "18.3.0", lockedReact: "18.3.0" }, /node_modules\/react is 18\.3\.1/],
    [{ react: "18.3.0", reactDom: "18.3.1", lockedReactDom: "18.3.0" }, /node_modules\/react-dom is 18\.3\.1/],
    [{ react: "18.3.0", reactDom: "18.3.0", lockedReact: "18.3.1" }, /package-lock\.json's node_modules\/react is 18\.3\.1/],
    [
      { react: "18.3.0", reactDom: "18.3.0", lockedReactDom: "18.3.1" },
      /package-lock\.json's node_modules\/react-dom is 18\.3\.1/,
    ],
  ];

  for (const [tree, message] of cases) {
    assert.throws(() => assertInstalled(installTree(tree), "18.3.0"), message);
  }
});

// The tests above run against fixtures; this one runs against the repo, so a
// range edited into a shape the script cannot read fails here rather than in
// CI's install step.
test("the repo's own peer ranges parse, and admit its pinned devDependencies", () => {
  const pkg = JSON.parse(readFileSync(join(repoRoot, "package.json"), "utf8"));

  for (const name of ["react", "react-dom"]) {
    assert.match(caretFloor(pkg.peerDependencies[name]), /^\d+\.\d+\.\d+$/);
    assert.doesNotThrow(() => assertAdmitted(pkg, pkg.devDependencies[name]));
  }
});
