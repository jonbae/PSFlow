-- | **PSFlow-specific** custom node + fixture guarding the `NodeProps` wiring
-- | (ticket 069). Not a port of anything upstream: `nodePropsProbe` renders every
-- | field ticket 069 threaded through `mkNodeProps` as a `data-*` attribute, so
-- | `tests/node-props.spec.ts` can assert the props record a user's node component
-- | actually receives. If a field is dropped or mis-wired again (the drift that
-- | produced 069 in the first place), the spec fails.
-- |
-- | It lives on its own route (`#/examples/node-props`, wired in `Example.Main`)
-- | rather than inside a `Generic.*` fixture because those are faithful ports of
-- | upstream's e2e suite — a PSFlow-only assertion there would break that
-- | invariant. Same reasoning as `Example.ColorMode`.
module Example.NodePropsProbe
  ( nodePropsProbe
  , nodePropsProbeFixture
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object as Object
import Generic.Fixture (Fixture, baseNode)
import React (NodeTypesMap)
import React.Basic (ReactComponent)
import React.Basic.Hooks (reactComponent)
import React.FFI.DOM (div_, textContent)
import React.Types.Nodes (NodeProps)
import System.Types.Ids (ParentId(..))
import Unsafe.Coerce (unsafeCoerce)

-- | `style` on the DOM-prop records is `Foreign`; build an inline-style object by
-- | coercing a plain record (mirrors `Generic.DragHandleNode`).
toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

-- | Renders the six fields added in 069 plus the two renamed position fields as
-- | `data-*` attributes. `div_` takes an open record straight to
-- | `React.createElement`, so quoted `data-…` labels reach the DOM verbatim. The
-- | id text + explicit box give the div non-zero size so it is a *visible*
-- | element, not just an attribute carrier.
nodePropsProbe :: ReactComponent (NodeProps Foreign)
nodePropsProbe = unsafePerformEffect $ reactComponent "NodePropsProbe"
  \(props :: NodeProps Foreign) ->
    pure $
      div_
        { className: "node-props-probe"
        , style: toForeignStyle
            { width: maybe "100px" (\w -> show w <> "px") props.width
            , height: maybe "40px" (\h -> show h <> "px") props.height
            , border: "1px solid #222"
            , background: "#eee"
            , fontSize: "10px"
            }
        , "data-selectable": show props.selectable
        , "data-draggable": show props.draggable
        , "data-deletable": show props.deletable
        , "data-width": maybe "" show props.width
        , "data-height": maybe "" show props.height
        , "data-parent-id": fromMaybe "" props.parentId
        , "data-pos-x": show props.positionAbsoluteX
        , "data-pos-y": show props.positionAbsoluteY
        }
        [ textContent props.id ]

-- | Two probe nodes covering both branches of the flag resolution in
-- | `NodeWrapper`:
-- |
-- | * `probe-parent` leaves `selectable`/`draggable`/`deletable` at `Nothing`, so
-- |   the wrapper falls through to `elementsSelectable`/`nodesDraggable` (both
-- |   default `true`) and `fromMaybe true` respectively.
-- | * `probe-child` sets all three to `Just false` (the explicit branch) and
-- |   parents itself to `probe-parent`.
-- |
-- | The parent deliberately sits **off-origin** at (100, 200): the child's own
-- | `position` is (50, 25) but its `positionAbsolute` is (150, 225), so asserting
-- | the latter proves the renamed fields carry *absolute* position rather than
-- | raw `position`. With the parent at the origin the two would coincide and the
-- | assertion would pass under a mis-wiring.
nodePropsProbeFixture :: Fixture
nodePropsProbeFixture =
  { nodes:
      [ (baseNode "probe-parent" 100.0 200.0)
          { nodeType = Just "NodePropsProbe"
          , width = Just 300.0
          , height = Just 200.0
          , measured = { width: Just 300.0, height: Just 200.0 }
          }
      , (baseNode "probe-child" 50.0 25.0)
          { nodeType = Just "NodePropsProbe"
          , parentId = Just (ParentId "probe-parent")
          , selectable = Just false
          , draggable = Just false
          , deletable = Just false
          , width = Just 120.0
          , height = Just 40.0
          , measured = { width: Just 120.0, height: Just 40.0 }
          }
      ]
  , edges: []
  , deleteKeyCode: Nothing
  , multiSelectionKeyCode: Nothing
  , nodeDragThreshold: Nothing
  , fitView: Just true
  , nodeTypes: Just (unsafeCoerce (Object.singleton "NodePropsProbe" nodePropsProbe) :: NodeTypesMap)
  , minZoom: Nothing
  , maxZoom: Nothing
  , panOnScroll: Nothing
  , defaultViewport: Nothing
  , autoPanOnConnect: Nothing
  , autoPanOnNodeDrag: Nothing
  }
