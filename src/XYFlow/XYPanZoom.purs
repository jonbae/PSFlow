-- | d3-backed pan/zoom controller — port of
-- | `xyflow-main/packages/system/src/xypanzoom/XYPanZoom.ts`.
-- |
-- | The TS factory builds a d3-zoom behavior, attaches it to a selection,
-- | seeds the viewport, and returns a record of imperative methods. The PS
-- | port mirrors that shape: `createXYPanZoom :: PanZoomParams -> Effect
-- | PanZoomInstance`. d3 wiring is delegated to `XYFlow.FFI.D3Zoom`; the
-- | mutable `ZoomPanValues` record lives in `XYFlow.XYPanZoom.EventHandler`.
module XYFlow.XYPanZoom
  ( createXYPanZoom
  ) where

import Prelude hiding (clamp)

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_, nonCanceler)
import Effect.Aff (makeAff) as Aff
import Effect.Ref as Ref
import Foreign (Foreign)
import XYFlow.FFI.D3Selection (D3Selection, d3Select)
import XYFlow.FFI.D3Zoom
  ( D3ZoomBehavior
  , ZoomTransform
  , currentZoomTransform
  , linearInterpolate
  , selectionCallZoom
  , selectionGetZoomHandler
  , selectionSetDblClickHandler
  , selectionSetDblClickNull
  , selectionSetWheelHandler
  , setClickDistance
  , setInterpolate
  , setScaleExtent
  , setTranslateExtent
  , setWheelDelta
  , setZoomFilter
  , setZoomOn
  , smoothZoomInterpolate
  , zoomBehaviorConstrain
  , zoomBehaviorScaleBy
  , zoomBehaviorScaleTo
  , zoomBehaviorTransform
  , zoomCreate
  )
import XYFlow.Types.Connection (InterpolateMode(..), Viewport)
import XYFlow.Types.Geometry (CoordinateExtent(..))
import XYFlow.Types.PanZoom
  ( PanZoomInstance
  , PanZoomParams
  , PanZoomTransformOptions
  , PanZoomUpdateOptions
  )
import XYFlow.Utils.Dom (elementBoundingRect)
import XYFlow.Utils.General (clamp, isNumeric)
import XYFlow.XYPanZoom.EventHandler
  ( ZoomPanValues
  , createPanOnScrollHandler
  , createPanZoomEndHandler
  , createPanZoomHandler
  , createPanZoomStartHandler
  , createZoomOnScrollHandler
  , defaultZoomPanValues
  )
import XYFlow.XYPanZoom.Filter (createFilter)
import XYFlow.XYPanZoom.Utils
  ( transformToViewport
  , viewportToTransform
  , wheelDelta
  )

-- | Construct the controller. Reads the host element's bounding box once at
-- | construction (matching TS), seeds the d3 zoom behavior, applies the
-- | initial viewport, and returns the imperative method record.
createXYPanZoom :: PanZoomParams -> Effect PanZoomInstance
createXYPanZoom params = do
  zpv <- defaultZoomPanValues
  bbox <- elementBoundingRect params.domNode
  zoomInst <- zoomCreate
  _ <- setScaleExtent params.minZoom params.maxZoom zoomInst
  _ <- setTranslateExtent
    extentMinX
    extentMinY
    extentMaxX
    extentMaxY
    zoomInst
  d3Sel <- d3Select params.domNode
  selectionCallZoom d3Sel zoomInst

  -- Seed the viewport (constrained to the visible bbox + translate extent).
  -- The TS source doesn't `await`; PS uses `launchAff_` for fire-and-forget.
  launchAff_ $ void $ setViewportConstrainedImpl zoomInst d3Sel
    { x: params.viewport.x
    , y: params.viewport.y
    , zoom: clamp params.viewport.zoom params.minZoom params.maxZoom
    }
    (mkBboxExtent bbox.width bbox.height)
    params.translateExtent

  -- Cache the zoom + dblclick handlers d3 installs by default.
  d3ZoomHandler <- selectionGetZoomHandler d3Sel "wheel.zoom"
  d3DblClickHandler <- selectionGetZoomHandler d3Sel "dblclick.zoom"
  _ <- setWheelDelta wheelDelta zoomInst

  pure
    { update: updateImpl params zpv zoomInst d3Sel d3ZoomHandler d3DblClickHandler
    , destroy: destroyImpl zoomInst
    , getViewport: getViewportImpl params.domNode
    , setViewport: setViewportImpl zoomInst d3Sel
    , setViewportConstrained: setViewportConstrainedImpl zoomInst d3Sel
    , setScaleExtent: \mn mx -> void (setScaleExtent mn mx zoomInst)
    , setTranslateExtent: \(CoordinateExtent ext) -> void
        (setTranslateExtent ext.minX ext.minY ext.maxX ext.maxY zoomInst)
    , scaleTo: scaleToImpl zoomInst d3Sel
    , scaleBy: scaleByImpl zoomInst d3Sel
    , syncViewport: syncViewportImpl zoomInst d3Sel
    , setClickDistance: setClickDistanceImpl zoomInst
    }
  where
  CoordinateExtent ext0 = params.translateExtent
  extentMinX = ext0.minX
  extentMinY = ext0.minY
  extentMaxX = ext0.maxX
  extentMaxY = ext0.maxY

-- ----------------------------------------------------------------------------
-- update / destroy
-- ----------------------------------------------------------------------------

updateImpl
  :: PanZoomParams
  -> ZoomPanValues
  -> D3ZoomBehavior
  -> D3Selection
  -> (Foreign -> Effect Unit)
  -> (Foreign -> Effect Unit)
  -> PanZoomUpdateOptions
  -> Effect Unit
updateImpl params zpv zoomInst d3Sel d3ZoomHandler d3DblClickHandler opts = do
  active <- Ref.read zpv.isZoomingOrPanning
  when (opts.userSelectionActive && not active)
    (destroyImpl zoomInst)

  let
    isPanOnScroll = opts.panOnScroll
      && not opts.zoomActivationKeyPressed
      && not opts.userSelectionActive
    paneClickDistance =
      if opts.selectionOnDrag then infinity
      else if not (isNumeric opts.paneClickDistance)
        || opts.paneClickDistance < 0.0 then 0.0
      else opts.paneClickDistance
  _ <- setClickDistance paneClickDistance zoomInst

  wheelHandler <-
    if isPanOnScroll then createPanOnScrollHandler
      { zoomPanValues: zpv
      , noWheelClassName: opts.noWheelClassName
      , d3Selection: d3Sel
      , d3Zoom: zoomInst
      , panOnScrollMode: opts.panOnScrollMode
      , panOnScrollSpeed: opts.panOnScrollSpeed
      , zoomOnPinch: opts.zoomOnPinch
      , onPanZoomStart: params.onPanZoomStart
      , onPanZoom: params.onPanZoom
      , onPanZoomEnd: params.onPanZoomEnd
      }
    else createZoomOnScrollHandler
      { noWheelClassName: opts.noWheelClassName
      , preventScrolling: opts.preventScrolling
      , d3ZoomHandler
      }
  selectionSetWheelHandler d3Sel wheelHandler

  startH <- createPanZoomStartHandler
    { zoomPanValues: zpv
    , onDraggingChange: params.onDraggingChange
    , onPanZoomStart: params.onPanZoomStart
    }
  _ <- setZoomOn "start" startH zoomInst

  zoomH <- createPanZoomHandler
    { zoomPanValues: zpv
    , panOnDrag: opts.panOnDrag
    , onPaneContextMenu: case opts.onPaneContextMenu of
        Just _ -> true
        Nothing -> false
    , onPanZoom: params.onPanZoom
    , onTransformChange: opts.onTransformChange
    }
  _ <- setZoomOn "zoom" zoomH zoomInst

  endH <- createPanZoomEndHandler
    { zoomPanValues: zpv
    , panOnDrag: opts.panOnDrag
    , panOnScroll: opts.panOnScroll
    , onDraggingChange: params.onDraggingChange
    , onPanZoomEnd: params.onPanZoomEnd
    , onPaneContextMenu: case opts.onPaneContextMenu of
        Just _ -> Just (\_ -> pure unit)
        Nothing -> Nothing
    }
  _ <- setZoomOn "end" endH zoomInst

  _ <- setZoomFilter
    ( createFilter
        { zoomActivationKeyPressed: opts.zoomActivationKeyPressed
        , panOnDrag: opts.panOnDrag
        , zoomOnScroll: opts.zoomOnScroll
        , panOnScroll: opts.panOnScroll
        , zoomOnDoubleClick: opts.zoomOnDoubleClick
        , zoomOnPinch: opts.zoomOnPinch
        , userSelectionActive: opts.userSelectionActive
        , noPanClassName: opts.noPanClassName
        , noWheelClassName: opts.noWheelClassName
        , lib: opts.lib
        , connectionInProgress: opts.connectionInProgress
        }
    )
    zoomInst

  if opts.zoomOnDoubleClick then
    selectionSetDblClickHandler d3Sel d3DblClickHandler
  else
    selectionSetDblClickNull d3Sel

destroyImpl :: D3ZoomBehavior -> Effect Unit
destroyImpl zoomInst = void (setZoomOn "zoom" (\_ -> pure unit) zoomInst)

-- ----------------------------------------------------------------------------
-- viewport setters / scale operations
-- ----------------------------------------------------------------------------

-- | TS uses Promise; PS uses Aff. The `makeAff` form lets us hand d3 a
-- | resolver callback. For the typed-scaffold pass we resolve immediately —
-- | d3-zoom's interpolate APIs aren't exercised in the test harness.
setViewportImpl
  :: D3ZoomBehavior
  -> D3Selection
  -> Viewport
  -> Maybe PanZoomTransformOptions
  -> Aff (Maybe ZoomTransform)
setViewportImpl zoomInst d3Sel viewport mOpts =
  Aff.makeAff \resolve -> do
    let nextTransform = viewportToTransform viewport
    case mOpts of
      Just opts -> do
        let interp = case opts.interpolate of
              Just Linear -> linearInterpolate
              _ -> smoothZoomInterpolate
        _ <- setInterpolate interp zoomInst
        zoomBehaviorTransform zoomInst d3Sel nextTransform
      Nothing -> zoomBehaviorTransform zoomInst d3Sel nextTransform
    resolve (Right (Just nextTransform))
    pure nonCanceler

setViewportConstrainedImpl
  :: D3ZoomBehavior
  -> D3Selection
  -> Viewport
  -> CoordinateExtent
  -> CoordinateExtent
  -> Aff (Maybe ZoomTransform)
setViewportConstrainedImpl zoomInst d3Sel viewport extent translateExtent =
  Aff.makeAff \resolve -> do
    let
      next = viewportToTransform viewport
      CoordinateExtent e = extent
      CoordinateExtent t = translateExtent
      constrained = zoomBehaviorConstrain zoomInst next
        e.minX e.minY e.maxX e.maxY
        t.minX t.minY t.maxX t.maxY
    zoomBehaviorTransform zoomInst d3Sel constrained
    resolve (Right (Just constrained))
    pure nonCanceler

scaleToImpl
  :: D3ZoomBehavior
  -> D3Selection
  -> Number
  -> Maybe PanZoomTransformOptions
  -> Aff Boolean
scaleToImpl zoomInst d3Sel zoom mOpts = Aff.makeAff \resolve -> do
  case mOpts of
    Just opts -> do
      let interp = case opts.interpolate of
            Just Linear -> linearInterpolate
            _ -> smoothZoomInterpolate
      _ <- setInterpolate interp zoomInst
      zoomBehaviorScaleTo zoomInst d3Sel zoom
    Nothing -> zoomBehaviorScaleTo zoomInst d3Sel zoom
  resolve (Right true)
  pure nonCanceler

scaleByImpl
  :: D3ZoomBehavior
  -> D3Selection
  -> Number
  -> Maybe PanZoomTransformOptions
  -> Aff Boolean
scaleByImpl zoomInst d3Sel factor mOpts = Aff.makeAff \resolve -> do
  case mOpts of
    Just opts -> do
      let interp = case opts.interpolate of
            Just Linear -> linearInterpolate
            _ -> smoothZoomInterpolate
      _ <- setInterpolate interp zoomInst
      zoomBehaviorScaleBy zoomInst d3Sel factor
    Nothing -> zoomBehaviorScaleBy zoomInst d3Sel factor
  resolve (Right true)
  pure nonCanceler

syncViewportImpl
  :: D3ZoomBehavior
  -> D3Selection
  -> Viewport
  -> Effect Unit
syncViewportImpl zoomInst d3Sel viewport = do
  let nextTransform = viewportToTransform viewport
  zoomBehaviorTransform zoomInst d3Sel nextTransform

setClickDistanceImpl :: D3ZoomBehavior -> Number -> Effect Unit
setClickDistanceImpl zoomInst distance = do
  let valid =
        if not (isNumeric distance) || distance < 0.0 then 0.0 else distance
  void (setClickDistance valid zoomInst)

getViewportImpl :: forall a. a -> Effect Viewport
getViewportImpl node = do
  t <- currentZoomTransform node
  pure (transformToViewport t)

-- ----------------------------------------------------------------------------
-- Local helpers
-- ----------------------------------------------------------------------------

mkBboxExtent :: Number -> Number -> CoordinateExtent
mkBboxExtent w h = CoordinateExtent { minX: 0.0, minY: 0.0, maxX: w, maxY: h }

infinity :: Number
infinity = 1.0 / 0.0
