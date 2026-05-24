-- | `useHandleConnections` — observe the set of connections attached to
-- | a specific handle on a node. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useHandleConnections.ts`.
-- |
-- | **Deprecated upstream.** Upstream marks this hook as deprecated in
-- | favour of `useNodeConnections`. We port it for API parity but new
-- | consumers should prefer `React.Hook.NodeConnections.useNodeConnections`.
-- |
-- | **Key construction.** Mirrors upstream — when `id` is `Nothing` the
-- | lookup key is `"${nodeId}-${handleType}"`; when `Just h` it is
-- | `"${nodeId}-${handleType}-${h}"`. The default `nodeId` falls back to
-- | the surrounding `NodeIdContext` so the hook is usable from a
-- | custom-node component without explicit prop drilling.
-- |
-- | **`onConnect` / `onDisconnect` callbacks** are fired in a
-- | `useEffect` whose dep is the current connection array (compared by
-- | structural `Eq`). Each render diffs the previous and current sets
-- | and invokes the appropriate callback with the newly-added / -removed
-- | connections.
module React.Hook.HandleConnections
  ( UseHandleConnectionsParams
  , UseHandleConnectionsHook(..)
  , useHandleConnections
  , handleLookupKey
  ) where

import Prelude

import Control.Alt ((<|>))
import Data.Array (any, filter, fromFoldable, null) as Array
import Data.Foldable (for_)
import Data.Map (lookup) as Map
import Data.Map.Internal (values) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (class Newtype)
import Effect (Effect)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseContext, UseEffect, UseRef, coerceHook, readRef, useEffect, useRef, writeRef)
import React.Basic.Hooks as React
import React.Context.NodeId (useNodeId)
import React.Hook.Store (UseStore, useStore)
import System.Types.Connection (Connection, HandleConnection)
import System.Types.Handle (HandleType(..))

-- | Inputs to the hook. Matches TS `UseHandleConnectionsParams` field
-- | for field except that the deprecated `id` (handle id) sits as the
-- | optional `id` field.
type UseHandleConnectionsParams =
  { handleType :: HandleType
  , id :: Maybe String
  , nodeId :: Maybe String
  , onConnect :: Maybe (Array Connection -> Effect Unit)
  , onDisconnect :: Maybe (Array Connection -> Effect Unit)
  }

newtype UseHandleConnectionsHook hooks =
  UseHandleConnectionsHook
    ( UseEffect (UnsafeReference (Array HandleConnection))
        ( UseRef (Array HandleConnection)
            ( UseStore (Array HandleConnection)
                ( UseContext (Maybe String) hooks )
            )
        )
    )

derive instance newtypeUseHandleConnectionsHook ::
  Newtype (UseHandleConnectionsHook hooks) _

-- | Build the lookup key. Public for testing.
handleLookupKey :: String -> HandleType -> Maybe String -> String
handleLookupKey nodeId hType mHandleId =
  nodeId
    <> "-"
    <> handleTypeName hType
    <> case mHandleId of
      Just h -> "-" <> h
      Nothing -> ""

handleTypeName :: HandleType -> String
handleTypeName Source = "source"
handleTypeName Target = "target"

useHandleConnections
  :: UseHandleConnectionsParams
  -> Hook UseHandleConnectionsHook (Array HandleConnection)
useHandleConnections params = coerceHook React.do
  -- Fall back to the surrounding NodeIdContext when no explicit nodeId
  -- is supplied. If both are missing we use the empty string — the
  -- selector will then look up a key that cannot exist, returning [].
  mContextId <- useNodeId
  let
    currentNodeId = fromMaybe "" (params.nodeId <|> mContextId)
    key = handleLookupKey currentNodeId params.handleType params.id

  connections <- useStore \s ->
    case Map.lookup key s.connectionLookup of
      Nothing -> [] :: Array HandleConnection
      Just inner -> Array.fromFoldable (Map.values inner)

  -- Track the previous connection set so we can compute diffs for the
  -- onConnect / onDisconnect callbacks.
  prevRef <- useRef ([] :: Array HandleConnection)

  useEffect (UnsafeReference connections) do
    prev <- readRef prevRef
    let
      droppedConns = Array.filter (notIn connections) prev
      addedConns = Array.filter (notIn prev) connections
    when (not (Array.null droppedConns)) do
      for_ params.onDisconnect \cb -> cb (map toConnection droppedConns)
    when (not (Array.null addedConns)) do
      for_ params.onConnect \cb -> cb (map toConnection addedConns)
    writeRef prevRef connections
    pure (pure unit)

  pure connections

-- | Strip the `edgeId` field to project a `HandleConnection` to a plain
-- | `Connection`. Used when invoking the user's callback.
toConnection :: HandleConnection -> Connection
toConnection c =
  { source: c.source
  , target: c.target
  , sourceHandle: c.sourceHandle
  , targetHandle: c.targetHandle
  }

-- | Predicate: `x` is *not* present in `xs` (by structural equality on
-- | the `HandleConnection` record).
notIn :: Array HandleConnection -> HandleConnection -> Boolean
notIn xs x = not (Array.any (eq x) xs)

