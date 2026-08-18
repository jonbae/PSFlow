-- | The handlers, crossing — boundary stage 2.
-- |
-- | Stage 1 left every callback prop **refused at mount**. This module is what
-- | replaces those refusals: one JS-shaped type per handler, and one converter
-- | that turns a JavaScript function into the PureScript one the internals call.
-- |
-- | ## Why callbacks went before the larger chunks
-- |
-- | They are the only class of prop *nothing else can observe*. A handler that
-- | never fires leaves no residue in the DOM, so an end-state comparison of the
-- | two implementations passes green whether ps-flow called the consumer's
-- | function or not. Every other stage is at least visible to something.
-- |
-- | ## The direction that is not compiler-checked
-- |
-- | A callback crossing is inbound in the type — a JavaScript function comes in
-- | and a PureScript one goes out — and **outbound in the values**: every
-- | argument travels from ps-flow to the consumer. So the compiler forces each
-- | converter to produce a function of the right PureScript arity and nothing
-- | more; that the `JsNode` it hands over names every field a node has is
-- | `parity/boundary/drift.mjs`'s to check, exactly as it is for `nodeOut`.
-- |
-- | ## One invariant, which a gate reads
-- |
-- | **Every callback prop on this surface is typed by a synonym declared
-- | here.** `parity/boundary/mount.mjs` derives the list of callback props from
-- | this module's `type Js… =` declarations rather than from a list of its own,
-- | so a handler that crosses is checked by construction and a handler that is
-- | added later cannot be forgotten by the gate. A converter defined somewhere
-- | else would be invisible to it, which is why they all live here even when
-- | only one component uses them.
-- |
-- | ## What does not cross here
-- |
-- | `onInit` is a callback and is still refused, because its single argument is
-- | the imperative `ReactFlowInstance` — thirty methods whose converter is
-- | boundary stage 3's whole subject. Handing the PureScript instance to a
-- | JavaScript consumer would be the silent wrong shape this module exists to
-- | remove, so it is refused with the stage that lands it. It is the one
-- | callback prop whose refusal survives stage 2.
module Boundary.Callbacks
  ( JsCommandHandler
  , JsConnectStartParams
  , JsConnectionState
  , JsEdgeMouseHandler
  , JsInteractiveChangeHandler
  , JsIsValidConnection
  , JsMiniMapClickHandler
  , JsMouseEventHandler
  , JsNodeMouseHandler
  , JsOnBeforeDelete
  , JsOnConnect
  , JsOnConnectEnd
  , JsOnConnectStart
  , JsOnDelete
  , JsOnEdgesChange
  , JsOnEdgesDelete
  , JsOnError
  , JsOnMove
  , JsOnNodeDrag
  , JsOnNodesChange
  , JsOnNodesDelete
  , JsOnPaneScroll
  , JsOnReconnect
  , JsOnReconnectEnd
  , JsOnReconnectStart
  , JsOnResize
  , JsOnResizeEnd
  , JsOnResizeStart
  , JsOnScroll
  , JsOnSelectionChange
  , JsOnViewportChange
  , JsResizeParams
  , JsResizeParamsWithDirection
  , JsSelectionDragHandler
  , JsShouldResize
  , commandHandlerIn
  , edgeMouseHandlerIn
  , interactiveChangeHandlerIn
  , isValidConnectionIn
  , miniMapClickHandlerIn
  , mouseEventHandlerIn
  , nodeMouseHandlerIn
  , onBeforeDeleteIn
  , onConnectEndIn
  , onConnectIn
  , onConnectStartIn
  , onDeleteIn
  , onEdgesChangeIn
  , onEdgesDeleteIn
  , onErrorIn
  , onMoveIn
  , onNodeDragIn
  , onNodesChangeIn
  , onNodesDeleteIn
  , onPaneScrollIn
  , onReconnectEndIn
  , onReconnectIn
  , onReconnectStartIn
  , onResizeEndIn
  , onResizeIn
  , onResizeStartIn
  , onScrollIn
  , onSelectionChangeIn
  , onViewportChangeIn
  , selectionDragHandlerIn
  , shouldResizeIn
  ) where

import Prelude

import Boundary.Elements
  ( JsConnection
  , JsEdge
  , JsEdgeChange
  , JsGraphSelection
  , JsHandle
  , JsInternalNode
  , JsNode
  , JsNodeChange
  , JsViewport
  , JsXYPosition
  , connectionOut
  , edgeChangeOut
  , edgeIn
  , edgeOut
  , graphSelectionOut
  , handleOut
  , internalNodeOut
  , nodeChangeOut
  , nodeIn
  , nodeOut
  , viewportOut
  )
import Boundary.Enums (handleTypeOut, positionOut)
import Boundary.Undefined (Undefinable, toUndefinable)
import Boundary.Untagged (asBoolean, typeName)
import Data.Either (Either, either)
import Data.Function.Uncurried (Fn2, runFn2)
import Data.Int (toNumber) as Int
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Nullable (Nullable, notNull, null, toNullable)
import Effect (Effect)
import Effect.Aff.Compat (EffectFnAff(..), EffectFnCanceler, EffectFnCb, fromEffectFnAff)
import Effect.Class (liftEffect)
import Effect.Exception (Error)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried
  ( EffectFn1
  , EffectFn2
  , EffectFn3
  , EffectFn4
  , runEffectFn1
  , runEffectFn2
  , runEffectFn3
  , runEffectFn4
  )
import Foreign (Foreign, unsafeToForeign)
import React.Types.Edges (EdgeMouseHandler, OnReconnect)
import React.Types.General
  ( IsValidConnection
  , OnBeforeDelete
  , OnBeforeDeleteResult
  , OnDelete
  , OnEdgesChange
  , OnEdgesDelete
  , OnMove
  , OnNodesChange
  , OnNodesDelete
  , OnSelectionChangeFunc
  , OnViewportChange
  )
import React.Types.Nodes (NodeMouseHandler, OnNodeDrag, SelectionDragHandler)
import System.Types.Connection (FinalConnectionState)
import System.Types.Edge (EdgeBase)
import System.Types.Geometry (XYPosition)
import System.Types.Handle (HandleType)
import System.Types.Node (InternalNodeBase, OnError)
import System.XYHandle (OnConnect, OnConnectEnd, OnConnectStart, OnConnectStartParams)
import System.XYResizer
  ( OnResize
  , OnResizeEnd
  , OnResizeStart
  , ResizeDragEvent(..)
  , ResizeParams
  , ResizeParamsWithDirection
  , ShouldResize
  )
import Unsafe.Coerce (unsafeCoerce)
import Web.TouchEvent.TouchEvent (TouchEvent)
import Web.UIEvent.MouseEvent (MouseEvent)
import Web.UIEvent.WheelEvent (WheelEvent)

-- ────────────────────────────────────────────────────────────────────────
-- Events
-- ────────────────────────────────────────────────────────────────────────

-- | The event object a handler is handed.
-- |
-- | A coercion, and correctly so: the `MouseEvent` the internals carry *is*
-- | React's `SyntheticEvent` — `React.Component.NodeWrapper` and its siblings
-- | coerce the synthetic event into one on the way in and never read a DOM-only
-- | member of it. So what leaves here is the same object upstream would hand
-- | over, and there is nothing to translate.
eventOut :: forall event. event -> Foreign
eventOut = unsafeToForeign

-- | Upstream types the connection events `MouseEvent | TouchEvent`, which is
-- | untagged; PureScript needs the tag, so the internals carry an `Either` and
-- | both sides of it cross as the same object.
connectEventOut :: Either MouseEvent TouchEvent -> Foreign
connectEventOut = either eventOut eventOut

-- ────────────────────────────────────────────────────────────────────────
-- The shapes only a handler carries
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream's `OnConnectStartParams`. All three members are `T | null`, not
-- | `T | undefined` — the same place `Connection` puts `null` and for the same
-- | reason, so `Nullable` is right here too.
type JsConnectStartParams =
  { nodeId :: Nullable String
  , handleId :: Nullable String
  , handleType :: Nullable String
  }

connectStartParamsOut :: OnConnectStartParams -> JsConnectStartParams
connectStartParamsOut p =
  { nodeId: toNullable (map unwrap p.nodeId)
  , handleId: toNullable p.handleId
  , handleType: toNullable (map handleTypeOut p.handleType)
  }

-- | Upstream's `FinalConnectionState`, which is `ConnectionState` minus its
-- | `inProgress` discriminant: **one record either way**, whose members are all
-- | `null` when no connection was in progress.
-- |
-- | ps-flow models the same thing as `Maybe ConnectionInProgressData`, and the
-- | absent case is where the two shapes part company. `undefined`, or the
-- | absence of the argument, would be the obvious crossing and would be wrong:
-- | a consumer writing upstream's own `if (connectionState.isValid)` would
-- | throw rather than read `null`. So `Nothing` becomes the all-`null` record
-- | upstream ships as `initialConnection`.
type JsConnectionState =
  { isValid :: Nullable Boolean
  , from :: Nullable JsXYPosition
  , fromHandle :: Nullable JsHandle
  , fromPosition :: Nullable String
  , fromNode :: Nullable JsInternalNode
  , to :: Nullable JsXYPosition
  , toHandle :: Nullable JsHandle
  , toPosition :: Nullable String
  , toNode :: Nullable JsInternalNode
  , pointer :: Nullable JsXYPosition
  }

connectionStateOut :: FinalConnectionState (InternalNodeBase Foreign) -> JsConnectionState
connectionStateOut = case _ of
  Nothing -> noConnection
  Just c ->
    { isValid: toNullable c.isValid
    , from: notNull c.from
    , fromHandle: notNull (handleOut c.fromHandle)
    , fromPosition: notNull (positionOut c.fromPosition)
    , fromNode: notNull (internalNodeOut c.fromNode)
    , to: notNull c.to
    , toHandle: toNullable (map handleOut c.toHandle)
    , toPosition: notNull (positionOut c.toPosition)
    , toNode: toNullable (map internalNodeOut c.toNode)
    , pointer: notNull c.pointer
    }

-- | Upstream's `initialConnection`, minus `inProgress`. Written out rather than
-- | built from a fold so that a member added to `ConnectionInProgressData`
-- | fails to compile here as well as above.
noConnection :: JsConnectionState
noConnection =
  { isValid: null
  , from: null
  , fromHandle: null
  , fromPosition: null
  , fromNode: null
  , to: null
  , toHandle: null
  , toPosition: null
  , toNode: null
  , pointer: null
  }

-- | Upstream's `ResizeParams` and `ResizeParamsWithDirection`. The direction
-- | pair is `Int` in PureScript and `number` in JavaScript, which is the only
-- | field of either that is not already the same on both sides.
type JsResizeParams =
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  }

type JsResizeParamsWithDirection =
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  , direction :: { dx :: Number, dy :: Number }
  }

resizeParamsOut :: ResizeParams -> JsResizeParams
resizeParamsOut p = { x: p.x, y: p.y, width: p.width, height: p.height }

resizeParamsWithDirectionOut :: ResizeParamsWithDirection -> JsResizeParamsWithDirection
resizeParamsWithDirectionOut p =
  { x: p.x
  , y: p.y
  , width: p.width
  , height: p.height
  , direction:
      { dx: Int.toNumber p.direction.dx
      , dy: Int.toNumber p.direction.dy
      }
  }

-- ────────────────────────────────────────────────────────────────────────
-- The handler types, and their converters
--
-- One `type Js… =` per handler shape, because `parity/boundary/mount.mjs`
-- reads them to find out which props are callbacks. A prop typed inline would
-- be invisible to that gate.
-- ────────────────────────────────────────────────────────────────────────

type JsNodeMouseHandler = EffectFn2 Foreign JsNode Unit

nodeMouseHandlerIn :: JsNodeMouseHandler -> NodeMouseHandler Foreign
nodeMouseHandlerIn f = \event node -> runEffectFn2 f (eventOut event) (nodeOut node)

type JsOnNodeDrag = EffectFn3 Foreign JsNode (Array JsNode) Unit

onNodeDragIn :: JsOnNodeDrag -> OnNodeDrag Foreign
onNodeDragIn f = \event node nodes ->
  runEffectFn3 f (eventOut event) (nodeOut node) (map nodeOut nodes)

type JsEdgeMouseHandler = EffectFn2 Foreign JsEdge Unit

edgeMouseHandlerIn :: JsEdgeMouseHandler -> EdgeMouseHandler Foreign
edgeMouseHandlerIn f = \event edge -> runEffectFn2 f (eventOut event) (edgeOut edge)

type JsSelectionDragHandler = EffectFn2 Foreign (Array JsNode) Unit

selectionDragHandlerIn :: JsSelectionDragHandler -> SelectionDragHandler Foreign
selectionDragHandlerIn f = \event nodes -> runEffectFn2 f (eventOut event) (map nodeOut nodes)

type JsMouseEventHandler = EffectFn1 Foreign Unit

mouseEventHandlerIn :: JsMouseEventHandler -> (MouseEvent -> Effect Unit)
mouseEventHandlerIn f = \event -> runEffectFn1 f (eventOut event)

-- | `onScroll` on the flow's outer wrapper, and the one handler on this surface
-- | that loses an argument.
-- |
-- | Upstream's is `(event: React.UIEvent) => void`.
-- | `React.Types.Component.ReactFlowProps` declares ps-flow's as a bare
-- | `Effect Unit` and its own comment says why: the synthetic event is dropped
-- | so the prop stays callable from PureScript without an FFI bridge. There is
-- | therefore no event here to hand over, and a consumer's `(event) => …` is
-- | called with none — a gap in the internals, not something a converter can
-- | close, and it is a census row rather than a refusal because refusing would
-- | make a working handler an error.
-- |
-- | A PureScript `Effect Unit` is a nullary function at runtime and so is the
-- | consumer's, which is why this needs no wrapper at all.
type JsOnScroll = Effect Unit

onScrollIn :: JsOnScroll -> Effect Unit
onScrollIn = identity

-- | `(event?: React.WheelEvent) => void` — upstream's argument is optional, and
-- | it is `undefined` rather than `null` when the pane scrolled without one.
type JsOnPaneScroll = EffectFn1 (Undefinable Foreign) Unit

onPaneScrollIn :: JsOnPaneScroll -> (Maybe WheelEvent -> Effect Unit)
onPaneScrollIn f = \event -> runEffectFn1 f (toUndefinable (map eventOut event))

-- | The two change callbacks a controlled flow wires. They crossed in stage 1,
-- | with `<ReactFlow />` itself — a flow whose `onNodesChange` never fires does
-- | not move — but their types live here with the rest, because the invariant
-- | this module's header states is what `parity/boundary/mount.mjs` reads.
type JsOnNodesChange = EffectFn1 (Array JsNodeChange) Unit

onNodesChangeIn :: JsOnNodesChange -> OnNodesChange Foreign
onNodesChangeIn f = \changes -> runEffectFn1 f (map nodeChangeOut changes)

type JsOnEdgesChange = EffectFn1 (Array JsEdgeChange) Unit

onEdgesChangeIn :: JsOnEdgesChange -> OnEdgesChange Foreign
onEdgesChangeIn f = \changes -> runEffectFn1 f (map edgeChangeOut changes)

type JsOnNodesDelete = EffectFn1 (Array JsNode) Unit

onNodesDeleteIn :: JsOnNodesDelete -> OnNodesDelete Foreign
onNodesDeleteIn f = \nodes -> runEffectFn1 f (map nodeOut nodes)

type JsOnEdgesDelete = EffectFn1 (Array JsEdge) Unit

onEdgesDeleteIn :: JsOnEdgesDelete -> OnEdgesDelete Foreign
onEdgesDeleteIn f = \edges -> runEffectFn1 f (map edgeOut edges)

type JsOnDelete = EffectFn1 JsGraphSelection Unit

onDeleteIn :: JsOnDelete -> OnDelete Foreign Foreign
onDeleteIn f = \deleted -> runEffectFn1 f (graphSelectionOut deleted)

type JsOnSelectionChange = EffectFn1 JsGraphSelection Unit

onSelectionChangeIn :: JsOnSelectionChange -> OnSelectionChangeFunc Foreign Foreign
onSelectionChangeIn f = \params -> runEffectFn1 f (graphSelectionOut params)

type JsOnConnect = EffectFn1 JsConnection Unit

onConnectIn :: JsOnConnect -> OnConnect
onConnectIn f = \connection -> runEffectFn1 f (connectionOut connection)

type JsOnConnectStart = EffectFn2 Foreign JsConnectStartParams Unit

onConnectStartIn :: JsOnConnectStart -> OnConnectStart
onConnectStartIn f = \event params ->
  runEffectFn2 f (connectEventOut event) (connectStartParamsOut params)

type JsOnConnectEnd = EffectFn2 Foreign JsConnectionState Unit

onConnectEndIn :: JsOnConnectEnd -> OnConnectEnd Foreign
onConnectEndIn f = \event state ->
  runEffectFn2 f (connectEventOut event) (connectionStateOut state)

type JsOnReconnect = EffectFn2 JsEdge JsConnection Unit

onReconnectIn :: JsOnReconnect -> OnReconnect Foreign
onReconnectIn f = \oldEdge newConnection ->
  runEffectFn2 f (edgeOut oldEdge) (connectionOut newConnection)

type JsOnReconnectStart = EffectFn3 Foreign JsEdge String Unit

onReconnectStartIn
  :: JsOnReconnectStart
  -> (MouseEvent -> EdgeBase Foreign -> HandleType -> Effect Unit)
onReconnectStartIn f = \event edge handleType ->
  runEffectFn3 f (eventOut event) (edgeOut edge) (handleTypeOut handleType)

type JsOnReconnectEnd = EffectFn4 Foreign JsEdge String JsConnectionState Unit

onReconnectEndIn
  :: JsOnReconnectEnd
  -> ( MouseEvent
       -> EdgeBase Foreign
       -> HandleType
       -> FinalConnectionState (InternalNodeBase Foreign)
       -> Effect Unit
     )
onReconnectEndIn f = \event edge handleType state ->
  runEffectFn4 f (eventOut event) (edgeOut edge) (handleTypeOut handleType)
    (connectionStateOut state)

-- | `(event: MouseEvent | TouchEvent | null, viewport: Viewport) => void`. The
-- | event is `null` and not `undefined` when the viewport moved without one —
-- | a programmatic `fitView`, say — which is upstream's own type and the
-- | opposite choice from `onPaneScroll` two entries up.
type JsOnMove = EffectFn2 (Nullable Foreign) JsViewport Unit

onMoveIn :: JsOnMove -> OnMove
onMoveIn f = \event viewport ->
  runEffectFn2 f (toNullable (map eventOut event)) (viewportOut viewport)

type JsOnViewportChange = EffectFn1 JsViewport Unit

onViewportChangeIn :: JsOnViewportChange -> OnViewportChange
onViewportChangeIn f = \viewport -> runEffectFn1 f (viewportOut viewport)

type JsOnError = EffectFn2 String String Unit

onErrorIn :: JsOnError -> OnError
onErrorIn f = \id message -> runEffectFn2 f id message

-- | `<Controls />`'s three buttons. Upstream declares them `() => void`, which
-- | a PureScript `Effect Unit` already is at runtime.
type JsCommandHandler = Effect Unit

commandHandlerIn :: JsCommandHandler -> Effect Unit
commandHandlerIn = identity

type JsInteractiveChangeHandler = EffectFn1 Boolean Unit

interactiveChangeHandlerIn :: JsInteractiveChangeHandler -> (Boolean -> Effect Unit)
interactiveChangeHandlerIn f = \interactive -> runEffectFn1 f interactive

-- | `<MiniMap onClick>` — `(event, position) => void`, where the position is
-- | the flow coordinate the click landed on rather than a screen one.
type JsMiniMapClickHandler = EffectFn2 Foreign JsXYPosition Unit

miniMapClickHandlerIn :: JsMiniMapClickHandler -> (MouseEvent -> XYPosition -> Effect Unit)
miniMapClickHandlerIn f = \event position -> runEffectFn2 f (eventOut event) position

-- ────────────────────────────────────────────────────────────────────────
-- The two handlers that are not `… -> Effect Unit`
-- ────────────────────────────────────────────────────────────────────────

-- | `(edge: Edge | Connection) => boolean` — a **predicate**, called during a
-- | connection drag, so it is the one handler whose return value ps-flow reads.
-- |
-- | A JavaScript unary function returning a boolean *is* a
-- | `Foreign -> Boolean`, which is why there is no `EffectFn` here.
type JsIsValidConnection = Foreign -> Boolean

-- | The argument is upstream's untagged `Edge | Connection`, and which of the
-- | two it is carries meaning: an existing edge is being reconnected, or a new
-- | connection is being drawn. ps-flow's `IsValidConnection` hands the
-- | converter both halves — the connection fields, plus the edge when there is
-- | one — so the narrowing upstream erases is rebuilt here rather than guessed.
isValidConnectionIn :: forall e. JsIsValidConnection -> IsValidConnection e
isValidConnectionIn f = \candidate -> f (candidateOut candidate)
  where
  candidateOut c = case c.edge of
    Just edge -> unsafeToForeign (edgeOut edge)
    Nothing -> unsafeToForeign
      ( connectionOut
          { source: c.source
          , target: c.target
          , sourceHandle: c.sourceHandle
          , targetHandle: c.targetHandle
          }
      )

-- | `({ nodes, edges }) => Promise<boolean | { nodes, edges }>` — the one
-- | handler on this surface that answers, and the one whose answer is
-- | asynchronous.
type JsOnBeforeDelete = EffectFn1 JsGraphSelection Foreign

-- | `Promise` in, `Aff` out. The consumer may hand back a promise or the value
-- | itself: upstream `await`s the result, and `Promise.resolve` folds the two
-- | cases together the same way.
onBeforeDeleteIn :: JsOnBeforeDelete -> OnBeforeDelete Foreign Foreign
onBeforeDeleteIn f = \selection -> do
  answered <- liftEffect (runEffectFn1 f (graphSelectionOut selection))
  settled <- fromEffectFnAff (EffectFnAff (awaitPromise answered))
  pure (beforeDeleteResultIn settled)

-- | `boolean | { nodes, edges }`, narrowed. `true` means "delete what you were
-- | going to", `false` means "delete nothing", and the object narrows the set.
-- | ps-flow's own result record spells the first two as `allow` with no
-- | replacement lists, which is the shape `React.Hook.ReactFlow` reads.
beforeDeleteResultIn :: Foreign -> OnBeforeDeleteResult Foreign Foreign
beforeDeleteResultIn raw = case asBoolean raw of
  Just allow -> { allow, nodes: Nothing, edges: Nothing }
  -- The `typeName` guard is not decoration: `null` reaches here as readily as
  -- an object, and reading `.nodes` off it throws a `TypeError` that names
  -- neither the prop nor what it should have been handed.
  Nothing | typeName raw == "object" ->
    let
      bag = (unsafeCoerce raw) :: JsGraphSelection
    in
      case isArrayOf bag.nodes, isArrayOf bag.edges of
        true, true ->
          { allow: true
          , nodes: Just (map nodeIn bag.nodes)
          , edges: Just (map edgeIn bag.edges)
          }
        _, _ -> badBeforeDeleteResult raw
  Nothing -> badBeforeDeleteResult raw

badBeforeDeleteResult :: forall a. Foreign -> a
badBeforeDeleteResult raw =
  unsafeThrow $
    "ps-flow: `onBeforeDelete` must resolve to a boolean or to "
      <> "`{ nodes, edges }`, got "
      <> typeName raw
      <> "."

-- ────────────────────────────────────────────────────────────────────────
-- The resizer lifecycle
--
-- `<NodeResizer />` and `<NodeResizeControl />` hang their three lifecycle
-- handlers and their `shouldResize` predicate off the same four types, so the
-- converters are written once here and both components use them.
-- ────────────────────────────────────────────────────────────────────────

type JsOnResizeStart = EffectFn2 Foreign JsResizeParams Unit

onResizeStartIn :: JsOnResizeStart -> OnResizeStart
onResizeStartIn f = \event params ->
  runEffectFn2 f (resizeDragEventOut event) (resizeParamsOut params)

type JsOnResize = EffectFn2 Foreign JsResizeParamsWithDirection Unit

onResizeIn :: JsOnResize -> OnResize
onResizeIn f = \event params ->
  runEffectFn2 f (resizeDragEventOut event) (resizeParamsWithDirectionOut params)

type JsOnResizeEnd = EffectFn2 Foreign JsResizeParams Unit

onResizeEndIn :: JsOnResizeEnd -> OnResizeEnd
onResizeEndIn f = \event params ->
  runEffectFn2 f (resizeDragEventOut event) (resizeParamsOut params)

-- | `(event, params) => boolean`, and a predicate rather than a notification —
-- | returning `false` refuses the resize. Upstream's is synchronous, so the
-- | consumer's answer is lifted into the `Effect` ps-flow's own type asks for.
-- |
-- | `Fn2` and not `a -> b -> Boolean`: a curried PureScript function of two
-- | arguments is two nested calls at runtime, so `f(event)` on a consumer's
-- | `(event, params) => …` would return `undefined` and the second call would
-- | fail. `JsIsValidConnection` above is the one predicate a bare arrow is
-- | right for, because upstream's takes a single argument.
type JsShouldResize = Fn2 Foreign JsResizeParamsWithDirection Boolean

shouldResizeIn :: JsShouldResize -> ShouldResize
shouldResizeIn f = \event params ->
  pure (runFn2 f (resizeDragEventOut event) (resizeParamsWithDirectionOut params))

-- | `ResizeDragEvent` is a newtype over the d3 drag event, so unwrapping is
-- | the whole conversion — what the consumer gets is d3's own object, which is
-- | what upstream passes too.
resizeDragEventOut :: ResizeDragEvent -> Foreign
resizeDragEventOut (ResizeDragEvent raw) = raw

-- ────────────────────────────────────────────────────────────────────────
-- FFI
-- ────────────────────────────────────────────────────────────────────────

-- | Whether a value the consumer returned is really an array, checked per
-- | field so that `{ nodes: 3 }` is refused rather than iterated.
foreign import isArrayOf :: forall a. Array a -> Boolean

-- | `Promise` to the callback pair `Effect.Aff.Compat` expects. `aff-promise`
-- | is the package that does this, and it is not a dependency of this project;
-- | one promise on the whole surface does not earn one.
foreign import awaitPromise
  :: forall a
   . Foreign
  -> EffectFn2 (EffectFnCb Error) (EffectFnCb a) EffectFnCanceler
