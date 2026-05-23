-- | `<NodeToolbar />` — floats above a node (or set of nodes) at a
-- | chosen `Position`. Mirrors `xyflow-main/.../NodeToolbar/NodeToolbar.tsx`.
module React.Additional.NodeToolbar
  ( nodeToolbar
  , module React.Types.Component
  ) where

import Prelude

import Data.Array (filter, foldl, fromFoldable, length) as Array
import Data.Either (Either(..))
import Data.Map (Map)
import Data.Map (empty, insert, isEmpty, lookup, values) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (class Newtype)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object as Object
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (UnsafeReference(..), reactChildrenFromArray, reactChildrenToArray, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.Additional.NodeToolbar.Portal (nodeToolbarPortal)
import React.Context.NodeId (useNodeId)
import React.FFI.DOM (div_)
import React.Hook.Store (useStore)
import React.Types.Component (NodeToolbarProps)
import React.Types.Nodes (InternalNode)
import React.Types.Store (ReactFlowState)
import System.Types.Geometry (Position(..), Transform(..))
import System.Types.Node (Align(..))
import System.Utils.Graph (getInternalNodesBounds)
import System.Utils.Toolbar (getNodeToolbarTransform)
import Unsafe.Coerce (unsafeCoerce)

toForeignStyle :: Object String -> Foreign
toForeignStyle = unsafeCoerce

-- | Slice the store for the transform + selectedCount used to decide
-- | visibility. `UnsafeReference` covers the bundled node-lookup that
-- | the toolbar reads each render.
newtype TbSlice n = TbSlice
  { x :: Number
  , y :: Number
  , zoom :: Number
  , selectedNodesCount :: Int
  , nodes :: UnsafeReference (Map String (InternalNode n))
  }

derive instance newtypeTbSlice :: Newtype (TbSlice n) _

instance eqTbSlice :: Eq (TbSlice n) where
  eq (TbSlice a) (TbSlice b) =
    a.x == b.x
      && a.y == b.y
      && a.zoom == b.zoom
      && a.selectedNodesCount == b.selectedNodesCount
      && a.nodes == b.nodes

idsFromProp
  :: Maybe (Either String (Array String))
  -> Maybe String
  -> Array String
idsFromProp mProp ctxId = case mProp of
  Just (Right arr) -> arr
  Just (Left s) -> [ s ]
  Nothing -> case ctxId of
    Just s -> [ s ]
    Nothing -> [ "" ]

lookupNodes
  :: forall n e
   . Array String
  -> ReactFlowState n e
  -> Map String (InternalNode n)
lookupNodes ids s =
  Array.foldl
    ( \acc nid -> case Map.lookup nid s.nodeLookup of
        Nothing -> acc
        Just n -> Map.insert n.id n acc
    )
    Map.empty
    ids

selectorFor
  :: forall n e
   . Array String
  -> ReactFlowState n e
  -> TbSlice n
selectorFor ids s =
  let
    Transform t = s.transform
  in
    TbSlice
      { x: t.tx
      , y: t.ty
      , zoom: t.scale
      , selectedNodesCount: Array.length (Array.filter _.selected s.nodes)
      , nodes: UnsafeReference (lookupNodes ids s)
      }

nodeToolbar :: ReactComponent NodeToolbarProps
nodeToolbar =
  unsafePerformEffect $ reactComponentWithChildren "NodeToolbar"
    \(props :: NodeToolbarProps) -> React.do
      ctxId <- useNodeId
      let ids = idsFromProp props.nodeId ctxId
      TbSlice slice <- useStore (selectorFor ids)
      let
        UnsafeReference nodes = slice.nodes
        nodesArr = Array.fromFoldable (Map.values nodes)
        isActive = case props.isVisible of
          Just b -> b
          Nothing ->
            Array.length nodesArr == 1
              && (case nodesArr of
                    [ n ] -> n.selected
                    _ -> false)
              && slice.selectedNodesCount == 1
      if not isActive || Map.isEmpty nodes then pure mempty
      else
        let
          nodeRect = getInternalNodesBounds nodes Nothing
          viewport = { x: slice.x, y: slice.y, zoom: slice.zoom }
          position = fromMaybe PosTop props.position
          offset = fromMaybe 10.0 props.offset
          align = fromMaybe AlignCenter props.align
          transformStr = getNodeToolbarTransform nodeRect viewport position
            offset align
          maxZ = Array.foldl (\m n -> max m (n.internals.z + 1.0)) 0.0 nodesArr
          baseStyle = fromMaybe Object.empty props.style
          wrapperStyle = baseStyle
            # Object.insert "position" "absolute"
            # Object.insert "transform" transformStr
            # Object.insert "zIndex" (show maxZ)
          userClass = fromMaybe "" props.className
          className = "react-flow__node-toolbar"
            <> (if userClass == "" then "" else " " <> userClass)
          dataIdStr = Array.foldl (\acc n -> acc <> n.id <> " ") "" nodesArr
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
