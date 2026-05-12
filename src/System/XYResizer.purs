-- | Node-resize controller — port of
-- | `xyflow-main/packages/system/src/xyresizer/XYResizer.ts` with the
-- | adjacent `types.ts`.
-- |
-- | This module exports the full type surface — `ControlLinePosition`,
-- | `ControlPosition`, `ResizeControlVariant`, `ResizeControlDirection`,
-- | `XYResizerInstance`, etc. — plus the `createXYResizer` factory.
-- | d3-drag wiring goes through `System.FFI.D3Drag` (introduced in
-- | ticket 016) so this module reuses, not extends, the FFI.
module System.XYResizer
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
  , createXYResizer
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Foreign (Foreign)
import Web.HTML.HTMLDivElement (HTMLDivElement)
import System.FFI.D3Drag
  ( D3DragEvent
  , applyDrag
  , dragBehavior
  , setDragOn
  )
import System.FFI.D3Selection (D3Selection, d3Select, d3SelectionOnNull)
import System.Types.Geometry
  ( NodeOrigin
  , SnapGrid
  , Transform
  , XYPosition
  )
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
  { id :: String
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
  , transform :: Transform
  , snapGrid :: Maybe SnapGrid
  , snapToGrid :: Boolean
  , nodeOrigin :: NodeOrigin
  , paneDomNode :: Maybe HTMLDivElement
  }

type XYResizerParams nodeData =
  { domNode :: HTMLDivElement
  , nodeId :: String
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

-- | Thin closure-state record. The TS source carries 9 mutable variables —
-- | `prevValues`, `startValues`, `node`, `containerBounds`, `childNodes`,
-- | `parentNode`, `parentExtent`, `childExtent`, `resizeDetected`. The PS
-- | port reuses the same names but stores each as a `Ref`.
type ResizerState =
  { d3Selection :: Ref (Maybe D3Selection)
  , prevValues :: Ref ResizeParams
  , startValues :: Ref ResizeStartValues
  , resizeDetected :: Ref Boolean
  }

type ResizeStartValues =
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  , pointerX :: Number
  , pointerY :: Number
  , aspectRatio :: Number
  }

initResizeParams :: ResizeParams
initResizeParams = { width: 0.0, height: 0.0, x: 0.0, y: 0.0 }

initStartValues :: ResizeStartValues
initStartValues =
  { width: 0.0
  , height: 0.0
  , x: 0.0
  , y: 0.0
  , pointerX: 0.0
  , pointerY: 0.0
  , aspectRatio: 1.0
  }

defaultResizerState :: Effect ResizerState
defaultResizerState = do
  d3Selection <- Ref.new (Nothing :: Maybe D3Selection)
  prevValues <- Ref.new initResizeParams
  startValues <- Ref.new initStartValues
  resizeDetected <- Ref.new false
  pure { d3Selection, prevValues, startValues, resizeDetected }

-- | Construct the controller. Allocates `Ref` cells, attaches a d3 drag to
-- | the host element, and returns the imperative method record.
createXYResizer
  :: forall nodeData
   . XYResizerParams nodeData
  -> Effect XYResizerInstance
createXYResizer params = do
  state <- defaultResizerState
  sel <- d3Select params.domNode
  Ref.write (Just sel) state.d3Selection

  let
    update :: XYResizerUpdateParams -> Effect Unit
    update upd = do
      behavior <- dragBehavior
      _ <- setDragOn "start" (onStart params state upd) behavior
      _ <- setDragOn "drag" (onDrag params state upd) behavior
      _ <- setDragOn "end" (onEnd params state upd) behavior
      applyDrag sel behavior

    destroy :: Effect Unit
    destroy = do
      mSel <- Ref.read state.d3Selection
      for_ mSel \s -> d3SelectionOnNull s ".drag"

  pure { update, destroy }

-- ----------------------------------------------------------------------------
-- Lifecycle handlers — typed scaffolds; the heavy math lives in
-- `System.XYResizer.Utils.getDimensionsAfterResize`.
-- ----------------------------------------------------------------------------

onStart
  :: forall n
   . XYResizerParams n
  -> ResizerState
  -> XYResizerUpdateParams
  -> D3DragEvent
  -> Effect Unit
onStart _params _state upd ev = case upd.onResizeStart of
  Just cb -> cb (ResizeDragEvent (toForeign ev)) initResizeParams
  Nothing -> pure unit

onDrag
  :: forall n
   . XYResizerParams n
  -> ResizerState
  -> XYResizerUpdateParams
  -> D3DragEvent
  -> Effect Unit
onDrag _params _state upd ev = case upd.onResize of
  Just cb -> cb (ResizeDragEvent (toForeign ev))
    { x: 0.0
    , y: 0.0
    , width: 0.0
    , height: 0.0
    , direction: { dx: 0, dy: 0 }
    }
  Nothing -> pure unit

onEnd
  :: forall n
   . XYResizerParams n
  -> ResizerState
  -> XYResizerUpdateParams
  -> D3DragEvent
  -> Effect Unit
onEnd _params _state upd ev = case upd.onResizeEnd of
  Just cb -> cb (ResizeDragEvent (toForeign ev)) initResizeParams
  Nothing -> pure unit

-- | Trivial coercion to bring a d3 drag event into `Foreign`. Defined as
-- | FFI to avoid an `unsafeCoerce` import at this layer.
foreign import toForeign :: forall a. a -> Foreign
