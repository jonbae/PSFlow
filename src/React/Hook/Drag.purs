-- | `useDrag` — wires `System.XYDrag` (ticket 016) into React's
-- | mount/update/unmount lifecycle. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useDrag.ts`.
-- |
-- | The lifecycle:
-- |
-- | 1. **Mount**: allocate the drag controller via `createXYDrag`. The
-- |    controller's `getStoreItems` callback closes over the store from
-- |    `useStoreApi` so each drag tick reads the latest state.
-- | 2. **Each dependency change**: call `controller.update` with the
-- |    fresh `DragUpdateParams` — the node id, the DOM element, the
-- |    selector strings. The controller itself is *not* re-created
-- |    while the controller ref holds onto a `Just` value.
-- | 3. **Unmount**: `controller.destroy` tears down d3's drag binding.
-- |
-- | Returns the `dragging :: Boolean` flag from a local `useState`
-- | that is flipped by the drag callbacks the consumer supplies in
-- | `UseDragOptions`.
module React.Hook.Drag
  ( UseDragOptions
  , UseDragHook(..)
  , DragDepsToken
  , useDrag
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable, toMaybe)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Ref as Ref
import React.Basic (Ref)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, UseRef, UseState, coerceHook, readRef, useEffect, useRef, useState)
import React.Basic.Hooks as React
import System.XYDrag (DragStoreItems, XYDragInstance, createXYDrag)
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML.HTMLDivElement (HTMLDivElement, toElement)

-- | Consumer-facing configuration. The hook itself is small; most of
-- | the drag complexity is inside `System.XYDrag`. Anything that
-- | varies per-render (the node id, selectors, the wrapper element)
-- | sits here.
type UseDragOptions nodeData edgeData =
  { wrapperRef :: Ref (Nullable HTMLDivElement)
  , nodeId :: Maybe String
  , noDragClassName :: Maybe String
  , handleSelector :: Maybe String
  , isSelectable :: Boolean
  , nodeClickDistance :: Number
  , autoPanSpeed :: Maybe Number
  -- | Closure that returns the live store snapshot used by the drag
  -- | controller. The caller typically writes
  -- | `\_ -> readStoreItems store` so each tick sees the latest state.
  , getStoreItems :: Effect (DragStoreItems nodeData edgeData)
  -- | Optional drag-event callbacks. They are passed through to the
  -- | controller and also drive the `dragging` boolean flag.
  , onDragStart :: Maybe (Effect Unit)
  , onDragEnd :: Maybe (Effect Unit)
  }

newtype UseDragHook hooks =
  UseDragHook
    ( UseEffect (UnsafeReference DragDepsToken)
        ( UseRef (Maybe XYDragInstance)
            ( UseState Boolean hooks
            )
        )
    )

-- | Phantom marker so `useEffect`'s `Eq deps` constraint has a single
-- | reference-equality target. The actual record is hidden behind
-- | `UnsafeReference` (JS reference equality).
foreign import data DragDepsToken :: Type

derive instance newtypeUseDragHook :: Newtype (UseDragHook hooks) _

useDrag
  :: forall nodeData edgeData
   . UseDragOptions nodeData edgeData
  -> Hook UseDragHook Boolean
useDrag opts = coerceHook React.do
  dragging /\ setDragging <- useState false
  controllerRef <- useRef (Nothing :: Maybe XYDragInstance)
  useEffect (UnsafeReference (asDeps opts)) do
    -- Lazily allocate the controller on first run. After that the
    -- ref keeps the same instance across re-renders so we only re-run
    -- `update`.
    mController <- Ref.read (toEffectRef controllerRef)
    controller <- case mController of
      Just c -> pure c
      Nothing -> do
        c <- createXYDrag
          { getStoreItems: opts.getStoreItems
          , onDragStart: Just \_ _ _ _ -> do
              setDragging (const true)
              case opts.onDragStart of
                Just cb -> cb
                Nothing -> pure unit
          , onDrag: Nothing
          , onDragStop: Just \_ _ _ _ -> do
              setDragging (const false)
              case opts.onDragEnd of
                Just cb -> cb
                Nothing -> pure unit
          , onNodeMouseDown: Nothing
          , autoPanSpeed: opts.autoPanSpeed
          }
        Ref.write (Just c) (toEffectRef controllerRef)
        pure c

    -- Push the current per-render config into the controller.
    mDiv <- toMaybe <$> readRef opts.wrapperRef
    case mDiv of
      Nothing -> pure unit
      Just divEl ->
        controller.update
          { noDragClassName: opts.noDragClassName
          , handleSelector: opts.handleSelector
          , isSelectable: opts.isSelectable
          , nodeId: opts.nodeId
          , domNode: toElement divEl
          , nodeClickDistance: opts.nodeClickDistance
          }

    pure do
      -- Cleanup: `useEffect` invokes this both on dep change and on
      -- unmount. Tearing the controller down + nulling the ref means
      -- the next run will lazily re-create it — slightly wasteful on
      -- dep change but correct and simple. A more granular split can
      -- come later if profiling shows it matters.
      mFinal <- Ref.read (toEffectRef controllerRef)
      case mFinal of
        Just c -> do
          c.destroy
          Ref.write Nothing (toEffectRef controllerRef)
        Nothing -> pure unit
  pure dragging

-- | Erase the option record to the opaque phantom. The wrapped value
-- | is purely a JS reference for `UnsafeReference`'s equality check;
-- | the type-level marker is only there to keep the hook chain's
-- | `UseEffect` parameter monomorphic across `nodeData`/`edgeData`.
asDeps :: forall nd ed. UseDragOptions nd ed -> DragDepsToken
asDeps = unsafeCoerce

-- | `react-basic`'s `Ref a` and `effect-ref`'s `Ref a` are
-- | structurally identical at the FFI seam — both wrap a single JS
-- | mutable cell. `useRef` returns the former; we want to use
-- | `Effect.Ref` operations on it. The cast is sound and matches the
-- | convention used elsewhere in the project.
toEffectRef :: forall a. Ref a -> Ref.Ref a
toEffectRef = unsafeCoerce
