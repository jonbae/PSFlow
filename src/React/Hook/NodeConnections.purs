-- | `useNodeConnections` — observe the connections attached to a node,
-- | optionally narrowed to a specific handle type and/or handle id.
-- | Mirrors `xyflow-main/packages/react/src/hooks/useNodeConnections.ts`.
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
import Data.Array (any, filter, fromFoldable, null) as Array
import Data.Foldable (for_)
import Data.Map (lookup) as Map
import Data.Map.Internal (values) as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Ref as Ref
import React.Basic (Ref)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseContext, UseEffect, UseRef, coerceHook, useEffect, useRef)
import React.Basic.Hooks as React
import React.Context.NodeId (useNodeId)
import React.Hook.Store (UseStore, useStore)
import System.Constants (ErrorCode(..), errorMessage)
import System.Types.Connection (NodeConnection)
import System.Types.Handle (HandleType(..))
import Unsafe.Coerce (unsafeCoerce)

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
        ( UseRef (Array NodeConnection)
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
      Just inner -> Array.fromFoldable (Map.values inner)

  prevRef <- useRef ([] :: Array NodeConnection)

  useEffect (UnsafeReference connections) do
    prev <- Ref.read (toEffectRef prevRef)
    let
      droppedConns = Array.filter (notIn connections) prev
      addedConns = Array.filter (notIn prev) connections
    when (not (Array.null droppedConns)) do
      for_ params.onDisconnect \cb -> cb droppedConns
    when (not (Array.null addedConns)) do
      for_ params.onConnect \cb -> cb addedConns
    Ref.write connections (toEffectRef prevRef)
    pure (pure unit)

  pure connections

notIn :: Array NodeConnection -> NodeConnection -> Boolean
notIn xs x = not (Array.any (eq x) xs)

toEffectRef :: forall a. Ref a -> Ref.Ref a
toEffectRef = unsafeCoerce
