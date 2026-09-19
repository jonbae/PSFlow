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
module React.Container.InitValues
  ( defaultViewport
  , defaultNodeOrigin
  , defaultMinZoom
  , defaultMaxZoom
  , defaultElementsSelectable
  , defaultNoPanClassName
  , defaultRfId
  ) where

import System.Types.Connection (Viewport)
import System.Types.Geometry (NodeOrigin, mkNodeOrigin)

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
