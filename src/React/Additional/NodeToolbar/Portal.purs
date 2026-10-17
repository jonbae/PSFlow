-- | `<NodeToolbarPortal />` — portals its children into the flow's
-- | `.react-flow__renderer` so the toolbar escapes node clipping. Mirrors
-- | `xyflow/.../NodeToolbar/NodeToolbarPortal.tsx`.
module React.Additional.NodeToolbar.Portal
  ( nodeToolbarPortal
  , selectTarget
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, fragment)
import React.Basic.Hooks (UnsafeReference(..), reactChildrenToArray, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.Hook.Store (useStore)
import React.Portal.FFI (createPortal)
import React.Types.Component (EdgeLabelRendererProps) as Re
import React.Types.Store (ReactFlowState)
import Web.DOM.Element (Element)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.HTML.HTMLDivElement (toParentNode)

-- | Upstream's `state.domNode?.querySelector('.react-flow__renderer')`. The
-- | slice is `Maybe Element` wrapped in `UnsafeReference` for stable Eq.
selectTarget :: forall n e. ReactFlowState n e -> Maybe (UnsafeReference Element)
selectTarget s = case s.domNode of
  Nothing -> Nothing
  Just dn -> case unsafePerformEffect (querySelector qs (toParentNode dn)) of
    Nothing -> Nothing
    Just el -> Just (UnsafeReference el)
  where
  qs = QuerySelector ".react-flow__renderer"

nodeToolbarPortal :: ReactComponent Re.EdgeLabelRendererProps
nodeToolbarPortal =
  unsafePerformEffect $ reactComponentWithChildren "NodeToolbarPortal"
    \(props :: Re.EdgeLabelRendererProps) -> React.do
      mTarget <- useStore selectTarget
      pure case mTarget of
        Nothing -> mempty
        Just (UnsafeReference el) ->
          createPortal (fragment (reactChildrenToArray props.children)) el
