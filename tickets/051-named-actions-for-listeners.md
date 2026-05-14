# 051 — Named `Action` constructors for listener / middleware registration

## Context

Tickets 029 (`React.Hook.Listeners`) and 031 (`React.Hook.Middleware`)
register and de-register callbacks in the store by reaching into
state fields directly:

- `state.onViewportChangeStart` / `onViewportChange` / `onViewportChangeEnd`
- `state.onSelectionChangeHandlers`
- `state.onNodesChangeMiddlewareMap`
- `state.onEdgesChangeMiddlewareMap`

The hook layer uses the `PatchState (state -> state)` escape hatch on
`React.Store.Action.Action` for all four. This kept the original hook
PR small but is a wart on the reducer's audit trail — any future
logging middleware sees `PatchState <function>` and not the actual
intent.

## Goal

Replace each `PatchState` call inside `React.Hook.Listeners` and
`React.Hook.Middleware` with a named `Action` constructor.

## Proposed additions to `React.Store.Action.Action`

```purescript
| SetOnViewportChangeStart (Maybe OnViewportChange)
| SetOnViewportChange      (Maybe OnViewportChange)
| SetOnViewportChangeEnd   (Maybe OnViewportChange)
| AddSelectionChangeHandler    (OnSelectionChangeFunc n e)
| RemoveSelectionChangeHandler (OnSelectionChangeFunc n e)
| AddOnNodesChangeMiddleware    MiddlewareKey (Array (NodeChange n) -> Array (NodeChange n))
| RemoveOnNodesChangeMiddleware MiddlewareKey
| AddOnEdgesChangeMiddleware    MiddlewareKey (Array (EdgeChange e) -> Array (EdgeChange e))
| RemoveOnEdgesChangeMiddleware MiddlewareKey
```

The `RemoveSelectionChangeHandler` case removes by JS reference
equality (mirrors the current `unsafeRefEq`-based filter in the hook).

## Files touched

- `src/React/Store/Action.purs` — add the constructors above.
- `src/React/Store/Reduce.purs` — add a case for each.
- `src/React/Hook/Listeners.purs` — replace `dispatch (PatchState …)`
  calls with the named-action equivalents.
- `src/React/Hook/Middleware.purs` — same.

The reducer cases are all pure state mutators (no `Effect_` emission),
so the existing `reduce` shape is preserved.

## Acceptance criteria

- `purs compile` passes with zero warnings.
- `React.Hook.Listeners` and `React.Hook.Middleware` contain no
  `PatchState` calls.
- Behaviour is unchanged: the same fields are updated with the same
  values in the same order.

## Prerequisite tickets

- 026 (store / reducer foundation)
- 029, 031 (the hooks whose bodies are being rewritten)
