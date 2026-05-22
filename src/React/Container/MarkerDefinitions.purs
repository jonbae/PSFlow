-- | `<MarkerDefinitions />` — the `<svg><defs>` block that publishes one
-- | `<marker>` per unique edge-marker config in the store. Marker IDs
-- | are derived by `System.Utils.Marker.createMarkerIds` and referenced
-- | from `EdgeWrapper`'s `markerStart` / `markerEnd` URL attributes.
-- |
-- | Mirrors
-- | `xyflow-main/packages/react/src/container/EdgeRenderer/MarkerDefinitions.tsx`.
-- |
-- | **Fidelity notes.**
-- |   * TS reads `defaultEdgeOptions?.markerStart / markerEnd` to seed
-- |     the marker collection with the default markers. PS's
-- |     `DefaultEdgeOptions` scaffold doesn't carry those two fields
-- |     yet, so we pass `Nothing` for both. Edges with explicit
-- |     `markerStart` / `markerEnd` still produce their markers.
-- |   * `memo` is applied to the public export, matching TS.
-- |   * `useMemo` over the marker array is skipped; recomputation
-- |     happens only when the slice (edges + defaultEdgeOptions)
-- |     changes, which is rare.
module React.Container.MarkerDefinitions
  ( markerDefinitions
  ) where

import Prelude

import Data.Array (null) as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent)
import React.Basic.Hooks (UnsafeReference(..), memo, reactComponent)
import React.Basic.Hooks as React
import React.Container.MarkerSymbols (markerSymbol)
import React.FFI.DOM (defs_, marker_, svg_)
import React.Hook.Store (useStore)
import React.Types.Component (MarkerDefinitionsProps)
import React.Types.Edges (DefaultEdgeOptions, Edge)
import React.Types.Store (ReactFlowState)
import System.Types.Edge (MarkerProps)
import System.Utils.Marker (createMarkerIds)

-- | Slice projects both inputs to `createMarkerIds`. Wrap each in
-- | `UnsafeReference` so the hook's `Eq` constraint is satisfied
-- | without an `Eq e` requirement (matches the trick used in
-- | `EdgeWrapper`).
type MarkerSlice e =
  { edges :: UnsafeReference (Array (Edge e))
  , defaultEdgeOptions :: UnsafeReference (Maybe (DefaultEdgeOptions e))
  }

selectSlice :: forall n e. ReactFlowState n e -> MarkerSlice e
selectSlice s =
  { edges: UnsafeReference s.edges
  , defaultEdgeOptions: UnsafeReference s.defaultEdgeOptions
  }

markerElement :: MarkerProps -> JSX
markerElement m =
  marker_
    { className: "react-flow__arrowhead"
    , id: m.id
    , key: m.id
    , markerWidth: fromMaybe 12.5 m.width
    , markerHeight: fromMaybe 12.5 m.height
    , viewBox: "-10 -10 20 20"
    , markerUnits: fromMaybe "strokeWidth" m.markerUnits
    , orient: fromMaybe "auto-start-reverse" m.orient
    , refX: 0
    , refY: 0
    }
    [ markerSymbol m.markerType
        { color: m.color, strokeWidth: m.strokeWidth }
    ]

markerDefinitions :: ReactComponent MarkerDefinitionsProps
markerDefinitions =
  unsafePerformEffect $ memo $ reactComponent "MarkerDefinitions"
    \(props :: MarkerDefinitionsProps) -> React.do
      slice <- useStore selectSlice
      let
        UnsafeReference edges = slice.edges
        markers = createMarkerIds edges
          { id: props.rfId
          , defaultColor: props.defaultColor
          , defaultMarkerStart: Nothing
          , defaultMarkerEnd: Nothing
          }
      pure $
        if Array.null markers then mempty
        else
          svg_
            { className: "react-flow__marker"
            , "aria-hidden": "true"
            }
            [ defs_ {} (map markerElement markers) ]
