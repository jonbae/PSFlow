-- | `useViewportHelper` — returns a stable record of viewport-manipulation
-- | functions over the current store. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useViewportHelper.ts`.
-- |
-- | Every animated method (`zoomIn`, `zoomOut`, `zoomTo`, `setViewport`,
-- | `setCenter`, `fitBounds`) returns `Aff Boolean` — `true` once the d3
-- | transition resolves, `false` when there is no `panZoom` instance
-- | yet. Non-animated readers (`getZoom`, `getViewport`,
-- | `screenToFlowPosition`, `flowToScreenPosition`) stay `Effect`-typed.
-- |
-- | The returned record is wrapped in `useMemo unit` so its reference is
-- | stable across re-renders — important so consumers that take the
-- | helper as a `useEffect` dep don't re-run on every render.
module React.Hook.ViewportHelper
  ( UseViewportHelper(..)
  , useViewportHelper
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (class Newtype, unwrap)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import React.Basic.Hooks (Hook, UseMemo, coerceHook, useMemo)
import React.Basic.Hooks as React
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Shell (Store)
import React.Types.Instance
  ( FitBoundsOptions
  , ScreenToFlowOptions
  , ViewportHelperFunctions
  , ZoomOptions
  )
import Effect (Effect)
import System.Types.Connection (Padding(..), PaddingValue(..), SetCenterOptions, Viewport)
import System.Types.Geometry (Rect, SnapGrid(..), Transform(..), XYPosition)
import System.Types.PanZoom (PanZoomInstance, PanZoomTransformOptions)
import System.Utils.Dom (elementBoundingRect)
import System.Utils.General (getViewportForBounds, pointToRendererPoint, rendererPointToPoint)
import Web.HTML.HTMLDivElement (toElement)

newtype UseViewportHelper hooks =
  UseViewportHelper
    (UseMemo Unit ViewportHelperFunctions (UseStoreApi hooks))

derive instance newtypeUseViewportHelper :: Newtype (UseViewportHelper hooks) _

-- | Build the helper. The hook itself is small; the heavy lifting lives
-- | in the `mkHelper` builder below, which closes over the store so each
-- | method reads the latest state on demand.
useViewportHelper :: Hook UseViewportHelper ViewportHelperFunctions
useViewportHelper = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  helper <- useMemo unit \_ -> mkHelper store
  pure helper

mkHelper :: forall n e. Store n e -> ViewportHelperFunctions
mkHelper store =
  { zoomIn: \opts -> withPanZoom \pz -> pz.scaleBy 1.2 (Just (toPzOpts opts))
  , zoomOut: \opts -> withPanZoom \pz -> pz.scaleBy (1.0 / 1.2) (Just (toPzOpts opts))
  , zoomTo: \z opts -> withPanZoom \pz -> pz.scaleTo z (Just (toPzOpts opts))
  , getZoom: do
      s <- store.getState
      pure (unwrap s.transform).scale
  , setViewport: \viewport opts -> do
      s <- liftEffect store.getState
      case s.panZoom of
        Nothing -> pure false
        Just pz -> do
          _ <- pz.setViewport viewport (Just (toPzOpts opts))
          pure true
  , getViewport: do
      Transform t <- _.transform <$> store.getState
      pure { x: t.tx, y: t.ty, zoom: t.scale }
  , setCenter: \x y opts -> setCenter store x y opts
  , fitBounds: \bounds opts -> fitBounds store bounds opts
  , screenToFlowPosition: \pos opts -> screenToFlow store pos opts
  , flowToScreenPosition: \pos -> flowToScreen store pos
  }
  where
  withPanZoom :: (PanZoomInstance -> Aff Boolean) -> Aff Boolean
  withPanZoom k = do
    s <- liftEffect store.getState
    case s.panZoom of
      Nothing -> pure false
      Just pz -> k pz

-- | Project our public `ZoomOptions` record onto the
-- | `PanZoomTransformOptions` record expected by `PanZoomInstance`
-- | methods. Both have the same shape — duration / ease / interpolate —
-- | so this is a no-op at runtime, but typed.
toPzOpts :: ZoomOptions -> PanZoomTransformOptions
toPzOpts opts =
  { duration: opts.duration
  , ease: opts.ease
  , interpolate: opts.interpolate
  }

-- | `setCenter` mirrors the upstream store action: compute the target
-- | viewport from the desired center coordinates and the current frame
-- | size, then animate `panZoom` there.
setCenter
  :: forall n e
   . Store n e
  -> Number
  -> Number
  -> SetCenterOptions
  -> Aff Boolean
setCenter store x y opts = do
  s <- liftEffect store.getState
  case s.panZoom of
    Nothing -> pure false
    Just pz -> do
      let
        nextZoom = fromMaybe s.maxZoom opts.zoom
        centerX = s.width / 2.0 - x * nextZoom
        centerY = s.height / 2.0 - y * nextZoom
        viewport :: Viewport
        viewport = { x: centerX, y: centerY, zoom: nextZoom }
      _ <- pz.setViewport viewport
        ( Just
            { duration: opts.duration
            , ease: opts.ease
            , interpolate: opts.interpolate
            }
        )
      pure true

-- | `fitBounds` computes the viewport that frames the given `Rect`
-- | (with optional padding) and animates `panZoom` there. The default
-- | padding ratio matches upstream: `0.1`.
fitBounds
  :: forall n e
   . Store n e
  -> Rect
  -> FitBoundsOptions
  -> Aff Boolean
fitBounds store bounds opts = do
  s <- liftEffect store.getState
  case s.panZoom of
    Nothing -> pure false
    Just pz -> do
      let
        padding = UniformPadding (RatioPadding (fromMaybe 0.1 opts.padding))
        viewport = getViewportForBounds
          bounds
          s.width
          s.height
          s.minZoom
          s.maxZoom
          padding
      _ <- pz.setViewport viewport
        ( Just
            { duration: opts.duration
            , ease: opts.ease
            , interpolate: opts.interpolate
            }
        )
      pure true

-- | Translate a screen-space point (client coordinates) into flow-space
-- | coordinates. When the wrapper element is unmounted the input
-- | position is returned unchanged — matches upstream's behaviour.
screenToFlow
  :: forall n e
   . Store n e
  -> XYPosition
  -> ScreenToFlowOptions
  -> Effect XYPosition
screenToFlow store clientPos opts = do
  s <- store.getState
  case s.domNode of
    Nothing -> pure clientPos
    Just divEl -> do
      bbox <- elementBoundingRect (toElement divEl)
      let
        corrected = { x: clientPos.x - bbox.left, y: clientPos.y - bbox.top }
        snapToGrid = fromMaybe s.snapToGrid opts.snapToGrid
        snapGrid = case opts.snapGrid of
          Just g -> SnapGrid g
          Nothing -> s.snapGrid
        mGrid = if snapToGrid then Just snapGrid else Nothing
      pure (pointToRendererPoint corrected s.transform mGrid)

flowToScreen
  :: forall n e
   . Store n e
  -> XYPosition
  -> Effect XYPosition
flowToScreen store flowPos = do
  s <- store.getState
  case s.domNode of
    Nothing -> pure flowPos
    Just divEl -> do
      bbox <- elementBoundingRect (toElement divEl)
      let rendererPos = rendererPointToPoint flowPos s.transform
      pure { x: rendererPos.x + bbox.left, y: rendererPos.y + bbox.top }
