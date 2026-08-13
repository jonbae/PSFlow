import { test } from "@playwright/test";

// One-off helper: produces parity/driver/dist/smoke.png as a
// visual artifact of the rendered flow. Not a gate — it asserts nothing. Run
// with:
//   npx playwright test --config examples/react-smoke/playwright.config.ts --project=screenshot
test("screenshot", async ({ page }) => {
  await page.setViewportSize({ width: 800, height: 600 });
  await page.goto("/parity/driver/index.html#/smoke");
  await page.waitForSelector(".react-flow__edge", { timeout: 10_000 });
  await page.waitForTimeout(500);
  await page.screenshot({
    path: "parity/driver/dist/smoke.png",
    fullPage: false,
  });
});
