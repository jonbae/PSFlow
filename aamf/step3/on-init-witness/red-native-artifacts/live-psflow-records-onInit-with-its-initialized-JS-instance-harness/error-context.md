# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: live.spec.mjs >> psflow records onInit with its initialized JS instance
- Location: parity/system/harness/live.spec.mjs:84:3

# Error details

```
Error: expect(received).toHaveLength(expected)

Expected length: 1
Received length: 0
Received array:  []
```

# Page snapshot

```yaml
- application [ref=e4]:
  - generic [ref=e6]:
    - generic:
      - generic:
        - img:
          - group "Edge from Node-1 to Node-2" [ref=e7] [cursor=pointer]:
            - generic [ref=e10]:
              - generic: edge
        - img:
          - group "Edge from Node-1 to Node-3" [ref=e14] [cursor=pointer]:
            - generic [ref=e17]:
              - generic: edge
      - generic:
        - group [ref=e21]: Node-1
        - group [ref=e23]: Node-2
        - group [ref=e25]: Node-3
        - group [ref=e28]: Node-4
        - group [ref=e30]
        - group [ref=e33]: notConnectable
        - group [ref=e34] [cursor=pointer]: notDraggable
        - group [ref=e37]: notSelectable
        - group [ref=e40]: notDeletable
  - link "React Flow attribution" [ref=e44] [cursor=pointer]:
    - /url: https://reactflow.dev
    - text: React Flow
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
  79  |     expect(JSON.parse(await page.locator("output").textContent() || "[]")).toEqual(receipts);
  80  |   }
  81  | });
  82  | 
  83  | for (const side of ["psflow", "upstream"]) {
  84  |   test(`${side} records onInit with its initialized JS instance`, async ({ page }) => {
  85  |     test.skip(side === "upstream" && !existsSync(resolve(repoRoot, "parity/driver/dist/upstream.js")), "no upstream bundle");
  86  |     const trace = await drive(page, defineScenario({
  87  |       id: "live--initialized-instance",
  88  |       route: NODES_GENERAL,
  89  |       run: async () => {},
  90  |     }), side);
  91  |     const calls = trace.sections.callbacks.filter(entry => entry.name === "onInit");
> 92  |     expect(calls).toHaveLength(1);
      |                   ^ Error: expect(received).toHaveLength(expected)
  93  |     expect(calls[0].args).toHaveLength(1);
  94  |     expect(calls[0].args[0].viewportInitialized).toBe(true);
  95  |     expect(calls[0].args[0].getNodes).toEqual({ "@ref": "function" });
  96  |     expect(calls[0].args[0].setViewport).toEqual({ "@ref": "function" });
  97  |   });
  98  | }
  99  | 
  100 | test("a mount resolves the container, and the trace it produces is a valid trace", async ({ page }) => {
  101 |   const trace = await drive(
  102 |     page,
  103 |     defineScenario({ id: "live--mount-only", route: NODES_GENERAL, run: async () => {} })
  104 |   );
  105 | 
  106 |   const [mount] = trace.sections.driving;
  107 |   expect(mount.action).toBe("mount");
  108 |   expect(mount.resolved).toBe(true);
  109 |   expect(mount.box.width).toBeGreaterThan(0);
  110 |   expect(mount.box.height).toBeGreaterThan(0);
  111 |   expect(trace.sections.dom.page).toEqual({ scrollX: 0, scrollY: 0, visualViewportScale: 1 });
  112 | });
  113 | 
  114 | // `dom.mjs` is tested against a hand-built document, which can say what capture
  115 | // keeps and nothing about what a real render puts there. This is the other half:
  116 | // that the selector reaches a mounted flow, and that what comes back is the
  117 | // nested element tree rather than an empty shell — a section that captured only
  118 | // the root would compare clean on both sides forever.
  119 | test("the dom section carries the flow's own element tree, nested", async ({ page }) => {
  120 |   const { sections } = await drive(
  121 |     page,
  122 |     defineScenario({ id: "live--dom-capture", route: NODES_GENERAL, run: async () => {} })
  123 |   );
  124 | 
  125 |   expect(sections.dom.root.tag).toBe("div");
  126 |   expect(sections.dom.root.attrs.class).toContain("react-flow");
  127 | 
  128 |   const nodes = [];
  129 |   const walk = (el) => {
  130 |     if (el.attrs["data-id"] && el.attrs.class?.includes("react-flow__node")) nodes.push(el.attrs["data-id"]);
  131 |     el.children.forEach(walk);
  132 |   };
  133 |   walk(sections.dom.root);
  134 | 
  135 |   expect(nodes).toContain("Node-1");
  136 | });
  137 | 
  138 | // Settling is defined by observation rather than by a duration, and the claim a
  139 | // double cannot make is that a real mount — React committing, the resize
  140 | // observers measuring, `fitView` running — actually reaches a state where two
  141 | // consecutive snapshots agree. If it did not, every capture would end at the
  142 | // ceiling and the whole net would be unreachable, which is a thing to learn
  143 | // here rather than from a corpus of sixty scenarios later.
  144 | test("a real flow settles, and the transform it settles at is measured, not zero", async ({ page }) => {
  145 |   const { sections } = await drive(
  146 |     page,
  147 |     defineScenario({ id: "live--settling", route: NODES_GENERAL, run: async () => {} })
  148 |   );
  149 | 
  150 |   const viewport = [];
  151 |   const walk = (el) => {
  152 |     if (el.attrs.class?.includes("react-flow__viewport")) viewport.push(el.attrs.style ?? "");
  153 |     el.children.forEach(walk);
  154 |   };
  155 |   walk(sections.dom.root);
  156 | 
  157 |   // `fitView` lands a transform on the viewport, and it lands a frame or more
  158 |   // after the flow first appears. A capture that did not wait catches the
  159 |   // identity transform instead.
  160 |   expect(viewport[0]).toMatch(/translate/);
  161 | });
  162 | 
  163 | // The one claim the fake port cannot make: that a gesture composed of pointer
  164 | // primitives moves the thing it grabbed.
  165 | test("dragNode moves the node it grabbed, by the distance it was told", async ({ page }) => {
  166 |   const trace = await drive(
  167 |     page,
  168 |     defineScenario({
  169 |       id: "live--drag-node",
  170 |       route: NODES_GENERAL,
  171 |       run: (actions) => actions.dragNode(NODE, { dx: 100, dy: 40, steps: 4 }),
  172 |     })
  173 |   );
  174 | 
  175 |   const [press] = entriesOf(trace, "pointerDown");
  176 |   expect(press.resolved).toBe(true);
  177 | 
  178 |   const after = await page.locator(NODE).boundingBox();
  179 |   expect(after.x - press.box.x).toBeCloseTo(100, 0);
  180 |   expect(after.y - press.box.y).toBeCloseTo(40, 0);
  181 | });
  182 | 
  183 | test("an unresolved target is recorded and driving continues — never a timeout", async ({ page }) => {
  184 |   const trace = await drive(
  185 |     page,
  186 |     defineScenario({
  187 |       id: "live--unresolved-target",
  188 |       route: NODES_GENERAL,
  189 |       run: async (actions) => {
  190 |         await actions.pointerDown('.react-flow__node[data-id="no-such-node"]');
  191 |         await actions.pointerUp(null);
  192 |       },
```