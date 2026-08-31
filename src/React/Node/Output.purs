-- | `<OutputNode />` — target-only built-in node. Renders a target
-- | handle on top, then the user-supplied label. Mirrors
-- | `xyflow-main/packages/react/src/components/Nodes/OutputNode.tsx`.
-- |
-- | Default `targetPosition = PosTop`.
module React.Node.Output
  ( outputNode
  ) where

import Prelude

import Control.Monad.Except (runExcept)
import Data.Either (hush)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (null)
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

outputNode :: ReactComponent (NodeProps Foreign)
outputNode = unsafePerformEffect $ reactComponent "OutputNode" \(props :: NodeProps Foreign) ->
  pure $
    let
      targetPos = fromMaybe PosTop props.targetPosition
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
        , innerRef: null
        }
        <> label
