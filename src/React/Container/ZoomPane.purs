-- | `<ZoomPane />` — pan/zoom interaction surface backed by the
-- | d3-zoom controller (`System.XYPanZoom`, ticket 018). Mirrors
-- | `xyflow-main/packages/react/src/container/ZoomPane/index.tsx`.
-- |
-- | Lifecycle:
-- |
-- |   1. **Mount.** Instantiate `XYPanZoom` against the rendered
-- |      `<div ref={paneRef}>`. Cache the instance in a `useRef` and
-- |      also write it into the store (`state.panZoom`) so other hooks
-- |      (`useViewportHelper`, the future `<ReactFlow />` root) can
-- |      drive the same controller. Also publish the seeded
-- |      `state.transform` and `state.domNode` (the closest
-- |      `.react-flow` ancestor).
-- |   2. **Update.** On every render, call `panZoom.update` with the
-- |      latest `PanZoomUpdateOptions` so prop changes (zoom modes,
-- |      classes, callbacks) take effect.
-- |   3. **Unmount.** `panZoom.destroy` tears down d3's zoom handlers.
-- |
-- | **Callback wiring.** The lifecycle callbacks (`onMove*`,
-- | `onViewportChange*`) live in the store, not on this component's
-- | props — TS reads them via `store.getState()` inside each d3 tick
-- | (TS lines 78–92) so the most recent reference is fired. The
-- | matching prop fields on `ZoomPaneProps` are kept for external
-- | shape parity but not consulted here.
-- |
-- | **`onTransformChange`.** Always fires the optional
-- | `props.onViewportChange`; commits to `state.transform` only when
-- | `isControlledViewport` is false (matches TS lines 57-65).
module React.Container.ZoomPane
  ( zoomPane
  , module React.Types.Component
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (ReactComponent)
import React.Basic.Hooks (Hook, UnsafeReference(..), memo, reactChildrenToArray, reactComponentWithChildren, readRef, useEffect, useEffectOnce, useRef, writeRef)
import React.Basic.Hooks as React
import React.FFI.DOM (div_)
import React.Hook.KeyPress (useKeyPress)
import React.Hook.ResizeHandler (useResizeHandler)
import React.Hook.Store (UseStoreApi, useStore, useStoreApi)
import React.Types.Component (ZoomPaneProps)
import React.Types.Store (ReactFlowState)
import System.Types.Connection (ConnectionState(..))
import System.Types.Geometry (Transform(..), mkTransform)
import System.Types.PanZoom (PanZoomInstance)
import System.XYPanZoom (createXYPanZoom)
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML.HTMLDivElement (HTMLDivElement, toHTMLElement)
import Web.TouchEvent.TouchEvent (TouchEvent)
import Web.UIEvent.MouseEvent (MouseEvent)

-- ----------------------------------------------------------------------------
-- FFI
-- ----------------------------------------------------------------------------

-- | `Element.closest('.react-flow')` — walks ancestors to find the
-- | root flow `<div>`. Returns `Nothing` when the pane isn't yet
-- | parented into a `.react-flow` container.
foreign import closestReactFlowRootImpl
  :: HTMLDivElement -> Effect (Nullable HTMLDivElement)

toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

-- ----------------------------------------------------------------------------
-- Store slice
-- ----------------------------------------------------------------------------

newtype ZoomPaneSlice = ZoomPaneSlice
  { userSelectionActive :: Boolean
  , lib :: String
  , connectionInProgress :: Boolean
  }

derive instance newtypeZoomPaneSlice :: Newtype ZoomPaneSlice _
derive newtype instance eqZoomPaneSlice :: Eq ZoomPaneSlice

selectSlice :: forall n e. ReactFlowState n e -> ZoomPaneSlice
selectSlice s = ZoomPaneSlice
  { userSelectionActive: s.userSelectionActive
  , lib: s.lib
  , connectionInProgress: case s.connection of
      ConnectionInProgress _ -> true
      NoConnection -> false
  }

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------

-- | TS passes the raw `MouseEvent | TouchEvent | null` straight to
-- | `onMoveStart` / `onMove` / `onMoveEnd`. The PS `OnMove` callback
-- | only carries the mouse case; touch events are dropped. Matches the
-- | shape `React.Types.General.OnMove` exposes today.
mouseFromEvt :: Maybe (Either MouseEvent TouchEvent) -> Maybe MouseEvent
mouseFromEvt = case _ of
  Just (Left me) -> Just me
  _ -> Nothing

-- | Phantom marker so `useEffect`'s `Eq` deps constraint has a single
-- | reference-equality target (same trick as `Drag.DragDepsToken`).
foreign import data ZoomPaneDepsToken :: Type

-- | Bundle the three deps into a record before erasing the type. A point-free
-- | `unsafeCoerce` at this multi-arity does *not* work at runtime — PS curries
-- | the call so `asUpdateDeps p s t` becomes `((id p) s) t`, which would try
-- | to call `props` as a function. Threading through an explicit record sidesteps
-- | the curry trap while preserving the reference-equality semantics.
asUpdateDeps
  :: ZoomPaneProps -> ZoomPaneSlice -> Boolean -> ZoomPaneDepsToken
asUpdateDeps p s t = unsafeCoerce { p, s, t }

-- ----------------------------------------------------------------------------
-- Component
-- ----------------------------------------------------------------------------

zoomPane :: ReactComponent ZoomPaneProps
zoomPane =
  unsafePerformEffect $ memo $ reactComponentWithChildren "ZoomPane"
    \(props :: ZoomPaneProps) -> React.do
      store <- (useStoreApi :: Hook UseStoreApi _)
      slice <- useStore selectSlice
      zoomActivationKeyPressed <- useKeyPress props.zoomActivationKeyCode Nothing

      paneRef <- useRef (toNullable Nothing :: Nullable HTMLDivElement)
      panZoomRef <- useRef (Nothing :: Maybe PanZoomInstance)

      useResizeHandler paneRef Nothing

      -- ---- init: create panZoom once on mount ----------------------------
      useEffectOnce do
        mDiv <- toMaybe <$> readRef paneRef
        case mDiv of
          Nothing -> pure (pure unit)
          Just divEl -> do
            let domEl = toHTMLElement divEl
            inst <- createXYPanZoom
              { domNode: domEl
              , minZoom: props.minZoom
              , maxZoom: props.maxZoom
              , translateExtent: props.translateExtent
              , viewport: props.defaultViewport
              , onDraggingChange: \dragging ->
                  store.setState \prev ->
                    if prev.paneDragging == dragging then prev
                    else prev { paneDragging = dragging }
              , onPanZoomStart: Just \evt vp -> do
                  s <- store.getState
                  for_ s.onMoveStart \cb -> cb (mouseFromEvt evt) vp
                  for_ s.onViewportChangeStart \cb -> cb vp
              , onPanZoom: Just \evt vp -> do
                  s <- store.getState
                  for_ s.onMove \cb -> cb (mouseFromEvt evt) vp
                  for_ s.onViewportChange \cb -> cb vp
              , onPanZoomEnd: Just \evt vp -> do
                  s <- store.getState
                  for_ s.onMoveEnd \cb -> cb (mouseFromEvt evt) vp
                  for_ s.onViewportChangeEnd \cb -> cb vp
              }
            writeRef panZoomRef (Just inst)
            vp <- inst.getViewport
            rootDiv <- closestReactFlowRootImpl divEl
            store.setState \s -> s
              { panZoom = Just inst
              , transform = mkTransform vp.x vp.y vp.zoom
              , domNode = toMaybe rootDiv
              }
            pure do
              mInst <- readRef panZoomRef
              for_ mInst _.destroy

      -- ---- update: push latest options on every dep change ----------------
      useEffect
        (UnsafeReference (asUpdateDeps props slice zoomActivationKeyPressed))
        do
          mInst <- readRef panZoomRef
          for_ mInst \inst ->
            inst.update
              { onPaneContextMenu: case props.onPaneContextMenu of
                  Just _ -> Just (pure unit)
                  Nothing -> Nothing
              , zoomOnScroll: props.zoomOnScroll
              , zoomOnPinch: props.zoomOnPinch
              , panOnScroll: props.panOnScroll
              , panOnScrollSpeed: props.panOnScrollSpeed
              , panOnScrollMode: props.panOnScrollMode
              , zoomOnDoubleClick: props.zoomOnDoubleClick
              , panOnDrag: props.panOnDrag
              , zoomActivationKeyPressed
              , preventScrolling: props.preventScrolling
              , noPanClassName: props.noPanClassName
              , userSelectionActive:
                  (case slice of ZoomPaneSlice s -> s.userSelectionActive)
              , noWheelClassName: props.noWheelClassName
              , lib: (case slice of ZoomPaneSlice s -> s.lib)
              , onTransformChange: \(Transform t) -> do
                  for_ props.onViewportChange \cb ->
                    cb { x: t.tx, y: t.ty, zoom: t.scale }
                  when (not props.isControlledViewport) do
                    store.setState \s -> s { transform = Transform t }
              , connectionInProgress:
                  (case slice of ZoomPaneSlice s -> s.connectionInProgress)
              , selectionOnDrag: props.selectionOnDrag
              , paneClickDistance: props.paneClickDistance
              }
          pure (pure unit)

      pure $
        div_
          { ref: paneRef
          , className: "react-flow__renderer"
          , style: toForeignStyle
              { position: "absolute"
              , width: "100%"
              , height: "100%"
              , top: 0
              , left: 0
              }
          }
          (reactChildrenToArray props.children)
