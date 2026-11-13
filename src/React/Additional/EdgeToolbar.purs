-- | `<EdgeToolbar />` — anchored at a midpoint of an edge, rendered
-- | through `EdgeLabelRenderer`. Mirrors `xyflow/.../EdgeToolbar/EdgeToolbar.tsx`.
module React.Additional.EdgeToolbar
  ( edgeToolbar
  , module React.Types.Component
  ) where

import Prelude

import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (toMaybe)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object as Object
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (UnsafeReference(..), reactChildrenFromArray, reactChildrenToArray, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.FFI.DOM (div_)
import React.Hook.Store (sameValue, shallow, useStoreWith)
import React.Portal.EdgeLabelRenderer (edgeLabelRenderer)
import React.Types.Component (EdgeToolbarProps)
import React.Types.Edges (Edge)
import React.Types.Store (ReactFlowState)
import System.Types.Edge (AlignX(..), AlignY(..), originalUserEdge)
import System.Types.Geometry (Transform(..))
import System.Utils.Toolbar (getEdgeToolbarTransform)
import Unsafe.Coerce (unsafeCoerce)

toForeignStyle :: Object String -> Foreign
toForeignStyle = unsafeCoerce

-- | TS's `edgeSelector`, the edge the toolbar is for.
selectEdge :: forall n e. String -> ReactFlowState n e -> Maybe (Edge e)
selectEdge edgeId s = Map.lookup edgeId s.edgeLookup

-- | TS's `zoomSelector`, compared by `Object.is` as `useStore` compares a
-- | selection upstream hands it no equality for.
selectZoom :: forall n e. ReactFlowState n e -> Number
selectZoom s = let Transform t = s.transform in t.scale

-- | TS's `shallow` over the edge its store holds. Upstream's store holds the
-- | consumer's own edge object, and an edge decoded from one keeps it, so two
-- | such edges compare by their objects' keys: a copy of an edge with the
-- | same values is the same edge. Any other edge is the same only as itself.
sameEdge :: forall e. Maybe (Edge e) -> Maybe (Edge e) -> Boolean
sameEdge = case _, _ of
  Nothing, Nothing -> true
  Just a, Just b ->
    UnsafeReference a == UnsafeReference b
      || case toMaybe (originalUserEdge a), toMaybe (originalUserEdge b) of
        Just original, Just other -> shallow original other
        _, _ -> false
  _, _ -> false

edgeToolbar :: ReactComponent EdgeToolbarProps
edgeToolbar =
  unsafePerformEffect $ reactComponentWithChildren "EdgeToolbar"
    \(props :: EdgeToolbarProps) -> React.do
      mEdge <- useStoreWith (selectEdge props.edgeId) sameEdge
      zoom <- useStoreWith selectZoom sameValue
      let
        isActive = case props.isVisible of
          Just b -> b
          Nothing -> case mEdge of
            Just e -> e.selected == Just true
            Nothing -> false
      if not isActive then pure mempty
      else
        let
          alignX = fromMaybe AlignXCenter props.alignX
          alignY = fromMaybe AlignYCenter props.alignY
          transformStr = getEdgeToolbarTransform props.x props.y zoom alignX alignY
          baseZIndex = case mEdge of
            Just e -> fromMaybe 0 e.zIndex
            Nothing -> 0
          zIndex = baseZIndex + 1
          userClass = fromMaybe "" props.className
          className = "react-flow__edge-toolbar"
            <> (if userClass == "" then "" else " " <> userClass)
          baseStyle = fromMaybe Object.empty props.style
          wrapperStyle = baseStyle
            # Object.insert "position" "absolute"
            # Object.insert "transform" transformStr
            # Object.insert "zIndex" (show zIndex)
            # Object.insert "pointerEvents" "all"
            # Object.insert "transformOrigin" "0 0"
          dataId = case mEdge of
            Just e -> e.id
            Nothing -> ""
          toolbarDiv = div_
            { style: toForeignStyle wrapperStyle
            , className
            , "data-id": dataId
            }
            (reactChildrenToArray props.children)
        in
          pure $ element edgeLabelRenderer
            { children: reactChildrenFromArray [ toolbarDiv ]
            }
