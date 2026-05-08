-- | Store reconciliation utilities. Mirrors `utils/store.ts`. The TS code
-- | mutates `Map`s in place; the PS port wraps each lookup in `Effect.Ref`,
-- | reads, computes a new map, and writes back. Pure callers can use
-- | `handleExpandParent` directly without constructing Refs.
module XYFlow.Utils.Store
  ( UpdateNodesOptions
  , defaultUpdateNodesOptions
  , AdoptUserNodesReturn
  , isManualZIndexMode
  , updateAbsolutePositions
  , adoptUserNodes
  , handleExpandParent
  , updateNodeInternals
  , updateConnectionLookup
  , panBy
  , selectedNodeZ
  , rootParentZIncrement
  ) where

import Prelude

import Data.Array (any, foldl, fromFoldable, length) as Array
import Data.Either (Either(..))
import Data.Foldable (foldM, foldl) as Foldable
import Data.Int (toNumber) as Int
import Data.Map (Map)
import Data.Map (empty, insert, lookup, toUnfoldable, values) as Map
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Number (abs, round) as Number
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Web.HTML.HTMLElement (HTMLElement)
import XYFlow.Constants (infiniteExtent)
import XYFlow.Types.Connection
  ( ConnectionLookup
  , HandleConnection
  , ZIndexMode(..)
  )
import XYFlow.Types.Edge (EdgeBase, EdgeLookup)
import XYFlow.Types.Geometry
  ( CoordinateExtent(..)
  , NodeOrigin(..)
  , Rect
  , Transform(..)
  , XYPosition
  , mkNodeOrigin
  )
import XYFlow.Types.Handle (Handle, HandleType(..))
import XYFlow.Types.Node
  ( InternalNodeBase
  , InternalNodeUpdate
  , NodeBase
  , NodeChange(..)
  , NodeExtent(..)
  , NodeHandleBounds
  , NodeLookup
  , ParentExpandChild
  , ParentLookup
  , SetAttributesMode(..)
  )
import XYFlow.Types.PanZoom (PanZoomInstance)
import XYFlow.Utils.Dom
  ( elementBoundingRect
  , findViewportZoom
  , getDimensions
  , getHandleBounds
  )
import XYFlow.Utils.General
  ( clampPosition
  , clampPositionToParent
  , getBoundsOfRects
  , getNodeDimensions
  , getNodePositionWithOrigin
  , isCoordinateExtent
  , isNumeric
  , nodeToRect
  )

-- | Magic numbers from the TS source.
selectedNodeZ :: Int
selectedNodeZ = 1000

rootParentZIncrement :: Int
rootParentZIncrement = 10

type UpdateNodesOptions n =
  { nodeOrigin :: NodeOrigin
  , nodeExtent :: CoordinateExtent
  , elevateNodesOnSelect :: Boolean
  , defaults :: Maybe (NodeBase n -> NodeBase n)
  , zIndexMode :: ZIndexMode
  , checkEquality :: Boolean
  }

defaultUpdateNodesOptions :: forall n. UpdateNodesOptions n
defaultUpdateNodesOptions =
  { nodeOrigin: mkNodeOrigin 0.0 0.0
  , nodeExtent: infiniteExtent
  , elevateNodesOnSelect: true
  , defaults: Nothing
  , zIndexMode: ZBasic
  , checkEquality: true
  }

type AdoptUserNodesReturn =
  { nodesInitialized :: Boolean
  , hasSelectedNodes :: Boolean
  }

isManualZIndexMode :: ZIndexMode -> Boolean
isManualZIndexMode = case _ of
  ZManual -> true
  _ -> false

-- Pure helpers --------------------------------------------------------------

calculateZ :: forall n. NodeBase n -> Int -> ZIndexMode -> Number
calculateZ node selZ zMode =
  let
    zIndex = case node.zIndex of
      Just z | isNumeric (Int.toNumber z) -> Int.toNumber z
      _ -> 0.0
    bonus =
      if isManualZIndexMode zMode then 0.0
      else if node.selected then Int.toNumber selZ
      else 0.0
  in
    zIndex + bonus

-- | Strip the `internals` field so an InternalNodeBase can be passed to
-- | NodeBase-shaped helpers.
toBaseLike :: forall n. InternalNodeBase n -> NodeBase n
toBaseLike n =
  { id: n.id
  , position: n.position
  , data: n.data
  , sourcePosition: n.sourcePosition
  , targetPosition: n.targetPosition
  , hidden: n.hidden
  , selected: n.selected
  , dragging: n.dragging
  , draggable: n.draggable
  , selectable: n.selectable
  , connectable: n.connectable
  , deletable: n.deletable
  , dragHandle: n.dragHandle
  , width: n.width
  , height: n.height
  , initialWidth: n.initialWidth
  , initialHeight: n.initialHeight
  , parentId: n.parentId
  , zIndex: n.zIndex
  , extent: n.extent
  , expandParent: n.expandParent
  , ariaLabel: n.ariaLabel
  , origin: n.origin
  , handles: n.handles
  , measured: n.measured
  , nodeType: n.nodeType
  }

calculateChildXYZ
  :: forall n
   . InternalNodeBase n
  -> InternalNodeBase n
  -> NodeOrigin
  -> CoordinateExtent
  -> Int
  -> ZIndexMode
  -> { x :: Number, y :: Number, z :: Number }
calculateChildXYZ child parent origin extent selZ zMode =
  let
    parentX = parent.internals.positionAbsolute.x
    parentY = parent.internals.positionAbsolute.y
    childDimensions = getNodeDimensions child
    positionWithOrigin = getNodePositionWithOrigin (toBaseLike child) origin
    childExtent = isCoordinateExtent child.extent
    clampedRel = case childExtent of
      Just ce -> clampPosition positionWithOrigin ce
        { width: Just childDimensions.width
        , height: Just childDimensions.height
        }
      Nothing -> positionWithOrigin
    absInitial =
      clampPosition
        { x: parentX + clampedRel.x, y: parentY + clampedRel.y }
        extent
        { width: Just childDimensions.width
        , height: Just childDimensions.height
        }
    absoluteFinal = case child.extent of
      Just ParentExtent ->
        clampPositionToParent absInitial childDimensions parent
      _ -> absInitial
    childZ = calculateZ (toBaseLike child) selZ zMode
    parentZ = parent.internals.z
  in
    { x: absoluteFinal.x
    , y: absoluteFinal.y
    , z: if parentZ >= childZ then parentZ + 1.0 else childZ
    }

updateParentLookup
  :: forall n. InternalNodeBase n -> ParentLookup n -> ParentLookup n
updateParentLookup node parentLookup = case node.parentId of
  Nothing -> parentLookup
  Just pid ->
    let
      childMap = case Map.lookup pid parentLookup of
        Just m -> m
        Nothing -> Map.empty
    in
      Map.insert pid (Map.insert node.id node childMap) parentLookup

updateChildNodePure
  :: forall n
   . InternalNodeBase n
  -> NodeLookup n
  -> ParentLookup n
  -> UpdateNodesOptions n
  -> Maybe Int
  -> { node :: InternalNodeBase n
     , nodeLookup :: NodeLookup n
     , parentLookup :: ParentLookup n
     , rootParentIndex :: Maybe Int
     }
updateChildNodePure node nodeLookup parentLookup options rootParentIndex =
  case node.parentId of
    Nothing -> { node, nodeLookup, parentLookup, rootParentIndex }
    Just parentId ->
      case Map.lookup parentId nodeLookup of
        Nothing -> { node, nodeLookup, parentLookup, rootParentIndex }
        Just parentNode ->
          let
            parentLookup1 = updateParentLookup node parentLookup

            shouldBump = case rootParentIndex, parentNode.parentId of
              Just _, Nothing ->
                parentNode.internals.rootParentIndex == Nothing
                  && options.zIndexMode == ZAuto
              _, _ -> false

            { parentNode2, nextRootIndex } =
              if shouldBump then
                let
                  nextI = (fromMaybe 0 rootParentIndex) + 1
                  bumped = parentNode
                    { internals = parentNode.internals
                        { rootParentIndex = Just nextI
                        , z = parentNode.internals.z
                            + Int.toNumber nextI * Int.toNumber rootParentZIncrement
                        }
                    }
                in
                  { parentNode2: bumped, nextRootIndex: Just nextI }
              else
                let
                  next = case rootParentIndex, parentNode.internals.rootParentIndex of
                    Just _, Just i -> Just i
                    _, _ -> rootParentIndex
                in
                  { parentNode2: parentNode, nextRootIndex: next }

            nodeLookupAfterParent =
              Map.insert parentNode2.id parentNode2 nodeLookup

            selZ =
              if options.elevateNodesOnSelect
                && not (isManualZIndexMode options.zIndexMode) then selectedNodeZ
              else 0

            xyz = calculateChildXYZ node parentNode2 options.nodeOrigin
              options.nodeExtent
              selZ
              options.zIndexMode

            positionAbs = node.internals.positionAbsolute
            positionChanged = xyz.x /= positionAbs.x || xyz.y /= positionAbs.y

            updatedNode =
              if positionChanged || xyz.z /= node.internals.z then
                node
                  { internals = node.internals
                      { positionAbsolute =
                          if positionChanged then { x: xyz.x, y: xyz.y }
                          else positionAbs
                      , z = xyz.z
                      }
                  }
              else node

            nodeLookupFinal =
              Map.insert node.id updatedNode nodeLookupAfterParent
          in
            { node: updatedNode
            , nodeLookup: nodeLookupFinal
            , parentLookup: parentLookup1
            , rootParentIndex: nextRootIndex
            }

-- Public Effect functions --------------------------------------------------

updateAbsolutePositions
  :: forall n
   . Ref (NodeLookup n)
  -> Ref (ParentLookup n)
  -> UpdateNodesOptions n
  -> Effect Unit
updateAbsolutePositions nodeLookupRef parentLookupRef options = do
  initial <- Ref.read nodeLookupRef
  parents <- Ref.read parentLookupRef
  let
    finalState = Foldable.foldl
      ( \st node ->
          if isJust node.parentId then
            let
              r = updateChildNodePure node st.nodeLookup st.parentLookup
                options
                st.rootParentIndex
            in
              { nodeLookup: r.nodeLookup
              , parentLookup: r.parentLookup
              , rootParentIndex: r.rootParentIndex
              }
          else
            let
              positionWithOrigin =
                getNodePositionWithOrigin (toBaseLike node) options.nodeOrigin
              ext = case isCoordinateExtent node.extent of
                Just ce -> ce
                Nothing -> options.nodeExtent
              dims = getNodeDimensions node
              clamped = clampPosition positionWithOrigin ext
                { width: Just dims.width, height: Just dims.height }
              updated = node
                { internals = node.internals
                    { positionAbsolute = clamped }
                }
            in
              st { nodeLookup = Map.insert node.id updated st.nodeLookup }
      )
      { nodeLookup: initial
      , parentLookup: parents
      , rootParentIndex: Nothing :: Maybe Int
      }
      (Map.values initial)
  Ref.write finalState.nodeLookup nodeLookupRef
  Ref.write finalState.parentLookup parentLookupRef

adoptUserNodes
  :: forall n
   . Array (NodeBase n)
  -> Ref (NodeLookup n)
  -> Ref (ParentLookup n)
  -> UpdateNodesOptions n
  -> Effect AdoptUserNodesReturn
adoptUserNodes nodes nodeLookupRef parentLookupRef options = do
  prev <- Ref.read nodeLookupRef
  let
    selZ =
      if options.elevateNodesOnSelect
        && not (isManualZIndexMode options.zIndexMode) then selectedNodeZ
      else 0

    initial =
      { nodeLookup: (Map.empty :: NodeLookup n)
      , parentLookup: (Map.empty :: ParentLookup n)
      , nodesInitialized: Array.length nodes > 0
      , hasSelectedNodes: false
      , rootParentIndex: Just 0 :: Maybe Int
      }

    step st userNode =
      let
        userNodeWithDefaults = case options.defaults of
          Just f -> f userNode
          Nothing -> userNode
        positionWithOrigin =
          getNodePositionWithOrigin userNodeWithDefaults options.nodeOrigin
        extent = case isCoordinateExtent userNodeWithDefaults.extent of
          Just ce -> ce
          Nothing -> options.nodeExtent
        dims = getNodeDimensions userNodeWithDefaults
        clamped = clampPosition positionWithOrigin extent
          { width: Just dims.width, height: Just dims.height }
        oldInternal = Map.lookup userNodeWithDefaults.id prev
        internalNode :: InternalNodeBase n
        internalNode =
          { id: userNodeWithDefaults.id
          , position: userNodeWithDefaults.position
          , data: userNodeWithDefaults.data
          , sourcePosition: userNodeWithDefaults.sourcePosition
          , targetPosition: userNodeWithDefaults.targetPosition
          , hidden: userNodeWithDefaults.hidden
          , selected: userNodeWithDefaults.selected
          , dragging: userNodeWithDefaults.dragging
          , draggable: userNodeWithDefaults.draggable
          , selectable: userNodeWithDefaults.selectable
          , connectable: userNodeWithDefaults.connectable
          , deletable: userNodeWithDefaults.deletable
          , dragHandle: userNodeWithDefaults.dragHandle
          , width: userNodeWithDefaults.width
          , height: userNodeWithDefaults.height
          , initialWidth: userNodeWithDefaults.initialWidth
          , initialHeight: userNodeWithDefaults.initialHeight
          , parentId: userNodeWithDefaults.parentId
          , zIndex: userNodeWithDefaults.zIndex
          , extent: userNodeWithDefaults.extent
          , expandParent: userNodeWithDefaults.expandParent
          , ariaLabel: userNodeWithDefaults.ariaLabel
          , origin: userNodeWithDefaults.origin
          , handles: userNodeWithDefaults.handles
          , measured: userNodeWithDefaults.measured
          , nodeType: userNodeWithDefaults.nodeType
          , internals:
              { positionAbsolute: clamped
              , z: calculateZ userNodeWithDefaults selZ options.zIndexMode
              , rootParentIndex: case oldInternal of
                  Just o -> o.internals.rootParentIndex
                  Nothing -> Nothing
              , handleBounds: parseHandles userNodeWithDefaults oldInternal
              , bounds: case oldInternal of
                  Just o -> o.internals.bounds
                  Nothing -> Nothing
              }
          }

        nodeLookup1 =
          Map.insert userNodeWithDefaults.id internalNode st.nodeLookup
        st1 = st { nodeLookup = nodeLookup1 }

        st2 =
          let
            measuredOk =
              isJust internalNode.measured.width
                && isJust internalNode.measured.height
          in
            if not measuredOk && not internalNode.hidden then
              st1 { nodesInitialized = false }
            else st1

        st3 = case userNodeWithDefaults.parentId of
          Just _ ->
            let
              r = updateChildNodePure internalNode st2.nodeLookup
                st2.parentLookup
                options
                st2.rootParentIndex
            in
              st2
                { nodeLookup = r.nodeLookup
                , parentLookup = r.parentLookup
                , rootParentIndex = r.rootParentIndex
                }
          Nothing -> st2
      in
        st3
          { hasSelectedNodes = st3.hasSelectedNodes || userNodeWithDefaults.selected
          }

    final = Foldable.foldl step initial nodes
  Ref.write final.nodeLookup nodeLookupRef
  Ref.write final.parentLookup parentLookupRef
  pure
    { nodesInitialized: final.nodesInitialized
    , hasSelectedNodes: final.hasSelectedNodes
    }

parseHandles
  :: forall n
   . NodeBase n
  -> Maybe (InternalNodeBase n)
  -> Maybe NodeHandleBounds
parseHandles userNode internalNode = case userNode.handles of
  Nothing ->
    case userNode.measured.width, userNode.measured.height of
      Nothing, _ -> Nothing
      _, Nothing -> Nothing
      _, _ -> case internalNode of
        Just i -> i.internals.handleBounds
        Nothing -> Nothing
  Just handles ->
    let
      empty :: { source :: Array Handle, target :: Array Handle }
      empty = { source: [], target: [] }

      go acc h =
        let
          bounds :: Handle
          bounds =
            { id: h.id
            , width: fromMaybe 1.0 h.width
            , height: fromMaybe 1.0 h.height
            , nodeId: userNode.id
            , x: h.x
            , y: h.y
            , position: h.position
            , handleType: h.handleType
            }
        in
          case h.handleType of
            Source -> acc { source = acc.source <> [ bounds ] }
            Target -> acc { target = acc.target <> [ bounds ] }

      collected = Foldable.foldl go empty handles
    in
      Just { source: Just collected.source, target: Just collected.target }

handleExpandParent
  :: forall n
   . Array ParentExpandChild
  -> NodeLookup n
  -> ParentLookup n
  -> NodeOrigin
  -> Array (NodeChange n)
handleExpandParent children nodeLookup parentLookup defaultOrigin =
  let
    expansions =
      Foldable.foldl
        ( \acc child -> case Map.lookup child.parentId nodeLookup of
            Nothing -> acc
            Just parent ->
              let
                prevRect = case Map.lookup child.parentId acc of
                  Just r -> r.expandedRect
                  Nothing -> nodeToRect (Right parent) defaultOrigin
                expanded = getBoundsOfRects prevRect child.rect
              in
                Map.insert child.parentId
                  { expandedRect: expanded, parent }
                  acc
        )
        ( Map.empty ::
            Map String { expandedRect :: Rect, parent :: InternalNodeBase n }
        )
        children

    pairs :: Array (Tuple String { expandedRect :: Rect, parent :: InternalNodeBase n })
    pairs = Map.toUnfoldable expansions
  in
    Array.foldl (stepExpansion children parentLookup defaultOrigin) [] pairs

stepExpansion
  :: forall n
   . Array ParentExpandChild
  -> ParentLookup n
  -> NodeOrigin
  -> Array (NodeChange n)
  -> Tuple String { expandedRect :: Rect, parent :: InternalNodeBase n }
  -> Array (NodeChange n)
stepExpansion children parentLookup defaultOrigin changes (Tuple parentId rec) =
  let
    positionAbsolute = rec.parent.internals.positionAbsolute
    dimensions = getNodeDimensions rec.parent
    NodeOrigin origin = fromMaybe defaultOrigin rec.parent.origin

    xChange =
      if rec.expandedRect.x < positionAbsolute.x then
        Number.round (Number.abs (positionAbsolute.x - rec.expandedRect.x))
      else 0.0
    yChange =
      if rec.expandedRect.y < positionAbsolute.y then
        Number.round (Number.abs (positionAbsolute.y - rec.expandedRect.y))
      else 0.0

    newWidth = max dimensions.width (Number.round rec.expandedRect.width)
    newHeight = max dimensions.height (Number.round rec.expandedRect.height)

    widthChange = (newWidth - dimensions.width) * origin.ox
    heightChange = (newHeight - dimensions.height) * origin.oy

    significantPositionChange =
      xChange > 0.0 || yChange > 0.0 || widthChange /= 0.0
        || heightChange /= 0.0

    posChange =
      if significantPositionChange then
        [ NodePositionChange
            { id: parentId
            , position: Just
                { x: rec.parent.position.x - xChange + widthChange
                , y: rec.parent.position.y - yChange + heightChange
                }
            , positionAbsolute: Nothing
            , dragging: false
            }
        ]
      else []

    childPosChanges =
      if significantPositionChange then
        case Map.lookup parentId parentLookup of
          Nothing -> []
          Just kids ->
            ( Array.fromFoldable (Map.values kids)
                # filterMap
                    ( \kid ->
                        if Array.any (\c -> c.id == kid.id) children then Nothing
                        else
                          Just
                            ( NodePositionChange
                                { id: kid.id
                                , position: Just
                                    { x: kid.position.x + xChange
                                    , y: kid.position.y + yChange
                                    }
                                , positionAbsolute: Nothing
                                , dragging: false
                                }
                            )
                    )
            )
      else []

    significantDimensionChange =
      dimensions.width < rec.expandedRect.width
        || dimensions.height < rec.expandedRect.height
        || xChange /= 0.0
        || yChange /= 0.0

    dimChange =
      if significantDimensionChange then
        [ NodeDimensionChange
            { id: parentId
            , dimensions: Just
                { width:
                    newWidth
                      +
                        ( if xChange /= 0.0 then origin.ox * xChange - widthChange
                          else 0.0
                        )
                , height:
                    newHeight
                      +
                        ( if yChange /= 0.0 then origin.oy * yChange - heightChange
                          else 0.0
                        )
                }
            , resizing: false
            , setAttributes: SetBothDimensions
            }
        ]
      else []
  in
    changes <> posChange <> childPosChanges <> dimChange

filterMap :: forall a b. (a -> Maybe b) -> Array a -> Array b
filterMap f =
  Array.foldl
    ( \acc x -> case f x of
        Just b -> acc <> [ b ]
        Nothing -> acc
    )
    []

-- DOM-driven node-internals update -----------------------------------------

updateNodeInternals
  :: forall n
   . Map String InternalNodeUpdate
  -> Ref (NodeLookup n)
  -> Ref (ParentLookup n)
  -> Maybe HTMLElement
  -> NodeOrigin
  -> CoordinateExtent
  -> ZIndexMode
  -> Effect { changes :: Array (NodeChange n), updatedInternals :: Boolean }
updateNodeInternals updates nodeLookupRef parentLookupRef mDom origin extent zMode =
  case mDom of
    Nothing -> pure { changes: [], updatedInternals: false }
    Just dom -> do
      mZoom <- findViewportZoom dom
      case mZoom of
        Nothing -> pure { changes: [], updatedInternals: false }
        Just zoom -> do
          nodeLookup0 <- Ref.read nodeLookupRef
          parentLookup0 <- Ref.read parentLookupRef
          let
            initial =
              { nodeLookup: nodeLookup0
              , parentLookup: parentLookup0
              , changes: ([] :: Array (NodeChange n))
              , parentExpandChildren: ([] :: Array ParentExpandChild)
              , updatedInternals: false
              }
          result <-
            Foldable.foldM
              ( \acc u -> processUpdate u acc zoom origin extent zMode )
              initial
              (Map.values updates)
          Ref.write result.nodeLookup nodeLookupRef
          Ref.write result.parentLookup parentLookupRef
          let
            finalChanges =
              if Array.length result.parentExpandChildren > 0 then
                result.changes
                  <> handleExpandParent result.parentExpandChildren
                    result.nodeLookup
                    result.parentLookup
                    origin
              else result.changes
          pure
            { changes: finalChanges
            , updatedInternals: result.updatedInternals
            }

type UpdateAcc n =
  { nodeLookup :: NodeLookup n
  , parentLookup :: ParentLookup n
  , changes :: Array (NodeChange n)
  , parentExpandChildren :: Array ParentExpandChild
  , updatedInternals :: Boolean
  }

processUpdate
  :: forall n
   . InternalNodeUpdate
  -> UpdateAcc n
  -> Number
  -> NodeOrigin
  -> CoordinateExtent
  -> ZIndexMode
  -> Effect (UpdateAcc n)
processUpdate update acc zoom origin extent zMode =
  case Map.lookup update.id acc.nodeLookup of
    Nothing -> pure acc
    Just node ->
      if node.hidden then
        let
          cleared = node
            { internals = node.internals { handleBounds = Nothing } }
        in
          pure
            ( acc
                { nodeLookup =
                    Map.insert node.id cleared acc.nodeLookup
                , updatedInternals = true
                }
            )
      else do
        dims <- getDimensions update.nodeElement
        let
          dimensionChanged =
            node.measured.width /= Just dims.width
              || node.measured.height /= Just dims.height
          shouldUpdate =
            dims.width > 0.0 && dims.height > 0.0
              &&
                ( dimensionChanged
                    || node.internals.handleBounds == Nothing
                    || update.force
                )
        if not shouldUpdate then pure acc
        else do
          nodeBounds <- elementBoundingRect update.nodeElement
          let
            chosenExt = case isCoordinateExtent node.extent of
              Just ce -> Just ce
              Nothing -> Just extent
            positionAbsoluteAdjusted = case node.parentId, node.extent of
              Just pid, Just ParentExtent ->
                case Map.lookup pid acc.nodeLookup of
                  Just parent ->
                    clampPositionToParent node.internals.positionAbsolute dims
                      parent
                  Nothing -> node.internals.positionAbsolute
              _, _ -> case chosenExt of
                Just ce ->
                  clampPosition node.internals.positionAbsolute ce
                    { width: Just dims.width, height: Just dims.height }
                Nothing -> node.internals.positionAbsolute
          sourceHandles <- getHandleBounds Source update.nodeElement nodeBounds
            zoom
            node.id
          targetHandles <- getHandleBounds Target update.nodeElement nodeBounds
            zoom
            node.id
          let
            newNode = node
              { measured = { width: Just dims.width, height: Just dims.height }
              , internals = node.internals
                  { positionAbsolute = positionAbsoluteAdjusted
                  , handleBounds = Just
                      { source: sourceHandles, target: targetHandles }
                  }
              }
            nodeLookup1 = Map.insert node.id newNode acc.nodeLookup

            childResult = case node.parentId of
              Just _ ->
                let
                  r = updateChildNodePure newNode nodeLookup1 acc.parentLookup
                    ( defaultUpdateNodesOptions
                        { nodeOrigin = origin, zIndexMode = zMode }
                    )
                    Nothing
                in
                  { nodeLookup: r.nodeLookup, parentLookup: r.parentLookup }
              Nothing ->
                { nodeLookup: nodeLookup1, parentLookup: acc.parentLookup }

            extraChanges =
              if dimensionChanged then
                [ NodeDimensionChange
                    { id: node.id
                    , dimensions: Just dims
                    , resizing: false
                    , setAttributes: SetBothDimensions
                    }
                ]
              else []
            extraExpand = case node.parentId of
              Just pid | dimensionChanged && node.expandParent ->
                [ { id: node.id
                  , parentId: pid
                  , rect: nodeToRect (Right newNode) origin
                  }
                ]
              _ -> []
          pure
            ( acc
                { nodeLookup = childResult.nodeLookup
                , parentLookup = childResult.parentLookup
                , changes = acc.changes <> extraChanges
                , parentExpandChildren = acc.parentExpandChildren
                    <> extraExpand
                , updatedInternals = true
                }
            )

-- Connection lookup --------------------------------------------------------

addConnectionToLookup
  :: String
  -> HandleConnection
  -> String
  -> ConnectionLookup
  -> String
  -> Maybe String
  -> ConnectionLookup
addConnectionToLookup typeStr connection connectionKey connectionLookup nodeId mHandleId =
  let
    addAt key lookup =
      let
        inner = case Map.lookup key lookup of
          Just m -> m
          Nothing -> Map.empty
      in
        Map.insert key (Map.insert connectionKey connection inner) lookup

    afterNode = addAt nodeId connectionLookup
    afterType = addAt (nodeId <> "-" <> typeStr) afterNode
  in
    case mHandleId of
      Just hid -> addAt (nodeId <> "-" <> typeStr <> "-" <> hid) afterType
      Nothing -> afterType

updateConnectionLookup
  :: forall e
   . Ref ConnectionLookup
  -> Ref (EdgeLookup e)
  -> Array (EdgeBase e)
  -> Effect Unit
updateConnectionLookup connRef edgeRef edges = do
  let
    initial =
      { connectionLookup: (Map.empty :: ConnectionLookup)
      , edgeLookup: (Map.empty :: EdgeLookup e)
      }
    final = Foldable.foldl
      ( \st edge ->
          let
            connection :: HandleConnection
            connection =
              { edgeId: edge.id
              , source: edge.source
              , target: edge.target
              , sourceHandle: edge.sourceHandle
              , targetHandle: edge.targetHandle
              }
            sourceKey =
              edge.source <> "-" <> fromMaybe "null" edge.sourceHandle
                <> "--"
                <> edge.target
                <> "-"
                <> fromMaybe "null" edge.targetHandle
            targetKey =
              edge.target <> "-" <> fromMaybe "null" edge.targetHandle
                <> "--"
                <> edge.source
                <> "-"
                <> fromMaybe "null" edge.sourceHandle
            connLookup1 =
              addConnectionToLookup "source" connection targetKey
                st.connectionLookup
                edge.source
                edge.sourceHandle
            connLookup2 =
              addConnectionToLookup "target" connection sourceKey
                connLookup1
                edge.target
                edge.targetHandle
          in
            { connectionLookup: connLookup2
            , edgeLookup: Map.insert edge.id edge st.edgeLookup
            }
      )
      initial
      edges
  Ref.write final.connectionLookup connRef
  Ref.write final.edgeLookup edgeRef

-- Pan-by ------------------------------------------------------------------

panBy
  :: XYPosition
  -> Maybe PanZoomInstance
  -> Transform
  -> CoordinateExtent
  -> Number
  -> Number
  -> Aff Boolean
panBy delta mPanZoom (Transform t) translateExtent width height =
  case mPanZoom of
    Nothing -> pure false
    Just pz ->
      if delta.x == 0.0 && delta.y == 0.0 then pure false
      else do
        next <- pz.setViewportConstrained
          { x: t.tx + delta.x, y: t.ty + delta.y, zoom: t.scale }
          ( CoordinateExtent
              { minX: 0.0, minY: 0.0, maxX: width, maxY: height }
          )
          translateExtent
        pure case next of
          Just _ -> true
          Nothing -> false
