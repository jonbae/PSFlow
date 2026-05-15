-- | `<InputNode />` — source-only built-in node. Renders the user-
-- | supplied label then a single source handle on the bottom. Mirrors
-- | `xyflow-main/packages/react/src/components/Nodes/InputNode.tsx`.
-- |
-- | Default `sourcePosition = PosBottom`.
module React.Node.Input
  ( inputNode
  ) where

import Prelude

import Control.Monad.Except (runExcept)
import Data.Either (hush)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign, readString)
import Foreign.Index ((!))
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (reactComponent)
import React.FFI.DOM (textContent)
import React.Handle (handle)
import React.Types.Nodes (NodeProps)
import System.Types.Geometry (Position(..))
import System.Types.Handle (HandleType(..))

readLabel :: Foreign -> Maybe String
readLabel f = hush $ runExcept (f ! "label" >>= readString)

inputNode :: ReactComponent (NodeProps Foreign)
inputNode = unsafePerformEffect $ reactComponent "InputNode" \(props :: NodeProps Foreign) ->
  pure $
    let
      sourcePos = fromMaybe PosBottom props.sourcePosition
      label :: JSX
      label = case readLabel props.data of
        Just s -> textContent s
        Nothing -> mempty
    in
      label
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
