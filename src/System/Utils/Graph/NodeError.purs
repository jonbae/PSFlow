-- | Structured failure and fallback conditions for `calculateNodePosition`
-- | (`System.Utils.Graph`). Ticket 050 #3.
-- |
-- | ## Why this module exists
-- |
-- | `calculateNodePosition` collapses THREE distinct outcomes that the TS
-- | source keeps separate, all into `Nothing`/silent fallbacks:
-- |
-- |   1. the node id is absent from the `NodeLookup` — TS uses the non-null
-- |      assertion `nodeLookup.get(id)!` and would otherwise crash; there is
-- |      no `ErrorCode` for this case;
-- |   2. an `extent: 'parent'` node has no resolvable parent — TS calls
-- |      `onError('005', …)` then falls through to the default extents;
-- |   3. the node has no measured width/height — TS calls `onError('015', …)`
-- |      then substitutes `?? 0`.
-- |
-- | ## The contract decision: fatal vs non-fatal
-- |
-- | Cases 2 and 3 are *non-fatal*. TS (and the current PS port) still return
-- | a usable position through fallback paths. Only case 1 has no position to
-- | offer.
-- |
-- | Therefore `calculateNodePosition` returns:
-- |
-- |   * `Left (NodeNotFound id)`  — case 1, the ONLY value-level failure;
-- |   * `Right { position, .. }`  — cases 2 and 3 keep their fallback
-- |                                 positions, exactly as before.
-- |
-- | This preserves runtime behaviour at the sole call site
-- | (`System.XYDrag`), which reads "no position" as "this node did not move"
-- | (`pure acc`). Promoting 005/015 to `Left` would silently drop those
-- | nodes' movement — a behaviour change we deliberately reject.
-- |
-- | The 005/015 conditions are still modelled here as `NodeError`
-- | constructors so a *caller's* `Effect` boundary can name and emit them
-- | (mirroring the `getEdgePosition` design, where warning emission is pushed
-- | to the edge of the program). `nodeErrorCode` maps each constructor to its
-- | `System.Constants.ErrorCode`, returning `Nothing` for `NodeNotFound`,
-- | which has no numbered code in the TS source.
-- |
-- | ## Monad stack
-- |
-- | Pure `Either NodeError` — no transformer. The computation has no effects,
-- | the failure is a value, and `Either`'s short-circuit matches "produce a
-- | position or report why not". Applicative accumulation (`V`) is
-- | unnecessary: exactly one fatal outcome is ever returned.
module System.Utils.Graph.NodeError
  ( NodeError(..)
  , nodeErrorCode
  , renderNodeError
  ) where

import Prelude

import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Show.Generic (genericShow)
import System.Constants (ErrorCode(..), errorMessage)
import System.Types.Ids (NodeId)

-- | The outcomes `calculateNodePosition` can distinguish.
-- |
-- | Only `NodeNotFound` is returned as `Left`. The remaining constructors
-- | name the non-fatal fallbacks (see the module header) so the caller's
-- | Effect boundary can surface them; the pure position path still succeeds.
-- |
-- |   * `NodeNotFound id`             — fatal: `id` absent from `NodeLookup`;
-- |                                     no `ErrorCode`.
-- |   * `ParentExtentWithoutParent id`— non-fatal (E005): `extent: 'parent'`
-- |                                     but no parent resolved.
-- |   * `NodeNotInitialized id`       — non-fatal (E015): node has no measured
-- |                                     width/height.
data NodeError
  = NodeNotFound NodeId
  | ParentExtentWithoutParent NodeId
  | NodeNotInitialized NodeId

derive instance eqNodeError :: Eq NodeError
derive instance genericNodeError :: Generic NodeError _

instance showNodeError :: Show NodeError where
  show = genericShow

-- | The `System.Constants.ErrorCode` a `NodeError` corresponds to, or
-- | `Nothing` when there is none.
-- |
-- | `NodeNotFound` maps to `Nothing`: the TS source has no numbered error for
-- | the absent-node case (it relies on a non-null assertion). The non-fatal
-- | variants map onto the codes TS emits via `onError`:
-- | `ParentExtentWithoutParent -> Just E005`, `NodeNotInitialized -> Just
-- | E015`.
nodeErrorCode :: NodeError -> Maybe ErrorCode
nodeErrorCode = case _ of
  NodeNotFound _ -> Nothing
  ParentExtentWithoutParent _ -> Just E005
  NodeNotInitialized _ -> Just E015

-- | A human-readable description, mirroring `System.Constants.errorMessage`.
-- | Coded variants should defer to `errorMessage (nodeErrorCode …)`;
-- | `NodeNotFound` supplies its own text since it carries no `ErrorCode`.
renderNodeError :: NodeError -> String
renderNodeError e = case nodeErrorCode e of
  Just code -> errorMessage code
  Nothing -> case e of
    NodeNotFound nid ->
      "Node with id \"" <> unwrap nid <> "\" not found in the node lookup."
    _ ->
      "Node not found in the node lookup."
