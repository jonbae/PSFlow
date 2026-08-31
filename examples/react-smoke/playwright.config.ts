import { defineConfig, devices } from "@playwright/test";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { readdirSync } from "node:fs";

// Resolve to the repo root so the static server serves
// `node_modules/@xyflow/react/dist/style.css` (referenced by index.html)
// alongside the bundled driver output. `__dirname` isn't defined in
// ESM modules — recover it from `import.meta.url`.
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..", "..");
const testDir = path.join(__dirname, "tests");

// One project per suite rather than one `chromium` project, because the specs
// in this directory are not one gate. `--project` is what the split npm
// scripts select on.
const chrome = { ...devices["Desktop Chrome"] };
const suites = [
  // The conformance test suite — upstream's own framework-parameterized e2e
  // specs, ported. `npm run test:conformance`.
  { name: "conformance", testMatch: /generic-[\w-]+\.spec\.ts$/, use: chrome },
  // The smoke test suite — liveness, and since issue #61 nothing else: its
  // eight hand-authored parity assertions retired into the net, per test.
  // `npm run test:smoke`.
  { name: "smoke", testMatch: /(^|[\\/])smoke\.spec\.ts$/, use: chrome },
  // Outside the five-gate scheme, and never was a gate: `screenshot` asserts
  // nothing at all and only writes an artifact. A `node-props` project stood
  // beside it until that PSFlow-specific guard retired on the net's `props`
  // section (issue #61).
  { name: "screenshot", testMatch: /screenshot\.spec\.ts$/, use: chrome },
];

// A spec matched by no project silently stops running, and one matched by two
// runs twice — both of which a green report is indistinguishable from. Neither
// Playwright nor any other gate would say so, and the split above is exactly
// the edit that introduces the risk, so it checks itself. This throws before
// any suite starts, which is the loud failure the alternative lacks.
for (const spec of readdirSync(testDir).filter((f) => f.endsWith(".spec.ts"))) {
  const hits = suites.filter((s) => s.testMatch.test(path.join(testDir, spec)));
  if (hits.length !== 1) {
    throw new Error(
      `playwright.config.ts: ${spec} is matched by ${hits.length} projects` +
        (hits.length ? ` (${hits.map((h) => h.name).join(", ")})` : "") +
        `; every spec must belong to exactly one.`
    );
  }
}

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
  projects: suites,
  webServer: {
    command: `npx http-server "${repoRoot}" -p 5173 -c-1 --silent`,
    url: "http://127.0.0.1:5173/parity/driver/index.html",
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
