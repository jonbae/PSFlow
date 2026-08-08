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
import Boundary.Undefined (Undefinable, fromUndefinable, isDefined)
import Data.Either (Either(..))
import Data.Function.Uncurried (Fn2, Fn3, mkFn2, mkFn3)
import Data.Maybe (Maybe(..))
import Effect.Exception.Unsafe (unsafeThrow)
import Foreign (Foreign)
import React.Store.Changes (applyEdgeChanges, applyNodeChanges) as PS
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
type JsAddEdgeOptions =
  { getEdgeId :: Undefinable (JsConnection -> String)
  -- Refused. Present so it can be seen and rejected, never read.
  , onError :: Undefinable Foreign
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
    -- back the array it was given. With `onError` refused above there is
    -- nobody to report to, so this returns the caller's own array — not a
    -- round-tripped copy of it, because nothing happened to it.
    Left _ -> edges
    Right next -> map edgeOut next
  where
  options = map guardAddEdgeOptions (fromUndefinable rawOptions)

  generate :: PS.GetEdgeId
  generate = case options >>= (fromUndefinable <<< _.getEdgeId) of
    Just custom -> custom <<< connectionOut
    Nothing -> PS.getEdgeId

  edge =
    if isEdgeBase edgeParams then edgeIn (unsafeCoerce edgeParams)
    else edgeFromConnection generate (connectionIn (unsafeCoerce edgeParams))

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
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | `onError` is a callback, and callbacks land in boundary stage 2. Refused
-- | rather than ignored for the reason every deferred prop is: a handler that
-- | is never called looks exactly like a handler the consumer never passed,
-- | and this one is the only signal that `addEdge` declined to add anything.
guardAddEdgeOptions :: JsAddEdgeOptions -> JsAddEdgeOptions
guardAddEdgeOptions o
  | isDefined o.onError =
      unsafeThrow
        "ps-flow: `addEdge`'s `options.onError` has not crossed the JavaScript \
        \boundary yet — it lands in boundary stage 2 (the callback props). It \
        \is refused rather than ignored so that a handler ps-flow would never \
        \call fails loudly instead of looking like a handler you did not pass."
guardAddEdgeOptions o = o

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
