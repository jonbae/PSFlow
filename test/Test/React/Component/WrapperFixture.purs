-- | A node wrapper or an edge wrapper, rendered on the server inside a real
-- | store holding node `a` above node `b` and the edge `ab` between them.
-- |
-- | Each node carries its handles so the store seeds their bounds without a
-- | DOM, as upstream's server rendering does. A test changes the fields it is
-- | about with a record update on `nodeA`, `edgeAB`, `nodeProps` or
-- | `edgeProps`, and reads the markup `renderInStore` returns.
module Test.React.Component.WrapperFixture
  ( edgeAB
  , edgeProps
  , has
  , nodeA
  , nodeProps
  , renderInStore
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), contains)
import Effect (Effect)
import React.Basic (JSX)
import React.Context.Store (OpaqueStore, storeProvider)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Edges (EdgeWrapperProps)
import React.Types.Nodes (NodeWrapperProps)
import System.Types.Edge (EdgeBase)
import System.Types.Geometry (Position(..), XYPosition)
import System.Types.Handle (HandleIdField(..), HandleType(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeBase, NodeHandle)
import Unsafe.Coerce (unsafeCoerce)

foreign import renderMarkup :: JSX -> Effect String

has :: String -> String -> Boolean
has needle = contains (Pattern needle)

-- | A 50 × 25 node at `at`, carrying `handles`.
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
  , focusable: Nothing
  , ariaRole: Nothing
  , domAttributes: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: Nothing
  , resizing: Nothing
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
  { id: HandleIdUnset, x: 24.0, y, position, handleType, width: Just 2.0, height: Just 2.0 }

-- | Node `a`, at the origin, with a source handle on its bottom side.
nodeA :: NodeBase Unit
nodeA = nodeAt "a" { x: 0.0, y: 0.0 } [ handleAt Source PosBottom 24.0 ]

-- | Node `b`, below `a`, with a target handle on its top side.
nodeB :: NodeBase Unit
nodeB = nodeAt "b" { x: 0.0, y: 100.0 } [ handleAt Target PosTop (-1.0) ]

-- | The edge from `a` to `b`.
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
  , focusable: Nothing
  , reconnectable: Nothing
  , ariaRole: Nothing
  , domAttributes: Nothing
  , labelStyle: Nothing
  , labelShowBg: Nothing
  , labelBgStyle: Nothing
  , labelBgPadding: Nothing
  , labelBgBorderRadius: Nothing
  , pathOptions: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | The wrapper props for node `a`, focusable and with keyboard a11y on.
nodeProps :: NodeWrapperProps Unit
nodeProps =
  { id: "a"
  , nodesConnectable: true
  , elementsSelectable: true
  , nodesDraggable: true
  , nodesFocusable: true
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
  , disableKeyboardA11y: false
  , nodeTypes: Nothing
  , nodeExtent: Nothing
  , onError: Nothing
  , nodeClickDistance: Nothing
  }

-- | The wrapper props for edge `ab`, focusable.
edgeProps :: EdgeWrapperProps Unit Unit
edgeProps =
  { id: "ab"
  , edgesFocusable: true
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
  , disableKeyboardA11y: Nothing
  }

-- | These tests write the state and then render on the server, where React
-- | reads the store's server snapshot, its initial state. They render the
-- | state they wrote, so the store handed over serves that one instead.
storeToOpaque :: Store Unit Unit -> OpaqueStore
storeToOpaque store = unsafeCoerce (store { getInitialState = store.getState })

-- | The wrapper's markup, rendered inside a store holding `a` (as given)
-- | above `nodeB`, and `ab` (as given) between them.
renderInStore :: { a :: NodeBase Unit, ab :: EdgeBase Unit } -> JSX -> Effect String
renderInStore { a, ab } wrapper = do
  store <- createStore
    ( (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
        { nodes = Just [ a, nodeB ]
        , edges = Just [ ab ]
        }
    )
  renderMarkup (storeProvider (Just (storeToOpaque store)) [ wrapper ])
