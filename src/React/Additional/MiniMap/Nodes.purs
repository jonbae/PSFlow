-- | `<MiniMapNodes />` — iterates visible nodes and renders each via
-- | the user-supplied `nodeComponent` (defaulting to `miniMapNode`).
-- | Mirrors `xyflow-main/.../MiniMap/MiniMapNodes.tsx`.
-- |
-- | The TS source splits subscriptions per-node for fewer re-renders.
-- | The PS port subscribes to the full node array once via a
-- | `UnsafeReference` newtype — simpler at the cost of one re-render per
-- | store mutation. Acceptable for the typical minimap workload.
module React.Additional.MiniMap.Nodes
  ( miniMapNodes
  ) where

import Prelude

import Data.Array (mapMaybe)
import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent, element, fragment)
import React.Basic.Hooks (UnsafeReference(..), memo, reactComponent)
import React.Basic.Hooks as React
import React.Additional.MiniMap.Node (miniMapNode)
import React.Hook.Store (useStore)
import React.Types.Component (MiniMapNodesProps)
import React.Types.Nodes (InternalNode, Node)
import React.Types.Store (ReactFlowState)
import System.Utils.General (getNodeDimensions, nodeHasDimensions)
import Unsafe.Coerce (unsafeCoerce)

-- | Stable cross-browser shape-rendering hint. The TS source toggles
-- | between `crispEdges` and `geometricPrecision` based on browser; the
-- | PS port picks `geometricPrecision` unconditionally.
shapeRendering :: String
shapeRendering = "geometricPrecision"

selectNodes :: forall n e. ReactFlowState n e -> UnsafeReference (Array (InternalNode n))
selectNodes s =
  UnsafeReference (mapMaybe (\node -> Map.lookup node.id s.nodeLookup) s.nodes)

-- | Drop the `internals` field to obtain the public `Node` row. The
-- | underlying JS object is the same minus an extra field, which user
-- | functions ignore — this is the same trick `Node` aliases already
-- | use at the seam between `System.Types.Node` and `React.Types.Nodes`.
internalToBase :: forall n. InternalNode n -> Node n
internalToBase = unsafeCoerce

renderOne :: forall n. MiniMapNodesProps n -> InternalNode n -> Maybe JSX
renderOne props internal =
  let
    base :: Node n
    base = internalToBase internal
  in
    if internal.hidden then Nothing
    else if not (nodeHasDimensions base) then Nothing
    else case getNodeDimensions internal of
      Nothing -> Nothing
      Just dims ->
        let
          cls = case props.nodeClassName of
            Just f -> f base
            Nothing -> ""
          color = map (\f -> f base) props.nodeColor
          stroke = map (\f -> f base) props.nodeStrokeColor
          userComp = fromMaybe miniMapNode props.nodeComponent
        in
          Just $ element userComp
            { id: internal.id
            , x: internal.internals.positionAbsolute.x
            , y: internal.internals.positionAbsolute.y
            , width: dims.width
            , height: dims.height
            , borderRadius: props.nodeBorderRadius
            , className: cls
            , color
            , shapeRendering
            , strokeColor: stroke
            , strokeWidth: props.nodeStrokeWidth
            , style: Nothing
            , selected: internal.selected
            , onClick: props.onClick
            }

miniMapNodes :: forall n. ReactComponent (MiniMapNodesProps n)
miniMapNodes =
  unsafePerformEffect $ memo $ reactComponent "MiniMapNodes"
    \(props :: MiniMapNodesProps n) -> React.do
      UnsafeReference nodes <- useStore selectNodes
      pure $ fragment (mapMaybe (renderOne props) nodes)
