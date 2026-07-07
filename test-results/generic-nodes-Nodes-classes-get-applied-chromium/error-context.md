# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: generic-nodes.spec.ts >> Nodes >> classes get applied
- Location: examples/react-smoke/tests/generic-nodes.spec.ts:227:3

# Error details

```
Error: expect(locator).toHaveClass(expected) failed

Locator: locator('.react-flow__node').and(locator('[data-id="Node-1"]'))
Expected pattern: /playwright-test-class-123/
Received string:  "react-flow__node react-flow__node-input nopan selectable draggable"
Timeout: 5000ms

Call log:
  - Expect "toHaveClass" with timeout 5000ms
  - waiting for locator('.react-flow__node').and(locator('[data-id="Node-1"]'))
    14 × locator resolved to <div tabindex="0" role="group" data-id="Node-1" aria-roledescription="node" data-testid="rf__node-Node-1" class="react-flow__node react-flow__node-input nopan selectable draggable">…</div>
       - unexpected value "react-flow__node react-flow__node-input nopan selectable draggable"

```

```yaml
- group
```

# Test source

```ts
  131 | 
  132 |       await dragHandle.hover();
  133 |       await page.mouse.down();
  134 |       await page.mouse.move(500, 500);
  135 |       await page.mouse.up();
  136 | 
  137 |       const transformAfterDragHandleMove = await node.evaluate((element) => {
  138 |         return element.style.transform;
  139 |       });
  140 | 
  141 |       expect(transformBeforeMove).not.toMatch(transformAfterDragHandleMove);
  142 |     });
  143 |   });
  144 | 
  145 |   test.describe("deleting", () => {
  146 |     test("deleting a node and its edges", async ({ page }) => {
  147 |       const node = page.locator(`.${FRAMEWORK}-flow__node`).and(page.locator('[data-id="Node-1"]'));
  148 |       await expect(node).toHaveCSS("visibility", "visible");
  149 | 
  150 |       await node.click();
  151 |       await page.keyboard.press("d");
  152 | 
  153 |       await expect(node).not.toBeAttached();
  154 | 
  155 |       const edges = await page.locator(`.${FRAMEWORK}-flow__edge`).all();
  156 |       expect(edges).toHaveLength(0);
  157 |     });
  158 | 
  159 |     test("deletable=false prevents deletion", async ({ page }) => {
  160 |       const node = page.locator(`.${FRAMEWORK}-flow__node`).and(page.locator('[data-id="notDeletable"]'));
  161 |       await expect(node).toHaveCSS("visibility", "visible");
  162 | 
  163 |       await expect(node).toBeAttached();
  164 | 
  165 |       await node.click();
  166 |       // pressing backspace breaks webkit
  167 |       await page.keyboard.press("d");
  168 | 
  169 |       await expect(node).toBeAttached();
  170 |     });
  171 |   });
  172 | 
  173 |   test.describe("connecting", () => {
  174 |     test("connecting two nodes", async ({ page }) => {
  175 |       let connectionLine = page.locator(`.${FRAMEWORK}-flow__connectionline`);
  176 |       const outputSourceHandle = page.locator(`.${FRAMEWORK}-flow__handle`).and(page.locator('[data-nodeid="Node-1"]'));
  177 |       const inputSourceHandle = page.locator(`.${FRAMEWORK}-flow__handle`).and(page.locator('[data-nodeid="Node-4"]'));
  178 | 
  179 |       await expect(page.locator(`.${FRAMEWORK}-flow__node`).first()).toHaveCSS("visibility", "visible");
  180 |       await expect(outputSourceHandle).toBeInViewport();
  181 |       await expect(inputSourceHandle).toBeInViewport();
  182 | 
  183 |       await expect(page.locator(`.${FRAMEWORK}-flow__edge`)).toHaveCount(2);
  184 | 
  185 |       await outputSourceHandle.hover();
  186 |       await page.mouse.down();
  187 |       await inputSourceHandle.hover();
  188 |       await expect(connectionLine).toBeInViewport();
  189 |       await page.mouse.up();
  190 | 
  191 |       await expect(connectionLine).not.toBeInViewport();
  192 | 
  193 |       await expect(page.locator('[data-id="xy-edge__Node-1-Node-4"]')).toBeInViewport();
  194 | 
  195 |       await expect(page.locator(`.${FRAMEWORK}-flow__edge`)).toHaveCount(3);
  196 |     });
  197 | 
  198 |     test("connectable=false prevents connections", async ({ page }) => {
  199 |       const outputHandle = page.locator(`.${FRAMEWORK}-flow__handle`).and(page.locator('[data-nodeid="Node-1"]'));
  200 |       const notConnectableHandle = page
  201 |         .locator(`.${FRAMEWORK}-flow__handle`)
  202 |         .and(page.locator('[data-nodeid="notConnectable"]'));
  203 | 
  204 |       const notConnectableBox = await notConnectableHandle.boundingBox();
  205 | 
  206 |       await expect(page.locator(`.${FRAMEWORK}-flow__node`).first()).toHaveCSS("visibility", "visible");
  207 |       await expect(outputHandle).toBeInViewport();
  208 |       await expect(notConnectableHandle).toBeInViewport();
  209 | 
  210 |       await expect(page.locator(`.${FRAMEWORK}-flow__edge`)).toHaveCount(2);
  211 | 
  212 |       await outputHandle.hover();
  213 |       await page.mouse.down();
  214 |       await page.mouse.move(notConnectableBox!.x + 2, notConnectableBox!.y + 2);
  215 |       await page.mouse.up();
  216 | 
  217 |       await expect(page.locator(`.${FRAMEWORK}-flow__edge`)).toHaveCount(2);
  218 |     });
  219 |   });
  220 | 
  221 |   test("hidden=true hides the node", async ({ page }) => {
  222 |     const node = page.locator(`.${FRAMEWORK}-flow__node`).and(page.locator('[data-id="hidden"]'));
  223 | 
  224 |     await expect(node).not.toBeInViewport();
  225 |   });
  226 | 
  227 |   test("classes get applied", async ({ page }) => {
  228 |     const node = page.locator(`.${FRAMEWORK}-flow__node`).and(page.locator('[data-id="Node-1"]'));
  229 |     await expect(node).toHaveCSS("visibility", "visible");
  230 | 
> 231 |     await expect(node).toHaveClass(/playwright-test-class-123/);
      |                        ^ Error: expect(locator).toHaveClass(expected) failed
  232 |   });
  233 | 
  234 |   test("styles get applied", async ({ page }) => {
  235 |     const node = page.locator(`.${FRAMEWORK}-flow__node`).and(page.locator('[data-id="Node-1"]'));
  236 |     await expect(node).toHaveCSS("visibility", "visible");
  237 | 
  238 |     await expect(node).toHaveCSS("background-color", "rgb(255, 0, 0)");
  239 |   });
  240 | });
  241 | 
```