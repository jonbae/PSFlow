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
module Boundary.Utils
  ( JsAddEdgeOptions
  , addEdge
  , applyEdgeChanges
  , applyNodeChanges
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
import Data.Either (Either(..))
import Data.Function.Uncurried (Fn2, Fn3, mkFn2, mkFn3)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (runEffectFn2)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Store.Changes (applyEdgeChanges, applyNodeChanges) as PS
import System.Constants (ErrorCode(..), errorMessage)
import System.Types.Connection (Connection)
import System.Types.Edge (EdgeBase)
import System.Utils.Edges.General (GetEdgeId, addEdge, getEdgeId) as PS
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
  , animated: false
  , hidden: false
  , deletable: Nothing
  , selectable: Nothing
  , data: Nothing
  , selected: false
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
