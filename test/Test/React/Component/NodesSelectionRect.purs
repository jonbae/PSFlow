-- | What `<NodesSelection />` renders around the selected nodes.
-- |
-- | The local proxy for the report's `shift-drag-selects-nodes` and
-- | `selection-box-touch` scenarios, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's rectangle takes `style={{ width, height }}`
-- | with numbers, which React writes in pixels. ps-flow passed strings with
-- | no unit, such as `"350"`, which the browser drops as invalid CSS, so its
-- | rectangle had no size.
-- |
-- | The test also checks the rectangle's other two differences from
-- | upstream, which no scenario reaches:
-- |
-- | - Upstream renders whenever the bounds are numbers. An empty
-- |   selection's bounds are 0 by 0, so it renders a rectangle of no size.
-- |   ps-flow also required a size above 0.
-- | - Upstream's `tabIndex` is `undefined` under `disableKeyboardA11y`.
-- |   ps-flow's was 0.
-- |
-- | `spago test` has no DOM, so the markup is a server render, compared
-- | whole.
module Test.React.Component.NodesSelectionRect
  ( runNodesSelectionRectTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (JSX, element)
import React.Component.NodesSelection (nodesSelection)
import React.Context.Store (OpaqueStore, storeProvider)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Nodes (Node)
import System.Types.Geometry (XYPosition)
import System.Types.Ids (NodeId(..))
import Unsafe.Coerce (unsafeCoerce)

foreign import renderMarkup :: JSX -> Effect String

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

storeToOpaque :: Store Unit Unit -> OpaqueStore
storeToOpaque = unsafeCoerce

node :: String -> XYPosition -> Boolean -> Node Unit
node id position selected =
  { id: NodeId id
  , position
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: if selected then Just true else Nothing
  , dragging: Nothing
  , draggable: Nothing
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Nothing
  , height: Nothing
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: Nothing
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Just 150.0, height: Just 40.0 }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | Two 150 by 40 nodes, at (0, 0) and (200, 97): 350 by 137 together.
nodes :: Boolean -> Array (Node Unit)
nodes selected =
  [ node "a" { x: 0.0, y: 0.0 } selected
  , node "b" { x: 200.0, y: 97.0 } selected
  ]

-- | `<NodesSelection />` over `ns`, as `renderToStaticMarkup` writes it.
rendered :: { disableKeyboardA11y :: Boolean, userSelectionActive :: Boolean } -> Array (Node Unit) -> Effect String
rendered o ns = do
  store <- createStore ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just ns })
  store.setState _ { userSelectionActive = o.userSelectionActive }
  renderMarkup
    ( storeProvider (Just (storeToOpaque store))
        [ element nodesSelection
            { onSelectionContextMenu: Nothing
            , noPanClassName: Just "nopan"
            , disableKeyboardA11y: o.disableKeyboardA11y
            }
        ]
    )

-- | Upstream's markup for a rectangle with `attrs` before its style, of
-- | `size`, at the bounds' origin, (0, 0).
upstreamMarkup :: String -> String -> String
upstreamMarkup attrs size =
  "<div class=\"react-flow__nodesselection react-flow__container nopan\""
    <> " style=\"transform:translate(0px,0px) scale(1) translate(0px,0px)\">"
    <> "<div class=\"react-flow__nodesselection-rect\""
    <> attrs
    <> " style=\""
    <> size
    <> "\"></div></div>"

runNodesSelectionRectTests :: Effect Unit
runNodesSelectionRectTests = do
  log "\n=== NodesSelection: the rectangle around the selected nodes ==="

  selected <- rendered { disableKeyboardA11y: false, userSelectionActive: false } (nodes true)
  assert "the rectangle takes the selected nodes' bounds in pixels"
    (selected == upstreamMarkup " tabindex=\"-1\"" "width:350px;height:137px")

  empty <- rendered { disableKeyboardA11y: false, userSelectionActive: false } (nodes false)
  assert "with nothing selected, the rectangle renders with no size, at the origin"
    (empty == upstreamMarkup " tabindex=\"-1\"" "width:0;height:0")

  noA11y <- rendered { disableKeyboardA11y: true, userSelectionActive: false } (nodes true)
  assert "under disableKeyboardA11y, the rectangle has no tabindex"
    (noA11y == upstreamMarkup "" "width:350px;height:137px")

  lasso <- rendered { disableKeyboardA11y: false, userSelectionActive: true } (nodes true)
  assert "while a selection box is active, nothing renders"
    (lasso == "")
