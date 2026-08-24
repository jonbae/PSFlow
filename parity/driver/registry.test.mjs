import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";

import { RegistryError, collectComponents, collectFixtures, directComponents, fixtureRoots } from "./registry.mjs";

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

// ── The second kind of route ────────────────────────────────────────────

// Written down rather than globbed (`registry.mjs` says what the count refuses),
// but here rather than in `build.mjs` for the same reason the fixture roots are:
// the corpus mounts the example driver too, and a second copy of the list would
// drift into a route the page serves and the net never mounts.
test("the directly mounted components are named once, and each says what it is", () => {
  assert.deepEqual(
    directComponents("/repo").map(({ route, kind }) => [route, kind]),
    [
      ["/examples/color-mode", "example-driver"],
      ["/smoke", "contract"],
      ["/examples/node-props", "contract"],
    ]
  );
});

// A route with no `#` on it, exactly as a fixture's is once `routeOf` has
// flattened it — the build puts the `#` back for the page, which matches a
// directly mounted component on the whole hash.
test("a component route is a hash path with the hash left off", () => {
  for (const { route } of directComponents("/repo")) assert.ok(route.startsWith("/"), route);
});

test("a component whose module is missing fails with the message its entry gave it", () => {
  assert.throws(
    () =>
      collectComponents([
        { route: "/gone", kind: "contract", file: join(tmpdir(), "psflow-absent.tsx"), missing: "restore it from git" },
      ]),
    (e) => e instanceof RegistryError && /restore it from git/.test(e.message)
  );
});

// The corpus reads this field to decide what gets a mount-only baseline, so a
// typo in it would silently drop the example driver out of the net.
test("a component of no known kind fails rather than being routed anyway", () => {
  const dir = root({ "here.tsx": "export default () => null;\n" });

  assert.throws(
    () => collectComponents([{ route: "/x", kind: "fixture", file: join(dir, "here.tsx") }]),
    (e) => e instanceof RegistryError && /example-driver/.test(e.message)
  );
});

test("two components claiming one route fail rather than one silently winning", () => {
  const dir = root({ "here.tsx": "export default () => null;\n" });
  const twice = [
    { route: "/x", kind: "contract", file: join(dir, "here.tsx") },
    { route: "/x", kind: "contract", file: join(dir, "here.tsx") },
  ];

  assert.throws(() => collectComponents(twice), (e) => e instanceof RegistryError && /\/x/.test(e.message));
});
