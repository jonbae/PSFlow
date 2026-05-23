-- | `<Wrapper />` — detects an existing `<ReactFlowProvider>` higher in
-- | the tree; passes through if one is present, otherwise allocates one
-- | with the supplied initial-state options. Mirrors
-- | `xyflow-main/packages/react/src/container/ReactFlow/Wrapper.tsx`.
-- |
-- | Same prop shape as `ReactFlowProvider` (`ReactFlowProviderProps n e`)
-- | because the "no outer provider" path forwards the initial values
-- | straight to the provider.
module React.Container.Wrapper
  ( wrapper
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, element, fragment)
import React.Basic.Hooks (reactChildrenToArray, reactComponentWithChildren, useContext)
import React.Basic.Hooks as React
import React.Context.Store (storeContext)
import React.Provider (reactFlowProvider)
import React.Types.Component (ReactFlowProviderProps)

wrapper :: forall n e. ReactComponent (ReactFlowProviderProps n e)
wrapper =
  unsafePerformEffect $ reactComponentWithChildren "Wrapper"
    \(props :: ReactFlowProviderProps n e) -> React.do
      mStore <- useContext storeContext
      pure $ case mStore of
        Just _ -> fragment (reactChildrenToArray props.children)
        Nothing -> element reactFlowProvider props
