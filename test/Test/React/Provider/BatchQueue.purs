-- | What the batch provider does with a drained queue, as upstream's two
-- | queue handlers do it.
-- |
-- | The local proxy for `React.Provider.Batch` on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | which `uncontrolled-update-node` showed missing three `onNodesChange`
-- | calls. Upstream's node handler fires `onNodesChange` with the diff whether
-- | or not the nodes are uncontrolled, after the nodes-change middleware, and
-- | its diff reports `replace` only for an item that isn't the object the
-- | store holds. ps-flow's fired only for controlled nodes, skipped the
-- | middleware, and reported `replace` for every node. Upstream's edge handler
-- | fires `onEdgesChange` for controlled edges even with an empty diff.
module Test.React.Provider.BatchQueue
  ( runBatchQueueTests
  ) where

import Prelude

import Boundary.Elements (JsEdge, JsNode, edgeIn, nodeIn, nodeOut)
import Boundary.SetState (setStateOut)
import Data.Array ((!!))
import Data.Map as Map
import Data.Maybe (Maybe(..), isJust)
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Effect.Uncurried (runEffectFn1)
import Foreign (Foreign, unsafeToForeign)
import Partial.Unsafe (unsafeCrashWith)
import React.Provider.Batch (planEdgeQueue, planNodeQueue)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import React.Types.Nodes (Node)
import React.Types.Store (MiddlewareKey(..), ReactFlowState)
import System.Types.Edge (EdgeChange(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeChange(..))
import Unsafe.Reference (unsafeRefEq)

foreign import nodes :: Array JsNode
foreign import added :: JsNode
foreign import edges :: Array JsEdge
foreign import relabelB :: Foreign

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

type State = ReactFlowState Foreign Foreign

opts :: InitialStateOptions Foreign Foreign
opts = defaultInitialStateOptions

uncontrolled :: Array (Node Foreign) -> State
uncontrolled ns = initialState (opts { defaultNodes = Just ns, defaultEdges = Just (map edgeIn edges) })

controlled :: Array (Node Foreign) -> State
controlled ns = initialState (opts { nodes = Just ns, edges = Just (map edgeIn edges) })

-- | The store's nodes with `b` replaced, as `updateNode` builds them.
relabelled :: State -> Array (Node Foreign)
relabelled s = map (\n -> if n.id == NodeId "b" then n { data = unsafeToForeign "relabelled" } else n) s.nodes

replacedIds :: Maybe (Array (NodeChange Foreign)) -> Maybe (Array String)
replacedIds = map (map describe)
  where
  describe = case _ of
    NodeReplaceChange c -> "replace " <> show c.id
    NodeAddChange c -> "add " <> show c.item.id <> " at " <> show c.index
    NodeRemoveChange c -> "remove " <> show c.id
    _ -> "other"

edgeKinds :: Maybe (Array (EdgeChange Foreign)) -> Maybe (Array String)
edgeKinds = map (map describe)
  where
  describe = case _ of
    EdgeReplaceChange c -> "replace " <> c.id
    EdgeAddChange _ -> "add"
    EdgeRemoveChange c -> "remove " <> c.id
    _ -> "other"

runBatchQueueTests :: Effect Unit
runBatchQueueTests = do
  log "\n=== BatchProvider: the queue handlers ==="

  let
    jsNodes = map nodeIn nodes
    free = uncontrolled jsNodes
    held = controlled jsNodes
    freePlan = planNodeQueue free (relabelled free)
    heldPlan = planNodeQueue held (relabelled held)

  assert "uncontrolled nodes are set, and onNodesChange fires too"
    (isJust freePlan.setNodes && replacedIds freePlan.onNodesChange == Just [ "replace \"b\"" ])
  assert "controlled nodes aren't set, and onNodesChange fires"
    (not (isJust heldPlan.setNodes) && replacedIds heldPlan.onNodesChange == Just [ "replace \"b\"" ])
  assert "an added node is an add at its index"
    (replacedIds (planNodeQueue held (held.nodes <> [ nodeIn added ])).onNodesChange == Just [ "add \"c\" at (Just 2)" ])

  let
    same = planNodeQueue held held.nodes
    sameQueued = planNodeQueue (held { fitViewQueued = true }) held.nodes
  assert "an unchanged queue fires nothing"
    (not (isJust same.onNodesChange) && not same.refitNextFrame)
  assert "an unchanged queue with a fitView queued sets the nodes again on the next frame"
    (not (isJust sameQueued.onNodesChange) && sameQueued.refitNextFrame)

  let
    dropping = held { onNodesChangeMiddlewareMap = Map.singleton (MiddlewareKey 1) (\_ -> []) }
  assert "the nodes-change middleware runs over the diff"
    (not (isJust (planNodeQueue dropping (relabelled dropping)).onNodesChange))

  let
    relabelEdge s = map (\e -> if e.id == "b-a" then e { label = Just "relabelled" } else e) s.edges
    heldEdges = planEdgeQueue held (relabelEdge held)
  assert "controlled edges fire onEdgesChange for the changed edge only"
    (not (isJust heldEdges.setEdges) && edgeKinds heldEdges.onEdgesChange == Just [ "replace b-a" ])
  assert "controlled edges fire onEdgesChange even with an empty diff"
    (edgeKinds (planEdgeQueue held held.edges).onEdgesChange == Just [])
  assert "uncontrolled edges are set, and onEdgesChange doesn't fire"
    ( let p = planEdgeQueue free (relabelEdge free)
      in isJust p.setEdges && edgeKinds p.onEdgesChange == Nothing
    )

  -- A consumer's `setNodes(fn)` crosses out and back. The nodes it hands
  -- back untouched have to come back as the same records, or the diff reads
  -- every node as replaced.
  result <- Ref.new ([] :: Array (Node Foreign))
  let
    set :: (Array (Node Foreign) -> Array (Node Foreign)) -> Effect Unit
    set f = Ref.write (f jsNodes) result
  runEffectFn1 (setStateOut "setNodes" nodeIn nodeOut set) relabelB
  next <- Ref.read result
  assert "a setNodes updater's untouched nodes come back as the same records"
    ( case next !! 0, jsNodes !! 0, next !! 1, jsNodes !! 1 of
        Just a, Just a0, Just b, Just b0 -> unsafeRefEq a a0 && not (unsafeRefEq b b0)
        _, _, _, _ -> false
    )
  assert "so the diff reports only the node the updater changed"
    (replacedIds (planNodeQueue held next).onNodesChange == Just [ "replace \"b\"" ])
