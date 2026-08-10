// Adopted from xyflow/tests/playwright/e2e/node-toolbar.spec.ts (the conformance test suite).
// Faithful copy of upstream's framework-parameterized e2e suite; the ONLY
// changes are the infrastructure bits that differ for PSFlow:
//   1. FRAMEWORK is hard-set to 'react' (upstream reads process.env.FRAMEWORK).
//   2. the route is loaded via the static smoke server + hash router
//      ('/examples/react-smoke/index.html#/tests/generic/node-toolbar/general')
//      instead of a vite path ('/tests/generic/node-toolbar/general').
//   3. the beforeEach waitForSelector timeout is bumped to 10s for the static server.
import { test, expect } from "@playwright/test";

const FRAMEWORK = "react";
const ROUTE = "/examples/react-smoke/index.html#/tests/generic/node-toolbar/general";

type Position = "top" | "right" | "bottom" | "left";
const positions: Position[] = ["top", "right", "bottom", "left"];

type Alignment = "start" | "center" | "end";
const alignments: Alignment[] = ["start", "center", "end"];
type Permutation = {
  id: string;
  position: Position;
  align: Alignment;
};
const permutations: Permutation[] = [];

positions.forEach((position) => {
  alignments.forEach((align) => {
    permutations.push({
      id: `node-${align}-${position}`,
      position,
      align,
    });
  });
});

test.describe("Node Toolbar", async () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(ROUTE);
    // Wait till the edges are rendered
    await page.waitForSelector('[data-id="first-edge"]', { timeout: 10_000 });
  });

  test("all toolbars are positioned correctly", async ({ page }) => {
    const tests = permutations.map((permutation) => async () => {
      const toolbar = page
        .locator(`[data-id="${permutation.id}"]`)
        .and(page.locator(`.${FRAMEWORK}-flow__node-toolbar`));
      const node = page.locator(`[data-id="${permutation.id}"]`).and(page.locator(`.${FRAMEWORK}-flow__node`));

      await expect(toolbar).toBeAttached({ timeout: 5000 });
      await expect(node).toBeAttached({ timeout: 5000 });

      const toolbarBox = await toolbar.boundingBox();
      const nodeBox = await node.boundingBox();

      switch (permutation.position) {
        case "top":
          expect(toolbarBox!.y).toBeLessThan(nodeBox!.y);
          break;
        case "right":
          expect(toolbarBox!.x).toBeGreaterThan(nodeBox!.x);
          break;
        case "bottom":
          expect(toolbarBox!.y).toBeGreaterThan(nodeBox!.y);
          break;
        case "left":
          expect(toolbarBox!.x).toBeLessThan(nodeBox!.x);
          break;
      }

      const dimension = permutation.position === "top" || permutation.position === "bottom" ? "x" : "y";
      const extent = permutation.position === "top" || permutation.position === "bottom" ? "width" : "height";

      switch (permutation.align) {
        case "start":
          expect(Math.floor(toolbarBox![dimension])).toBe(Math.floor(nodeBox![dimension]));
          break;
        case "center":
          expect(Math.floor(toolbarBox![dimension] + toolbarBox![extent] * 0.5)).toBe(
            Math.floor(nodeBox![dimension] + nodeBox![extent] * 0.5)
          );
          break;
        case "end":
          expect(Math.floor(toolbarBox![dimension] + toolbarBox![extent])).toBe(
            Math.floor(nodeBox![dimension] + nodeBox![extent])
          );
          break;
      }
    });
    await Promise.all(tests.map((t) => t()));
  });

  test("toolbar default behaviour", async ({ page }) => {
    const node = page.locator('[data-id="default-node"]').and(page.locator(`.${FRAMEWORK}-flow__node`));
    const toolbar = page.locator('[data-id="default-node"]').and(page.locator(`.${FRAMEWORK}-flow__node-toolbar`));

    await expect(node).toBeAttached();
    await expect(toolbar).not.toBeAttached();

    await node.click();
    await expect(toolbar).toBeAttached();
  });
});
