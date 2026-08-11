-- | `useNodesState` and `useEdgesState`, crossing.
-- |
-- | The 21 hooks are boundary **stage 3**, fused with `ReactFlowInstance`
-- | because `useReactFlow` *returns* the instance and they share a converter.
-- | That argument is specific to `useReactFlow`. These two return their own
-- | bundles and touch no instance, so they cross alone, in stage 1, pulled
-- | forward by upstream's `examples/ColorMode/index.tsx` — the second driver,
-- | which is the first thing in the repo to call either of them from
-- | JavaScript.
-- |
-- | Both were **broken from JavaScript** before this, in two ways that a
-- | consumer sees and no PureScript test could:
-- |
-- |   * The hook returns a PureScript **record** where upstream returns a
-- |     3-tuple, so `const [nodes, , onNodesChange] = useNodesState(…)`
-- |     destructured `undefined` three times.
-- |   * A PureScript `Hook` is an unrun `Effect` at runtime, so the call
-- |     returned a thunk rather than calling `useState` at all.
-- |   * `setEdges` is `(Array e -> Array e) -> Effect Unit`, so
-- |     `setEdges(eds => …)` built another unrun thunk and mutated nothing.
-- |     That is the `setNodes(fn)` silent no-op the whole boundary effort
-- |     started from, and this is the first place it is fixed.
-- |
-- | What holds the third one is `parity/boundary/mount.mjs`, which calls the
-- | setter itself. No browser gate does: the ColorMode driver's own
-- | `setEdges(eds => addEdge(params, eds))` runs on connect, and
-- | `generic-props.spec.ts` never draws one.
-- |
-- | ## The array, and what checks it
-- |
-- | Upstream's return is positional, so there is no JS-shaped *record* here
-- | for `parity/boundary/drift.mjs` to compare labels against. The equivalent
-- | guard is a type: `nodesTripleOut` takes a **closed** record spelling the
-- | bundle's three fields, so a fourth field added to `NodesStateBundle`
-- | fails to unify and the build stops. Same claim as the drift gate's, made
-- | by the compiler instead of by a script.
-- |
-- | ## SetStateAction
-- |
-- | Upstream's setter is React's own `Dispatch<SetStateAction<T[]>>`, which
-- | accepts the next array *or* a function of the previous one. ps-flow's is
-- | the function form only, so the array form is adapted here rather than
-- | refused — it is React's contract, not an unimplemented prop, and a
-- | consumer writing `setNodes([])` is writing correct upstream code.
-- |
-- | Both forms round-trip: the previous array goes out through `nodeOut`
-- | before the consumer's function sees it, and what comes back goes in
-- | through `nodeIn`. So what a consumer is handed is what `applyNodeChanges`
-- | hands them, and what they return may be built from either.
module Boundary.Hooks
  ( JsEdgesState
  , JsNodesState
  , JsTriple
  , useEdgesState
  , useNodesState
  ) where

import Prelude

import Boundary.Elements
  ( JsEdge
  , JsEdgeChange
  , JsNode
  , JsNodeChange
  , edgeChangeIn
  , edgeIn
  , edgeOut
  , nodeChangeIn
  , nodeIn
  , nodeOut
  )
import Boundary.Untagged (asArray, asFunction, typeName)
import Data.Function.Uncurried (Fn3, runFn3)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (EffectFn1, mkEffectFn1)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic.Hooks (Render)
import React.Hook.NodesEdgesState (useEdgesState, useNodesState) as PS
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import System.Types.Edge (EdgeChange)
import System.Types.Node (NodeChange)
import Unsafe.Coerce (unsafeCoerce)

-- ────────────────────────────────────────────────────────────────────────
-- The JS shapes
-- ────────────────────────────────────────────────────────────────────────

-- | A JavaScript tuple: an array whose slots have different types, which is
-- | not something `Array` can say. Opaque, because the only thing ps-flow
-- | ever does with one is hand it to a consumer who destructures it.
foreign import data JsTriple :: Type -> Type -> Type -> Type

foreign import mkTriple :: forall a b c. Fn3 a b c (JsTriple a b c)

-- | `[nodes, setNodes, onNodesChange]`.
type JsNodesState =
  JsTriple (Array JsNode) (EffectFn1 Foreign Unit) (EffectFn1 (Array JsNodeChange) Unit)

-- | `[edges, setEdges, onEdgesChange]`.
type JsEdgesState =
  JsTriple (Array JsEdge) (EffectFn1 Foreign Unit) (EffectFn1 (Array JsEdgeChange) Unit)

-- ────────────────────────────────────────────────────────────────────────
-- Running the hook
-- ────────────────────────────────────────────────────────────────────────

-- | A `Hook` is a `Render`, which is a newtype over `Effect`. React's own
-- | rules are what make running it here safe: a hook may only be called
-- | during a render, so the caller is inside one, and `reactComponent` runs
-- | its own hooks exactly this way.
runHook :: forall hooks newHook a. Render hooks newHook a -> Effect a
runHook = unsafeCoerce

-- ────────────────────────────────────────────────────────────────────────
-- useNodesState
-- ────────────────────────────────────────────────────────────────────────

useNodesState :: Array JsNode -> JsNodesState
useNodesState initialNodes =
  unsafePerformEffect (nodesTripleOut <$> runHook (PS.useNodesState (map nodeIn initialNodes)))

-- | The closed record is the staleness guard — see the module header.
nodesTripleOut
  :: { nodes :: Array (Node Foreign)
     , setNodes :: (Array (Node Foreign) -> Array (Node Foreign)) -> Effect Unit
     , onNodesChange :: Array (NodeChange Foreign) -> Effect Unit
     }
  -> JsNodesState
nodesTripleOut bundle = runFn3 mkTriple
  (map nodeOut bundle.nodes)
  (setStateOut "setNodes" nodeIn nodeOut bundle.setNodes)
  (mkEffectFn1 \changes -> bundle.onNodesChange (map nodeChangeIn changes))

-- ────────────────────────────────────────────────────────────────────────
-- useEdgesState
-- ────────────────────────────────────────────────────────────────────────

useEdgesState :: Array JsEdge -> JsEdgesState
useEdgesState initialEdges =
  unsafePerformEffect (edgesTripleOut <$> runHook (PS.useEdgesState (map edgeIn initialEdges)))

edgesTripleOut
  :: { edges :: Array (Edge Foreign)
     , setEdges :: (Array (Edge Foreign) -> Array (Edge Foreign)) -> Effect Unit
     , onEdgesChange :: Array (EdgeChange Foreign) -> Effect Unit
     }
  -> JsEdgesState
edgesTripleOut bundle = runFn3 mkTriple
  (map edgeOut bundle.edges)
  (setStateOut "setEdges" edgeIn edgeOut bundle.setEdges)
  (mkEffectFn1 \changes -> bundle.onEdgesChange (map edgeChangeIn changes))

-- ────────────────────────────────────────────────────────────────────────
-- The setter
-- ────────────────────────────────────────────────────────────────────────

-- | React's `Dispatch<SetStateAction<T[]>>`, over a `T` this boundary
-- | converts. `name` is the setter as the consumer wrote it, so a bad
-- | argument names `setEdges` rather than some helper of ours.
setStateOut
  :: forall js ps
   . String
  -> (js -> ps)
  -> (ps -> js)
  -> ((Array ps -> Array ps) -> Effect Unit)
  -> EffectFn1 Foreign Unit
setStateOut name inward outward set = mkEffectFn1 \action ->
  case asFunction action of
    Just update ->
      set \previous -> map inward (expect "returned" (update (unsafeCoerce (map outward previous))))
    Nothing -> set \_ -> map inward (expect "was called with" action)
  where
  expect what raw = case asArray raw of
    Just entries -> unsafeCoerce entries
    Nothing ->
      unsafeThrow $
        "ps-flow: `" <> name <> "` " <> what <> " " <> typeName raw
          <> " — it takes the next array, or a function of the previous one."
