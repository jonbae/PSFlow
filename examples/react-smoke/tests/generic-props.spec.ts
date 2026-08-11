// Adopted from xyflow/tests/playwright/e2e/props.spec.ts (the conformance test suite).
// Faithful copy of upstream's framework-parameterized e2e suite; the ONLY
// changes are the two infrastructure bits that differ for PSFlow:
//   1. FRAMEWORK is hard-set to 'react' (upstream reads process.env.FRAMEWORK).
//   2. the route is loaded via the static server + hash router
//      ('/parity/driver/index.html#/examples/color-mode') instead of a vite
//      path ('/examples/color-mode').
//
// Unlike the other four conformance specs this one does not drive a
// generic-test fixture: upstream has no props fixture, and its own props spec
// points at its `examples/ColorMode` page. So the driver page carries that
// page too, as a second **driver** — upstream's `ColorMode/index.tsx`
// imported unmodified, with `@xyflow/react` aliased to `index.js`, so this
// spec enters through the JS surface with the rest of the suite. Run
// `npm run build:driver` after changing `src/` or re-vendoring `xyflow/`.
import { test, expect } from "@playwright/test";

const FRAMEWORK = "react";
const ROUTE = "/parity/driver/index.html#/examples/color-mode";

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
