-- | Animated viewport changes on native timers, compared frame by frame with
-- | upstream's `XYPanZoom` (upstream #5276).
module Test.System.XYPanZoom.Transitions (runTransitionTests) where

import Prelude

import Boundary.Elements (JsCoordinateExtent, coordinateExtentIn)
import Boundary.Store (panZoomOut)
import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable, toMaybe, toNullable)
import Effect (Effect)
import Effect.Aff (launchAff_, makeAff, nonCanceler)
import Effect.Exception (error)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn1, runEffectFn1, runEffectFn2)
import Foreign (Foreign)
import System.Types.Connection (Viewport)
import System.Types.PanZoom (OnPanZoom)
import System.XYPanZoom (createXYPanZoom)
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML.HTMLElement (HTMLElement)

type JsOnPanZoom = EffectFn2 (Nullable Foreign) Viewport Unit

-- | Upstream's `PanZoomParams`.
type JsParams =
  { domNode :: HTMLElement
  , minZoom :: Number
  , maxZoom :: Number
  , viewport :: Viewport
  , translateExtent :: JsCoordinateExtent
  , onDraggingChange :: EffectFn1 Boolean Unit
  , onPanZoomStart :: JsOnPanZoom
  , onPanZoom :: JsOnPanZoom
  , onPanZoomEnd :: JsOnPanZoom
  }

foreign import checkTransitions
  :: EffectFn2 (EffectFn1 JsParams Foreign) (EffectFn1 (Nullable String) Unit) Unit

-- | The parameters are the only adaptation. The controller and the instance
-- | JavaScript receives, `panZoomOut`, are production code.
runTransitionTests :: Effect Unit
runTransitionTests = launchAff_ $ makeAff \resume -> do
  runEffectFn2 checkTransitions create $ mkEffectFn1 \result ->
    resume case toMaybe result of
      Nothing -> Right unit
      Just message -> Left (error message)
  pure nonCanceler
  where
  create :: EffectFn1 JsParams Foreign
  create = mkEffectFn1 \p -> panZoomOut <$> createXYPanZoom
    { domNode: p.domNode
    , minZoom: p.minZoom
    , maxZoom: p.maxZoom
    , viewport: p.viewport
    , translateExtent: coordinateExtentIn "XYPanZoom.translateExtent" p.translateExtent
    , onDraggingChange: runEffectFn1 p.onDraggingChange
    , onPanZoomStart: Just (onPanZoomIn p.onPanZoomStart)
    , onPanZoom: Just (onPanZoomIn p.onPanZoom)
    , onPanZoomEnd: Just (onPanZoomIn p.onPanZoomEnd)
    }

  onPanZoomIn :: JsOnPanZoom -> OnPanZoom
  onPanZoomIn f source = runEffectFn2 f (toNullable (map (either unsafeCoerce unsafeCoerce) source))
