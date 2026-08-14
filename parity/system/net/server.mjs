// The static server the net's two runs load the driver page from (#51).
//
// A server rather than `file://` because the page is an ES module graph and a
// module import from a file URL is a cross-origin request; and this one rather
// than the `http-server` binary the Playwright configs spawn, for one property
// that matters more than the twenty lines it costs: **port 0**. The kernel picks
// a free port and the run reads back which, so the gate cannot collide with a
// dev server, with a Playwright run in another terminal, or with itself.
//
// It serves the repo root, because the driver page reaches out of its own
// directory twice — up to the bundles it imports, and up to the exact-pinned
// `@xyflow/*` stylesheets, which the flow's layout is measured through.

import { createReadStream, statSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join, normalize, resolve, sep } from "node:path";

// A module served as `text/plain` is refused by the browser outright, and a
// stylesheet served as one is ignored *silently* — which would leave the flow
// laid out by nothing and both sides agreeing about it.
const CONTENT_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".map": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
};

/**
 * Resolves a request path against `root`, or null when the result would sit
 * outside it.
 *
 * The URL parser already resolves `..` away, so nothing a browser can send
 * climbs. The check is here so that staying inside the served tree is a
 * property of this file rather than of the parser's current behaviour — the net
 * serves a whole repository, and a request that reached past it would serve a
 * file no trace could explain.
 */
export const resolveRequest = (root, url) => {
  const path = decodeURIComponent(new URL(url, "http://localhost").pathname);
  const target = resolve(root, "." + normalize(path));
  const inside = target === root || target.startsWith(root + sep);
  return inside ? target : null;
};

/**
 * Serves `root` on a kernel-chosen port. Returns `{ origin, close }`.
 *
 * Caching is off: the run rebuilds both bundles immediately before capturing,
 * and a 304 for the bundle that was just replaced would have the gate report on
 * the code it was measuring last time.
 */
export const serveDirectory = async (root) => {
  const served = resolve(root);

  const server = createServer((request, response) => {
    const target = resolveRequest(served, request.url);
    const file = target && statSync(target, { throwIfNoEntry: false })?.isDirectory() ? join(target, "index.html") : target;

    if (!file || !statSync(file, { throwIfNoEntry: false })?.isFile()) {
      response.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
      response.end(`not found: ${request.url}`);
      return;
    }

    response.writeHead(200, {
      "content-type": CONTENT_TYPES[extname(file)] ?? "application/octet-stream",
      "cache-control": "no-store",
    });
    createReadStream(file).pipe(response);
  });

  await new Promise((ready, failed) => {
    server.once("error", failed);
    server.listen(0, "127.0.0.1", ready);
  });

  const { port } = server.address();
  return {
    origin: `http://127.0.0.1:${port}`,
    close: () =>
      new Promise((closed) => {
        server.closeAllConnections?.();
        server.close(closed);
      }),
  };
};
