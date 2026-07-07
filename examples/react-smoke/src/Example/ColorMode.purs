-- | Bespoke ColorMode example page for the Layer 2 `props.spec` port (ticket
-- | 065). A **minimal** stand-in for xyflow's `examples/ColorMode` example: a
-- | stateful flow holding a `ColorMode`, passed to `<ReactFlow colorMode=…>`,
-- | with a `<Panel top-right>` housing a `<select data-testid="colormode-select">`
-- | (light/dark/system). MiniMap/Background/Controls are omitted — the two adopted
-- | tests only assert the `.react-flow` `dark`-class states.
-- |
-- | Reached via the non-generic route `#/examples/color-mode` (wired in
-- | `Example.Main`); it can't go through `fixtureForRoute`/`flowView` because the
-- | `Fixture` model has no `colorMode`/`Panel`/`select`.
module Example.ColorMode
  ( colorModeApp
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Generic.Defaults (defaultReactFlowProps)
import React (ColorMode(..), Edge, Node, PanelPosition(..), Position(..), panel, reactFlow)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Events (EventHandler)
import React.Basic.Hooks (reactChildrenFromArray, reactComponent, useState)
import React.Basic.Hooks as React
import React.FFI.DOM (textContent)
import React.Types.Component (PanelProps)
import System.Types.Ids (NodeId(..))

foreign import select_ :: forall p. Record p -> Array JSX -> JSX
foreign import option_ :: forall p. Record p -> Array JSX -> JSX

-- | Wrap a `String -> Effect Unit` as a `<select onChange>` handler reading
-- | `event.target.value`.
foreign import onSelectChangeImpl :: (String -> Effect Unit) -> EventHandler

parseMode :: String -> ColorMode
parseMode = case _ of
  "dark" -> DarkMode
  "system" -> SystemMode
  _ -> LightMode

-- | Four nodes (`A` = input, `B`/`C`/`D` default) + three edges from `A`, echoing
-- | upstream's example data. `measured` is pre-seeded so the nodes are
-- | `visibility: visible` on first paint (the tests assert that).
nodes :: Array (Node Unit)
nodes =
  [ (mkNode "A" 0.0 150.0) { nodeType = Just "input" }
  , mkNode "B" 250.0 0.0
  , mkNode "C" 250.0 150.0
  , mkNode "D" 250.0 300.0
  ]
  where
  mkNode nid x y =
    { id: NodeId nid
    , position: { x, y }
    , data: unit
    , sourcePosition: Just PosRight
    , targetPosition: Just PosLeft
    , hidden: false
    , selected: false
    , dragging: false
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
    , expandParent: false
    , ariaLabel: Nothing
    , origin: Nothing
    , handles: Nothing
    , measured: { width: Just 150.0, height: Just 40.0 }
    , nodeType: Nothing
    , className: Nothing
    , style: Nothing
    }

edges :: Array (Edge Unit)
edges =
  [ mkEdge "A-B" "A" "B"
  , mkEdge "A-C" "A" "C"
  , mkEdge "A-D" "A" "D"
  ]
  where
  mkEdge eid src tgt =
    { id: eid
    , edgeType: Nothing
    , source: NodeId src
    , target: NodeId tgt
    , sourceHandle: Nothing
    , targetHandle: Nothing
    , animated: false
    , hidden: false
    , deletable: Nothing
    , selectable: Nothing
    , data: Nothing
    , selected: false
    , markerStart: Nothing
    , markerEnd: Nothing
    , zIndex: Nothing
    , ariaLabel: Nothing
    , interactionWidth: Nothing
    , className: Nothing
    , style: Nothing
    }

colorModeSelect :: EventHandler -> JSX
colorModeSelect onChange = select_
  { onChange, "data-testid": "colormode-select" }
  [ option_ { value: "light" } [ textContent "light" ]
  , option_ { value: "dark" } [ textContent "dark" ]
  , option_ { value: "system" } [ textContent "system" ]
  ]

colorModePanel :: EventHandler -> JSX
colorModePanel onChange = element panel
  ({ position: TopRight
   , className: Nothing
   , style: Nothing
   , "aria-label": Nothing
   , "data-testid": Nothing
   , children: reactChildrenFromArray [ colorModeSelect onChange ]
   } :: PanelProps)

colorModeFlow :: ReactComponent {}
colorModeFlow = unsafePerformEffect $ reactComponent "ColorModeFlow" \(_ :: {}) -> React.do
  colorMode /\ setColorMode <- useState LightMode
  let
    onChange = onSelectChangeImpl \v -> setColorMode (const (parseMode v))
    rfProps =
      defaultReactFlowProps
        { defaultNodes = Just nodes
        , defaultEdges = Just edges
        , colorMode = Just colorMode
        , fitView = Just true
        , children = reactChildrenFromArray [ colorModePanel onChange ]
        }
  pure $ element reactFlow rfProps

colorModeApp :: JSX
colorModeApp = element colorModeFlow {}
