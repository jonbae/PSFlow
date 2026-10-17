-- | Shared utilities for the per-node wrapper component. Mirrors
-- | `xyflow/packages/react/src/components/NodeWrapper/utils.tsx`.
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
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (toNullable)
import Data.Tuple.Nested ((/\))
import Foreign (Foreign, unsafeToForeign)
import Foreign.Object (Object)
import Foreign.Object (fromFoldable, lookup) as Object
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
-- | spreads over `node.style`.
-- |
-- | TS returns `number | string | undefined`, and falls back to
-- | `node.style?.width` and `node.style?.height` last. Without that fallback
-- | the spread writes an empty `width` over the consumer's own, and a node
-- | sized only through `style` renders at its content's size. The fallback is
-- | the consumer's own value, a number or a CSS string, so it crosses as
-- | `Foreign`. An empty result is `null`, which React drops from a style as it
-- | does upstream's `undefined`.
getNodeInlineStyleDimensions
  :: forall n. InternalNode n -> { width :: Foreign, height :: Foreign }
getNodeInlineStyleDimensions node =
  case node.internals.handleBounds of
    Nothing ->
      { width: coalesce "width" [ node.width, node.initialWidth ]
      , height: coalesce "height" [ node.height, node.initialHeight ]
      }
    Just _ ->
      { width: coalesce "width" [ node.width ]
      , height: coalesce "height" [ node.height ]
      }
  where
  -- `Object String` is how ps-flow types a node's style, but a consumer's
  -- `{ width: 320 }` arrives as a number, so the member is read as `Foreign`.
  styleMember :: String -> Maybe Foreign
  styleMember key = node.style >>= \s -> Object.lookup key (unsafeCoerce s :: Object Foreign)

  coalesce :: String -> Array (Maybe Number) -> Foreign
  coalesce key dims = case Foldable.oneOf dims of
    Just n -> unsafeToForeign n
    Nothing -> fromMaybe (unsafeToForeign (toNullable (Nothing :: Maybe Number))) (styleMember key)

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
