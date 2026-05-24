import { expect, test } from "@playwright/test";

// Walks the runtime checklist from tickets/053-react-runtime-verification.md.
// Items annotated with `test.skip(...)` are blocked by a 052 follow-up
// — link the issue ID in the skip reason so the gap is auditable.
const APP = "/examples/react-smoke/index.html";

test.describe("ps-flow smoke test", () => {
  test.beforeEach(async ({ page }) => {
    page.on("pageerror", (err) => {
      throw new Error(`pageerror: ${err.message}\n${err.stack ?? ""}`);
    });
    await page.goto(APP);
    // Wait for the outer wrapper to mount — class names come from the
    // upstream stylesheet, not the bundled JS, so this is the earliest
    // proof that React rendered something.
    await page.waitForSelector(".react-flow", { timeout: 10_000 });
  });

  test("two nodes and one edge render", async ({ page }) => {
    const nodes = page.locator(".react-flow__node");
    await expect(nodes).toHaveCount(2);
    const edges = page.locator(".react-flow__edge");
    await expect(edges).toHaveCount(1);
  });

  test("Background renders behind the flow", async ({ page }) => {
    await expect(page.locator(".react-flow__background")).toBeVisible();
  });

  test("MiniMap renders and is clickable", async ({ page }) => {
    const minimap = page.locator(".react-flow__minimap");
    await expect(minimap).toBeVisible();
    // The pan-on-minimap-click interaction itself is a deeper wiring step
    // (handler -> panBy through XYMinimap); the smoke test only verifies
    // the surface here. A future ticket should add a regression for the
    // pan behaviour once handle-drag wiring lands.
    await minimap.click({ position: { x: 50, y: 50 } });
  });

  test("Controls render and clicking zoom-in changes the transform", async ({
    page,
  }) => {
    const controls = page.locator(".react-flow__controls");
    await expect(controls).toBeVisible();
    const zoomIn = page.locator(".react-flow__controls-zoomin");
    const zoomOut = page.locator(".react-flow__controls-zoomout");
    const fitView = page.locator(".react-flow__controls-fitview");
    await expect(zoomIn).toBeVisible();
    await expect(zoomOut).toBeVisible();
    await expect(fitView).toBeVisible();
    const before = await viewportTransform(page);
    await zoomIn.click();
    await page.waitForTimeout(300);
    const after = await viewportTransform(page);
    expect(after).not.toBe(before);
  });

  test("wheel-zoom changes the viewport transform", async ({ page }) => {
    const before = await viewportTransform(page);
    const pane = page.locator(".react-flow__pane").first();
    await pane.hover();
    await page.mouse.wheel(0, -200);
    await page.waitForTimeout(200);
    const after = await viewportTransform(page);
    expect(after).not.toBe(before);
  });

  test("background drag pans the viewport", async ({ page }) => {
    const before = await viewportTransform(page);
    const pane = page.locator(".react-flow__pane").first();
    const box = await pane.boundingBox();
    if (!box) throw new Error("pane has no bounding box");
    const startX = box.x + box.width / 2;
    const startY = box.y + box.height / 2;
    await page.mouse.move(startX, startY);
    await page.mouse.down();
    await page.mouse.move(startX + 100, startY + 50, { steps: 10 });
    await page.mouse.up();
    await page.waitForTimeout(200);
    const after = await viewportTransform(page);
    expect(after).not.toBe(before);
  });

  test("no console errors during a 5-second interaction session", async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on("console", (msg) => {
      if (msg.type() === "error") errors.push(msg.text());
    });
    const pane = page.locator(".react-flow__pane").first();
    await pane.hover();
    await page.mouse.wheel(0, -100);
    await page.locator(".react-flow__controls-zoomout").click();
    await page.locator(".react-flow__controls-fitview").click();
    await page.waitForTimeout(1500);
    expect(errors).toEqual([]);
  });

  // Blocked: node drag requires <Handle> connection-drag wiring (currently
  // a stub in src/React/Handle.purs). See ticket 052 / surrounding
  // discussion before re-enabling.
  test.skip("node drag fires onNodesChange (blocked by Handle wiring)", () => {});

  // Blocked: click-connect needs the same store helpers.
  test.skip("click-connect creates an edge (blocked by Handle wiring)", () => {});
});

// Read the inline transform CSS applied to `.react-flow__viewport`. ReactFlow
// stores pan/zoom as `transform: translate(x, y) scale(z)`; we use the raw
// string for change detection.
async function viewportTransform(page: import("@playwright/test").Page): Promise<string> {
  return await page.evaluate(() => {
    const vp = document.querySelector<HTMLElement>(".react-flow__viewport");
    return vp ? vp.style.transform : "";
  });
}
