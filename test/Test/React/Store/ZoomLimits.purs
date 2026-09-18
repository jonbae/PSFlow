-- | The zoom and pan limits reach the pan-zoom instance when they change.
-- |
-- | The local proxy for "Push minZoom, maxZoom and translateExtent to the
-- | pan-zoom instance when they change" (#103). `SetMinZoom`, `SetMaxZoom` and
-- | `SetTranslateExtent` used to write store state and stop there, so a flow
-- | that changed any of the three after mount kept the d3 zoom behavior it was
-- | created with. Upstream's setters push the new bound onto the instance
-- | before they `set()` (`xyflow-main/packages/react/src/store/index.ts`
-- | :358-373).
-- |
-- | What the net could measure is a gesture against the new limits, and no
-- | scenario in the corpus zooms after changing them. So the claim is checked
-- | here instead, against a recording stand-in for the instance: dispatch the
-- | action, then read what the instance was asked for.
-- |
-- | The stand-in records only the two methods under test. Every other field is
-- | inert, because the shell never calls them on this path — and if it starts
-- | to, `spago test` says so rather than a browser.
module Test.React.Store.ZoomLimits
  ( runZoomLimitsTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import System.Types.Geometry (CoordinateExtent, mkCoordinateExtent)
import System.Types.PanZoom (PanZoomInstance)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | What the instance was asked for, in call order.
type Calls =
  { scaleExtent :: Ref (Array { min :: Number, max :: Number })
  , translateExtent :: Ref (Array CoordinateExtent)
  }

newCalls :: Effect Calls
newCalls = do
  scaleExtent <- Ref.new []
  translateExtent <- Ref.new []
  pure { scaleExtent, translateExtent }

-- | A `PanZoomInstance` that records the two extent setters and does nothing
-- | else. The `Aff`-returning methods answer `Nothing`/`false`, which is the
-- | real instance's own answer when its d3 selection is unavailable.
recordingInstance :: Calls -> PanZoomInstance
recordingInstance calls =
  { update: \_ -> pure unit
  , destroy: pure unit
  , getViewport: pure { x: 0.0, y: 0.0, zoom: 1.0 }
  , setViewport: \_ _ -> pure Nothing
  , setViewportConstrained: \_ _ _ -> pure Nothing
  , setScaleExtent: \min max ->
      Ref.modify_ (_ <> [ { min, max } ]) calls.scaleExtent
  , setTranslateExtent: \ext ->
      Ref.modify_ (_ <> [ ext ]) calls.translateExtent
  , scaleTo: \_ _ -> pure false
  , scaleBy: \_ _ -> pure false
  , syncViewport: \_ -> pure unit
  , setClickDistance: \_ -> pure unit
  }

-- | A store with the recording instance already in state, which is what
-- | `ZoomPane`'s mount effect leaves behind.
mountedStore :: Calls -> Effect (Store Unit Unit)
mountedStore calls = do
  store <- createStore
    (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
  store.dispatch (PatchState _ { panZoom = Just (recordingInstance calls) })
  pure store

runZoomLimitsTests :: Effect Unit
runZoomLimitsTests = do
  log "running zoom-limit dispatch tests..."

  -- `minZoom` carries the `maxZoom` already in state, and vice versa. That
  -- pairing is upstream's: it reads the other bound from `get()` before its
  -- own `set()` lands, so the extent is always a complete pair.
  callsMin <- newCalls
  storeMin <- mountedStore callsMin
  storeMin.dispatch (SetMinZoom 0.1)
  minCalls <- Ref.read callsMin.scaleExtent
  assert "SetMinZoom sets the scale extent against the current maxZoom"
    (minCalls == [ { min: 0.1, max: 2.0 } ])

  callsMax <- newCalls
  storeMax <- mountedStore callsMax
  storeMax.dispatch (SetMaxZoom 8.0)
  maxCalls <- Ref.read callsMax.scaleExtent
  assert "SetMaxZoom sets the scale extent against the current minZoom"
    (maxCalls == [ { min: 0.5, max: 8.0 } ])

  -- Two changes in a row, which is what `<StoreUpdater />` dispatches when a
  -- flow moves both bounds at once: the second call sees the first's write.
  callsBoth <- newCalls
  storeBoth <- mountedStore callsBoth
  storeBoth.dispatch (SetMinZoom 0.1)
  storeBoth.dispatch (SetMaxZoom 8.0)
  bothCalls <- Ref.read callsBoth.scaleExtent
  assert "a second bound composes with the first rather than reverting it"
    (bothCalls == [ { min: 0.1, max: 2.0 }, { min: 0.1, max: 8.0 } ])

  stateBoth <- storeBoth.getState
  assert "both bounds also land in store state"
    (stateBoth.minZoom == 0.1 && stateBoth.maxZoom == 8.0)

  -- `translateExtent` goes through unchanged, and store state keeps its own
  -- copy because `panBy` reads the limit from there rather than from the
  -- instance (`System.Utils.Store`).
  callsExt <- newCalls
  storeExt <- mountedStore callsExt
  let extent = mkCoordinateExtent (-100.0) (-100.0) 900.0 700.0
  storeExt.dispatch (SetTranslateExtent extent)
  extCalls <- Ref.read callsExt.translateExtent
  assert "SetTranslateExtent reaches the instance with the new extent"
    (extCalls == [ extent ])

  stateExt <- storeExt.getState
  assert "the translate extent also lands in store state"
    (stateExt.translateExtent == extent)

  -- Before the pane mounts there is no instance, and `createXYPanZoom` seeds
  -- the extent from this same state when it arrives. Upstream's `panZoom?.`
  -- makes the same call a no-op; the point here is that it is not a crash.
  storeBare <- createStore
    (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
  storeBare.dispatch (SetMinZoom 0.1)
  storeBare.dispatch (SetTranslateExtent extent)
  stateBare <- storeBare.getState
  assert "with no instance yet, state still moves and nothing throws"
    (stateBare.minZoom == 0.1 && stateBare.translateExtent == extent)
