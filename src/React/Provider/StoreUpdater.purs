-- | `<StoreUpdater />` — one-way sync from `<ReactFlow>` props into the
-- | store. Mirrors
-- | `xyflow-main/packages/react/src/components/StoreUpdater/index.tsx`.
-- |
-- | TS uses a single `useEffect` with `fieldsToTrack.map((f) => props[f])`
-- | as the dep array and a `previousFields` ref to gate per-field
-- | dispatches. The PS port spreads each field into its own `useEffect`,
-- | which caches that field's previous value and re-runs only when the `Eq`
-- | instance says it changed — the same per-field gate, with React keeping
-- | the ref. `React.Provider.TrackedProp` supplies the instance, and its
-- | docstring says why `UnsafeReference` could not: it compared the `Maybe`
-- | wrapper, which the boundary rebuilds on every render.
-- |
-- | **The seven seeded fields.** `previousFields` does not start empty. It
-- | starts as `initPrevValues`, so on the mount render `translateExtent`,
-- | `nodeOrigin`, `minZoom`, `maxZoom`, `elementsSelectable`,
-- | `noPanClassName` and `rfId` are skipped when they hold the value an
-- | omitted prop resolves to. React's deps cache cannot express that, because
-- | React runs every effect on mount whatever its deps. So those seven go
-- | through `effectOnJustFrom`, which keeps its own ref the way upstream
-- | does. It matters most for `nodeOrigin` and `rfId`. `<ReactFlow />` always
-- | hands both over, so without a seed they would dispatch on every flow's
-- | mount. It also matters for `minZoom`, `maxZoom` and `translateExtent`,
-- | whose dispatch reaches the pan-zoom instance as well as the state.
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
-- | wipes the store. TS also resets `previousFields.current` to
-- | `initPrevValues` there, and each seeded field does the same with its own
-- | ref. `effectOnJustFrom` says why that is needed.
module React.Provider.StoreUpdater
  ( storeUpdater
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Hooks (Hook, UseEffect, UseRef, coerceHook, reactComponent, readRef, useEffect, useEffectOnce, useRef, writeRef)
import React.Basic.Hooks as React
import React.Hook.Store (useStoreApi)
import React.Provider.TrackedProp (TrackedProp(..), dispatchable, initPrevValues)
import React.Store.Action (Action(..))
import React.Types.Component (StoreUpdaterProps)
import System.Constants (mergeAriaLabelConfig)

-- | One `useEffect` per tracked prop. Fires when the prop's value changes,
-- | dispatches if it is `Just _`, no-ops on `Nothing`.
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
      effectOnJustFrom initPrevValues.minZoom dispatch props.minZoom SetMinZoom
      effectOnJustFrom initPrevValues.maxZoom dispatch props.maxZoom SetMaxZoom
      effectOnJustFrom initPrevValues.translateExtent dispatch props.translateExtent
        SetTranslateExtent
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
      effectOnJustFrom initPrevValues.elementsSelectable dispatch props.elementsSelectable \v ->
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
      effectOnJustFrom initPrevValues.noPanClassName dispatch props.noPanClassName \v ->
        PatchState \s -> s { noPanClassName = v }
      effectOnJustFrom initPrevValues.nodeOrigin dispatch props.nodeOrigin \v ->
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

      -- rfId — always present (not Maybe), and seeded like the six above.
      effectOnJustFrom initPrevValues.rfId dispatch (Just props.rfId) \v ->
        PatchState \s -> s { rfId = v }

      pure mempty

-- | Helper: a `useEffect` that dispatches `mkAction v` when the field is
-- | `Just v` and its value has changed since the last render, and otherwise
-- | no-ops. `TrackedProp` is what makes "has changed" mean what it means
-- | upstream. Each call is one hook (PS's rules of hooks require a fixed
-- | sequence of hook calls per render — which is what this gives us when each
-- | `effectOnJust` is at the same source position every render).
effectOnJust
  :: forall a action
   . (action -> Effect Unit)
  -> Maybe a
  -> (a -> action)
  -> Hook (UseEffect (TrackedProp a)) Unit
effectOnJust dispatch mValue mkAction =
  useEffect (TrackedProp mValue) do
    case mValue of
      Just v -> dispatch (mkAction v)
      Nothing -> pure unit
    pure (pure unit)

-- | Hook tag for `effectOnJustFrom`: `useRef` → `useEffectOnce` →
-- | `useEffect`.
newtype UseSeededProp a hooks =
  UseSeededProp
    ( UseEffect (TrackedProp a)
        (UseEffect Unit
            (UseRef (Maybe a) hooks)
        )
    )

derive instance newtypeUseSeededProp ::
  Newtype (UseSeededProp a hooks) _

-- | `effectOnJust` for a field that upstream seeds in `initPrevValues`. The
-- | first run compares against the seed, and later runs compare against the
-- | previous prop. `effectOnJust` is this with a seed of `Nothing`, which is
-- | what every unseeded field starts from upstream too. It needs no ref,
-- | because comparing against `Nothing` is just a check for `Just`.
-- |
-- | The previous value lives in a ref, as upstream's does, because the deps
-- | cache cannot say what the first run compares against. The ref goes back
-- | to the seed on unmount, which is upstream's
-- | `previousFields.current = initPrevValues` next to its `reset()`. A real
-- | unmount discards the ref anyway. The remount that keeps it is StrictMode's
-- | simulated one, which runs every cleanup, `Reset` included, before it runs
-- | any effect again. Without the write-back, a field would compare against a
-- | value that `Reset` had just removed from the store, and skip putting it
-- | back.
effectOnJustFrom
  :: forall a action
   . Maybe a
  -> (action -> Effect Unit)
  -> Maybe a
  -> (a -> action)
  -> Hook (UseSeededProp a) Unit
effectOnJustFrom seed dispatch mValue mkAction = coerceHook React.do
  previous <- useRef seed
  useEffectOnce (pure (writeRef previous seed))
  useEffect (TrackedProp mValue) do
    prev <- readRef previous
    writeRef previous mValue
    for_ (dispatchable prev mValue) (dispatch <<< mkAction)
    pure (pure unit)
