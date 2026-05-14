-- | `useMoveSelectedNodes` — returns a function that nudges every
-- | currently-selected node by a `(dx, dy)` offset scaled by a factor.
-- | Used by `panActivation`-key shortcuts. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useMoveSelectedNodes.ts`.
-- |
-- | The hook is `Effect`-flavoured at its boundary — the returned
-- | function may be invoked at any point after mount and reads live
-- | state from the store each call.
module React.Hook.MoveSelectedNodes
  ( useMoveSelectedNodes
  ) where

import Prelude

import Data.Array (filter) as Array
import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Effect (Effect)
import React.Basic.Hooks (Hook)
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import System.Types.Geometry (XYPosition)

useMoveSelectedNodes
  :: Hook UseStoreApi (XYPosition -> Number -> Effect Unit)
useMoveSelectedNodes = map mkMover useStoreApi
  where
  mkMover store = \delta factor -> do
    st <- store.getState
    let
      selected = Array.filter _.selected st.nodes
      dragItems =
        map
          ( \n ->
              let
                absolute = case Map.lookup n.id st.nodeLookup of
                  Just internal -> internal.internals.positionAbsolute
                  Nothing -> n.position
                newPos =
                  { x: n.position.x + delta.x * factor
                  , y: n.position.y + delta.y * factor
                  }
              in
                { id: n.id
                , position: newPos
                , distance: { x: 0.0, y: 0.0 }
                , measured:
                    { width: fromMaybe 0.0 n.measured.width
                    , height: fromMaybe 0.0 n.measured.height
                    }
                , internals: { positionAbsolute: absolute }
                , extent: n.extent
                , parentId: n.parentId
                , origin: n.origin
                , expandParent: n.expandParent
                , dragging: false
                }
          )
          selected
    -- Discrete move: not a drag (`false`). The reducer trips the
    -- usual position-change pipeline.
    store.dispatch (UpdateNodePositions dragItems false)
