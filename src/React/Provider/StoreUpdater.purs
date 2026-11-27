-- | `<StoreUpdater />` — one-way sync from `<ReactFlow>` props into the
-- | store. Mirrors
-- | `xyflow/packages/react/src/components/StoreUpdater/index.tsx`.
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
-- |   * `fitView` → `Assign (partial { fitViewQueued: … })` (renamed).
-- |   * `fitViewOptions` → `Assign (partial { fitViewOptions: Just … })`.
-- |   * `ariaLabelConfig` → `Assign` after running through
-- |     `mergeAriaLabelConfig`.
-- |   * Everything else → a generic `Assign` of the matching member, which
-- |     is upstream's `store.setState({ [fieldName]: fieldValue })`.
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
import React.Store.Partial (partial)
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
        Assign (partial { fitViewQueued: v })
      effectOnJust dispatch props.fitViewOptions \v ->
        Assign (partial { fitViewOptions: Just v })
      effectOnJust dispatch props.ariaLabelConfig \v ->
        Assign (partial { ariaLabelConfig: mergeAriaLabelConfig v })

      -- Generic Assign — one effect per field
      effectOnJust dispatch props.onConnect \v ->
        Assign (partial { onConnect: Just v })
      effectOnJust dispatch props.onConnectStart \v ->
        Assign (partial { onConnectStart: Just v })
      effectOnJust dispatch props.onConnectEnd \v ->
        Assign (partial { onConnectEnd: Just v })
      effectOnJust dispatch props.onClickConnectStart \v ->
        Assign (partial { onClickConnectStart: Just v })
      effectOnJust dispatch props.onClickConnectEnd \v ->
        Assign (partial { onClickConnectEnd: Just v })
      effectOnJust dispatch props.nodesDraggable \v ->
        Assign (partial { nodesDraggable: v })
      effectOnJust dispatch props.autoPanOnNodeFocus \v ->
        Assign (partial { autoPanOnNodeFocus: v })
      effectOnJust dispatch props.nodesConnectable \v ->
        Assign (partial { nodesConnectable: v })
      effectOnJust dispatch props.nodesFocusable \v ->
        Assign (partial { nodesFocusable: v })
      effectOnJust dispatch props.edgesFocusable \v ->
        Assign (partial { edgesFocusable: v })
      effectOnJust dispatch props.edgesReconnectable \v ->
        Assign (partial { edgesReconnectable: v })
      effectOnJust dispatch props.elevateNodesOnSelect \v ->
        Assign (partial { elevateNodesOnSelect: v })
      effectOnJust dispatch props.elevateEdgesOnSelect \v ->
        Assign (partial { elevateEdgesOnSelect: v })
      effectOnJust dispatch props.onNodesChange \v ->
        Assign (partial { onNodesChange: Just v })
      effectOnJust dispatch props.onEdgesChange \v ->
        Assign (partial { onEdgesChange: Just v })
      effectOnJustFrom initPrevValues.elementsSelectable dispatch props.elementsSelectable \v ->
        Assign (partial { elementsSelectable: v })
      effectOnJust dispatch props.connectionMode \v ->
        Assign (partial { connectionMode: v })
      effectOnJust dispatch props.snapGrid \v ->
        Assign (partial { snapGrid: v })
      effectOnJust dispatch props.snapToGrid \v ->
        Assign (partial { snapToGrid: v })
      effectOnJust dispatch props.connectOnClick \v ->
        Assign (partial { connectOnClick: v })
      effectOnJust dispatch props.defaultEdgeOptions \v ->
        Assign (partial { defaultEdgeOptions: Just v })
      effectOnJust dispatch props.onNodesDelete \v ->
        Assign (partial { onNodesDelete: Just v })
      effectOnJust dispatch props.onEdgesDelete \v ->
        Assign (partial { onEdgesDelete: Just v })
      effectOnJust dispatch props.onDelete \v ->
        Assign (partial { onDelete: Just v })
      effectOnJust dispatch props.onNodeDrag \v ->
        Assign (partial { onNodeDrag: Just v })
      effectOnJust dispatch props.onNodeDragStart \v ->
        Assign (partial { onNodeDragStart: Just v })
      effectOnJust dispatch props.onNodeDragStop \v ->
        Assign (partial { onNodeDragStop: Just v })
      effectOnJust dispatch props.onSelectionDrag \v ->
        Assign (partial { onSelectionDrag: Just v })
      effectOnJust dispatch props.onSelectionDragStart \v ->
        Assign (partial { onSelectionDragStart: Just v })
      effectOnJust dispatch props.onSelectionDragStop \v ->
        Assign (partial { onSelectionDragStop: Just v })
      effectOnJust dispatch props.onMoveStart \v ->
        Assign (partial { onMoveStart: Just v })
      effectOnJust dispatch props.onMove \v ->
        Assign (partial { onMove: Just v })
      effectOnJust dispatch props.onMoveEnd \v ->
        Assign (partial { onMoveEnd: Just v })
      effectOnJustFrom initPrevValues.noPanClassName dispatch props.noPanClassName \v ->
        Assign (partial { noPanClassName: v })
      effectOnJustFrom initPrevValues.nodeOrigin dispatch props.nodeOrigin \v ->
        Assign (partial { nodeOrigin: v })
      effectOnJust dispatch props.autoPanOnConnect \v ->
        Assign (partial { autoPanOnConnect: v })
      effectOnJust dispatch props.autoPanOnNodeDrag \v ->
        Assign (partial { autoPanOnNodeDrag: v })
      effectOnJust dispatch props.onError \v ->
        Assign (partial { onError: Just v })
      effectOnJust dispatch props.connectionRadius \v ->
        Assign (partial { connectionRadius: v })
      effectOnJust dispatch props.isValidConnection \v ->
        Assign (partial { isValidConnection: Just v })
      effectOnJust dispatch props.selectNodesOnDrag \v ->
        Assign (partial { selectNodesOnDrag: v })
      effectOnJust dispatch props.nodeDragThreshold \v ->
        Assign (partial { nodeDragThreshold: v })
      effectOnJust dispatch props.connectionDragThreshold \v ->
        Assign (partial { connectionDragThreshold: v })
      effectOnJust dispatch props.onBeforeDelete \v ->
        Assign (partial { onBeforeDelete: Just v })
      effectOnJust dispatch props.debug \v ->
        Assign (partial { debug: v })
      effectOnJust dispatch props.autoPanSpeed \v ->
        Assign (partial { autoPanSpeed: v })
      effectOnJust dispatch props.zIndexMode \v ->
        Assign (partial { zIndexMode: v })

      -- rfId — always present (not Maybe), and seeded like the six above.
      effectOnJustFrom initPrevValues.rfId dispatch (Just props.rfId) \v ->
        Assign (partial { rfId: v })

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
