-- | Renders a `Fixture` into a `<ReactFlowProvider><ReactFlow/></...>` tree,
-- | mirroring xyflow's generic-test `Flow.tsx`. Uncontrolled (`defaultNodes`/
-- | `defaultEdges` + `initialNodes`/`initialEdges`) so the store owns the data —
-- | selection, drag, delete and connect all mutate the store directly, which is
-- | what the adopted e2e specs observe.
module Generic.Flow
  ( flowView
  ) where

import Data.Maybe (Maybe(..))
import Generic.Defaults (defaultProviderProps, defaultReactFlowProps)
import Generic.Fixture (Fixture)
import React (reactFlow, reactFlowProvider)
import React.Basic (JSX, element)
import React.Basic.Hooks (reactChildrenFromArray)

flowView :: Fixture -> JSX
flowView cfg = element reactFlowProvider providerProps
  where
  rfProps =
    defaultReactFlowProps
      { deleteKeyCode = cfg.deleteKeyCode
      , multiSelectionKeyCode = cfg.multiSelectionKeyCode
      , nodeDragThreshold = cfg.nodeDragThreshold
      , fitView = cfg.fitView
      , connectOnClick = Just true
      , nodeTypes = cfg.nodeTypes
      , minZoom = cfg.minZoom
      , maxZoom = cfg.maxZoom
      , panOnScroll = cfg.panOnScroll
      , defaultViewport = cfg.defaultViewport
      , autoPanOnConnect = cfg.autoPanOnConnect
      , autoPanOnNodeDrag = cfg.autoPanOnNodeDrag
      }

  -- Seed the store via `defaultNodes`/`defaultEdges` (not `initialNodes`): the
  -- provider's `createStore` derives `hasDefaultNodes`/`hasDefaultEdges` from
  -- these, and the store only *commits* drag/connect changes (vs. merely firing
  -- the callback) when those flags are set — see reduceTriggerNodeChanges.
  providerProps =
    defaultProviderProps
      { defaultNodes = Just cfg.nodes
      , defaultEdges = Just cfg.edges
      , fitView = cfg.fitView
      , children = reactChildrenFromArray [ element reactFlow rfProps ]
      }
