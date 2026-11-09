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
-- | **The round trip.** The values handed in are the ones the other half of
-- | this boundary produced — JS-shaped nodes, edges, changes and connections —
-- | and the values handed back go straight into `<ReactFlow nodes={…} />`. So
-- | every one of these is `in` on the way down and `out` on the way up, and
-- | the fields the PureScript records do not model are lost in the middle. That
-- | is not new here: `edgeIn` already drops an edge's `label` when the same
-- | edge is passed to `ReactFlow` directly. It is the same gap seen twice, and
-- | it is a census entry rather than something this module can fix.
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
module Boundary.Utils
  ( JsAddEdgeOptions
  , addEdge
  , applyEdgeChanges
  , applyNodeChanges
  , getViewportForBounds
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
  , connectionOut
  , edgeChangeIn
  , edgeIn
  , edgeOut
  , nodeChangeIn
  , nodeIn
  , nodeOut
  )
import Boundary.Undefined (Undefinable, fromUndefinable)
import Boundary.Untagged (asNumber, asString, typeName)
import Data.Either (Either(..))
import Data.Function.Uncurried (Fn2, Fn3, mkFn2, mkFn3)
import Data.Maybe (Maybe(..), isJust)
import Data.Number (isNaN) as Number
import Data.String (Pattern(..))
import Data.String.CodeUnits (stripSuffix)
import Effect (Effect)
import Effect.Console (error) as Console
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn6, mkEffectFn6, runEffectFn1, runEffectFn2)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Store.Changes (applyEdgeChanges, applyNodeChanges) as PS
import System.Constants (ErrorCode(..), errorMessage)
import System.Types.Connection (Connection, Padding(..), PaddingValue(..), Viewport)
import System.Types.Edge (EdgeBase)
import System.Types.Geometry (Rect)
import System.Utils.Edges.General (GetEdgeId, addEdge, getEdgeId) as PS
import System.Utils.General (getViewportForBounds) as PS
import System.Utils.Graph (isEdgeBase)
import Unsafe.Coerce (unsafeCoerce)

-- ────────────────────────────────────────────────────────────────────────
-- The change appliers
-- ────────────────────────────────────────────────────────────────────────

applyNodeChanges :: Fn2 (Array JsNodeChange) (Array JsNode) (Array JsNode)
applyNodeChanges = mkFn2 \changes nodes ->
  map nodeOut (PS.applyNodeChanges (map nodeChangeIn changes) (map nodeIn nodes))

applyEdgeChanges :: Fn2 (Array JsEdgeChange) (Array JsEdge) (Array JsEdge)
applyEdgeChanges = mkFn2 \changes edges ->
  map edgeOut (PS.applyEdgeChanges (map edgeChangeIn changes) (map edgeIn edges))

-- ────────────────────────────────────────────────────────────────────────
-- addEdge
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream's `AddEdgeOptions`, both members of it.
-- |
-- | `getEdgeId` is honoured, and it is the one place on this surface where a
-- | consumer's function is called with a value this module produced rather
-- | than handed one it consumes — so the *outbound* connection converter is
-- | what makes it work. ps-flow's own `addEdge` takes a `GetEdgeId`
-- | positionally and never calls it (it demands a complete `Edge`), so the
-- | generator is applied here, where the connection becomes an edge.
-- |
-- | `onError` was refused until boundary stage 2 crossed the callbacks. It is
-- | the only signal a consumer gets that `addEdge` declined to add anything,
-- | and `reportAddEdgeError` below is where the code upstream reports beside
-- | the message comes back.
-- |
-- | **A consumer who passes none gets silence, where upstream warns.**
-- | Upstream's `addEdge` defaults the option — `onError: options.onError ??
-- | defaultOnError`, a `createDevWarn` — so an empty endpoint prints in
-- | development even when nobody asked. ps-flow has no `createDevWarn`, and
-- | inventing one here would be this module adding behaviour the internals do
-- | not have, which is the same thing refusing `MiniMap.nodeColor`'s string
-- | form avoids. The divergence is real and lands in the net's `console`
-- | section, which is the mechanism built to see it.
type JsAddEdgeOptions =
  { getEdgeId :: Undefinable (JsConnection -> String)
  , onError :: Undefinable JsOnError
  }

-- | `addEdge(edgeParams, edges, options?)`.
-- |
-- | `edgeParams` is upstream's `Edge | Connection`, untagged and narrowed at
-- | the use site — `isEdgeBase` is the narrowing upstream itself uses, and
-- | ps-flow already ports it as the `isEdge` export.
addEdge :: Fn2 Foreign (Array JsEdge) (Array JsEdge)
addEdge = withDefaultedOptions (mkFn3 addEdgeWithOptions)

addEdgeWithOptions
  :: Foreign -> Array JsEdge -> Undefinable JsAddEdgeOptions -> Array JsEdge
addEdgeWithOptions edgeParams edges rawOptions =
  case PS.addEdge edge (map edgeIn edges) generate of
    -- Upstream reports the empty endpoint through `options.onError` and hands
    -- back the array it was given — not a round-tripped copy of it, because
    -- nothing happened to it.
    Left message -> unsafePerformEffect do
      case options >>= (fromUndefinable <<< _.onError) of
        Nothing -> pure unit
        Just onError -> reportAddEdgeError onError message
      pure edges
    Right next -> map edgeOut next
  where
  options = fromUndefinable rawOptions

  generate :: PS.GetEdgeId
  generate = case options >>= (fromUndefinable <<< _.getEdgeId) of
    Just custom -> custom <<< connectionOut
    Nothing -> PS.getEdgeId

  edge =
    if isEdgeBase edgeParams then edgeIn (unsafeCoerce edgeParams)
    else edgeFromConnection generate (connectionIn (unsafeCoerce edgeParams))

-- | `onError` takes upstream's error **code** as well as its message, and
-- | ps-flow's `addEdge` returns only the message: `System.Constants.ErrorCode`
-- | is a sum whose tag `errorMessage` erases. So the code is restored here.
-- |
-- | It is restored by *checking* rather than by assuming. `addEdge` has exactly
-- | one failing branch today, `E006`, which is also the only error upstream's
-- | own `addEdge` reports — so a message that is not that one means a second
-- | failure mode was added to the internals with no code to carry it, and
-- | reporting it as `"006"` would be a wrong code the consumer cannot tell from
-- | a right one.
reportAddEdgeError :: JsOnError -> String -> Effect Unit
reportAddEdgeError onError message
  | message == errorMessage E006 = runEffectFn2 onError "006" message
  | otherwise =
      unsafeThrow $
        "ps-flow: `addEdge` failed with " <> show message
          <> ", which is not the one error it is able to report. `options.onError` "
          <> "takes upstream's error code as its first argument and there is no "
          <> "code for this one, so it is refused rather than reported under "
          <> "another error's."

-- | The `{ ...connection, id }` upstream builds, written as a record so that a
-- | field added to `EdgeBase` fails here rather than arriving undefined.
edgeFromConnection :: PS.GetEdgeId -> Connection -> EdgeBase Foreign
edgeFromConnection generate c =
  { id: generate c
  , edgeType: Nothing
  , source: c.source
  , target: c.target
  , sourceHandle: c.sourceHandle
  , targetHandle: c.targetHandle
  , animated: Nothing
  , hidden: Nothing
  , deletable: Nothing
  , selectable: Nothing
  , data: Nothing
  , selected: Nothing
  , markerStart: Nothing
  , markerEnd: Nothing
  , zIndex: Nothing
  , label: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
  }

-- ────────────────────────────────────────────────────────────────────────
-- The optional third argument
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream declares `options` with a default (`options: AddEdgeOptions = {}`),
-- | so its `length` is **two** and a consumer may call it either way.
-- | PureScript has no default parameters, and a bare `Fn3` would report an
-- | arity of three — a shape difference a JavaScript consumer can see, and one
-- | surface parity compares. This restores it: the `Fn2` is what PureScript
-- | may call, and the third argument is the one it never passes.
foreign import withDefaultedOptions
  :: forall a b options r. Fn3 a b (Undefinable options) r -> Fn2 a b r

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
