-- | The two portal targets, crossing — boundary stage 4.
-- |
-- | `<EdgeLabelRenderer />` and `<ViewportPortal />` are one entry in the
-- | **hole register** between them, and its reason is the sharpest statement
-- | of why crossing and driving are different claims:
-- |
-- | > no fixture portals anything. GraphView draws both containers for every
-- | > flow whether or not the export is used, so a container in every trace
-- | > says nothing — only content inside one does.
-- |
-- | So this module does not close that hole and is not trying to. What it
-- | removes is the reason a scenario could not be written: both components
-- | take `children` and nothing else, and `children` is the one prop a
-- | JavaScript caller cannot pass through a PureScript record — `ReactChildren
-- | JSX` is what `reactComponentWithChildren` produces, and a raw re-export
-- | published the un-wrapped PureScript component instead.
-- |
-- | Neither is memoized on either side, and neither has a prop to convert. The
-- | wrappers are as thin as a crossing gets, and they are still the difference
-- | between a name that resolves and a component that mounts.
module Boundary.Portals
  ( JsEdgeLabelRendererProps
  , JsViewportPortalProps
  , edgeLabelRenderer
  , viewportPortal
  ) where

import Prelude

import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (ReactChildren, reactComponentWithChildren)
import React.Portal.EdgeLabelRenderer (edgeLabelRenderer) as PS
import React.Portal.ViewportPortal (viewportPortal) as PS
import React.Types.Component (EdgeLabelRendererProps, ViewportPortalProps)

type JsEdgeLabelRendererProps =
  { children :: ReactChildren JSX
  }

-- | A one-field conversion, written out rather than inlined, and spelled
-- | `convert<Component>` like every other converter on this surface. That name
-- | is not decoration: `parity/boundary/mount.mjs` finds the converters by it
-- | and fails on a module that has none, so a component crossing with its
-- | conversion inlined would be a component the mount gate never looks at.
convertEdgeLabelRenderer :: JsEdgeLabelRendererProps -> EdgeLabelRendererProps
convertEdgeLabelRenderer p =
  { children: p.children
  }

edgeLabelRenderer :: ReactComponent JsEdgeLabelRendererProps
edgeLabelRenderer =
  unsafePerformEffect $ reactComponentWithChildren "EdgeLabelRenderer"
    \(props :: JsEdgeLabelRendererProps) ->
      pure (element PS.edgeLabelRenderer (convertEdgeLabelRenderer props))

type JsViewportPortalProps =
  { children :: ReactChildren JSX
  }

convertViewportPortal :: JsViewportPortalProps -> ViewportPortalProps
convertViewportPortal p =
  { children: p.children
  }

viewportPortal :: ReactComponent JsViewportPortalProps
viewportPortal =
  unsafePerformEffect $ reactComponentWithChildren "ViewportPortal"
    \(props :: JsViewportPortalProps) ->
      pure (element PS.viewportPortal (convertViewportPortal props))
