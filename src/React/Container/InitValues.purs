-- | Module-level default constants used by `<ReactFlow />` when the user
-- | omits the corresponding prop. Mirrors
-- | `xyflow-main/packages/react/src/container/ReactFlow/init-values.ts`,
-- | and adds the defaults upstream writes inline instead.
-- |
-- | **One home for seven values.** Upstream writes `minZoom`, `maxZoom`,
-- | `elementsSelectable`, `noPanClassName` and `rfId` three times over: as
-- | destructuring defaults in `container/ReactFlow/index.tsx`, as initial
-- | state in `store/initialState.ts`, and as `<StoreUpdater />`'s
-- | `initPrevValues`. The three have to agree. A seed tells the component
-- | that the store already holds a value, so a seed that drifted from the
-- | initial state would skip a dispatch the store needed. So the PS port
-- | writes them here once, and `React.Container.ReactFlow`,
-- | `React.Store.InitialState` and `React.Provider.TrackedProp.initPrevValues`
-- | all read them from here. `translateExtent`'s default is
-- | `System.Constants.infiniteExtent`, which already had one home.
-- |
-- | **And the one place they are applied.** `resolveSeeded` and
-- | `seededStoreProps` turn a consumer's `Maybe` props into the values
-- | `<ReactFlow />` passes on, so the defaults are read here rather than
-- | spelled again at a call site. `seededStoreProps` is the one that has to
-- | exist: `<StoreUpdater />`'s props are `Maybe`, so handing it the raw prop
-- | type-checks and quietly means "absent" where upstream means "the
-- | default".
module React.Container.InitValues
  ( defaultViewport
  , defaultNodeOrigin
  , defaultMinZoom
  , defaultMaxZoom
  , defaultElementsSelectable
  , defaultNoPanClassName
  , defaultRfId
  , RawSeeded
  , Seeded
  , SeededStoreProps
  , resolveSeeded
  , seededStoreProps
  ) where

import Data.Maybe (Maybe(..), fromMaybe)
import System.Constants (infiniteExtent)
import System.Types.Connection (Viewport)
import System.Types.Geometry (CoordinateExtent, NodeOrigin, mkNodeOrigin)

defaultViewport :: Viewport
defaultViewport = { x: 0.0, y: 0.0, zoom: 1.0 }

-- | One object, not a fresh `[0, 0]` per use. `<StoreUpdater />`'s seed
-- | compares by reference, as upstream's `===` does, so what `<ReactFlow />`
-- | hands over for an omitted `nodeOrigin` is skipped on mount only because
-- | it is this object and the seed is this object too.
defaultNodeOrigin :: NodeOrigin
defaultNodeOrigin = mkNodeOrigin 0.0 0.0

defaultMinZoom :: Number
defaultMinZoom = 0.5

defaultMaxZoom :: Number
defaultMaxZoom = 2.0

defaultElementsSelectable :: Boolean
defaultElementsSelectable = true

defaultNoPanClassName :: String
defaultNoPanClassName = "nopan"

-- | Upstream's `id || '1'`. `<ReactFlow />` has no `id` prop in the PS port,
-- | so this is the only `rfId` a flow ever has.
defaultRfId :: String
defaultRfId = "1"

-- ────────────────────────────────────────────────────────────────────────
-- Applying them
--
-- The six seeded fields `<ReactFlow />` resolves before passing on, minus
-- `rfId`, which is not a prop here (see `React.Container.ReactFlow`'s
-- "Skipped from TS").
-- ────────────────────────────────────────────────────────────────────────

-- | The six as a consumer passes them: each `Maybe`, because each may be
-- | omitted. An open row, so `<ReactFlow />` hands over its whole props
-- | record and a test hands over six fields.
type RawSeeded r =
  ( minZoom :: Maybe Number
  , maxZoom :: Maybe Number
  , translateExtent :: Maybe CoordinateExtent
  , elementsSelectable :: Maybe Boolean
  , noPanClassName :: Maybe String
  , nodeOrigin :: Maybe NodeOrigin
  | r
  )

-- | The six resolved, as `<GraphView />` takes them. `<Wrapper />` is still
-- | handed the raw `minZoom` and `maxZoom`, where upstream hands it the
-- | resolved pair: it builds the store once and `React.Store.InitialState`
-- | falls back to these same constants, so the two spellings cannot differ.
type Seeded =
  { minZoom :: Number
  , maxZoom :: Number
  , translateExtent :: CoordinateExtent
  , elementsSelectable :: Boolean
  , noPanClassName :: String
  , nodeOrigin :: NodeOrigin
  }

-- | The six resolved, as `<StoreUpdater />` takes them: `Maybe`, because that
-- | is the shape of every tracked field, but never `Nothing`, because
-- | `<ReactFlow />` has already supplied the default.
type SeededStoreProps =
  { minZoom :: Maybe Number
  , maxZoom :: Maybe Number
  , translateExtent :: Maybe CoordinateExtent
  , elementsSelectable :: Maybe Boolean
  , noPanClassName :: Maybe String
  , nodeOrigin :: Maybe NodeOrigin
  }

-- | Upstream's destructuring defaults for the six
-- | (`xyflow/packages/react/src/container/ReactFlow/index.tsx`:83-123).
-- |
-- | An omitted prop resolves to the object the seed table holds, not to a
-- | copy of it: `infiniteExtent` and `defaultNodeOrigin` are each one value,
-- | and `<StoreUpdater />`'s comparison is upstream's `===`.
resolveSeeded :: forall r. Record (RawSeeded r) -> Seeded
resolveSeeded props =
  { minZoom: fromMaybe defaultMinZoom props.minZoom
  , maxZoom: fromMaybe defaultMaxZoom props.maxZoom
  , translateExtent: fromMaybe infiniteExtent props.translateExtent
  , elementsSelectable: fromMaybe defaultElementsSelectable props.elementsSelectable
  , noPanClassName: fromMaybe defaultNoPanClassName props.noPanClassName
  , nodeOrigin: fromMaybe defaultNodeOrigin props.nodeOrigin
  }

-- | What `<ReactFlow />` hands `<StoreUpdater />` for the six: the resolved
-- | value, which is what upstream hands over, and never the raw prop.
-- |
-- | The difference shows when a consumer removes a prop after mount. Upstream
-- | resolves the default again and dispatches it, because the default differs
-- | from the value that was there. Passing the raw prop makes that `Nothing`,
-- | which `React.Provider.TrackedProp.dispatchable` reads as upstream's
-- | `typeof props[fieldName] === 'undefined'` — a skip — so the store keeps
-- | the removed value while `<GraphView />` is handed the default.
seededStoreProps :: forall r. Record (RawSeeded r) -> SeededStoreProps
seededStoreProps props =
  let
    seeded = resolveSeeded props
  in
    { minZoom: Just seeded.minZoom
    , maxZoom: Just seeded.maxZoom
    , translateExtent: Just seeded.translateExtent
    , elementsSelectable: Just seeded.elementsSelectable
    , noPanClassName: Just seeded.noPanClassName
    , nodeOrigin: Just seeded.nodeOrigin
    }
