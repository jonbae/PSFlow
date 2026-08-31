import { expect, test } from "@playwright/test";

// The smoke test suite — **liveness, and nothing else** (issue #61).
//
// It used to be ten tests: two liveness ones and eight hand-authored parity
// assertions, which were the densest such assertions in the repo. The eight
// retired when the dual-run net began re-reporting each of them, recorded **per
// test** in `parity/system/corpus/retirement-debt.mjs` — which names, for each,
// what it proved and the scenario that replaced it. Per test rather than per
// file because `node drag fires onNodesChange` was the only callback assertion
// on either surface, and a file-level retirement would have dropped it with
// nothing saying so.
//
// **These two do not retire.** What is left is the claim no differential
// instrument makes: that the page comes up at all and says nothing while it is
// used. The net compares ps-flow against upstream, so two sides that were both
// broken in the same way compare clean — and a page that never mounted compares
// two empty traces. That is a different question from "does ps-flow match
// xyflow", and it is the one this file answers.
//
// It runs against a **driver** now, rather than against the ps-flow contract
// component it used to mount: `Smoke.tsx` existed to carry the eight
// assertions, its flow is `parity/system/fixtures/flow/chrome-defaults.ts`
// since they retired, and the driver mounts that fixture on both sides. So the
// page whose liveness is checked here is the same page the net drives.
const APP = "/parity/driver/index.html#/tests/generic/flow/chrome-defaults";

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

  // Liveness, and the test the `pageerror` trap above rides on: a trap
  // registered in a hook needs some test to run for it to fire in. The counts
  // are the fixture's own — two nodes and one edge — and they are here because
  // a `.react-flow` wrapper with nothing inside it is what a mount that threw
  // half way looks like.
  test("the driver page mounts and renders its fixture", async ({ page }) => {
    await expect(page.locator(".react-flow__node")).toHaveCount(2);
    await expect(page.locator(".react-flow__edge")).toHaveCount(1);
  });

  // Liveness, the second half: a session that drives the flow through the wheel
  // and through two of the Controls buttons, and prints nothing. The net records
  // the console as a section and compares it, which catches ps-flow saying
  // something upstream does not — this catches both of them saying it.
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
});
