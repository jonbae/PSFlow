-- | Shared utilities for the React-side node layer.
-- |
-- | * `handleNodeClick` — selection-dispatch helper invoked from the
-- |   (future) `NodeWrapper` click path and from the drag-start branch
-- |   that wants single-click selection. Mirrors
-- |   `xyflow-main/packages/react/src/components/Nodes/utils.ts`.
-- | * `builtinNodeTypes` — registry of the four built-in node component
-- |   types under the keys `input`, `default`, `output`, `group`.
-- |   Consumed by `NodeWrapper` (ticket 035) when resolving the user's
-- |   `nodeTypes` against the built-ins.
module React.Node.Util
  ( HandleNodeClickArgs
  , handleNodeClick
  , builtinNodeTypes
  ) where

import Prelude

import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object (fromFoldable) as Object
import Data.Tuple.Nested ((/\))
import React.Basic (ReactComponent)
import React.Node.Default (defaultNode)
import React.Node.Group (groupNode)
import React.Node.Input (inputNode)
import React.Node.Output (outputNode)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import React.Types.Nodes (Node, NodeProps)
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

-- | Map from the TS built-in node-type keys to their PS components.
-- |
-- | The value row is `Foreign` because the registry erases the user
-- | data row (built-in nodes only read `.label`). Consumers that want
-- | the typed `NodeProps n` form should instantiate their own
-- | `nodeTypes` record.
builtinNodeTypes :: Object (ReactComponent (NodeProps Foreign))
builtinNodeTypes = Object.fromFoldable
  [ "input" /\ inputNode
  , "default" /\ defaultNode
  , "output" /\ outputNode
  , "group" /\ groupNode
  ]
