// The harness's own browser self-test.
//
// Its own config rather than a project inside `examples/react-smoke`'s: that
// file is the example app's, its self-check enumerates its own `tests/`
// directory, and the net is not an example. One Chromium project, because touch
// arrives through CDP — which is precisely what the corpus ticket bought by
// specifying `Input.dispatchTouchEvent` over a second browser target.
//
// This is not `parity:system`. It proves the *harness* drives a real page —
// that a selector resolves to a box, that a gesture moves what it grabs, that
// CDP touch reaches the renderer — and it asserts nothing about ps-flow against
// upstream. The gate that does arrives with `dom` capture (#51).

import { defineConfig, devices } from "@playwright/test";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, "..", "..", "..");

export default defineConfig({
  testDir: here,
  // Explicit, because Playwright's default would also collect this directory's
  // `*.test.mjs` — which are node tests over the fake port and would fail
  // bizarrely under a browser runner.
  testMatch: /\.spec\.mjs$/,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: 0,
  workers: 1,
  reporter: [["list"]],
  use: {
    baseURL: "http://127.0.0.1:5173",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  projects: [{ name: "harness", use: { ...devices["Desktop Chrome"] } }],
  webServer: {
    command: `npx http-server "${repoRoot}" -p 5173 -c-1 --silent`,
    url: "http://127.0.0.1:5173/parity/driver/index.html",
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
