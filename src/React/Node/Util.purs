-- | Shared utilities for the React-side node layer.
-- |
-- | * `handleNodeClick` — selection-dispatch helper invoked from the
-- |   `NodeWrapper` click path and from the drag-start branch that
-- |   wants single-click selection. Mirrors
-- |   `xyflow/packages/react/src/components/Nodes/utils.ts`.
-- | * `moveNodesByArrowKey` — the arrow-key branch of TS `NodeWrapper`'s
-- |   `onKeyDown`, past its guards, kept out of the component so a test
-- |   can call it without a DOM.
-- |
-- | The built-in node-type registry (`builtinNodeTypes`) lives in
-- | `React.Component.NodeWrapper.Util`, where the wrapper's
-- | lookup-with-fallback resolution path consumes it (matches the TS
-- | source layout).
module React.Node.Util
  ( HandleNodeClickArgs
  , handleNodeClick
  , MoveNodesByArrowKeyArgs
  , moveNodesByArrowKey
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (Nullable, toMaybe)
import Data.String (Pattern(..), Replacement(..), replace, toLower)
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
import System.Types.Geometry (XYPosition)
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

-- | Mirrors TS `handleNodeClick`. Reads the store, ends a nodes
-- | selection, then either selects the node (if not yet selected) or
-- | unselects it (if `unselect` is true, or if multi-select is active and
-- | the node is already selected).
-- |
-- | **The nodes selection.** TS's `store.setState({ nodesSelectionActive:
-- | false })` comes first, for any node it finds, so a click after a
-- | selection box hides the box's rectangle. It comes before the
-- | selection, too, which writes into the store in place and notifies
-- | nobody: after it, the `setState` would be what tells `useStore` of the
-- | selection.
-- |
-- | **The edges.** TS unselects with `edges: []`, so unselecting a node
-- | leaves the selected edges alone. `Nothing` would be every edge in the
-- | store.
-- |
-- | **The blur.** Unselecting a node leaves the browser's focus on its
-- | `<div>`, so the node keeps its focus ring and the next keystroke
-- | still reaches it — it looks unselected and behaves selected. TS
-- | drops focus on the next animation frame, and so does this. The
-- | frame is not a detail: `unselectNodesAndEdges` re-renders, and
-- | blurring inside the same tick fights the render that is still
-- | placing the element.
-- |
-- | The ref is read *inside* the frame, as TS's
-- | `requestAnimationFrame(() => nodeRef?.current?.blur())` reads
-- | `.current` inside its callback — and for the same reason the frame
-- | exists at all. Reading at dispatch time captures whatever `<div>`
-- | the ref held before the re-render this function just triggered, so
-- | a render that replaces the element would leave the blur landing on
-- | a detached node, and a ref still empty at dispatch would schedule
-- | nothing where TS would still blur.
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
      args.store.dispatch (PatchState _ { nodesSelectionActive = false })
      if asNode.selected /= Just true then
        args.store.dispatch (AddSelectedNodes [ args.id ])
      else if args.unselect || (asNode.selected == Just true && state.multiSelectionActive) then do
        args.store.dispatch
          (UnselectNodesAndEdges { nodes: Just [ asNode ], edges: Just [] })
        void $ requestAnimationFrame do
          mDiv <- toMaybe <$> readRef args.nodeRef
          for_ mDiv (blur <<< toHTMLElement)
      else
        pure unit

type MoveNodesByArrowKeyArgs n e =
  { id :: NodeId
  , store :: Store n e
  -- | The event's `key`: `ArrowUp`, `ArrowDown`, `ArrowLeft`, or
  -- | `ArrowRight`.
  , key :: String
  , direction :: XYPosition
  , factor :: Number
  -- | The node's absolute position as the wrapper rendered it, for a node
  -- | the lookup no longer holds.
  , positionAbsolute :: XYPosition
  , moveSelectedNodes :: XYPosition -> Number -> Effect Unit
  }

-- | TS `NodeWrapper`'s `onKeyDown`, once it has found an arrow key on a
-- | selected, draggable node and prevented the browser's scroll. It
-- | announces the move in the aria-live region, then makes it:
-- |
-- | ```ts
-- | store.setState({
-- |   ariaLiveMessage: ariaLabelConfig['node.a11yDescription.ariaLiveMessage']({
-- |     direction: event.key.replace('Arrow', '').toLowerCase(),
-- |     x: ~~internals.positionAbsolute.x,
-- |     y: ~~internals.positionAbsolute.y,
-- |   }),
-- | });
-- | moveSelectedNodes({ direction: arrowKeyDiffs[event.key], factor: event.shiftKey ? 4 : 1 });
-- | ```
-- |
-- | **The position** is the node's before the move, truncated to an
-- | integer. TS's `internals` is the lookup's own object, which
-- | `moveSelectedNodes` writes each move into, so it holds the last move
-- | even when React hasn't rendered the node since. ps-flow's rendered node
-- | is a copy, so this reads the lookup.
moveNodesByArrowKey :: forall n e. MoveNodesByArrowKeyArgs n e -> Effect Unit
moveNodesByArrowKey args = do
  state <- args.store.getState
  let
    at = fromMaybe args.positionAbsolute
      (_.internals.positionAbsolute <$> Map.lookup args.id state.nodeLookup)
    message = state.ariaLabelConfig.nodeA11yDescriptionAriaLiveMessage
      { direction: toLower (replace (Pattern "Arrow") (Replacement "") args.key)
      , x: toInt32 at.x
      , y: toInt32 at.y
      }
  args.store.dispatch (PatchState _ { ariaLiveMessage = message })
  args.moveSelectedNodes args.direction args.factor

-- | JavaScript's `~~n`: `n` truncated toward zero and wrapped to a 32-bit
-- | integer, with `NaN` and the infinities at 0.
foreign import toInt32 :: Number -> Number
