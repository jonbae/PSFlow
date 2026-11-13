-- | `<NodeToolbar />` — floats above a node (or set of nodes) at a
-- | chosen `Position`. Mirrors `xyflow/.../NodeToolbar/NodeToolbar.tsx`.
module React.Additional.NodeToolbar
  ( nodeToolbar
  , toolbarWrapperStyle
  , toolbarZIndex
  , module React.Types.Component
  ) where

import Prelude

import Data.Array (filter, foldl, fromFoldable, length) as Array
import Data.Either (Either(..))
import Data.FoldableWithIndex (allWithIndex)
import Data.Map (Map)
import Data.Map (empty, insert, isEmpty, lookup, size, values) as Map
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.Newtype (unwrap)
import Data.Number (infinity)
import Data.Number.Format (toString) as Number
import Data.String (trim) as String
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object as Object
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (reactChildrenFromArray, reactChildrenToArray, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.Additional.NodeToolbar.Portal (nodeToolbarPortal)
import React.Context.NodeId (useNodeId)
import React.FFI.DOM (div_)
import React.Hook.Store (shallow, useStoreWith)
import React.Types.Component (NodeToolbarProps)
import React.Types.Nodes (InternalNode)
import React.Types.Store (ReactFlowState)
import System.Types.Geometry (Position(..), Transform(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (Align(..))
import System.Utils.Graph (getInternalNodesBounds)
import System.Utils.Toolbar (getNodeToolbarTransform)
import Unsafe.Coerce (unsafeCoerce)

toForeignStyle :: Object String -> Foreign
toForeignStyle = unsafeCoerce

-- | Upstream's `Math.max(...nodesArray.map((node) => node.internals.z + 1))`,
-- | over the toolbar's nodes' `internals.z`.
toolbarZIndex :: Array Number -> Number
toolbarZIndex = Array.foldl (\m z -> max m (z + 1.0)) (-infinity)

-- | Upstream's `{ position: 'absolute', transform, zIndex, ...style }`: the
-- | consumer's style goes last, so its keys win. `Object.union` prefers its
-- | first argument and keeps the second's keys first, which is the spread's
-- | order too.
-- |
-- | `zIndex` is written as JavaScript writes the number, `1` and not
-- | `show`'s `1.0`, which isn't a CSS integer, so a browser drops it.
toolbarWrapperStyle :: Maybe (Object String) -> String -> Number -> Object String
toolbarWrapperStyle style transform zIndex =
  Object.union (fromMaybe Object.empty style)
    ( Object.empty
        # Object.insert "position" "absolute"
        # Object.insert "transform" transform
        # Object.insert "zIndex" (Number.toString zIndex)
    )

-- | TS's `storeSelector`: what the toolbar reads besides its nodes, compared
-- | with `shallow`, so a pan to `-0` from `0` renders it again.
type ToolbarView =
  { x :: Number
  , y :: Number
  , zoom :: Number
  , selectedNodesCount :: Int
  }

selectView :: forall n e. ReactFlowState n e -> ToolbarView
selectView s =
  let
    Transform t = s.transform
  in
    { x: t.tx
    , y: t.ty
    , zoom: t.scale
    , selectedNodesCount: Array.length (Array.filter (\n -> n.selected == Just true) s.nodes)
    }

-- | TS's `nodesEqualityFn`: the same ids, each drawn from the same place,
-- | size, selection and `internals.z`. A move of another node, or a change to
-- | a node's data, doesn't render the toolbar again.
sameToolbarNodes :: forall n. Map NodeId (InternalNode n) -> Map NodeId (InternalNode n) -> Boolean
sameToolbarNodes a b =
  Map.size a == Map.size b
    && allWithIndex (\id node -> maybe false (sameToolbarNode node) (Map.lookup id b)) a

-- | TS's `nodeEqualityFn` turned around. Upstream's answers `true` for a
-- | difference and compares with `!==`, which is PureScript's `/=` on each.
sameToolbarNode :: forall n. InternalNode n -> InternalNode n -> Boolean
sameToolbarNode a b =
  a.internals.positionAbsolute.x == b.internals.positionAbsolute.x
    && a.internals.positionAbsolute.y == b.internals.positionAbsolute.y
    && a.measured.width == b.measured.width
    && a.measured.height == b.measured.height
    && a.selected == b.selected
    && a.internals.z == b.internals.z

idsFromProp
  :: Maybe (Either String (Array String))
  -> Maybe String
  -> Array NodeId
idsFromProp mProp ctxId = case mProp of
  Just (Right arr) -> map NodeId arr
  Just (Left s) -> [ NodeId s ]
  Nothing -> case ctxId of
    Just s -> [ NodeId s ]
    Nothing -> [ NodeId "" ]

-- | TS's `nodesSelector`: the toolbar's nodes the lookup has, by id.
lookupNodes
  :: forall n e
   . Array NodeId
  -> ReactFlowState n e
  -> Map NodeId (InternalNode n)
lookupNodes ids s =
  Array.foldl
    ( \acc nid -> case Map.lookup nid s.nodeLookup of
        Nothing -> acc
        Just n -> Map.insert n.id n acc
    )
    Map.empty
    ids

nodeToolbar :: ReactComponent NodeToolbarProps
nodeToolbar =
  unsafePerformEffect $ reactComponentWithChildren "NodeToolbar"
    \(props :: NodeToolbarProps) -> React.do
      ctxId <- useNodeId
      let ids = idsFromProp props.nodeId ctxId
      nodes <- useStoreWith (lookupNodes ids) sameToolbarNodes
      view <- useStoreWith selectView shallow
      let
        nodesArr = Array.fromFoldable (Map.values nodes)
        isActive = case props.isVisible of
          Just b -> b
          Nothing ->
            Array.length nodesArr == 1
              && (case nodesArr of
                    [ n ] -> n.selected == Just true
                    _ -> false)
              && view.selectedNodesCount == 1
      if not isActive || Map.isEmpty nodes then pure mempty
      else
        let
          nodeRect = getInternalNodesBounds nodes Nothing
          viewport = { x: view.x, y: view.y, zoom: view.zoom }
          position = fromMaybe PosTop props.position
          offset = fromMaybe 10.0 props.offset
          align = fromMaybe AlignCenter props.align
          transformStr = getNodeToolbarTransform nodeRect viewport position
            offset align
          wrapperStyle = toolbarWrapperStyle props.style transformStr
            (toolbarZIndex (map _.internals.z nodesArr))
          userClass = fromMaybe "" props.className
          className = "react-flow__node-toolbar"
            <> (if userClass == "" then "" else " " <> userClass)
          -- TS `.reduce((acc, node) => `${acc}${node.id} `, '').trim()` — the
          -- `.trim()` drops the trailing space so an exact-match `[data-id="…"]`
          -- selector resolves (upstream NodeToolbar.tsx:136).
          dataIdStr = String.trim
            (Array.foldl (\acc n -> acc <> unwrap n.id <> " ") "" nodesArr)
          toolbarDiv = div_
            { style: toForeignStyle wrapperStyle
            , className
            , "data-id": dataIdStr
            }
            (reactChildrenToArray props.children)
        in
          pure $ element nodeToolbarPortal
            { children: reactChildrenFromArray [ toolbarDiv ]
            }
