-- | `<SelectionListener />` — fires `onSelectionChange` and every entry
-- | in `state.onSelectionChangeHandlers` whenever the selected-id sets
-- | change. Mirrors
-- | `xyflow/packages/react/src/components/SelectionListener/index.tsx`.
-- |
-- | TS uses two components — a thin outer one that decides whether to
-- | mount the inner subscriber, and the inner subscriber itself. PS does
-- | the same: only the inner subscribes to the store and runs an effect.
-- |
-- | **Eq-dedup via id arrays.** TS uses `shallow(a.map(id), b.map(id))`
-- | as the equality comparator for `useStore`. `Selected`'s `Eq` compares
-- | the same ids, so `useStore` keeps the selection it took when the ids
-- | last changed, and the effect reports that one, as TS's does.
module React.Provider.SelectionListener
  ( selectionListener
  , Selected(..)
  , selectSelected
  ) where

import Prelude

import Data.Array (filter, null) as Array
import Data.Foldable (for_)
import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), isJust)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (UnsafeReference(..), reactComponent, useEffect)
import React.Basic.Hooks as React
import React.Hook.Store (useStore, useStoreApi)
import React.Types.Component (SelectionListenerProps)
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import React.Types.Store (ReactFlowState)

-- | The selection `onSelectionChange` receives, compared by ids only.
newtype Selected n e = Selected { nodes :: Array (Node n), edges :: Array (Edge e) }

instance eqSelected :: Eq (Selected n e) where
  eq (Selected a) (Selected b) =
    map _.id a.nodes == map _.id b.nodes && map _.id a.edges == map _.id b.edges

-- | TS's `selector`: for each node whose internal node is selected, its
-- | `internals.userNode`, and each selected edge in the edge lookup.
-- |
-- | A selection box or a click sets the internal node's `selected` in place,
-- | which notifies nobody, so this reads it at the next update that does. A
-- | box's own `setState` follows at once, so a controlled flow reports the
-- | boxed nodes as the consumer gave them. A click has none, so it reports
-- | the node when the consumer's update lands, selected. ps-flow's internal
-- | node has no `userNode`, so the user's node is the one in `nodes`, which
-- | is also the lookup's order.
selectSelected :: forall n e. ReactFlowState n e -> Selected n e
selectSelected s = Selected
  { nodes: Array.filter
      (\n -> (Map.lookup n.id s.nodeLookup >>= _.selected) == Just true)
      s.nodes
  , edges: Array.filter
      (\e -> (Map.lookup e.id s.edgeLookup >>= _.selected) == Just true)
      s.edges
  }

-- The inner component that subscribes and runs the effect.
selectionListenerInner :: forall n e. ReactComponent (SelectionListenerProps n e)
selectionListenerInner =
  unsafePerformEffect $ reactComponent "SelectionListenerInner"
    \(props :: SelectionListenerProps n e) -> React.do
      store <- useStoreApi
      selected <- useStore selectSelected
      useEffect (UnsafeReference selected) do
        s <- store.getState
        let Selected params = selected
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
