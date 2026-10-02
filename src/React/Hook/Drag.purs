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
-- | A `disabled` drag skips step 2, so d3 never binds to the element.
-- | That is what lets a drag that starts on an undraggable node pan the
-- | pane: d3-drag's `mousedown` handler stops the event's propagation
-- | whether or not its filter then starts a drag, so a bound element
-- | never lets d3-zoom see the pointer go down. `nodeId` cannot stand in
-- | for `disabled`, because `Nothing` is how `<NodesSelection />` asks for
-- | a selection drag.
-- |
-- | Returns the `dragging :: Boolean` flag from a local `useState`
-- | that is flipped by the drag callbacks the consumer supplies in
-- | `UseDragOptions`.
module React.Hook.Drag
  ( UseDragOptions
  , UseDragHook(..)
  , DragDepsToken
  , DragBinding
  , bindDrag
  , useDrag
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable, toMaybe)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import React.Basic (Ref)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, UseRef, UseState, coerceHook, readRef, useEffect, useRef, useState, writeRef)
import React.Basic.Hooks as React
import System.Types.Ids (NodeId)
import System.XYDrag (DragStoreItems, DragUpdateParams, XYDragInstance, createXYDrag)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Element (Element)
import Web.HTML.HTMLDivElement (HTMLDivElement, toElement)

-- | Consumer-facing configuration. The hook itself is small; most of
-- | the drag complexity is inside `System.XYDrag`. Anything that
-- | varies per-render (the node id, selectors, the wrapper element)
-- | sits here.
type UseDragOptions nodeData edgeData =
  { wrapperRef :: Ref (Nullable HTMLDivElement)
  -- | Leave the element unbound. Mirrors `useDrag.ts`'s `disabled`.
  , disabled :: Boolean
  , nodeId :: Maybe NodeId
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
  -- | Called by `XYDrag.startDrag` on drag start when the node is
  -- | selectable and `selectNodesOnDrag` is on — the node wrapper wires
  -- | this to `handleNodeClick` so a click (incl. a zero-distance drag)
  -- | selects the node. Mirrors `useDrag.ts`'s `onNodeMouseDown`.
  , onNodeMouseDown :: Maybe (NodeId -> Effect Unit)
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
    mDiv <- toMaybe <$> readRef opts.wrapperRef
    bindDrag
      { disabled: opts.disabled
      , domNode: toElement <$> mDiv
      -- Lazily allocate the controller on first run. After that the
      -- ref keeps the same instance across re-renders so we only re-run
      -- `update`.
      , controller: do
          mController <- readRef controllerRef
          case mController of
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
                , onNodeMouseDown: opts.onNodeMouseDown
                , autoPanSpeed: opts.autoPanSpeed
                }
              writeRef controllerRef (Just c)
              pure c
      -- Cleanup: `useEffect` invokes this both on dep change and on
      -- unmount. Tearing the controller down + nulling the ref means
      -- the next run will lazily re-create it — slightly wasteful on
      -- dep change but correct and simple. A more granular split can
      -- come later if profiling shows it matters.
      , release: do
          mFinal <- readRef controllerRef
          for_ mFinal _.destroy
          writeRef controllerRef Nothing
      , params: \domNode ->
          { noDragClassName: opts.noDragClassName
          , handleSelector: opts.handleSelector
          , isSelectable: opts.isSelectable
          , nodeId: opts.nodeId
          , domNode
          , nodeClickDistance: opts.nodeClickDistance
          }
      }
  pure dragging

-- | What one run of `useDrag`'s effect needs, with the React ref and
-- | `createXYDrag` behind `controller` and `release` so a test can run it
-- | without a DOM.
type DragBinding =
  { disabled :: Boolean
  , domNode :: Maybe Element
  -- | The controller the ref holds, allocating one if it holds none.
  , controller :: Effect XYDragInstance
  -- | Destroy the controller the ref holds, and empty the ref.
  , release :: Effect Unit
  , params :: Element -> DragUpdateParams
  }

-- | One run of `useDrag`'s effect: bind the element and return the
-- | cleanup. Mirrors `useDrag.ts`'s second effect, which returns early,
-- | with no cleanup, when the drag is disabled or the element is not
-- | mounted.
bindDrag :: DragBinding -> Effect (Effect Unit)
bindDrag b = case b.domNode of
  Just domNode | not b.disabled -> do
    controller <- b.controller
    controller.update (b.params domNode)
    pure b.release
  _ -> pure (pure unit)

-- | Erase the option record to the opaque phantom. The wrapped value
-- | is purely a JS reference for `UnsafeReference`'s equality check;
-- | the type-level marker is only there to keep the hook chain's
-- | `UseEffect` parameter monomorphic across `nodeData`/`edgeData`.
asDeps :: forall nd ed. UseDragOptions nd ed -> DragDepsToken
asDeps = unsafeCoerce

