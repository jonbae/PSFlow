-- | Shared resize types; the controller re-exports its original API.
module System.XYResizer.Types
  ( ControlLinePosition(..)
  , CornerPosition(..)
  , ControlPosition(..)
  , ResizeControlVariant(..)
  , ResizeControlDirection(..)
  , ResizeParams
  , ResizeParamsWithDirection
  , ResizeBoundaries
  , RequiredXYResizerChange
  , ShouldResize
  , OnResizeStart
  , OnResize
  , OnResizeEnd
  , ResizeDragEvent(..)
  , XYResizerChange
  , XYResizerChildChange
  , XYResizerInstance
  , XYResizerUpdateParams
  , XYResizerParams
  , ResizerStoreItems
  , xyResizerHandlePositions
  , xyResizerLinePositions
  ) where

import Prelude
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Foreign (Foreign)
import Web.HTML.HTMLDivElement (HTMLDivElement)
import System.Types.Geometry (NodeOrigin, SnapGrid, Transform, XYPosition)
import System.Types.Ids (NodeId)
import System.Types.Node (NodeExtent, NodeLookup)

-- | TS `ControlLinePosition = 'top' | 'bottom' | 'left' | 'right'`.
data ControlLinePosition = LineTop | LineBottom | LineLeft | LineRight

derive instance eqControlLinePosition :: Eq ControlLinePosition
derive instance ordControlLinePosition :: Ord ControlLinePosition
derive instance genericControlLinePosition :: Generic ControlLinePosition _

instance showControlLinePosition :: Show ControlLinePosition where
  show = genericShow

-- | TS `'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'`.
data CornerPosition
  = CornerTopLeft
  | CornerTopRight
  | CornerBottomLeft
  | CornerBottomRight

derive instance eqCornerPosition :: Eq CornerPosition
derive instance ordCornerPosition :: Ord CornerPosition
derive instance genericCornerPosition :: Generic CornerPosition _

instance showCornerPosition :: Show CornerPosition where
  show = genericShow

-- | TS union `ControlLinePosition | corner-position`. The PS port nests the
-- | two halves rather than flattening to 8 constructors — `getControlDirection`
-- | dispatches on this nested shape.
data ControlPosition
  = ControlLine ControlLinePosition
  | ControlCorner CornerPosition

derive instance eqControlPosition :: Eq ControlPosition
derive instance ordControlPosition :: Ord ControlPosition
derive instance genericControlPosition :: Generic ControlPosition _

instance showControlPosition :: Show ControlPosition where
  show = genericShow

-- | TS enum `ResizeControlVariant { Line, Handle }`.
data ResizeControlVariant = LineVariant | HandleVariant

derive instance eqResizeControlVariant :: Eq ResizeControlVariant
derive instance ordResizeControlVariant :: Ord ResizeControlVariant
derive instance genericResizeControlVariant :: Generic ResizeControlVariant _

instance showResizeControlVariant :: Show ResizeControlVariant where
  show = genericShow

-- | TS `'horizontal' | 'vertical'`.
data ResizeControlDirection = Horizontal | Vertical

derive instance eqResizeControlDirection :: Eq ResizeControlDirection
derive instance ordResizeControlDirection :: Ord ResizeControlDirection
derive instance genericResizeControlDirection :: Generic ResizeControlDirection _

instance showResizeControlDirection :: Show ResizeControlDirection where
  show = genericShow

-- | The TS `XY_RESIZER_HANDLE_POSITIONS` array. Translated to PS using the
-- | nested `ControlPosition` ADT.
xyResizerHandlePositions :: Array ControlPosition
xyResizerHandlePositions =
  [ ControlCorner CornerTopLeft
  , ControlCorner CornerTopRight
  , ControlCorner CornerBottomLeft
  , ControlCorner CornerBottomRight
  ]

xyResizerLinePositions :: Array ControlLinePosition
xyResizerLinePositions = [ LineTop, LineRight, LineBottom, LineLeft ]

-- ----------------------------------------------------------------------------
-- ResizeParams / boundaries / change records
-- ----------------------------------------------------------------------------

type ResizeParams =
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  }

type ResizeParamsWithDirection =
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  , direction :: { dx :: Int, dy :: Int }
  }

type ResizeBoundaries =
  { minWidth :: Number
  , minHeight :: Number
  , maxWidth :: Number
  , maxHeight :: Number
  }

-- | TS `ResizeDragEvent = D3DragEvent<...>`. Opaque newtype around `Foreign`
-- | so callers can read `sourceEvent` (mouse/touch) via FFI in the future
-- | without leaking d3 internals into the API.
newtype ResizeDragEvent = ResizeDragEvent Foreign

-- | TS callback aliases.
type ShouldResize = ResizeDragEvent -> ResizeParamsWithDirection -> Effect Boolean
type OnResizeStart = ResizeDragEvent -> ResizeParams -> Effect Unit
type OnResize = ResizeDragEvent -> ResizeParamsWithDirection -> Effect Unit
type OnResizeEnd = ResizeDragEvent -> ResizeParams -> Effect Unit

type XYResizerChange =
  { x :: Maybe Number
  , y :: Maybe Number
  , width :: Maybe Number
  , height :: Maybe Number
  }

type XYResizerChildChange =
  { id :: NodeId
  , position :: XYPosition
  , extent :: Maybe NodeExtent
  }

-- | TS `Required<XYResizerChange>` — every field non-`Maybe`.
type RequiredXYResizerChange =
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  }

-- | Subset of the store the controller reads on every drag tick.
type ResizerStoreItems nodeData =
  { nodeLookup :: NodeLookup nodeData
  , nodeOrder :: Array NodeId
  , transform :: Transform
  , snapGrid :: Maybe SnapGrid
  , snapToGrid :: Boolean
  , nodeOrigin :: NodeOrigin
  , paneDomNode :: Maybe HTMLDivElement
  }

type XYResizerParams nodeData =
  { domNode :: HTMLDivElement
  , nodeId :: NodeId
  , getStoreItems :: Effect (ResizerStoreItems nodeData)
  , onChange :: XYResizerChange -> Array XYResizerChildChange -> Effect Unit
  , onEnd :: Maybe (RequiredXYResizerChange -> Effect Unit)
  }

type XYResizerUpdateParams =
  { controlPosition :: ControlPosition
  , boundaries :: ResizeBoundaries
  , keepAspectRatio :: Boolean
  , resizeDirection :: Maybe ResizeControlDirection
  , onResizeStart :: Maybe OnResizeStart
  , onResize :: Maybe OnResize
  , onResizeEnd :: Maybe OnResizeEnd
  , shouldResize :: Maybe ShouldResize
  }

type XYResizerInstance =
  { update :: XYResizerUpdateParams -> Effect Unit
  , destroy :: Effect Unit
  }

