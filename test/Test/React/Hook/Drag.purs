-- | One run of `useDrag`'s effect, against upstream's `disabled`.
-- |
-- | The local proxy for "Pan the pane when a drag starts on an undraggable
-- | node, as upstream does" (#125). Upstream's `<NodeWrapper />` hands
-- | `useDrag` `disabled: node.hidden || !isDraggable`, and the hook's effect
-- | returns before `update`, so d3-drag never binds to the node
-- | (`xyflow-main/packages/react/src/hooks/useDrag.ts`). ps-flow had no
-- | `disabled`: it passed the undraggable node `nodeId: Nothing` and bound it
-- | anyway. d3-drag's `mousedown` handler stops the event's propagation
-- | before its filter has a say, so the pointer-down never reached d3-zoom
-- | and the pane did not pan.
-- |
-- | Like `Test.React.Provider.InitPrevValues`, this runs without rendering:
-- | `spago test` has no DOM. `bindDrag` is the effect's whole body, with the
-- | React ref and `createXYDrag` replaced by counters. A `bindDrag` that
-- | ignores `disabled` is what the hook amounted to before the fix, and it
-- | fails the first two checks.
module Test.React.Hook.Drag
  ( runDragHookTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Hook.Drag (bindDrag)
import System.Types.Ids (NodeId(..))
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Element (Element)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A stand-in for the node's `<div>`. Only the controller's `update`
-- | would read it, and the counting controller does not.
element :: Element
element = unsafeCoerce {}

type Counts =
  { allocated :: Int
  -- | The node id each `update` was handed.
  , updates :: Array (Maybe NodeId)
  , released :: Int
  }

-- | Run one effect for a node wrapper's binding, then its cleanup, and
-- | count what reached the controller.
runBinding
  :: { disabled :: Boolean, domNode :: Maybe Element }
  -> Effect Counts
runBinding { disabled, domNode } = do
  allocated <- Ref.new 0
  updates <- Ref.new []
  released <- Ref.new 0
  cleanup <- bindDrag
    { disabled
    , domNode
    , controller: do
        Ref.modify_ (_ + 1) allocated
        pure
          { update: \p -> Ref.modify_ (_ <> [ p.nodeId ]) updates
          , destroy: pure unit
          }
    , release: Ref.modify_ (_ + 1) released
    , params: \d ->
        { noDragClassName: Just "nodrag"
        , handleSelector: Nothing
        , isSelectable: true
        , nodeId: Just (NodeId "a")
        , domNode: d
        , nodeClickDistance: 0.0
        }
    }
  cleanup
  { allocated: _, updates: _, released: _ }
    <$> Ref.read allocated
    <*> Ref.read updates
    <*> Ref.read released

runDragHookTests :: Effect Unit
runDragHookTests = do
  log "\n=== useDrag: a disabled drag leaves the element unbound (#125) ==="

  undraggable <- runBinding { disabled: true, domNode: Just element }
  assert "an undraggable node is never bound, so its pointer-down reaches d3-zoom"
    (undraggable.updates == [])
  assert "an undraggable node allocates no controller and releases none"
    (undraggable.allocated == 0 && undraggable.released == 0)

  draggable <- runBinding { disabled: false, domNode: Just element }
  assert "a draggable node is bound once, under its own id"
    (draggable.updates == [ Just (NodeId "a") ])
  assert "a draggable node's cleanup releases the controller it bound"
    (draggable.allocated == 1 && draggable.released == 1)

  unmounted <- runBinding { disabled: false, domNode: Nothing }
  assert "an element that is not mounted is not bound"
    (unmounted.updates == [] && unmounted.allocated == 0)
