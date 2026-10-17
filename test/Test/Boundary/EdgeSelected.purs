-- | What an edge's `selected` holds when nothing has selected it.
-- |
-- | The local proxy for the edge `selected` part of the map's "required
-- | Booleans where upstream's field is optional" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `selected` is an optional field that only a selection change
-- | sets: an edge the consumer wrote without it reads back without it, and an
-- | edge `addEdge` builds from a connection has none. Its readers treat
-- | absent as `false`, and `getSelectionChanges` skips an item whose
-- | `selected` is `undefined` and isn't becoming selected. ps-flow held a
-- | required `Boolean`, so every edge read back with `selected: false`.
module Test.Boundary.EdgeSelected
  ( runEdgeSelectedTests
  ) where

import Prelude

import Boundary.Elements (JsEdge, edgeIn, edgeOut)
import Boundary.Utils (addEdge)
import Data.Array (length) as Array
import Data.Function.Uncurried (runFn2)
import Data.Map as Map
import Data.Set as Set
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign, unsafeToForeign)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.Changes (getEdgeSelectionChanges)

foreign import plainEdge :: JsEdge
foreign import edgeUnselected :: JsEdge
foreign import connection :: Foreign
foreign import hasOwnKey :: forall a. String -> a -> Boolean
foreign import isFalseAt :: forall a. String -> a -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | How many selection changes selecting `selectedIds` makes, in a flow
-- | holding only `edge`.
selectionChanges :: JsEdge -> Array String -> Int
selectionChanges edge selectedIds =
  Array.length
    ( getEdgeSelectionChanges (Map.singleton "ab" (edgeIn edge)) (Set.fromFoldable selectedIds)
    ).changes

runEdgeSelectedTests :: Effect Unit
runEdgeSelectedTests = do
  log "\n=== Edges: selected stays unset until a selection change sets it ==="

  assert "an edge written without selected reads back without it"
    (not (hasOwnKey "selected" (edgeOut (edgeIn plainEdge))))
  assert "an edge written with selected: false reads back with it"
    (isFalseAt "selected" (edgeOut (edgeIn edgeUnselected)))
  assert "an edge addEdge builds from a connection has no selected"
    (map (hasOwnKey "selected") (runFn2 addEdge (unsafeToForeign connection) []) == [ false ])
  assert "an edge without selected that stays unselected makes no selection change, as upstream's guard has it"
    (selectionChanges plainEdge [] == 0)
  assert "an edge without selected that becomes selected makes one"
    (selectionChanges plainEdge [ "ab" ] == 1)
