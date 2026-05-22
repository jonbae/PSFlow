-- | `<EdgeRenderer />` — fans out over the visible edge IDs and mounts
-- | one `<EdgeWrapper />` per ID, plus the `<MarkerDefinitions />`
-- | overlay that publishes the shared SVG arrowhead `<marker>`s.
-- |
-- | Mirrors `xyflow-main/packages/react/src/container/EdgeRenderer/index.tsx`.
-- |
-- | **Fidelity notes.**
-- |   * `memo` is applied to the public export (matches TS).
-- |   * Each `EdgeWrapper` already renders its own `<svg><g>` (per-
-- |     edge z-index ordering depends on having one SVG per edge), so
-- |     the outer container is a plain `<div>`, not an `<svg>` — same
-- |     as TS.
-- |   * The optional `children` slot from TS (`ReactNode`) is omitted;
-- |     no in-tree caller needs it.
module React.Container.EdgeRenderer
  ( edgeRenderer
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent, element, keyed)
import React.Basic.Hooks (UnsafeReference(..), memo, reactComponent)
import React.Basic.Hooks as React
import React.Component.EdgeWrapper (edgeWrapper)
import React.Container.MarkerDefinitions (markerDefinitions)
import React.FFI.DOM (div_)
import React.Hook.Store (useStore)
import React.Hook.VisibleIds (useVisibleEdgeIds)
import React.Types.Component (EdgeRendererProps)
import React.Types.Store (ReactFlowState)
import System.Types.Connection (ConnectionMode)
import System.Types.Node (OnError)

-- ----------------------------------------------------------------------------
-- Flags slice
-- ----------------------------------------------------------------------------

type EdgeFlagsSlice =
  { edgesFocusable :: Boolean
  , edgesReconnectable :: Boolean
  , elementsSelectable :: Boolean
  , connectionMode :: ConnectionMode
  , onError :: UnsafeReference (Maybe OnError)
  }

selectFlags :: forall n e. ReactFlowState n e -> EdgeFlagsSlice
selectFlags s =
  { edgesFocusable: s.edgesFocusable
  , edgesReconnectable: s.edgesReconnectable
  , elementsSelectable: s.elementsSelectable
  , connectionMode: s.connectionMode
  , onError: UnsafeReference s.onError
  }

-- ----------------------------------------------------------------------------
-- The component
-- ----------------------------------------------------------------------------

edgeRenderer :: forall n e. ReactComponent (EdgeRendererProps n e)
edgeRenderer =
  unsafePerformEffect $ memo $ reactComponent "EdgeRenderer"
    \(props :: EdgeRendererProps n e) -> React.do
      flags <- useStore selectFlags
      edgeIds <- useVisibleEdgeIds props.onlyRenderVisibleElements
      let
        UnsafeReference onError = flags.onError
        edgeChildren :: Array JSX
        edgeChildren = map
          ( \edgeId ->
              keyed edgeId $ element edgeWrapper
                { id: edgeId
                , edgesFocusable: flags.edgesFocusable
                , edgesReconnectable: flags.edgesReconnectable
                , elementsSelectable: flags.elementsSelectable
                , noPanClassName: props.noPanClassName
                , onReconnect: props.onReconnect
                , onContextMenu: props.onEdgeContextMenu
                , onMouseEnter: props.onEdgeMouseEnter
                , onMouseMove: props.onEdgeMouseMove
                , onMouseLeave: props.onEdgeMouseLeave
                , onClick: props.onEdgeClick
                , reconnectRadius: props.reconnectRadius
                , onDoubleClick: props.onEdgeDoubleClick
                , onReconnectStart: props.onReconnectStart
                , onReconnectEnd: props.onReconnectEnd
                , rfId: Just props.rfId
                , onError
                , edgeTypes: props.edgeTypes
                , disableKeyboardA11y: Just props.disableKeyboardA11y
                }
          )
          edgeIds
      pure $
        div_
          { className: "react-flow__edges" }
          ( [ element markerDefinitions
                { defaultColor: props.defaultMarkerColor
                , rfId: Just props.rfId
                }
            ] <> edgeChildren
          )
