module Test.React.Hook.OnInitTiming (runOnInitTimingTests) where

import Prelude

import Boundary.Elements (JsNode, nodeIn)
import Boundary.Undefined (Undefinable, fromUndefinable)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Uncurried (EffectFn1, mkEffectFn1, runEffectFn1)
import Foreign (Foreign)
import React.Hook.Listeners (useOnInitHandler)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (createStore)
import Unsafe.Coerce (unsafeCoerce)

type Renderer = { render :: EffectFn1 (Effect Unit) Unit, unmount :: Effect Unit }
type Session =
  { render :: EffectFn1 (Undefinable (EffectFn1 Foreign Unit)) Unit
  , ready :: EffectFn1 Boolean Unit
  , unmount :: Effect Unit
  }

foreign import initialNode :: JsNode
foreign import newRenderer :: Foreign -> Effect Renderer
foreign import checkTiming :: EffectFn1 (Effect Session) Unit

runOnInitTimingTests :: Effect Unit
runOnInitTimingTests = runEffectFn1 checkTiming do
  store <- createStore ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign)
    { nodes = Just [ nodeIn initialNode ] })
  renderer <- newRenderer (unsafeCoerce (Just store))
  pure
    { render: mkEffectFn1 \raw -> do
        let callback = map (\fn flow -> runEffectFn1 fn (unsafeCoerce flow)) (fromUndefinable raw)
        runEffectFn1 renderer.render (unsafeCoerce (useOnInitHandler callback) :: Effect Unit)
    , ready: mkEffectFn1 \ready ->
        -- Only the platform controller's presence is read by this hook.
        store.dispatch (PatchState _ { panZoom = if ready then Just (unsafeCoerce {}) else Nothing })
    , unmount: renderer.unmount
    }
