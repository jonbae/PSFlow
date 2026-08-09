// Adopted from xyflow/tests/playwright/e2e/pane.spec.ts.
// Faithful copy of upstream's framework-parameterized e2e suite; the
// ONLY changes are the infrastructure bits that differ for PSFlow:
//   1. FRAMEWORK is hard-set to 'react' (upstream reads process.env.FRAMEWORK).
//   2. routes are loaded via the static server + hash router
//      ('/parity/driver/index.html#/tests/generic/pane/<name>')
//      instead of a vite path ('/tests/generic/pane/<name>').
//   3. getTransform is inlined here (upstream imports it from ./utils).
//
// The page is the TSX driver, with `@xyflow/react` aliased to `index.js` — so
// this spec enters through the JS surface, the door the audience comes
// through, and it mounts upstream's own `pane/general.ts` and
// `pane/non-defaults.ts` unmodified. Run `npm run build:driver` after changing
// `src/` or re-vendoring `xyflow/`.
import { test, expect, type Locator } from "@playwright/test";

const FRAMEWORK = "react";
const ROUTE_GENERAL = "/parity/driver/index.html#/tests/generic/pane/general";
const ROUTE_NON_DEFAULTS = "/parity/driver/index.html#/tests/generic/pane/non-defaults";

const MATCH_ALL_NUMBERS = /[\d\.]+/g;

// Inlined from xyflow/tests/playwright/e2e/utils.ts. Parses translateX/Y + scale
// out of the viewport element's `style.transform` (f.ex "translate(590px, 324px) scale(2)").
async function getTransform(element: Locator) {
  const transformString = await element.evaluate((el) => {
    return (el as HTMLElement).style.transform;
  });

  const transforms = transformString.match(MATCH_ALL_NUMBERS);
  return {
    translateX: parseFloat(transforms![0]),
    translateY: parseFloat(transforms![1]),
    scale: parseFloat(transforms![2]),
  };
}

test.describe("Pane default", () => {
  test.beforeEach(async ({ page }) => {
    // Go to the starting url before each test.
    await page.goto(ROUTE_GENERAL);

    // Wait till the edges are rendered
    await page.waitForSelector('[data-id="first-edge"]', { timeout: 10_000 });
  });

  test.describe("pan & zoom", () => {
    test("panning the pane moves it", async ({ page }) => {
      const pane = page.locator(`.${FRAMEWORK}-flow__pane`);
      const viewport = page.locator(`.${FRAMEWORK}-flow__viewport`);

      await expect(pane).toBeAttached();

      const paneBox = await pane.boundingBox();
      const transformsBefore = await getTransform(viewport);
      const movementPx = 100;

      await pane.hover();
      await page.mouse.down();
      // Move pane by 100, 100
      await page.mouse.move(
        paneBox!.x + paneBox!.width * 0.5 + movementPx,
        paneBox!.y + paneBox!.height * 0.5 + movementPx
      );

      const transformsAfter = await getTransform(viewport);

      // Deviation from upstream: round the translate delta to whole pixels before
      // the `movementPx - delta < 1` check (upstream floors the raw delta). The pane
      // pans in screen space so the delta is integral, but IEEE-754 subtraction makes
      // it *look* fractional: our fitView puts translateY at 157.131 and
      // `257.131 - 157.131 === 99.99999999999997`, so `Math.floor` yields 99 and the
      // assertion fails despite an exact 100px pan. (translateX, 390.571 -> 490.571,
      // subtracts cleanly and passes upstream-verbatim.) Rounding preserves the
      // "pane moved by ~movementPx" intent without the float artifact.
      const deltaX = Math.round(transformsAfter.translateX - transformsBefore.translateX);
      const deltaY = Math.round(transformsAfter.translateY - transformsBefore.translateY);

      expect(movementPx - deltaX).toBeLessThan(1);
      expect(movementPx - deltaY).toBeLessThan(1);
    });

    test("scrolling the default pane zooms it", async ({ page }) => {
      const pane = page.locator(`.${FRAMEWORK}-flow__pane`);
      const viewport = page.locator(`.${FRAMEWORK}-flow__viewport`);

      await expect(pane).toBeAttached();

      const transformsBefore = await getTransform(viewport);

      await pane.hover();
      await page.mouse.wheel(0, 100);

      const transformsAfter = await getTransform(viewport);

      expect(transformsAfter.scale).not.toBe(transformsBefore.scale);
    });
  });

  test.describe("minZoom & maxZoom", () => {
    test("minZoom", async ({ page }) => {
      const pane = page.locator(`.${FRAMEWORK}-flow__pane`);
      const viewport = page.locator(`.${FRAMEWORK}-flow__viewport`);

      await expect(pane).toBeAttached();

      await pane.hover();

      // Zoom out
      await page.mouse.wheel(5000, 5000);

      const transformsMinZoom = await getTransform(viewport);
      expect(transformsMinZoom.scale).toBe(0.25);
    });

    test("maxZoom", async ({ page }) => {
      const pane = page.locator(`.${FRAMEWORK}-flow__pane`);
      const viewport = page.locator(`.${FRAMEWORK}-flow__viewport`);

      await expect(pane).toBeAttached();

      await pane.hover();

      // Zoom in
      await page.mouse.wheel(-5000, -5000);

      const transformsMaxZoom = await getTransform(viewport);
      expect(transformsMaxZoom.scale).toBe(4);
    });
  });

  test.describe("autoPan", () => {
    test("autoPanOnNodeDrag", async ({ page }) => {
      const viewport = page.locator(`.${FRAMEWORK}-flow__viewport`);
      const node = page.locator('[data-id="1"]');

      await expect(node).toBeAttached();

      const transformBefore = await getTransform(viewport);

      await node.hover();
      await page.mouse.down();
      await page.mouse.move(0, 0);
      await page.waitForTimeout(500);
      await page.mouse.move(2000, 2000, { steps: 100 });
      await page.mouse.up();

      const transformAfter = await getTransform(viewport);

      await expect(transformAfter.translateX).not.toEqual(transformBefore.translateX);
      await expect(transformAfter.translateY).not.toEqual(transformBefore.translateY);
    });

    test("autoPanOnConnect", async ({ page }) => {
      const viewport = page.locator(`.${FRAMEWORK}-flow__viewport`);
      const handle = page.locator(`[data-id="1"] .${FRAMEWORK}-flow__handle`);

      await expect(handle).toBeAttached();

      const transformBefore = await getTransform(viewport);

      await handle.hover();
      await page.mouse.down();
      await page.mouse.move(0, 0);
      await page.waitForTimeout(500);
      await page.mouse.move(100, 100, { steps: 100 });

      const transformAfter = await getTransform(viewport);

      await expect(transformAfter.translateX).not.toEqual(transformBefore.translateX);
      await expect(transformAfter.translateY).not.toEqual(transformBefore.translateY);
    });
  });
});

test.describe("Pane non-default", () => {
  test.beforeEach(async ({ page }) => {
    // Go to the starting url before each test.
    await page.goto(ROUTE_NON_DEFAULTS);

    // Wait till the edges are rendered
    await page.waitForSelector('[data-id="first-edge"]', { timeout: 10_000 });
  });

  test.describe("pan & zoom", () => {
    test("panOnScroll pans the pane on scrolling", async ({ page }) => {
      const pane = page.locator(`.${FRAMEWORK}-flow__pane`);
      const viewport = page.locator(`.${FRAMEWORK}-flow__viewport`);

      await expect(pane).toBeAttached();

      const transformsBefore = await getTransform(viewport);

      await pane.hover();
      await page.mouse.wheel(100, 100);

      const transformsAfter = await getTransform(viewport);

      expect(transformsAfter.translateX).not.toBe(transformsBefore.translateX);
      expect(transformsAfter.translateY).not.toBe(transformsBefore.translateY);
    });

    test("intialViewport", async ({ page }) => {
      const pane = page.locator(`.${FRAMEWORK}-flow__pane`);
      const viewport = page.locator(`.${FRAMEWORK}-flow__viewport`);

      await expect(pane).toBeAttached();

      const viewportTransform = await getTransform(viewport);

      expect(viewportTransform.translateX).toBe(1.23);
      expect(viewportTransform.translateY).toBe(9.87);
      expect(viewportTransform.scale).toBe(1.234);
    });
  });
});
