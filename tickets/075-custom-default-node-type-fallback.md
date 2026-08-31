# 075 — Unknown node type ignores a user-supplied `default` in `nodeTypes`

## Context

Found by the [071](071-version-drift-audit-12-3-to-12-11.md) changelog sweep.
This is the sweep's one genuine, still-open **behavioral** divergence: PSFlow
carries the pre-fix behavior of upstream
[#5384](https://github.com/xyflow/xyflow/pull/5384).

When a node's `type` matches neither `nodeTypes` nor the built-in registry,
`resolveNodeComponent` falls back to a default component.
`src/React/Component/NodeWrapper.purs:188-200`:

```purescript
Nothing -> do
  for_ mOnError \cb -> cb "003" (errorMessage (E003 nodeType))
  case Object.lookup "default" builtinNodeTypes of
    Just c -> pure { nodeType: "default", component: c }
```

It goes straight to `builtinNodeTypes`. Upstream
(`xyflow/packages/react/src/components/NodeWrapper/index.tsx:61`) checks the
user's map first:

```ts
NodeComponent = nodeTypes?.['default'] || builtinNodeTypes.default;
```

**Effect:** a user who registers a custom `default` node type gets it for nodes
that explicitly say `type: "default"` (the earlier lookup at `:185` finds it),
but *not* for nodes with an unrecognised type — those silently fall back to the
built-in component instead of the user's. Inconsistent within a single flow,
which is what makes it a bug rather than a defensible simplification.

[#5735](https://github.com/xyflow/xyflow/pull/5735) ("Allow `type` field to be
missing in `BuiltInNode`") is bundled here: PSFlow already defaults a missing
type to `"default"` correctly (`edgeTypeInit`-style handling at `:321` has the
edge analogue), so only the fallback above is wrong.

## Why this was not fixed inline in 071

The fix is one expression, but 071's triage rule requires that an existing gate
extend to catch it with ≤1 new assertion and no new fixture. It fails both:
`resolveNodeComponent` is private to `NodeWrapper` (the module exports only
`nodeWrapper`), and no example fixture registers a custom `default` node type.
Gating it needs a new fixture *and* route, which is precisely the scope the cap
exists to keep out of 071.

## Scope

One-line change plus its guard:

```purescript
case Object.lookup "default" typesObj of
  Just c -> pure { nodeType: "default", component: c }
  Nothing -> case Object.lookup "default" builtinNodeTypes of
    ...
```

Check whether `resolveEdgeComponent`
(`src/React/Component/EdgeWrapper.purs:225-237`) has the same shape — it looks
structurally identical and likely needs the same fix for `edgeTypes`.

## Acceptance criteria

- An unknown node type resolves to `nodeTypes['default']` when the user supplies
  one, and to the built-in only otherwise.
- The edge path is checked and fixed if it shares the defect.
- A fixture registering a custom `default` node type, plus a spec asserting an
  unknown-typed node renders it. Reverting the fix fails that spec.
- `npm run parity:surface`, `spago test`, `npm run test:smoke` stay green.
- PRs #5384 and #5735 flip from `not-ported` to a covered bucket in
  `parity/changelog-audit/verdicts.json`.

## Source files

- `src/React/Component/NodeWrapper.purs:188-200` — the defect
- `src/React/Component/EdgeWrapper.purs:225-237` — check for the same shape
- `xyflow/packages/react/src/components/NodeWrapper/index.tsx:55-61` — upstream
