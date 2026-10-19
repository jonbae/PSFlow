-- | The `toPosition` of the connection state a connection ends with.
-- |
-- | The local proxy for the report's `connect-drag-released-on-pane`
-- | scenario, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `XYHandle` ends a drag with
-- |
-- |     toPosition: previousConnection.toHandle ? previousConnection.toPosition : null
-- |
-- | and `<Handle />` ends a click connection with
-- |
-- |     connectionClone.toPosition = connectionClone.toHandle ? connectionClone.toHandle.position : null;
-- |
-- | so a connection that ends on no handle reports no `toPosition`. ps-flow
-- | handed on the last connection as it was, whose `toPosition` is the side
-- | opposite the handle it started from. A drag released on the pane
-- | reported `left` where upstream reports `null`.
-- |
-- | The test checks `endConnection` and `clickConnectEndState`, which build
-- | the two states, and what the boundary makes of the result. That the
-- | handlers use them is the net's to check: `spago test` has no DOM to
-- | press a handle in.
module Test.System.FinalConnectionState
  ( runFinalConnectionStateTests
  ) where

import Prelude

import Boundary.Callbacks (JsConnectionState, connectionStateOut)
import Data.Maybe (Maybe(..), isNothing)
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign, unsafeToForeign)
import Partial.Unsafe (unsafeCrashWith)
import React.Handle (clickConnectEndState)
import System.Types.Connection (ConnectionInProgressData, ConnectionState(..))
import System.Types.Geometry (Position(..))
import System.Types.Handle (Handle, HandleIdField(..), HandleType(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeBase)
import System.XYHandle (endConnection)

foreign import toPositionIsNull :: JsConnectionState -> Boolean
foreign import toPositionIs :: String -> JsConnectionState -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

handleAt :: String -> HandleType -> Position -> Handle
handleAt nodeId handleType position =
  { id: HandleIdNull, nodeId: NodeId nodeId, x: 0.0, y: 0.0, position, handleType, width: 8.0, height: 8.0 }

-- | A connection from `a`'s right-hand source handle, with the pointer over
-- | `toHandle`, and the `toPosition` `XYHandle` gave it.
inProgress :: forall node. node -> Maybe Handle -> Position -> ConnectionInProgressData node
inProgress node toHandle toPosition =
  { isValid: Nothing
  , from: { x: 99.0, y: 20.0 }
  , fromHandle: handleAt "a" Source PosRight
  , fromPosition: PosRight
  , fromNode: node
  , to: { x: 179.0, y: 60.0 }
  , toHandle
  , toPosition
  , toNode: Nothing
  , pointer: { x: 179.0, y: 60.0 }
  }

-- | `b`'s target handle, on its top side.
topOfB :: Handle
topOfB = handleAt "b" Target PosTop

internalNode :: InternalNodeBase Foreign
internalNode =
  { id: NodeId "a"
  , position: { x: 0.0, y: 0.0 }
  , data: unsafeToForeign {}
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: Nothing
  , dragging: Nothing
  , draggable: Nothing
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Nothing
  , height: Nothing
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: Nothing
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Nothing, height: Nothing }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  , internals:
      { positionAbsolute: { x: 0.0, y: 0.0 }
      , z: 0.0
      , rootParentIndex: Nothing
      , handleBounds: Nothing
      , bounds: Nothing
      }
  }

runFinalConnectionStateTests :: Effect Unit
runFinalConnectionStateTests = do
  log "\n=== The toPosition a connection ends with ==="

  let onPane = endConnection (inProgress unit Nothing PosLeft)
  assert "a drag released on no handle ends with no toPosition"
    (map _.toPosition onPane == Just Nothing)
  assert "a drag released on no handle keeps the rest of the connection"
    (map _.to onPane == Just { x: 179.0, y: 60.0 } && map _.fromPosition onPane == Just PosRight)

  assert "a drag released on a handle ends with its toPosition"
    (map _.toPosition (endConnection (inProgress unit (Just topOfB) PosTop)) == Just (Just PosTop))
  assert "a drag released on a handle it can't connect to keeps the toPosition XYHandle gave it, as TS does"
    (map _.toPosition (endConnection (inProgress unit (Just topOfB) PosLeft)) == Just (Just PosLeft))

  assert "a click with no connection in progress ends with none"
    (isNothing (clickConnectEndState (NoConnection :: ConnectionState Unit)))
  assert "a click connection over no handle ends with no toPosition"
    ( map _.toPosition (clickConnectEndState (ConnectionInProgress (inProgress unit Nothing PosLeft)))
        == Just Nothing
    )
  assert "a click connection over a handle ends with that handle's position, as TS does"
    ( map _.toPosition (clickConnectEndState (ConnectionInProgress (inProgress unit (Just topOfB) PosLeft)))
        == Just (Just PosTop)
    )

  assert "the boundary hands a consumer a null toPosition"
    (toPositionIsNull (connectionStateOut (endConnection (inProgress internalNode Nothing PosLeft))))
  assert "the boundary hands a consumer a handle's toPosition by name"
    (toPositionIs "top" (connectionStateOut (endConnection (inProgress internalNode (Just topOfB) PosTop))))
