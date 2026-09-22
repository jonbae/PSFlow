-- | The store's `panBy`, in the shape a drag can await.
-- |
-- | Upstream's is a store method, not an action: it reads the viewport slice
-- | off `get()`, hands it to `System.Utils.Store.panBy`, and returns that
-- | function's promise unchanged (`xyflow/packages/react/src/store/index.ts`,
-- | `panBy`). Every caller that cares whether the pan landed — the node drag,
-- | the selection drag, the two connection handles — reads the Boolean from
-- | there.
-- |
-- | ps-flow modelled it as the `PanBy` action instead. The action reaches the
-- | same function through `RunPanBy`, but a dispatch has no result, so four
-- | copies of an adapter dispatched and answered `pure true`. An auto-pan
-- | frame reads that as "the viewport moved" and moves the dragged nodes by
-- | the distance it asked to pan, which at a `translateExtent` boundary is a
-- | node travelling thousands of pixels a second while the viewport holds
-- | still.
-- |
-- | This is that store method: one function, read-then-call, no dispatch.
-- | `React.Container.Pane`'s lasso auto-pan was the last caller still
-- | dispatching the action; it reads this instead, and the `PanBy` action and
-- | its `RunPanBy` effect are gone, because upstream has no action on this
-- | path at all.
module React.Store.PanBy
  ( panBy
  ) where

import Prelude

import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import React.Store.Shell (Store)
import System.Types.Geometry (XYPosition)
import System.Utils.Store (panBy) as Store

panBy :: forall n e. Store n e -> XYPosition -> Aff Boolean
panBy store delta = do
  s <- liftEffect store.getState
  Store.panBy delta s.panZoom s.transform s.translateExtent s.width s.height
