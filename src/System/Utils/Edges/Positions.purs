-- | Edge endpoint resolution. Mirrors `utils/edges/positions.ts`.
-- |
-- | Divergence note: the TS function calls `params.onError?.(...)` as a side
-- | effect when handle resolution fails, then returns `null`. The PS port
-- | keeps `getEdgePosition` total (`Maybe EdgePosition`) and lets callers
-- | observe `Nothing` plus the originating ids to surface the same error
-- | through their own `Effect` channel. The `onError` field is retained for
-- | API parity but is never invoked from this module.
module System.Utils.Edges.Positions
  ( GetEdgePositionParams
  , getEdgePosition
  , getHandlePosition
  ) where

import Prelude

import Data.Array (concat, find, length, mapMaybe, (!!)) as Array
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import System.Types.Connection (ConnectionMode(..))
import System.Types.Edge (EdgePosition)
import System.Types.Geometry (Position(..), XYPosition)
import System.Types.Handle
  ( Handle
  , mkSourceHandle
  , mkTargetHandle
  , unSourceHandle
  , unTargetHandle
  )
import System.Types.Ids (NodeId)
import System.Types.Node (InternalNodeBase, NodeHandle, NodeHandleBounds, OnError)
import System.Utils.General (getNodeDimensions)

type GetEdgePositionParams n =
  { id :: String
  , sourceNode :: InternalNodeBase n
  , sourceHandle :: Maybe String
  , targetNode :: InternalNodeBase n
  , targetHandle :: Maybe String
  , connectionMode :: ConnectionMode
  , onError :: Maybe OnError
  }

isNodeInitialized :: forall n. InternalNodeBase n -> Boolean
isNodeInitialized node = hasHandles && hasSomeWidth
  where
  hasHandles = case node.internals.handleBounds of
    Just _ -> true
    Nothing -> case node.handles of
      Just hs -> Array.length hs > 0
      Nothing -> false
  hasSomeWidth =
    isJust node.measured.width
      || isJust node.width
      || isJust node.initialWidth

toHandleBounds :: forall n. InternalNodeBase n -> Maybe NodeHandleBounds
toHandleBounds node = case node.handles of
  Nothing -> Nothing
  Just handles ->
    let
      asHandles = map (\h -> nodeHandleToHandle h node.id) handles
    in
      Just
        { source: Array.mapMaybe mkSourceHandle asHandles
        , target: Array.mapMaybe mkTargetHandle asHandles
        }

nodeHandleToHandle :: NodeHandle -> NodeId -> Handle
nodeHandleToHandle h nodeId =
  { id: h.id
  , nodeId
  , x: h.x
  , y: h.y
  , position: h.position
  , handleType: h.handleType
  , width: fromMaybe 1.0 h.width
  , height: fromMaybe 1.0 h.height
  }

getHandle :: Array Handle -> Maybe String -> Maybe Handle
getHandle bounds handleId = case handleId of
  Nothing -> bounds Array.!! 0
  Just hid -> Array.find (\h -> h.id == Just hid) bounds

getEdgePosition
  :: forall n
   . GetEdgePositionParams n
  -> Maybe EdgePosition
getEdgePosition params =
  if not (isNodeInitialized params.sourceNode)
    || not (isNodeInitialized params.targetNode) then Nothing
  else do
    let
      sourceBounds = case params.sourceNode.internals.handleBounds of
        Just b -> Just b
        Nothing -> toHandleBounds params.sourceNode
      targetBounds = case params.targetNode.internals.handleBounds of
        Just b -> Just b
        Nothing -> toHandleBounds params.targetNode
      sourceHandles = case sourceBounds of
        Just b -> map unSourceHandle b.source
        Nothing -> []
      targetHandlePool = case params.connectionMode of
        Strict ->
          case targetBounds of
            Just b -> map unTargetHandle b.target
            Nothing -> []
        Loose ->
          -- In Loose mode the target endpoint may also be a source
          -- handle, so both arrays are unwrapped and merged.
          case targetBounds of
            Just b -> Array.concat
              [ map unTargetHandle b.target, map unSourceHandle b.source ]
            Nothing -> []
    sh <- getHandle sourceHandles params.sourceHandle
    th <- getHandle targetHandlePool params.targetHandle
    let
      srcXY = getHandlePosition params.sourceNode (Just sh) sh.position false
      tgtXY = getHandlePosition params.targetNode (Just th) th.position false
    pure
      { sourceX: srcXY.x
      , sourceY: srcXY.y
      , targetX: tgtXY.x
      , targetY: tgtXY.y
      , sourcePosition: sh.position
      , targetPosition: th.position
      }

-- | Compute the on-canvas position of a handle. `Nothing` for `handle` falls
-- | back to using the node's outer dimensions and `fallbackPosition`.
getHandlePosition
  :: forall n
   . InternalNodeBase n
  -> Maybe Handle
  -> Position
  -> Boolean
  -> XYPosition
getHandlePosition node handle fallbackPosition center =
  let
    baseX = case handle of
      Just h -> h.x
      Nothing -> 0.0
    baseY = case handle of
      Just h -> h.y
      Nothing -> 0.0
    x = baseX + node.internals.positionAbsolute.x
    y = baseY + node.internals.positionAbsolute.y
    dim = case handle of
      Just h -> { width: h.width, height: h.height }
      Nothing -> fromMaybe { width: 0.0, height: 0.0 }
        (getNodeDimensions node)
    pos = case handle of
      Just h -> h.position
      Nothing -> fallbackPosition
  in
    if center then { x: x + dim.width / 2.0, y: y + dim.height / 2.0 }
    else case pos of
      PosTop -> { x: x + dim.width / 2.0, y }
      PosRight -> { x: x + dim.width, y: y + dim.height / 2.0 }
      PosBottom -> { x: x + dim.width / 2.0, y: y + dim.height }
      PosLeft -> { x, y: y + dim.height / 2.0 }

