-- | The imperative `ReactFlowInstance`, crossing — boundary stage 3.
-- |
-- | Thirty-two members: nine general readers and writers, four `update…`
-- | methods, two intersection tests, two connection queries, `toObject`,
-- | `deleteElements`, `getNodesBounds`, `fitView`, the ten viewport helpers,
-- | and one plain `Boolean`. Nothing on this surface reaches a JavaScript
-- | consumer by more paths: `useReactFlow` returns it, `onInit` is handed it,
-- | and the net's `api` section is fourteen of these methods read as snapshot
-- | content.
-- |
-- | ## Why the instance and the hooks are one stage
-- |
-- | `useReactFlow` *returns* this record, so the hook cannot cross without the
-- | converter below and the converter is worth nothing without a hook that
-- | hands it out. Splitting them would have meant crossing a hook whose return
-- | value is still PureScript-shaped, which is the silent-wrong-shape failure
-- | the boundary module exists to remove.
-- |
-- | ## Three representations, and which is which
-- |
-- | Every method here changes shape in at least one of three ways, and it is
-- | worth naming them because the same three account for all thirty-two:
-- |
-- |   * **Currying.** `setCenter x y options` is three PureScript
-- |     applications and one JavaScript call, so every method of more than one
-- |     argument becomes an `EffectFn2`/`EffectFn3`. A curried method reached
-- |     from JavaScript returns a function where the caller expected a result,
-- |     which is the failure `getBezierPath` still has on the passthrough
-- |     surface.
-- |   * **`Effect` and `Aff`.** A nullary reader is an `Effect`, which is
-- |     already `() => a` in JavaScript and needs nothing. The eleven animated
-- |     or asynchronous methods are `Aff`, which is *not* a promise, and
-- |     `Boundary.Promise` is what makes `await instance.fitView()` wait for
-- |     the animation rather than for nothing.
-- |   * **`Maybe` and the untagged unions.** `getNode` answers `Maybe`, which
-- |     upstream spells `undefined`; `addNodes` takes `Node | Node[]`;
-- |     `setNodes` takes React's `SetStateAction`; and the two `update…`
-- |     methods take a **partial** where ps-flow's updater takes a whole
-- |     element.
-- |
-- | ## The merge is part of the conversion, not new behaviour
-- |
-- | `updateNode` is the one place that needs saying out loud. Upstream's
-- | second argument is `Partial<Node> | ((node) => Partial<Node>)` and
-- | ps-flow's is `Node -> Node`, a *total* function of the whole element.
-- | There is no way to turn a partial into a total function without performing
-- | upstream's merge, so the merge lives here — including `options.replace`,
-- | which ps-flow's internals accept and ignore. Leaving `replace` out would
-- | have given a consumer who asked for replacement a silent merge, which is
-- | this module's own failure mode wearing the other hat.
-- |
-- | The same reading settles `updateNodeData`, and there it is load-bearing:
-- | ps-flow's `updateNodeData` is byte-for-byte its `updateNode` and does not
-- | touch `data` at all, so the data merge upstream performs is supplied here
-- | too. That is a divergence in the internals rather than in the crossing, and
-- | it is recorded on the divergence backlog; what this module owes the
-- | consumer meanwhile is upstream's contract.
-- |
-- | ## What the compiler holds, and what a gate has to
-- |
-- | Inbound arguments are compiler-checked the usual way: building the
-- | PureScript record or calling the PureScript method forces a value of the
-- | right type for each. **Outbound** — every `JsNode`, `JsEdge`,
-- | `JsHandleConnection` and `JsRect` this module produces — is not, exactly as
-- | it is not for `nodeOut`, so `parity/boundary/drift.mjs` compares
-- | `ReactFlowInstance` against `JsReactFlowInstance` label for label and the
-- | four record shapes below against their PureScript counterparts.
module Boundary.Instance
  ( JsDeleteElementsOptions
  , JsDeletedElements
  , JsFitBoundsOptions
  , JsHandleConnection
  , JsHandleConnectionsParams
  , JsNodeConnectionsParams
  , JsReactFlowInstance
  , JsReactFlowJsonObject
  , JsRect
  , JsScreenToFlowOptions
  , JsSetCenterOptions
  , JsUpdateOptions
  , JsViewportHelperOptions
  , fitBoundsOptionsIn
  , handleConnectionOut
  , instanceOut
  , setCenterOptionsIn
  , viewportHelperOptionsIn
  ) where

import Prelude

import Boundary.Elements
  ( JsEdge
  , JsInternalNode
  , JsNode
  , JsViewport
  , JsXYPosition
  , edgeIn
  , edgeOut
  , internalNodeOut
  , nodeIn
  , nodeOut
  , snapGridIn
  , viewportIn
  , viewportOut
  )
import Boundary.Enums (handleTypeIn, interpolateModeIn)
import Boundary.FitView (JsFitViewOptions, fitViewOptionsIn)
import Boundary.Promise (Promise, toPromise)
import Boundary.SetState (setStateOut)
import Boundary.Undefined (Undefinable, fromUndefinable, toUndefinable)
import Boundary.Untagged (asFunction, asString, oneOrMany, typeName)
import Data.Either (Either(..))
import Data.Int (round) as Int
import Data.Maybe (Maybe(..), maybe)
import Data.Newtype (unwrap, wrap)
import Effect (Effect)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried
  ( EffectFn1
  , EffectFn2
  , EffectFn3
  , mkEffectFn1
  , mkEffectFn2
  , mkEffectFn3
  )
import Foreign (Foreign)
import React.Types.Edges (Edge)
import React.Types.Instance
  ( FitBoundsOptions
  , NodeOrIdOrRect(..)
  , NodeRefForBounds(..)
  , ReactFlowInstance
  , ScreenToFlowOptions
  , UpdateOptions
  , ZoomOptions
  )
import React.Types.Nodes (Node)
import System.Types.Connection (HandleConnection, InterpolateMode, SetCenterOptions)
import Unsafe.Coerce (unsafeCoerce)

-- ────────────────────────────────────────────────────────────────────────
-- The JS shapes
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream `Rect`. Named here rather than in `Boundary.Elements` because
-- | this is the first crossing that produces one: `getNodesBounds` returns it
-- | and `fitBounds`/`isNodeIntersecting` take it.
type JsRect = { x :: Number, y :: Number, width :: Number, height :: Number }

-- | Upstream `ReactFlowJsonObject`. `toObject`'s return, and the richest
-- | single observation the net has available — three sections of a trace read
-- | off one call.
type JsReactFlowJsonObject =
  { nodes :: Array JsNode
  , edges :: Array JsEdge
  , viewport :: JsViewport
  }

-- | Upstream `DeleteElementsOptions`. Each member is `Node | { id }`, and both
-- | forms collapse to the same thing: ps-flow's `Either String (Node n)` is
-- | read for its id on both branches and nothing else, so the crossing reads
-- | `.id` once and produces the `Left`.
type JsDeleteElementsOptions =
  { nodes :: Undefinable (Array Foreign)
  , edges :: Undefinable (Array Foreign)
  }

type JsDeletedElements =
  { deletedNodes :: Array JsNode
  , deletedEdges :: Array JsEdge
  }

-- | Upstream's `{ replace: boolean }`, which is optional at the call site.
type JsUpdateOptions = { replace :: Boolean }

-- | Upstream `ViewportHelperFunctionOptions`, shared by `zoomIn`, `zoomOut`,
-- | `zoomTo` and `setViewport`.
type JsViewportHelperOptions =
  { duration :: Undefinable Number
  , ease :: Undefinable (Number -> Number)
  , interpolate :: Undefinable String
  }

-- | `ViewportHelperFunctionOptions & { zoom?: number }`.
type JsSetCenterOptions =
  { duration :: Undefinable Number
  , ease :: Undefinable (Number -> Number)
  , interpolate :: Undefinable String
  , zoom :: Undefinable Number
  }

-- | `ViewportHelperFunctionOptions & { padding?: number }`.
type JsFitBoundsOptions =
  { duration :: Undefinable Number
  , ease :: Undefinable (Number -> Number)
  , interpolate :: Undefinable String
  , padding :: Undefinable Number
  }

-- | `screenToFlowPosition`'s second argument.
type JsScreenToFlowOptions =
  { snapToGrid :: Undefinable Boolean
  , snapGrid :: Undefinable (Array Number)
  }

-- | `Connection & { edgeId }`, which is what both connection queries return.
-- | Upstream's `HandleConnection` and `NodeConnection` are the same shape and
-- | ps-flow's `NodeConnection` is literally a synonym for its `HandleConnection`,
-- | so one type serves both.
type JsHandleConnection =
  { source :: String
  , target :: String
  , sourceHandle :: Undefinable String
  , targetHandle :: Undefinable String
  , edgeId :: String
  }

-- | `getHandleConnections`' argument. The rename is the one every nested type
-- | tag on this surface carries: PureScript keeps `type` for the element's own
-- | tag, so the handle's kind is `handleType` there and `type` here.
type JsHandleConnectionsParams =
  { "type" :: String
  , nodeId :: String
  , id :: Undefinable String
  }

-- | `getNodeConnections`' argument. Upstream keeps `handleType` unabbreviated
-- | on this one — the two queries disagree with each other, not with ps-flow —
-- | so there is no rename here and there is one above.
type JsNodeConnectionsParams =
  { handleType :: Undefinable String
  , nodeId :: String
  , handleId :: Undefinable String
  }

-- | The instance as a JavaScript caller sees it.
-- |
-- | Field for field with `React.Types.Instance.ReactFlowInstance`, which
-- | `parity/boundary/drift.mjs` checks: no renames, nothing refused, and a
-- | thirty-third member added to either side fails the gate.
type JsReactFlowInstance =
  { getNodes :: Effect (Array JsNode)
  , setNodes :: EffectFn1 Foreign Unit
  , addNodes :: EffectFn1 Foreign Unit
  , getNode :: EffectFn1 String (Undefinable JsNode)
  , getInternalNode :: EffectFn1 String (Undefinable JsInternalNode)
  , getEdges :: Effect (Array JsEdge)
  , setEdges :: EffectFn1 Foreign Unit
  , addEdges :: EffectFn1 Foreign Unit
  , getEdge :: EffectFn1 String (Undefinable JsEdge)
  , toObject :: Effect JsReactFlowJsonObject
  , deleteElements :: EffectFn1 JsDeleteElementsOptions (Promise JsDeletedElements)
  , getIntersectingNodes ::
      EffectFn3 Foreign (Undefinable Boolean) (Undefinable (Array JsNode)) (Array JsNode)
  , isNodeIntersecting :: EffectFn3 Foreign JsRect (Undefinable Boolean) Boolean
  , updateNode :: EffectFn3 String Foreign (Undefinable JsUpdateOptions) Unit
  , updateNodeData :: EffectFn3 String Foreign (Undefinable JsUpdateOptions) Unit
  , updateEdge :: EffectFn3 String Foreign (Undefinable JsUpdateOptions) Unit
  , updateEdgeData :: EffectFn3 String Foreign (Undefinable JsUpdateOptions) Unit
  , getNodesBounds :: EffectFn1 (Array Foreign) JsRect
  , getHandleConnections :: EffectFn1 JsHandleConnectionsParams (Array JsHandleConnection)
  , getNodeConnections :: EffectFn1 JsNodeConnectionsParams (Array JsHandleConnection)
  , fitView :: EffectFn1 (Undefinable JsFitViewOptions) (Promise Boolean)
  , zoomIn :: EffectFn1 (Undefinable JsViewportHelperOptions) (Promise Boolean)
  , zoomOut :: EffectFn1 (Undefinable JsViewportHelperOptions) (Promise Boolean)
  , zoomTo :: EffectFn2 Number (Undefinable JsViewportHelperOptions) (Promise Boolean)
  , getZoom :: Effect Number
  , setViewport :: EffectFn2 JsViewport (Undefinable JsViewportHelperOptions) (Promise Boolean)
  , getViewport :: Effect JsViewport
  , setCenter :: EffectFn3 Number Number (Undefinable JsSetCenterOptions) (Promise Boolean)
  , fitBounds :: EffectFn2 JsRect (Undefinable JsFitBoundsOptions) (Promise Boolean)
  , screenToFlowPosition ::
      EffectFn2 JsXYPosition (Undefinable JsScreenToFlowOptions) JsXYPosition
  , flowToScreenPosition :: EffectFn1 JsXYPosition JsXYPosition
  , viewportInitialized :: Boolean
  }

-- ────────────────────────────────────────────────────────────────────────
-- The crossing
-- ────────────────────────────────────────────────────────────────────────

-- | The whole instance, method by method.
-- |
-- | Written as one record literal rather than thirty-two named converters
-- | because the record type is what checks it: a member missed here is a
-- | compile error, and a member whose shape is wrong is one too. Only the
-- | four options bags and the two narrowings are lifted out, because each has
-- | more than one caller.
instanceOut :: ReactFlowInstance Foreign Foreign -> JsReactFlowInstance
instanceOut i =
  { getNodes: map nodeOut <$> i.getNodes

  , setNodes: setStateOut "setNodes" nodeIn nodeOut i.setNodes

  -- `Node | Node[]`. ps-flow takes the array, which is the wider form.
  , addNodes: mkEffectFn1 \payload -> i.addNodes (map jsNode (oneOrMany payload))

  , getNode: mkEffectFn1 \id -> toUndefinable <<< map nodeOut <$> i.getNode id

  , getInternalNode: mkEffectFn1 \id ->
      toUndefinable <<< map internalNodeOut <$> i.getInternalNode id

  , getEdges: map edgeOut <$> i.getEdges

  , setEdges: setStateOut "setEdges" edgeIn edgeOut i.setEdges

  , addEdges: mkEffectFn1 \payload -> i.addEdges (map jsEdge (oneOrMany payload))

  , getEdge: mkEffectFn1 \id -> toUndefinable <<< map edgeOut <$> i.getEdge id

  , toObject: do
      o <- i.toObject
      pure
        { nodes: map nodeOut o.nodes
        , edges: map edgeOut o.edges
        , viewport: viewportOut o.viewport
        }

  , deleteElements: mkEffectFn1 \options ->
      toPromise do
        deleted <- i.deleteElements
          { nodes: map (map (elementRef "deleteElements.nodes")) (fromUndefinable options.nodes)
          , edges: map (map (elementRef "deleteElements.edges")) (fromUndefinable options.edges)
          }
        pure
          { deletedNodes: map nodeOut deleted.deletedNodes
          , deletedEdges: map edgeOut deleted.deletedEdges
          }

  , getIntersectingNodes: mkEffectFn3 \target partially nodes ->
      map nodeOut <$>
        i.getIntersectingNodes
          (nodeOrIdOrRect "getIntersectingNodes" target)
          (fromUndefinable partially)
          (map (map nodeIn) (fromUndefinable nodes))

  , isNodeIntersecting: mkEffectFn3 \target area partially ->
      i.isNodeIntersecting
        (nodeOrIdOrRect "isNodeIntersecting" target)
        area
        (fromUndefinable partially)

  -- The two `update…` pairs. `merge` is upstream's `{ ...element, ...update }`
  -- and `replace` its documented escape from it; see the module header for why
  -- both live here rather than in the internals.
  , updateNode: mkEffectFn3 \id update options ->
      i.updateNode id
        (elementUpdater nodeOut nodeIn update (replaceWanted options))
        (updateOptionsIn options)

  , updateNodeData: mkEffectFn3 \id update options ->
      i.updateNodeData id
        (dataUpdater nodeOut nodeIn update (replaceWanted options))
        (updateOptionsIn options)

  , updateEdge: mkEffectFn3 \id update options ->
      i.updateEdge id
        (elementUpdater edgeOut edgeIn update (replaceWanted options))
        (updateOptionsIn options)

  , updateEdgeData: mkEffectFn3 \id update options ->
      i.updateEdgeData id
        (dataUpdater edgeOut edgeIn update (replaceWanted options))
        (updateOptionsIn options)

  , getNodesBounds: mkEffectFn1 \refs ->
      i.getNodesBounds (map (nodeRefForBounds "getNodesBounds") refs)

  , getHandleConnections: mkEffectFn1 \params ->
      map handleConnectionOut <$>
        i.getHandleConnections
          { handleType: handleTypeIn "getHandleConnections.type" params."type"
          , nodeId: params.nodeId
          , id: fromUndefinable params.id
          }

  , getNodeConnections: mkEffectFn1 \params ->
      map handleConnectionOut <$>
        i.getNodeConnections
          { handleType:
              map (handleTypeIn "getNodeConnections.handleType")
                (fromUndefinable params.handleType)
          , nodeId: params.nodeId
          , handleId: fromUndefinable params.handleId
          }

  , fitView: mkEffectFn1 \options ->
      toPromise (i.fitView (map fitViewOptionsIn (fromUndefinable options)))

  , zoomIn: mkEffectFn1 \options ->
      toPromise (i.zoomIn (viewportHelperOptionsIn "zoomIn" options))

  , zoomOut: mkEffectFn1 \options ->
      toPromise (i.zoomOut (viewportHelperOptionsIn "zoomOut" options))

  , zoomTo: mkEffectFn2 \level options ->
      toPromise (i.zoomTo level (viewportHelperOptionsIn "zoomTo" options))

  , getZoom: i.getZoom

  , setViewport: mkEffectFn2 \viewport options ->
      toPromise
        (i.setViewport (viewportIn viewport) (viewportHelperOptionsIn "setViewport" options))

  , getViewport: viewportOut <$> i.getViewport

  , setCenter: mkEffectFn3 \x y options ->
      toPromise (i.setCenter x y (setCenterOptionsIn options))

  , fitBounds: mkEffectFn2 \bounds options ->
      toPromise (i.fitBounds bounds (fitBoundsOptionsIn options))

  , screenToFlowPosition: mkEffectFn2 \position options ->
      i.screenToFlowPosition position (screenToFlowOptionsIn options)

  , flowToScreenPosition: mkEffectFn1 i.flowToScreenPosition

  , viewportInitialized: i.viewportInitialized
  }

-- ────────────────────────────────────────────────────────────────────────
-- The narrowings
-- ────────────────────────────────────────────────────────────────────────

-- | `Node | { id } | Rect`, which upstream narrows with `isRectObject` first
-- | and `isNode` second. The order is upstream's and is kept: a rect is four
-- | finite numbers, a whole element is anything carrying a `position`, and a
-- | bare reference is what is left.
nodeOrIdOrRect :: String -> Foreign -> NodeOrIdOrRect Foreign
nodeOrIdOrRect field raw
  | isRectObject raw = RectArg (unsafeCoerce raw)
  | positionField raw = NodeArg (nodeIn (unsafeCoerce raw))
  | otherwise = case asString (identityField raw) of
      Just id -> IdArg (wrap id)
      Nothing ->
        badArgument field
          "a node, `{ id }` or a rect ({ x, y, width, height })"
          (typeName raw)

-- | `Node | InternalNode | string`, for `getNodesBounds`. An internal node is
-- | told from a plain one by `internals`, which is the field that makes it one.
nodeRefForBounds :: String -> Foreign -> NodeRefForBounds Foreign
nodeRefForBounds field raw = case asString raw of
  Just id -> BoundsId (wrap id)
  Nothing
    | internalsField raw -> BoundsInternal (unsafeCoerce raw)
    | positionField raw -> BoundsNode (nodeIn (unsafeCoerce raw))
    | otherwise ->
        badArgument field "a node, an internal node or a node id" (typeName raw)

-- | `Node | { id }`, for `deleteElements`. ps-flow's `Either String (Node n)`
-- | is read for its id on both branches and for nothing else, so both forms
-- | reduce to the `Left` and the `Right` is unreachable by construction.
elementRef :: forall a. String -> Foreign -> Either String a
elementRef field raw = case asString (identityField raw) of
  Just id -> Left id
  Nothing -> badArgument field "elements carrying an `id`" (typeName raw)

badArgument :: forall a. String -> String -> String -> a
badArgument field expected got =
  unsafeThrow $
    "ps-flow: `" <> field <> "` takes " <> expected <> ", got " <> got <> "."

-- ────────────────────────────────────────────────────────────────────────
-- The updaters
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream's `Partial<T> | ((element: T) => Partial<T>)`, as ps-flow's
-- | `T -> T`.
-- |
-- | The partial is resolved against the element the internals hand us, so the
-- | consumer's function sees a JS-shaped element exactly as upstream's does,
-- | and what they return is merged over it. `replace` skips the merge, which
-- | is upstream's own branch — with upstream's own guard, that the value be a
-- | whole element rather than a partial, since replacing with a partial would
-- | leave a node with no `position`.
elementUpdater
  :: forall js ps
   . (ps -> js)
  -> (js -> ps)
  -> Foreign
  -> Boolean
  -> (ps -> ps)
elementUpdater outward inward update replace = \element ->
  let
    current = unsafeCoerce (outward element) :: Foreign
    next = resolveUpdate update current
  in
    if replace && wholeElement next then inward (unsafeCoerce next)
    else inward (unsafeCoerce (mergeInto current next))

-- | The same, one level down. Upstream's `updateNodeData` merges into `data`
-- | rather than into the element, hands the consumer's function the whole
-- | element even though what comes back is only the data, and honours
-- | `replace` by dropping the previous data rather than the previous element.
dataUpdater
  :: forall js ps
   . (ps -> js)
  -> (js -> ps)
  -> Foreign
  -> Boolean
  -> (ps -> ps)
dataUpdater outward inward update replace = \element ->
  let
    current = unsafeCoerce (outward element) :: Foreign
    nextData = resolveUpdate update current
    merged = if replace then nextData else mergeInto (dataField current) nextData
  in
    inward (unsafeCoerce (mergeInto current (asDataField merged)))

-- | `typeof update === 'function' ? update(current) : update`, which is the
-- | first line of all four of upstream's `update…` methods.
resolveUpdate :: Foreign -> Foreign -> Foreign
resolveUpdate update current = case asFunction update of
  Just f -> f current
  Nothing -> update

-- ────────────────────────────────────────────────────────────────────────
-- The options bags
-- ────────────────────────────────────────────────────────────────────────

-- | An absent bag and a bag with every member absent mean the same thing —
-- | upstream defaults the parameter to `{}` — so `member` flattens the two
-- | `Maybe`s and there is one branch here rather than two.
viewportHelperOptionsIn :: String -> Undefinable JsViewportHelperOptions -> ZoomOptions
viewportHelperOptionsIn field options =
  { duration: durationIn options _.duration
  , ease: member options _.ease
  , interpolate: interpolateIn field options _.interpolate
  }

setCenterOptionsIn :: Undefinable JsSetCenterOptions -> SetCenterOptions
setCenterOptionsIn options =
  { duration: durationIn options _.duration
  , ease: member options _.ease
  , interpolate: interpolateIn "setCenter" options _.interpolate
  , zoom: member options _.zoom
  }

fitBoundsOptionsIn :: Undefinable JsFitBoundsOptions -> FitBoundsOptions
fitBoundsOptionsIn options =
  { duration: durationIn options _.duration
  , ease: member options _.ease
  , interpolate: interpolateIn "fitBounds" options _.interpolate
  , padding: member options _.padding
  }

screenToFlowOptionsIn :: Undefinable JsScreenToFlowOptions -> ScreenToFlowOptions
screenToFlowOptionsIn options =
  { snapToGrid: member options _.snapToGrid
  , snapGrid:
      map (unwrap <<< snapGridIn "screenToFlowPosition.snapGrid")
        (member options _.snapGrid)
  }

-- | One member of an options bag that may itself be absent — two `Maybe`s
-- | flattened, which is what upstream's `options?.member` means.
member :: forall bag a. Undefinable bag -> (bag -> Undefinable a) -> Maybe a
member bag get = fromUndefinable bag >>= (get >>> fromUndefinable)

-- | `duration` is milliseconds, `number` upstream and `Int` in ps-flow. The
-- | rounding is the one `Boundary.FitView` applies to the option of this name.
durationIn :: forall bag. Undefinable bag -> (bag -> Undefinable Number) -> Maybe Int
durationIn bag get = map Int.round (member bag get)

interpolateIn
  :: forall bag
   . String
  -> Undefinable bag
  -> (bag -> Undefinable String)
  -> Maybe InterpolateMode
interpolateIn field bag get =
  map (interpolateModeIn (field <> ".interpolate")) (member bag get)

updateOptionsIn :: Undefinable JsUpdateOptions -> UpdateOptions
updateOptionsIn options = { replace: replaceWanted options }

-- | Upstream's default is `{ replace: false }`, so an absent bag and an absent
-- | member both mean merge.
replaceWanted :: Undefinable JsUpdateOptions -> Boolean
replaceWanted options = maybe false _.replace (fromUndefinable options)

-- ────────────────────────────────────────────────────────────────────────
-- Small outbound shapes
-- ────────────────────────────────────────────────────────────────────────

handleConnectionOut :: HandleConnection -> JsHandleConnection
handleConnectionOut c =
  { source: unwrap c.source
  , target: unwrap c.target
  , sourceHandle: toUndefinable c.sourceHandle
  , targetHandle: toUndefinable c.targetHandle
  , edgeId: c.edgeId
  }

-- ────────────────────────────────────────────────────────────────────────
-- Reading a `Foreign` that has already been narrowed
-- ────────────────────────────────────────────────────────────────────────
--
-- `addNodes`/`addEdges` take `T | T[]`, so their elements arrive as `Foreign`
-- once `oneOrMany` has split them and are converted one at a time. There is no
-- narrowing left to do: a caller who passed something that is not a node is
-- caught by `nodeIn` reading fields off it, exactly as they would have been had
-- they passed it inside the array form.

jsNode :: Foreign -> Node Foreign
jsNode = nodeIn <<< unsafeCoerce

jsEdge :: Foreign -> Edge Foreign
jsEdge = edgeIn <<< unsafeCoerce

-- | Upstream's `isRectObject`: four finite numbers under `x`, `y`, `width` and
-- | `height`.
foreign import isRectObject :: Foreign -> Boolean

-- | Whether the value carries a `position`, which is what upstream's `isNode`
-- | tests for and what tells a whole element from an `{ id }`.
foreign import positionField :: Foreign -> Boolean

-- | The `replace` guard, widened to cover both element kinds: upstream writes
-- | `isNode` on the node methods and `isEdge` on the edge ones, and an edge is
-- | identified by `source` where a node is by `position`. One test serves both
-- | because the two updaters are otherwise identical and neither kind answers
-- | the other's test — upstream's own `isNodeBase` excludes anything with a
-- | `source`.
foreign import wholeElement :: Foreign -> Boolean

foreign import internalsField :: Foreign -> Boolean

-- | `value.id`, read without asserting that the value has one — the caller
-- | folds the result through `asString` and reports the failure itself.
foreign import identityField :: Foreign -> Foreign

foreign import dataField :: Foreign -> Foreign

-- | `{ data: value }`, which is the half of the element `updateNodeData`
-- | replaces.
foreign import asDataField :: Foreign -> Foreign

-- | `{ ...target, ...source }`, upstream's merge, allocating rather than
-- | mutating: a consumer holding the element they were handed must not see it
-- | change under them.
foreign import mergeInto :: Foreign -> Foreign -> Foreign
