# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: live.spec.mjs >> keyboard actions finish the native frame work and retain held modifiers
- Location: parity/system/harness/live.spec.mjs:54:1

# Error details

```
Error: expect(received).toEqual(expected) // deep equality

- Expected  - 10
+ Received  +  0

@@ -2,16 +2,6 @@
    Array [
      "keydown",
      "Shift",
      true,
    ],
-   Array [
-     "keydown",
-     "ArrowRight",
-     true,
-   ],
-   Array [
-     "keyup",
-     "ArrowRight",
-     true,
-   ],
  ]
```

# Page snapshot

```yaml
- status [ref=e2]: "[[\"keydown\",\"Shift\",true],[\"keydown\",\"ArrowRight\",true],[\"keyup\",\"ArrowRight\",true]]"
```

# Test source

```ts
  1   | // The harness against a real browser.
  2   | //
  3   | // Everything above the port is tested without one, against `fake-port.mjs`.
  4   | // That leaves exactly one claim untested: that the port's four dispatch paths
  5   | // reach a real renderer, and that a selector resolves to a box a real gesture
  6   | // can act on. A helper module shipped without ever having driven a page is the
  7   | // failure this repo names most often — a check that cannot see the thing it is
  8   | // checking — and the driving log would record a beautifully-shaped sequence of
  9   | // actions that did nothing at all.
  10  | //
  11  | // It asserts nothing about ps-flow against upstream. That is `parity:system`,
  12  | // which is `../net.mjs`.
  13  | 
  14  | import { test, expect } from "@playwright/test";
  15  | import { existsSync, readFileSync } from "node:fs";
  16  | import { fileURLToPath } from "node:url";
  17  | import { dirname, resolve } from "node:path";
  18  | 
  19  | import { CALL_LOG, OBSERVE } from "./call-log.mjs";
  20  | import { checkSelfConsistency } from "../compare/consistency.mjs";
  21  | import { defineScenario, driverUrl, runScenario } from "./scenario.mjs";
  22  | import { createPagePort } from "./port.mjs";
  23  | 
  24  | const here = dirname(fileURLToPath(import.meta.url));
  25  | const repoRoot = resolve(here, "..", "..", "..");
  26  | 
  27  | // The committed ruleset, because self-consistency below is the one the net runs
  28  | // rather than a stricter cousin of it: a rule the policy has already settled
  29  | // would otherwise make this file red for a reason nobody here decided.
  30  | const rules = JSON.parse(readFileSync(resolve(here, "..", "normalization.json"), "utf8")).rules;
  31  | 
  32  | // The ps-flow side of this file runs off `dist/psflow.js`, which is committed —
  33  | // fixtures bundled in — so all but two of these are meant to run on a clean
  34  | // clone, and the two that need the other side skip themselves below. Reading the
  35  | // vendored version at module load would undo all of that: an absent `xyflow/`
  36  | // would throw during collection and take the seven with it. README lists the
  37  | // scripts that hard-fail without the checkout and this is deliberately not one.
  38  | //
  39  | // A trace's `baseline` says which vendored upstream it was captured against, so
  40  | // with no checkout there is no honest version to name. These traces are the
  41  | // harness testing itself — never persisted, never compared, no parity claim —
  42  | // so the field is envelope-only here and says plainly that nothing was vendored.
  43  | const vendored = resolve(repoRoot, "xyflow/packages/react/package.json");
  44  | const baseline = existsSync(vendored) ? JSON.parse(readFileSync(vendored, "utf8")).version : "no-vendored-checkout";
  45  | 
  46  | const NODES_GENERAL = "/tests/generic/nodes/general";
  47  | const EDGES_GENERAL = "/tests/generic/edges/general";
  48  | const NODE = '.react-flow__node[data-id="Node-1"]';
  49  | 
  50  | const drive = (page, scenario, side = "psflow") => runScenario(page, scenario, { side, capture: 1, baseline });
  51  | 
  52  | const entriesOf = (trace, action) => trace.sections.driving.filter((e) => e.action === action);
  53  | 
  54  | test("keyboard actions finish the native frame work and retain held modifiers", async ({ page }) => {
  55  |   await page.setContent(`<output></output><script>
  56  |     for (const type of ['keydown', 'keyup']) {
  57  |       document.addEventListener(type, event => {
  58  |         const receipt = [type, event.key, event.shiftKey];
  59  |         requestAnimationFrame(() => requestAnimationFrame(() => setTimeout(() => {
  60  |           const output = document.querySelector('output');
  61  |           const receipts = JSON.parse(output.textContent || '[]');
  62  |           receipts.push(receipt);
  63  |           output.textContent = JSON.stringify(receipts);
  64  |         }, 0)));
  65  |       });
  66  |     }
  67  |   </script>`);
  68  |   const port = createPagePort(page);
  69  |   const receipts = [];
  70  |   for (const [action, key, expected] of [
  71  |     ["down", "Shift", [["keydown", "Shift", true]]],
  72  |     ["press", "ArrowRight", [["keydown", "ArrowRight", true], ["keyup", "ArrowRight", true]]],
  73  |     ["up", "Shift", [["keyup", "Shift", false]]],
  74  |   ]) {
  75  |     await port.keyboard(action, key);
  76  |     receipts.push(...expected);
  77  |     // Read once, without Playwright's retrying assertions: a later receipt
  78  |     // would conceal the port returning before the browser work completed.
> 79  |     expect(JSON.parse(await page.locator("output").textContent() || "[]")).toEqual(receipts);
      |                                                                            ^ Error: expect(received).toEqual(expected) // deep equality
  80  |   }
  81  | });
  82  | 
  83  | test("a mount resolves the container, and the trace it produces is a valid trace", async ({ page }) => {
  84  |   const trace = await drive(
  85  |     page,
  86  |     defineScenario({ id: "live--mount-only", route: NODES_GENERAL, run: async () => {} })
  87  |   );
  88  | 
  89  |   const [mount] = trace.sections.driving;
  90  |   expect(mount.action).toBe("mount");
  91  |   expect(mount.resolved).toBe(true);
  92  |   expect(mount.box.width).toBeGreaterThan(0);
  93  |   expect(mount.box.height).toBeGreaterThan(0);
  94  |   expect(trace.sections.dom.page).toEqual({ scrollX: 0, scrollY: 0, visualViewportScale: 1 });
  95  | });
  96  | 
  97  | // `dom.mjs` is tested against a hand-built document, which can say what capture
  98  | // keeps and nothing about what a real render puts there. This is the other half:
  99  | // that the selector reaches a mounted flow, and that what comes back is the
  100 | // nested element tree rather than an empty shell — a section that captured only
  101 | // the root would compare clean on both sides forever.
  102 | test("the dom section carries the flow's own element tree, nested", async ({ page }) => {
  103 |   const { sections } = await drive(
  104 |     page,
  105 |     defineScenario({ id: "live--dom-capture", route: NODES_GENERAL, run: async () => {} })
  106 |   );
  107 | 
  108 |   expect(sections.dom.root.tag).toBe("div");
  109 |   expect(sections.dom.root.attrs.class).toContain("react-flow");
  110 | 
  111 |   const nodes = [];
  112 |   const walk = (el) => {
  113 |     if (el.attrs["data-id"] && el.attrs.class?.includes("react-flow__node")) nodes.push(el.attrs["data-id"]);
  114 |     el.children.forEach(walk);
  115 |   };
  116 |   walk(sections.dom.root);
  117 | 
  118 |   expect(nodes).toContain("Node-1");
  119 | });
  120 | 
  121 | // Settling is defined by observation rather than by a duration, and the claim a
  122 | // double cannot make is that a real mount — React committing, the resize
  123 | // observers measuring, `fitView` running — actually reaches a state where two
  124 | // consecutive snapshots agree. If it did not, every capture would end at the
  125 | // ceiling and the whole net would be unreachable, which is a thing to learn
  126 | // here rather than from a corpus of sixty scenarios later.
  127 | test("a real flow settles, and the transform it settles at is measured, not zero", async ({ page }) => {
  128 |   const { sections } = await drive(
  129 |     page,
  130 |     defineScenario({ id: "live--settling", route: NODES_GENERAL, run: async () => {} })
  131 |   );
  132 | 
  133 |   const viewport = [];
  134 |   const walk = (el) => {
  135 |     if (el.attrs.class?.includes("react-flow__viewport")) viewport.push(el.attrs.style ?? "");
  136 |     el.children.forEach(walk);
  137 |   };
  138 |   walk(sections.dom.root);
  139 | 
  140 |   // `fitView` lands a transform on the viewport, and it lands a frame or more
  141 |   // after the flow first appears. A capture that did not wait catches the
  142 |   // identity transform instead.
  143 |   expect(viewport[0]).toMatch(/translate/);
  144 | });
  145 | 
  146 | // The one claim the fake port cannot make: that a gesture composed of pointer
  147 | // primitives moves the thing it grabbed.
  148 | test("dragNode moves the node it grabbed, by the distance it was told", async ({ page }) => {
  149 |   const trace = await drive(
  150 |     page,
  151 |     defineScenario({
  152 |       id: "live--drag-node",
  153 |       route: NODES_GENERAL,
  154 |       run: (actions) => actions.dragNode(NODE, { dx: 100, dy: 40, steps: 4 }),
  155 |     })
  156 |   );
  157 | 
  158 |   const [press] = entriesOf(trace, "pointerDown");
  159 |   expect(press.resolved).toBe(true);
  160 | 
  161 |   const after = await page.locator(NODE).boundingBox();
  162 |   expect(after.x - press.box.x).toBeCloseTo(100, 0);
  163 |   expect(after.y - press.box.y).toBeCloseTo(40, 0);
  164 | });
  165 | 
  166 | test("an unresolved target is recorded and driving continues — never a timeout", async ({ page }) => {
  167 |   const trace = await drive(
  168 |     page,
  169 |     defineScenario({
  170 |       id: "live--unresolved-target",
  171 |       route: NODES_GENERAL,
  172 |       run: async (actions) => {
  173 |         await actions.pointerDown('.react-flow__node[data-id="no-such-node"]');
  174 |         await actions.pointerUp(null);
  175 |       },
  176 |     })
  177 |   );
  178 | 
  179 |   expect(trace.sections.driving.map((e) => [e.action, e.resolved])).toEqual([
```