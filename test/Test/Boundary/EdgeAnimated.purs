-- | What an edge's `animated` holds when the consumer doesn't set it.
-- |
-- | The local proxy for the `animated` part of the map's "required Booleans
-- | where upstream's field is optional" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `animated` is an optional field that nothing fills in: an edge
-- | the consumer wrote without it reads back without it, an edge `addEdge`
-- | builds from a connection has none, and `EdgeWrapper`'s
-- | `{ ...defaultEdgeOptions, ...edge }` lets an edge's own `false` override
-- | the default. ps-flow held a required `Boolean`, so every edge read back
-- | with `animated: false`, and a default of `true` overrode an edge's own
-- | `false`.
module Test.Boundary.EdgeAnimated
  ( runEdgeAnimatedTests
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
foreign import edgeNotAnimated :: JsEdge
foreign import connection :: Foreign
foreign import hasOwnKey :: forall a. String -> a -> Boolean
foreign import isFalseAt :: forall a. String -> a -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | `defaultEdgeOptions` that set only `animated: true`.
animatedByDefault :: DefaultEdgeOptions Foreign
animatedByDefault =
  { animated: Just true
  , hidden: Nothing
  , deletable: Nothing
  , selectable: Nothing
  , focusable: Nothing
  , data: Nothing
  , zIndex: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , reconnectable: Nothing
  }

runEdgeAnimatedTests :: Effect Unit
runEdgeAnimatedTests = do
  log "\n=== Edges: animated stays unset until something sets it ==="

  assert "an edge written without animated reads back without it"
    (not (hasOwnKey "animated" (edgeOut (edgeIn plainEdge))))
  assert "an edge written with animated: false reads back with it"
    (isFalseAt "animated" (edgeOut (edgeIn edgeNotAnimated)))
  assert "an edge addEdge builds from a connection has no animated"
    (map (hasOwnKey "animated") (runFn2 addEdge (unsafeToForeign connection) []) == [ false ])
  assert "defaultEdgeOptions' animated fills an edge that doesn't set it"
    ((applyDefaults (Just animatedByDefault) (edgeIn plainEdge)).animated == Just true)
  assert "an edge's own animated: false overrides defaultEdgeOptions' true, as upstream's spread does"
    ((applyDefaults (Just animatedByDefault) (edgeIn edgeNotAnimated)).animated == Just false)
