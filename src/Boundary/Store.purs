-- | The store, crossing: what `useStore` and `useStoreApi` hand a JavaScript
-- | consumer.
-- |
-- | Upstream's `useStore(selector, equalityFn)` is zustand's
-- | `useStoreWithEqualityFn` over the flow's store, and its `useStoreApi()` is
-- | `{ getState, setState, subscribe }` from that store. Both expose the
-- | state itself: 85 members and 20 actions, read and written by the
-- | consumer's own code. ps-flow's state is a PureScript record whose
-- | `nodeLookup` is a `Data.Map`, whose `transform` is a newtype and whose
-- | callbacks are PureScript functions, so this module is the one place that
-- | state has a JavaScript shape.
-- |
-- | ## One converter per member, in both directions
-- |
-- | `stateFields` names every member of `ReactFlowState` with a `toJs` and a
-- | `fromJs`, typed by the member it converts. `parity/boundary/drift.mjs`
-- | compares `StateFields`' labels with the state's, so a member added to the
-- | state fails that gate until it has both.
-- | `toJs` hands back the consumer's own objects wherever ps-flow kept them:
-- | the nodes and edges they passed, the `defaultEdgeOptions` object, every
-- | callback. Upstream's store holds exactly those, and a selector compares
-- | what it reads by reference.
-- |
-- | ## What `Store.js` adds
-- |
-- | When a conversion runs, and the identities around it. A state's view is
-- | built once and converts each member on its first read, so a selector that
-- | reads `transform` never pays for `nodeLookup`. An unchanged member keeps
-- | its converted value across states, which is what lets
-- | `useStore((s) => s.nodes)` skip a render. A value read out of the store and
-- | written back converts to the PureScript value it came from.
-- |
-- | ## Writes
-- |
-- | `setState` is zustand's: a function partial is called with the state, the
-- | result is merged with `Object.assign` semantics, and every `subscribe`
-- | listener hears `(state, previousState)`. Keys that are not state members
-- | are kept beside the state, as upstream's object keeps them. A direct
-- | assignment, `getState().x = v`, writes into the live state and notifies
-- | nobody, which is what the same line does to upstream's plain object.
-- |
-- | `setState(next, true)`, or a partial that is not an object, replaces the
-- | state, and `getState()` then returns `next` itself: its member properties
-- | become accessors over the new PureScript state, in place. Each later
-- | state is `Object.assign({}, state, partial)` over it, so a member `next`
-- | left out stays out until something writes it.
-- |
-- | ## What a write leaves the internals
-- |
-- | Upstream's store is a plain object, so every value a consumer writes is
-- | stored as it is, and `getState()` here always reads it back. What
-- | ps-flow's internals receive depends on the member:
-- |
-- |   * A boolean, number or string member holds the written value itself,
-- |     whatever it is, and JavaScript coerces it where the internals use it,
-- |     as it coerces upstream's.
-- |   * A callback, `panZoom` or `fitViewResolver` is `Nothing` for `null` or
-- |     `undefined`, and otherwise the written value, called when it is used.
-- |     A value that is not a function throws then, as upstream's does.
-- |   * `connectionMode` and `zIndexMode` hold the mode upstream's
-- |     comparisons choose for the written value.
-- |   * Any other member holds the written value converted. When it cannot
-- |     convert, the internals keep the previous value, and development
-- |     builds say so.
-- |
-- | A callback that PureScript code installed has no JavaScript original, so
-- | it reads back as an adapter from `Boundary.Callbacks`, which JavaScript
-- | calls with upstream's arguments.
module Boundary.Store
  ( JsStoreApi
  , JsStoreView
  , storeViewOf
  , useStoreApiObject
  , selectorThrough
  , equalityFor
  , internalNodeOutCached
  , panZoomOut
  , registerChangeConvertersForJs
  ) where

import Prelude

import Boundary.Callbacks
  ( adaptedFrom
  , edgeChangeFromJs
  , edgeChangeIdentityOut
  , nodeChangeFromJs
  , nodeChangeIdentityOut
  , connectionStateOut
  , isValidConnectionIn
  , isValidConnectionOut
  , onBeforeDeleteIn
  , onBeforeDeleteOut
  , onConnectEndIn
  , onConnectEndOut
  , onConnectIn
  , onConnectOut
  , onConnectStartIn
  , onConnectStartOut
  , onDeleteIn
  , onDeleteOut
  , onEdgesChangeIn
  , onEdgesChangeOut
  , onEdgesDeleteIn
  , onEdgesDeleteOut
  , onErrorIn
  , onErrorOut
  , onMoveIn
  , onMoveOut
  , onNodeDragIn
  , onNodeDragOut
  , onNodesChangeIn
  , onNodesChangeOut
  , onNodesDeleteIn
  , onNodesDeleteOut
  , onSelectionChangeOut
  , onViewportChangeIn
  , onViewportChangeOut
  , selectionDragHandlerIn
  , selectionDragHandlerOut
  , stableSelectionChangeIn
  , withInProgress
  )
import Boundary.Elements
  ( JsEdgeChange
  , JsInternalNode
  , JsHandle
  , JsNodeChange
  , JsXYPosition
  , coordinateExtentIn
  , coordinateExtentOut
  , defaultEdgeOptionsIn
  , defaultEdgeOptionsOut
  , edgeIdentityOut
  , edgeIn
  , handleIn
  , internalNodeIn
  , internalNodeOut
  , nodeExtentIn
  , nodeIdentityOut
  , nodeIn
  , nodeOriginIn
  , nodeOriginOut
  , snapGridIn
  )
import Boundary.Enums (handleTypeIn, interpolateModeIn, panOnScrollModeIn, positionIn)
import Boundary.FitView (JsFitViewOptions, fitViewOptionsIn)
import Boundary.FlowMembers (JsAriaLabelConfig, ariaLabelConfigIn, panOnDragIn)
import Boundary.Instance (JsHandleConnection, handleConnectionOut, setCenterOptionsIn)
import Boundary.Original (originalOf, remembering)
import Boundary.Promise (toPromise)
import Boundary.Undefined (Undefinable, fromUndefinable, isDefined, isNull, pruneUndefined, toUndefinable, undefined)
import Boundary.Untagged (asArray, asNumber, asString, typeName)
import Data.Array (catMaybes, filter, index, nub, reverse) as Array
import Data.Array.NonEmpty (toArray) as NEA
import Data.List (fromFoldable, toUnfoldable) as List
import Data.Map (Map)
import Data.Map (fromFoldable, keys, lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.Newtype (unwrap, wrap)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Data.Set (fromFoldable, member, toUnfoldable) as Set
import Data.String (null) as String
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff.Compat (EffectFnAff(..), EffectFnCanceler, EffectFnCb, fromEffectFnAff)
import Effect.Class (liftEffect)
import Effect.Exception (Error)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn1, mkEffectFn2, mkEffectFn3, runEffectFn1)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Object (Object)
import React.FFI.Env (isDevelopment)
import React.Store.Action (Action(..))
import React.Store.PanBy (panBy) as StorePanBy
import React.Store.InitialState (defaultOnError)
import React.Store.Shell (Store)
import React.Store.InPlace (mirrorInPlace)
import React.Types.Edges (DefaultEdgeOptions, Edge)
import React.Types.General
  ( IsValidConnection
  , OnBeforeDelete
  , OnDelete
  , OnEdgesChange
  , OnEdgesDelete
  , OnMove
  , OnMoveEnd
  , OnMoveStart
  , OnNodesChange
  , OnNodesDelete
  , OnSelectionChangeFunc
  , OnViewportChange
  )
import React.Types.Nodes (Node)
import React.Store.Middleware (registerChangeConverters)
import React.Types.Store (ConnectionClickStartHandle, FitViewResolver, MiddlewareMap, ReactFlowState)
import System.XYDrag (OnNodeDrag, OnSelectionDrag)
import System.XYHandle (OnConnect, OnConnectEnd, OnConnectStart)
import System.Constants (AriaLabelConfig, mergeAriaLabelConfig)
import System.Types.Connection (ConnectionLookup, ConnectionMode(..), ConnectionState(..), HandleConnection, HandleConnections, InterpolateMode(..), PanOnScrollMode(..), SetCenterOptions, Padding(..), PaddingValue(..), SelectionRect, ZIndexMode(..))
import System.Types.Edge (EdgeBase, EdgeChange, EdgeLookup)
import System.Types.Geometry (CoordinateExtent, NodeOrigin, SnapGrid, Transform(..))
import System.Types.Node (InternalNodeBase, InternalNodeUpdate, NodeBase, NodeChange, NodeDragItem, NodeLookup, OnError, ParentLookup)
import System.FFI.D3Zoom (ZoomTransform)
import System.Types.PanZoom (PanOnDrag(..), PanZoomInstance, PanZoomTransformOptions, PanZoomUpdateOptions)
import System.Utils.General (devWarn)
import System.Utils.Graph (FitViewOptions)
import Unsafe.Coerce (unsafeCoerce)
import Unsafe.Reference (unsafeRefEq)
import Web.HTML.HTMLDivElement (HTMLDivElement)

-- ────────────────────────────────────────────────────────────────────────
-- The JavaScript side
-- ────────────────────────────────────────────────────────────────────────

-- | One store's view: `getState`, `setState`, `subscribe` and the selector
-- | adapter `useStore` reads through. Built once per store.
foreign import data JsStoreView :: Type

-- | `{ getState, setState, subscribe }`, as upstream's `useStoreApi` returns.
foreign import data JsStoreApi :: Type

foreign import absent :: Foreign
foreign import reversibleImpl :: forall a b. (a -> b) -> a -> b
foreign import producedFromImpl :: forall a b. a -> Nullable b
foreign import newMap :: Array (Array Foreign) -> Foreign
foreign import mapEntriesImpl :: Foreign -> Nullable (Array (Array Foreign))
foreign import isMap :: Foreign -> Boolean
foreign import callMethod :: Foreign -> String -> Array Foreign -> Effect Foreign
foreign import awaitMethodImpl
  :: forall a
   . Foreign
  -> String
  -> Array Foreign
  -> EffectFn2 (EffectFnCb Error) (EffectFnCb a) EffectFnCanceler
foreign import storeViewImpl :: forall n e. Store n e -> (Unit -> ViewSpec) -> JsStoreView
foreign import curriedEquality :: Undefinable Foreign -> Foreign
foreign import useApiObject :: EffectFn1 JsStoreView JsStoreApi
foreign import selectThrough :: JsStoreView -> Undefinable Foreign -> Foreign

type State = ReactFlowState Foreign Foreign

-- | What `Store.js` builds a view from.
type ViewSpec =
  { getState :: Effect State
  , patch :: (State -> State) -> Effect Unit
  , mutate :: (State -> State) -> Effect Unit
  , subscribeStates :: (State -> State -> Effect Unit) -> Effect (Effect Unit)
  , observeTransitions :: (State -> State -> Boolean -> Effect Unit) -> Effect Unit
  , keys :: Array String
  , fields :: Object Foreign
  , actions :: Foreign
  , isDevelopment :: Boolean
  }

-- | The view of a store, built on the first call and shared after it.
storeViewOf :: forall n e. Store n e -> JsStoreView
storeViewOf store = storeViewImpl store \_ -> viewSpec (unsafeCoerce store)

-- | Upstream's `useStoreApi` result for one component.
useStoreApiObject :: EffectFn1 JsStoreView JsStoreApi
useStoreApiObject = useApiObject

-- | A consumer's selector, reading the view rather than the PureScript state.
-- | The same selector gets the same adapter back, so the selection memo
-- | survives a re-render as upstream's does. An absent selector is zustand's
-- | identity default, the whole state.
selectorThrough :: forall a. JsStoreView -> Undefinable Foreign -> State -> a
selectorThrough view selector = unsafeCoerce (selectThrough view selector)

-- | The curried equality the selection memo calls: the consumer's
-- | `equalityFn`, or `Object.is` when there is none.
equalityFor :: forall a. Undefinable Foreign -> a -> a -> Boolean
equalityFor = unsafeCoerce <<< curriedEquality

viewSpec :: Store Foreign Foreign -> ViewSpec
viewSpec store =
  { getState: store.getState
  , patch: \f -> store.dispatch (PatchState f)
  , mutate: \f -> store.dispatch (MutateState f)
  , subscribeStates: store.subscribeStates
  , observeTransitions: store.observeTransitions
  , keys: stateKeys
  , fields: unsafeCoerce stateFields
  , actions: actionsOut store
  , isDevelopment
  }

-- ────────────────────────────────────────────────────────────────────────
-- The members, in upstream's order
-- ────────────────────────────────────────────────────────────────────────

-- | `getInitialState`'s keys in the order it writes them, then the optional
-- | callbacks `StoreUpdater` adds. The view places the 20 actions between the
-- | two, where `createStore` spreads them.
stateKeys :: Array String
stateKeys =
  [ "rfId", "width", "height", "transform", "nodes", "nodesInitialized", "nodeLookup"
  , "parentLookup", "edges", "edgeLookup", "connectionLookup", "onNodesChange"
  , "onEdgesChange", "hasDefaultNodes", "hasDefaultEdges", "panZoom", "minZoom"
  , "maxZoom", "translateExtent", "nodeExtent", "nodesSelectionActive"
  , "userSelectionActive", "userSelectionRect", "connectionMode", "domNode"
  , "paneDragging", "noPanClassName", "nodeOrigin", "nodeDragThreshold"
  , "connectionDragThreshold", "snapGrid", "snapToGrid", "nodesDraggable"
  , "nodesConnectable", "nodesFocusable", "edgesFocusable", "edgesReconnectable"
  , "elementsSelectable", "elevateNodesOnSelect", "elevateEdgesOnSelect"
  , "selectNodesOnDrag", "multiSelectionActive", "fitViewQueued", "fitViewOptions"
  , "fitViewResolver", "connection", "connectionClickStartHandle", "connectOnClick"
  , "ariaLiveMessage", "autoPanOnConnect", "autoPanOnNodeDrag", "autoPanOnNodeFocus"
  , "autoPanSpeed", "connectionRadius", "onError", "isValidConnection"
  , "onSelectionChangeHandlers", "lib", "debug", "ariaLabelConfig", "zIndexMode"
  , "onNodesChangeMiddlewareMap", "onEdgesChangeMiddlewareMap"
  , "onNodeDragStart", "onNodeDrag", "onNodeDragStop", "onSelectionDragStart"
  , "onSelectionDrag", "onSelectionDragStop", "onMoveStart", "onMove", "onMoveEnd"
  , "onConnect", "onConnectStart", "onConnectEnd", "onClickConnectStart"
  , "onClickConnectEnd", "defaultEdgeOptions", "onNodesDelete", "onEdgesDelete"
  , "onDelete", "onViewportChangeStart", "onViewportChange", "onViewportChangeEnd"
  , "onBeforeDelete"
  ]

-- | Both directions of one member. `toJs` is handed the whole state too,
-- | because the lookups take their iteration order from `nodes` and `edges`,
-- | as upstream's maps take theirs from the order they were filled in.
type Field a =
  { toJs :: State -> a -> Foreign
  , fromJs :: Foreign -> a
  , optional :: Boolean
  }

-- | One `Field` per state member, typed by the member it converts. Its labels
-- | are `ReactFlowState`'s, and `parity/boundary/drift.mjs` compares the two
-- | label sets, so a member added to the state fails that gate until it has a
-- | converter here. (A type class computing this record from the state's row
-- | said the same thing to the compiler, which took more than twenty minutes
-- | to solve it for 85 members.)
type StateFields =
  { rfId :: Field String
  , width :: Field Number
  , height :: Field Number
  , transform :: Field Transform
  , nodes :: Field (Array (Node Foreign))
  , nodesInitialized :: Field Boolean
  , nodeLookup :: Field (NodeLookup Foreign)
  , parentLookup :: Field (ParentLookup Foreign)
  , edges :: Field (Array (Edge Foreign))
  , edgeLookup :: Field (EdgeLookup Foreign)
  , connectionLookup :: Field ConnectionLookup
  , onNodesChange :: Field (Maybe (OnNodesChange Foreign))
  , onEdgesChange :: Field (Maybe (OnEdgesChange Foreign))
  , hasDefaultNodes :: Field Boolean
  , hasDefaultEdges :: Field Boolean
  , domNode :: Field (Maybe HTMLDivElement)
  , paneDragging :: Field Boolean
  , noPanClassName :: Field String
  , panZoom :: Field (Maybe PanZoomInstance)
  , minZoom :: Field Number
  , maxZoom :: Field Number
  , translateExtent :: Field CoordinateExtent
  , nodeExtent :: Field CoordinateExtent
  , nodeOrigin :: Field NodeOrigin
  , nodeDragThreshold :: Field Number
  , connectionDragThreshold :: Field Number
  , nodesSelectionActive :: Field Boolean
  , userSelectionActive :: Field Boolean
  , userSelectionRect :: Field (Maybe SelectionRect)
  , connection :: Field (ConnectionState (InternalNodeBase Foreign))
  , connectionMode :: Field ConnectionMode
  , connectionClickStartHandle :: Field (Maybe ConnectionClickStartHandle)
  , snapToGrid :: Field Boolean
  , snapGrid :: Field SnapGrid
  , nodesDraggable :: Field Boolean
  , autoPanOnNodeFocus :: Field Boolean
  , nodesConnectable :: Field Boolean
  , nodesFocusable :: Field Boolean
  , edgesFocusable :: Field Boolean
  , edgesReconnectable :: Field Boolean
  , elementsSelectable :: Field Boolean
  , elevateNodesOnSelect :: Field Boolean
  , elevateEdgesOnSelect :: Field Boolean
  , selectNodesOnDrag :: Field Boolean
  , multiSelectionActive :: Field Boolean
  , onNodeDragStart :: Field (Maybe (OnNodeDrag Foreign))
  , onNodeDrag :: Field (Maybe (OnNodeDrag Foreign))
  , onNodeDragStop :: Field (Maybe (OnNodeDrag Foreign))
  , onSelectionDragStart :: Field (Maybe (OnSelectionDrag Foreign))
  , onSelectionDrag :: Field (Maybe (OnSelectionDrag Foreign))
  , onSelectionDragStop :: Field (Maybe (OnSelectionDrag Foreign))
  , onMoveStart :: Field (Maybe OnMoveStart)
  , onMove :: Field (Maybe OnMove)
  , onMoveEnd :: Field (Maybe OnMoveEnd)
  , onConnect :: Field (Maybe OnConnect)
  , onConnectStart :: Field (Maybe OnConnectStart)
  , onConnectEnd :: Field (Maybe (OnConnectEnd Foreign))
  , onClickConnectStart :: Field (Maybe OnConnectStart)
  , onClickConnectEnd :: Field (Maybe (OnConnectEnd Foreign))
  , connectOnClick :: Field Boolean
  , defaultEdgeOptions :: Field (Maybe (DefaultEdgeOptions Foreign))
  , fitViewQueued :: Field Boolean
  , fitViewOptions :: Field (Maybe FitViewOptions)
  , fitViewResolver :: Field (Maybe FitViewResolver)
  , onNodesDelete :: Field (Maybe (OnNodesDelete Foreign))
  , onEdgesDelete :: Field (Maybe (OnEdgesDelete Foreign))
  , onDelete :: Field (Maybe (OnDelete Foreign Foreign))
  , onError :: Field (Maybe OnError)
  , onViewportChangeStart :: Field (Maybe OnViewportChange)
  , onViewportChange :: Field (Maybe OnViewportChange)
  , onViewportChangeEnd :: Field (Maybe OnViewportChange)
  , onBeforeDelete :: Field (Maybe (OnBeforeDelete Foreign Foreign))
  , onSelectionChangeHandlers :: Field (Array (OnSelectionChangeFunc Foreign Foreign))
  , ariaLiveMessage :: Field String
  , autoPanOnConnect :: Field Boolean
  , autoPanOnNodeDrag :: Field Boolean
  , autoPanSpeed :: Field Number
  , connectionRadius :: Field Number
  , isValidConnection :: Field (Maybe (IsValidConnection Foreign))
  , lib :: Field String
  , debug :: Field Boolean
  , ariaLabelConfig :: Field AriaLabelConfig
  , zIndexMode :: Field ZIndexMode
  , onNodesChangeMiddlewareMap :: Field (MiddlewareMap (NodeChange Foreign))
  , onEdgesChangeMiddlewareMap :: Field (MiddlewareMap (EdgeChange Foreign))
  }

-- | Every member's `Field`.
stateFields :: StateFields
stateFields =
  { rfId: written
  , width: written
  , height: written
  , transform: plain transformOut (transformIn "transform")
  , nodes: plain nodesOut (listOf "nodes" (reversible nodeIn))
  , nodesInitialized: written
  , nodeLookup: field nodeLookupOut (nodeLookupIn "nodeLookup")
  , parentLookup: field parentLookupOut (parentLookupIn "parentLookup")
  , edges: plain edgesOut (listOf "edges" (reversible edgeIn))
  , edgeLookup: field edgeLookupOut (edgeLookupIn "edgeLookup")
  , connectionLookup: field connectionLookupOut (connectionLookupIn "connectionLookup")
  , onNodesChange: callback nullValue onNodesChangeIn onNodesChangeOut
  , onEdgesChange: callback nullValue onEdgesChangeIn onEdgesChangeOut
  , hasDefaultNodes: written
  , hasDefaultEdges: written
  , domNode: plain (unsafeToForeign <<< toNullable) domNodeIn
  , paneDragging: written
  , noPanClassName: written
  , panZoom: plain (maybe nullValue panZoomOut) (absentOr (Just <<< panZoomFromJs))
  , minZoom: written
  , maxZoom: written
  , translateExtent: plain (unsafeToForeign <<< coordinateExtentOut) (coordinateExtentIn "translateExtent" <<< unsafeCoerce)
  , nodeExtent: plain (unsafeToForeign <<< coordinateExtentOut) (coordinateExtentIn "nodeExtent" <<< unsafeCoerce)
  , nodeOrigin: plain (unsafeToForeign <<< nodeOriginOut) (nodeOriginIn "nodeOrigin" <<< unsafeCoerce)
  , nodeDragThreshold: written
  , connectionDragThreshold: written
  , nodesSelectionActive: written
  , userSelectionActive: written
  , userSelectionRect: plain (unsafeToForeign <<< toNullable) selectionRectIn
  , connection: plain liveConnectionOut liveConnectionIn
  , connectionMode: plain connectionModeOut connectionModeFromJs
  , connectionClickStartHandle: plain clickStartOut clickStartIn
  , snapToGrid: written
  , snapGrid: plain (\g -> unsafeToForeign [ (unwrap g).gx, (unwrap g).gy ]) (snapGridIn "snapGrid" <<< unsafeCoerce)
  , nodesDraggable: written
  , autoPanOnNodeFocus: written
  , nodesConnectable: written
  , nodesFocusable: written
  , edgesFocusable: written
  , edgesReconnectable: written
  , elementsSelectable: written
  , elevateNodesOnSelect: written
  , elevateEdgesOnSelect: written
  , selectNodesOnDrag: written
  , multiSelectionActive: written
  , onNodeDragStart: optionalCallback onNodeDragIn onNodeDragOut
  , onNodeDrag: optionalCallback onNodeDragIn onNodeDragOut
  , onNodeDragStop: optionalCallback onNodeDragIn onNodeDragOut
  , onSelectionDragStart: optionalCallback (unsafeCoerce selectionDragHandlerIn) (unsafeCoerce selectionDragHandlerOut)
  , onSelectionDrag: optionalCallback (unsafeCoerce selectionDragHandlerIn) (unsafeCoerce selectionDragHandlerOut)
  , onSelectionDragStop: optionalCallback (unsafeCoerce selectionDragHandlerIn) (unsafeCoerce selectionDragHandlerOut)
  , onMoveStart: optionalCallback (unsafeCoerce onMoveIn) (unsafeCoerce onMoveOut)
  , onMove: optionalCallback onMoveIn onMoveOut
  , onMoveEnd: optionalCallback (unsafeCoerce onMoveIn) (unsafeCoerce onMoveOut)
  , onConnect: optionalCallback onConnectIn onConnectOut
  , onConnectStart: optionalCallback onConnectStartIn onConnectStartOut
  , onConnectEnd: optionalCallback onConnectEndIn onConnectEndOut
  , onClickConnectStart: optionalCallback onConnectStartIn onConnectStartOut
  , onClickConnectEnd: optionalCallback onConnectEndIn onConnectEndOut
  , connectOnClick: written
  , defaultEdgeOptions:
      { toJs: \_ -> maybe absent (unsafeToForeign <<< defaultEdgeOptionsOut)
      , fromJs: absentOr (Just <<< defaultEdgeOptionsIn <<< unsafeCoerce)
      , optional: true
      }
  , fitViewQueued: written
  , fitViewOptions: plain (maybe (unsafeToForeign undefined) fitViewOptionsOut)
      (absentOr (Just <<< remembering fitViewOptionsIn <<< (unsafeCoerce :: Foreign -> JsFitViewOptions)))
  , fitViewResolver: plain (maybe nullValue unsafeToForeign) (absentOr (Just <<< unsafeCoerce))
  , onNodesDelete: optionalCallback onNodesDeleteIn onNodesDeleteOut
  , onEdgesDelete: optionalCallback onEdgesDeleteIn onEdgesDeleteOut
  , onDelete: optionalCallback onDeleteIn onDeleteOut
  , onError:
      plain (maybe devWarnOut storeOnErrorOut) (absentOr (Just <<< functionIn onErrorIn))
  , onViewportChangeStart: optionalCallback onViewportChangeIn onViewportChangeOut
  , onViewportChange: optionalCallback onViewportChangeIn onViewportChangeOut
  , onViewportChangeEnd: optionalCallback onViewportChangeIn onViewportChangeOut
  , onBeforeDelete: optionalCallback onBeforeDeleteIn onBeforeDeleteOut
  , onSelectionChangeHandlers:
      plain (unsafeToForeign <<< map (callbackOut onSelectionChangeOut))
        (listOf "onSelectionChangeHandlers" selectionHandlerIn)
  , ariaLiveMessage: written
  , autoPanOnConnect: written
  , autoPanOnNodeDrag: written
  , autoPanSpeed: written
  , connectionRadius: written
  , isValidConnection: callback (unsafeToForeign undefined) isValidConnectionIn isValidConnectionOut
  , lib: written
  , debug: written
  , ariaLabelConfig: plain ariaLabelConfigOut (mergeAriaLabelConfig <<< ariaLabelConfigIn <<< (unsafeCoerce :: Foreign -> JsAriaLabelConfig))
  , zIndexMode: plain zIndexModeOut zIndexModeFromJs
  , onNodesChangeMiddlewareMap: plain middlewareMapOut (middlewareMapIn "onNodesChangeMiddlewareMap")
  , onEdgesChangeMiddlewareMap: plain middlewareMapOut (middlewareMapIn "onEdgesChangeMiddlewareMap")
  }

-- ────────────────────────────────────────────────────────────────────────
-- Field builders
-- ────────────────────────────────────────────────────────────────────────

field :: forall a. (State -> a -> Foreign) -> (Foreign -> a) -> Field a
field toJs fromJs = { toJs, fromJs, optional: false }

plain :: forall a. (a -> Foreign) -> (Foreign -> a) -> Field a
plain toJs = field (const toJs)

-- | A boolean, number or string member: the written value itself, whatever
-- | it is. Upstream stores it as it is, and these compile to the same
-- | JavaScript operators upstream's internals use on it.
written :: forall a. Field a
written = plain unsafeToForeign unsafeCoerce

-- | `fromMaybe` with a fallback that runs only when needed, because every
-- | fallback here throws.
fromMaybe' :: forall a. (Unit -> a) -> Maybe a -> a
fromMaybe' fallback = case _ of
  Just a -> a
  Nothing -> fallback unit

wrongType :: forall a. String -> String -> Foreign -> Unit -> a
wrongType key expected v _ =
  unsafeThrow $
    "ps-flow: the store member `" <> key <> "` takes " <> expected <> ", got "
      <> typeName v
      <> "."

-- | `null` and `undefined` both mean the member's absence on the way in.
absentOr :: forall a. (Foreign -> Maybe a) -> Foreign -> Maybe a
absentOr present v
  | isNullish v = Nothing
  | otherwise = present v

isNullish :: Foreign -> Boolean
isNullish v = isNull (unsafeCoerce v :: Undefinable Foreign) || not (isDefined (unsafeCoerce v :: Undefinable Foreign))

nullValue :: Foreign
nullValue = unsafeToForeign (toNullable (Nothing :: Maybe Foreign))

listOf :: forall a. String -> (Foreign -> a) -> Foreign -> Array a
listOf key each v = case asArray v of
  Just items -> map each items
  Nothing -> wrongType key "an array" v unit

-- | The value the store handed out, if this is one, and a conversion if not.
reversible :: forall js ps. (js -> ps) -> Foreign -> ps
reversible convert v = case toMaybe (producedFromImpl v) of
  Just ps -> ps
  Nothing -> convert (unsafeCoerce v)


-- ────────────────────────────────────────────────────────────────────────
-- Callbacks
-- ────────────────────────────────────────────────────────────────────────

-- | The consumer's own function when one was converted, and otherwise the
-- | adapter that lets JavaScript call the PureScript one.
callbackOut :: forall js ps. (ps -> js) -> ps -> Foreign
callbackOut out f = case originalOf f of
  Just original -> original
  Nothing -> unsafeToForeign (out f)

-- | An adapter the store handed out goes back as its PureScript function.
-- | Anything else converts, and is called when it is used: upstream calls
-- | whatever a member holds, and a value that is not a function throws then.
functionIn :: forall js ps. (js -> ps) -> Foreign -> ps
functionIn convert v = case adaptedFrom v of
  Just ps -> ps
  Nothing -> remembering convert (unsafeCoerce v)

-- | A member upstream's initial state holds with a fixed value when nothing
-- | was set: `null` for the change handlers, `undefined` for
-- | `isValidConnection`, and `devWarn` for `onError`.
callback :: forall js ps. Foreign -> (js -> ps) -> (ps -> js) -> Field (Maybe ps)
callback whenAbsent convert out =
  plain (maybe whenAbsent (callbackOut out)) (absentOr (Just <<< functionIn convert))

-- | A member upstream's state lacks until `StoreUpdater` sets it.
optionalCallback :: forall js ps. (js -> ps) -> (ps -> js) -> Field (Maybe ps)
optionalCallback convert out = (callback absent convert out) { optional = true }

-- | `useOnSelectionChange`'s handlers, which the hook removes by reference:
-- | each converts through the hook's own cache, so the list written back
-- | holds the functions the hook put in it.
selectionHandlerIn :: Foreign -> OnSelectionChangeFunc Foreign Foreign
selectionHandlerIn v = case adaptedFrom v of
  Just ps -> ps
  Nothing -> stableSelectionChangeIn (unsafeCoerce v)

-- | Upstream's default `onError`, `createDevWarn('React Flow', …)`.
devWarnOut :: Foreign
devWarnOut = unsafeToForeign (mkEffectFn2 (devWarn isDevelopment))

-- | The store's `onError`: upstream's `devWarn` while it holds the default
-- | the store starts with, and otherwise the consumer's own function.
storeOnErrorOut :: OnError -> Foreign
storeOnErrorOut f
  | unsafeRefEq f defaultOnError = devWarnOut
  | otherwise = callbackOut onErrorOut f

-- ────────────────────────────────────────────────────────────────────────
-- Nodes, edges and their lookups
-- ────────────────────────────────────────────────────────────────────────

-- | An internal node as `nodeLookup` hands it out: one object per PureScript
-- | node, so an unchanged node reads back as the object read before.
internalNodeOutCached :: InternalNodeBase Foreign -> Foreign
internalNodeOutCached = reversibleImpl \node -> unsafeToForeign $
  mirrorInPlace
    (\current view -> view { selected = toUndefinable current.selected })
    node
    (internalNodeOut node)

-- | The consumer's own array when the store holds the one decoded from it,
-- | as upstream's `nodes` is the array the consumer passed. An array the
-- | store built itself is mapped, each node still the consumer's own.
nodesOut :: Array (NodeBase Foreign) -> Foreign
nodesOut nodes = case originalOf nodes of
  Just original -> original
  Nothing -> unsafeToForeign (map (reversibleImpl (unsafeToForeign <<< nodeIdentityOut)) nodes)

edgesOut :: Array (EdgeBase Foreign) -> Foreign
edgesOut edges = case originalOf edges of
  Just original -> original
  Nothing -> unsafeToForeign (map (reversibleImpl (unsafeToForeign <<< edgeIdentityOut)) edges)

-- | `preferred`, deduplicated and kept to `present`, then what is left of
-- | `present` in its own order.
ordered :: forall k. Ord k => Array k -> Array k -> Array k
ordered preferred present =
  let
    presentSet = Set.fromFoldable present
    first = Array.nub (Array.filter (\k -> Set.member k presentSet) preferred)
    firstSet = Set.fromFoldable first
  in
    first <> Array.filter (\k -> not (Set.member k firstSet)) present

entry :: String -> Foreign -> Array Foreign
entry key value = [ unsafeToForeign key, value ]

nodeLookupOut :: State -> NodeLookup Foreign -> Foreign
nodeLookupOut s lookup =
  newMap $ Array.catMaybes $ map
    (\id -> map (\n -> entry (unwrap id) (internalNodeOutCached n)) (Map.lookup id lookup))
    (ordered (map _.id s.nodes) (Set.toUnfoldable (Map.keys lookup)))

parentLookupOut :: State -> ParentLookup Foreign -> Foreign
parentLookupOut s lookup =
  newMap $ Array.catMaybes $ map
    ( \parent -> map
        ( \children -> entry (unwrap parent) $ newMap $ Array.catMaybes $ map
            (\id -> map (\n -> entry (unwrap id) (internalNodeOutCached n)) (Map.lookup id children))
            (ordered (map _.id s.nodes) (Set.toUnfoldable (Map.keys children)))
        )
        (Map.lookup parent lookup)
    )
    (ordered (Array.catMaybes (map _.parentId s.nodes)) (Set.toUnfoldable (Map.keys lookup)))

edgeLookupOut :: State -> EdgeLookup Foreign -> Foreign
edgeLookupOut s lookup =
  newMap $ Array.catMaybes $ map
    (\id -> map (\e -> entry id (edgeOutOne e)) (Map.lookup id lookup))
    (ordered (map _.id s.edges) (Set.toUnfoldable (Map.keys lookup)))
  where
  edgeOutOne = reversibleImpl (unsafeToForeign <<< edgeIdentityOut)

-- | Upstream fills this from `edges` in order, adding each edge under its
-- | source node's three keys and then its target node's, and a JavaScript
-- | `Map` keeps the position a key was first set at.
connectionLookupOut :: State -> Map String HandleConnections -> Foreign
connectionLookupOut s lookup =
  newMap $ Array.catMaybes $ map
    (\key -> map (\c -> entry key (connectionsOut c)) (Map.lookup key lookup))
    (ordered (edgeKeys =<< s.edges) (Set.toUnfoldable (Map.keys lookup)))
  where
  edgeKeys e =
    sideKeys (unwrap e.source) "source" e.sourceHandle
      <> sideKeys (unwrap e.target) "target" e.targetHandle
  sideKeys node side handle =
    [ node, node <> "-" <> side ]
      <> case handle of
        Just h | not (String.null h) -> [ node <> "-" <> side <> "-" <> h ]
        _ -> []
  connectionsOut c =
    newMap $ Array.catMaybes $ map
      (\k -> map (\hc -> entry k (unsafeToForeign (handleConnectionOut hc))) (Map.lookup k c.byKey))
      (Array.reverse (List.toUnfoldable c.order))

entriesOf :: String -> Foreign -> Array (Tuple Foreign Foreign)
entriesOf key v = case toMaybe (mapEntriesImpl v) of
  Just entries -> Array.catMaybes $ map
    ( case _ of
        [ k, value ] -> Just (Tuple k value)
        _ -> Nothing
    )
    entries
  Nothing -> wrongType key "a Map" v unit

keyIn :: String -> Foreign -> String
keyIn key k = fromMaybe' (wrongType key "string keys" k) (asString k)

nodeLookupIn :: String -> Foreign -> NodeLookup Foreign
nodeLookupIn key v = Map.fromFoldable $ map
  (\(Tuple k node) -> Tuple (wrap (keyIn key k)) (internalIn node))
  (entriesOf key v)

internalIn :: Foreign -> InternalNodeBase Foreign
internalIn = reversible internalNodeIn

parentLookupIn :: String -> Foreign -> ParentLookup Foreign
parentLookupIn key v = Map.fromFoldable $ map
  (\(Tuple k children) -> Tuple (wrap (keyIn key k)) (nodeLookupIn key children))
  (entriesOf key v)

edgeLookupIn :: String -> Foreign -> EdgeLookup Foreign
edgeLookupIn key v = Map.fromFoldable $ map
  (\(Tuple k e) -> Tuple (keyIn key k) (reversible edgeIn e))
  (entriesOf key v)

connectionLookupIn :: String -> Foreign -> Map String HandleConnections
connectionLookupIn key v = Map.fromFoldable $ map
  ( \(Tuple k inner) ->
      let
        pairs = map (\(Tuple ck hc) -> Tuple (keyIn key ck) (handleConnectionIn (unsafeCoerce hc))) (entriesOf key inner)
      in
        Tuple (keyIn key k)
          { byKey: Map.fromFoldable pairs
          , order: List.fromFoldable (Array.reverse (map (\(Tuple ck _) -> ck) pairs))
          }
  )
  (entriesOf key v)

handleConnectionIn :: JsHandleConnection -> HandleConnection
handleConnectionIn c =
  { source: wrap c.source
  , target: wrap c.target
  , sourceHandle: toMaybe c.sourceHandle
  , targetHandle: toMaybe c.targetHandle
  , edgeId: c.edgeId
  }

-- ────────────────────────────────────────────────────────────────────────
-- The other structured members
-- ────────────────────────────────────────────────────────────────────────

transformOut :: Transform -> Foreign
transformOut (Transform t) = unsafeToForeign [ t.tx, t.ty, t.scale ]

-- | `[x, y, zoom]`, each the written value itself, as upstream reads
-- | `transform[0]`, `transform[1]` and `transform[2]` and nothing else.
transformIn :: String -> Foreign -> Transform
transformIn key v = case asArray v of
  Just items ->
    let
      at i = unsafeCoerce (fromMaybe (unsafeToForeign undefined) (Array.index items i))
    in
      Transform { tx: at 0, ty: at 1, scale: at 2 }
  Nothing -> wrongType key "[x, y, zoom]" v unit

domNodeIn :: Foreign -> Maybe HTMLDivElement
domNodeIn = absentOr (Just <<< unsafeCoerce)

selectionRectIn :: Foreign -> Maybe SelectionRect
selectionRectIn = absentOr \v ->
  let
    r = unsafeCoerce v :: SelectionRect
  in
    Just { x: r.x, y: r.y, width: r.width, height: r.height, startX: r.startX, startY: r.startY }

connectionModeOut :: ConnectionMode -> Foreign
connectionModeOut = unsafeToForeign <<< case _ of
  Strict -> "strict"
  Loose -> "loose"

zIndexModeOut :: ZIndexMode -> Foreign
zIndexModeOut = unsafeToForeign <<< case _ of
  ZAuto -> "auto"
  ZBasic -> "basic"
  ZManual -> "manual"

-- | The mode upstream's internals act on: they compare
-- | `connectionMode === 'strict'`, so anything else is loose.
connectionModeFromJs :: Foreign -> ConnectionMode
connectionModeFromJs v = if asString v == Just "strict" then Strict else Loose

-- | Upstream compares `zIndexMode === 'manual'` and `=== 'auto'`, so
-- | anything else is basic.
zIndexModeFromJs :: Foreign -> ZIndexMode
zIndexModeFromJs v = case asString v of
  Just "manual" -> ZManual
  Just "auto" -> ZAuto
  _ -> ZBasic

-- | Upstream's `ConnectionState`: `FinalConnectionState` plus `inProgress`,
-- | all eleven members `null` beside `inProgress: false` when no connection
-- | is being drawn, and the store's raw `to` while one is.
liveConnectionOut :: ConnectionState (InternalNodeBase Foreign) -> Foreign
liveConnectionOut = case _ of
  NoConnection -> withInProgress false (connectionStateOut Nothing)
  ConnectionInProgress c ->
    withInProgress true (connectionStateOut (Just c { toPosition = Just c.toPosition }))

type JsLiveConnection =
  { inProgress :: Boolean
  , isValid :: Nullable Boolean
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

-- | `updateConnection`'s argument, and a `setState({ connection })`. The
-- | internal nodes a connection names are the store's own when they were read
-- | from it, as upstream's handle code passes them.
liveConnectionIn :: Foreign -> ConnectionState (InternalNodeBase Foreign)
liveConnectionIn v =
  let
    c = unsafeCoerce v :: JsLiveConnection
    required :: forall a. String -> Nullable a -> a
    required name = fromMaybe' (wrongType ("connection." <> name) "a value while `inProgress`" v) <<< toMaybe
  in
    if not c.inProgress then NoConnection
    else ConnectionInProgress
      { isValid: toMaybe c.isValid
      , from: required "from" c.from
      , fromHandle: handleIn "connection.fromHandle" (required "fromHandle" c.fromHandle)
      , fromPosition: positionIn "connection.fromPosition" (required "fromPosition" c.fromPosition)
      , fromNode: internalIn (unsafeToForeign (required "fromNode" c.fromNode))
      , to: required "to" c.to
      , toHandle: map (handleIn "connection.toHandle") (toMaybe c.toHandle)
      , toPosition: positionIn "connection.toPosition" (required "toPosition" c.toPosition)
      , toNode: map (internalIn <<< unsafeToForeign) (toMaybe c.toNode)
      , pointer: required "pointer" c.pointer
      }

type JsClickStart = { nodeId :: String, id :: Nullable String, type :: String }

clickStartOut :: Maybe ConnectionClickStartHandle -> Foreign
clickStartOut = case _ of
  Nothing -> nullValue
  Just h -> unsafeToForeign ({ nodeId: h.nodeId, id: toNullable h.id, type: handleTypeName h.handleType } :: JsClickStart)
  where
  handleTypeName t = if show t == "Source" then "source" else "target"

clickStartIn :: Foreign -> Maybe ConnectionClickStartHandle
clickStartIn = absentOr \v ->
  let
    h = unsafeCoerce v :: JsClickStart
  in
    Just { nodeId: h.nodeId, id: toMaybe h.id, handleType: handleTypeIn' h.type }
  where
  handleTypeIn' = handleTypeIn "connectionClickStartHandle.type"

ariaLabelConfigOut :: AriaLabelConfig -> Foreign
ariaLabelConfigOut c = unsafeToForeign
  { "node.a11yDescription.default": c.nodeA11yDescriptionDefault
  , "node.a11yDescription.keyboardDisabled": c.nodeA11yDescriptionKeyboardDisabled
  , "node.a11yDescription.ariaLiveMessage": c.nodeA11yDescriptionAriaLiveMessage
  , "edge.a11yDescription.default": c.edgeA11yDescriptionDefault
  , "controls.ariaLabel": c.controlsAriaLabel
  , "controls.zoomIn.ariaLabel": c.controlsZoomInAriaLabel
  , "controls.zoomOut.ariaLabel": c.controlsZoomOutAriaLabel
  , "controls.fitView.ariaLabel": c.controlsFitViewAriaLabel
  , "controls.interactive.ariaLabel": c.controlsInteractiveAriaLabel
  , "minimap.ariaLabel": c.minimapAriaLabel
  , "handle.ariaLabel": c.handleAriaLabel
  }

-- | The consumer's own options object when it came from one, and otherwise
-- | upstream's shape of ps-flow's record.
fitViewOptionsOut :: FitViewOptions -> Foreign
fitViewOptionsOut o = case originalOf o of
  Just original -> original
  Nothing -> unsafeToForeign $ pruneUndefined
    { padding: toUndefinable (map paddingOut o.padding)
    , includeHiddenNodes: o.includeHiddenNodes
    , minZoom: toUndefinable o.minZoom
    , maxZoom: toUndefinable o.maxZoom
    , duration: toUndefinable o.duration
    , ease: toUndefinable o.ease
    , interpolate: toUndefinable (map interpolateOut o.interpolate)
    , nodes: toUndefinable (map (map \n -> { id: unwrap n.id }) o.nodes)
    }

paddingOut :: Padding -> Foreign
paddingOut = case _ of
  UniformPadding value -> paddingValueOut value
  DirectionalPadding sides -> unsafeToForeign $ pruneUndefined
    { top: toUndefinable (map paddingValueOut sides.top)
    , right: toUndefinable (map paddingValueOut sides.right)
    , bottom: toUndefinable (map paddingValueOut sides.bottom)
    , left: toUndefinable (map paddingValueOut sides.left)
    }

paddingValueOut :: PaddingValue -> Foreign
paddingValueOut = case _ of
  PxPadding n -> unsafeToForeign (show n <> "px")
  PctPadding n -> unsafeToForeign (show n <> "%")
  RatioPadding n -> unsafeToForeign n

interpolateOut :: InterpolateMode -> String
interpolateOut = case _ of
  Smooth -> "smooth"
  Linear -> "linear"

-- | The store's live middleware map itself, which is what upstream hands
-- | out: a consumer's `.set(key, fn)` on it registers `fn`.
middlewareMapOut :: forall c. MiddlewareMap c -> Foreign
middlewareMapOut middlewares = unsafePerformEffect do
  registerChangeConvertersForJs
  pure (unsafeToForeign middlewares)

-- | Any `Map` is taken as it is, as upstream's store takes it, and the store
-- | runs its values when it runs middleware.
middlewareMapIn :: forall c. String -> Foreign -> MiddlewareMap c
middlewareMapIn key v
  | isMap v = unsafePerformEffect do
      registerChangeConvertersForJs
      pure (unsafeCoerce v)
  | otherwise = wrongType key "a Map" v unit

-- | What a consumer's middleware, and JavaScript calling a PureScript one,
-- | converts changes through. Called before JavaScript can reach a map.
registerChangeConvertersForJs :: Effect Unit
registerChangeConvertersForJs =
  registerChangeConverters
    { toJs: unsafeToForeign <<< map nodeChangeIdentityOut
    , fromJs: map nodeChangeFromJs <<< (unsafeCoerce :: Foreign -> Array JsNodeChange)
    }
    { toJs: unsafeToForeign <<< map edgeChangeIdentityOut
    , fromJs: map edgeChangeFromJs <<< (unsafeCoerce :: Foreign -> Array JsEdgeChange)
    }

-- | The pan-zoom instance's eleven members, with upstream's argument shapes:
-- | the consumer's own object when one was written, and otherwise a view of
-- | the instance ps-flow's pane made.
panZoomOut :: PanZoomInstance -> Foreign
panZoomOut pz = case originalOf pz of
  Just original -> original
  Nothing -> panZoomView pz

-- | A view the store handed out goes back as its instance; anything else is
-- | the consumer's own, and `panZoomIn` calls it.
panZoomFromJs :: Foreign -> PanZoomInstance
panZoomFromJs = reversible panZoomIn

-- | A pan-zoom instance written from JavaScript. Each member calls the
-- | object's method of the same name when the store calls it, with
-- | upstream's argument shapes, as upstream's store calls `panZoom.…`, so a
-- | missing method throws then, as it does upstream.
panZoomIn :: Foreign -> PanZoomInstance
panZoomIn = remembering \pz ->
  { update: \options -> void (callMethod pz "update" [ panZoomUpdateOut options ])
  , destroy: void (callMethod pz "destroy" [])
  , getViewport: map unsafeCoerce (callMethod pz "getViewport" [])
  , setViewport: \viewport options ->
      map transformResult (awaitMethod pz "setViewport" [ unsafeToForeign viewport, transformOptionsOut options ])
  , setViewportConstrained: \viewport extent translateExtent ->
      map transformResult
        ( awaitMethod pz "setViewportConstrained"
            [ unsafeToForeign viewport
            , unsafeToForeign (coordinateExtentOut extent)
            , unsafeToForeign (coordinateExtentOut translateExtent)
            ]
        )
  , setScaleExtent: \minZoom maxZoom -> void (callMethod pz "setScaleExtent" [ unsafeToForeign [ minZoom, maxZoom ] ])
  , setTranslateExtent: \extent -> void (callMethod pz "setTranslateExtent" [ unsafeToForeign (coordinateExtentOut extent) ])
  , scaleTo: \zoom options -> map unsafeCoerce (awaitMethod pz "scaleTo" [ unsafeToForeign zoom, transformOptionsOut options ])
  , scaleBy: \factor options -> map unsafeCoerce (awaitMethod pz "scaleBy" [ unsafeToForeign factor, transformOptionsOut options ])
  , syncViewport: \viewport -> void (callMethod pz "syncViewport" [ unsafeToForeign viewport ])
  , setClickDistance: \distance -> void (callMethod pz "setClickDistance" [ unsafeToForeign distance ])
  }
  where
  transformResult result
    | isNullish result = Nothing
    | otherwise = Just (unsafeCoerce result)

awaitMethod :: forall a. Foreign -> String -> Array Foreign -> Aff a
awaitMethod object name args = fromEffectFnAff (EffectFnAff (awaitMethodImpl object name args))

-- | Upstream's `{ duration, ease, interpolate }`, each key present.
transformOptionsOut :: Maybe PanZoomTransformOptions -> Foreign
transformOptionsOut = case _ of
  Nothing -> unsafeToForeign undefined
  Just o -> unsafeToForeign
    { duration: toUndefinable o.duration
    , ease: toUndefinable o.ease
    , interpolate: toUndefinable (map interpolateOut o.interpolate)
    }

-- | The reverse of `panZoomUpdateIn`: upstream's `update` options.
panZoomUpdateOut :: PanZoomUpdateOptions -> Foreign
panZoomUpdateOut o = unsafeToForeign
  { noWheelClassName: o.noWheelClassName
  , noPanClassName: o.noPanClassName
  , onPaneContextMenu: toUndefinable (map (\effect -> mkEffectFn1 \(_ :: Foreign) -> effect) o.onPaneContextMenu)
  , preventScrolling: o.preventScrolling
  , panOnScroll: o.panOnScroll
  , panOnDrag: panOnDragOut o.panOnDrag
  , panOnScrollMode: panOnScrollModeOut o.panOnScrollMode
  , panOnScrollSpeed: o.panOnScrollSpeed
  , userSelectionActive: o.userSelectionActive
  , zoomOnPinch: o.zoomOnPinch
  , zoomOnScroll: o.zoomOnScroll
  , zoomOnDoubleClick: o.zoomOnDoubleClick
  , zoomActivationKeyPressed: o.zoomActivationKeyPressed
  , lib: o.lib
  , onTransformChange: mkEffectFn1 \t -> o.onTransformChange (transformIn "panZoom.update.onTransformChange" t)
  , connectionInProgress: o.connectionInProgress
  , paneClickDistance: o.paneClickDistance
  , selectionOnDrag: o.selectionOnDrag
  }
  where
  panOnDragOut = case _ of
    NoPan -> unsafeToForeign false
    PanAlways -> unsafeToForeign true
    PanOnButtons buttons -> unsafeToForeign (NEA.toArray buttons)
  panOnScrollModeOut = case _ of
    Free -> "free"
    Vertical -> "vertical"
    Horizontal -> "horizontal"

panZoomView :: PanZoomInstance -> Foreign
panZoomView = reversibleImpl \pz -> unsafeToForeign
  { update: mkEffectFn1 \options -> pz.update (panZoomUpdateIn options)
  , destroy: pz.destroy
  , setViewport: mkEffectFn2 \viewport options ->
      toPromise (map (toUndefinable <<< map zoomTransformOut) (pz.setViewport viewport (Just (transformOptionsIn options))))
  , setViewportConstrained: mkEffectFn3 \viewport extent translateExtent ->
      toPromise
        ( map (toUndefinable <<< map zoomTransformOut)
            ( pz.setViewportConstrained viewport
                (coordinateExtentIn "panZoom.setViewportConstrained" extent)
                (coordinateExtentIn "panZoom.setViewportConstrained" translateExtent)
            )
        )
  , getViewport: pz.getViewport
  , scaleTo: mkEffectFn2 \zoom options -> toPromise (pz.scaleTo zoom (Just (transformOptionsIn options)))
  , scaleBy: mkEffectFn2 \factor options -> toPromise (pz.scaleBy factor (Just (transformOptionsIn options)))
  , setScaleExtent: mkEffectFn1 \extent -> case extent of
      [ minZoom, maxZoom ] -> pz.setScaleExtent minZoom maxZoom
      _ -> unsafeThrow "ps-flow: `panZoom.setScaleExtent` takes [minZoom, maxZoom]."
  , setTranslateExtent: mkEffectFn1 \extent ->
      pz.setTranslateExtent (coordinateExtentIn "panZoom.setTranslateExtent" extent)
  , syncViewport: mkEffectFn1 pz.syncViewport
  , setClickDistance: mkEffectFn1 pz.setClickDistance
  }

-- | d3's own transform object, which is what upstream's promise resolves to.
zoomTransformOut :: ZoomTransform -> Foreign
zoomTransformOut = unsafeCoerce

type JsTransformOptions =
  { duration :: Undefinable Foreign
  , ease :: Undefinable (Number -> Number)
  , interpolate :: Undefinable String
  }

transformOptionsIn :: Undefinable JsTransformOptions -> PanZoomTransformOptions
transformOptionsIn options = case fromUndefinable options of
  Nothing -> { duration: Nothing, ease: Nothing, interpolate: Nothing }
  Just o ->
    { duration: fromUndefinable o.duration >>= asNumber
    , ease: fromUndefinable o.ease
    , interpolate: map (interpolateModeIn "panZoom.interpolate") (fromUndefinable o.interpolate)
    }

type JsPanZoomUpdate =
  { noWheelClassName :: String
  , noPanClassName :: String
  , onPaneContextMenu :: Undefinable (EffectFn1 Foreign Unit)
  , preventScrolling :: Boolean
  , panOnScroll :: Boolean
  , panOnDrag :: Foreign
  , panOnScrollMode :: String
  , panOnScrollSpeed :: Number
  , userSelectionActive :: Boolean
  , zoomOnPinch :: Boolean
  , zoomOnScroll :: Boolean
  , zoomOnDoubleClick :: Boolean
  , zoomActivationKeyPressed :: Boolean
  , lib :: String
  , onTransformChange :: EffectFn1 Foreign Unit
  , connectionInProgress :: Boolean
  , paneClickDistance :: Number
  , selectionOnDrag :: Boolean
  }

panZoomUpdateIn :: JsPanZoomUpdate -> PanZoomUpdateOptions
panZoomUpdateIn o =
  { noWheelClassName: o.noWheelClassName
  , noPanClassName: o.noPanClassName
  , onPaneContextMenu: map (\f -> runEffectFn1 f (unsafeToForeign undefined)) (fromUndefinable o.onPaneContextMenu)
  , preventScrolling: o.preventScrolling
  , panOnScroll: o.panOnScroll
  , panOnDrag: panOnDragIn o.panOnDrag
  , panOnScrollMode: panOnScrollModeIn "panZoom.update.panOnScrollMode" o.panOnScrollMode
  , panOnScrollSpeed: o.panOnScrollSpeed
  , userSelectionActive: o.userSelectionActive
  , zoomOnPinch: o.zoomOnPinch
  , zoomOnScroll: o.zoomOnScroll
  , zoomOnDoubleClick: o.zoomOnDoubleClick
  , zoomActivationKeyPressed: o.zoomActivationKeyPressed
  , lib: o.lib
  , onTransformChange: \t -> runEffectFn1 o.onTransformChange (transformOut t)
  , connectionInProgress: o.connectionInProgress
  , paneClickDistance: o.paneClickDistance
  , selectionOnDrag: o.selectionOnDrag
  }

-- ────────────────────────────────────────────────────────────────────────
-- The twenty actions
-- ────────────────────────────────────────────────────────────────────────

type JsInternalNodeUpdate = { id :: String, nodeElement :: HTMLDivElement, force :: Undefinable Boolean }

type JsDragItem =
  { id :: String
  , position :: JsXYPosition
  , distance :: Undefinable JsXYPosition
  , measured :: Undefinable { width :: Undefinable Number, height :: Undefinable Number }
  , internals :: { positionAbsolute :: JsXYPosition }
  , extent :: Undefinable Foreign
  , parentId :: Undefinable String
  , origin :: Undefinable (Array Number)
  , expandParent :: Undefinable Boolean
  , dragging :: Undefinable Boolean
  }

dragItemIn :: JsDragItem -> NodeDragItem
dragItemIn i =
  { id: wrap i.id
  , position: i.position
  , distance: fromMaybe { x: 0.0, y: 0.0 } (fromUndefinable i.distance)
  , measured:
      { width: fromMaybe 0.0 (fromUndefinable i.measured >>= (_.width >>> fromUndefinable))
      , height: fromMaybe 0.0 (fromUndefinable i.measured >>= (_.height >>> fromUndefinable))
      }
  , internals: { positionAbsolute: i.internals.positionAbsolute }
  , extent: map nodeExtentIn (fromUndefinable i.extent)
  , parentId: map wrap (fromUndefinable i.parentId)
  , origin: map (nodeOriginIn "updateNodePositions.origin") (fromUndefinable i.origin)
  , expandParent: fromUndefinable i.expandParent
  , dragging: fromUndefinable i.dragging
  }

-- | A JavaScript `Map`'s values in insertion order, which is the order
-- | upstream iterates `updateNodeInternals`' and `updateNodePositions`' maps.
mapValuesIn :: forall a. String -> Foreign -> Array a
mapValuesIn key v = map (\(Tuple _ value) -> unsafeCoerce value) (entriesOf key v)

type JsUnselectParams = { nodes :: Undefinable (Array Foreign), edges :: Undefinable (Array Foreign) }

-- | The nodes an action is handed, remembering the consumer's array.
-- | Upstream's `setNodes(nodes)` stores the array itself, so
-- | `getState().nodes` reads it back, and `nodesOut` hands back this one.
nodeList :: String -> Foreign -> Array (NodeBase Foreign)
nodeList key = remembering (listOf key (reversible nodeIn))

-- | `nodeList` for edges, which `edgesOut` hands back.
edgeList :: String -> Foreign -> Array (EdgeBase Foreign)
edgeList key = remembering (listOf key (reversible edgeIn))

actionsOut :: Store Foreign Foreign -> Foreign
actionsOut store = unsafeToForeign
  { setNodes: mkEffectFn1 \nodes -> store.dispatch (SetNodes (nodeList "setNodes" nodes))
  , setEdges: mkEffectFn1 \edges -> store.dispatch (SetEdges (edgeList "setEdges" edges))
  , setDefaultNodesAndEdges: mkEffectFn2 \nodes edges ->
      store.dispatch
        ( SetDefaultNodesAndEdges
            (map (nodeList "setDefaultNodesAndEdges") (fromUndefinable nodes))
            (map (edgeList "setDefaultNodesAndEdges") (fromUndefinable edges))
        )
  , updateNodeInternals: mkEffectFn1 \updates ->
      store.dispatch
        ( UpdateNodeInternals (map updateIn (mapValuesIn "updateNodeInternals" updates))
            { triggerFitView: false }
        )
  , updateNodePositions: mkEffectFn2 \items dragging ->
      store.dispatch
        ( UpdateNodePositions (map dragItemIn (mapValuesIn "updateNodePositions" items))
            (fromMaybe false (fromUndefinable dragging))
        )
  , triggerNodeChanges: mkEffectFn1 \changes -> store.dispatch (TriggerNodeChanges (map nodeChangeFromJs changes))
  , triggerEdgeChanges: mkEffectFn1 \changes -> store.dispatch (TriggerEdgeChanges (map edgeChangeFromJs changes))
  , addSelectedNodes: mkEffectFn1 \ids -> store.dispatch (AddSelectedNodes (map wrap ids))
  , addSelectedEdges: mkEffectFn1 \ids -> store.dispatch (AddSelectedEdges ids)
  , unselectNodesAndEdges: mkEffectFn1 \(params :: Undefinable JsUnselectParams) ->
      store.dispatch
        ( UnselectNodesAndEdges
            { nodes: map (map (reversible nodeIn)) (fromUndefinable params >>= (_.nodes >>> fromUndefinable))
            , edges: map (map (reversible edgeIn)) (fromUndefinable params >>= (_.edges >>> fromUndefinable))
            }
        )
  , setMinZoom: mkEffectFn1 \zoom -> store.dispatch (SetMinZoom zoom)
  , setMaxZoom: mkEffectFn1 \zoom -> store.dispatch (SetMaxZoom zoom)
  , setTranslateExtent: mkEffectFn1 \extent ->
      store.dispatch (SetTranslateExtent (coordinateExtentIn "setTranslateExtent" extent))
  , resetSelectedElements: store.dispatch ResetSelectedElements
  , setNodeExtent: mkEffectFn1 \extent ->
      store.dispatch (SetNodeExtent (coordinateExtentIn "setNodeExtent" extent))
  , panBy: mkEffectFn1 \delta -> toPromise (StorePanBy.panBy store delta)
  , setCenter: mkEffectFn3 \x y options -> toPromise (setCenterAff store x y (setCenterOptionsIn options))
  , cancelConnection: store.dispatch CancelConnection
  , updateConnection: mkEffectFn1 \connection -> store.dispatch (UpdateConnection (liveConnectionIn connection))
  , reset: store.dispatch Reset
  }
  where
  updateIn :: JsInternalNodeUpdate -> InternalNodeUpdate
  updateIn u = { id: wrap u.id, nodeElement: u.nodeElement, force: fromMaybe false (fromUndefinable u.force) }

-- | Upstream's store `setCenter`: `false` with no pan-zoom instance, and
-- | otherwise `true` once the viewport has been set.
setCenterAff :: Store Foreign Foreign -> Number -> Number -> SetCenterOptions -> Aff Boolean
setCenterAff store x y options = do
  s <- liftEffect store.getState
  case s.panZoom of
    Nothing -> pure false
    Just pz -> do
      let zoom = fromMaybe s.maxZoom options.zoom
      _ <- pz.setViewport
        { x: s.width / 2.0 - x * zoom, y: s.height / 2.0 - y * zoom, zoom }
        (Just { duration: options.duration, ease: options.ease, interpolate: options.interpolate })
      pure true
