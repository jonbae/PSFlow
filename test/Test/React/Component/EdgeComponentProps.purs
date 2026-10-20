-- | The `selectable` and `deletable` an edge component receives.
-- |
-- | The local proxy for the report's
-- | `mount-baseline--edges-general--probe-edge` scenario, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `<EdgeWrapper />` renders the edge
-- | component with
-- |
-- |     selectable={isSelectable}
-- |     deletable={edge.deletable ?? true}
-- |
-- | where `isSelectable` is the edge's own `selectable`, or the flow's
-- | `elementsSelectable` when the edge doesn't set one. ps-flow handed the
-- | component the edge's own fields, so an edge that set neither gave it
-- | `undefined` for both.
module Test.React.Component.EdgeComponentProps
  ( runEdgeComponentPropsTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (JSX, element)
import React.Component.EdgeWrapper (edgeWrapper)
import React.Context.Store (OpaqueStore, storeProvider)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Edges (EdgeTypesMap, EdgeWrapperProps)
import System.Types.Edge (EdgeBase)
import System.Types.Geometry (Position(..), XYPosition)
import System.Types.Handle (HandleIdField(..), HandleType(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeBase, NodeHandle)
import Unsafe.Coerce (unsafeCoerce)

foreign import renderMarkup :: JSX -> Effect String
foreign import recordingEdgeTypes :: EdgeTypesMap
foreign import takeRecorded :: Effect (Array Received)

-- | The two props this test reads, out of the `EdgeProps` the component
-- | receives.
type Received = { selectable :: Maybe Boolean, deletable :: Maybe Boolean }

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
  { id: HandleIdUnset, x: 24.0, y, position, handleType, width: Just 2.0, height: Just 2.0 }

-- | The edge `ab`, of the recording type, with the `selectable` and
-- | `deletable` it sets.
edgeSetting :: { selectable :: Maybe Boolean, deletable :: Maybe Boolean } -> EdgeBase Unit
edgeSetting { selectable, deletable } =
  { id: "ab"
  , edgeType: Just "recording"
  , source: NodeId "a"
  , target: NodeId "b"
  , sourceHandle: Nothing
  , targetHandle: Nothing
  , animated: Nothing
  , hidden: Nothing
  , deletable
  , selectable
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

wrapperProps :: Boolean -> EdgeWrapperProps Unit Unit
wrapperProps elementsSelectable =
  { id: "ab"
  , edgesFocusable: true
  , edgesReconnectable: false
  , elementsSelectable
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
  , edgeTypes: Just recordingEdgeTypes
  , onError: Nothing
  , disableKeyboardA11y: Just false
  }

storeToOpaque :: Store Unit Unit -> OpaqueStore
storeToOpaque = unsafeCoerce

-- | The props the edge component receives, in a flow with
-- | `elementsSelectable`, holding `a` above `b` and `edge` between them.
received :: Boolean -> EdgeBase Unit -> Effect Received
received elementsSelectable edge = do
  store <- createStore
    ( (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
        { nodes = Just
            [ nodeAt "a" { x: 0.0, y: 0.0 } [ handleAt Source PosBottom 24.0 ]
            , nodeAt "b" { x: 0.0, y: 100.0 } [ handleAt Target PosTop (-1.0) ]
            ]
        , edges = Just [ edge ]
        }
    )
  _ <- renderMarkup
    (storeProvider (Just (storeToOpaque store)) [ element edgeWrapper (wrapperProps elementsSelectable) ])
  recorded <- takeRecorded
  case recorded of
    [ props ] -> pure props
    _ -> unsafeCrashWith "FAIL the edge component didn't render exactly once, so its props can't be read"

runEdgeComponentPropsTests :: Effect Unit
runEdgeComponentPropsTests = do
  log "\n=== EdgeWrapper: the edge component's selectable and deletable ==="

  unset <- received true (edgeSetting { selectable: Nothing, deletable: Nothing })
  assert "an edge that sets neither is selectable in a selectable flow"
    (unset.selectable == Just true)
  assert "an edge that doesn't set deletable is deletable, as `?? true` gives"
    (unset.deletable == Just true)

  unselectableFlow <- received false (edgeSetting { selectable: Nothing, deletable: Nothing })
  assert "an edge that doesn't set selectable takes the flow's elementsSelectable"
    (unselectableFlow.selectable == Just false)

  ownTrue <- received false (edgeSetting { selectable: Just true, deletable: Nothing })
  assert "an edge's own selectable wins over the flow's"
    (ownTrue.selectable == Just true)

  ownFalse <- received true (edgeSetting { selectable: Just false, deletable: Just false })
  assert "an edge's own selectable false wins over a selectable flow"
    (ownFalse.selectable == Just false)
  assert "an edge's own deletable false is handed on"
    (ownFalse.deletable == Just false)
