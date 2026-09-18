-- | `<StoreUpdater />`'s per-field change check, without rendering.
-- |
-- | The local proxy for "Dispatch a StoreUpdater prop only when its value
-- | changes, so fitView stops re-fitting mid-drag" (#98). The component itself
-- | needs a store context and a React tree; what the ticket is about is one
-- | `Eq` instance, so the checks run against that.
-- |
-- | Every value here is built the way the real ones are, through
-- | `Boundary.Undefined.fromUndefinable`, because that is where the bug lived:
-- | `fromUndefinable` applies `Just` at run time, so two renders of the same
-- | unchanged prop produce two `Just`s that hold one payload and are not the
-- | same object. The first check asserts both halves of that — the wrappers
-- | differ, which is what `UnsafeReference` saw and re-dispatched on, and the
-- | payloads do not.
-- |
-- | The `snapGrid` checks are the honest other half: a field whose payload the
-- | boundary rebuilds still counts as changed. That is not a gap in the
-- | comparison, it is what upstream's `!==` reports for a fresh object too.
module Test.React.Provider.TrackedProp
  ( runTrackedPropTests
  ) where

import Prelude

import Boundary.Undefined (Undefinable, defined, fromUndefinable, undefined)
import Data.Maybe (Maybe)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic.Hooks (UnsafeReference(..))
import React.Provider.TrackedProp (changed)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | One render's worth of a tracked prop: the same crossing `Boundary.Flow`
-- | performs per field, per render.
render :: forall a. Undefinable a -> Maybe a
render = fromUndefinable

-- | A payload the boundary rebuilds rather than passes through, which is what
-- | `snapGrid`, `nodeOrigin` and every converted callback look like. Taking the
-- | number as an argument keeps the compiler from lifting the array to a
-- | constant shared by both calls.
grid :: Number -> Undefinable (Array Number)
grid n = defined [ n, n ]

runTrackedPropTests :: Effect Unit
runTrackedPropTests = do
  log "running StoreUpdater tracked-prop tests..."

  -- The bug, and the fix, in one pair of assertions. `fitView: true` twice.
  let
    fitA = render (defined true)
    fitB = render (defined true)
  assert "an unchanged prop is a fresh wrapper every render"
    (UnsafeReference fitA /= UnsafeReference fitB)
  assert "an unchanged boolean does not re-dispatch"
    (not (changed fitA fitB))

  -- The dispatches that must still happen.
  assert "a boolean that flips re-dispatches"
    (changed (render (defined true)) (render (defined false)))
  assert "a prop that appears re-dispatches"
    (changed (render (undefined :: Undefinable Boolean)) (render (defined true)))
  assert "a prop that goes away re-dispatches"
    (changed (render (defined true)) (render (undefined :: Undefinable Boolean)))

  -- Upstream compares `undefined !== undefined`, which is false: an absent
  -- prop dispatches nothing, and stays that way across renders.
  assert "an absent prop does not re-dispatch"
    (not (changed (render (undefined :: Undefinable Boolean))
           (render (undefined :: Undefinable Boolean))))

  -- `minZoom`, `maxZoom`, `connectionRadius`, `autoPanSpeed`: the numbers that
  -- reach the pan-zoom instance. `noPanClassName` is the string case.
  assert "an unchanged number does not re-dispatch"
    (not (changed (render (defined 0.5)) (render (defined 0.5))))
  assert "a number that moves re-dispatches"
    (changed (render (defined 0.5)) (render (defined 2.0)))
  assert "an unchanged string does not re-dispatch"
    (not (changed (render (defined "nopan")) (render (defined "nopan"))))

  -- A payload the boundary rebuilds. Same contents, different object, so it
  -- re-dispatches — as it would upstream.
  assert "a rebuilt array re-dispatches although its contents match"
    (changed (render (grid 10.0)) (render (grid 10.0)))

  -- And the same object across two renders does not, which is what a consumer
  -- holding a stable reference gets.
  let stableGrid = grid 10.0
  assert "one array passed twice does not re-dispatch"
    (not (changed (render stableGrid) (render stableGrid)))
