-- | The store's change triggers, handed nothing to change.
-- |
-- | The local proxy for "Stop firing onNodesChange and onEdgesChange with
-- | an empty change list" (#139). Upstream's `triggerNodeChanges` and
-- | `triggerEdgeChanges` act only `if (changes?.length)`
-- | (`xyflow/packages/react/src/store/index.ts`): no commit in uncontrolled
-- | mode and no call to the consumer. ps-flow's reducers had no guard, so a
-- | pane click with nothing selected called `onNodesChange([])` and
-- | `onEdgesChange([])`, which `drag-by-custom-drag-handle` records and
-- | upstream does not.
-- |
-- | Each check runs `reduce` and reads the effects it hands the shell. A
-- | reducer without the guard fails the first, and the other three reach a
-- | trigger with an empty list the same way.
module Test.React.Store.EmptyChanges
  ( runEmptyChangesTests
  ) where

import Prelude

import Data.Array (null) as Array
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import React.Store.Reduce (reduce)
import React.Types.Store (ReactFlowState)
import Unsafe.Reference (unsafeRefEq)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A controlled flow: the consumer owns `nodes` and `edges`.
controlled :: ReactFlowState Unit Unit
controlled = initialState
  ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just [], edges = Just [] })

-- | An uncontrolled flow: the store owns them, and commits a change itself.
uncontrolled :: ReactFlowState Unit Unit
uncontrolled = initialState
  ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { defaultNodes = Just [], defaultEdges = Just [] })

runEmptyChangesTests :: Effect Unit
runEmptyChangesTests = do
  log "\n=== Store: an empty change list reaches nobody (#139) ==="

  let reset = reduce controlled ResetSelectedElements
  assert "a pane click with nothing selected calls neither onNodesChange nor onEdgesChange"
    (Array.null reset.effects)

  let unselect = reduce controlled (UnselectNodesAndEdges { nodes: Nothing, edges: Nothing })
  assert "unselecting with nothing selected calls neither change handler"
    (Array.null unselect.effects)

  let nodes = reduce uncontrolled (TriggerNodeChanges [])
  assert "an empty node change list in an uncontrolled flow commits nothing and calls nothing"
    (Array.null nodes.effects && unsafeRefEq nodes.state uncontrolled)

  let edges = reduce uncontrolled (TriggerEdgeChanges [])
  assert "an empty edge change list in an uncontrolled flow commits nothing and calls nothing"
    (Array.null edges.effects && unsafeRefEq edges.state uncontrolled)
