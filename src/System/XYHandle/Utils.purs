-- | Pure helpers used by `XYFlow.XYHandle`. Mirrors
-- | `xyflow-main/packages/system/src/xyhandle/utils.ts`.
-- |
-- | Three of the four exported functions are pure (`getClosestHandle`,
-- | `getHandle`, `isConnectionValid`). `getHandleType` reads `classList` on a
-- | DOM element and is `Effect`-typed.
module System.XYHandle.Utils
  ( HandleRef
  , getClosestHandle
  , getHandle
  , getHandleType
  , isConnectionValid
  ) where

import Prelude

import Data.Array (concat, find, foldl, fromFoldable, head) as Array
import Data.Either (Either(..))
import Data.Map (lookup, values) as Map
import Data.Maybe (Maybe(..))
import Data.Number (sqrt)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Web.DOM.Element (Element)
import System.Types.Connection (ConnectionMode(..))
import System.Types.Geometry (NodeOrigin, XYPosition, mkNodeOrigin)
import System.Types.Handle (Handle, HandleType(..))
import System.Types.Node (InternalNodeBase, NodeLookup)
import System.Utils.Edges.Positions (getHandlePosition)
import System.Utils.General (getOverlappingArea, nodeToRect)

-- | The minimum identifying triple for a handle currently being dragged from.
-- | TS uses `Pick<Handle, 'nodeId' | 'id' | 'type'>`.
type HandleRef =
  { nodeId :: String
  , id :: Maybe String
  , handleType :: HandleType
  }

-- | The TS magic constant added to `connectionRadius` when scanning the
-- | spatial neighbourhood for handles. Wider than the visual radius so that
-- | quickly-moving pointers still pick up handles between frames.
additionalDistance :: Number
additionalDistance = 250.0

zeroOrigin :: NodeOrigin
zeroOrigin = mkNodeOrigin 0.0 0.0

-- | Positive-infinity seed for `min` folds over distances.
infinity :: Number
infinity = 1.0 / 0.0

-- | Return the subset of `nodeLookup` whose bounding rect overlaps the square
-- | centred on `position` of side `2 * distance`. Used to prune the handle
-- | search to nearby nodes.
nodesWithinDistance
  :: forall n
   . XYPosition
  -> NodeLookup n
  -> Number
  -> Array (InternalNodeBase n)
nodesWithinDistance position lookup distance =
  let
    rect =
      { x: position.x - distance
      , y: position.y - distance
      , width: distance * 2.0
      , height: distance * 2.0
      }
  in
    Array.foldl
      ( \acc node ->
          if getOverlappingArea rect (nodeToRect (Right node) zeroOrigin) > 0.0 then
            acc <> [ node ]
          else acc
      )
      []
      (mapValues lookup)

-- | `Map.values` returns a `List`; we want an `Array` for the foldl helpers
-- | below. `Array.fromFoldable` is the standard bridge.
mapValues :: forall n. NodeLookup n -> Array (InternalNodeBase n)
mapValues lookup = Array.fromFoldable (Map.values lookup)

-- | Find the nearest handle to `position` within `connectionRadius`. Skips the
-- | `fromHandle` itself. When several handles tie at the minimum distance the
-- | function prefers one of the *opposite* type (matching TS behaviour) and
-- | otherwise returns the first.
getClosestHandle
  :: forall n
   . XYPosition
  -> Number
  -> NodeLookup n
  -> HandleRef
  -> Maybe Handle
getClosestHandle position connectionRadius lookup fromHandle =
  let
    closeNodes = nodesWithinDistance position lookup
      (connectionRadius + additionalDistance)

    pairs :: Array (Tuple (InternalNodeBase n) Handle)
    pairs = Array.concat (map handlesOf closeNodes)
      where
      handlesOf node =
        let
          src = case node.internals.handleBounds of
            Just hb -> hb.source
            Nothing -> []
          tgt = case node.internals.handleBounds of
            Just hb -> hb.target
            Nothing -> []
        in
          map (Tuple node) (src <> tgt)

    isFromHandle h =
      fromHandle.nodeId == h.nodeId
        && fromHandle.handleType == h.handleType
        && fromHandle.id == h.id

    -- For each candidate compute the absolute position and distance, drop
    -- those outside `connectionRadius`.
    annotated
      :: Array
           { handle :: Handle
           , distance :: Number
           }
    annotated = Array.foldl
      ( \acc (Tuple node h) ->
          if isFromHandle h then acc
          else
            let
              abs = getHandlePosition node (Just h) h.position true
              dx = abs.x - position.x
              dy = abs.y - position.y
              d = sqrt (dx * dx + dy * dy)
            in
              if d > connectionRadius then acc
              else acc <>
                [ { handle: h { x = abs.x, y = abs.y }
                  , distance: d
                  }
                ]
      )
      []
      pairs

    minDistance = Array.foldl (\acc r -> min acc r.distance) infinity annotated

    closest = Array.foldl
      ( \acc r -> if r.distance == minDistance then acc <> [ r.handle ] else acc
      )
      []
      annotated

    oppositeType = case fromHandle.handleType of
      Source -> Target
      Target -> Source
  in
    case closest of
      [] -> Nothing
      [ h ] -> Just h
      _ -> case Array.find (\h -> h.handleType == oppositeType) closest of
        Just h -> Just h
        Nothing -> Array.head closest

-- | Look up a handle on a node by id. With `withAbsolutePosition = true` the
-- | returned handle's `x`/`y` are the on-canvas coordinates; otherwise they
-- | are the node-relative offsets.
getHandle
  :: forall n
   . String
  -> HandleType
  -> Maybe String
  -> NodeLookup n
  -> ConnectionMode
  -> Boolean
  -> Maybe Handle
getHandle nodeId handleType handleId lookup mode withAbsolutePosition =
  case Map.lookup nodeId lookup of
    Nothing -> Nothing
    Just node ->
      let
        handles :: Array Handle
        handles = case mode of
          Strict -> case node.internals.handleBounds of
            Just hb -> case handleType of
              Source -> hb.source
              Target -> hb.target
            Nothing -> []
          Loose -> case node.internals.handleBounds of
            Just hb -> hb.source <> hb.target
            Nothing -> []

        match :: Maybe Handle
        match = case handleId of
          Just hid -> Array.find (\h -> h.id == Just hid) handles
          Nothing -> Array.head handles
      in
        case match of
          Nothing -> Nothing
          Just h
            | withAbsolutePosition ->
                let abs = getHandlePosition node (Just h) h.position true
                in Just (h { x = abs.x, y = abs.y })
            | otherwise -> Just h

-- | Reads `element.classList.contains(className)`. Implemented in JS because
-- | `Web.DOM.Element` doesn't expose `classList` directly on the
-- | `web-dom` package version pinned in `spago.yaml`.
foreign import classListContains :: Element -> String -> Effect Boolean

-- | Decide the active handle type. If the caller passed an explicit
-- | `edgeUpdaterType` we honour it; otherwise we sniff the DOM element's
-- | classes for `target` or `source`. Returns `Nothing` when the element
-- | carries neither class.
getHandleType
  :: Maybe HandleType
  -> Maybe Element
  -> Effect (Maybe HandleType)
getHandleType edgeUpdaterType handleDomNode = case edgeUpdaterType of
  Just ht -> pure (Just ht)
  Nothing -> case handleDomNode of
    Nothing -> pure Nothing
    Just el -> do
      isTarget <- classListContains el "target"
      if isTarget then pure (Just Target)
      else do
        isSource <- classListContains el "source"
        if isSource then pure (Just Source) else pure Nothing

-- | Three-state truth table for connection validity:
-- |   isHandleValid                 -> Just true
-- |   in radius && !isHandleValid   -> Just false
-- |   otherwise                     -> Nothing
isConnectionValid :: Boolean -> Boolean -> Maybe Boolean
isConnectionValid isInsideConnectionRadius isHandleValid
  | isHandleValid = Just true
  | isInsideConnectionRadius && not isHandleValid = Just false
  | otherwise = Nothing
