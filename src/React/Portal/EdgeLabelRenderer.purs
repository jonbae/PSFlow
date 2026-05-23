-- | `<EdgeLabelRenderer />` — portal target that lets edge components
-- | render HTML (not SVG) labels above the SVG layer. Mirrors
-- | `xyflow-main/packages/react/src/components/EdgeLabelRenderer/index.tsx`.
module React.Portal.EdgeLabelRenderer
  ( edgeLabelRenderer
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, fragment)
import React.Basic.Hooks (UnsafeReference(..), reactChildrenToArray, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.Hook.Store (useStore)
import React.Portal.FFI (createPortal)
import React.Types.Component (EdgeLabelRendererProps)
import React.Types.Store (ReactFlowState)
import Web.DOM.Element (Element)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.HTML.HTMLDivElement (toParentNode)

selectTarget :: forall n e. ReactFlowState n e -> Maybe (UnsafeReference Element)
selectTarget s = case s.domNode of
  Nothing -> Nothing
  Just dn -> case unsafePerformEffect (querySelector qs (toParentNode dn)) of
    Nothing -> Nothing
    Just el -> Just (UnsafeReference el)
  where
  qs = QuerySelector ".react-flow__edgelabel-renderer"

edgeLabelRenderer :: ReactComponent EdgeLabelRendererProps
edgeLabelRenderer =
  unsafePerformEffect $ reactComponentWithChildren "EdgeLabelRenderer"
    \(props :: EdgeLabelRendererProps) -> React.do
      mTarget <- useStore selectTarget
      pure case mTarget of
        Nothing -> mempty
        Just (UnsafeReference el) ->
          createPortal (fragment (reactChildrenToArray props.children)) el
