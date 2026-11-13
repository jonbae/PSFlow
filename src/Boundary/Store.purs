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
-- | ## Precise exclusions
-- |
-- | Each of these throws with a message naming the call:
-- |
-- |   * `setState(_, true)` and a non-object `setState` partial, which replace
-- |     upstream's whole state. ps-flow's internals read a complete record.
-- |   * A value of the wrong type for a typed member, such as
-- |     `setState({ minZoom: "2" })`. Upstream stores it and fails later.
-- |   * A `panZoom`, `fitViewResolver` or middleware map the store did not
-- |     hand out. Those are created by ps-flow's own pane and hooks.
-- |   * Calling a callback member that PureScript code installed. Every
-- |     callback a JavaScript consumer installs reads back as itself.
module Boundary.Store
  ( JsStoreApi
  , JsStoreView
  , storeViewOf
  , useStoreApiObject
  , selectorThrough
  , equalityFor
  , panZoomOut
  ) where

import Prelude

import Boundary.Callbacks
  ( connectionStateOut
  , isValidConnectionIn
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
  , onSelectionChangeIn
  , onViewportChangeIn
  , selectionDragHandlerIn
  , withInProgress
  )
import Boundary.Elements
  ( JsInternalNode
  , JsHandle
  , JsXYPosition
  , coordinateExtentIn
  , coordinateExtentOut
  , defaultEdgeOptionsIn
  , defaultEdgeOptionsOut
  , edgeChangeIn
  , edgeChangeOut
  , edgeIdentityOut
  , edgeIn
  , handleIn
  , internalNodeIn
  , internalNodeOut
  , nodeChangeIn
  , nodeChangeOut
  , nodeExtentIn
  , nodeIdentityOut
  , nodeIn
  , nodeOriginIn
  , nodeOriginOut
  , snapGridIn
  )
import Boundary.Enums (connectionModeIn, handleTypeIn, interpolateModeIn, panOnScrollModeIn, positionIn, zIndexModeIn)
import Boundary.FitView (JsFitViewOptions, fitViewOptionsIn)
import Boundary.Flow (JsAriaLabelConfig, ariaLabelConfigIn, panOnDragIn)
import Boundary.Instance (JsHandleConnection, handleConnectionOut, setCenterOptionsIn)
import Boundary.Original (originalOf, remembering)
import Boundary.Promise (toPromise)
import Boundary.Undefined (Undefinable, fromUndefinable, isDefined, isNull, pruneUndefined, toUndefinable, undefined)
import Boundary.Untagged (asArray, asBoolean, asFunction, asNumber, asString, typeName)
import Data.Array (catMaybes, filter, nub, reverse) as Array
import Data.Function.Uncurried (mkFn1)
import Data.List (fromFoldable, toUnfoldable) as List
import Data.Map (Map)
import Data.Map (fromFoldable, keys, lookup, toUnfoldable) as Map
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.Newtype (unwrap, wrap)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Data.Set (fromFoldable, member, toUnfoldable) as Set
import Data.String (null) as String
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.AVar (AVar)
import Effect.Aff.AVar (kill, put, read) as AVar
import Effect.Class (liftEffect)
import Effect.Exception (error)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (EffectFn1, mkEffectFn1, mkEffectFn2, mkEffectFn3, runEffectFn1)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Object (Object)
import React.FFI.Env (isDevelopment)
import React.Store.Action (Action(..))
import React.Store.PanBy (panBy) as StorePanBy
import React.Store.Shell (Store)
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
import React.Types.Store (ConnectionClickStartHandle, MiddlewareKey(..), ReactFlowState)
import System.XYDrag (OnNodeDrag, OnSelectionDrag)
import System.XYHandle (OnConnect, OnConnectEnd, OnConnectStart)
import System.Constants (AriaLabelConfig, mergeAriaLabelConfig)
import System.Types.Connection (ConnectionLookup, ConnectionMode(..), ConnectionState(..), HandleConnection, HandleConnections, InterpolateMode(..), SetCenterOptions, Padding(..), PaddingValue(..), SelectionRect, ZIndexMode(..))
import System.Types.Edge (EdgeBase, EdgeChange, EdgeLookup)
import System.Types.Geometry (CoordinateExtent, NodeOrigin, SnapGrid, Transform(..))
import System.Types.Node (InternalNodeBase, InternalNodeUpdate, NodeBase, NodeChange, NodeDragItem, NodeLookup, OnError, ParentLookup)
import System.FFI.D3Zoom (ZoomTransform)
import System.Types.PanZoom (PanZoomInstance, PanZoomTransformOptions, PanZoomUpdateOptions)
import System.Utils.General (devWarn)
import System.Utils.Graph (FitViewOptions)
import Unsafe.Coerce (unsafeCoerce)
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
foreign import middlewareSymbol :: Int -> Foreign
foreign import newMap :: Array (Array Foreign) -> Foreign
foreign import mapEntriesImpl :: Foreign -> Nullable (Array (Array Foreign))
foreign import refusingFunction :: String -> Foreign
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
  , keys :: Array String
  , fields :: Object Foreign
  , actions :: Foreign
  , replaceRefusal :: String
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
  , keys: stateKeys
  , fields: unsafeCoerce stateFields
  , actions: actionsOut store
  , replaceRefusal:
      "ps-flow: `setState` cannot replace the whole state — a `true` second "
        <> "argument, or a partial that is not an object, replaces upstream's "
        <> "state outright, and ps-flow's internals read every member of theirs. "
        <> "Pass an object of the members to change."
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
  , fitViewResolver :: Field (Maybe (AVar Boolean))
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
  , onNodesChangeMiddlewareMap :: Field (Map MiddlewareKey (Array (NodeChange Foreign) -> Array (NodeChange Foreign)))
  , onEdgesChangeMiddlewareMap :: Field (Map MiddlewareKey (Array (EdgeChange Foreign) -> Array (EdgeChange Foreign)))
  }

-- | Every member's `Field`.
stateFields :: StateFields
stateFields =
  { rfId: string "rfId"
  , width: number "width"
  , height: number "height"
  , transform: plain transformOut (transformIn "transform")
  , nodes: plain nodesOut (listOf "nodes" (reversible nodeIn))
  , nodesInitialized: boolean "nodesInitialized"
  , nodeLookup: field nodeLookupOut (nodeLookupIn "nodeLookup")
  , parentLookup: field parentLookupOut (parentLookupIn "parentLookup")
  , edges: plain edgesOut (listOf "edges" (reversible edgeIn))
  , edgeLookup: field edgeLookupOut (edgeLookupIn "edgeLookup")
  , connectionLookup: field connectionLookupOut (connectionLookupIn "connectionLookup")
  , onNodesChange: callback nullValue "onNodesChange" onNodesChangeIn
  , onEdgesChange: callback nullValue "onEdgesChange" onEdgesChangeIn
  , hasDefaultNodes: boolean "hasDefaultNodes"
  , hasDefaultEdges: boolean "hasDefaultEdges"
  , domNode: plain (unsafeToForeign <<< toNullable) domNodeIn
  , paneDragging: boolean "paneDragging"
  , noPanClassName: string "noPanClassName"
  , panZoom: plain (maybe nullValue panZoomOut) (createdHere "panZoom")
  , minZoom: number "minZoom"
  , maxZoom: number "maxZoom"
  , translateExtent: plain (unsafeToForeign <<< coordinateExtentOut) (coordinateExtentIn "translateExtent" <<< unsafeCoerce)
  , nodeExtent: plain (unsafeToForeign <<< coordinateExtentOut) (coordinateExtentIn "nodeExtent" <<< unsafeCoerce)
  , nodeOrigin: plain (unsafeToForeign <<< nodeOriginOut) (nodeOriginIn "nodeOrigin" <<< unsafeCoerce)
  , nodeDragThreshold: number "nodeDragThreshold"
  , connectionDragThreshold: number "connectionDragThreshold"
  , nodesSelectionActive: boolean "nodesSelectionActive"
  , userSelectionActive: boolean "userSelectionActive"
  , userSelectionRect: plain (unsafeToForeign <<< toNullable) selectionRectIn
  , connection: plain liveConnectionOut liveConnectionIn
  , connectionMode: plain connectionModeOut (connectionModeIn "connectionMode" <<< stringIn "connectionMode")
  , connectionClickStartHandle: plain clickStartOut clickStartIn
  , snapToGrid: boolean "snapToGrid"
  , snapGrid: plain (\g -> unsafeToForeign [ (unwrap g).gx, (unwrap g).gy ]) (snapGridIn "snapGrid" <<< unsafeCoerce)
  , nodesDraggable: boolean "nodesDraggable"
  , autoPanOnNodeFocus: boolean "autoPanOnNodeFocus"
  , nodesConnectable: boolean "nodesConnectable"
  , nodesFocusable: boolean "nodesFocusable"
  , edgesFocusable: boolean "edgesFocusable"
  , edgesReconnectable: boolean "edgesReconnectable"
  , elementsSelectable: boolean "elementsSelectable"
  , elevateNodesOnSelect: boolean "elevateNodesOnSelect"
  , elevateEdgesOnSelect: boolean "elevateEdgesOnSelect"
  , selectNodesOnDrag: boolean "selectNodesOnDrag"
  , multiSelectionActive: boolean "multiSelectionActive"
  , onNodeDragStart: optionalCallback "onNodeDragStart" onNodeDragIn
  , onNodeDrag: optionalCallback "onNodeDrag" onNodeDragIn
  , onNodeDragStop: optionalCallback "onNodeDragStop" onNodeDragIn
  , onSelectionDragStart: optionalCallback "onSelectionDragStart" (unsafeCoerce selectionDragHandlerIn)
  , onSelectionDrag: optionalCallback "onSelectionDrag" (unsafeCoerce selectionDragHandlerIn)
  , onSelectionDragStop: optionalCallback "onSelectionDragStop" (unsafeCoerce selectionDragHandlerIn)
  , onMoveStart: optionalCallback "onMoveStart" (unsafeCoerce onMoveIn)
  , onMove: optionalCallback "onMove" onMoveIn
  , onMoveEnd: optionalCallback "onMoveEnd" (unsafeCoerce onMoveIn)
  , onConnect: optionalCallback "onConnect" onConnectIn
  , onConnectStart: optionalCallback "onConnectStart" onConnectStartIn
  , onConnectEnd: optionalCallback "onConnectEnd" onConnectEndIn
  , onClickConnectStart: optionalCallback "onClickConnectStart" onConnectStartIn
  , onClickConnectEnd: optionalCallback "onClickConnectEnd" onConnectEndIn
  , connectOnClick: boolean "connectOnClick"
  , defaultEdgeOptions:
      { toJs: \_ -> maybe absent (unsafeToForeign <<< defaultEdgeOptionsOut)
      , fromJs: absentOr (Just <<< defaultEdgeOptionsIn <<< unsafeCoerce)
      , optional: true
      }
  , fitViewQueued: boolean "fitViewQueued"
  , fitViewOptions: plain (maybe (unsafeToForeign undefined) fitViewOptionsOut)
      (absentOr (Just <<< remembering fitViewOptionsIn <<< (unsafeCoerce :: Foreign -> JsFitViewOptions)))
  , fitViewResolver: plain (maybe nullValue resolverOut) (createdHere "fitViewResolver")
  , onNodesDelete: optionalCallback "onNodesDelete" onNodesDeleteIn
  , onEdgesDelete: optionalCallback "onEdgesDelete" onEdgesDeleteIn
  , onDelete: optionalCallback "onDelete" onDeleteIn
  , onError: callback devWarnOut "onError" onErrorIn
  , onViewportChangeStart: optionalCallback "onViewportChangeStart" onViewportChangeIn
  , onViewportChange: optionalCallback "onViewportChange" onViewportChangeIn
  , onViewportChangeEnd: optionalCallback "onViewportChangeEnd" onViewportChangeIn
  , onBeforeDelete: optionalCallback "onBeforeDelete" onBeforeDeleteIn
  , onSelectionChangeHandlers:
      plain (unsafeToForeign <<< map (callbackOut "onSelectionChangeHandlers"))
        (listOf "onSelectionChangeHandlers" (functionIn "onSelectionChangeHandlers" onSelectionChangeIn))
  , ariaLiveMessage: string "ariaLiveMessage"
  , autoPanOnConnect: boolean "autoPanOnConnect"
  , autoPanOnNodeDrag: boolean "autoPanOnNodeDrag"
  , autoPanSpeed: number "autoPanSpeed"
  , connectionRadius: number "connectionRadius"
  , isValidConnection: callback (unsafeToForeign undefined) "isValidConnection" isValidConnectionIn
  , lib: string "lib"
  , debug: boolean "debug"
  , ariaLabelConfig: plain ariaLabelConfigOut (mergeAriaLabelConfig <<< ariaLabelConfigIn <<< (unsafeCoerce :: Foreign -> JsAriaLabelConfig))
  , zIndexMode: plain zIndexModeOut (zIndexModeIn "zIndexMode" <<< stringIn "zIndexMode")
  , onNodesChangeMiddlewareMap: plain (middlewareMapOut nodeChangeIn nodeChangeOut) (onlyHandedOut "onNodesChangeMiddlewareMap")
  , onEdgesChangeMiddlewareMap: plain (middlewareMapOut edgeChangeIn edgeChangeOut) (onlyHandedOut "onEdgesChangeMiddlewareMap")
  }

-- ────────────────────────────────────────────────────────────────────────
-- Field builders
-- ────────────────────────────────────────────────────────────────────────

field :: forall a. (State -> a -> Foreign) -> (Foreign -> a) -> Field a
field toJs fromJs = { toJs, fromJs, optional: false }

plain :: forall a. (a -> Foreign) -> (Foreign -> a) -> Field a
plain toJs = field (const toJs)

boolean :: String -> Field Boolean
boolean key = plain unsafeToForeign \v -> fromMaybe' (wrongType key "a boolean" v) (asBoolean v)

number :: String -> Field Number
number key = plain unsafeToForeign \v -> fromMaybe' (wrongType key "a number" v) (asNumber v)

string :: String -> Field String
string key = plain unsafeToForeign (stringIn key)

stringIn :: String -> Foreign -> String
stringIn key v = fromMaybe' (wrongType key "a string" v) (asString v)

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

-- | Members only ps-flow's own components create. One the store handed out
-- | is converted back before this runs; anything else is refused.
createdHere :: forall a. String -> Foreign -> Maybe a
createdHere key = absentOr \v ->
  unsafeThrow $
    "ps-flow: the store member `" <> key <> "` accepts `null` or a value read "
      <> "from this store, got "
      <> typeName v
      <> " — ps-flow's pane and hooks create it, and a JavaScript object has no "
      <> "PureScript form to hand them."

-- | A member with no absent state that only ps-flow's hooks fill: the
-- | middleware maps. The map the store handed out is the only one accepted.
onlyHandedOut :: forall a. String -> Foreign -> a
onlyHandedOut key v =
  unsafeThrow $
    "ps-flow: the store member `" <> key <> "` accepts only the map read from "
      <> "this store, got "
      <> typeName v
      <> " — `experimental_useOnNodesChangeMiddleware` and "
      <> "`experimental_useOnEdgesChangeMiddleware` are what register middleware."

-- ────────────────────────────────────────────────────────────────────────
-- Callbacks
-- ────────────────────────────────────────────────────────────────────────

-- | The consumer's own function when one was converted, and otherwise a
-- | function that says why it cannot be called from JavaScript.
callbackOut :: forall f. String -> f -> Foreign
callbackOut key f = case originalOf f of
  Just original -> original
  Nothing ->
    refusingFunction $
      "ps-flow: the store's `" <> key <> "` was installed from PureScript, and "
        <> "ps-flow has no JavaScript form of it to call."

functionIn :: forall js ps. String -> (js -> ps) -> Foreign -> ps
functionIn key convert v = case asFunction v of
  Just _ -> remembering convert (unsafeCoerce v)
  Nothing -> wrongType key "a function" v unit

-- | A member upstream's initial state holds with a fixed value when nothing
-- | was set: `null` for the change handlers, `undefined` for
-- | `isValidConnection`, and `devWarn` for `onError`.
callback :: forall js ps. Foreign -> String -> (js -> ps) -> Field (Maybe ps)
callback whenAbsent key convert =
  plain (maybe whenAbsent (callbackOut key)) (absentOr (Just <<< functionIn key convert))

-- | A member upstream's state lacks until `StoreUpdater` sets it.
optionalCallback :: forall js ps. String -> (js -> ps) -> Field (Maybe ps)
optionalCallback key convert = (callback absent key convert) { optional = true }

-- | Upstream's default `onError`, `createDevWarn('React Flow', …)`.
devWarnOut :: Foreign
devWarnOut = unsafeToForeign (mkEffectFn2 (devWarn isDevelopment))

-- ────────────────────────────────────────────────────────────────────────
-- Nodes, edges and their lookups
-- ────────────────────────────────────────────────────────────────────────

nodeOutCached :: InternalNodeBase Foreign -> Foreign
nodeOutCached = reversibleImpl (unsafeToForeign <<< internalNodeOut)

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
    (\id -> map (\n -> entry (unwrap id) (nodeOutCached n)) (Map.lookup id lookup))
    (ordered (map _.id s.nodes) (Set.toUnfoldable (Map.keys lookup)))

parentLookupOut :: State -> ParentLookup Foreign -> Foreign
parentLookupOut s lookup =
  newMap $ Array.catMaybes $ map
    ( \parent -> map
        ( \children -> entry (unwrap parent) $ newMap $ Array.catMaybes $ map
            (\id -> map (\n -> entry (unwrap id) (nodeOutCached n)) (Map.lookup id children))
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

transformIn :: String -> Foreign -> Transform
transformIn key v = case map (map asNumber) (asArray v) of
  Just [ Just tx, Just ty, Just scale ] -> Transform { tx, ty, scale }
  _ -> wrongType key "[x, y, zoom]" v unit

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

-- | Upstream's `withResolvers<boolean>()` result, `{ promise, resolve,
-- | reject }`, over the `AVar` the queued `fitView` waits on.
resolverOut :: AVar Boolean -> Foreign
resolverOut = reversibleImpl \avar -> unsafeToForeign
  { promise: unsafePerformEffect (toPromise (AVar.read avar))
  , resolve: mkEffectFn1 \value -> launchAff_ (AVar.put value avar)
  , reject: mkEffectFn1 \reason -> launchAff_ (AVar.kill (error (rejectionText reason)) avar)
  }
  where
  rejectionText reason = fromMaybe (typeName reason) (asString reason)

-- | Each middleware under a `Symbol` of its own, taking and returning
-- | JavaScript changes.
middlewareMapOut
  :: forall c js
   . (js -> c)
  -> (c -> js)
  -> Map MiddlewareKey (Array c -> Array c)
  -> Foreign
middlewareMapOut changeIn changeOut middlewares =
  newMap $ map
    (\(Tuple (MiddlewareKey key) f) -> [ middlewareSymbol key, adapter f ])
    (Map.toUnfoldable middlewares :: Array _)
  where
  adapter f = unsafeToForeign (mkFn1 \changes -> map changeOut (f (map changeIn changes)))

-- | The pan-zoom instance's eleven members, with upstream's argument shapes.
panZoomOut :: PanZoomInstance -> Foreign
panZoomOut = reversibleImpl \pz -> unsafeToForeign
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

actionsOut :: Store Foreign Foreign -> Foreign
actionsOut store = unsafeToForeign
  { setNodes: mkEffectFn1 \nodes -> store.dispatch (SetNodes (listOf "setNodes" (reversible nodeIn) nodes))
  , setEdges: mkEffectFn1 \edges -> store.dispatch (SetEdges (listOf "setEdges" (reversible edgeIn) edges))
  , setDefaultNodesAndEdges: mkEffectFn2 \nodes edges ->
      store.dispatch
        ( SetDefaultNodesAndEdges
            (map (listOf "setDefaultNodesAndEdges" (reversible nodeIn)) (fromUndefinable nodes))
            (map (listOf "setDefaultNodesAndEdges" (reversible edgeIn)) (fromUndefinable edges))
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
  , triggerNodeChanges: mkEffectFn1 \changes -> store.dispatch (TriggerNodeChanges (map nodeChangeIn changes))
  , triggerEdgeChanges: mkEffectFn1 \changes -> store.dispatch (TriggerEdgeChanges (map edgeChangeIn changes))
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
