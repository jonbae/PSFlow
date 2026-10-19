-- | When `useDrag` rebinds a node's drag.
-- |
-- | The local proxy for the report's `selection-box-touch` scenario, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `useDrag` binds d3-drag in an effect keyed
-- | on
-- |
-- |     [noDragClassName, handleSelector, disabled, isSelectable, nodeRef, nodeId, nodeClickDistance]
-- |
-- | ps-flow's was keyed on the options record, which is new every render,
-- | so it rebound on every render. Its cleanup removes the element's
-- | `.drag` listeners, and d3-drag keeps a touch gesture's move and end
-- | listeners on the element, so a touch drag ended at the first render
-- | after it started: in the scenario, the one that selects the node.
-- |
-- | The test renders the real hook with a committing stand-in for React's
-- | dispatcher, against an element that counts its `touchmove` listeners.
module Test.React.Hook.DragRebind
  ( runDragRebindTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (Ref)
import React.Basic.Hooks (Hook)
import React.Hook.Drag (UseDragOptions, useDrag)
import System.Types.Ids (NodeId(..))
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML.HTMLDivElement (HTMLDivElement)

type Renderer =
  { render :: Effect Boolean -> Effect Boolean
  , commit :: Effect Unit
  , unmount :: Effect Unit
  }

type DragTarget =
  { ref :: Ref (Nullable HTMLDivElement)
  , touchMoveListeners :: Effect Int
  , touchMoveRemovals :: Effect Int
  }

foreign import newCommittingRenderer :: Effect Renderer
foreign import newDragTarget :: Effect DragTarget

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A `Hook` is an `Effect` with a phantom tag, run here outside React.
runHook :: forall hooks a. Hook hooks a -> Effect a
runHook = unsafeCoerce

-- | A node wrapper's options, built fresh, closures and all, as a render
-- | builds them. `render` only tells one render's closures from another's.
options :: Ref (Nullable HTMLDivElement) -> { disabled :: Boolean, isSelectable :: Boolean, render :: Int } -> UseDragOptions Unit Unit
options ref o =
  { wrapperRef: ref
  , disabled: o.disabled
  , nodeId: Just (NodeId "a")
  , noDragClassName: Just "nodrag"
  , handleSelector: Nothing
  , isSelectable: o.isSelectable
  , nodeClickDistance: 0.0
  , autoPanSpeed: Nothing
  , getStoreItems: pure (unsafeCoerce { render: o.render })
  , onDragStart: Nothing
  , onDragEnd: Nothing
  , onNodeMouseDown: Just \_ -> when (o.render < 0) (pure unit)
  }

runDragRebindTests :: Effect Unit
runDragRebindTests = do
  log "\n=== useDrag: a re-render keeps the node's drag bound ==="

  target <- newDragTarget
  renderer <- newCommittingRenderer
  let
    renderWith o = do
      _ <- renderer.render (runHook (useDrag (options target.ref o)))
      renderer.commit

  renderWith { disabled: false, isSelectable: true, render: 1 }
  bound <- target.touchMoveListeners
  assert "the first render binds the element's touch listeners"
    (bound == 1)

  renderWith { disabled: false, isSelectable: true, render: 2 }
  renderWith { disabled: false, isSelectable: true, render: 3 }
  kept <- target.touchMoveRemovals
  assert "re-renders with fresh options and closures keep the binding, as a touch gesture needs"
    (kept == 0)

  renderWith { disabled: false, isSelectable: false, render: 4 }
  rebound <- target.touchMoveRemovals
  rebindHolds <- target.touchMoveListeners
  assert "a change upstream lists, such as isSelectable, rebinds it"
    (rebound == 1 && rebindHolds == 1)

  renderWith { disabled: true, isSelectable: false, render: 5 }
  disabled <- target.touchMoveListeners
  assert "disabling the drag releases it"
    (disabled == 0)

  renderWith { disabled: false, isSelectable: false, render: 6 }
  renderer.unmount
  released <- target.touchMoveListeners
  assert "unmounting releases it"
    (released == 0)
