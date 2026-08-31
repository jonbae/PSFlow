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
-- | ## The `Eq` a consumer's data gets
-- |
-- | Six of the hooks are constrained `Eq n` or `Eq e`, because they subscribe
-- | to a store slice and re-render when it changes. A JavaScript consumer's
-- | node data is `Foreign`, which has no `Eq`, so this module supplies one:
-- | `React.Basic.Hooks.UnsafeReference`, whose instance is JavaScript
-- | reference equality. That is deliberate rather than a workaround — upstream
-- | compares these slices with zustand's `shallow`, which is `Object.is` per
-- | element, so reference equality on the leaf is nearer upstream than a
-- | structural comparison would be. It is not *identical* to upstream, which
-- | compares the whole node object by identity; the difference is recorded on
-- | the divergence backlog.
-- |
-- | ## The two that do not cross
-- |
-- | `useStore` and `useStoreApi` hand the consumer the **internal store
-- | state** — an 85-field PureScript record whose `nodeLookup` is a
-- | `Data.Map` where upstream's is a JavaScript `Map`, and whose `transform`
-- | is a newtype where upstream's is a three-element array. There is no
-- | `JsReactFlowState` and building one is not this stage's work.
-- |
-- | So they cross as far as their *shape* — arity and callability, which is
-- | what `parity/surface/diff.mjs` compares — and **refuse at the call**, with
-- | a message naming what has not crossed. The alternative was to hand the
-- | PureScript state over raw, which is worse than it looks: a consumer's
-- | `(s) => s.nodes.length` would work, because a PureScript `Array` *is* a
-- | JavaScript array, while `(s) => s.nodeLookup.get(id)` would return
-- | `undefined` forever. A surface that is right often enough to be trusted
-- | and wrong without saying so is the failure this whole module exists to
-- | remove.
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

import Boundary.Callbacks
  ( JsConnectionState
  , JsOnSelectionChange
  , JsOnViewportChange
  , connectionStateOut
  , onSelectionChangeIn
  , onViewportChangeIn
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
  , internalNodeOut
  , keyCodeValueIn
  , nodeChangeIn
  , nodeChangeOut
  , nodeIn
  , nodeOut
  , viewportOut
  )
import Boundary.Enums (handleTypeIn)
import Boundary.Instance
  ( JsHandleConnection
  , JsReactFlowInstance
  , handleConnectionOut
  , instanceOut
  )
import Boundary.SetState (setStateOut)
import Boundary.Undefined (Undefinable, fromUndefinable, toUndefinable)
import Boundary.Untagged (asArray, asString, oneOrMany, typeName)
import Data.Function.Uncurried (Fn3, runFn3)
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Newtype (unwrap, wrap)
import Data.Nullable (Nullable, toNullable)
import Effect (Effect)
import Effect.Exception (throw)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried
  ( EffectFn1
  , EffectFn2
  , mkEffectFn1
  , mkEffectFn2
  , runEffectFn1
  )
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign, unsafeToForeign)
import React.Basic.Hooks (Render, UnsafeReference(..))
import React.Context.NodeId (useNodeId) as PS
import React.Hook.HandleConnections (useHandleConnections) as PS
import React.Hook.KeyPress (useKeyPress) as PS
import React.Hook.Middleware
  ( useOnEdgesChangeMiddleware
  , useOnNodesChangeMiddleware
  ) as PS
import React.Hook.NodeConnections (useNodeConnections) as PS
import React.Hook.NodesEdgesState (useEdgesState, useNodesState) as PS
import React.Hook.ReactFlow (useReactFlow) as PS
import React.Hook.Selectors
  ( useConnectionWith
  , useEdges
  , useInternalNode
  , useNodes
  , useNodesData
  , useNodesInitialized
  , useViewport
  ) as PS
import React.Hook.Listeners (useOnSelectionChange, useOnViewportChange) as PS
import React.Hook.UpdateNodeInternals (useUpdateNodeInternals) as PS
import React.Types.Edges (Edge)
import React.Types.Nodes (InternalNode, Node)
import System.Types.Connection
  ( Connection
  , ConnectionState(..)
  , NodeConnection
  )
import System.Types.Edge (EdgeChange)
import System.Types.Node (InternalNodeBase, NodeChange)
import Unsafe.Coerce (unsafeCoerce)

-- ────────────────────────────────────────────────────────────────────────
-- Running a hook, and the `Eq` for consumer data
-- ────────────────────────────────────────────────────────────────────────

-- | See the module header: a `Hook` is a `Render`, which is a newtype over
-- | `Effect`, and React's rules are what make running one here safe.
runHook :: forall hooks newHook a. Render hooks newHook a -> Effect a
runHook = unsafeCoerce

-- | A consumer's node or edge data, carrying the `Eq` the store hooks need.
-- | `UnsafeReference` is a newtype, so this is `Foreign` at runtime and the
-- | coercions below move between the two views of the same value.
type JsData = UnsafeReference Foreign

-- | Read a slice back as `Foreign` once the hook has produced it. The
-- | `Eq` wrapper is a newtype, so this is the identity at runtime and its only
-- | job is to hand the converters the type they are written against.
transparent :: forall a b. a -> b
transparent = unsafeCoerce

-- | Each store hook pins its own `n` by the type of the `transparent` it is
-- | read through — the local signature is what chooses the `Eq` dictionary,
-- | and there is no shorter place to say it, because the hook-effect tag in
-- | `Hook`'s first parameter differs for every one of them.

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

type JsUseKeyPressOptions = { actInsideInputWithModifier :: Undefinable Boolean }

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

useNodes :: Effect (Array JsNode)
useNodes = map nodeOut <<< out <$> runHook PS.useNodes
  where
  out :: Array (Node JsData) -> Array (Node Foreign)
  out = transparent

useEdges :: Effect (Array JsEdge)
useEdges = map edgeOut <<< out <$> runHook PS.useEdges
  where
  out :: Array (Edge JsData) -> Array (Edge Foreign)
  out = transparent

useViewport :: Effect JsViewport
useViewport = viewportOut <$> runHook PS.useViewport

-- | Upstream's `options` parameter has a default, so it is optional at the
-- | call site and `includeHiddenNodes` defaults to `false`.
useNodesInitialized :: EffectFn1 (Undefinable JsUseNodesInitializedOptions) Boolean
useNodesInitialized = mkEffectFn1 \options ->
  runHook
    ( PS.useNodesInitialized
        { includeHiddenNodes: fromMaybe false (member options _.includeHiddenNodes) }
    )

useInternalNode :: EffectFn1 String (Undefinable JsInternalNode)
useInternalNode = mkEffectFn1 \id ->
  toUndefinable <<< map internalNodeOut <<< out <$> runHook (PS.useInternalNode (wrap id))
  where
  out :: Maybe (InternalNode JsData) -> Maybe (InternalNode Foreign)
  out = transparent

-- | `string | string[]`, and the shape of the answer follows the shape of the
-- | argument: upstream's two overloads return a single pick-or-`null` for one
-- | id and an array for an array. ps-flow's single `Array NodeId -> …`
-- | signature does not make that distinction and this restores it.
-- |
-- | The three fields are upstream's `DistributivePick`. ps-flow answers with
-- | whole internal nodes, so the narrowing to `{ id, type, data }` happens
-- | here — handing over the whole node would be a superset, and on a surface
-- | the net compares by every enumerable own property a superset is a
-- | divergence like any other.
useNodesData :: EffectFn1 Foreign Foreign
useNodesData = mkEffectFn1 \ids -> do
  let requested = oneOrMany ids
  found <- out <$> runHook (PS.useNodesData (map (wrap <<< readNodeId "useNodesData") requested))
  let picks = map nodeDataOut found
  pure
    if isJust (asArray ids) then unsafeToForeign picks
    else unsafeToForeign (toNullable (single picks))
  where
  out :: Array (InternalNode JsData) -> Array (InternalNode Foreign)
  out = transparent

  -- ps-flow drops ids it cannot find, so a single id that is not in the
  -- lookup comes back as an empty array and upstream's `null` is what that
  -- means.
  single picks = case picks of
    [ only ] -> Just only
    _ -> Nothing

nodeDataOut :: InternalNode Foreign -> JsNodeData
nodeDataOut n =
  { id: unwrap n.id
  , "type": toUndefinable n.nodeType
  , data: n.data
  }

-- | Upstream's `useConnection(selector?)`: with no selector it answers the
-- | whole `ConnectionState`, and with one it answers the projection.
-- |
-- | ps-flow splits that overload into two hooks and exports only the nullary
-- | one, so both forms are served here by the internal `useConnectionWith`.
-- | Either way the consumer's function is handed the **JS-shaped** state —
-- | the same object `onConnectEnd` receives — rather than the PureScript sum
-- | type it would otherwise see.
-- |
-- | The result is wrapped in `UnsafeReference` for the store hook's `Eq`, so
-- | a projection that returns a fresh object each render re-renders each
-- | render. That is upstream's behaviour too: its `useConnection` passes
-- | `shallow`, which compares one level, and a fresh nested object defeats it
-- | the same way.
useConnection :: EffectFn1 (Undefinable (EffectFn1 JsConnectionState Foreign)) Foreign
useConnection = mkEffectFn1 \selector ->
  let
    project :: JsConnectionState -> Foreign
    project = case fromUndefinable selector of
      Nothing -> unsafeToForeign
      Just f -> \state -> unsafePerformEffect (runEffectFn1 f state)
  in
    unwrap <$> runHook (PS.useConnectionWith (UnsafeReference <<< project <<< stateOut))
  where
  stateOut :: ConnectionState (InternalNodeBase Foreign) -> JsConnectionState
  stateOut = connectionStateOut <<< case _ of
    NoConnection -> Nothing
    ConnectionInProgress inProgress -> Just inProgress

-- ────────────────────────────────────────────────────────────────────────
-- The listener hooks
-- ────────────────────────────────────────────────────────────────────────

useOnViewportChange :: EffectFn1 JsUseOnViewportChangeOptions Unit
useOnViewportChange = mkEffectFn1 \options ->
  runHook
    ( PS.useOnViewportChange
        { onStart: map onViewportChangeIn (fromUndefinable options.onStart)
        , onChange: map onViewportChangeIn (fromUndefinable options.onChange)
        , onEnd: map onViewportChangeIn (fromUndefinable options.onEnd)
        }
    )

useOnSelectionChange :: EffectFn1 JsUseOnSelectionChangeOptions Unit
useOnSelectionChange = mkEffectFn1 \options ->
  runHook
    ( PS.useOnSelectionChange
        { onChange: map onSelectionChangeIn (fromUndefinable options.onChange) }
    )

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
        ( map
            (\o -> { actInsideInputWithModifier: fromMaybe false (fromUndefinable o.actInsideInputWithModifier) })
            (fromUndefinable options)
        )
    )

-- | `string | null` — upstream's `NodeIdContext` defaults to `null` and not to
-- | `undefined`, so this is the one place on the surface where `Nullable` is
-- | right and `Undefinable` is not.
useNodeId :: Effect (Nullable String)
useNodeId = toNullable <$> runHook PS.useNodeId

experimental_useOnNodesChangeMiddleware
  :: EffectFn1 (EffectFn1 (Array JsNodeChange) (Array JsNodeChange)) Unit
experimental_useOnNodesChangeMiddleware = mkEffectFn1 \middleware ->
  runHook
    ( PS.useOnNodesChangeMiddleware \changes ->
        map nodeChangeIn
          (unsafePerformEffect (runEffectFn1 middleware (map nodeChangeOut changes)))
    )

experimental_useOnEdgesChangeMiddleware
  :: EffectFn1 (EffectFn1 (Array JsEdgeChange) (Array JsEdgeChange)) Unit
experimental_useOnEdgesChangeMiddleware = mkEffectFn1 \middleware ->
  runHook
    ( PS.useOnEdgesChangeMiddleware \changes ->
        map edgeChangeIn
          (unsafePerformEffect (runEffectFn1 middleware (map edgeChangeOut changes)))
    )

-- ────────────────────────────────────────────────────────────────────────
-- The two that refuse
-- ────────────────────────────────────────────────────────────────────────
--
-- See the module header. Both are callable and both throw, because the value
-- they would hand over is the internal store state and no converter for it
-- exists. Their arity is upstream's, so `parity/surface/diff.mjs` sees them
-- agree; that they refuse is `parity/boundary/mount.mjs`'s to hold, by calling
-- each one and reading the message it throws.

-- | `Effect.Exception.throw` and not `unsafeThrow`: the refusal has to happen
-- | when the hook is *called*, and `useStoreApi` is nullary, so an
-- | `unsafeThrow` in its body would fire while `index.js` was being imported
-- | and take the whole surface down with it. `throw` builds an `Effect` that
-- | throws when run, which is the same thing one call later.
useStore :: EffectFn2 Foreign (Undefinable Foreign) Foreign
useStore = mkEffectFn2 \_ _ -> throw (storeRefusal "useStore")

useStoreApi :: Effect Foreign
useStoreApi = throw (storeRefusal "useStoreApi")

storeRefusal :: String -> String
storeRefusal name =
  "ps-flow: `" <> name
    <> "` has not crossed the JavaScript boundary — it hands over ps-flow's "
    <> "internal store state, which is a PureScript record and not upstream's "
    <> "object: `nodeLookup` is a `Data.Map` where upstream has a `Map`, "
    <> "`transform` is a newtype where upstream has `[x, y, zoom]`, and the "
    <> "other 83 fields are unconverted. It is refused rather than handed over "
    <> "raw so that the selectors which would silently answer `undefined` fail "
    <> "instead. `useReactFlow`, `useNodes`, `useEdges` and `useViewport` have "
    <> "crossed and reach most of the same state."

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
