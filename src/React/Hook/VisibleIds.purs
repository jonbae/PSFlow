-- | `useVisibleNodeIds` / `useVisibleEdgeIds` — selector hooks that feed
-- | `NodeRenderer` and `EdgeRenderer` the array of IDs to render.
-- |
-- | Mirrors `xyflow-main/packages/react/src/hooks/useVisibleNodeIds.ts`
-- | and `…/useVisibleEdgeIds.ts`. Subscribing to ID arrays only is the
-- | optimisation that lets a renderer skip re-rendering during a drag
-- | tick: the ID array doesn't change, so the slice's `Eq` short-
-- | circuits the subscriber. The per-node / per-edge wrapper subscribes
-- | to its own slice and absorbs the tick.
-- |
-- | The pure selectors live in [`React.Hook.VisibleIds.Pure`](src/React/Hook/VisibleIds/Pure.purs)
-- | so unit tests can drive them without `React.Basic.Hooks` (which
-- | transitively imports `react`) being on the test classpath.
module React.Hook.VisibleIds
  ( module React.Hook.VisibleIds.Pure
  , useVisibleNodeIds
  , useVisibleEdgeIds
  ) where

import React.Basic.Hooks (Hook)
import React.Hook.Store (UseStore, useStore)
import React.Hook.VisibleIds.Pure (selectVisibleEdgeIds, selectVisibleNodeIds)
import System.Types.Ids (NodeId)

useVisibleNodeIds
  :: Boolean -> Hook (UseStore (Array NodeId)) (Array NodeId)
useVisibleNodeIds onlyRenderVisible =
  useStore (selectVisibleNodeIds onlyRenderVisible)

useVisibleEdgeIds
  :: Boolean -> Hook (UseStore (Array String)) (Array String)
useVisibleEdgeIds onlyRenderVisible =
  useStore (selectVisibleEdgeIds onlyRenderVisible)
