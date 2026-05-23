# 053 — React runtime verification (browser smoke test)

## Context

Ticket [049](049-react-public-api.md) landed the public API barrel
(`src/React.purs`), the JavaScript shim (`index.js`), the
`useNodesState` / `useEdgesState` wrappers, and a compilable example
under `examples/react-smoke/`. `spago build` and `spago test` are green
on the entire workspace.

The remaining half of 049 — the runtime browser checklist — was
explicitly deferred. Installing `react` / `react-dom`, bundling the
example, and exercising it in a real browser is the gate that flips the
React-layer port from "structurally complete" to "actually works".
This ticket owns that work.

## Prerequisites

- Ticket 049 merged.
- A working browser. The repo has no e2e harness today; this ticket
  may install one (Playwright / Vitest browser mode / a hand-written
  HTML page) — see *Approach* below.

## Approach

1. **Install runtime deps.** Add `react@^18`, `react-dom@^18` to the
   root `package.json`'s `dependencies` (still `"private": true`).
   `npm install`.
2. **Bundle the example.** From inside `examples/react-smoke/`, run
   `spago bundle-app` — the manifest already declares
   `bundle.module = Example.Main`, `outfile = dist/example.js`,
   `platform = browser`. Verify the output bundle resolves
   `react-dom/client` and the compiled PS modules cleanly.
3. **HTML harness.** Add `examples/react-smoke/index.html` that loads
   the bundle, includes `<div id="app">`, and pulls in
   `@xyflow/react/dist/style.css` + `base.css` from the upstream npm
   package (install `@xyflow/react` as a dev dep purely for its
   stylesheet — we don't import any TS code).
4. **Manual checklist.** Open the page in a real browser; walk through
   the runtime items from ticket 049:
   - [ ] Two nodes render at their configured positions.
   - [ ] One edge renders between them.
   - [ ] Pan: dragging the background moves the viewport.
   - [ ] Zoom: mouse wheel zooms the viewport.
   - [ ] Node drag: click+drag a node; `onNodesChange` fires.
   - [ ] Selection: clicking a node selects it; `onSelectionChange` fires.
   - [ ] MiniMap: appears bottom-right; reflects current viewport;
         clicking pans the main viewport.
   - [ ] Background: dotted grid renders behind everything.
   - [ ] Controls: zoom-in, zoom-out, fit-view, lock buttons render and
         work.
   - [ ] No `console.error`s during a 30-second interaction session.
   - [ ] No React strict-mode double-mount issues.
   - [ ] Upstream CSS files apply cleanly without manual class-name
         patching.

## Known blockers from ticket 052

Several items above are expected to fail until follow-ups land:

- **Node drag** depends on `<Handle />` connection-drag wiring, which
  is currently a no-op stub
  ([src/React/Handle.purs](../src/React/Handle.purs) header). The
  underlying `System.XYHandle.onPointerDown` is in place — only the
  React-side glue is missing.
- **Click-connect** (the two-step click-to-connect flow) is gated on
  the same store-helper plumbing.
- **Dev-mode warnings** gate on `state.debug` instead of
  `process.env.NODE_ENV`
  ([052 #1](052-react-flow-divergences-followups.md)).

Treat these as expected failures; the checklist is *advisory* until 052
closes. Items that *aren't* blocked (rendering, pan/zoom, MiniMap,
Background, Controls) must pass.

## Acceptance Criteria

- The example bundles via `spago bundle-app` with no errors.
- A browser session exercises every non-blocked checklist item.
- Each blocked item is annotated with the 052 issue ID that owns it.
- `tickets/000-overview.md` gets an amendment:
  > React layer port complete (YYYY-MM-DD) — see ticket 053.

## Source Files

- [tickets/049-react-public-api.md](049-react-public-api.md) — the
  parent ticket with the original runtime checklist.
- [tickets/052-react-flow-divergences-followups.md](052-react-flow-divergences-followups.md)
  — known blockers.
- [examples/react-smoke/](../examples/react-smoke/) — the smoke-test
  app to bundle.
- [src/React.purs](../src/React.purs) — public-API barrel under test.
- [index.js](../index.js) — JS shim that wraps the compiled output.
