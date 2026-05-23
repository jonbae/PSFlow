-- | `<ReactFlowProvider />` — allocates the singleton `Store` and wraps
-- | children in `storeContext` + `batchContext`. Mirrors
-- | `xyflow-main/packages/react/src/components/ReactFlowProvider/index.tsx`.
-- |
-- | **Store-once invariant.** TS uses `useState(() => createStore(opts))`
-- | so the store is allocated lazily exactly once per mount. PS doesn't
-- | have lazy-init `useState`; `useMemo unit` with `unsafePerformEffect`
-- | inside the factory is the equivalent — same pattern already used by
-- | `React.Container.NodeRenderer` for its shared `ResizeObserver`.
-- |
-- | The store is opaque (`OpaqueStore`) at the context boundary because
-- | `ReactContext` is monomorphic in PureScript. The cast happens here
-- | (one of two documented seams; the other is in `React.Hook.Store`).
module React.Provider
  ( reactFlowProvider
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (reactComponentWithChildren, useMemo)
import React.Basic.Hooks as React
import React.Context.Store (OpaqueStore, storeProvider)
import React.Provider.Batch (batchProvider)
import React.Store.InitialState (InitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Component (ReactFlowProviderProps)
import Unsafe.Coerce (unsafeCoerce)

-- | One of the two documented `Store n e <-> OpaqueStore` seams. See
-- | `React.Context.Store` header for the contract.
storeToOpaque :: forall n e. Store n e -> OpaqueStore
storeToOpaque = unsafeCoerce

reactFlowProvider :: forall n e. ReactComponent (ReactFlowProviderProps n e)
reactFlowProvider =
  unsafePerformEffect $ reactComponentWithChildren "ReactFlowProvider"
    \(props :: ReactFlowProviderProps n e) -> React.do
      store <- useMemo unit \_ ->
        unsafePerformEffect (createStore (toInitOptions props))
      pure $ storeProvider (Just (storeToOpaque store))
        [ element batchProvider { children: props.children } ]
  where
  toInitOptions :: ReactFlowProviderProps n e -> InitialStateOptions n e
  toInitOptions props =
    { nodes: props.initialNodes
    , edges: props.initialEdges
    , defaultNodes: props.defaultNodes
    , defaultEdges: props.defaultEdges
    , width: props.initialWidth
    , height: props.initialHeight
    , fitView: props.fitView
    , fitViewOptions: props.initialFitViewOptions
    , minZoom: props.initialMinZoom
    , maxZoom: props.initialMaxZoom
    , nodeOrigin: props.nodeOrigin
    , nodeExtent: props.nodeExtent
    , zIndexMode: props.zIndexMode
    }
