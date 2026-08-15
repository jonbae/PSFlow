import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";

import { RegistryError, collectFixtures, fixtureRoots } from "./registry.mjs";

// A fixture root is a directory of `.ts` files; the tests build small real ones
// rather than mocking `fs`, because what is under test is how the walk turns a
// path into a route key, and a mock would have to reproduce that to be wrong.
const root = (files) => {
  const dir = mkdtempSync(join(tmpdir(), "psflow-registry-"));
  for (const [name, contents] of Object.entries(files)) {
    mkdirSync(dirname(join(dir, name)), { recursive: true });
    writeFileSync(join(dir, name), contents ?? "export default {};\n");
  }
  return dir;
};

const routes = (fixtures) => fixtures.map((f) => f.route).sort();

test("a route key is the path below its root, the way upstream's glob derives it", () => {
  const dir = root({ "nodes/general.ts": null, "pane/general.ts": null });

  assert.deepEqual(routes(collectFixtures([{ dir }])), ["./nodes/general.ts", "./pane/general.ts"]);
});

test("nested directories keep posix separators whatever the host uses", () => {
  const dir = root({ "edges/deep/nested/general.ts": null });

  assert.deepEqual(routes(collectFixtures([{ dir }])), ["./edges/deep/nested/general.ts"]);
});

test("only `.ts` joins the registry — a fixture's own components are not routes", () => {
  const dir = root({
    "nodes/general.ts": null,
    "nodes/components/DragHandleNode.tsx": null,
    "nodes/general.d.ts": null,
    "README.md": "not a fixture\n",
  });

  assert.deepEqual(routes(collectFixtures([{ dir }])), ["./nodes/general.ts"]);
});

test("two roots merge into one registry", () => {
  const upstream = root({ "nodes/general.ts": null });
  const psflow = root({ "resize/general.ts": null });

  assert.deepEqual(routes(collectFixtures([{ dir: upstream }, { dir: psflow }])), [
    "./nodes/general.ts",
    "./resize/general.ts",
  ]);
});

// The hazard the second root introduces. Two roots are globbed into one flat
// route space, so a PSFlow fixture that happens to sit at a vendored fixture's
// path would silently shadow it — the suite would keep passing while driving
// something else entirely.
test("a route claimed by two roots fails rather than one silently winning", () => {
  const upstream = root({ "nodes/general.ts": null });
  const psflow = root({ "nodes/general.ts": null });

  assert.throws(() => collectFixtures([{ dir: upstream }, { dir: psflow }]), (e) => {
    assert.ok(e instanceof RegistryError);
    assert.match(e.message, /\.\/nodes\/general\.ts/);
    assert.match(e.message, new RegExp(upstream.replace(/[\\^$.*+?()[\]{}|]/g, "\\$&")));
    assert.match(e.message, new RegExp(psflow.replace(/[\\^$.*+?()[\]{}|]/g, "\\$&")));
    return true;
  });
});

test("a missing root fails with the message its caller gave it", () => {
  assert.throws(
    () => collectFixtures([{ dir: join(tmpdir(), "psflow-registry-absent"), missing: "re-vendor xyflow/" }]),
    (e) => e instanceof RegistryError && /re-vendor xyflow\//.test(e.message)
  );
});

// The roots live here rather than in `build.mjs` because the net's corpus
// derives a mount-only baseline per fixture from the same list. Two lists would
// drift into a fixture the page serves and the net never mounts — a hole
// nothing reports, since neither list knows the other exists.
test("the two roots are named once, and their absences mean different things", () => {
  const [vendored, own] = fixtureRoots("/repo");

  assert.equal(vendored.dir, join("/repo", "xyflow/examples/react/src/generic-tests"));
  assert.equal(own.dir, join("/repo", "parity/system/fixtures"));
  assert.match(vendored.missing, /re-vendor/i);
  assert.match(own.missing, /git/i);
});

// A root that is present and empty is legitimate — `parity/system/fixtures/`
// is exactly that until the corpus lands — so emptiness is only a failure in
// the aggregate, where it would mean a page that answers every route with 404.
test("one empty root is fine; every root empty is not", () => {
  const upstream = root({ "nodes/general.ts": null });
  const empty = root({ "README.md": "nothing here yet\n" });

  assert.deepEqual(routes(collectFixtures([{ dir: upstream }, { dir: empty }])), ["./nodes/general.ts"]);
  assert.throws(() => collectFixtures([{ dir: empty }]), RegistryError);
});
