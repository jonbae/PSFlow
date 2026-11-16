-- | `<MiniMapNodes />` — iterates visible nodes and renders each via
-- | the user-supplied `nodeComponent` (defaulting to `miniMapNode`).
-- | Mirrors `xyflow/.../MiniMap/MiniMapNodes.tsx`.
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
import Data.Newtype (unwrap)
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent, element, fragment)
import React.Basic.Hooks (UnsafeReference(..), memo, reactComponent)
import React.Basic.Hooks as React
import React.Additional.MiniMap.Node (miniMapNode)
import React.Hook.Store (useStore)
import React.Types.Component (MiniMapNodeAttribute(..), MiniMapNodesProps)
import React.Types.Nodes (InternalNode, Node)
import React.Types.Store (ReactFlowState)
import System.Utils.General (getNodeDimensions, nodeHasDimensions)

-- | TS `typeof window === 'undefined' || !!window.chrome ? 'crispEdges' :
-- | 'geometricPrecision'`: crisp on a server and in Chrome, precise
-- | elsewhere.
foreign import shapeRenderingNow :: Effect String

selectNodes :: forall n e. ReactFlowState n e -> UnsafeReference (Array (InternalNode n))
selectNodes s =
  UnsafeReference (mapMaybe (\node -> Map.lookup node.id s.nodeLookup) s.nodes)

-- | Upstream reads each minimap node from `internals.userNode`, the node the
-- | consumer wrote, and only its position from the internal node. So a node
-- | is drawn only when the consumer's own node has a size — `measured`,
-- | `width` or `initialWidth`, which a flow that ignores its dimension
-- | changes never gets — and its colour, class, selection and style are the
-- | consumer's node's.
renderOne :: forall n. MiniMapNodesProps n -> String -> InternalNode n -> Maybe JSX
renderOne props shapeRendering internal =
  let
    node :: Node n
    node = internal.internals.userNode
  in
    if node.hidden == Just true then Nothing
    else if not (nodeHasDimensions node) then Nothing
    else
      let
        dims = fromMaybe { width: 0.0, height: 0.0 } (getNodeDimensions node)
        -- TS `getAttrFunction`: a function is called with the node, and
        -- any other value is returned as it is. `nodeClassName`
        -- defaults to `''`.
        cls = fromMaybe "" (attributeOf node =<< props.nodeClassName)
        color = attributeOf node =<< props.nodeColor
        stroke = attributeOf node =<< props.nodeStrokeColor
        userComp = fromMaybe miniMapNode props.nodeComponent
      in
        Just $ element userComp
          { id: unwrap node.id
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
          , style: node.style
          , selected: node.selected == Just true
          , onClick: props.onClick
          }

attributeOf :: forall n. Node n -> MiniMapNodeAttribute n -> Maybe String
attributeOf node = case _ of
  AttributeValue value -> Just value
  AttributeOf f -> Just (f node)

miniMapNodes :: forall n. ReactComponent (MiniMapNodesProps n)
miniMapNodes =
  unsafePerformEffect $ memo $ reactComponent "MiniMapNodes"
    \(props :: MiniMapNodesProps n) -> React.do
      UnsafeReference nodes <- useStore selectNodes
      let shapeRendering = unsafePerformEffect shapeRenderingNow
      pure $ fragment (mapMaybe (renderOne props shapeRendering) nodes)
