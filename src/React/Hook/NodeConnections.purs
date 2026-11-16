-- | `useNodeConnections` — observe the connections attached to a node,
-- | optionally narrowed to a specific handle type and/or handle id.
-- | Mirrors `xyflow/packages/react/src/hooks/useNodeConnections.ts`.
-- |
-- | **Key construction** mirrors upstream:
-- |
-- |   * `handleType = Nothing`                                → `nodeId`
-- |   * `handleType = Just t, handleId = Nothing`             → `"${nodeId}-${t}"`
-- |   * `handleType = Just t, handleId = Just h`              → `"${nodeId}-${t}-${h}"`
-- |
-- | The default `nodeId` falls back to the surrounding
-- | `NodeIdContext`. When neither is available the hook throws the
-- | upstream `errorMessage E014`.
-- |
-- | **`onConnect` / `onDisconnect` callbacks** fire with the
-- | newly-added / -removed connections on every render where the
-- | connection set changes (compared by structural `Eq`).
module React.Hook.NodeConnections
  ( UseNodeConnectionsParams
  , UseNodeConnectionsHook(..)
  , useNodeConnections
  , nodeLookupKey
  ) where

import Prelude

import Control.Alt ((<|>))
import Data.Array (any, filter, null) as Array
import Data.Foldable (for_)
import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.Exception.Unsafe (unsafeThrow)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseContext, UseEffect, UseRef, coerceHook, readRef, useEffect, useRef, writeRef)
import React.Basic.Hooks as React
import React.Context.NodeId (useNodeId)
import React.Hook.Store (UseStore, useStore)
import System.Constants (ErrorCode(..), errorMessage)
import System.Types.Connection (NodeConnection)
import System.Types.Handle (HandleType(..))
import System.Utils.Store (handleConnectionsInOrder)

-- | Inputs. The optional `nodeId` (TS `id`) is renamed to clarify which
-- | id this refers to.
type UseNodeConnectionsParams =
  { nodeId :: Maybe String
  , handleType :: Maybe HandleType
  , handleId :: Maybe String
  , onConnect :: Maybe (Array NodeConnection -> Effect Unit)
  , onDisconnect :: Maybe (Array NodeConnection -> Effect Unit)
  }

newtype UseNodeConnectionsHook hooks =
  UseNodeConnectionsHook
    ( UseEffect (UnsafeReference (Array NodeConnection))
        ( UseRef (Maybe (Array NodeConnection))
            ( UseStore (Array NodeConnection)
                ( UseContext (Maybe String) hooks )
            )
        )
    )

derive instance newtypeUseNodeConnectionsHook ::
  Newtype (UseNodeConnectionsHook hooks) _

-- | Build the lookup key. Public for testing.
nodeLookupKey :: String -> Maybe HandleType -> Maybe String -> String
nodeLookupKey nodeId mType mHandleId = case mType of
  Nothing -> nodeId
  Just t -> nodeId <> "-" <> handleTypeName t <> case mHandleId of
    Just h -> "-" <> h
    Nothing -> ""

handleTypeName :: HandleType -> String
handleTypeName Source = "source"
handleTypeName Target = "target"

useNodeConnections
  :: UseNodeConnectionsParams
  -> Hook UseNodeConnectionsHook (Array NodeConnection)
useNodeConnections params = coerceHook React.do
  mContextId <- useNodeId
  let
    currentNodeId = case params.nodeId <|> mContextId of
      Just id -> id
      Nothing -> unsafeThrow (errorMessage E014)
    key = nodeLookupKey currentNodeId params.handleType params.handleId

  connections <- useStore \s ->
    case Map.lookup key s.connectionLookup of
      Nothing -> [] :: Array NodeConnection
      Just inner -> handleConnectionsInOrder inner

  -- TS holds the previous connections in a ref that starts `null`, and the
  -- first effect only fills it: neither handler runs at mount.
  prevRef <- useRef (Nothing :: Maybe (Array NodeConnection))

  useEffect (UnsafeReference connections) do
    readRef prevRef >>= case _ of
      Nothing -> pure unit
      Just prev -> do
        let
          droppedConns = Array.filter (notIn connections) prev
          addedConns = Array.filter (notIn prev) connections
        when (not (Array.null droppedConns)) do
          for_ params.onDisconnect \cb -> cb droppedConns
        when (not (Array.null addedConns)) do
          for_ params.onConnect \cb -> cb addedConns
    writeRef prevRef (Just connections)
    pure (pure unit)

  pure connections

-- | Whether `x` is missing from `xs`, compared as upstream's lookup keys its
-- | connections: by their two ends and handles, not by edge.
notIn :: Array NodeConnection -> NodeConnection -> Boolean
notIn xs x = not (Array.any (sameEnds x) xs)
  where
  sameEnds a b =
    a.source == b.source && a.sourceHandle == b.sourceHandle
      && a.target == b.target
      && a.targetHandle == b.targetHandle

