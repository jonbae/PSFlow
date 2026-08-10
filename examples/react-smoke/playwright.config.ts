import { defineConfig, devices } from "@playwright/test";
import path from "node:path";
import { fileURLToPath } from "node:url";

// Resolve to the repo root so the static server serves
// `node_modules/@xyflow/react/dist/style.css` (referenced by index.html)
// alongside the bundled example output. `__dirname` isn't defined in
// ESM modules — recover it from `import.meta.url`.
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..", "..");

export default defineConfig({
  testDir: "./tests",
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
  // One project per suite rather than one `chromium` project, because the
  // suites in this directory are not one gate. `--project` is what the split
  // npm scripts select on; every spec file must be matched by exactly one
  // project, or it silently stops running.
  projects: [
    // The conformance test suite — upstream's own framework-parameterized e2e
    // specs, ported. `npm run test:conformance`.
    {
      name: "conformance",
      testMatch: /generic-[\w-]+\.spec\.ts$/,
      use: { ...devices["Desktop Chrome"] },
    },
    // The smoke test suite — liveness plus the hand-authored interaction
    // assertions that have not been retired yet. `npm run test:smoke`.
    {
      name: "smoke",
      testMatch: /(^|[\\/])smoke\.spec\.ts$/,
      use: { ...devices["Desktop Chrome"] },
    },
    // Outside the five-gate scheme. `node-props` is a PSFlow-specific guard
    // that retires when the net's `props` section is green (issue #61);
    // `screenshot` never was a gate and only writes an artifact.
    {
      name: "node-props",
      testMatch: /node-props\.spec\.ts$/,
      use: { ...devices["Desktop Chrome"] },
    },
    {
      name: "screenshot",
      testMatch: /screenshot\.spec\.ts$/,
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: `npx http-server "${repoRoot}" -p 5173 -c-1 --silent`,
    url: "http://127.0.0.1:5173/examples/react-smoke/index.html",
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
