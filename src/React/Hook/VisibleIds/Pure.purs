-- | Pure selectors backing `React.Hook.VisibleIds`. Lives in its own
-- | module so unit tests can import the selectors without pulling
-- | `React.Basic.Hooks` (which transitively imports `react`) into the
-- | Node test runner.
module React.Hook.VisibleIds.Pure
  ( selectVisibleNodeIds
  , selectVisibleEdgeIds
  ) where

import Prelude

import Data.Array (fromFoldable, mapMaybe) as Array
import Data.Map (keys, lookup) as Map
import Data.Maybe (Maybe(..))
import React.Types.Store (ReactFlowState)
import System.Types.Ids (NodeId)
import System.Utils.Edges.General (isEdgeVisible)
import System.Utils.Graph (getNodesInside)

-- | Pure selector. `onlyRenderVisible = false` returns every node ID;
-- | `true` filters by viewport intersection (partially-visible counts).
selectVisibleNodeIds
  :: forall n e. Boolean -> ReactFlowState n e -> Array NodeId
selectVisibleNodeIds onlyRenderVisible s =
  if onlyRenderVisible then
    map _.id
      ( getNodesInside s.nodeLookup
          { x: 0.0, y: 0.0, width: s.width, height: s.height }
          s.transform
          { partially: true, excludeNonSelectable: false }
      )
  else
    Array.fromFoldable (Map.keys s.nodeLookup)

-- | Pure selector. `onlyRenderVisible = false` returns every edge ID;
-- | `true` keeps edges whose source and target nodes both resolve in
-- | `nodeLookup` and whose bounding box intersects the viewport.
-- | Returns `[]` if the viewport has zero width or height.
selectVisibleEdgeIds
  :: forall n e. Boolean -> ReactFlowState n e -> Array String
selectVisibleEdgeIds onlyRenderVisible s =
  if not onlyRenderVisible then
    map _.id s.edges
  else if s.width <= 0.0 || s.height <= 0.0 then
    []
  else
    Array.mapMaybe keep s.edges
  where
  keep edge =
    case Map.lookup edge.source s.nodeLookup,
      Map.lookup edge.target s.nodeLookup of
      Just src, Just tgt ->
        if isEdgeVisible
          { sourceNode: src
          , targetNode: tgt
          , width: s.width
          , height: s.height
          , transform: s.transform
          }
        then Just edge.id
        else Nothing
      _, _ -> Nothing
