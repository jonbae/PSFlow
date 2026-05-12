-- | Pan/zoom event filter — port of
-- | `xyflow-main/packages/system/src/xypanzoom/filter.ts`.
-- |
-- | Builds an `Effect Boolean` predicate handed to `d3-zoom` via
-- | `behavior.filter(...)`. The predicate must be `Effect`-typed because it
-- | reads DOM properties (`closest`, `target`, `event.preventDefault`).
module System.XYPanZoom.Filter
  ( FilterParams
  , createFilter
  ) where

import Prelude

import Effect (Effect)
import Foreign (Foreign)
import System.Types.PanZoom (PanOnDrag(..))
import System.XYPanZoom.Utils (isWrappedWithClass)

import Data.Array (elem) as Array
import Data.Array.NonEmpty (toArray) as NEA

type FilterParams =
  { zoomActivationKeyPressed :: Boolean
  , zoomOnScroll :: Boolean
  , zoomOnPinch :: Boolean
  , panOnDrag :: PanOnDrag
  , panOnScroll :: Boolean
  , zoomOnDoubleClick :: Boolean
  , userSelectionActive :: Boolean
  , noWheelClassName :: String
  , noPanClassName :: String
  , lib :: String
  , connectionInProgress :: Boolean
  }

-- Tags read from a DOM event via tiny FFI helpers. `Foreign` keeps the
-- d3 event opaque on the PS side.
foreign import eventType :: Foreign -> Effect String
foreign import eventButton :: Foreign -> Effect Int
foreign import eventCtrlKey :: Foreign -> Effect Boolean
foreign import eventTouchesLength :: Foreign -> Effect Int
foreign import eventPreventDefault :: Foreign -> Effect Unit

-- | Build the predicate. Mirrors the TS `createFilter` decision tree
-- | top-to-bottom; only the early-return ordering matters.
createFilter :: FilterParams -> Foreign -> Effect Boolean
createFilter p event = do
  ty <- eventType event
  button <- eventButton event
  ctrl <- eventCtrlKey event

  let
    zoomScroll = p.zoomActivationKeyPressed || p.zoomOnScroll
    pinchZoom = p.zoomOnPinch && ctrl
    isWheelEvent = ty == "wheel"

    -- Promote PanOnDrag to (allowsAnyDrag, allowedButtons).
    allowsAnyDrag = case p.panOnDrag of
      NoPan -> false
      PanAlways -> true
      PanOnButtons _ -> true
    isButtonAllowed = case p.panOnDrag of
      PanOnButtons btns -> Array.elem button (NEA.toArray btns)
      _ -> false

  -- Middle-click on a node/edge always passes. The TS source uses this for
  -- right-click pan support; the PS branch is structurally identical.
  if button == 1 && ty == "mousedown" then do
    onNode <- isWrappedWithClass event (p.lib <> "-flow__node")
    onEdge <- isWrappedWithClass event (p.lib <> "-flow__edge")
    if onNode || onEdge then pure true
    else fallthrough p ty button ctrl zoomScroll pinchZoom isWheelEvent
      allowsAnyDrag isButtonAllowed event
  else fallthrough p ty button ctrl zoomScroll pinchZoom isWheelEvent
    allowsAnyDrag isButtonAllowed event

fallthrough
  :: FilterParams
  -> String
  -> Int
  -> Boolean
  -> Boolean
  -> Boolean
  -> Boolean
  -> Boolean
  -> Boolean
  -> Foreign
  -> Effect Boolean
fallthrough p ty button ctrl zoomScroll pinchZoom isWheelEvent allowsAnyDrag
  isButtonAllowed event = do
  -- All interactions disabled?
  if not allowsAnyDrag && not zoomScroll && not p.panOnScroll
    && not p.zoomOnDoubleClick
    && not p.zoomOnPinch then
    pure false
  else if p.userSelectionActive then pure false
  else if p.connectionInProgress && not isWheelEvent then pure false
  else do
    insideNoWheel <- isWrappedWithClass event p.noWheelClassName
    if insideNoWheel && isWheelEvent then pure false
    else do
      insideNoPan <- isWrappedWithClass event p.noPanClassName
      if insideNoPan
        && (not isWheelEvent
            || (p.panOnScroll && isWheelEvent && not p.zoomActivationKeyPressed)) then
        pure false
      else if not p.zoomOnPinch && ctrl && isWheelEvent then pure false
      else do
        if not p.zoomOnPinch && ty == "touchstart" then do
          touches <- eventTouchesLength event
          if touches > 1 then do
            eventPreventDefault event
            pure false
          else pure (allowAt button ctrl isWheelEvent allowsAnyDrag
            isButtonAllowed p ty zoomScroll pinchZoom)
        else pure (allowAt button ctrl isWheelEvent allowsAnyDrag
          isButtonAllowed p ty zoomScroll pinchZoom)

-- | The tail of the filter — purely a function of the booleans/strings.
allowAt
  :: Int
  -> Boolean
  -> Boolean
  -> Boolean
  -> Boolean
  -> FilterParams
  -> String
  -> Boolean
  -> Boolean
  -> Boolean
allowAt button ctrl isWheelEvent allowsAnyDrag isButtonAllowed p ty zoomScroll
  pinchZoom
  | not zoomScroll && not p.panOnScroll && not pinchZoom && isWheelEvent = false
  | not allowsAnyDrag
      && (ty == "mousedown" || ty == "touchstart") = false
  | (case p.panOnDrag of
       PanOnButtons _ -> not isButtonAllowed && ty == "mousedown"
       _ -> false) = false
  | otherwise =
      let
        buttonAllowedFinal = case p.panOnDrag of
          PanOnButtons _ -> isButtonAllowed
          _ -> button == 0 || button <= 1
      in
        (not ctrl || isWheelEvent) && buttonAllowedFinal
