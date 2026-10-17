-- | The inline `width` and `height` a node wrapper spreads over `node.style`.
-- |
-- | The local proxy for `getNodeInlineStyleDimensions` on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | which drives `drag-child-expand-parent` apart at mount. Upstream renders
-- | `{ ...node.style, ...inlineDimensions }`, and `inlineDimensions` falls
-- | back to `node.style?.width` and `node.style?.height` last, so a node sized
-- | only through `style` keeps that size. ps-flow's left the fallback out and
-- | wrote an empty `width` and `height` over the style's, so the parent in
-- | that scenario measured 150 by 37 instead of 320 by 220, and its
-- | `expandParent` child grew it at once.
module Test.React.Component.NodeInlineDimensions
  ( runNodeInlineDimensionsTests
  ) where

import Prelude

import Boundary.Elements (JsNode, nodeIn)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign, unsafeToForeign)
import Partial.Unsafe (unsafeCrashWith)
import React.Component.NodeWrapper.Util (getNodeInlineStyleDimensions)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeBase)

foreign import styledNode :: JsNode
foreign import cssStyledNode :: JsNode
foreign import sizedStyledNode :: JsNode
foreign import initialSizedStyledNode :: JsNode
foreign import plainNode :: JsNode
foreign import is :: Foreign -> Foreign -> Boolean
foreign import nullForeign :: Foreign

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

internalOf :: JsNode -> InternalNodeBase Foreign
internalOf node =
  let
    state = initialState
      ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign) { nodes = Just [ nodeIn node ] })
  in
    case Map.lookup (NodeId "a") state.nodeLookup of
      Just internal -> internal
      Nothing -> unsafeCrashWith "the node didn't adopt"

-- | The same node after its handles are measured, when upstream stops
-- | reading `initialWidth` and `initialHeight`.
measured :: InternalNodeBase Foreign -> InternalNodeBase Foreign
measured internal =
  internal { internals = internal.internals { handleBounds = Just { source: [], target: [] } } }

dimensionsAre :: Foreign -> Foreign -> InternalNodeBase Foreign -> Boolean
dimensionsAre width height internal =
  let
    dims = getNodeInlineStyleDimensions internal
  in
    is width dims.width && is height dims.height

runNodeInlineDimensionsTests :: Effect Unit
runNodeInlineDimensionsTests = do
  log "\n=== NodeWrapper: inline dimensions fall back to the node's style ==="

  let
    num = unsafeToForeign :: Number -> Foreign
    str = unsafeToForeign :: String -> Foreign

  assert "a node sized only through style keeps the style's width and height"
    (dimensionsAre (num 320.0) (num 220.0) (internalOf styledNode))
  assert "a style's CSS strings cross as the consumer wrote them"
    (dimensionsAre (str "100%") (str "4rem") (internalOf cssStyledNode))
  assert "a node's own width and height win over its style's"
    (dimensionsAre (num 50.0) (num 30.0) (internalOf sizedStyledNode))
  assert "before measurement, initialWidth and initialHeight win over the style's"
    (dimensionsAre (num 10.0) (num 12.0) (internalOf initialSizedStyledNode))
  assert "after measurement, the style's width and height apply again"
    (dimensionsAre (num 320.0) (num 220.0) (measured (internalOf initialSizedStyledNode)))
  assert "a node with neither has an empty width and height"
    (dimensionsAre nullForeign nullForeign (internalOf plainNode))
