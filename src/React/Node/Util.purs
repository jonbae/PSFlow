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
import Data.Nullable (Nullable, toMaybe)
import Effect (Effect)
import React.Basic (Ref)
import React.Basic.Hooks (readRef)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import Data.Newtype (unwrap)
import React.Types.Nodes (Node)
import System.Constants (ErrorCode(..), errorMessage)
import System.Types.Ids (NodeId)
import System.FFI.AnimationFrame (requestAnimationFrame)
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML.HTMLDivElement (HTMLDivElement, toHTMLElement)
import Web.HTML.HTMLElement (blur)

type HandleNodeClickArgs n e =
  { id :: NodeId
  , store :: Store n e
  , unselect :: Boolean
  -- | The wrapper `<div>` of the node being clicked, so the unselect
  -- | branch can take focus off it. Required, where TS's is optional:
  -- | all three call sites are in `React.Component.NodeWrapper`, which
  -- | has the ref in scope, and TS passes it from all three of its own.
  -- | An optional field here would only be a way to forget it.
  , nodeRef :: Ref (Nullable HTMLDivElement)
  }

-- | Mirrors TS `handleNodeClick`. Reads the store, then either selects
-- | the node (if not yet selected) or unselects it (if `unselect` is
-- | true, or if multi-select is active and the node is already
-- | selected).
-- |
-- | **The blur.** Unselecting a node leaves the browser's focus on its
-- | `<div>`, so the node keeps its focus ring and the next keystroke
-- | still reaches it — it looks unselected and behaves selected. TS
-- | drops focus on the next animation frame, and so does this. The
-- | frame is not a detail: `unselectNodesAndEdges` re-renders, and
-- | blurring inside the same tick fights the render that is still
-- | placing the element.
handleNodeClick :: forall n e. HandleNodeClickArgs n e -> Effect Unit
handleNodeClick args = do
  state <- args.store.getState
  case Map.lookup args.id state.nodeLookup of
    Nothing -> case state.onError of
      Just cb -> cb "012" (errorMessage (E012 (unwrap args.id)))
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
      else if args.unselect || (asNode.selected && state.multiSelectionActive) then do
        args.store.dispatch
          (UnselectNodesAndEdges { nodes: Just [ asNode ], edges: Nothing })
        mDiv <- toMaybe <$> readRef args.nodeRef
        case mDiv of
          Nothing -> pure unit
          Just div -> void $ requestAnimationFrame (blur (toHTMLElement div))
      else
        pure unit
