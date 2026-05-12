-- | Graph traversal, node bounds, fit-view, and deletion utilities. Mirrors
-- | `xyflow-main/packages/system/src/utils/graph.ts` minus the runtime
-- | `is*Base` type guards (those are unnecessary in PS, where the type
-- | system enforces the shape statically).
module XYFlow.Utils.Graph
  ( getNodePositionWithOrigin
  , getOutgoers
  , getIncomers
  , GetNodesBoundsParams
  , getNodesBounds
  , GetInternalNodesBoundsParams
  , getInternalNodesBounds
  , GetNodesInsideOptions
  , getNodesInside
  , getConnectedEdges
  , FitViewParams
  , FitViewOptions
  , fitViewport
  , CalculateNodePositionParams
  , calculateNodePosition
  , OnBeforeDelete
  , GetElementsToRemoveParams
  , getElementsToRemove
  ) where

import Prelude

import Control.Alt ((<|>))
import Data.Array (any, filter, foldl, fromFoldable, length, snoc) as Array
import Data.Either (Either(..))
import Data.Foldable (foldMap, foldl) as Foldable
import Data.Map (Map)
import Data.Map (filter, lookup, size, values) as Map
import Data.Maybe (Maybe(..), fromMaybe, isJust, isNothing)
import Data.Newtype (unwrap)
import Data.Set (Set)
import Data.Set (fromFoldable, member) as Set
import Effect.Aff (Aff)
import XYFlow.Types.Connection
  ( InterpolateMode
  , Padding(..)
  , PaddingValue(..)
  )
import XYFlow.Types.Edge (EdgeBase)
import XYFlow.Types.Geometry
  ( BoundingBox(..)
  , CoordinateExtent(..)
  , NodeOrigin(..)
  , Rect
  , Transform(..)
  , XYPosition
  , mkNodeOrigin
  )
import XYFlow.Types.Node
  ( InternalNodeBase
  , NodeBase
  , NodeExtent(..)
  , NodeLookup
  , OnError
  )
import XYFlow.Types.PanZoom (PanZoomInstance)
import XYFlow.Utils.General
  ( boxToRect
  , clampPosition
  , getNodePositionWithOrigin
  , getOverlappingArea
  , getViewportForBounds
  , isCoordinateExtent
  , nodeToBox
  , nodeToRect
  , pointToRendererPoint
  ) as G

-- | Re-exported so ticket-009 consumers see this name in `Utils.Graph`,
-- | even though the implementation lives in `Utils.General` (cycle break).
getNodePositionWithOrigin
  :: forall n. NodeBase n -> NodeOrigin -> XYPosition
getNodePositionWithOrigin = G.getNodePositionWithOrigin

-- Outgoers / Incomers ------------------------------------------------------

getOutgoers
  :: forall n e r
   . { id :: String | r }
  -> Array (NodeBase n)
  -> Array (EdgeBase e)
  -> Array (NodeBase n)
getOutgoers node nodes edges
  | node.id == "" = []
  | otherwise =
      let
        ids = Set.fromFoldable
          ( map _.target
              (Array.filter (\e -> e.source == node.id) edges)
          )
      in
        Array.filter (\n -> Set.member n.id ids) nodes

getIncomers
  :: forall n e r
   . { id :: String | r }
  -> Array (NodeBase n)
  -> Array (EdgeBase e)
  -> Array (NodeBase n)
getIncomers node nodes edges
  | node.id == "" = []
  | otherwise =
      let
        ids = Set.fromFoldable
          ( map _.source
              (Array.filter (\e -> e.target == node.id) edges)
          )
      in
        Array.filter (\n -> Set.member n.id ids) nodes

-- Bounds ------------------------------------------------------------------

type GetNodesBoundsParams n =
  { nodeOrigin :: NodeOrigin
  , nodeLookup :: Maybe (NodeLookup n)
  }

-- | Compute the bounding rectangle for a list of nodes. The TS function
-- | issues a `console.warn` when `nodeLookup` is missing; the PS port leaves
-- | the choice explicit via `Maybe` and stays pure.
-- |
-- | Uses `Foldable.foldMap` over the `BoundingBox` monoid (whose `mempty`
-- | is the (+Inf, -Inf) seed and whose `<>` is `getBoundsOfBoxes`).
getNodesBounds
  :: forall n
   . Array (NodeBase n)
  -> Maybe (NodeLookup n)
  -> NodeOrigin
  -> Rect
getNodesBounds nodes mLookup origin
  | Array.length nodes == 0 = { x: 0.0, y: 0.0, width: 0.0, height: 0.0 }
  | otherwise = G.boxToRect (unwrap (Foldable.foldMap nodeBoundingBox nodes))
      where
      nodeBoundingBox node =
        let
          source = case mLookup of
            Just lookup -> case Map.lookup node.id lookup of
              Just internal -> Right internal
              Nothing -> Left node
            Nothing -> Left node
        in
          BoundingBox (G.nodeToBox source origin)

type GetInternalNodesBoundsParams n =
  { useRelativePosition :: Boolean
  , filter :: Maybe (InternalNodeBase n -> Boolean)
  }

getInternalNodesBounds
  :: forall n
   . Map String (InternalNodeBase n)
  -> Maybe (InternalNodeBase n -> Boolean)
  -> Rect
getInternalNodesBounds nodeLookup mFilter =
  let
    keep node = case mFilter of
      Nothing -> true
      Just f -> f node

    kept = Array.filter keep (Array.fromFoldable (Map.values nodeLookup))
  in
    if Array.length kept == 0
      then { x: 0.0, y: 0.0, width: 0.0, height: 0.0 }
      else
        let
          merged = Foldable.foldMap
            (\n -> BoundingBox (G.nodeToBox (Right n) zeroOrigin))
            kept
        in
          G.boxToRect (unwrap merged)
  where
  zeroOrigin = mkNodeOrigin 0.0 0.0

type GetNodesInsideOptions =
  { partially :: Boolean
  , excludeNonSelectable :: Boolean
  }

getNodesInside
  :: forall n
   . NodeLookup n
  -> Rect
  -> Transform
  -> GetNodesInsideOptions
  -> Array (InternalNodeBase n)
getNodesInside nodes rect transform opts =
  Array.filter visible (Array.fromFoldable (Map.values nodes))
  where
  Transform t = transform

  paneRect :: Rect
  paneRect =
    let
      tl = G.pointToRendererPoint
        { x: rect.x, y: rect.y }
        transform
        Nothing
    in
      { x: tl.x
      , y: tl.y
      , width: rect.width / t.scale
      , height: rect.height / t.scale
      }

  zeroOrigin = mkNodeOrigin 0.0 0.0

  visible node =
    let
      hidden = node.hidden
      selectable = fromMaybe true node.selectable
    in
      if (opts.excludeNonSelectable && not selectable) || hidden then false
      else
        let
          mDims = G.getNodeDimensions node
          area = case mDims of
            Just d -> d.width * d.height
            Nothing -> 0.0
          overlapping = G.getOverlappingArea paneRect
            (G.nodeToRect (Right node) zeroOrigin)
          partiallyVisible = opts.partially && overlapping > 0.0
          forceInitialRender = isNothing node.internals.handleBounds
        in
          forceInitialRender || partiallyVisible || overlapping >= area
            || node.dragging

-- Connected edges --------------------------------------------------------

getConnectedEdges
  :: forall n e
   . Array (NodeBase n)
  -> Array (EdgeBase e)
  -> Array (EdgeBase e)
getConnectedEdges nodes edges =
  let
    ids :: Set String
    ids = Set.fromFoldable (map _.id nodes)
  in
    Array.filter
      (\e -> Set.member e.source ids || Set.member e.target ids)
      edges

-- Fit-view ---------------------------------------------------------------

type FitViewParams n =
  { nodes :: NodeLookup n
  , width :: Number
  , height :: Number
  , panZoom :: PanZoomInstance
  , minZoom :: Number
  , maxZoom :: Number
  }

-- | Options for `fitViewport`. The TS source parameterises this on `NodeType`
-- | only to allow the optional `nodes` filter to inherit the node's data
-- | shape; in PS the filter just needs an `id`, so the type is flat.
type FitViewOptions =
  { padding :: Maybe Padding
  , includeHiddenNodes :: Boolean
  , minZoom :: Maybe Number
  , maxZoom :: Maybe Number
  , duration :: Maybe Int
  , ease :: Maybe (Number -> Number)
  , interpolate :: Maybe InterpolateMode
  , nodes :: Maybe (Array { id :: String })
  }

defaultFitViewOptions :: FitViewOptions
defaultFitViewOptions =
  { padding: Nothing
  , includeHiddenNodes: false
  , minZoom: Nothing
  , maxZoom: Nothing
  , duration: Nothing
  , ease: Nothing
  , interpolate: Nothing
  , nodes: Nothing
  }

defaultFitViewPadding :: Padding
defaultFitViewPadding = UniformPadding (RatioPadding 0.1)

fitViewport
  :: forall n
   . FitViewParams n
  -> Maybe (FitViewOptions)
  -> Aff Boolean
fitViewport params mOptions = do
  let
    options = fromMaybe defaultFitViewOptions mOptions
    nodesToFit = filterFitViewNodes params.nodes options
  if Map.size nodesToFit == 0 then pure true
  else do
    let
      bounds = getInternalNodesBounds nodesToFit Nothing
      viewport = G.getViewportForBounds
        bounds
        params.width
        params.height
        (fromMaybe params.minZoom options.minZoom)
        (fromMaybe params.maxZoom options.maxZoom)
        (fromMaybe defaultFitViewPadding options.padding)
    _ <- params.panZoom.setViewport viewport
      ( Just
          { duration: options.duration
          , ease: options.ease
          , interpolate: options.interpolate
          }
      )
    pure true

filterFitViewNodes
  :: forall n
   . NodeLookup n
  -> FitViewOptions
  -> NodeLookup n
filterFitViewNodes nodes opts =
  let
    optionIds = case opts.nodes of
      Just nodeArr -> Just (Set.fromFoldable (map _.id nodeArr))
      Nothing -> Nothing
  in
    Map.filter
      ( \n ->
          let
            hasSize =
              isJust n.measured.width && isJust n.measured.height
            visible = opts.includeHiddenNodes || not n.hidden
            inOptions = case optionIds of
              Nothing -> true
              Just ids -> Set.member n.id ids
          in
            hasSize && visible && inOptions
      )
      nodes

-- Calculate node position --------------------------------------------------

type CalculateNodePositionParams n =
  { nodeId :: String
  , nextPosition :: XYPosition
  , nodeLookup :: NodeLookup n
  , nodeOrigin :: NodeOrigin
  , nodeExtent :: Maybe CoordinateExtent
  , onError :: Maybe OnError
  }

-- | Returns `Nothing` when the node id is absent. The TS source uses the
-- | non-null assertion `nodeLookup.get(nodeId)!`; we make the partiality
-- | observable instead of crashing.
calculateNodePosition
  :: forall n
   . CalculateNodePositionParams n
  -> Maybe { position :: XYPosition, positionAbsolute :: XYPosition }
calculateNodePosition p = case Map.lookup p.nodeId p.nodeLookup of
  Nothing -> Nothing
  Just node ->
    let
      parentNode = case node.parentId of
        Just pid -> Map.lookup pid p.nodeLookup
        Nothing -> Nothing
      parentX = case parentNode of
        Just pn -> pn.internals.positionAbsolute.x
        Nothing -> 0.0
      parentY = case parentNode of
        Just pn -> pn.internals.positionAbsolute.y
        Nothing -> 0.0
      NodeOrigin origin = fromMaybe p.nodeOrigin node.origin

      extentBase = case node.extent of
        Just ne -> G.isCoordinateExtent (Just ne) <|> p.nodeExtent
        Nothing -> p.nodeExtent

      extent = case node.extent of
        Just ParentExtent | not node.expandParent ->
          case parentNode of
            Just pn -> case pn.measured.width, pn.measured.height of
              Just pw, Just ph ->
                Just
                  ( CoordinateExtent
                      { minX: parentX
                      , minY: parentY
                      , maxX: parentX + pw
                      , maxY: parentY + ph
                      }
                  )
              _, _ -> extentBase
            Nothing -> extentBase
        _ -> case parentNode, node.extent of
          Just _, Just (CoordExtent (CoordinateExtent ce)) ->
            Just
              ( CoordinateExtent
                  { minX: ce.minX + parentX
                  , minY: ce.minY + parentY
                  , maxX: ce.maxX + parentX
                  , maxY: ce.maxY + parentY
                  }
              )
          _, _ -> extentBase

      positionAbsolute = case extent of
        Just ext ->
          G.clampPosition p.nextPosition ext
            { width: node.measured.width, height: node.measured.height }
        Nothing -> p.nextPosition

      width = fromMaybe 0.0 node.measured.width
      height = fromMaybe 0.0 node.measured.height
    in
      Just
        { position:
            { x: positionAbsolute.x - parentX + width * origin.ox
            , y: positionAbsolute.y - parentY + height * origin.oy
            }
        , positionAbsolute
        }

-- Element removal ----------------------------------------------------------

type OnBeforeDelete n e =
  { nodes :: Array (NodeBase n), edges :: Array (EdgeBase e) }
  -> Aff
       ( Either Boolean
           { nodes :: Array (NodeBase n), edges :: Array (EdgeBase e) }
       )

type GetElementsToRemoveParams n e =
  { nodesToRemove :: Array { id :: String }
  , edgesToRemove :: Array { id :: String }
  , nodes :: Array (NodeBase n)
  , edges :: Array (EdgeBase e)
  , onBeforeDelete :: Maybe (OnBeforeDelete n e)
  }

getElementsToRemove
  :: forall n e
   . GetElementsToRemoveParams n e
  -> Aff { nodes :: Array (NodeBase n), edges :: Array (EdgeBase e) }
getElementsToRemove p = do
  let
    nodeIds = Set.fromFoldable (map _.id p.nodesToRemove) :: Set String
    matchingNodes = collectMatchingNodes nodeIds p.nodes

    edgeIds = Set.fromFoldable (map _.id p.edgesToRemove) :: Set String
    deletableEdges = Array.filter (\e -> e.deletable /= Just false) p.edges
    connectedEdges = getConnectedEdges matchingNodes deletableEdges
    matchingEdges =
      Array.foldl
        ( \acc edge ->
            if Set.member edge.id edgeIds
              && not (Array.any (\e -> e.id == edge.id) acc) then Array.snoc acc edge
            else acc
        )
        connectedEdges
        deletableEdges

  case p.onBeforeDelete of
    Nothing -> pure { nodes: matchingNodes, edges: matchingEdges }
    Just cb -> do
      result <- cb { nodes: matchingNodes, edges: matchingEdges }
      pure case result of
        Left true -> { nodes: matchingNodes, edges: matchingEdges }
        Left false -> { nodes: [], edges: [] }
        Right r -> r
  where
  collectMatchingNodes nodeIds nodes = Array.foldl step [] nodes
    where
    step acc node
      | node.deletable == Just false = acc
      | otherwise =
          let
            isIncluded = Set.member node.id nodeIds
            parentHit = case node.parentId of
              Just pid ->
                not isIncluded && Array.any (\n -> n.id == pid) acc
              Nothing -> false
          in
            if isIncluded || parentHit then Array.snoc acc node
            else acc
