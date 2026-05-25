-- | DOM-touching utilities. Mirrors `utils/dom.ts`. Every exported function
-- | returns `Effect a` because it reads from the DOM. The TS `MouseEvent |
-- | TouchEvent` union is replaced with `Either MouseEvent TouchEvent` so the
-- | runtime `'clientX' in event` discriminator is unnecessary.
module System.Utils.Dom
  ( DOMRect
  , ShadowRoot
  , GetPointerPositionParams
  , PointerPosition
  , getPointerPosition
  , getDimensions
  , getHostForElement
  , isInputDOMNode
  , getEventPosition
  , getHandleBounds
  , elementBoundingRect
  , findViewportZoom
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (Nullable, toMaybe)
import Effect (Effect)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Document (Document)
import Web.HTML.HTMLDivElement (HTMLDivElement)
import Web.HTML.HTMLElement (HTMLElement)
import Web.TouchEvent.TouchEvent (TouchEvent)
import Web.UIEvent.KeyboardEvent (KeyboardEvent)
import Web.UIEvent.MouseEvent (MouseEvent)
import System.Types.Geometry
  ( Dimensions
  , Position(..)
  , SnapGrid
  , Transform
  , XYPosition
  )
import Data.Newtype (unwrap)
import System.Types.Handle (Handle, HandleType(..))
import System.Types.Ids (NodeId)
import System.Utils.General (pointToRendererPoint, snapPosition)

-- | Subset of a DOM `DOMRect` carried as a plain record so we don't depend on
-- | a wrapper type. Only the four fields used by xyflow are exposed.
type DOMRect =
  { left :: Number
  , top :: Number
  , width :: Number
  , height :: Number
  }

-- | TS calls this `ShadowRoot`. We don't have a PS binding, so model the host
-- | opaquely. Callers usually only need to know whether they're in document
-- | or shadow context.
foreign import data ShadowRoot :: Type

type GetPointerPositionParams =
  { transform :: Transform
  , snapGrid :: SnapGrid
  , snapToGrid :: Boolean
  , containerBounds :: Maybe DOMRect
  }

type PointerPosition =
  { x :: Number, y :: Number, xSnapped :: Number, ySnapped :: Number }

-- FFI imports ---------------------------------------------------------------

foreign import offsetWidth :: HTMLDivElement -> Effect Number
foreign import offsetHeight :: HTMLDivElement -> Effect Number

-- | Generic `getBoundingClientRect` reader; the type parameter accommodates
-- | both `HTMLDivElement` and `HTMLElement` callers.
foreign import elementBoundingRectImpl
  :: forall a. a -> Effect DOMRect

foreign import mouseClientX :: MouseEvent -> Effect Number
foreign import mouseClientY :: MouseEvent -> Effect Number
foreign import touchClientX :: TouchEvent -> Effect Number
foreign import touchClientY :: TouchEvent -> Effect Number

foreign import isInputDOMNodeImpl :: KeyboardEvent -> Effect Boolean

-- | Returns `{ tag: "doc" | "shadow", value: <opaque> }` for the given
-- | element. The element is treated opaquely on the JS side.
foreign import getRootNodeImpl
  :: HTMLElement -> Effect { tag :: String, value :: HTMLElement }

-- | Window-document fallback used when no element is supplied.
foreign import windowDocumentRoot
  :: Effect { tag :: String, value :: HTMLElement }

-- | Reads the m22 component of the `.xyflow__viewport` child's transform.
-- | Returns `Nothing` when the host has no viewport child or computed style
-- | isn't available.
foreign import findViewportZoomImpl
  :: HTMLElement -> Effect (Nullable Number)

findViewportZoom :: HTMLElement -> Effect (Maybe Number)
findViewportZoom host = map toMaybe (findViewportZoomImpl host)

-- Public surface -----------------------------------------------------------

elementBoundingRect :: forall a. a -> Effect DOMRect
elementBoundingRect = elementBoundingRectImpl

isInputDOMNode :: KeyboardEvent -> Effect Boolean
isInputDOMNode = isInputDOMNodeImpl

getHostForElement
  :: Maybe HTMLElement -> Effect (Either Document ShadowRoot)
getHostForElement m = do
  rec <- case m of
    Just el -> getRootNodeImpl el
    Nothing -> windowDocumentRoot
  pure
    if rec.tag == "shadow" then Right (unsafeCoerce rec.value :: ShadowRoot)
    else Left (unsafeCoerce rec.value :: Document)

getDimensions :: HTMLDivElement -> Effect Dimensions
getDimensions node = do
  w <- offsetWidth node
  h <- offsetHeight node
  pure { width: w, height: h }

getEventPosition
  :: Either MouseEvent TouchEvent
  -> Maybe DOMRect
  -> Effect XYPosition
getEventPosition ev bounds = do
  rawX <- case ev of
    Left me -> mouseClientX me
    Right te -> touchClientX te
  rawY <- case ev of
    Left me -> mouseClientY me
    Right te -> touchClientY te
  let
    bx = case bounds of
      Just b -> b.left
      Nothing -> 0.0
    by = case bounds of
      Just b -> b.top
      Nothing -> 0.0
  pure { x: rawX - bx, y: rawY - by }

getPointerPosition
  :: Either MouseEvent TouchEvent
  -> GetPointerPositionParams
  -> Effect PointerPosition
getPointerPosition ev params = do
  raw <- getEventPosition ev params.containerBounds
  let
    pointerPos = pointToRendererPoint raw params.transform Nothing
    snapped =
      if params.snapToGrid then snapPosition pointerPos params.snapGrid
      else pointerPos
  pure
    { x: pointerPos.x
    , y: pointerPos.y
    , xSnapped: snapped.x
    , ySnapped: snapped.y
    }

-- | Loose handle row coming back from JS. `id` and `handlePos` are
-- | `Nullable String` because `Element.getAttribute` returns `string | null`
-- | at the JS seam — they get converted to `Maybe` inside `toHandle`.
-- | Position arrives as a plain string (the `data-handlepos` attribute)
-- | and is parsed into `Position` here.
type RawHandle =
  { id :: Nullable String
  , handlePos :: Nullable String
  , x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  }

foreign import getHandleBoundsImpl
  :: String
  -> HTMLDivElement
  -> DOMRect
  -> Number
  -> String
  -> Effect (Nullable (Array RawHandle))

getHandleBounds
  :: HandleType
  -> HTMLDivElement
  -> DOMRect
  -> Number
  -> NodeId
  -> Effect (Maybe (Array Handle))
getHandleBounds ht el bounds zoom nodeId = do
  -- The FFI takes a bare `String`; unwrap and re-tag so the returned
  -- `Handle.nodeId` carries the `NodeId` newtype.
  result <- toMaybe <$> getHandleBoundsImpl (handleTypeTag ht) el bounds zoom (unwrap nodeId)
  pure (map (map (toHandle ht nodeId)) result)
  where
  handleTypeTag = case _ of
    Source -> "source"
    Target -> "target"

  toHandle handleType nid raw =
    { id: toMaybe raw.id
    , nodeId: nid
    , x: raw.x
    , y: raw.y
    , position: parsePosition (fromMaybe "" (toMaybe raw.handlePos))
    , handleType
    , width: raw.width
    , height: raw.height
    }

  -- TS coerces the raw attribute string straight to `Position`; we parse it.
  -- Unknown strings degrade to `PosTop` rather than crashing.
  parsePosition s = case s of
    "left" -> PosLeft
    "right" -> PosRight
    "top" -> PosTop
    "bottom" -> PosBottom
    _ -> PosTop
