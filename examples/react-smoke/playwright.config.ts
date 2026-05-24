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
  projects: [
    {
      name: "chromium",
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
