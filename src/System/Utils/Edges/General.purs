-- | Pure edge utilities ported from
-- | `xyflow-main/packages/system/src/utils/edges/general.ts`.
module System.Utils.Edges.General
  ( EdgeCenter
  , EdgePathResult
  , getEdgeCenter
  , GetEdgeZIndexParams
  , getElevatedEdgeZIndex
  , IsEdgeVisibleParams
  , isEdgeVisible
  , GetEdgeId
  , getEdgeId
  , addEdge
  , reconnectEdge
  ) where

import Prelude

import Data.Array (any, filter, snoc) as Array
import Data.Either (Either(..))
import Data.Int (floor) as Int
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Number (abs) as Number
import System.Constants (ErrorCode(..), errorMessage)
import Data.Newtype (unwrap)
import System.Types.Connection (Connection, ZIndexMode(..))
import System.Types.Edge (EdgeBase)
import System.Types.Geometry (Box, Rect, Transform(..), mkNodeOrigin)
import System.Types.Node (InternalNodeBase)
import System.Utils.General
  ( boxToRect
  , getBoundsOfBoxes
  , getOverlappingArea
  , nodeToBox
  )

-- | Computed midpoint plus per-axis offsets to the source corner.
type EdgeCenter =
  { centerX :: Number
  , centerY :: Number
  , offsetX :: Number
  , offsetY :: Number
  }

-- | The unified return shape for every `getXxxPath` function in the edges
-- | subpackage. The TS originals return a 5-tuple; PS uses a record.
type EdgePathResult =
  { path :: String
  , labelX :: Number
  , labelY :: Number
  , offsetX :: Number
  , offsetY :: Number
  }

getEdgeCenter
  :: { sourceX :: Number
     , sourceY :: Number
     , targetX :: Number
     , targetY :: Number
     }
  -> EdgeCenter
getEdgeCenter { sourceX, sourceY, targetX, targetY } =
  let
    xOffset = Number.abs (targetX - sourceX) / 2.0
    centerX =
      if targetX < sourceX then targetX + xOffset
      else targetX - xOffset
    yOffset = Number.abs (targetY - sourceY) / 2.0
    centerY =
      if targetY < sourceY then targetY + yOffset
      else targetY - yOffset
  in
    { centerX, centerY, offsetX: xOffset, offsetY: yOffset }

type GetEdgeZIndexParams n =
  { sourceNode :: InternalNodeBase n
  , targetNode :: InternalNodeBase n
  , selected :: Boolean
  , zIndex :: Int
  , elevateOnSelect :: Boolean
  , zIndexMode :: ZIndexMode
  }

-- | The TS source treats `internals.z` as `number`; we keep it as `Number`
-- | until the very end where the result is floored to `Int`.
getElevatedEdgeZIndex :: forall n. GetEdgeZIndexParams n -> Int
getElevatedEdgeZIndex p = case p.zIndexMode of
  ZManual -> p.zIndex
  _ ->
    let
      edgeZ =
        if p.elevateOnSelect && p.selected then p.zIndex + 1000
        else p.zIndex
      sourceContributes =
        isJust p.sourceNode.parentId
          || (p.elevateOnSelect && p.sourceNode.selected)
      targetContributes =
        isJust p.targetNode.parentId
          || (p.elevateOnSelect && p.targetNode.selected)
      sourceZ = if sourceContributes then p.sourceNode.internals.z else 0.0
      targetZ = if targetContributes then p.targetNode.internals.z else 0.0
      nodeZ = max sourceZ targetZ
    in
      edgeZ + Int.floor nodeZ

type IsEdgeVisibleParams n =
  { sourceNode :: InternalNodeBase n
  , targetNode :: InternalNodeBase n
  , width :: Number
  , height :: Number
  , transform :: Transform
  }

isEdgeVisible :: forall n. IsEdgeVisibleParams n -> Boolean
isEdgeVisible p =
  let
    Transform t = p.transform
    origin = mkNodeOrigin 0.0 0.0
    sourceBox = nodeToBox (Right p.sourceNode) origin
    targetBox = nodeToBox (Right p.targetNode) origin
    raw = getBoundsOfBoxes sourceBox targetBox
    edgeBox :: Box
    edgeBox =
      { x: raw.x
      , y: raw.y
      , x2: if raw.x == raw.x2 then raw.x2 + 1.0 else raw.x2
      , y2: if raw.y == raw.y2 then raw.y2 + 1.0 else raw.y2
      }
    viewRect :: Rect
    viewRect =
      { x: -t.tx / t.scale
      , y: -t.ty / t.scale
      , width: p.width / t.scale
      , height: p.height / t.scale
      }
  in
    getOverlappingArea viewRect (boxToRect edgeBox) > 0.0

type GetEdgeId = Connection -> String

-- | Default edge id derived from the connection's endpoints.
getEdgeId :: Connection -> String
getEdgeId c =
  "xy-edge__"
    <> unwrap c.source
    <> fromMaybe "" c.sourceHandle
    <> "-"
    <> unwrap c.target
    <> fromMaybe "" c.targetHandle

connectionExists :: forall e. EdgeBase e -> Array (EdgeBase e) -> Boolean
connectionExists edge edges = Array.any matches edges
  where
  matches el =
    el.source == edge.source
      && el.target == edge.target
      && handleMatches el.sourceHandle edge.sourceHandle
      && handleMatches el.targetHandle edge.targetHandle

  -- TS: `el.sourceHandle === edge.sourceHandle || (!el.sourceHandle &&
  -- !edge.sourceHandle)`. The second disjunct is why this is not plain `==`:
  -- a handle id of `""` is falsy, so upstream reads it as *no handle* and an
  -- edge carrying one is a duplicate of the same edge carrying none.
  handleMatches a b = a == b || (blank a && blank b)

  blank = case _ of
    Nothing -> true
    Just h -> h == ""

-- | TS returns the original array on bad input and emits a console warning.
-- | PS exposes the failure via `Either String`, so callers can choose to
-- | report or silently fall back via `fromRight`.
addEdge
  :: forall e
   . EdgeBase e
  -> Array (EdgeBase e)
  -> GetEdgeId
  -> Either String (Array (EdgeBase e))
addEdge edgeParams _ _
  | unwrap edgeParams.source == "" || unwrap edgeParams.target == "" =
      Left (errorMessage E006)
addEdge edgeParams edges _ =
  if connectionExists edgeParams edges then Right edges
  else Right (Array.snoc edges edgeParams)

reconnectEdge
  :: forall e
   . EdgeBase e
  -> Connection
  -> Array (EdgeBase e)
  -> Boolean
  -> GetEdgeId
  -> Either String (Array (EdgeBase e))
reconnectEdge oldEdge newConnection edges shouldReplaceId edgeIdGen =
  if unwrap newConnection.source == "" || unwrap newConnection.target == "" then
    Left (errorMessage E006)
  else case Array.filter (\e -> e.id == oldEdge.id) edges of
    [] -> Left (errorMessage (E007 oldEdge.id))
    _ ->
      let
        nextId =
          if shouldReplaceId then edgeIdGen newConnection
          else oldEdge.id
        edge = oldEdge
          { id = nextId
          , source = newConnection.source
          , target = newConnection.target
          , sourceHandle = newConnection.sourceHandle
          , targetHandle = newConnection.targetHandle
          }
        without = Array.filter (\e -> e.id /= oldEdge.id) edges
      in
        Right (Array.snoc without edge)
