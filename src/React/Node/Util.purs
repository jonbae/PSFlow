-- | Shared utilities for the React-side node layer.
-- |
-- | * `handleNodeClick` — selection-dispatch helper invoked from the
-- |   `NodeWrapper` click path and from the drag-start branch that
-- |   wants single-click selection. Mirrors
-- |   `xyflow-main/packages/react/src/components/Nodes/utils.ts`.
-- |
-- | The built-in node-type registry (`builtinNodeTypes`) lives in
-- | `React.Component.NodeWrapper.Util`, where the wrapper's
-- | lookup-with-fallback resolution path consumes it (matches the TS
-- | source layout).
module React.Node.Util
  ( HandleNodeClickArgs
  , handleNodeClick
  ) where

import Prelude

import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import React.Types.Nodes (Node)
import System.Constants (ErrorCode(..), errorMessage)
import Unsafe.Coerce (unsafeCoerce)

type HandleNodeClickArgs n e =
  { id :: String
  , store :: Store n e
  , unselect :: Boolean
  }

-- | Mirrors TS `handleNodeClick`. Reads the store, then either selects
-- | the node (if not yet selected) or unselects it (if `unselect` is
-- | true, or if multi-select is active and the node is already
-- | selected). The TS source's RAF blur is intentionally omitted —
-- | it relies on a `nodeRef` we don't thread through this initial
-- | port; can be added when `NodeWrapper` (ticket 035) lands.
handleNodeClick :: forall n e. HandleNodeClickArgs n e -> Effect Unit
handleNodeClick args = do
  state <- args.store.getState
  case Map.lookup args.id state.nodeLookup of
    Nothing -> case state.onError of
      Just cb -> cb "012" (errorMessage (E012 args.id))
      Nothing -> pure unit
    Just node -> do
      -- `InternalNode n` carries the same `id`/`selected` fields as
      -- `Node n`; the unselect reducer only reads those two, so the
      -- coerce is sound. Lifting avoids re-deriving the public Node
      -- from the internal one (which would require duplicating
      -- positionAbsolute/measured fields).
      let asNode = (unsafeCoerce node) :: Node n
      if not asNode.selected then
        args.store.dispatch (AddSelectedNodes [ args.id ])
      else if args.unselect || (asNode.selected && state.multiSelectionActive) then
        args.store.dispatch
          (UnselectNodesAndEdges { nodes: Just [ asNode ], edges: Nothing })
      else
        pure unit
