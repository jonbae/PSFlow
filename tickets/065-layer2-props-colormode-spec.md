# 065 — Layer 2: props.spec (color mode) — bespoke example page

## Context

Layer 2 e2e port (recipe: ticket [061](061-layer2-nodes-spec-interaction-gaps.md)),
**last** of the four remaining specs. Unlike the others, `props.spec.ts` **does
not use the generic-test harness** — upstream navigates to `/examples/color-mode`
(`xyflow/examples/react/src/examples/ColorMode/index.tsx`), a standalone example
app. So this needs a bespoke example page and a non-generic router branch, not a
`fixtureForRoute` entry.

Upstream spec: `xyflow/tests/playwright/e2e/props.spec.ts` (2 tests).

## Tests (2)

- `colorMode > render default light color mode` — first `.react-flow__node`
  visible; `.react-flow` does **not** have the `dark` class.
- `colorMode > render dark color mode` — select `[data-testid="colormode-select"]`
  → `dark`; `.react-flow` gains the `dark` class.

## Decision — minimal port

The feature under test already works; the tests only assert the two `dark`-class
states. Build a **minimal** ColorMode page, not a faithful port of upstream's
example.

- **Minimal (chosen):** a stateful flow holding `colorMode` state, passing it to
  `<ReactFlow colorMode=...>`, with a `<Panel position="top-right">` containing
  `<select data-testid="colormode-select">` (light/dark; `system` optional).
  MiniMap/Background/Controls omitted (decorative for these 2 assertions).
  Lowest incidental-breakage risk.
- **Faithful alternative** (recorded, not chosen): port upstream's full ColorMode
  example (MiniMap/Background/Controls, `system` mode) for incidental extra
  surface coverage, at higher effort and more chances an unrelated bug blocks the
  2 tests. Revisit only if that extra coverage is wanted.

## Work

- New bespoke example module (e.g. `examples/react-smoke/src/Example/ColorMode.purs`)
  — stateful `colorMode`, `<Panel>` + `<select data-testid="colormode-select">`.
- New **non-generic** router branch in `examples/react-smoke/src/Example/Main.purs`
  `main`: a distinct route (e.g. `#/examples/color-mode`) that renders the
  ColorMode page directly (it can't go through `fixtureForRoute`/`flowView` —
  the `Fixture` model has no `colorMode`/`Panel`/`select`). Point the spec's
  `ROUTE` at it.
- Adopt the spec as `examples/react-smoke/tests/generic-props.spec.ts` (or
  `colormode.spec.ts`) with the infra edits.

## Feature status — no gap, fixture just doesn't exist

`colorMode` + `dark`-class already work: `useColorModeClass` in
`src/React/Container/ReactFlow.purs` maps `Dark → "dark"`; hook
`src/React/Hook/ColorModeClass.purs` (Light/Dark/System via
`src/React/FFI/MatchMedia.purs`); `Panel` exists (`src/React/Portal/Panel.purs`).
There is no PSFlow ColorMode example today (grep finds only `colorMode: Nothing`
defaults).

## Acceptance criteria

- `npm run build:smoke && npm run test:smoke -- --grep "colorMode|props"` → both green.
- Full `npm run test:smoke` stays green.

## Source files

- New: `examples/react-smoke/tests/generic-props.spec.ts`,
  `examples/react-smoke/src/Example/ColorMode.purs`
- Edit: `examples/react-smoke/src/Example/Main.purs` (new router branch)
- Reference: `xyflow/tests/playwright/e2e/props.spec.ts`,
  `xyflow/examples/react/src/examples/ColorMode/index.tsx`
