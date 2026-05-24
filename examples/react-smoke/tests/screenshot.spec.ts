import { test } from "@playwright/test";

// One-off helper: produces examples/react-smoke/dist/smoke.png as a
// visual artifact of the rendered flow. Run with:
//   npx playwright test --config examples/react-smoke/playwright.config.ts --grep screenshot
test("screenshot", async ({ page }) => {
  await page.setViewportSize({ width: 800, height: 600 });
  await page.goto("/examples/react-smoke/index.html");
  await page.waitForSelector(".react-flow__edge", { timeout: 10_000 });
  await page.waitForTimeout(500);
  await page.screenshot({
    path: "examples/react-smoke/dist/smoke.png",
    fullPage: false,
  });
});
