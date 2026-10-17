-- | What an edge's `hidden` holds when the consumer doesn't set it.
-- |
-- | The local proxy for the edge `hidden` part of the map's "required
-- | Booleans where upstream's field is optional" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `hidden` is an optional field that nothing fills in: an edge
-- | the consumer wrote without it reads back without it, an edge `addEdge`
-- | builds from a connection has none, and `EdgeWrapper`'s
-- | `{ ...defaultEdgeOptions, ...edge }` lets an edge's own `false` override
-- | the default. ps-flow held a required `Boolean`, so every edge read back
-- | with `hidden: false`, and a default of `true` overrode an edge's own
-- | `false`.
module Test.Boundary.EdgeHidden
  ( runEdgeHiddenTests
  ) where

import Prelude

import Boundary.Elements (JsEdge, edgeIn, edgeOut)
import Boundary.Utils (addEdge)
import Data.Function.Uncurried (runFn2)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign, unsafeToForeign)
import Partial.Unsafe (unsafeCrashWith)
import React.Component.EdgeWrapper (applyDefaults)
import React.Types.Edges (DefaultEdgeOptions)

foreign import plainEdge :: JsEdge
foreign import edgeShown :: JsEdge
foreign import connection :: Foreign
foreign import hasOwnKey :: forall a. String -> a -> Boolean
foreign import isFalseAt :: forall a. String -> a -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | `defaultEdgeOptions` that set only `hidden: true`.
hiddenByDefault :: DefaultEdgeOptions Foreign
hiddenByDefault =
  { animated: Nothing
  , hidden: Just true
  , deletable: Nothing
  , selectable: Nothing
  , focusable: Nothing
  , data: Nothing
  , zIndex: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , reconnectable: Nothing
  }

runEdgeHiddenTests :: Effect Unit
runEdgeHiddenTests = do
  log "\n=== Edges: hidden stays unset until something sets it ==="

  assert "an edge written without hidden reads back without it"
    (not (hasOwnKey "hidden" (edgeOut (edgeIn plainEdge))))
  assert "an edge written with hidden: false reads back with it"
    (isFalseAt "hidden" (edgeOut (edgeIn edgeShown)))
  assert "an edge addEdge builds from a connection has no hidden"
    (map (hasOwnKey "hidden") (runFn2 addEdge (unsafeToForeign connection) []) == [ false ])
  assert "defaultEdgeOptions' hidden fills an edge that doesn't set it"
    ((applyDefaults (Just hiddenByDefault) (edgeIn plainEdge)).hidden == Just true)
  assert "an edge's own hidden: false overrides defaultEdgeOptions' true, as upstream's spread does"
    ((applyDefaults (Just hiddenByDefault) (edgeIn edgeShown)).hidden == Just false)
