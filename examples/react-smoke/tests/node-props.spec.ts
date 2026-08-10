// PSFlow-specific parity guard for ticket 069 — NOT an upstream port.
//
// Unlike the `generic-*.spec.ts` files (faithful copies of xyflow's
// framework-parameterized e2e suite), this spec exists only to pin the
// `NodeProps` record PSFlow hands to a user's custom node component. Ticket 069
// added `width`/`height`/`parentId`/`selectable`/`deletable`/`draggable` and
// renamed `xPos`/`yPos` → `positionAbsoluteX`/`positionAbsoluteY`; the
// surface-parity prop-member diff that caught the gap was informational, not a
// gate, which is how the drift survived from 12.3.5 in the first place. This is
// the gate. It sits outside the five-gate scheme and retires when the net's
// `props` section is green ([#61](https://github.com/jonbae/PSFlow/issues/61));
// `npm run test:node-props` is its runner.
//
// The page (`Example.NodePropsProbe`, route `#/examples/node-props`) renders each
// of those fields as a `data-*` attribute on a `.node-props-probe` div. The
// expected strings are exactly what PureScript's `show` emits — `Number` carries
// a trailing `.0`, `Boolean` is lower-case.
import { test, expect, type Page } from "@playwright/test";

const ROUTE = "/examples/react-smoke/index.html#/examples/node-props";

const probe = (page: Page, id: string) =>
  page.locator(`.react-flow__node[data-id="${id}"] .node-props-probe`);

test.describe("NodeProps (PSFlow guard, ticket 069)", () => {
  // `probe-child` sets selectable/draggable/deletable explicitly to false and
  // parents itself to `probe-parent`, so it covers the explicit-flag branch of
  // NodeWrapper plus `parentId`. Its own `position` is (50, 25) but its parent
  // sits at (100, 200), so the expected absolute (150, 225) is a real assertion:
  // wiring raw `position` into positionAbsoluteX/Y instead fails here.
  test("threads explicit flags, dimensions, parentId and absolute position", async ({ page }) => {
    await page.goto(ROUTE);
    await expect(page.locator(".react-flow")).toBeVisible();

    const child = probe(page, "probe-child");
    await expect(child).toBeVisible();

    await expect(child).toHaveAttribute("data-selectable", "false");
    await expect(child).toHaveAttribute("data-draggable", "false");
    await expect(child).toHaveAttribute("data-deletable", "false");

    await expect(child).toHaveAttribute("data-width", "120.0");
    await expect(child).toHaveAttribute("data-height", "40.0");

    await expect(child).toHaveAttribute("data-parent-id", "probe-parent");

    await expect(child).toHaveAttribute("data-pos-x", "150.0");
    await expect(child).toHaveAttribute("data-pos-y", "225.0");
  });

  // `probe-parent` leaves all three flags at `Nothing`, so it covers the
  // defaulted branch: selectable/draggable fall through to the flow-level
  // `elementsSelectable`/`nodesDraggable` and deletable to `fromMaybe true`.
  test("defaults unset flags from the flow-level props", async ({ page }) => {
    await page.goto(ROUTE);
    await expect(page.locator(".react-flow")).toBeVisible();

    const parent = probe(page, "probe-parent");
    await expect(parent).toBeVisible();

    await expect(parent).toHaveAttribute("data-selectable", "true");
    await expect(parent).toHaveAttribute("data-draggable", "true");
    await expect(parent).toHaveAttribute("data-deletable", "true");

    await expect(parent).toHaveAttribute("data-width", "300.0");
    await expect(parent).toHaveAttribute("data-height", "200.0");

    await expect(parent).toHaveAttribute("data-parent-id", "");

    await expect(parent).toHaveAttribute("data-pos-x", "100.0");
    await expect(parent).toHaveAttribute("data-pos-y", "200.0");
  });
});
