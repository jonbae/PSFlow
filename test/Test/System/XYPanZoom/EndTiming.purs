-- | The exported end handler on the native task queue, compared with source.
module Test.System.XYPanZoom.EndTiming (runEndTimingTests) where

import Prelude

import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable, toMaybe, toNullable)
import Effect (Effect)
import Effect.Aff (launchAff_, makeAff, nonCanceler)
import Effect.Exception (error)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn1, mkEffectFn2, runEffectFn2)
import Foreign (Foreign)
import System.Types.Connection (Viewport)
import System.Types.PanZoom (PanOnDrag(..))
import System.XYPanZoom.EventHandler (createPanZoomEndHandler, defaultZoomPanValues)
import Unsafe.Coerce (unsafeCoerce)

type Factory = EffectFn2 Boolean (EffectFn2 (Nullable Foreign) Viewport Unit) (EffectFn1 Foreign Unit)

foreign import checkEndTiming :: EffectFn2 Factory (EffectFn1 (Nullable String) Unit) Unit

runEndTimingTests :: Effect Unit
runEndTimingTests = launchAff_ $ makeAff \resume -> do
  runEffectFn2 checkEndTiming factory $ mkEffectFn1 \result ->
    resume case toMaybe result of
      Nothing -> Right unit
      Just message -> Left (error message)
  pure nonCanceler
  where
  factory :: Factory
  factory = mkEffectFn2 \panOnScroll callback -> do
    zoomPanValues <- defaultZoomPanValues
    handler <- createPanZoomEndHandler
      { zoomPanValues
      , panOnDrag: PanAlways
      , panOnScroll
      , onDraggingChange: \_ -> pure unit
      , onPanZoomEnd: Just \source viewport ->
          runEffectFn2 callback (toNullable (map (either unsafeCoerce unsafeCoerce) source)) viewport
      , onPaneContextMenu: Nothing
      }
    pure (mkEffectFn1 (handler <<< unsafeCoerce))
