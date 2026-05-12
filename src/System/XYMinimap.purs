-- | Minimap pan/zoom controller — port of
-- | `xyflow-main/packages/system/src/xyminimap/index.ts`.
-- |
-- | The TS factory creates a d3 selection on the minimap canvas, attaches a
-- | d3-zoom behavior with start/zoom handlers, and exposes the d3 `pointer`
-- | helper alongside `update`/`destroy`. The PS port reuses the d3 FFI
-- | introduced in tickets 016 and 018.
module System.XYMinimap
  ( XYMinimapInstance
  , XYMinimapParams
  , XYMinimapUpdate
  , defaultXYMinimapUpdate
  , createXYMinimap
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Ref as Ref
import Foreign (Foreign)
import Web.DOM.Element (Element)
import System.FFI.D3Selection (D3Selection, d3Pointer, d3Select)
import System.FFI.D3Zoom
  ( D3ZoomEvent
  , selectionCallZoom
  , setZoomOn
  , zoomCreate
  , zoomEventSourceEvent
  )
import System.Types.Connection (Viewport)
import System.Types.Geometry
  ( CoordinateExtent(..)
  , Transform(..)
  , XYPosition
  )
import System.Types.PanZoom (PanZoomInstance)
import System.Utils.General (isMacOs)

type XYMinimapParams =
  { panZoom :: PanZoomInstance
  , domNode :: Element
  , getTransform :: Effect Transform
  , getViewScale :: Effect Number
  }

type XYMinimapUpdate =
  { translateExtent :: CoordinateExtent
  , width :: Number
  , height :: Number
  , inversePan :: Boolean
  , zoomStep :: Number
  , pannable :: Boolean
  , zoomable :: Boolean
  }

type XYMinimapInstance =
  { update :: XYMinimapUpdate -> Effect Unit
  , destroy :: Effect Unit
  , pointer :: Element -> Foreign -> Effect XYPosition
  }

-- | TS uses `zoomStep = 1`, `pannable = true`, `zoomable = true`,
-- | `inversePan = false` as defaults for omitted fields. PS callers must
-- | supply all fields, so we expose the defaults as a starter record they
-- | can override with field updates.
defaultXYMinimapUpdate :: CoordinateExtent -> Number -> Number -> XYMinimapUpdate
defaultXYMinimapUpdate translateExtent width height =
  { translateExtent
  , width
  , height
  , inversePan: false
  , zoomStep: 1.0
  , pannable: true
  , zoomable: true
  }

createXYMinimap :: XYMinimapParams -> Effect XYMinimapInstance
createXYMinimap params = do
  selection <- d3Select params.domNode
  -- The TS source allocates `panStart` per-update inside the closure.
  -- We hoist it to a per-instance `Ref` so successive `update` calls share
  -- the cell — semantically equivalent because each `update` overwrites it
  -- in the start handler before the move handler reads it.
  panStart <- Ref.new { x: 0.0, y: 0.0 }

  let
    update :: XYMinimapUpdate -> Effect Unit
    update upd = do
      zoomBehavior <- zoomCreate
      _ <- setZoomOn "start" (panStartHandler panStart) zoomBehavior
      _ <- setZoomOn "zoom"
        (if upd.pannable then panHandler params upd selection panStart
         else \_ -> pure unit)
        zoomBehavior
      _ <- setZoomOn "zoom.wheel"
        (if upd.zoomable then zoomHandler params upd
         else \_ -> pure unit)
        zoomBehavior
      selectionCallZoom selection zoomBehavior

    destroy :: Effect Unit
    destroy = void (setZoomOn "zoom" (\_ -> pure unit) =<< zoomCreate)

    pointer :: Element -> Foreign -> Effect XYPosition
    pointer container ev = d3Pointer ev container

  pure { update, destroy, pointer }

-- | Cache the start pointer position. d3 fires `start` on every mousedown/
-- | touchstart; we only update on those (matching TS).
panStartHandler :: Ref.Ref XYPosition -> D3ZoomEvent -> Effect Unit
panStartHandler panStart event = do
  let src = zoomEventSourceEvent event
  isMouseDown <- sourceTypeIs src "mousedown"
  isTouchStart <- sourceTypeIs src "touchstart"
  when (isMouseDown || isTouchStart) do
    pos <- sourceClientXY src
    Ref.write pos panStart

-- | Pan delta -> setViewportConstrained call. The TS source bypasses the
-- | wait on `setViewportConstrained` (it's an awaitable Promise that we
-- | fire-and-forget); PS uses `launchAff_`.
panHandler
  :: XYMinimapParams
  -> XYMinimapUpdate
  -> D3Selection
  -> Ref.Ref XYPosition
  -> D3ZoomEvent
  -> Effect Unit
panHandler params upd _sel panStart event = do
  let src = zoomEventSourceEvent event
  isMove <- sourceTypeIs src "mousemove"
  isTouch <- sourceTypeIs src "touchmove"
  when (isMove || isTouch) do
    Transform t <- params.getTransform
    cur <- sourceClientXY src
    prev <- Ref.read panStart
    let
      panDx = cur.x - prev.x
      panDy = cur.y - prev.y
    Ref.write cur panStart
    viewScale <- params.getViewScale
    let
      moveScale =
        viewScale * (max t.scale (logN t.scale))
          * (if upd.inversePan then -1.0 else 1.0)
      position :: Viewport
      position =
        { x: t.tx - panDx * moveScale
        , y: t.ty - panDy * moveScale
        , zoom: t.scale
        }
      extent = CoordinateExtent
        { minX: 0.0, minY: 0.0, maxX: upd.width, maxY: upd.height }
    launchAff_ $ void $ params.panZoom.setViewportConstrained position
      extent upd.translateExtent

zoomHandler
  :: XYMinimapParams
  -> XYMinimapUpdate
  -> D3ZoomEvent
  -> Effect Unit
zoomHandler params upd event = do
  let src = zoomEventSourceEvent event
  isWheel <- sourceTypeIs src "wheel"
  when isWheel do
    Transform t <- params.getTransform
    ctrl <- sourceCtrlKey src
    mac <- isMacOs
    let factor = if ctrl && mac then 10.0 else 1.0
    delta <- sourceDeltaY src
    mode <- sourceDeltaMode src
    let
      mult
        | mode == 1 = 0.05
        | mode /= 0 = 1.0
        | otherwise = 0.002
      pinchDelta = (-delta) * mult * upd.zoomStep
      nextZoom = t.scale * powN 2.0 (pinchDelta * factor)
    launchAff_ $ void $ params.panZoom.scaleTo nextZoom Nothing

-- ----------------------------------------------------------------------------
-- FFI: tiny event accessors. `Foreign` keeps the source event opaque on the
-- PS side; the JS layer reads the relevant fields.
-- ----------------------------------------------------------------------------

foreign import sourceTypeIs :: Foreign -> String -> Effect Boolean
foreign import sourceClientXY :: Foreign -> Effect XYPosition
foreign import sourceCtrlKey :: Foreign -> Effect Boolean
foreign import sourceDeltaY :: Foreign -> Effect Number
foreign import sourceDeltaMode :: Foreign -> Effect Int
foreign import logN :: Number -> Number
foreign import powN :: Number -> Number -> Number

