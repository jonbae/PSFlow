-- | The graph utilities a driver calls, crossing.
-- |
-- | `applyNodeChanges`, `applyEdgeChanges` and `addEdge`. A React consumer of
-- | `@xyflow/react` reaches these on the first interaction, not the tenth:
-- | upstream's own `Flow.tsx` wires all three, because a controlled flow hands
-- | the store nothing back unless the consumer applies the changes themselves.
-- |
-- | Two things had to cross for that to work from JavaScript.
-- |
-- | **The calling convention.** Each of these is a PureScript function of two
-- | or three arguments, which is two or three *nested* functions at runtime.
-- | `applyNodeChanges(changes, nodes)` therefore returns a function rather than
-- | an array, and the consumer's `setNodes` stores it — the same silent
-- | failure as the unrun `Effect` thunk this whole effort started from, one
-- | layer along. `Fn2` is the fix, and it is what upstream's own arity is.
-- |
-- | **Consumer objects.** Change helpers keep untouched original references
-- | and shallow-copy touched/add/replace objects, preserving enumerable keys,
-- | symbols and explicit undefined. addEdge follows the same raw-object policy.
-- | Closed typed element round trips cannot preserve those observables, so
-- | the boundary ports the source branches over Foreign while the core typed
-- | reducer remains in use internally. Native copying/mutation is FFI only;
-- | grouping, update, validation and duplicate decisions are PureScript.
-- |
-- | Nothing here is proven by construction. Value-for-value comparison against
-- | upstream's implementations is surface parity's call-and-compare, which
-- | covers all seventeen pure functions at once; `parity/boundary/mount.mjs`
-- | holds only the calling convention and the round trip.
-- |
-- | `getViewportForBounds` joined them in stage 5. It has no round trip — its
-- | arguments are plain numbers and a rect, and it returns a fresh viewport —
-- | but it had the calling convention's failure exactly: six nested functions
-- | where upstream takes six arguments. What else it needed is its `padding`,
-- | below, and `parity/boundary/viewport.test.mjs` holds both against upstream
-- | entered from JavaScript.
-- |
-- | `getConnectedEdges` also reuses the existing graph implementation, while
-- | filtering the consumer's original objects so identity and custom fields
-- | survive. Its direct-call witness is `parity/boundary/connected-edges.test.mjs`.
-- | `getIncomers` keeps the same original-node contract, accepting an id-only
-- | query; `parity/boundary/incomers.test.mjs` also holds its early-return guard.
module Boundary.Utils
  ( JsAddEdgeOptions
  , addEdge
  , applyEdgeChanges
  , applyNodeChanges
  , getConnectedEdges
  , getIncomers
  , getNodesBounds
  , getOutgoers
  , getViewportForBounds
  , isEdge
  , isNode
  , reconnectEdge
  ) where

import Prelude

import Boundary.Callbacks (JsOnError)
import Boundary.Elements
  ( JsConnection
  , JsEdge
  , JsEdgeChange
  , JsNode
  , JsNodeChange
  , connectionIn
  )
import Boundary.Undefined (Undefinable, fromUndefinable, undefined)
import Boundary.Untagged (asNumber, asString, typeName)
import Data.Array as Array
import Data.Foldable (foldM, traverse_)
import Data.Function.Uncurried (Fn2, Fn3, mkFn2, mkFn3, runFn2)
import Data.Maybe (Maybe(..), isJust)
import Data.Number (infinity, isNaN) as Number
import Data.String (Pattern(..))
import Data.String.CodeUnits (stripSuffix)
import Effect (Effect)
import Effect.Console (error, warn) as Console
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, EffectFn4, EffectFn6, mkEffectFn2, mkEffectFn4, mkEffectFn6, runEffectFn1, runEffectFn2, runEffectFn3, runEffectFn4)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import System.Constants (ErrorCode(..), errorMessage)
import System.Types.Connection (Padding(..), PaddingValue(..), Viewport)
import System.Types.Edge (EdgeBase)
import System.Types.Geometry (Box, NodeOrigin(..), Rect, XYPosition)
import System.Types.Ids (NodeId)
import System.Types.Node (NodeBase)
import System.Utils.Edges.General (getEdgeId) as PS
import System.Utils.General (boxToRect, getNodePositionWithOrigin, getViewportForBounds, rectToBox) as PS
import System.Utils.Graph (getConnectedEdges, getIncomers, getOutgoers) as Graph
import Unsafe.Coerce (unsafeCoerce)
import Unsafe.Reference (unsafeRefEq)

-- ────────────────────────────────────────────────────────────────────────
-- The change appliers
-- ────────────────────────────────────────────────────────────────────────

applyNodeChanges :: Fn2 (Array JsNodeChange) (Array JsNode) (Array JsNode)
applyNodeChanges = mkFn2 \changes nodes ->
  unsafeCoerce $ unsafePerformEffect $ applyConsumerChanges (unsafeCoerce changes) (unsafeCoerce nodes)

applyEdgeChanges :: Fn2 (Array JsEdgeChange) (Array JsEdge) (Array JsEdge)
applyEdgeChanges = mkFn2 \changes edges ->
  unsafeCoerce $ unsafePerformEffect $ applyConsumerChanges (unsafeCoerce changes) (unsafeCoerce edges)

-- | The raw JS counterpart of React.Store.Changes. Keep upstream's buckets,
-- | terminal-change precedence and one shallow copy per changed element. The
-- | typed reducer remains the value implementation for internal PS callers;
-- | decoding here would erase the consumer's keys, absence and references.
applyConsumerChanges :: Array Foreign -> Array Foreign -> Effect (Array Foreign)
applyConsumerChanges changes elements = do
  changesMap <- newChangeMap
  additions <- newConsumerArray
  updated <- newConsumerArray
  traverse_ (\change -> do
    adding <- fieldEquals "type" "add" change
    if adding then pushConsumer additions change
    else do
      removing <- fieldEquals "type" "remove" change
      replacing <- if removing then pure false else fieldEquals "type" "replace" change
      if removing || replacing then do
        id <- boundsField "id" change
        runEffectFn3 setChangeMap changesMap id [ change ]
      else do
        id <- boundsField "id" change
        bucket <- runEffectFn2 boundsMapGet changesMap id
        if boundsTruthy bucket then pushConsumer (unsafeCoerce bucket) change
        else do
          nextId <- boundsField "id" change
          runEffectFn3 setChangeMap changesMap nextId [ change ]
    ) changes
  traverse_ (\element -> do
    id <- boundsField "id" element
    rawBucket <- runEffectFn2 boundsMapGet changesMap id
    if not (boundsTruthy rawBucket) then pushConsumer updated element
    else do
      let bucket = unsafeCoerce rawBucket :: Array Foreign
      case Array.head bucket of
        Nothing -> pure unit
        Just first -> do
          removing <- fieldEquals "type" "remove" first
          unless removing do
            replacing <- fieldEquals "type" "replace" first
            if replacing then do
              item <- boundsField "item" first
              copied <- runEffectFn1 copyEnumerable item
              pushConsumer updated copied
            else do
              copied <- runEffectFn1 copyEnumerable element
              traverse_ (\change -> applyConsumerChange change copied) bucket
              pushConsumer updated copied
    ) elements
  traverse_ (\change -> do
    index <- boundsField "index" change
    if typeName index /= "undefined" then do
      nextIndex <- boundsField "index" change
      item <- boundsField "item" change
      copied <- runEffectFn1 copyEnumerable item
      runEffectFn3 spliceConsumer updated nextIndex copied
    else do
      item <- boundsField "item" change
      copied <- runEffectFn1 copyEnumerable item
      pushConsumer updated copied
    ) additions
  pure updated

applyConsumerChange :: Foreign -> Foreign -> Effect Unit
applyConsumerChange change element = do
  changeType <- boundsField "type" change
  case asString changeType of
    Just "select" -> boundsField "selected" change >>= writeConsumer "selected" element
    Just "position" -> do
      writeDefined "position"
      writeDefined "dragging"
    Just "dimensions" -> do
      dimensions <- boundsField "dimensions" change
      when (typeName dimensions /= "undefined") do
        nextDimensions <- boundsField "dimensions" change
        measured <- runEffectFn1 copyEnumerable nextDimensions
        writeConsumer "measured" element measured
        attributes <- boundsField "setAttributes" change
        when (boundsTruthy attributes) do
          setDimension "width"
          setDimension "height"
      resizing <- boundsField "resizing" change
      when (typeName resizing == "boolean") do
        boundsField "resizing" change >>= writeConsumer "resizing" element
    _ -> pure unit
  where
  writeDefined key = do
    value <- boundsField key change
    when (typeName value /= "undefined") do
      boundsField key change >>= writeConsumer key element

  setDimension key = do
    attribute <- boundsField "setAttributes" change
    matches <- if unsafeRefEq attribute (unsafeCoerce true) then pure true
      else fieldEquals "setAttributes" key change
    when matches do
      dimensions <- boundsField "dimensions" change
      boundsField key dimensions >>= writeConsumer key element

fieldEquals :: String -> String -> Foreign -> Effect Boolean
fieldEquals key expected object = do
  value <- boundsField key object
  pure (asString value == Just expected)

writeConsumer :: String -> Foreign -> Foreign -> Effect Unit
writeConsumer key object value = runEffectFn3 writeProperty key object value

pushConsumer :: Array Foreign -> Foreign -> Effect Unit
pushConsumer = runEffectFn2 pushConsumerImpl

foreign import newChangeMap :: Effect Foreign
foreign import setChangeMap :: EffectFn3 Foreign Foreign (Array Foreign) Unit
foreign import newConsumerArray :: Effect (Array Foreign)
foreign import pushConsumerImpl :: EffectFn2 (Array Foreign) Foreign Unit
foreign import spliceConsumer :: EffectFn3 (Array Foreign) Foreign Foreign Unit
foreign import writeProperty :: EffectFn3 String Foreign Foreign Unit

-- | Only `id`, `source` and `target` are read by the retained graph function.
-- | These strings have the same runtime representation as its newtyped ids.
-- | Keep the original objects: an element in/out round trip would allocate
-- | copies and discard consumer fields. No optional/ADT fields are read here.
getConnectedEdges :: Fn2 (Array JsNode) (Array JsEdge) (Array JsEdge)
getConnectedEdges = mkFn2 \nodes edges ->
  unsafeCoerce
    ( Graph.getConnectedEdges
        (unsafeCoerce nodes :: Array (NodeBase Foreign))
        (unsafeCoerce edges :: Array (EdgeBase Foreign))
    )

-- | A query needs only its id. As above, the retained traversal reads raw
-- | string ids and filters the original nodes without an element round trip.
-- | Upstream returns before reading either array when the id is absent; the
-- | core's empty-string guard handles the remaining falsy string case.
getIncomers :: Fn3 { id :: String } (Array JsNode) (Array JsEdge) (Array JsNode)
getIncomers = mkFn3 \node nodes edges ->
  case fromUndefinable (unsafeCoerce node.id :: Undefinable String) of
    Nothing -> []
    Just _ -> unsafeCoerce
      ( Graph.getIncomers
          (unsafeCoerce node :: { id :: NodeId })
          (unsafeCoerce nodes :: Array (NodeBase Foreign))
          (unsafeCoerce edges :: Array (EdgeBase Foreign))
      )

-- | The outgoing counterpart: only query/edge ids are read, and the core
-- | filters original nodes in their input order. Keep the absence guard at
-- | the boundary and the empty-string guard in the retained traversal.
getOutgoers :: Fn3 { id :: String } (Array JsNode) (Array JsEdge) (Array JsNode)
getOutgoers = mkFn3 \node nodes edges ->
  case fromUndefinable (unsafeCoerce node.id :: Undefinable String) of
    Nothing -> []
    Just _ -> unsafeCoerce
      ( Graph.getOutgoers
          (unsafeCoerce node :: { id :: NodeId })
          (unsafeCoerce nodes :: Array (NodeBase Foreign))
          (unsafeCoerce edges :: Array (EdgeBase Foreign))
      )

-- | The JS union and lookup-selection rules do not fit the core's decoded
-- | node-array/PureScript-Map interface. Translate those branches here, using
-- | the existing origin and rect geometry after reading only geometry fields.
getNodesBounds :: EffectFn1 (Array Foreign) Rect
getNodesBounds = withBoundsOptions $ mkEffectFn2 \nodes rawParams -> do
  let params = if typeName rawParams == "undefined"
        then unsafeCoerce { nodeOrigin: [ 0.0, 0.0 ] }
        else rawParams
  development <- boundsDevelopment
  when development do
    lookup <- boundsField "nodeLookup" params
    unless (boundsTruthy lookup) $ Console.warn
      "Please use `getNodesBounds` from `useReactFlow`/`useSvelteFlow` hook to ensure correct values for sub flows. If not possible, you have to provide a nodeLookup to support sub flows."
  if Array.null nodes then pure { x: 0.0, y: 0.0, width: 0.0, height: 0.0 }
  else do
    box <- foldM (accumulateBounds params)
      { x: Number.infinity, y: Number.infinity, x2: -Number.infinity, y2: -Number.infinity }
      nodes
    pure (PS.boxToRect box)

accumulateBounds :: Foreign -> Box -> Foreign -> Effect Box
accumulateBounds params accumulated raw = do
  let isId = typeName raw == "string"
  firstLookup <- boundsField "nodeLookup" params
  let initial = if not (boundsTruthy firstLookup) && not isId
        then raw else unsafeCoerce (undefined :: Undefinable Foreign)
  lookup <- boundsField "nodeLookup" params
  current <- if boundsTruthy lookup then
      if isId then do
        activeLookup <- boundsField "nodeLookup" params
        runEffectFn2 boundsMapGet activeLookup raw
      else if boundsInternal raw then pure raw
      else do
        activeLookup <- boundsField "nodeLookup" params
        id <- boundsField "id" raw
        runEffectFn2 boundsMapGet activeLookup id
    else pure initial
  box <- if boundsTruthy current then do
      origin <- boundsField "nodeOrigin" params
      position <- boundsPosition current origin
      width <- boundsDimension "width" current
      height <- boundsDimension "height" current
      pure (PS.rectToBox { x: position.x, y: position.y, width, height })
    else pure { x: 0.0, y: 0.0, x2: 0.0, y2: 0.0 }
  pure
    { x: boundsMin accumulated.x box.x
    , y: boundsMin accumulated.y box.y
    , x2: boundsMax accumulated.x2 box.x2
    , y2: boundsMax accumulated.y2 box.y2
    }

-- Math.min/Math.max propagate NaN and distinguish the signs of zero.
-- Keep that numeric behavior local to this crossing; the core stays read-only.
boundsMin :: Number -> Number -> Number
boundsMin a b
  | Number.isNaN a = a
  | Number.isNaN b = b
  | a == 0.0 && b == 0.0 = if 1.0 / a < 0.0 then a else b
  | otherwise = min a b

boundsMax :: Number -> Number -> Number
boundsMax a b
  | Number.isNaN a = a
  | Number.isNaN b = b
  | a == 0.0 && b == 0.0 = if 1.0 / a > 0.0 then a else b
  | otherwise = max a b

boundsPosition :: Foreign -> Foreign -> Effect XYPosition
boundsPosition node defaultOrigin
  | boundsInternal node = do
      internals <- boundsField "internals" node
      position <- boundsField "positionAbsolute" internals
      x <- boundsField "x" position
      y <- boundsField "y" position
      pure { x: unsafeCoerce x, y: unsafeCoerce y }
  | otherwise = do
      width <- boundsDimension "width" node
      height <- boundsDimension "height" node
      ownOrigin <- boundsField "origin" node
      let selected = case boundsPresent ownOrigin of
            Just supplied -> supplied
            Nothing -> defaultOrigin
      origin <- if typeName selected == "undefined" then pure (NodeOrigin { ox: 0.0, oy: 0.0 })
        else do
          ox <- boundsField "0" selected
          oy <- boundsField "1" selected
          pure (NodeOrigin { ox: unsafeCoerce ox, oy: unsafeCoerce oy })
      positionForX <- boundsField "position" node
      x <- boundsField "x" positionForX
      positionForY <- boundsField "position" node
      y <- boundsField "y" positionForY
      pure $ PS.getNodePositionWithOrigin
        { position: { x: unsafeCoerce x, y: unsafeCoerce y }
        , origin: Just origin
        , measured: { width: Just width, height: Just height }
        , width: Nothing, height: Nothing, initialWidth: Nothing, initialHeight: Nothing
        }
        origin

boundsDimension :: String -> Foreign -> Effect Number
boundsDimension dimension node = do
  measured <- boundsField "measured" node
  measuredValue <- case boundsPresent measured of
    Just supplied -> boundsField dimension supplied
    Nothing -> pure (unsafeCoerce (undefined :: Undefinable Foreign))
  case boundsPresent measuredValue of
    Just supplied -> pure (unsafeCoerce supplied)
    Nothing -> do
      explicit <- boundsField dimension node
      case boundsPresent explicit of
        Just supplied -> pure (unsafeCoerce supplied)
        Nothing -> do
          initial <- boundsField (if dimension == "width" then "initialWidth" else "initialHeight") node
          pure case boundsPresent initial of
            Just supplied -> unsafeCoerce supplied
            Nothing -> 0.0

boundsPresent :: Foreign -> Maybe Foreign
boundsPresent raw = fromUndefinable (unsafeCoerce raw)

boundsField :: String -> Foreign -> Effect Foreign
boundsField = runEffectFn2 readProperty

boundsInternal :: Foreign -> Boolean
boundsInternal raw = runFn2 boundsHasProperty "id" raw
  && runFn2 boundsHasProperty "internals" raw
  && not (runFn2 boundsHasProperty "source" raw)
  && not (runFn2 boundsHasProperty "target" raw)

foreign import withBoundsOptions
  :: EffectFn2 (Array Foreign) Foreign Rect -> EffectFn1 (Array Foreign) Rect
foreign import boundsHasProperty :: Fn2 String Foreign Boolean
foreign import boundsTruthy :: Foreign -> Boolean
foreign import boundsMapGet :: EffectFn2 Foreign Foreign Foreign
foreign import boundsDevelopment :: Effect Boolean

-- | Upstream's shape guard uses property presence, not truthiness or a total
-- | object predicate. Native `in` also accepts functions and throws on primitives.
isNode :: Foreign -> Boolean
isNode raw = runFn2 boundsHasProperty "id" raw
  && runFn2 boundsHasProperty "position" raw
  && not (runFn2 boundsHasProperty "source" raw)
  && not (runFn2 boundsHasProperty "target" raw)

isEdge :: Foreign -> Boolean
isEdge raw = runFn2 boundsHasProperty "id" raw
  && runFn2 boundsHasProperty "source" raw
  && runFn2 boundsHasProperty "target" raw

-- | React's option spread/default precedes the system function. Keep original
-- | consumer objects and native rest/spread semantics instead of decoding them
-- | into closed records. The typed core and its PureScript callers stay intact.
reconnectEdge :: EffectFn3 Foreign Foreign (Array JsEdge) (Array JsEdge)
reconnectEdge = withReconnectOptions $ mkEffectFn4 \old connection edges rawOptions -> do
  let supplied = if typeName rawOptions == "undefined"
        then unsafeCoerce { shouldReplaceId: true } else rawOptions
  copied <- runEffectFn1 copyEnumerable supplied
  rawError <- boundsField "onError" supplied
  let onError = case boundsPresent rawError of
        Nothing -> unsafeCoerce defaultReconnectError
        Just callback -> callback
  options <- runEffectFn2 mergeEnumerable copied (unsafeCoerce { onError })
  oldParts <- runEffectFn1 splitEdgeIdentity old
  source <- boundsField "source" connection
  valid <- if boundsTruthy source then boundsTruthy <$> boundsField "target" connection else pure false
  if not valid then do
    reconnectError options "006" (errorMessage E006)
    pure edges
  else case Array.find (\edge -> edgeIdField (unsafeCoerce edge) == edgeIdField old) edges of
    Nothing -> missingEdge options oldParts.value edges
    Just found | not (boundsTruthy (unsafeCoerce found)) -> missingEdge options oldParts.value edges
    Just _ -> do
      generator <- boundsField "getEdgeId" options
      replace <- boundsField "shouldReplaceId" options
      id <- if boundsTruthy replace then
          if boundsTruthy generator then runEffectFn1 (unsafeCoerce generator) connection
          else unsafeCoerce <$> reconnectId connection
        else pure oldParts.value
      nextSource <- boundsField "source" connection
      nextTarget <- boundsField "target" connection
      sourceHandle <- boundsField "sourceHandle" connection
      targetHandle <- boundsField "targetHandle" connection
      next <- runEffectFn2 mergeEnumerable oldParts.rest
        (unsafeCoerce { id, source: nextSource, target: nextTarget, sourceHandle, targetHandle })
      pure $ Array.snoc
        (Array.filter (\edge -> edgeIdField (unsafeCoerce edge) /= (unsafeCoerce oldParts.value :: String)) edges)
        (unsafeCoerce next)
  where
  missingEdge options oldId currentEdges = do
    text <- runEffectFn1 interpolate oldId
    reconnectError options "007" (errorMessage (E007 text))
    pure currentEdges

edgeIdField :: Foreign -> String
edgeIdField raw = (unsafeCoerce raw :: { id :: String }).id

reconnectId :: Foreign -> Effect String
reconnectId connection = do
  source <- boundsField "source" connection
  sourceHandle <- boundsField "sourceHandle" connection
  target <- boundsField "target" connection
  targetHandle <- boundsField "targetHandle" connection
  sourceText <- runEffectFn1 interpolate source
  sourceHandleText <- if boundsTruthy sourceHandle then runEffectFn1 interpolate sourceHandle else pure ""
  targetText <- runEffectFn1 interpolate target
  targetHandleText <- if boundsTruthy targetHandle then runEffectFn1 interpolate targetHandle else pure ""
  pure $ PS.getEdgeId $ connectionIn $ unsafeCoerce
    { source: sourceText, target: targetText, sourceHandle: sourceHandleText, targetHandle: targetHandleText }

reconnectError :: Foreign -> String -> String -> Effect Unit
reconnectError options code message = do
  callback <- boundsField "onError" options
  case boundsPresent callback of
    Nothing -> pure unit
    Just fn -> runEffectFn4 invokeBinary fn options code message

defaultReconnectError :: EffectFn2 String String Unit
defaultReconnectError = mkEffectFn2 \code message -> do
  development <- boundsDevelopment
  when development $ Console.warn ("[React Flow]: " <> message <> " Help: https://reactflow.dev/error#" <> code)

foreign import withReconnectOptions
  :: EffectFn4 Foreign Foreign (Array JsEdge) Foreign (Array JsEdge)
  -> EffectFn3 Foreign Foreign (Array JsEdge) (Array JsEdge)
foreign import copyEnumerable :: EffectFn1 Foreign Foreign
foreign import splitEdgeIdentity :: EffectFn1 Foreign { value :: Foreign, rest :: Foreign }
foreign import mergeEnumerable :: EffectFn2 Foreign Foreign Foreign
foreign import invokeBinary :: EffectFn4 Foreign Foreign String String Unit

-- ────────────────────────────────────────────────────────────────────────
-- addEdge
-- ────────────────────────────────────────────────────────────────────────

-- | Both optional React-layer addEdge options; callbacks receive original JS
-- | objects. The default parameter keeps the public arity at two.
type JsAddEdgeOptions =
  { getEdgeId :: Undefinable (JsConnection -> String)
  , onError :: Undefinable JsOnError
  }

addEdge :: Fn2 Foreign (Array JsEdge) (Array JsEdge)
addEdge = withDefaultedOptions (mkFn3 \edgeParams edges rawOptions ->
  unsafePerformEffect (addEdgeWithOptions edgeParams edges rawOptions))

addEdgeWithOptions :: Foreign -> Array JsEdge -> Foreign -> Effect (Array JsEdge)
addEdgeWithOptions edgeParams edges rawOptions = do
  let supplied = if typeName rawOptions == "undefined" then unsafeCoerce {} else rawOptions
  copied <- runEffectFn1 copyEnumerable supplied
  rawError <- boundsField "onError" supplied
  let onError = case boundsPresent rawError of
        Nothing -> unsafeCoerce defaultReconnectError
        Just callback -> callback
  options <- runEffectFn2 mergeEnumerable copied (unsafeCoerce { onError })
  source <- boundsField "source" edgeParams
  valid <- if boundsTruthy source then boundsTruthy <$> boundsField "target" edgeParams else pure false
  if not valid then do
    reconnectError options "006" (errorMessage E006)
    pure edges
  else do
    generator <- boundsField "getEdgeId" options
    let complete = isEdge edgeParams
    edgeCopy <- runEffectFn1 copyEnumerable edgeParams
    edge <- if complete then pure edgeCopy
      else do
        id <- if boundsTruthy generator then runEffectFn1 (unsafeCoerce generator) edgeParams
          else unsafeCoerce <$> reconnectId edgeParams
        runEffectFn2 mergeEnumerable edgeCopy (unsafeCoerce { id })
    exists <- foldM (\found existing -> if found then pure true
      else connectionExists edge (unsafeCoerce existing)) false edges
    if exists then pure edges
    else do
      sourceHandle <- boundsField "sourceHandle" edge
      when (typeName sourceHandle == "null") $ runEffectFn2 deleteProperty "sourceHandle" edge
      targetHandle <- boundsField "targetHandle" edge
      when (typeName targetHandle == "null") $ runEffectFn2 deleteProperty "targetHandle" edge
      unsafeCoerce <$> runEffectFn2 concatConsumer (unsafeCoerce edges) edge

-- | The same strict equality/falsy-handle predicate and short-circuit reads as
-- | system connectionExists. Compare raw values, including explicit undefined.
connectionExists :: Foreign -> Foreign -> Effect Boolean
connectionExists edge existing = do
  sourceMatches <- equalField "source"
  if not sourceMatches then pure false
  else do
    targetMatches <- equalField "target"
    if not targetMatches then pure false
    else do
      sourceMatchesHandle <- equalHandle "sourceHandle"
      if sourceMatchesHandle then equalHandle "targetHandle" else pure false
  where
  equalField key = do
    left <- boundsField key existing
    right <- boundsField key edge
    pure (unsafeRefEq left right)
  equalHandle key = do
    equal <- equalField key
    if equal then pure true
    else do
      left <- boundsField key existing
      if boundsTruthy left then pure false
      else not <<< boundsTruthy <$> boundsField key edge

foreign import deleteProperty :: EffectFn2 String Foreign Unit
foreign import concatConsumer :: EffectFn2 (Array Foreign) Foreign (Array Foreign)
foreign import withDefaultedOptions
  :: forall a b r. Fn3 a b Foreign r -> Fn2 a b r

-- ────────────────────────────────────────────────────────────────────────
-- getViewportForBounds
-- ────────────────────────────────────────────────────────────────────────

-- | `getViewportForBounds(bounds, width, height, minZoom, maxZoom, padding)`.
-- |
-- | All six at once, as upstream declares them — and none with a default, so
-- | `Function.length` is six. `padding` is declared too, which is why a
-- | consumer who omits it is a consumer who passed `undefined`.
-- |
-- | An `EffectFn6` and not an `Fn6` because it is not pure from JavaScript:
-- | a malformed padding writes to the console, as upstream's does, and a
-- | `null` one throws. Both happen during the call, in upstream's order, and
-- | the arithmetic after them is `System.Utils.General`'s, unchanged.
getViewportForBounds :: EffectFn6 Rect Number Number Number Number Foreign Viewport
getViewportForBounds = mkEffectFn6 \bounds width height minZoom maxZoom rawPadding -> do
  padding <- viewportPaddingIn rawPadding
  pure (PS.getViewportForBounds bounds width height minZoom maxZoom padding)

-- | Upstream's `parsePaddings`, reading the JavaScript value directly.
-- |
-- | This is **not** `Boundary.FitView.paddingIn`, and the differences are the
-- | point. That converter reads an *option*, one level below a bag whose
-- | `padding` is folded through `Boundary.Undefined` first, so `null` never
-- | reaches it. Here the padding is a positional argument with no default and
-- | nothing above it: `undefined` arrives as itself and takes upstream's third
-- | branch, and `null` arrives as itself and takes upstream's *second* —
-- | `typeof null` is `'object'` — whose first `padding.top` throws the
-- | platform's own `TypeError`. That is reproduced by reading the property,
-- | not by composing a message: `readProperty` on `null` is the same read.
-- |
-- | The branches, in upstream's order:
-- |
-- |   * a string or number is one padding for every side. Upstream parses it
-- |     twice — against the height, then the width — so a malformed one is
-- |     reported twice.
-- |   * an object (an array, `null`) is read side by side, each side resolved
-- |     and parsed before the next is read: top, bottom, left, right.
-- |   * anything else — `undefined`, a boolean, a function — is zero on every
-- |     side, with nothing parsed and so nothing reported.
viewportPaddingIn :: Foreign -> Effect Padding
viewportPaddingIn raw = case typeName raw of
  "string" -> uniform
  "number" -> uniform
  "object" -> directional
  "array" -> directional
  "null" -> directional
  _ -> pure noPadding
  where
  uniform = case paddingValueIn raw of
    Just value -> pure (UniformPadding value)
    Nothing -> do
      reportInvalidPadding raw
      reportInvalidPadding raw
      pure noPadding

  directional = do
    top <- sideIn "top" "y"
    bottom <- sideIn "bottom" "y"
    left <- sideIn "left" "x"
    right <- sideIn "right" "x"
    -- Every side is resolved here, so the `x`/`y` fallback inside
    -- `System.Utils.General.parsePaddings` is never consulted: upstream
    -- applies it before parsing, and parsing is where it reports.
    pure $ DirectionalPadding
      { top: Just top
      , right: Just right
      , bottom: Just bottom
      , left: Just left
      , x: Nothing
      , y: Nothing
      }

  -- `parsePadding(padding[side] ?? padding[axis] ?? 0, …)`. The trailing `0`
  -- is a number, so it parses as a ratio of zero, which is zero.
  sideIn side axis = do
    resolved <- coalesce side axis
    case resolved of
      Nothing -> pure (RatioPadding 0.0)
      Just value -> parsePaddingValue value

  coalesce side axis = do
    first <- runEffectFn2 readProperty side raw
    if isNullish first then do
      second <- runEffectFn2 readProperty axis raw
      pure if isNullish second then Nothing else Just second
    else pure (Just first)

-- | Upstream's `parsePaddings` third branch: `{ top: 0, …, x: 0, y: 0 }`.
-- |
-- | `PxPadding 0.0` for the reason `Boundary.FitView.invalidPadding` gives:
-- | upstream's zero is a pixel count, and a ratio of zero arriving at the same
-- | number would be arithmetic rather than agreement.
noPadding :: Padding
noPadding = UniformPadding (PxPadding 0.0)

-- | One side through upstream's `parsePadding`: the value, or the message and
-- | zero.
parsePaddingValue :: Foreign -> Effect PaddingValue
parsePaddingValue raw = case paddingValueIn raw of
  Just value -> pure value
  Nothing -> do
    reportInvalidPadding raw
    pure (PxPadding 0.0)

-- | Which of upstream's three successful `parsePadding` branches a value
-- | takes, or `Nothing` for its fallthrough.
-- |
-- | The number branch has no guard: `NaN` and `Infinity` are numbers and are
-- | ratios, and what they compute to is the geometry's business. The string
-- | branches test the suffix and then `parseFloat` the **whole** string, which
-- | stops at the first character it cannot read — so `"12garbagepx"` is twelve
-- | pixels and `"Infinitypx"` infinite ones, where a stricter parse would
-- | report both. Only a `NaN` falls through.
paddingValueIn :: Foreign -> Maybe PaddingValue
paddingValueIn raw = case asNumber raw of
  Just ratio -> Just (RatioPadding ratio)
  Nothing -> asString raw >>= \s ->
    if endsWith "px" s && not (Number.isNaN (parseFloat s)) then
      Just (PxPadding (parseFloat s))
    else if endsWith "%" s && not (Number.isNaN (parseFloat s)) then
      Just (PctPadding (parseFloat s))
    else Nothing
  where
  endsWith suffix s = isJust (stripSuffix (Pattern suffix) s)

-- | Upstream's message, verbatim, through `console.error` with the one
-- | argument upstream passes.
reportInvalidPadding :: Foreign -> Effect Unit
reportInvalidPadding raw = do
  described <- runEffectFn1 interpolate raw
  Console.error $
    "The padding value \"" <> described
      <> "\" is invalid. Please provide a number or a string with a valid unit (px or %)."

-- | `==` against `null`: what `??` tests.
isNullish :: Foreign -> Boolean
isNullish value = case typeName value of
  "null" -> true
  "undefined" -> true
  _ -> false

-- | `object[key]`, with the platform's own semantics — including the
-- | `TypeError` a read on `null` throws, whose message is the platform's.
foreign import readProperty :: EffectFn2 String Foreign Foreign

-- | The global `parseFloat`, prefix-reading and `NaN` on failure.
-- | `Data.Number.fromString` is not it: that one refuses non-finite results.
foreign import parseFloat :: String -> Number

-- | `` `${value}` ``, the coercion upstream's message template applies.
foreign import interpolate :: EffectFn1 Foreign String
