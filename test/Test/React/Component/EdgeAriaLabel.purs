-- | An edge's `aria-label`, and the consumer's `null` that turns it off.
-- |
-- | The local proxy for the map's "`aria-label` never emitted on edges"
-- | entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `<EdgeWrapper />` renders
-- |
-- |     edge.ariaLabel === null ? undefined : edge.ariaLabel || `Edge from ${edge.source} to ${edge.target}`
-- |
-- | so an absent or empty label gets a default, a string is used as written,
-- | and `null` renders none. ps-flow rendered only the consumer's label, and
-- | its boundary read `null` as absent, which would have given a consumer
-- | who asked for no label the default one.
-- |
-- | `ariaLabel` is typed `string` upstream and `<EdgeWrapper />` reads `null`
-- | anyway, so the edge merged with `defaultEdgeOptions` keeps a `null` over
-- | a default label, as the spread does.
module Test.React.Component.EdgeAriaLabel
  ( runEdgeAriaLabelTests
  ) where

import Prelude

import Boundary.Elements (JsEdge, edgeIn, edgeOut)
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), contains)
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (JSX, element)
import React.Component.EdgeWrapper (edgeWrapper)
import React.Context.Store (OpaqueStore, storeProvider)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Edges (DefaultEdgeOptions, EdgeWrapperProps)
import System.Types.Edge (EdgeAriaLabel(..), EdgeBase)
import System.Types.Geometry (Position(..), XYPosition)
import System.Types.Handle (HandleType(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeBase, NodeHandle)
import Unsafe.Coerce (unsafeCoerce)

foreign import renderMarkup :: JSX -> Effect String
foreign import jsEdgeWithAriaLabel :: forall a. a -> JsEdge
foreign import jsNull :: Foreign
foreign import jsUndefined :: Foreign
foreign import ariaLabelIsNull :: JsEdge -> Boolean
foreign import ariaLabelIsUndefined :: JsEdge -> Boolean

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
  , selected: false
  , dragging: false
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

edgeLabelled :: Maybe EdgeAriaLabel -> EdgeBase Unit
edgeLabelled ariaLabel =
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
  , ariaLabel
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
  }

defaultsLabelled :: Maybe EdgeAriaLabel -> DefaultEdgeOptions Unit
defaultsLabelled ariaLabel =
  { animated: Nothing
  , hidden: Nothing
  , deletable: Nothing
  , selectable: Nothing
  , focusable: Nothing
  , data: Nothing
  , zIndex: Nothing
  , ariaLabel
  , interactionWidth: Nothing
  , reconnectable: Nothing
  }

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
  , disableKeyboardA11y: Just false
  }

storeToOpaque :: Store Unit Unit -> OpaqueStore
storeToOpaque = unsafeCoerce

-- | The edge wrapper's markup, in a store holding `a` above `b`, the edge
-- | `ab` between them, and `defaults` as the flow's `defaultEdgeOptions`.
renderEdge :: Maybe (DefaultEdgeOptions Unit) -> EdgeBase Unit -> Effect String
renderEdge defaults edge = do
  store <- createStore
    ( (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
        { nodes = Just
            [ nodeAt "a" { x: 0.0, y: 0.0 } [ handleAt Source PosBottom 24.0 ]
            , nodeAt "b" { x: 0.0, y: 100.0 } [ handleAt Target PosTop (-1.0) ]
            ]
        , edges = Just [ edge ]
        }
    )
  store.dispatch (PatchState _ { defaultEdgeOptions = defaults })
  markup <- renderMarkup (storeProvider (Just (storeToOpaque store)) [ element edgeWrapper edgeProps ])
  -- Every check below reads an attribute, so an edge that didn't render
  -- would pass the ones that look for none.
  if contains (Pattern "data-testid=\"rf__edge-ab\"") markup then pure markup
  else unsafeCrashWith ("FAIL the edge didn't render, so its attributes can't be read: " <> markup)

has :: String -> String -> Boolean
has needle = contains (Pattern needle)

runEdgeAriaLabelTests :: Effect Unit
runEdgeAriaLabelTests = do
  log "\n=== EdgeWrapper: aria-label falls back to a default unless it's null ==="

  let defaultLabel = "aria-label=\"Edge from a to b\""

  absent <- renderEdge Nothing (edgeLabelled Nothing)
  assert "an edge with no aria label gets the default one"
    (has defaultLabel absent)

  empty <- renderEdge Nothing (edgeLabelled (Just (AriaLabel "")))
  assert "an empty aria label gets the default one, as `||` does"
    (has defaultLabel empty)

  custom <- renderEdge Nothing (edgeLabelled (Just (AriaLabel "Custom")))
  assert "an aria label is rendered as written"
    (has "aria-label=\"Custom\"" custom)

  off <- renderEdge Nothing (edgeLabelled (Just AriaLabelOff))
  assert "a null aria label renders no aria-label"
    (not (has "aria-label" off))

  let defaults = Just (defaultsLabelled (Just (AriaLabel "From defaults")))
  fromDefaults <- renderEdge defaults (edgeLabelled Nothing)
  assert "an edge with no aria label takes the one in defaultEdgeOptions"
    (has "aria-label=\"From defaults\"" fromDefaults)

  offOverDefaults <- renderEdge defaults (edgeLabelled (Just AriaLabelOff))
  assert "a null aria label wins over the one in defaultEdgeOptions, as the spread does"
    (not (has "aria-label" offOverDefaults))

  assert "the boundary reads a consumer's null as the label turned off"
    ((edgeIn (jsEdgeWithAriaLabel jsNull)).ariaLabel == Just AriaLabelOff)
  assert "the boundary reads an absent aria label as absent"
    ((edgeIn (jsEdgeWithAriaLabel jsUndefined)).ariaLabel == Nothing)
  assert "the boundary reads a string aria label as written"
    ((edgeIn (jsEdgeWithAriaLabel "Custom")).ariaLabel == Just (AriaLabel "Custom"))
  assert "the boundary hands a consumer's null back as null"
    (ariaLabelIsNull (edgeOut (edgeLabelled (Just AriaLabelOff))))
  assert "the boundary hands an absent aria label back as undefined"
    (ariaLabelIsUndefined (edgeOut (edgeLabelled Nothing)))
