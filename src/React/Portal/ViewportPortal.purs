-- | `<ViewportPortal />` — portal target inside the transformed
-- | viewport (pans and zooms with the flow). Mirrors
-- | `xyflow-main/packages/react/src/components/ViewportPortal/index.tsx`.
-- |
-- | The target div is mounted as `.react-flow__viewport-portal` by
-- | `GraphView` (ticket 041).
module React.Portal.ViewportPortal
  ( viewportPortal
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, fragment)
import React.Basic.Hooks (UnsafeReference(..), reactChildrenToArray, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.Hook.Store (useStore)
import React.Portal.FFI (createPortal)
import React.Types.Component (ViewportPortalProps)
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
  qs = QuerySelector ".react-flow__viewport-portal"

viewportPortal :: ReactComponent ViewportPortalProps
viewportPortal =
  unsafePerformEffect $ reactComponentWithChildren "ViewportPortal"
    \(props :: ViewportPortalProps) -> React.do
      mTarget <- useStore selectTarget
      pure case mTarget of
        Nothing -> mempty
        Just (UnsafeReference el) ->
          createPortal (fragment (reactChildrenToArray props.children)) el
