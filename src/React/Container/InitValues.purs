-- | Module-level default constants used by `<ReactFlow />` when the user
-- | omits the corresponding prop. Mirrors
-- | `xyflow-main/packages/react/src/container/ReactFlow/init-values.ts`.
-- |
-- | These are kept in their own module (rather than inlined into
-- | `React.Container.ReactFlow`) so `StoreUpdater` can also pull
-- | `defaultNodeOrigin` from a single source.
module React.Container.InitValues
  ( defaultViewport
  , defaultNodeOrigin
  ) where

import System.Types.Connection (Viewport)
import System.Types.Geometry (NodeOrigin, mkNodeOrigin)

defaultViewport :: Viewport
defaultViewport = { x: 0.0, y: 0.0, zoom: 1.0 }

defaultNodeOrigin :: NodeOrigin
defaultNodeOrigin = mkNodeOrigin 0.0 0.0
