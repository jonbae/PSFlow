-- | What a handle's `id` holds when the handle has none.
-- |
-- | The local proxy for a handle's `id` on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream types a handle's `id` as `string | null` and leaves it optional.
-- | `getHandleBounds` reads it with `getAttribute('data-handleid')`, so a
-- | measured handle without one has `null`. `parseHandles` copies a
-- | `node.handles` entry's `id` as the consumer wrote it, so an entry without
-- | one has `undefined`, and an entry with `null` keeps it. ps-flow held a
-- | `Maybe String` and wrote `Nothing` as `undefined` everywhere, so every
-- | measured handle without an id crossed as `undefined`.
module Test.Boundary.HandleIdNull
  ( runHandleIdNullTests
  ) where

import Prelude

import Boundary.Elements (JsHandle, JsNode, handleOut, internalNodeOut, nodeIn, nodeOut)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import System.Types.Handle (HandleType(..))
import System.Types.Ids (NodeId(..))
import System.Utils.Dom (getHandleBounds)
import Web.HTML.HTMLDivElement (HTMLDivElement)

foreign import nodeElementWithoutHandleId :: HTMLDivElement
foreign import nodeElementWithHandleId :: HTMLDivElement
foreign import nodeWithHandles :: JsNode
foreign import handleIds :: Array JsHandle -> Array String
foreign import nodeHandleIds :: JsNode -> Array String
foreign import internalHandleIds :: forall a. a -> Array String

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

measuredIds :: HTMLDivElement -> Effect (Maybe (Array String))
measuredIds el = do
  handles <- getHandleBounds Source el { left: 0.0, top: 0.0, width: 50.0, height: 25.0 } 1.0 (NodeId "a")
  pure (map (handleIds <<< map handleOut) handles)

runHandleIdNullTests :: Effect Unit
runHandleIdNullTests = do
  log "\n=== Handles: an id-less handle's id is null when measured, and as written otherwise ==="

  withoutId <- measuredIds nodeElementWithoutHandleId
  assert "a handle measured without data-handleid has a null id"
    (withoutId == Just [ "null" ])
  withId <- measuredIds nodeElementWithHandleId
  assert "a handle measured with data-handleid has that id"
    (withId == Just [ "id out" ])

  assert "node.handles entries read back with the ids the consumer wrote"
    (nodeHandleIds (nodeOut (nodeIn nodeWithHandles)) == [ "undefined", "null", "id in" ])

  let
    state = initialState
      ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign) { nodes = Just [ nodeIn nodeWithHandles ] })
  assert "the internal node's handle bounds keep those ids, as parseHandles does"
    (map (internalHandleIds <<< internalNodeOut) (Map.lookup (NodeId "a") state.nodeLookup)
      == Just [ "undefined", "null", "id in" ])
