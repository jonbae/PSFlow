module XYFlow.Types.PanZoom
  ( PanZoomParams
  , PanZoomTransformOptions
  , PanZoomUpdateOptions
  , PanZoomInstance
  , OnPanZoom
  , OnDraggingChange
  , OnTransformChange
  , PanOnDrag(..)
  , module InterpolateModeReexport
  , module XYFlow.FFI.D3Zoom
  ) where

import Prelude

import Data.Array.NonEmpty (NonEmptyArray)
import Data.Either (Either)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Effect.Aff (Aff)
import Web.HTML.HTMLElement (HTMLElement)
import Web.TouchEvent.TouchEvent (TouchEvent)
import Web.UIEvent.MouseEvent (MouseEvent)
import XYFlow.FFI.D3Zoom (ZoomTransform(..))
import XYFlow.Types.Connection (InterpolateMode(..)) as InterpolateModeReexport
import XYFlow.Types.Connection (InterpolateMode, PanOnScrollMode, Viewport)
import XYFlow.Types.Geometry (CoordinateExtent, Transform)

type OnDraggingChange = Boolean -> Effect Unit

type OnTransformChange = Transform -> Effect Unit

-- | Pan/zoom event callback. The DOM event is `Maybe` because pan/zoom
-- | actions can be programmatic (no event); the inner `Either` distinguishes
-- | mouse from touch interactions.
type OnPanZoom = Maybe (Either MouseEvent TouchEvent) -> Viewport -> Effect Unit

type PanZoomParams =
  { domNode :: HTMLElement
  , minZoom :: Number
  , maxZoom :: Number
  , viewport :: Viewport
  , translateExtent :: CoordinateExtent
  , onDraggingChange :: OnDraggingChange
  , onPanZoomStart :: Maybe OnPanZoom
  , onPanZoom :: Maybe OnPanZoom
  , onPanZoomEnd :: Maybe OnPanZoom
  }

type PanZoomTransformOptions =
  { duration :: Maybe Int
  , ease :: Maybe (Number -> Number)
  , interpolate :: Maybe InterpolateMode
  }

type PanZoomUpdateOptions =
  { noWheelClassName :: String
  , noPanClassName :: String
  , onPaneContextMenu :: Maybe (Effect Unit)
  , preventScrolling :: Boolean
  , panOnScroll :: Boolean
  , panOnDrag :: PanOnDrag
  , panOnScrollMode :: PanOnScrollMode
  , panOnScrollSpeed :: Number
  , userSelectionActive :: Boolean
  , zoomOnPinch :: Boolean
  , zoomOnScroll :: Boolean
  , zoomOnDoubleClick :: Boolean
  , zoomActivationKeyPressed :: Boolean
  , lib :: String
  , onTransformChange :: OnTransformChange
  , connectionInProgress :: Boolean
  , paneClickDistance :: Number
  , selectionOnDrag :: Boolean
  }

-- | Service-object record returned by the d3-backed `createXYPanZoom`
-- | factory (ticket 018). Each `Effect`-returning method mutates d3 state;
-- | `Aff`-returning methods animate via d3's transition system and resolve
-- | when the animation finishes (or `Nothing`/`false` if the d3 selection
-- | was unavailable).
type PanZoomInstance =
  { update :: PanZoomUpdateOptions -> Effect Unit
  , destroy :: Effect Unit
  , getViewport :: Effect Viewport
  , setViewport :: Viewport -> Maybe PanZoomTransformOptions -> Aff (Maybe ZoomTransform)
  , setViewportConstrained :: Viewport -> CoordinateExtent -> CoordinateExtent -> Aff (Maybe ZoomTransform)
  , setScaleExtent :: Number -> Number -> Effect Unit
  , setTranslateExtent :: CoordinateExtent -> Effect Unit
  , scaleTo :: Number -> Maybe PanZoomTransformOptions -> Aff Boolean
  , scaleBy :: Number -> Maybe PanZoomTransformOptions -> Aff Boolean
  , syncViewport :: Viewport -> Effect Unit
  , setClickDistance :: Number -> Effect Unit
  }

-- | TS `boolean | number[]` is a 3-value space:
-- | `false` -> `NoPan`, `true` -> `PanAlways`, `number[]` -> `PanOnButtons`.
-- | A `NonEmptyArray` ensures the button-list case is meaningful.
data PanOnDrag
  = NoPan
  | PanAlways
  | PanOnButtons (NonEmptyArray Int)

derive instance eqPanOnDrag :: Eq PanOnDrag
derive instance genericPanOnDrag :: Generic PanOnDrag _

instance showPanOnDrag :: Show PanOnDrag where
  show = genericShow
