-- | `<StoreUpdater />` — one-way sync from `<ReactFlow>` props into the
-- | store. Mirrors
-- | `xyflow-main/packages/react/src/components/StoreUpdater/index.tsx`.
-- |
-- | TS uses a single `useEffect` with `fieldsToTrack.map((f) => props[f])`
-- | as the dep array and a `previousFields` ref to gate per-field
-- | dispatches. The PS port spreads each field into its own
-- | `useEffect (UnsafeReference props.fieldName)` — React's
-- | per-call effect ordering and identity-based gating combine to give
-- | the same observable behaviour without the manual prev-value bookkeeping.
-- |
-- | **Dispatch routing.**
-- |   * Setter-action fields (`SetNodes`, `SetEdges`, `SetMinZoom`,
-- |     `SetMaxZoom`, `SetTranslateExtent`, `SetNodeExtent`) get a
-- |     dedicated action.
-- |   * `fitView` → `PatchState (_ { fitViewQueued = … })` (renamed).
-- |   * `fitViewOptions` → `PatchState (_ { fitViewOptions = Just … })`.
-- |   * `ariaLabelConfig` → `PatchState` after running through
-- |     `mergeAriaLabelConfig`.
-- |   * Everything else → a generic `PatchState` setter on the matching
-- |     field name.
-- |
-- | **Mount/unmount.** On mount, `SetDefaultNodesAndEdges` seeds the
-- | controlled-default branch. On unmount, the reducer's `Reset` action
-- | wipes the store. TS additionally resets `previousFields.current` to
-- | `initPrevValues` on unmount — irrelevant in PS because we don't
-- | maintain a prev-ref.
module React.Provider.StoreUpdater
  ( storeUpdater
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, reactComponent, useEffect, useEffectOnce)
import React.Basic.Hooks as React
import React.Hook.Store (useStoreApi)
import React.Store.Action (Action(..))
import React.Types.Component (StoreUpdaterProps)
import System.Constants (mergeAriaLabelConfig)

-- | One `useEffect` per tracked prop. Fires when the prop's JS
-- | reference changes, dispatches if it is `Just _`, no-ops on `Nothing`.
-- |
-- | `dispatch` here is `store.dispatch`. We pass `Action n e` values that
-- | mention the same `n`/`e` as the inferred store; no annotation
-- | required.

storeUpdater :: forall n e. ReactComponent (StoreUpdaterProps n e)
storeUpdater =
  unsafePerformEffect $ reactComponent "StoreUpdater"
    \(props :: StoreUpdaterProps n e) -> React.do
      store <- useStoreApi
      let dispatch = store.dispatch

      -- Mount/unmount: seed defaults and reset on tear-down.
      useEffectOnce do
        dispatch (SetDefaultNodesAndEdges props.defaultNodes props.defaultEdges)
        pure (dispatch Reset)

      -- Setter-action fields
      effectOnJust dispatch props.nodes SetNodes
      effectOnJust dispatch props.edges SetEdges
      effectOnJust dispatch props.minZoom SetMinZoom
      effectOnJust dispatch props.maxZoom SetMaxZoom
      effectOnJust dispatch props.translateExtent SetTranslateExtent
      effectOnJust dispatch props.nodeExtent SetNodeExtent

      -- Renamed / wrapped fields
      effectOnJust dispatch props.fitView \v ->
        PatchState \s -> s { fitViewQueued = v }
      effectOnJust dispatch props.fitViewOptions \v ->
        PatchState \s -> s { fitViewOptions = Just v }
      effectOnJust dispatch props.ariaLabelConfig \v ->
        PatchState \s -> s { ariaLabelConfig = mergeAriaLabelConfig v }

      -- Generic PatchState — one effect per field
      effectOnJust dispatch props.onConnect \v ->
        PatchState \s -> s { onConnect = Just v }
      effectOnJust dispatch props.onConnectStart \v ->
        PatchState \s -> s { onConnectStart = Just v }
      effectOnJust dispatch props.onConnectEnd \v ->
        PatchState \s -> s { onConnectEnd = Just v }
      effectOnJust dispatch props.onClickConnectStart \v ->
        PatchState \s -> s { onClickConnectStart = Just v }
      effectOnJust dispatch props.onClickConnectEnd \v ->
        PatchState \s -> s { onClickConnectEnd = Just v }
      effectOnJust dispatch props.nodesDraggable \v ->
        PatchState \s -> s { nodesDraggable = v }
      effectOnJust dispatch props.autoPanOnNodeFocus \v ->
        PatchState \s -> s { autoPanOnNodeFocus = v }
      effectOnJust dispatch props.nodesConnectable \v ->
        PatchState \s -> s { nodesConnectable = v }
      effectOnJust dispatch props.nodesFocusable \v ->
        PatchState \s -> s { nodesFocusable = v }
      effectOnJust dispatch props.edgesFocusable \v ->
        PatchState \s -> s { edgesFocusable = v }
      effectOnJust dispatch props.edgesReconnectable \v ->
        PatchState \s -> s { edgesReconnectable = v }
      effectOnJust dispatch props.elevateNodesOnSelect \v ->
        PatchState \s -> s { elevateNodesOnSelect = v }
      effectOnJust dispatch props.elevateEdgesOnSelect \v ->
        PatchState \s -> s { elevateEdgesOnSelect = v }
      effectOnJust dispatch props.onNodesChange \v ->
        PatchState \s -> s { onNodesChange = Just v }
      effectOnJust dispatch props.onEdgesChange \v ->
        PatchState \s -> s { onEdgesChange = Just v }
      effectOnJust dispatch props.elementsSelectable \v ->
        PatchState \s -> s { elementsSelectable = v }
      effectOnJust dispatch props.connectionMode \v ->
        PatchState \s -> s { connectionMode = v }
      effectOnJust dispatch props.snapGrid \v ->
        PatchState \s -> s { snapGrid = v }
      effectOnJust dispatch props.snapToGrid \v ->
        PatchState \s -> s { snapToGrid = v }
      effectOnJust dispatch props.connectOnClick \v ->
        PatchState \s -> s { connectOnClick = v }
      effectOnJust dispatch props.defaultEdgeOptions \v ->
        PatchState \s -> s { defaultEdgeOptions = Just v }
      effectOnJust dispatch props.onNodesDelete \v ->
        PatchState \s -> s { onNodesDelete = Just v }
      effectOnJust dispatch props.onEdgesDelete \v ->
        PatchState \s -> s { onEdgesDelete = Just v }
      effectOnJust dispatch props.onDelete \v ->
        PatchState \s -> s { onDelete = Just v }
      effectOnJust dispatch props.onNodeDrag \v ->
        PatchState \s -> s { onNodeDrag = Just v }
      effectOnJust dispatch props.onNodeDragStart \v ->
        PatchState \s -> s { onNodeDragStart = Just v }
      effectOnJust dispatch props.onNodeDragStop \v ->
        PatchState \s -> s { onNodeDragStop = Just v }
      effectOnJust dispatch props.onSelectionDrag \v ->
        PatchState \s -> s { onSelectionDrag = Just v }
      effectOnJust dispatch props.onSelectionDragStart \v ->
        PatchState \s -> s { onSelectionDragStart = Just v }
      effectOnJust dispatch props.onSelectionDragStop \v ->
        PatchState \s -> s { onSelectionDragStop = Just v }
      effectOnJust dispatch props.onMoveStart \v ->
        PatchState \s -> s { onMoveStart = Just v }
      effectOnJust dispatch props.onMove \v ->
        PatchState \s -> s { onMove = Just v }
      effectOnJust dispatch props.onMoveEnd \v ->
        PatchState \s -> s { onMoveEnd = Just v }
      effectOnJust dispatch props.noPanClassName \v ->
        PatchState \s -> s { noPanClassName = v }
      effectOnJust dispatch props.nodeOrigin \v ->
        PatchState \s -> s { nodeOrigin = v }
      effectOnJust dispatch props.autoPanOnConnect \v ->
        PatchState \s -> s { autoPanOnConnect = v }
      effectOnJust dispatch props.autoPanOnNodeDrag \v ->
        PatchState \s -> s { autoPanOnNodeDrag = v }
      effectOnJust dispatch props.onError \v ->
        PatchState \s -> s { onError = Just v }
      effectOnJust dispatch props.connectionRadius \v ->
        PatchState \s -> s { connectionRadius = v }
      effectOnJust dispatch props.isValidConnection \v ->
        PatchState \s -> s { isValidConnection = Just v }
      effectOnJust dispatch props.selectNodesOnDrag \v ->
        PatchState \s -> s { selectNodesOnDrag = v }
      effectOnJust dispatch props.nodeDragThreshold \v ->
        PatchState \s -> s { nodeDragThreshold = v }
      effectOnJust dispatch props.connectionDragThreshold \v ->
        PatchState \s -> s { connectionDragThreshold = v }
      effectOnJust dispatch props.onBeforeDelete \v ->
        PatchState \s -> s { onBeforeDelete = Just v }
      effectOnJust dispatch props.debug \v ->
        PatchState \s -> s { debug = v }
      effectOnJust dispatch props.autoPanSpeed \v ->
        PatchState \s -> s { autoPanSpeed = v }
      effectOnJust dispatch props.zIndexMode \v ->
        PatchState \s -> s { zIndexMode = v }

      -- rfId — always present (not Maybe). One-off sync.
      useEffect (UnsafeReference props.rfId) do
        dispatch (PatchState \s -> s { rfId = props.rfId })
        pure (pure unit)

      pure mempty

-- | Helper: `useEffect (UnsafeReference m)` that dispatches `mkAction v`
-- | when `m == Just v`, otherwise no-ops. Each call is one hook (PS's
-- | rules of hooks require a fixed sequence of hook calls per render —
-- | which is what this gives us when each `effectOnJust` is at the same
-- | source position every render).
effectOnJust
  :: forall a action
   . (action -> Effect Unit)
  -> Maybe a
  -> (a -> action)
  -> Hook (UseEffect (UnsafeReference (Maybe a))) Unit
effectOnJust dispatch mValue mkAction =
  useEffect (UnsafeReference mValue) do
    case mValue of
      Just v -> dispatch (mkAction v)
      Nothing -> pure unit
    pure (pure unit)
