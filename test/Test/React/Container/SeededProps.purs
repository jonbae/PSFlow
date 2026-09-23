-- | What `<ReactFlow />` hands `<StoreUpdater />` for the six seeded fields.
-- |
-- | The local proxy for "Hand StoreUpdater the defaults ReactFlow resolves, so
-- | a prop removed after mount falls back to them" (#113). Upstream
-- | destructures `minZoom = 0.5`, `maxZoom = 2`,
-- | `translateExtent = infiniteExtent`, `elementsSelectable = true`,
-- | `noPanClassName = 'nopan'` and `nodeOrigin = defaultNodeOrigin`, and then
-- | passes those names on
-- | (`xyflow/packages/react/src/container/ReactFlow/index.tsx`:83-123,
-- | 193-239), so `<StoreUpdater />` never sees `undefined` for any of the six.
-- | ps-flow resolved them for `<GraphView />` and handed `<StoreUpdater />`
-- | the raw prop for five — `nodeOrigin` was the exception.
-- |
-- | Both ports agree on mount, and they agree while a prop holds a value. They
-- | part when a consumer removes one: upstream resolves the default and
-- | dispatches it, while a raw `Nothing` is
-- | `React.Provider.TrackedProp.dispatchable`'s skip, so the store kept the
-- | removed value.
-- |
-- | Like `Test.React.Provider.InitPrevValues`, this runs without rendering —
-- | `spago test` has no DOM and no store context. What it checks is the record
-- | the component would be handed. Putting `props` where
-- | `seededStoreProps props` now stands is the divergence exactly, and it
-- | fails every check in the first and third groups.
module Test.React.Container.SeededProps
  ( runSeededPropsTests
  ) where

import Prelude

import Boundary.Undefined (Undefinable, defined, fromUndefinable, undefined)
import Data.Maybe (Maybe(..), isNothing)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Container.InitValues (RawSeeded, resolveSeeded, seededStoreProps)
import React.Provider.TrackedProp (changed, dispatchable, initPrevValues)
import System.Types.Geometry (CoordinateExtent, mkCoordinateExtent, mkNodeOrigin)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | One render's worth of a prop that crosses the boundary, as
-- | `Boundary.Flow` crosses each field on every render.
render :: forall a. Undefinable a -> Maybe a
render = fromUndefinable

-- | A flow that sets none of the six, which is every flow in the corpus.
omitted :: Record (RawSeeded ())
omitted =
  { minZoom: render (undefined :: Undefinable Number)
  , maxZoom: render (undefined :: Undefinable Number)
  , translateExtent: render (undefined :: Undefinable CoordinateExtent)
  , elementsSelectable: render (undefined :: Undefinable Boolean)
  , noPanClassName: render (undefined :: Undefinable String)
  , nodeOrigin: render (undefined :: Undefinable _)
  }

-- | The same flow with all six set, each away from its default. This is the
-- | render before the one `omitted` stands for: the consumer passed these,
-- | the store holds them, and then the props go away.
passed :: Record (RawSeeded ())
passed =
  { minZoom: render (defined 0.1)
  , maxZoom: render (defined 8.0)
  , translateExtent: render (defined narrowExtent)
  , elementsSelectable: render (defined false)
  , noPanClassName: render (defined "pan-off")
  , nodeOrigin: render (defined (mkNodeOrigin 0.5 0.5))
  }

narrowExtent :: CoordinateExtent
narrowExtent = mkCoordinateExtent (-320.0) (-240.0) 320.0 240.0

-- | `<GraphView />` and `<StoreUpdater />` are handed the same six values.
-- | They were not: the store kept a removed `elementsSelectable: false` while
-- | `<GraphView />` had already been handed `true`.
agreesWithGraphView :: Record (RawSeeded ()) -> Boolean
agreesWithGraphView props =
  let
    view = resolveSeeded props
    store = seededStoreProps props
  in
    store.minZoom == Just view.minZoom
      && store.maxZoom == Just view.maxZoom
      && store.translateExtent == Just view.translateExtent
      && store.elementsSelectable == Just view.elementsSelectable
      && store.noPanClassName == Just view.noPanClassName
      && store.nodeOrigin == Just view.nodeOrigin

runSeededPropsTests :: Effect Unit
runSeededPropsTests = do
  log "running ReactFlow seeded store-prop tests..."

  let
    handedOmitted = seededStoreProps omitted
    handedPassed = seededStoreProps passed

  -- An omitted prop arrives as the value `initPrevValues` seeds, not as the
  -- absence upstream never sends. `changed` and not `dispatchable`, because a
  -- `Nothing` also dispatches nothing and would pass a check written the
  -- other way round. The two object fields must be the seed itself, since the
  -- comparison is upstream's `===`.
  assert "an omitted minZoom reaches <StoreUpdater /> as the seed"
    (not (changed initPrevValues.minZoom handedOmitted.minZoom))
  assert "an omitted maxZoom reaches <StoreUpdater /> as the seed"
    (not (changed initPrevValues.maxZoom handedOmitted.maxZoom))
  assert "an omitted translateExtent reaches <StoreUpdater /> as the seed"
    (not (changed initPrevValues.translateExtent handedOmitted.translateExtent))
  assert "an omitted elementsSelectable reaches <StoreUpdater /> as the seed"
    (not (changed initPrevValues.elementsSelectable handedOmitted.elementsSelectable))
  assert "an omitted noPanClassName reaches <StoreUpdater /> as the seed"
    (not (changed initPrevValues.noPanClassName handedOmitted.noPanClassName))
  assert "an omitted nodeOrigin reaches <StoreUpdater /> as the seed"
    (not (changed initPrevValues.nodeOrigin handedOmitted.nodeOrigin))

  -- So the mount render still dispatches none of the six, which is what the
  -- seed table is for and what ps-flow already did by handing over nothing.
  assert "an omitted prop still does not dispatch on mount"
    ( isNothing (dispatchable initPrevValues.minZoom handedOmitted.minZoom)
        && isNothing (dispatchable initPrevValues.maxZoom handedOmitted.maxZoom)
        && isNothing (dispatchable initPrevValues.translateExtent handedOmitted.translateExtent)
        && isNothing (dispatchable initPrevValues.elementsSelectable handedOmitted.elementsSelectable)
        && isNothing (dispatchable initPrevValues.noPanClassName handedOmitted.noPanClassName)
        && isNothing (dispatchable initPrevValues.nodeOrigin handedOmitted.nodeOrigin)
    )

  -- The ticket: the prop goes away after mount, and the store goes back to the
  -- default rather than keeping what the consumer removed. The previous value
  -- is the prop from the render before, which is `passed`.
  assert "a removed minZoom dispatches 0.5"
    (dispatchable passed.minZoom handedOmitted.minZoom == Just 0.5)
  assert "a removed maxZoom dispatches 2"
    (dispatchable passed.maxZoom handedOmitted.maxZoom == Just 2.0)
  assert "a removed translateExtent dispatches the infinite extent"
    ( dispatchable passed.translateExtent handedOmitted.translateExtent
        == Just (mkCoordinateExtent (-infinity) (-infinity) infinity infinity)
    )
  assert "a removed elementsSelectable dispatches true"
    (dispatchable passed.elementsSelectable handedOmitted.elementsSelectable == Just true)
  assert "a removed noPanClassName dispatches 'nopan'"
    (dispatchable passed.noPanClassName handedOmitted.noPanClassName == Just "nopan")
  assert "a removed nodeOrigin dispatches [0, 0]"
    (dispatchable passed.nodeOrigin handedOmitted.nodeOrigin == Just (mkNodeOrigin 0.0 0.0))

  -- Resolving is not overriding: a prop a consumer did pass reaches the store
  -- as it stands.
  assert "a prop that is passed reaches <StoreUpdater /> unchanged"
    ( handedPassed.minZoom == Just 0.1
        && handedPassed.maxZoom == Just 8.0
        && handedPassed.translateExtent == Just narrowExtent
        && handedPassed.elementsSelectable == Just false
        && handedPassed.noPanClassName == Just "pan-off"
        && handedPassed.nodeOrigin == Just (mkNodeOrigin 0.5 0.5)
    )

  -- And the two components are handed the same six, which is the invariant the
  -- divergence broke.
  assert "<GraphView /> and <StoreUpdater /> agree, with the props omitted"
    (agreesWithGraphView omitted)
  assert "<GraphView /> and <StoreUpdater /> agree, with the props passed"
    (agreesWithGraphView passed)

infinity :: Number
infinity = 1.0 / 0.0
