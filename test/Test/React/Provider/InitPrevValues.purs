-- | `<StoreUpdater />`'s mount render, against upstream's `initPrevValues`.
-- |
-- | The local proxy for "Seed StoreUpdater's previous values the way
-- | upstream's initPrevValues does" (#106). Upstream seeds the ref its
-- | tracking effect compares against with seven values, so a prop passed at
-- | one of them is skipped on the mount render
-- | (`xyflow-main/packages/react/src/components/StoreUpdater/index.tsx`
-- | :98-111). ps-flow had no seed. React runs every effect on mount, so each of
-- | the seven dispatched once whatever it held, and `nodeOrigin` and `rfId` did
-- | so on every flow, because `<ReactFlow />` always hands both of them over.
-- |
-- | Like `Test.React.Provider.TrackedProp`, this runs without rendering. The
-- | component needs a store context and a DOM-backed React tree, and
-- | `spago test` has neither. What it checks is what each of the component's
-- | effect runs reads: the seed table, and the comparison made against it.
-- | Every prop is built the way `<ReactFlow />` builds it. An empty seed table
-- | is what the component amounted to before the fix, and it fails the first
-- | seven checks and the last one.
-- |
-- | The expected values are written out as literals on purpose. They are
-- | upstream's, quoted from `initPrevValues`, so they are the assertion and
-- | not a second home for the defaults.
module Test.React.Provider.InitPrevValues
  ( runInitPrevValuesTests
  ) where

import Prelude

import Boundary.Undefined (Undefinable, defined, fromUndefinable, undefined)
import Data.Maybe (Maybe(..), isJust, isNothing)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Container.InitValues (defaultNodeOrigin)
import React.Provider.TrackedProp (dispatchable, initPrevValues)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import React.Store.Reduce (reduce)
import React.Types.Store (ReactFlowState)
import System.Constants (infiniteExtent)
import System.Types.Geometry (CoordinateExtent, mkCoordinateExtent, mkNodeOrigin)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | One render's worth of a prop that crosses the boundary, as
-- | `Boundary.Flow` crosses each field on every render.
render :: forall a. Undefinable a -> Maybe a
render = fromUndefinable

-- | An extent with the same contents as `infiniteExtent` that is not the same
-- | object, which is what `Boundary.Flow` builds from a consumer's array.
freshInfiniteExtent :: Number -> CoordinateExtent
freshInfiniteExtent inf = mkCoordinateExtent (-inf) (-inf) inf inf

-- | A store that was moved off every default, then reset. `Reset` is what
-- | `<StoreUpdater />`'s unmount dispatches, and a remount that keeps the
-- | component instance, which is what StrictMode's simulated one does,
-- | compares against the seed again.
resetState :: ReactFlowState Unit Unit
resetState =
  let
    moved = initialState
      ( (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
          { minZoom = Just 0.1
          , maxZoom = Just 8.0
          , nodeOrigin = Just (mkNodeOrigin 0.5 0.5)
          }
      )
  in
    (reduce moved Reset).state

runInitPrevValuesTests :: Effect Unit
runInitPrevValuesTests = do
  log "running StoreUpdater initPrevValues tests..."

  -- The mount render, one check per seeded field, each at upstream's seed.
  assert "minZoom passed at 0.5 does not dispatch on mount"
    (isNothing (dispatchable initPrevValues.minZoom (render (defined 0.5))))
  assert "maxZoom passed at 2 does not dispatch on mount"
    (isNothing (dispatchable initPrevValues.maxZoom (render (defined 2.0))))
  assert "elementsSelectable passed as true does not dispatch on mount"
    (isNothing (dispatchable initPrevValues.elementsSelectable (render (defined true))))
  assert "noPanClassName passed as 'nopan' does not dispatch on mount"
    (isNothing (dispatchable initPrevValues.noPanClassName (render (defined "nopan"))))
  -- `<ReactFlow />` has no `id` prop and always passes `rfId` "1", which is
  -- upstream's `id || '1'` for a flow without one.
  assert "rfId '1' does not dispatch on mount"
    (isNothing (dispatchable initPrevValues.rfId (Just "1")))
  -- `<ReactFlow />` resolves an omitted `nodeOrigin` to `defaultNodeOrigin`
  -- and passes that, as upstream's destructuring default does. Before the
  -- seed, this dispatched on every flow that did not set a node origin.
  assert "the defaultNodeOrigin an omitted nodeOrigin resolves to does not dispatch on mount"
    (isNothing (dispatchable initPrevValues.nodeOrigin (Just defaultNodeOrigin)))
  assert "infiniteExtent itself does not dispatch on mount"
    (isNothing (dispatchable initPrevValues.translateExtent (Just infiniteExtent)))

  -- Any other value still dispatches on mount.
  assert "minZoom at any other value dispatches on mount"
    (dispatchable initPrevValues.minZoom (render (defined 0.1)) == Just 0.1)
  assert "maxZoom at any other value dispatches on mount"
    (dispatchable initPrevValues.maxZoom (render (defined 8.0)) == Just 8.0)
  assert "elementsSelectable false dispatches on mount"
    (dispatchable initPrevValues.elementsSelectable (render (defined false)) == Just false)
  assert "another noPanClassName dispatches on mount"
    (dispatchable initPrevValues.noPanClassName (render (defined "pan-off")) == Just "pan-off")
  assert "another rfId dispatches on mount"
    (dispatchable initPrevValues.rfId (Just "2") == Just "2")
  assert "another node origin dispatches on mount"
    (dispatchable initPrevValues.nodeOrigin (Just (mkNodeOrigin 0.5 0.5)) == Just (mkNodeOrigin 0.5 0.5))

  -- The object seeds compare by reference, as upstream's `===` does: a
  -- consumer who writes `nodeOrigin={[0, 0]}` hands over a fresh array, which
  -- is not `defaultNodeOrigin`, and upstream dispatches it.
  assert "a fresh [0, 0] node origin still dispatches on mount"
    (isJust (dispatchable initPrevValues.nodeOrigin (Just (mkNodeOrigin 0.0 0.0))))
  assert "a fresh infinite extent still dispatches on mount"
    (isJust (dispatchable initPrevValues.translateExtent (Just (freshInfiniteExtent (1.0 / 0.0)))))

  -- An absent prop dispatches nothing, seeded or not. That is upstream's
  -- `typeof props[fieldName] === 'undefined'` check.
  assert "an absent seeded prop does not dispatch"
    (isNothing (dispatchable initPrevValues.minZoom (render (undefined :: Undefinable Number))))

  -- The seed governs only the first comparison. After that the previous value
  -- is the previous prop, so moving back to the default dispatches it.
  assert "a prop that returns to its seed after mount dispatches"
    (dispatchable (Just 0.1) (render (defined 0.5)) == Just 0.5)

  -- Every other field is unseeded, which upstream spells `undefined`. `fitView`
  -- and `fitViewOptions` are deliberately among them, so both sides dispatch
  -- them on mount.
  assert "an unseeded prop dispatches on mount"
    (dispatchable Nothing (render (defined true)) == Just true)

  -- What makes a skipped dispatch safe: the store already holds the seed. It
  -- does at creation, where an omitted option falls back to the same default,
  -- and it does after `Reset`, which is the case a remount compares against
  -- the seed again.
  assert "every seed is what the store holds after Reset"
    ( initPrevValues.minZoom == Just resetState.minZoom
        && initPrevValues.maxZoom == Just resetState.maxZoom
        && initPrevValues.translateExtent == Just resetState.translateExtent
        && initPrevValues.nodeOrigin == Just resetState.nodeOrigin
        && initPrevValues.elementsSelectable == Just resetState.elementsSelectable
        && initPrevValues.noPanClassName == Just resetState.noPanClassName
        && initPrevValues.rfId == Just resetState.rfId
    )
