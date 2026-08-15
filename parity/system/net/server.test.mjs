import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

import { resolveRequest, serveDirectory } from "./server.mjs";

const root = () => {
  const dir = mkdtempSync(join(tmpdir(), "psflow-serve-"));
  mkdirSync(join(dir, "parity/driver/dist"), { recursive: true });
  writeFileSync(join(dir, "parity/driver/index.html"), "<!doctype html>\n");
  writeFileSync(join(dir, "parity/driver/dist/psflow.js"), "export default 1;\n");
  return resolve(dir);
};

// Whatever a request says, the file it names is under the served root. `..`
// resolves away in the URL parser, encoded or not, and what is left cannot
// climb; the check in `resolveRequest` is what makes that a property of this
// file rather than of the parser's current behaviour.
test("no request names a file outside the served root", () => {
  const dir = root();

  assert.equal(resolveRequest(dir, "/parity/driver/index.html"), join(dir, "parity/driver/index.html"));
  assert.equal(resolveRequest(dir, "/parity/driver/../driver/index.html"), join(dir, "parity/driver/index.html"));

  for (const climb of ["/../../etc/passwd", "/%2e%2e/%2e%2e/etc/passwd", "/parity/../../../etc/passwd"]) {
    const resolved = resolveRequest(dir, climb);
    assert.ok(resolved === null || resolved.startsWith(dir + "/"), `${climb} escaped to ${resolved}`);
  }
});

// A module served as `text/plain` is refused outright; a stylesheet served as
// one is ignored **silently**, which would leave the flow laid out by nothing
// and both sides agreeing about it.
test("a bundle is served as a module, and a missing file is a 404 rather than a hang", async () => {
  const server = await serveDirectory(root());

  try {
    const bundle = await fetch(`${server.origin}/parity/driver/dist/psflow.js`);
    assert.equal(bundle.status, 200);
    assert.match(bundle.headers.get("content-type"), /text\/javascript/);
    assert.equal(await bundle.text(), "export default 1;\n");

    const page = await fetch(`${server.origin}/parity/driver/index.html`);
    assert.match(page.headers.get("content-type"), /text\/html/);

    assert.equal((await fetch(`${server.origin}/parity/driver/dist/upstream.js`)).status, 404);
  } finally {
    await server.close();
  }
});

// The run rebuilds both bundles immediately before capturing, and a cached copy
// of the one that was just replaced would have the gate report on the code it
// measured last time.
test("nothing is cached, because the bundles were rewritten a second ago", async () => {
  const server = await serveDirectory(root());

  try {
    const response = await fetch(`${server.origin}/parity/driver/dist/psflow.js`);
    assert.equal(response.headers.get("cache-control"), "no-store");
  } finally {
    await server.close();
  }
});

// Port 0 is why this exists rather than the `http-server` binary: the kernel
// picks, so the gate cannot collide with a dev server, with a Playwright run in
// another terminal, or with itself.
test("two servers can run at once, because neither chose its port", async () => {
  const [a, b] = await Promise.all([serveDirectory(root()), serveDirectory(root())]);

  try {
    assert.notEqual(a.origin, b.origin);
  } finally {
    await Promise.all([a.close(), b.close()]);
  }
});
