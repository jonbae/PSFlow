-- | Shared utilities for the per-node wrapper component. Mirrors
-- | `xyflow-main/packages/react/src/components/NodeWrapper/utils.tsx`.
-- |
-- |   * `arrowKeyDiffs` — `key → {dx,dy}` deltas for arrow-key node
-- |     nudging. Used by `React.Component.NodeWrapper`'s `onKeyDown`.
-- |   * `getNodeInlineStyleDimensions` — the inline `width`/`height`
-- |     styles a node wrapper renders before its handle bounds have been
-- |     measured. Returns `Foreign` so the JS spread can blend it with
-- |     `node.style` without forcing a type for the `Style` opaque.
-- |   * `builtinNodeTypes` — registry of the four built-in node
-- |     components (`input`, `default`, `output`, `group`), relocated
-- |     here from `React.Node.Util` so the wrapper's resolution
-- |     lookup-with-fallback lives next to its consumer (matches the TS
-- |     source layout).
module React.Component.NodeWrapper.Util
  ( arrowKeyDiffs
  , getNodeInlineStyleDimensions
  , builtinNodeTypes
  ) where

import Prelude

import Data.Foldable (oneOf) as Foldable
import Data.Map (Map)
import Data.Map (fromFoldable) as Map
import Data.Maybe (Maybe(..))
import Data.Nullable (toNullable)
import Data.Tuple.Nested ((/\))
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object (fromFoldable) as Object
import React.Basic (ReactComponent)
import React.Node.Default (defaultNode)
import React.Node.Group (groupNode)
import React.Node.Input (inputNode)
import React.Node.Output (outputNode)
import React.Types.Nodes (InternalNode, NodeProps)
import System.Types.Geometry (XYPosition)
import Unsafe.Coerce (unsafeCoerce)

-- | `{ ArrowUp → (0,-1), ArrowDown → (0,1), … }`. Lookups happen on the
-- | raw `KeyboardEvent.key` string, so the constants match the DOM
-- | spelling exactly.
arrowKeyDiffs :: Map String XYPosition
arrowKeyDiffs = Map.fromFoldable
  [ "ArrowUp" /\ { x: 0.0, y: -1.0 }
  , "ArrowDown" /\ { x: 0.0, y: 1.0 }
  , "ArrowLeft" /\ { x: -1.0, y: 0.0 }
  , "ArrowRight" /\ { x: 1.0, y: 0.0 }
  ]

-- | Compute the inline-style `{ width, height }` that the node wrapper
-- | emits before the handle bounds have been measured.
-- |
-- | TS returns `number | string | undefined`; the string branch reads
-- | `node.style?.width`, which our `Style` opaque doesn't expose yet.
-- | We collapse to `Number | undefined` here and document the gap.
getNodeInlineStyleDimensions
  :: forall n. InternalNode n -> { width :: Foreign, height :: Foreign }
getNodeInlineStyleDimensions node =
  case node.internals.handleBounds of
    Nothing ->
      { width: coalesce [ node.width, node.initialWidth ]
      , height: coalesce [ node.height, node.initialHeight ]
      }
    Just _ ->
      { width: coalesce [ node.width ]
      , height: coalesce [ node.height ]
      }
  where
  coalesce :: Array (Maybe Number) -> Foreign
  coalesce = unsafeCoerce <<< toNullable <<< Foldable.oneOf

-- | Registry of the four built-in node-type keys. Consumed by
-- | `React.Component.NodeWrapper`'s `nodeTypes[node.type] ||
-- | builtinNodeTypes[node.type]` resolution path.
-- |
-- | The value row is `Foreign` because the registry erases the user
-- | data row (built-in nodes only read `.label`). Consumers that want
-- | a typed `NodeProps n` form should instantiate their own
-- | `nodeTypes` record.
builtinNodeTypes :: Object (ReactComponent (NodeProps Foreign))
builtinNodeTypes = Object.fromFoldable
  [ "input" /\ inputNode
  , "default" /\ defaultNode
  , "output" /\ outputNode
  , "group" /\ groupNode
  ]
