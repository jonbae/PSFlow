-- | Which component draws a node or an edge whose type the consumer's
-- | `nodeTypes` or `edgeTypes` cannot resolve.
-- |
-- | Upstream's wrappers report the error and fall back to
-- | `nodeTypes?.['default'] || builtinNodeTypes.default` and
-- | `edgeTypes?.['default'] || builtinEdgeTypes.default`, so a consumer's own
-- | `default` type wins over the built-in one. For nodes that is upstream
-- | #5384, and #5735 relies on it. Each wrapper renders inside a real store,
-- | and a server render shows which component drew it.
-- | `parity/boundary/type-fallback.test.mjs` holds the same cases against
-- | upstream through `index.js`.
module Test.React.Component.TypeFallback
  ( runTypeFallbackTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (JSX, element)
import React.Component.EdgeWrapper (edgeWrapper)
import React.Component.NodeWrapper (nodeWrapper)
import React.Types.Edges (EdgeTypesMap)
import React.Types.Nodes (NodeTypesMap)
import System.Types.Node (OnError)
import Test.React.Component.WrapperFixture (edgeAB, edgeProps, has, nodeA, nodeProps, renderInStore)

-- | `{ default }`: a component drawing `<div class="custom-default">`.
foreign import nodeTypesWithDefault :: NodeTypesMap

-- | `{ default }`: a component drawing `<path class="custom-default-edge">`.
foreign import edgeTypesWithDefault :: EdgeTypesMap

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | What one wrapper renders, and the error codes it reported, when node `a`
-- | has `nodeType` and edge `ab` has `edgeType`.
type Rendered = { markup :: String, errors :: Array String }

renderWith
  :: { nodeType :: Maybe String, edgeType :: Maybe String }
  -> (OnError -> JSX)
  -> Effect Rendered
renderWith types wrapper = do
  codes <- Ref.new []
  let onError code _ = Ref.modify_ (_ <> [ code ]) codes
  markup <- renderInStore
    { a: nodeA { nodeType = types.nodeType }, ab: edgeAB { edgeType = types.edgeType } }
    (wrapper onError)
  errors <- Ref.read codes
  pure { markup, errors }

renderNode :: Maybe String -> Maybe NodeTypesMap -> Effect Rendered
renderNode nodeType nodeTypes =
  renderWith { nodeType, edgeType: Nothing } \onError ->
    element nodeWrapper nodeProps { nodeTypes = nodeTypes, onError = Just onError }

renderEdge :: Maybe String -> Maybe EdgeTypesMap -> Effect Rendered
renderEdge edgeType edgeTypes =
  renderWith { nodeType: Nothing, edgeType } \onError ->
    element edgeWrapper edgeProps { edgeTypes = edgeTypes, onError = Just onError }

runTypeFallbackTests :: Effect Unit
runTypeFallbackTests = do
  log "-- type fallback: an unresolved type draws the consumer's default --"

  unknownNode <- renderNode (Just "unknown") (Just nodeTypesWithDefault)
  assert "an unknown node type draws the consumer's default node type"
    (has "custom-default" unknownNode.markup)
  assert "… under the default type's class, as upstream's does"
    (has "react-flow__node-default" unknownNode.markup)
  assert "… and reports error 003" (unknownNode.errors == [ "003" ])

  untypedNode <- renderNode Nothing (Just nodeTypesWithDefault)
  assert "a node with no type draws the consumer's default node type, with no error"
    (has "custom-default" untypedNode.markup && untypedNode.errors == [])

  builtinNode <- renderNode (Just "unknown") Nothing
  assert "an unknown node type without a consumer default draws the built-in one"
    ( not (has "custom-default" builtinNode.markup)
        && has "react-flow__handle" builtinNode.markup
        && builtinNode.errors == [ "003" ]
    )

  unknownEdge <- renderEdge (Just "unknown") (Just edgeTypesWithDefault)
  assert "an unknown edge type draws the consumer's default edge type"
    (has "custom-default-edge" unknownEdge.markup)
  assert "… under the default type's class, as upstream's does"
    (has "react-flow__edge-default" unknownEdge.markup)
  assert "… and reports error 011" (unknownEdge.errors == [ "011" ])

  builtinEdge <- renderEdge (Just "unknown") Nothing
  assert "an unknown edge type without a consumer default draws the built-in one"
    ( not (has "custom-default-edge" builtinEdge.markup)
        && has "react-flow__edge-path" builtinEdge.markup
        && builtinEdge.errors == [ "011" ]
    )
