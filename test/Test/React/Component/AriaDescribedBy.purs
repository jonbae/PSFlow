-- | The `aria-describedby` that ties each node and edge to its hidden
-- | description.
-- |
-- | The local proxy for the map's "`aria-describedby` never emitted on nodes
-- | or edges" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | `<A11yDescriptions />` renders `react-flow__node-desc-<rfId>` and
-- | `react-flow__edge-desc-<rfId>`, and upstream's wrappers point at them:
-- |
-- |   * `<NodeWrapper />` sets it unless `disableKeyboardA11y`, whether or
-- |     not the node is focusable;
-- |   * `<EdgeWrapper />` sets it when the edge is focusable, whether or not
-- |     keyboard a11y is off.
-- |
-- | The two conditions differ, so each wrapper is checked against the other's
-- | condition too: a port that gave both the same one fails a check here.
-- | Each wrapper renders inside a real store, and a server render reads its
-- | attributes.
module Test.React.Component.AriaDescribedBy
  ( runAriaDescribedByTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), contains)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (JSX, element)
import React.Component.EdgeWrapper (edgeWrapper)
import React.Component.NodeWrapper (nodeWrapper)
import React.Context.Store (OpaqueStore, storeProvider)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Edges (EdgeWrapperProps)
import React.Types.Nodes (NodeWrapperProps)
import System.Types.Edge (EdgeBase)
import System.Types.Geometry (Position(..), XYPosition)
import System.Types.Handle (HandleType(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeBase, NodeHandle)
import Unsafe.Coerce (unsafeCoerce)

foreign import renderMarkup :: JSX -> Effect String

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A 50 × 25 node at `at`, carrying its handles so the store seeds their
-- | bounds without a DOM, as upstream's server rendering does.
nodeAt :: String -> XYPosition -> Array NodeHandle -> NodeBase Unit
nodeAt id at handles =
  { id: NodeId id
  , position: at
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: Nothing
  , dragging: Nothing
  , draggable: Nothing
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Just 50.0
  , height: Just 25.0
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: Nothing
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Just handles
  , measured: { width: Just 50.0, height: Just 25.0 }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

handleAt :: HandleType -> Position -> Number -> NodeHandle
handleAt handleType position y =
  { id: Nothing, x: 24.0, y, position, handleType, width: Just 2.0, height: Just 2.0 }

edgeAB :: EdgeBase Unit
edgeAB =
  { id: "ab"
  , edgeType: Nothing
  , source: NodeId "a"
  , target: NodeId "b"
  , sourceHandle: Nothing
  , targetHandle: Nothing
  , animated: Nothing
  , hidden: Nothing
  , deletable: Nothing
  , selectable: Nothing
  , data: Nothing
  , selected: Nothing
  , markerStart: Nothing
  , markerEnd: Nothing
  , zIndex: Nothing
  , label: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
  }

type A11y = { focusable :: Boolean, keyboardA11yOff :: Boolean }

nodeProps :: A11y -> NodeWrapperProps Unit
nodeProps a11y =
  { id: "a"
  , nodesConnectable: true
  , elementsSelectable: true
  , nodesDraggable: true
  , nodesFocusable: a11y.focusable
  , onClick: Nothing
  , onDoubleClick: Nothing
  , onMouseEnter: Nothing
  , onMouseMove: Nothing
  , onMouseLeave: Nothing
  , onContextMenu: Nothing
  , resizeObserver: Nothing
  , noDragClassName: "nodrag"
  , noPanClassName: "nopan"
  , rfId: "1"
  , disableKeyboardA11y: a11y.keyboardA11yOff
  , nodeTypes: Nothing
  , nodeExtent: Nothing
  , onError: Nothing
  , nodeClickDistance: Nothing
  }

edgeProps :: A11y -> EdgeWrapperProps Unit Unit
edgeProps a11y =
  { id: "ab"
  , edgesFocusable: a11y.focusable
  , edgesReconnectable: false
  , elementsSelectable: true
  , noPanClassName: "nopan"
  , onClick: Nothing
  , onDoubleClick: Nothing
  , onReconnect: Nothing
  , onContextMenu: Nothing
  , onMouseEnter: Nothing
  , onMouseMove: Nothing
  , onMouseLeave: Nothing
  , reconnectRadius: Nothing
  , onReconnectStart: Nothing
  , onReconnectEnd: Nothing
  , rfId: Just "1"
  , edgeTypes: Nothing
  , onError: Nothing
  , disableKeyboardA11y: Just a11y.keyboardA11yOff
  }

storeToOpaque :: Store Unit Unit -> OpaqueStore
storeToOpaque = unsafeCoerce

-- | The wrapper's markup, rendered inside a store holding `a` above `b` and
-- | the edge between them.
renderIn :: JSX -> Effect String
renderIn wrapper = do
  store <- createStore
    ( (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
        { nodes = Just
            [ nodeAt "a" { x: 0.0, y: 0.0 } [ handleAt Source PosBottom 24.0 ]
            , nodeAt "b" { x: 0.0, y: 100.0 } [ handleAt Target PosTop (-1.0) ]
            ]
        , edges = Just [ edgeAB ]
        }
    )
  renderMarkup (storeProvider (Just (storeToOpaque store)) [ wrapper ])

has :: String -> String -> Boolean
has needle = contains (Pattern needle)

runAriaDescribedByTests :: Effect Unit
runAriaDescribedByTests = do
  log "\n=== Wrappers: aria-describedby points at the a11y descriptions ==="

  let
    nodeDesc = "aria-describedby=\"react-flow__node-desc-1\""
    edgeDesc = "aria-describedby=\"react-flow__edge-desc-1\""
    renderNode a11y = renderIn (element nodeWrapper (nodeProps a11y))
    renderEdge a11y = renderIn (element edgeWrapper (edgeProps a11y))

  node <- renderNode { focusable: true, keyboardA11yOff: false }
  assert "a node renders, so the checks on its attributes aren't vacuous"
    (has "data-testid=\"rf__node-a\"" node)
  assert "a node points at the node description"
    (has nodeDesc node)

  unfocusableNode <- renderNode { focusable: false, keyboardA11yOff: false }
  assert "a node that isn't focusable still points at the node description"
    (has nodeDesc unfocusableNode)

  keyboardOffNode <- renderNode { focusable: true, keyboardA11yOff: true }
  assert "a node has no aria-describedby when keyboard a11y is off"
    (has "data-testid=\"rf__node-a\"" keyboardOffNode && not (has "aria-describedby" keyboardOffNode))

  edge <- renderEdge { focusable: true, keyboardA11yOff: false }
  assert "an edge renders, so the checks on its attributes aren't vacuous"
    (has "data-testid=\"rf__edge-ab\"" edge)
  assert "a focusable edge points at the edge description"
    (has edgeDesc edge)

  keyboardOffEdge <- renderEdge { focusable: true, keyboardA11yOff: true }
  assert "a focusable edge still points at the edge description when keyboard a11y is off"
    (has edgeDesc keyboardOffEdge)

  unfocusableEdge <- renderEdge { focusable: false, keyboardA11yOff: false }
  assert "an edge that isn't focusable has no aria-describedby"
    (has "data-testid=\"rf__edge-ab\"" unfocusableEdge && not (has "aria-describedby" unfocusableEdge))
