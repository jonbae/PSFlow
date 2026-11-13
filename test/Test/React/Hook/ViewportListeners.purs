module Test.React.Hook.ViewportListeners (runViewportListenerTests) where

import Prelude

import Boundary.Undefined (Undefinable, fromUndefinable, toUndefinable)
import Boundary.Hooks (JsUseOnViewportChangeOptions)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Ref as Ref
import Effect.Uncurried (EffectFn1, mkEffectFn1, runEffectFn1)
import Foreign (Foreign)
import React.Hook.Listeners (useOnViewportChange)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Subscribe(..), createStore)
import React.Basic.Hooks (UnsafeReference(..))
import React.Types.General (OnViewportChange)
import Unsafe.Coerce (unsafeCoerce)

-- Test callbacks use PureScript's Viewport -> Effect Unit calling convention.
type Slots =
  { onStart :: Undefinable OnViewportChange
  , onChange :: Undefinable OnViewportChange
  , onEnd :: Undefinable OnViewportChange
  }
type Renderer = { render :: EffectFn1 (Effect Unit) Unit, unmount :: Effect Unit }
type Session =
  { first :: EffectFn1 Slots Unit
  , second :: EffectFn1 Slots Unit
  , unmountFirst :: Effect Unit
  , unmountSecond :: Effect Unit
  , read :: Effect Slots
  , takeSnapshots :: Effect (Array Slots)
  , firstJs :: EffectFn1 JsUseOnViewportChangeOptions Unit
  , secondJs :: EffectFn1 JsUseOnViewportChangeOptions Unit
  }

foreign import newRenderer :: Foreign -> Effect Renderer
foreign import checkListeners :: EffectFn1 (Effect Session) Unit
foreign import publicViewportHook :: EffectFn1 JsUseOnViewportChangeOptions Unit

runViewportListenerTests :: Effect Unit
runViewportListenerTests = runEffectFn1 checkListeners do
  store <- createStore (defaultInitialStateOptions :: InitialStateOptions Foreign Foreign)
  first <- newRenderer (unsafeCoerce (Just store))
  second <- newRenderer (unsafeCoerce (Just store))
  snapshots <- Ref.new []
  let
    select state =
      { onStart: map UnsafeReference state.onViewportChangeStart
      , onChange: map UnsafeReference state.onViewportChange
      , onEnd: map UnsafeReference state.onViewportChangeEnd
      }
    unwrap (UnsafeReference callback) = callback
  _ <- case store.subscribe of
    Subscribe subscribe -> subscribe select \slots -> Ref.modify_ (_ <>
      [ { onStart: toUndefinable (map unwrap slots.onStart)
        , onChange: toUndefinable (map unwrap slots.onChange)
        , onEnd: toUndefinable (map unwrap slots.onEnd)
        }
      ]) snapshots
  let render renderer raw = runEffectFn1 renderer.render (unsafeCoerce (useOnViewportChange
        { onStart: fromUndefinable raw.onStart
        , onChange: fromUndefinable raw.onChange
        , onEnd: fromUndefinable raw.onEnd
        }) :: Effect Unit)
  pure
    { first: mkEffectFn1 (render first)
    , second: mkEffectFn1 (render second)
    , unmountFirst: first.unmount
    , unmountSecond: second.unmount
    , read: do
        state <- store.getState
        pure
          { onStart: toUndefinable state.onViewportChangeStart
          , onChange: toUndefinable state.onViewportChange
          , onEnd: toUndefinable state.onViewportChangeEnd
          }
    , takeSnapshots: do
        values <- Ref.read snapshots
        Ref.write [] snapshots
        pure values
    , firstJs: mkEffectFn1 \options -> runEffectFn1 first.render (runEffectFn1 publicViewportHook options)
    , secondJs: mkEffectFn1 \options -> runEffectFn1 second.render (runEffectFn1 publicViewportHook options)
    }
