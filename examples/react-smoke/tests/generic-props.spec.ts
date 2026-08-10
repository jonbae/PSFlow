// Adopted from xyflow/tests/playwright/e2e/props.spec.ts (the conformance test suite).
// Faithful copy of upstream's framework-parameterized e2e suite; the ONLY
// changes are the infrastructure bits that differ for PSFlow:
//   1. FRAMEWORK is hard-set to 'react' (upstream reads process.env.FRAMEWORK).
//   2. the route is loaded via the static smoke server + hash router
//      ('/examples/react-smoke/index.html#/examples/color-mode') instead of the
//      vite path ('/examples/color-mode'). Unlike the other conformance specs this
//      one hits a bespoke example page, not a generic-test fixture.
import { test, expect } from "@playwright/test";

const FRAMEWORK = "react";
const ROUTE = "/examples/react-smoke/index.html#/examples/color-mode";

test.describe("Props", () => {
  test.describe("colorMode", async () => {
    test("render default light color mode", async ({ page }) => {
      await page.goto(ROUTE);

      await expect(page.locator(`.${FRAMEWORK}-flow__node`).first()).toHaveCSS("visibility", "visible");

      await expect(page.locator(`.${FRAMEWORK}-flow`)).not.toHaveClass(/dark/);
    });

    test("render dark color mode", async ({ page }) => {
      await page.goto(ROUTE);
      await expect(page.locator(`.${FRAMEWORK}-flow__node`).first()).toHaveCSS("visibility", "visible");

      await page.getByTestId("colormode-select").selectOption({ label: "dark" });

      await expect(page.locator(`.${FRAMEWORK}-flow`)).toHaveClass(/dark/);
    });
  });
});
