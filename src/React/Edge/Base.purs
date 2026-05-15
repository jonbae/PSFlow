-- | The `<BaseEdge />` component — shared rendering for every built-in
-- | edge variant. Mirrors
-- | `xyflow-main/packages/react/src/components/Edges/BaseEdge.tsx`.
-- |
-- | Renders an SVG `<path>` for the visible stroke, an invisible
-- | interaction `<path>` with `stroke-opacity=0` and a wide
-- | `interactionWidth` for hit-testing, and (when `label` is present and
-- | `labelX`/`labelY` are supplied) an `<EdgeText>` group.
-- |
-- | Wrapped in `memo` so identical-prop re-renders are skipped, matching
-- | TS.
module React.Edge.Base
  ( baseEdge
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (memo, reactComponent)
import React.Edge.Text (edgeText)
import React.FFI.DOM (opt, path_)
import React.Types.Edges (BaseEdgeProps)

baseEdge :: ReactComponent BaseEdgeProps
baseEdge = unsafePerformEffect $ memo $ reactComponent "BaseEdge" \(props :: BaseEdgeProps) ->
  pure $
    let
      interactionWidth = fromMaybe 20.0 props.interactionWidth
      pathClass = case props.className of
        Just c -> "react-flow__edge-path " <> c
        Nothing -> "react-flow__edge-path"
      mainPath :: JSX
      mainPath = path_
        { id: opt props.id
        , d: props.path
        , fill: "none"
        , style: opt props.style
        , className: pathClass
        , markerStart: opt props.markerStart
        , markerEnd: opt props.markerEnd
        }
        []
      interactionPath :: JSX
      interactionPath
        | interactionWidth > 0.0 = path_
            { d: props.path
            , fill: "none"
            , strokeOpacity: 0
            , strokeWidth: interactionWidth
            , className: "react-flow__edge-interaction"
            }
            []
        | otherwise = mempty
      label :: JSX
      label = case props.label, props.labelX, props.labelY of
        Just _, Just lx, Just ly | isJust props.label ->
          element edgeText
            { x: lx
            , y: ly
            , label: props.label
            , labelStyle: props.labelStyle
            , labelShowBg: props.labelShowBg
            , labelBgStyle: props.labelBgStyle
            , labelBgPadding: props.labelBgPadding
            , labelBgBorderRadius: props.labelBgBorderRadius
            }
        _, _, _ -> mempty
    in
      mainPath <> interactionPath <> label
