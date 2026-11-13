-- | `ariaRole` and `domAttributes` on nodes and edges, as upstream's wrappers
-- | render them (upstream #5299 and #5317).
-- |
-- |   * `<NodeWrapper />` sets `role` to `node.ariaRole`, falling back to
-- |     `"group"` for a focusable node and to no attribute otherwise.
-- |   * `<EdgeWrapper />` sets `role` to `edge.ariaRole`, falling back to
-- |     `"group"` for a focusable edge and to `"img"` otherwise.
-- |   * Both spread `domAttributes` onto the element after every attribute
-- |     they set themselves, so its keys reach the element and win over the
-- |     wrapper's own `aria-roledescription`.
-- |
-- | Each wrapper renders inside a real store, and a server render reads its
-- | attributes. `parity/boundary/edge-fields.test.mjs` compares the same
-- | members with upstream's server render through `index.js`.
module Test.React.Component.AriaRoleDomAttributes
  ( runAriaRoleDomAttributesTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (element)
import React.Component.EdgeWrapper (edgeWrapper)
import React.Component.NodeWrapper (nodeWrapper)
import System.Types.Edge (EdgeBase)
import System.Types.Node (NodeBase)
import System.Types.Opaque (opaque)
import Test.React.Component.WrapperFixture (edgeAB, edgeProps, has, nodeA, nodeProps, renderInStore)

-- | `{ "data-kind": "n", title: "node", "aria-roledescription": "card" }`.
foreign import nodeAttributes :: Foreign

-- | `{ "data-kind": "x", title: "edge", "aria-roledescription": "link" }`.
foreign import edgeAttributes :: Foreign

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

renderNode :: { focusable :: Boolean } -> NodeBase Unit -> Effect String
renderNode { focusable } node =
  renderInStore { a: node, ab: edgeAB } (element nodeWrapper nodeProps { nodesFocusable = focusable })

renderEdge :: { focusable :: Boolean } -> EdgeBase Unit -> Effect String
renderEdge { focusable } edge =
  renderInStore { a: nodeA, ab: edge } (element edgeWrapper edgeProps { edgesFocusable = focusable })

runAriaRoleDomAttributesTests :: Effect Unit
runAriaRoleDomAttributesTests = do
  log "-- ariaRole and domAttributes on the node and edge wrappers --"

  nodeRole <- renderNode { focusable: true } nodeA { ariaRole = Just "listitem" }
  assert "a node's ariaRole is its role" (has "role=\"listitem\"" nodeRole)

  focusableNode <- renderNode { focusable: true } nodeA
  assert "a focusable node without ariaRole is a group" (has "role=\"group\"" focusableNode)

  unfocusableNode <- renderNode { focusable: true } nodeA { focusable = Just false }
  assert "a node that cannot take focus has no role, and no tabindex"
    (not (has "role=" unfocusableNode) && not (has "tabindex=" unfocusableNode))

  unfocusableRole <- renderNode { focusable: false } nodeA { ariaRole = Just "img" }
  assert "… unless it has an ariaRole" (has "role=\"img\"" unfocusableRole)

  nodeAttrs <- renderNode { focusable: true } nodeA { domAttributes = Just (opaque nodeAttributes) }
  assert "a node's domAttributes reach its element"
    (has "data-kind=\"n\"" nodeAttrs && has "title=\"node\"" nodeAttrs)
  assert "… after the wrapper's own attributes, so they win"
    (has "aria-roledescription=\"card\"" nodeAttrs && not (has "aria-roledescription=\"node\"" nodeAttrs))

  edgeRole <- renderEdge { focusable: true } edgeAB { ariaRole = Just "button" }
  assert "an edge's ariaRole is its role" (has "role=\"button\"" edgeRole)

  focusableEdge <- renderEdge { focusable: true } edgeAB
  assert "a focusable edge without ariaRole is a group" (has "role=\"group\"" focusableEdge)

  unfocusableEdge <- renderEdge { focusable: false } edgeAB
  assert "an edge that cannot take focus is an img" (has "role=\"img\"" unfocusableEdge)

  edgeAttrs <- renderEdge { focusable: true } edgeAB { domAttributes = Just (opaque edgeAttributes) }
  assert "an edge's domAttributes reach its element"
    (has "data-kind=\"x\"" edgeAttrs && has "title=\"edge\"" edgeAttrs)
  assert "… after the wrapper's own attributes, so they win"
    (has "aria-roledescription=\"link\"" edgeAttrs && not (has "aria-roledescription=\"edge\"" edgeAttrs))
