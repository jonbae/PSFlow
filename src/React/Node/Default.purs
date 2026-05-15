-- | `<DefaultNode />` — the standard node with both a target handle on
-- | top and a source handle on bottom, plus the user-supplied label.
-- | Mirrors `xyflow-main/packages/react/src/components/Nodes/DefaultNode.tsx`.
-- |
-- | Default `targetPosition = PosTop`, `sourcePosition = PosBottom`.
-- |
-- | The `data` row is left polymorphic; we read `.label` if it exists.
-- | For the built-in registry we instantiate at `Foreign`.
module React.Node.Default
  ( defaultNode
  ) where

import Prelude

import Data.Either (hush)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign, readString)
import Foreign.Index ((!))
import Control.Monad.Except (runExcept)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (reactComponent)
import React.FFI.DOM (textContent)
import React.Handle (handle)
import React.Types.Nodes (NodeProps)
import System.Types.Geometry (Position(..))
import System.Types.Handle (HandleType(..))

readLabel :: Foreign -> Maybe String
readLabel f = hush $ runExcept (f ! "label" >>= readString)

defaultNode :: ReactComponent (NodeProps Foreign)
defaultNode = unsafePerformEffect $ reactComponent "DefaultNode" \(props :: NodeProps Foreign) ->
  pure $
    let
      targetPos = fromMaybe PosTop props.targetPosition
      sourcePos = fromMaybe PosBottom props.sourcePosition
      label :: JSX
      label = case readLabel props.data of
        Just s -> textContent s
        Nothing -> mempty
    in
      element handle
        { handleType: Target
        , position: targetPos
        , id: Nothing
        , isConnectable: Just props.isConnectable
        , isConnectableStart: Nothing
        , isConnectableEnd: Nothing
        , onConnect: Nothing
        , isValidConnection: Nothing
        , className: Nothing
        , style: Nothing
        }
        <> label
        <> element handle
          { handleType: Source
          , position: sourcePos
          , id: Nothing
          , isConnectable: Just props.isConnectable
          , isConnectableStart: Nothing
          , isConnectableEnd: Nothing
          , onConnect: Nothing
          , isValidConnection: Nothing
          , className: Nothing
          , style: Nothing
          }
