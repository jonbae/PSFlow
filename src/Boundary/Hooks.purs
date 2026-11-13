-- | The twenty-one hooks, crossing.
-- |
-- | Two of them crossed in stage 1 — `useNodesState` and `useEdgesState`,
-- | pulled forward by upstream's `examples/ColorMode/index.tsx`, the second
-- | driver and the first thing in the repo to call either from JavaScript.
-- | The other nineteen are **stage 3**, fused with `ReactFlowInstance` because
-- | `useReactFlow` *returns* it and the two cannot be separated.
-- |
-- | Every one of them was **broken from JavaScript** before this, and all of
-- | them in the same first way:
-- |
-- |   * A PureScript `Hook` is a newtype over `Effect`, which is an unrun
-- |     thunk at runtime, so `useViewport()` returned a function rather than a
-- |     viewport and never called `useStore` at all.
-- |   * A hook with a class constraint carries the **dictionary** as its first
-- |     argument, so `useNodes` — nullary upstream — was a one-argument
-- |     function that a JavaScript caller could not supply.
-- |   * Anything the hook *returns* is PureScript-shaped: `Maybe` where
-- |     upstream has `undefined`, records where upstream has tuples,
-- |     `nodeType` where upstream has `type`.
-- |
-- | ## `runHook`, and why it is safe
-- |
-- | A `Hook` is a `Render`, which is a newtype over `Effect`, so running one
-- | is a coercion and a call. React's own rules are what make it safe: a hook
-- | may only be called during a render, so the caller is inside one, and
-- | `reactComponent` runs its own hooks by exactly this route.
-- |
-- | ## The equality each slice hook compares with
-- |
-- | Upstream's slice hooks are each `useStore(selector, equality)`, and the
-- | equality decides when a consumer's component renders and which object it
-- | reads back. So each one here builds what the consumer reads inside its
-- | selector, and compares that with upstream's equality, through
-- | `React.Hook.Store.useStoreWith`:
-- |
-- |   * `useNodes` and `useEdges` read the store's own `nodes` and `edges`,
-- |     the consumer's arrays, through the view `useStore` hands out.
-- |   * `useInternalNode` reads the internal node that `nodeLookup` holds.
-- |   * `useViewport` and `useConnection` read a fresh object per state.
-- |   * `useNodesData` compares with `shallowNodeData`, and the other five
-- |     with zustand's `shallow`.
-- |
-- | An unchanged slice keeps the object read before, as upstream's selection
-- | memo keeps it. The PureScript selector hooks compare PureScript values by
-- | their `Eq` instances, and a consumer's data is `Foreign`, so these share
-- | the PureScript hooks' selectors and not their equalities.
-- |
-- | ## The store hooks
-- |
-- | `useStore` and `useStoreApi` hand the consumer the store's state itself.
-- | Until Step 3 G they refused at the call, because ps-flow's state is a
-- | PureScript record and nothing gave it upstream's shape. `Boundary.Store`
-- | does now: every member in upstream's shape, the consumer's own objects
-- | where ps-flow kept them, and zustand's `setState` and `subscribe`. The
-- | selection runs through `React.Hook.Store.useStoreWith`, the hook every
-- | internal component reads the store through, with the consumer's
-- | `equalityFn` or `Object.is` in place of an `Eq` instance.
module Boundary.Hooks
  ( JsEdgesState
  , JsNodeConnectionsParams
  , JsNodeData
  , JsNodesState
  , JsTriple
  , JsUseHandleConnectionsParams
  , JsUseKeyPressOptions
  , JsUseNodesInitializedOptions
  , JsUseOnSelectionChangeOptions
  , JsUseOnViewportChangeOptions
  , experimental_useOnEdgesChangeMiddleware
  , experimental_useOnNodesChangeMiddleware
  , useConnection
  , useEdges
  , useEdgesState
  , useHandleConnections
  , useInternalNode
  , useKeyPress
  , useNodeConnections
  , useNodeId
  , useNodes
  , useNodesData
  , useNodesInitialized
  , useNodesState
  , useOnSelectionChange
  , useOnViewportChange
  , useReactFlow
  , useStore
  , useStoreApi
  , useUpdateNodeInternals
  , useViewport
  ) where

import Prelude
import React.Types.General (OnSelectionChangeFunc, OnViewportChange)

import Boundary.Callbacks
  ( JsConnectionState
  , JsOnSelectionChange
  , JsOnViewportChange
  , connectionStateOut
  , onSelectionChangeIn
  , onViewportChangeIn
  , withInProgress
  )
import Boundary.Elements
  ( JsConnection
  , JsEdge
  , JsEdgeChange
  , JsInternalNode
  , JsNode
  , JsNodeChange
  , JsViewport
  , connectionOut
  , edgeChangeIn
  , edgeChangeOut
  , edgeIn
  , edgeOut
  , keyCodeValueIn
  , nodeChangeIn
  , nodeChangeOut
  , nodeIn
  , nodeOut
  , viewportOut
  )
import Boundary.Enums (handleTypeIn)
import Boundary.Original (remembering, stably)
import Boundary.Store
  ( JsStoreApi
  , equalityFor
  , internalNodeOutCached
  , selectorThrough
  , storeViewOf
  , useStoreApiObject
  )
import Boundary.Instance
  ( JsHandleConnection
  , JsReactFlowInstance
  , handleConnectionOut
  , instanceOut
  )
import Boundary.SetState (setStateOut)
import Boundary.Undefined (Undefinable, fromUndefinable, toUndefinable)
import Boundary.Untagged (asArray, asString, oneOrMany, typeName)
import Data.Array (head) as Array
import Data.Function.Uncurried (Fn3, runFn3)
import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe, isJust, maybe)
import Data.Newtype (wrap)
import Data.Nullable (Nullable, toNullable)
import Effect (Effect)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried
  ( EffectFn1
  , EffectFn2
  , mkEffectFn1
  , mkEffectFn2
  , runEffectFn1
  )
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign, isNull, unsafeToForeign)
import React.Basic.Hooks (Render)
import React.Context.NodeId (useNodeId) as PS
import React.Hook.HandleConnections (useHandleConnections) as PS
import React.Hook.KeyPress (KeyPressTarget(..), UseKeyPressOptions, defaultUseKeyPressOptions, useKeyPress) as PS
import React.Hook.Middleware
  ( useOnEdgesChangeMiddleware
  , useOnNodesChangeMiddleware
  ) as PS
import React.Hook.NodeConnections (useNodeConnections) as PS
import React.Hook.NodesEdgesState (useEdgesState, useNodesState) as PS
import React.Hook.ReactFlow (useReactFlow) as PS
import React.Hook.Selectors
  ( selectConnection
  , selectNodesData
  , selectViewport
  , useNodesInitialized
  ) as PS
import React.Hook.Listeners (useOnSelectionChange, useOnViewportChange) as PS
import React.Hook.Store (sameValue, shallow)
import React.Hook.Store (useStoreApi, useStoreWith) as PS
import React.Store.Shell (Store)
import React.Hook.UpdateNodeInternals (useUpdateNodeInternals) as PS
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import React.Types.Store (ReactFlowState)
import System.Types.Connection
  ( Connection
  , ConnectionState(..)
  , NodeConnection
  )
import System.Types.Edge (EdgeChange)
import System.Types.Ids (NodeId)
import System.Types.Node (InternalNodeBase, NodeChange)
import System.Utils.ShallowNodeData (NodeSummary, shallowNodeData)
import Unsafe.Coerce (unsafeCoerce)

-- ────────────────────────────────────────────────────────────────────────
-- Running a hook
-- ────────────────────────────────────────────────────────────────────────

-- | See the module header: a `Hook` is a `Render`, which is a newtype over
-- | `Effect`, and React's rules are what make running one here safe.
runHook :: forall hooks newHook a. Render hooks newHook a -> Effect a
runHook = unsafeCoerce

-- | The flow's state with a JavaScript consumer's data in it. The store holds
-- | the data as it came, so a selector reads it as `Foreign`.
type JsState = ReactFlowState Foreign Foreign

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

-- | Upstream reads `target` and `actInsideInputWithModifier` with `??`, so
-- | `null` takes the default as absence does, and `preventDefault` with
-- | `!== false`, so only `false` turns it off.
type JsUseKeyPressOptions =
  { target :: Undefinable Foreign
  , actInsideInputWithModifier :: Undefinable Foreign
  , preventDefault :: Undefinable Foreign
  }

type JsUseNodesInitializedOptions = { includeHiddenNodes :: Undefinable Boolean }

type JsUseOnViewportChangeOptions =
  { onStart :: Undefinable JsOnViewportChange
  , onChange :: Undefinable JsOnViewportChange
  , onEnd :: Undefinable JsOnViewportChange
  }

type JsUseOnSelectionChangeOptions = { onChange :: Undefinable JsOnSelectionChange }

-- | `useHandleConnections`' parameter. The rename is the one every nested type
-- | tag on this surface carries — PureScript keeps `type` for the element's own
-- | tag — and the handlers take plain `Connection`s here where
-- | `useNodeConnections`' take `NodeConnection`s, which is upstream's
-- | inconsistency and not ps-flow's.
type JsUseHandleConnectionsParams =
  { "type" :: String
  , id :: Undefinable String
  , nodeId :: Undefinable String
  , onConnect :: Undefinable (EffectFn1 (Array JsConnection) Unit)
  , onDisconnect :: Undefinable (EffectFn1 (Array JsConnection) Unit)
  }

-- | `useNodeConnections`' parameter. Upstream calls the node id `id` on this
-- | one and `nodeId` on the hook above; ps-flow calls it `nodeId` on both, so
-- | this is the second rename and it points the other way.
type JsNodeConnectionsParams =
  { id :: Undefinable String
  , handleType :: Undefinable String
  , handleId :: Undefinable String
  , onConnect :: Undefinable (EffectFn1 (Array JsHandleConnection) Unit)
  , onDisconnect :: Undefinable (EffectFn1 (Array JsHandleConnection) Unit)
  }

-- | Upstream's `DistributivePick<Node, 'id' | 'type' | 'data'>` — three fields
-- | of a node and no more, which is what `useNodesData` answers with.
type JsNodeData =
  { id :: String
  , "type" :: Undefinable String
  , data :: Foreign
  }

-- ────────────────────────────────────────────────────────────────────────
-- useNodesState / useEdgesState  (stage 1)
-- ────────────────────────────────────────────────────────────────────────
--
-- Upstream's return is positional, so there is no JS-shaped *record* here for
-- `parity/boundary/drift.mjs` to compare labels against. The equivalent guard
-- is a type: `nodesTripleOut` takes a **closed** record spelling the bundle's
-- three fields, so a fourth field added to `NodesStateBundle` fails to unify
-- and the build stops. Same claim as the drift gate's, made by the compiler
-- instead of by a script.

useNodesState :: EffectFn1 (Array JsNode) JsNodesState
useNodesState = mkEffectFn1 \initialNodes ->
  nodesTripleOut <$> runHook (PS.useNodesState (map nodeIn initialNodes))

-- | The closed record is the staleness guard — see above.
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

useEdgesState :: EffectFn1 (Array JsEdge) JsEdgesState
useEdgesState = mkEffectFn1 \initialEdges ->
  edgesTripleOut <$> runHook (PS.useEdgesState (map edgeIn initialEdges))

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
-- The instance, and the hook that returns it
-- ────────────────────────────────────────────────────────────────────────

-- | `Effect` and not a bare value: a nullary PureScript binding is evaluated
-- | once when the module loads, which for a hook would mean calling
-- | `useStoreApi` outside a render. `Effect a` compiles to `() => a`, which is
-- | upstream's arity and runs on the call.
useReactFlow :: Effect JsReactFlowInstance
useReactFlow = instanceOut <$> runHook PS.useReactFlow

-- ────────────────────────────────────────────────────────────────────────
-- The store-slice hooks
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream's `useStore((s) => s.nodes, shallow)`. The selector reads the
-- | view `useStore` hands a consumer, so the answer is the array
-- | `getState().nodes` holds, which is the consumer's own when they passed it.
useNodes :: Effect (Array JsNode)
useNodes = unsafeCoerce <$> throughView readNodes
  where
  readNodes :: { nodes :: Foreign } -> Foreign
  readNodes = _.nodes

-- | Upstream's `useStore((s) => s.edges, shallow)`, as `useNodes` reads it.
useEdges :: Effect (Array JsEdge)
useEdges = unsafeCoerce <$> throughView readEdges
  where
  readEdges :: { edges :: Foreign } -> Foreign
  readEdges = _.edges

-- | `useStore(selector, shallow)` with a selector over the state a consumer
-- | reads. The view keeps one adapter per selector, so `read` is a top-level
-- | function and the selection memo survives a render.
throughView :: forall view. (view -> Foreign) -> Effect Foreign
throughView read = do
  store <- runHook PS.useStoreApi
  let view = storeViewOf (store :: Store Foreign Foreign)
  runHook (PS.useStoreWith (selectorThrough view (toUndefinable (Just (unsafeToForeign read)))) shallow)

-- | Upstream's `useStore(viewportSelector, shallow)`: `{ x, y, zoom }`, a new
-- | object per state, and the one read before while all three are the same
-- | by `Object.is`.
useViewport :: Effect JsViewport
useViewport = runHook (PS.useStoreWith selectViewportOut shallow)

selectViewportOut :: JsState -> JsViewport
selectViewportOut = viewportOut <<< PS.selectViewport

-- | Upstream's `options` parameter has a default, so it is optional at the
-- | call site and `includeHiddenNodes` defaults to `false`.
useNodesInitialized :: EffectFn1 (Undefinable JsUseNodesInitializedOptions) Boolean
useNodesInitialized = mkEffectFn1 \options ->
  runHook
    ( PS.useNodesInitialized
        { includeHiddenNodes: fromMaybe false (member options _.includeHiddenNodes) }
    )

-- | Upstream's `useStore((s) => s.nodeLookup.get(id), shallow)`. The answer
-- | is the internal node `getState().nodeLookup` holds, the same object for
-- | as long as the store keeps the node.
useInternalNode :: EffectFn1 String (Undefinable JsInternalNode)
useInternalNode = mkEffectFn1 \id -> runHook (PS.useStoreWith (selectInternalNode (wrap id)) shallow)
  where
  selectInternalNode :: NodeId -> JsState -> Undefinable JsInternalNode
  selectInternalNode id s =
    toUndefinable (map (unsafeCoerce <<< internalNodeOutCached) (Map.lookup id s.nodeLookup))

-- | `string | string[]`, and the shape of the answer follows the shape of the
-- | argument: upstream's two overloads return a single pick-or-`null` for one
-- | id and an array for an array.
-- |
-- | The three fields are upstream's `DistributivePick`, built in the selector
-- | so that `sameNodeData` compares what the consumer reads.
useNodesData :: EffectFn1 Foreign Foreign
useNodesData = mkEffectFn1 \ids ->
  let
    requested = map (wrap <<< readNodeId "useNodesData") (oneOrMany ids)

    picks :: JsState -> Array JsNodeData
    picks s = map nodeDataOut (PS.selectNodesData requested s)

    select :: JsState -> Foreign
    select
      | isJust (asArray ids) = unsafeToForeign <<< picks
      | otherwise = unsafeToForeign <<< toNullable <<< Array.head <<< picks
  in
    runHook (PS.useStoreWith select sameNodeData)

nodeDataOut :: NodeSummary Foreign -> JsNodeData
nodeDataOut n =
  { id: n.id
  , "type": toUndefinable n.nodeType
  , data: n.data
  }

-- | Upstream's `shallowNodeData`, over the answer a consumer reads. `null` is
-- | never the same as anything, a single pick compares as an array of one,
-- | and `data` compares by `Object.is`.
sameNodeData :: Foreign -> Foreign -> Boolean
sameNodeData a b = shallowNodeData (summariesIn a) (summariesIn b)
  where
  summariesIn v
    | isNull v = Nothing
    | otherwise = Just (map summaryIn (fromMaybe [ v ] (asArray v)))

  summaryIn v =
    let
      pick = unsafeCoerce v :: JsNodeData
    in
      { id: pick.id, nodeType: fromUndefinable pick."type", data: SameValue pick.data }

-- | A consumer's value, equal to another only by `Object.is`.
newtype SameValue = SameValue Foreign

instance eqSameValue :: Eq SameValue where
  eq (SameValue a) (SameValue b) = sameValue a b

-- | Upstream's `useConnection(selector?)`: with no selector it answers the
-- | whole `ConnectionState`, and with one it answers the projection.
-- |
-- | ps-flow's PureScript surface splits that overload into two hooks. Both
-- | forms are served here by upstream's `storeSelector`, which is
-- | `selectConnection`. Either way the consumer's function is handed the
-- | **JS-shaped** state —
-- | the same object `onConnectEnd` receives — rather than the PureScript sum
-- | type it would otherwise see.
-- |
-- | The result is compared with zustand's `shallow`, as upstream's
-- | `useConnection` compares it: one level of keys by `Object.is`. The state
-- | is a fresh object on every read, so reference equality would never hold,
-- | and the hook would re-render on every store update and again whenever
-- | React re-reads the selection after a commit. A projection that returns a
-- | fresh nested object still re-renders each time, upstream's too.
useConnection :: EffectFn1 (Undefinable (EffectFn1 JsConnectionState Foreign)) Foreign
useConnection = mkEffectFn1 \selector ->
  let
    project :: JsConnectionState -> Foreign
    project = case fromUndefinable selector of
      Nothing -> unsafeToForeign
      Just f -> \state -> unsafePerformEffect (runEffectFn1 f state)
  in
    runHook (PS.useStoreWith (project <<< stateOut <<< selectConnectionOf) shallow)
  where
  selectConnectionOf :: JsState -> ConnectionState (InternalNodeBase Foreign)
  selectConnectionOf = PS.selectConnection

  -- Upstream's `ConnectionState`, so `inProgress` leads, as the store's own
  -- `connection` member has it. A connection in progress always has a
  -- `toPosition`; only the final state `onConnectEnd` receives drops it.
  stateOut :: ConnectionState (InternalNodeBase Foreign) -> JsConnectionState
  stateOut = case _ of
    NoConnection -> unsafeCoerce (withInProgress false (connectionStateOut Nothing))
    ConnectionInProgress inProgress ->
      unsafeCoerce
        (withInProgress true (connectionStateOut (Just inProgress { toPosition = Just inProgress.toPosition })))

-- ────────────────────────────────────────────────────────────────────────
-- The listener hooks
-- ────────────────────────────────────────────────────────────────────────

useOnViewportChange :: EffectFn1 JsUseOnViewportChangeOptions Unit
useOnViewportChange = mkEffectFn1 \options ->
  runHook
    ( PS.useOnViewportChange
        { onStart: map stableViewportChangeIn (fromUndefinable options.onStart)
        , onChange: map stableViewportChangeIn (fromUndefinable options.onChange)
        , onEnd: map stableViewportChangeIn (fromUndefinable options.onEnd)
        }
    )

-- | Dependency identity belongs to the consumer callback. Preserve the
-- | existing conversion while giving the same function the same adapter.
stableViewportChangeIn :: JsOnViewportChange -> OnViewportChange
stableViewportChangeIn = cacheCallback (remembering onViewportChangeIn)

foreign import cacheCallback :: forall a b. (a -> b) -> a -> b

useOnSelectionChange :: EffectFn1 JsUseOnSelectionChangeOptions Unit
useOnSelectionChange = mkEffectFn1 \options ->
  runHook
    ( PS.useOnSelectionChange
        { onChange: map stableSelectionChangeIn (fromUndefinable options.onChange) }
    )

-- | The same consumer handler converts to the same PureScript function, so
-- | the listener's `[onChange]` dependency holds across renders, and the
-- | store's handler list reads back as the consumer's own function.
stableSelectionChangeIn :: JsOnSelectionChange -> OnSelectionChangeFunc Foreign Foreign
stableSelectionChangeIn = cacheCallback (remembering onSelectionChangeIn)

-- ────────────────────────────────────────────────────────────────────────
-- The connection-query hooks
-- ────────────────────────────────────────────────────────────────────────

useHandleConnections :: EffectFn1 JsUseHandleConnectionsParams (Array JsHandleConnection)
useHandleConnections = mkEffectFn1 \params ->
  map handleConnectionOut <$>
    runHook
      ( PS.useHandleConnections
          { handleType: handleTypeIn "useHandleConnections.type" params."type"
          , id: fromUndefinable params.id
          , nodeId: fromUndefinable params.nodeId
          , onConnect: map connectionsHandler (fromUndefinable params.onConnect)
          , onDisconnect: map connectionsHandler (fromUndefinable params.onDisconnect)
          }
      )

-- | Upstream's parameter is optional — it destructures with a `= {}` default —
-- | so a custom node calling `useNodeConnections()` bare gets the node id from
-- | the surrounding context, which is the common case.
useNodeConnections
  :: EffectFn1 (Undefinable JsNodeConnectionsParams) (Array JsHandleConnection)
useNodeConnections = mkEffectFn1 \params ->
  map handleConnectionOut <$>
    runHook
      ( PS.useNodeConnections
          { nodeId: member params _.id
          , handleType:
              map (handleTypeIn "useNodeConnections.handleType")
                (member params _.handleType)
          , handleId: member params _.handleId
          , onConnect: map nodeConnectionsHandler (member params _.onConnect)
          , onDisconnect: map nodeConnectionsHandler (member params _.onDisconnect)
          }
      )

-- | `useHandleConnections`' handlers take plain `Connection`s where
-- | `useNodeConnections`' take `NodeConnection`s. That is upstream's own
-- | inconsistency between two hooks that answer the same question, and it is
-- | reproduced rather than tidied.
connectionsHandler
  :: EffectFn1 (Array JsConnection) Unit
  -> Array Connection
  -> Effect Unit
connectionsHandler f = \connections -> runEffectFn1 f (map connectionOut connections)

nodeConnectionsHandler
  :: EffectFn1 (Array JsHandleConnection) Unit
  -> Array NodeConnection
  -> Effect Unit
nodeConnectionsHandler f = \connections -> runEffectFn1 f (map handleConnectionOut connections)

-- ────────────────────────────────────────────────────────────────────────
-- The rest
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream returns `(id: string | string[]) => void`; ps-flow's takes the
-- | array only, which is the wider of the two.
useUpdateNodeInternals :: Effect (EffectFn1 Foreign Unit)
useUpdateNodeInternals = do
  update <- runHook PS.useUpdateNodeInternals
  pure (mkEffectFn1 \ids -> update (map (readNodeId "useUpdateNodeInternals") (oneOrMany ids)))

-- | Both parameters are optional upstream, and the first *defaults to `null`* —
-- | which is why the key code is read with `keyCodeValueIn` rather than the
-- | null-refusing `keyCodeIn` the five key-code props use. See that function's
-- | own note: on a prop, `null` and absent differ; here they cannot.
useKeyPress :: EffectFn2 (Undefinable Foreign) (Undefinable JsUseKeyPressOptions) Boolean
useKeyPress = mkEffectFn2 \keyCode options ->
  runHook
    ( PS.useKeyPress
        (map (keyCodeValueIn "useKeyPress") (fromUndefinable keyCode))
        (maybe PS.defaultUseKeyPressOptions keyPressOptionsIn (fromUndefinable options))
    )

keyPressOptionsIn :: JsUseKeyPressOptions -> PS.UseKeyPressOptions
keyPressOptionsIn o =
  { target: maybe PS.OnDocument (PS.On <<< unsafeCoerce) (nullish o.target)
  , actInsideInputWithModifier: maybe true (unsafeCoerce :: Foreign -> Boolean) (nullish o.actInsideInputWithModifier)
  , preventDefault: not (strictlyFalse o.preventDefault)
  }
  where
  nullish :: Undefinable Foreign -> Maybe Foreign
  nullish u = case fromUndefinable u of
    Just v | not (isNull v) -> Just v
    _ -> Nothing

  strictlyFalse :: Undefinable Foreign -> Boolean
  strictlyFalse u = case fromUndefinable u of
    Just v -> sameValue v (unsafeToForeign false)
    Nothing -> false

-- | `string | null` — upstream's `NodeIdContext` defaults to `null` and not to
-- | `undefined`, so this is the one place on the surface where `Nullable` is
-- | right and `Undefinable` is not.
useNodeId :: Effect (Nullable String)
useNodeId = toNullable <$> runHook PS.useNodeId

experimental_useOnNodesChangeMiddleware
  :: EffectFn1 (EffectFn1 (Array JsNodeChange) (Array JsNodeChange)) Unit
experimental_useOnNodesChangeMiddleware = mkEffectFn1 \middleware ->
  runHook (PS.useOnNodesChangeMiddleware (stably "useOnNodesChangeMiddleware" nodesMiddlewareIn middleware))

-- | One adapter per consumer function. Upstream's effect depends on the
-- | consumer's `fn`, so a stable one registers once; an adapter made on each
-- | render would remove and re-add the middleware after every render, and
-- | each of those store writes notifies every subscriber.
nodesMiddlewareIn
  :: EffectFn1 (Array JsNodeChange) (Array JsNodeChange)
  -> Array (NodeChange Foreign)
  -> Array (NodeChange Foreign)
nodesMiddlewareIn middleware changes =
  map nodeChangeIn
    (unsafePerformEffect (runEffectFn1 middleware (map nodeChangeOut changes)))

experimental_useOnEdgesChangeMiddleware
  :: EffectFn1 (EffectFn1 (Array JsEdgeChange) (Array JsEdgeChange)) Unit
experimental_useOnEdgesChangeMiddleware = mkEffectFn1 \middleware ->
  runHook (PS.useOnEdgesChangeMiddleware (stably "useOnEdgesChangeMiddleware" edgesMiddlewareIn middleware))

edgesMiddlewareIn
  :: EffectFn1 (Array JsEdgeChange) (Array JsEdgeChange)
  -> Array (EdgeChange Foreign)
  -> Array (EdgeChange Foreign)
edgesMiddlewareIn middleware changes =
  map edgeChangeIn
    (unsafePerformEffect (runEffectFn1 middleware (map edgeChangeOut changes)))

-- ────────────────────────────────────────────────────────────────────────
-- The store
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream's `useStore(selector, equalityFn?)`. The selector reads the
-- | state's JavaScript view; with no selector the hook answers the whole
-- | view, as zustand's identity default does.
useStore :: EffectFn2 (Undefinable Foreign) (Undefinable Foreign) Foreign
useStore = mkEffectFn2 \selector equalityFn -> do
  store <- runHook PS.useStoreApi
  let view = storeViewOf (store :: Store Foreign Foreign)
  runHook (PS.useStoreWith (selectorThrough view selector) (equalityFor equalityFn))

-- | Upstream's `useStoreApi()`: `{ getState, setState, subscribe }`, one
-- | object per component holding the store's three functions.
-- |
-- | `Effect` and not a bare value, as `useReactFlow` is: a nullary binding
-- | would run when `index.js` was imported, outside any render.
useStoreApi :: Effect JsStoreApi
useStoreApi = do
  store <- runHook PS.useStoreApi
  runEffectFn1 useStoreApiObject (storeViewOf (store :: Store Foreign Foreign))

-- ────────────────────────────────────────────────────────────────────────
-- Small helpers
-- ────────────────────────────────────────────────────────────────────────

-- | One member of an options bag that may itself be absent — the two `Maybe`s
-- | flattened, which is what upstream's `options?.member` means.
member :: forall bag a. Undefinable bag -> (bag -> Undefinable a) -> Maybe a
member bag get = fromUndefinable bag >>= (get >>> fromUndefinable)

readNodeId :: String -> Foreign -> String
readNodeId field raw = case asString raw of
  Just id -> id
  Nothing ->
    unsafeThrow $
      "ps-flow: `" <> field <> "` takes a node id or an array of them, got "
        <> typeName raw
        <> "."
