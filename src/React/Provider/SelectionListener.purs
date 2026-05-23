-- | `<SelectionListener />` — fires `onSelectionChange` and every entry
-- | in `state.onSelectionChangeHandlers` whenever the selected-id sets
-- | change. Mirrors
-- | `xyflow-main/packages/react/src/components/SelectionListener/index.tsx`.
-- |
-- | TS uses two components — a thin outer one that decides whether to
-- | mount the inner subscriber, and the inner subscriber itself. PS does
-- | the same: only the inner subscribes to the store and runs an effect.
-- |
-- | **Eq-dedup via id arrays.** TS uses `shallow(a.map(id), b.map(id))`
-- | as the equality comparator for `useStore`. PS's `useStore` accepts
-- | any `Eq a` selector projection — projecting to `Array String`
-- | (ids only) does the same dedup job using the standard `Eq` instance
-- | for `Array String`. The full node/edge records are re-fetched from
-- | `store.getState` at fire time.
module React.Provider.SelectionListener
  ( selectionListener
  ) where

import Prelude

import Data.Array (filter, fromFoldable, mapMaybe, null) as Array
import Data.Foldable (for_)
import Data.Map (values) as Map
import Data.Maybe (Maybe(..), isJust)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (UnsafeReference(..), reactComponent, useEffect)
import React.Basic.Hooks as React
import React.Hook.Store (useStore, useStoreApi)
import React.Types.Component (SelectionListenerProps)
import React.Types.Store (ReactFlowState)

-- | Project just the selected-id arrays. `useStore` re-renders only when
-- | one of the two arrays differs (by structural `Eq`).
selectIds :: forall n e. ReactFlowState n e -> { nodes :: Array String, edges :: Array String }
selectIds s =
  { nodes: Array.mapMaybe
      (\n -> if n.selected then Just n.id else Nothing)
      (Array.fromFoldable (Map.values s.nodeLookup))
  , edges: Array.mapMaybe
      (\e -> if e.selected then Just e.id else Nothing)
      (Array.fromFoldable (Map.values s.edgeLookup))
  }

-- The inner component that subscribes and runs the effect.
selectionListenerInner :: forall n e. ReactComponent (SelectionListenerProps n e)
selectionListenerInner =
  unsafePerformEffect $ reactComponent "SelectionListenerInner"
    \(props :: SelectionListenerProps n e) -> React.do
      store <- useStoreApi
      selected <- useStore selectIds
      useEffect (UnsafeReference selected) do
        s <- store.getState
        -- TS reads `nodeLookup` and pushes `node.internals.userNode`. PS
        -- keeps `s.nodes` / `s.edges` in sync with the lookups (the
        -- reducer updates both) — filtering the arrays directly avoids
        -- the userNode hop and keeps the types as `Node n` / `Edge e`.
        let
          selectedNodes = Array.filter (\n -> n.selected) s.nodes
          selectedEdges = Array.filter (\e -> e.selected) s.edges
          params = { nodes: selectedNodes, edges: selectedEdges }
        case props.onSelectionChange of
          Just cb -> cb params
          Nothing -> pure unit
        for_ s.onSelectionChangeHandlers \fn -> fn params
        pure (pure unit)
      pure mempty

selectionListener :: forall n e. ReactComponent (SelectionListenerProps n e)
selectionListener =
  unsafePerformEffect $ reactComponent "SelectionListener"
    \(props :: SelectionListenerProps n e) -> React.do
      hasHandlers <- useStore (not <<< Array.null <<< _.onSelectionChangeHandlers)
      pure $
        if isJust props.onSelectionChange || hasHandlers
          then element selectionListenerInner props
          else mempty
