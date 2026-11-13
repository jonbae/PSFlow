# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: live.spec.mjs >> upstream reproduces its whole trace, call log included, across two captures
- Location: parity/system/harness/live.spec.mjs:240:1

# Error details

```
Error: expect(received).toEqual(expected) // deep equality

- Expected  -  1
+ Received  + 68

- Array []
+ Array [
+   Object {
+     "kind": "order",
+     "left": Array [
+       "onSelectionChange#1",
+       "onMoveStart#1",
+       "onViewportChange#1",
+       "onMove#1",
+       "onNodesChange#1",
+       "onMoveEnd#1",
+       "onInit#1",
+       "onPaneMouseEnter#1",
+       "onNodeMouseEnter#1",
+       "onPaneMouseMove#1",
+       "onNodeMouseMove#1",
+       "onNodesChange#2",
+       "onNodeDragStart#1",
+       "onSelectionChange#2",
+       "onPaneMouseMove#2",
+       "onNodesChange#3",
+       "onNodeDrag#1",
+       "onPaneMouseMove#3",
+       "onNodesChange#4",
+       "onNodeDrag#2",
+       "onPaneMouseMove#4",
+       "onNodesChange#5",
+       "onNodeDrag#3",
+       "onPaneMouseMove#5",
+       "onNodesChange#6",
+       "onNodeDrag#4",
+       "onNodesChange#7",
+       "onNodeDragStop#1",
+     ],
+     "path": Array [
+       "callbacks",
+     ],
+     "right": Array [
+       "onSelectionChange#1",
+       "onInit#1",
+       "onMoveStart#1",
+       "onViewportChange#1",
+       "onMove#1",
+       "onNodesChange#1",
+       "onMoveEnd#1",
+       "onPaneMouseEnter#1",
+       "onNodeMouseEnter#1",
+       "onPaneMouseMove#1",
+       "onNodeMouseMove#1",
+       "onNodesChange#2",
+       "onNodeDragStart#1",
+       "onSelectionChange#2",
+       "onPaneMouseMove#2",
+       "onNodesChange#3",
+       "onNodeDrag#1",
+       "onPaneMouseMove#3",
+       "onNodesChange#4",
+       "onNodeDrag#2",
+       "onPaneMouseMove#4",
+       "onNodesChange#5",
+       "onNodeDrag#3",
+       "onPaneMouseMove#5",
+       "onNodesChange#6",
+       "onNodeDrag#4",
+       "onNodesChange#7",
+       "onNodeDragStop#1",
+     ],
+   },
+ ]
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
        - group [active] [ref=e21]: Node-1
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
  193 |     })
  194 |   );
  195 | 
  196 |   expect(trace.sections.driving.map((e) => [e.action, e.resolved])).toEqual([
  197 |     ["mount", true],
  198 |     ["pointerDown", false],
  199 |     ["pointerUp", true],
  200 |   ]);
  201 | });
  202 | 
  203 | // Self-consistency is tested against fixture traces without a browser (#43), and
  204 | // there is one thing those cannot say: that a real page can satisfy it. The
  205 | // driving log carries no tolerance, so every box a drag resolves has to come back
  206 | // bit-identical from a second run of the same scenario. If real layout wobbles in
  207 | // the last decimal place, the whole check is unsatisfiable and the net would be
  208 | // permanently red — which is a thing to learn here, cheaply, rather than from a
  209 | // corpus of sixty scenarios later.
  210 | //
  211 | // Scoped to the two sections the *harness* answers for, and deliberately so.
  212 | // ps-flow's call log does not reproduce itself — the same drag fires the same
  213 | // calls in three different interleavings across six runs, where upstream fires
  214 | // one — and that is a library divergence of exactly the kind the net exists to
  215 | // find (#22). It is the gate's to report, on the run that measures it; asserting
  216 | // it either way here would make this file a parity claim, which is not its job.
  217 | // The whole-trace form of this check is the upstream one below.
  218 | const dragScenario = defineScenario({
  219 |   id: "live--drag-node",
  220 |   route: NODES_GENERAL,
  221 |   run: (actions) => actions.dragNode(NODE, { dx: 100, dy: 40, steps: 4 }),
  222 | });
  223 | 
  224 | const sectionsOf = (differences, ...names) => differences.filter((d) => names.includes(d.path?.[0]));
  225 | 
  226 | test("a side reproduces its own boxes and its own render across two captures", async ({ page }) => {
  227 |   const first = await runScenario(page, dragScenario, { side: "psflow", capture: 1, baseline });
  228 |   const second = await runScenario(page, dragScenario, { side: "psflow", capture: 2, baseline });
  229 | 
  230 |   const { differences } = checkSelfConsistency(first, second, { rules });
  231 | 
  232 |   expect(sectionsOf(differences, "driving", "dom")).toEqual([]);
  233 | });
  234 | 
  235 | // The whole check, on the side that can satisfy it today — and the claim the
  236 | // node tests cannot make about the call log: that a real library firing real
  237 | // handlers produces the *same sequence* twice, arguments included. If it did
  238 | // not, the section would be unusable rather than strict, and no amount of
  239 | // comparison logic downstream could tell the difference.
  240 | test("upstream reproduces its whole trace, call log included, across two captures", async ({ page }) => {
  241 |   test.skip(
  242 |     !existsSync(resolve(repoRoot, "parity/driver/dist/upstream.js")),
  243 |     "the upstream bundle is built beside a vendored xyflow/ and is not committed"
  244 |   );
  245 | 
  246 |   const first = await runScenario(page, dragScenario, { side: "upstream", capture: 1, baseline });
  247 |   const second = await runScenario(page, dragScenario, { side: "upstream", capture: 2, baseline });
  248 | 
  249 |   const result = checkSelfConsistency(first, second, { rules });
> 250 |   expect(result.differences).toEqual([]);
      |                              ^ Error: expect(received).toEqual(expected) // deep equality
  251 |   expect(result.consistent).toBe(true);
  252 | });
  253 | 
  254 | // ── The call log against a real page ───────────────────────────────────────
  255 | //
  256 | // `call-log.mjs` is tested in node against hand-made calls, which can say what
  257 | // the log keeps and nothing about whether a library ever reaches it. These are
  258 | // the other half: that the driver's wrapping survives the boundary, that the
  259 | // sequence is the library's own, and that a handler *no fixture sets* is
  260 | // installed — the last of which is the whole reason the driver derives its list
  261 | // rather than following the fixtures.
  262 | 
  263 | test("a real library firing real handlers lands in the callbacks section, in order", async ({ page }) => {
  264 |   const { sections } = await drive(page, dragScenario);
  265 |   const names = sections.callbacks.map((e) => e.name);
  266 | 
  267 |   // A mount alone fires some of these, which is why the drag's own three are
  268 |   // checked as a subsequence rather than as the whole section: what is being
  269 |   // claimed here is that the log caught them and kept the library's order.
  270 |   const drag = names.filter((n) => ["onNodeDragStart", "onNodeDrag", "onNodeDragStop"].includes(n));
  271 |   expect(drag[0]).toBe("onNodeDragStart");
  272 |   expect(drag[drag.length - 1]).toBe("onNodeDragStop");
  273 |   expect(drag.filter((n) => n === "onNodeDrag").length).toBeGreaterThan(0);
  274 |   expect(names).toContain("onNodesChange");
  275 | });
  276 | 
  277 | // Every argument, not only the ones a handler's signature makes obvious: the
  278 | // node a drag was about arrives as trace content, addressable field by field, so
  279 | // a region can point at one of them.
  280 | test("what a handler was handed arrives as trace content, addressable field by field", async ({ page }) => {
  281 |   const { sections } = await drive(page, dragScenario);
  282 |   const [event, node] = sections.callbacks.find((e) => e.name === "onNodeDragStart").args;
  283 | 
  284 |   expect(node.id).toBe("Node-1");
  285 |   expect(node.position).toEqual({ x: expect.any(Number), y: expect.any(Number) });
  286 |   expect(typeof event).toBe("object");
  287 | });
  288 | 
  289 | // The claim `serialize.mjs` exists to make, one level up from its own tests: a
  290 | // React synthetic event carries its fields as *own* properties, so they reach the
  291 | // trace — and a native event, carrying them on its prototype, arrives as its
  292 | // class name and nothing else. No shape check and no DOM diff can see that
  293 | // difference, and both kinds turn up in one drag: xyflow's own drag comes from
  294 | // d3, so `onNodeDragStart` is handed the native `MouseEvent`, while the handlers
  295 | // React wires are handed a synthetic one.
  296 | //
  297 | // Asserted on upstream, which is where the reference answer for what a handler
  298 | // *should* be handed lives. What ps-flow passes is the gate's to report.
  299 | test("upstream's synthetic event reaches the trace with its own fields on it", async ({ page }) => {
  300 |   test.skip(
  301 |     !existsSync(resolve(repoRoot, "parity/driver/dist/upstream.js")),
  302 |     "the upstream bundle is built beside a vendored xyflow/ and is not committed"
  303 |   );
  304 | 
  305 |   const trace = await drive(page, dragScenario, "upstream");
  306 |   const [event] = trace.sections.callbacks.find((e) => e.name === "onPaneMouseMove").args;
  307 | 
  308 |   expect(event["@class"]).toMatch(/Synthetic/);
  309 |   expect(event.type).toBe("pointermove");
  310 |   expect(typeof event.clientX).toBe("number");
  311 | 
  312 |   // The identities, kept as their kind and no further: each side rendered its
  313 |   // own DIV and neither could agree with the other about which one it was.
  314 |   expect(event.target).toEqual({ "@ref": "DIV" });
  315 |   expect(event.nativeEvent["@class"]).toBe("PointerEvent");
  316 | });
  317 | 
  318 | // The fixture sets no handler at all — `nodes/general.ts` is nodes, edges and
  319 | // `multiSelectionKeyCode`. Every call in its log is therefore a prop the driver
  320 | // installed because upstream declares it, which is the property that makes a
  321 | // handler firing on one side and not the other visible at all.
  322 | test("a handler no fixture ever set is installed, and fires", async ({ page }) => {
  323 |   const { sections } = await drive(page, dragScenario);
  324 | 
  325 |   expect(sections.callbacks.map((e) => e.name)).toContain("onPaneMouseMove");
  326 | });
  327 | 
  328 | // The refusal that keeps an empty section from being mistaken for a quiet one.
  329 | // A page with no log is a driver bundle built before there was one, and capture
  330 | // must not answer that with a section the other side's equally empty one
  331 | // compares clean against.
  332 | test("a page with no call log fails the capture rather than recording nothing", async ({ page }) => {
  333 |   // Installed before the driver's own script runs, so the property the log would
  334 |   // be published under refuses to hold it. The key travels as an argument for
  335 |   // the same reason `port.mjs` passes it into `page.evaluate`: an init script
  336 |   // reaches the page as source, with none of this scope.
  337 |   await page.addInitScript((key) => {
  338 |     Object.defineProperty(window, key, { value: undefined, writable: false, configurable: false });
  339 |   }, CALL_LOG);
  340 | 
  341 |   await expect(
  342 |     drive(page, defineScenario({ id: "live--no-call-log", route: NODES_GENERAL, run: async () => {} }))
  343 |   ).rejects.toThrow(/build:driver/);
  344 | });
  345 | 
  346 | // The other half of that guard, and the one that protects the *other* gates:
  347 | // wrapping is asked for by the URL, because installing a callback prop changes
  348 | // what the page renders. A page loaded without the parameter reports an empty
  349 | // list rather than staying silent — which is what `callbacksSection` turns into
  350 | // a failure, tested there — and every capture asks, because `driverUrl` is the
```