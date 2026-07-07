# 062 — Layer 2: pane.spec (pan / zoom / auto-pan)

## Context

Layer 2 ports xyflow's own framework-parameterized e2e specs against the ported
smoke fixture app (recipe established in ticket [061](061-layer2-nodes-spec-interaction-gaps.md)).
`nodes.spec.ts` is done (13/13). This ticket ports the **second** of the four
remaining upstream specs. It is sequenced **first** among the four — lowest risk,
no expected source gaps — to re-prove the recipe repeats.

Upstream spec: `xyflow/tests/playwright/e2e/pane.spec.ts` (8 tests). It imports
`getTransform` from `xyflow/tests/playwright/e2e/utils.ts`.

Two routes / two **data-only** fixtures (3 nodes + 2 edges each):

| Fixture | Route | Flow-prop overrides |
|---------|-------|---------------------|
| `pane/general.ts` | `#/tests/generic/pane/general` | `minZoom:0.25, maxZoom:4, fitView` |
| `pane/non-defaults.ts` | `#/tests/generic/pane/non-defaults` | `panOnScroll:true, defaultViewport:{x:1.23,y:9.87,zoom:1.234}, autoPanOnConnect:false, autoPanOnNodeDrag:false` |

(The commented-out `pane/activation-keys` block/route upstream is dead — ignore.)

## Resolution (2026-07-07) — 8 / 8 pass, no source gaps

Recipe repeated cleanly — **no `src/` changes**. All work was fixture/harness +
spec adoption:

- `Generic/Fixture.purs` — extended `type Fixture` with the 6 pan/zoom props
  (surfacing existing `Nothing` defaults), added `paneNodes`/`paneEdges` (shared)
  + `paneGeneral`/`paneNonDefaults` fixtures, and two `fixtureForRoute` arms.
- `Generic/Flow.purs` — passed the 6 new props through `rfProps`.
- `examples/react-smoke/tests/generic-pane.spec.ts` — adopted spec (inline
  `FRAMEWORK`, two hash `ROUTE`s, `getTransform` inlined from `utils.ts`).

One **spec-only deviation** (the "tolerance tuning" the ticket flagged, not
feature work): in `panning the pane moves it`, the raw translate delta is rounded
to whole pixels before the `movementPx - delta < 1` check. The pane pans in
screen space so the delta is integral, but IEEE-754 subtraction underflows it:
our fitView puts `translateY` at 157.131 and `257.131 - 157.131 ===
99.99999999999997`, so upstream's `Math.floor` yields 99 and the assertion fails
despite an exact 100px pan. (`translateX`, 390.571 → 490.571, subtracts cleanly
and passes upstream-verbatim.) All other 7 tests pass with the upstream
assertions unchanged. Full smoke suite 32/32 (13 nodes + 8 pane + 11 prior).

## Tests (8)

- `pan & zoom > panning the pane moves it` — drag pane ~100px, viewport `translateX/Y` changes.
- `pan & zoom > scrolling the default pane zooms it` — wheel changes viewport `scale`.
- `minZoom & maxZoom > minZoom` — wheel out, `scale === 0.25`.
- `minZoom & maxZoom > maxZoom` — wheel in, `scale === 4`.
- `autoPan > autoPanOnNodeDrag` — drag node `1` to viewport edge, viewport translate changes.
- `autoPan > autoPanOnConnect` — drag from node `1`'s handle to edge, viewport translate changes.
- `pan & zoom > panOnScroll pans the pane on scrolling` (non-defaults) — wheel changes translate (not scale).
- `pan & zoom > intialViewport` (non-defaults) — `defaultViewport` → translate `1.23`/`9.87`, scale `1.234`.

## Work

1. Copy the ~16-line `getTransform(element)` helper (regex-parses `translateX/Y`,
   `scale` from `el.style.transform`) into the spec or a local `tests/` util.
2. Extend `type Fixture` (`examples/react-smoke/src/Generic/Fixture.purs`) + the
   `flowView` passthrough (`Generic/Flow.purs`) with 6 flow props: `minZoom`,
   `maxZoom`, `panOnScroll`, `defaultViewport`, `autoPanOnConnect`,
   `autoPanOnNodeDrag`. All 6 already exist as `Nothing` defaults in
   `Generic/Defaults.purs` — this is surfacing, not adding, props.
3. Add the two fixtures (`paneGeneral`, `paneNonDefaults`) + two
   `fixtureForRoute` arms.
4. Adopt the spec as `examples/react-smoke/tests/generic-pane.spec.ts` with the
   three infra edits (inline `FRAMEWORK="react"`, hash `ROUTE`, `waitForSelector`).

## Feature status — no source gaps expected

All features exist: pan/zoom (`src/System/XYPanZoom.purs` `setScaleExtent` +
viewport clamp), `panOnScroll` (`src/System/XYPanZoom/Filter.purs` +
`EventHandler.purs`), `autoPanOnNodeDrag` (`src/System/XYDrag.purs`
`autoPanStep`/`autoPanLoop`), `autoPanOnConnect` (`src/System/XYHandle.purs`).
The only risk is Playwright timing fidelity — wheel deltas and the ~500ms
auto-pan warm-up — which may need `waitFor`/tolerance tuning in the spec, not
feature work.

## Acceptance criteria

- `npm run build:smoke && npm run test:smoke -- --grep pane` → `generic-pane.spec.ts`
  all 8 green (both routes).
- Full `npm run test:smoke` stays green (existing 24 smoke tests, incl.
  `generic-nodes.spec.ts` 13/13).

## Source files

- New: `examples/react-smoke/tests/generic-pane.spec.ts`
- Edit: `examples/react-smoke/src/Generic/{Fixture,Flow}.purs`
- Reference: `xyflow/tests/playwright/e2e/pane.spec.ts`,
  `xyflow/tests/playwright/e2e/utils.ts`,
  `xyflow/examples/react/src/generic-tests/pane/{general,non-defaults}.ts`
