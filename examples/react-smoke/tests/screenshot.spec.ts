import { test } from "@playwright/test";

// One-off helper: produces parity/driver/dist/smoke.png as a
// visual artifact of the rendered flow. Not a gate — it asserts nothing.
//
// It shoots the fixture the smoke suite's liveness tests mount. That used to be
// `#/smoke`, a PSFlow contract page; the flow moved into
// `parity/system/fixtures/flow/chrome-defaults.ts` when the eight assertions it
// carried retired into the net (issue #61), so the picture is now of the same
// flow through the driver — and of a page upstream mounts too. Run with:
//   npx playwright test --config examples/react-smoke/playwright.config.ts --project=screenshot
test("screenshot", async ({ page }) => {
  await page.setViewportSize({ width: 800, height: 600 });
  await page.goto("/parity/driver/index.html#/tests/generic/flow/chrome-defaults");
  await page.waitForSelector(".react-flow__edge", { timeout: 10_000 });
  await page.waitForTimeout(500);
  await page.screenshot({
    path: "parity/driver/dist/smoke.png",
    fullPage: false,
  });
});
