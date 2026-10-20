-- | Where `<Background />`'s pattern starts: the viewport's position,
-- | wrapped by the gap.
-- |
-- | The local proxy for the report's `wheel-zoom-from-identity-viewport`
-- | scenario, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `Background.tsx` sets the pattern's
-- | `x={transform[0] % scaledGap[0]}` and `y={transform[1] % scaledGap[1]}`.
-- | JavaScript's `%` takes the sign of the dividend, so a viewport left of
-- | or above the origin gives a negative offset. ps-flow's `modN` floored,
-- | which gave the positive offset one gap along. The tiles land in the
-- | same places, but the attributes differ.
-- |
-- | `spago test` has no DOM, so the markup is a server render.
module Test.React.Additional.BackgroundOffset
  ( runBackgroundOffsetTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), contains)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Additional.Background (background)
import React.Basic (JSX, element)
import React.Context.Store (OpaqueStore, storeProvider)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import System.Types.Geometry (mkTransform)
import Unsafe.Coerce (unsafeCoerce)

foreign import renderMarkup :: JSX -> Effect String

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

storeToOpaque :: Store Unit Unit -> OpaqueStore
storeToOpaque = unsafeCoerce

-- | The background's markup under a viewport at (`x`, `y`), zoomed to
-- | `zoom`, with the default gap of 20.
rendered :: Number -> Number -> Number -> Effect String
rendered x y zoom = do
  store <- createStore (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
  store.dispatch (PatchState _ { transform = mkTransform x y zoom })
  renderMarkup
    ( storeProvider (Just (storeToOpaque store))
        [ element background
            { id: Nothing
            , color: Nothing
            , bgColor: Nothing
            , className: Nothing
            , patternClassName: Nothing
            , gap: Nothing
            , size: Nothing
            , offset: Nothing
            , lineWidth: Nothing
            , variant: Nothing
            , style: Nothing
            }
        ]
    )

-- | Whether the pattern in `markup` starts at (`x`, `y`), as written.
startsAt :: String -> String -> String -> Boolean
startsAt x y markup = contains (Pattern ("x=\"" <> x <> "\" y=\"" <> y <> "\"")) markup

runBackgroundOffsetTests :: Effect Unit
runBackgroundOffsetTests = do
  log "\n=== Background: the pattern starts at the viewport, wrapped by the gap ==="

  right <- rendered 45.0 30.0 1.0
  assert "a viewport right of and below the origin starts the pattern at its remainder"
    (startsAt "5" "10" right)

  left <- rendered (-45.0) (-30.0) 1.0
  assert "a viewport left of and above the origin starts it at a negative remainder, as JavaScript's % gives"
    (startsAt "-5" "-10" left)

  -- The viewport upstream reaches in `wheel-zoom-from-identity-viewport`,
  -- and the pattern's start in its trace.
  zoomed <- rendered (-204.4850628946523) (-115.02284787824192) 1.3195079107728942
  assert "the pattern starts where upstream's does in wheel-zoom-from-identity-viewport"
    (startsAt "-19.7539553864471" "-9.462215016410383" zoomed)

  whole <- rendered (-40.0) 0.0 1.0
  assert "a viewport a whole number of gaps away starts it at 0"
    (startsAt "0" "0" whole)
