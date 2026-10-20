-- | Where a connection's line ends: `to`, in the flow's coordinates.
-- |
-- | The local proxy for the report's `connect-then-keyboard-move`,
-- | `connect-second-touch-point`, and
-- | `connect-source-handle-to-target-handle--probe-connection-line`
-- | scenarios, which
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93)'s
-- | map doesn't name. Upstream's `XYHandle` keeps `connection.to` where the
-- | pointer is in the container, and `useConnection`'s selector converts it
-- | with the store's transform. The connection line reads it through
-- | `useConnection`. ps-flow's `XYHandle` keeps the same point, but its
-- | connection line and `useConnection` read it as stored, so under a
-- | panned or zoomed viewport the line ended where the pointer would be in
-- | the flow's coordinates if the viewport weren't there.
-- |
-- | The flow here is panned by (100, 50) and zoomed to 2, with the pointer
-- | at (300, 250) in the container: (100, 100) in the flow.
module Test.React.Hook.ConnectionTo
  ( runConnectionToTests
  ) where

import Prelude

import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Number.Format (toString) as NumberFormat
import Data.String (Pattern(..), contains)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Hooks (reactComponent)
import React.Basic.Hooks as React
import React.Component.ConnectionLine (connectionLine)
import React.Context.Store (OpaqueStore, storeProvider)
import React.FFI.DOM (path_)
import React.Hook.Selectors (selectConnection, useConnection, useConnectionWith)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import React.Types.Edges (ConnectionLineComponent)
import React.Types.Nodes (Node)
import System.Types.Connection (ConnectionState(..))
import System.Types.Edge (ConnectionLineType(..))
import System.Types.Geometry (Position(..), mkTransform)
import System.Types.Handle (HandleIdField(..), HandleType(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeBase)
import Unsafe.Coerce (unsafeCoerce)

foreign import renderMarkup :: JSX -> Effect String

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

storeToOpaque :: Store Unit Unit -> OpaqueStore
storeToOpaque = unsafeCoerce

showN :: Number -> String
showN = NumberFormat.toString

nodeA :: Node Unit
nodeA =
  { id: NodeId "a"
  , position: { x: 0.0, y: 0.0 }
  , data: unit
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
  , measured: { width: Just 150.0, height: Just 40.0 }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | A store panned by (100, 50) and zoomed to 2, with a connection in
-- | progress from `a`'s bottom handle, at (75, 40) in the flow, and the
-- | pointer at (300, 250) in the container.
connecting :: Effect (Store Unit Unit)
connecting = do
  store <- createStore ((defaultInitialStateOptions :: InitialStateOptions Unit Unit) { nodes = Just [ nodeA ] })
  s <- store.getState
  case Map.lookup (NodeId "a") s.nodeLookup of
    Nothing -> unsafeCrashWith "FAIL the store has no node a"
    Just fromNode -> do
      let
        fromHandle =
          { id: HandleIdNull
          , nodeId: NodeId "a"
          , x: 74.0
          , y: 39.0
          , position: PosBottom
          , handleType: Source
          , width: 2.0
          , height: 2.0
          }
      store.dispatch $ PatchState _
        { transform = mkTransform 100.0 50.0 2.0
        , width = 800.0
        , height = 600.0
        , connection = ConnectionInProgress
            { isValid: Nothing
            , from: { x: 75.0, y: 40.0 }
            , fromHandle
            , fromPosition: PosBottom
            , fromNode
            , to: { x: 300.0, y: 250.0 }
            , toHandle: Nothing
            , toPosition: PosTop
            , toNode: Nothing
            , pointer: { x: 300.0, y: 250.0 }
            }
        }
      pure store

-- | A connection line component that draws where it's told the line ends.
endsAt :: ConnectionLineComponent Unit
endsAt p = path_ { d: "to " <> showN p.toX <> "," <> showN p.toY <> " pointer " <> showN p.pointer.x <> "," <> showN p.pointer.y } []

-- | The connection line over `store`, as `renderToStaticMarkup` writes it.
rendered :: Store Unit Unit -> Maybe (ConnectionLineComponent Unit) -> Effect String
rendered store component = renderMarkup
  ( storeProvider (Just (storeToOpaque store))
      [ element connectionLine
          { connectionLineComponent: component
          , connectionLineStyle: Nothing
          , connectionLineType: Just StraightLine
          , connectionLineContainerStyle: Nothing
          }
      ]
  )

-- | A component that draws where `useConnection` and `useConnectionWith`
-- | say the line ends.
hooks :: ReactComponent {}
hooks = unsafePerformEffect $ reactComponent "ConnectionHooks" \_ -> React.do
  whole <- useConnection
  slice <- useConnectionWith toOf
  pure $ path_ { d: "useConnection " <> describe (toOf whole) <> " useConnectionWith " <> describe slice } []
  where
  toOf :: ConnectionState (InternalNodeBase Unit) -> Maybe { x :: Number, y :: Number }
  toOf = case _ of
    ConnectionInProgress c -> Just c.to
    NoConnection -> Nothing
  describe = case _ of
    Just p -> showN p.x <> "," <> showN p.y
    Nothing -> "none"

has :: String -> String -> Boolean
has needle = contains (Pattern needle)

runConnectionToTests :: Effect Unit
runConnectionToTests = do
  log "\n=== useConnection and ConnectionLine: the line ends at `to` in the flow ==="

  store <- connecting
  s <- store.getState
  case selectConnection s of
    NoConnection -> assert "useConnection's selector reports the connection in progress" false
    ConnectionInProgress c -> do
      assert "useConnection's selector converts `to` to the flow's coordinates"
        (c.to == { x: 100.0, y: 100.0 })
      assert "and leaves `pointer` in the container's coordinates"
        (c.pointer == { x: 300.0, y: 250.0 })
      assert "and `from` as the store holds it"
        (c.from == { x: 75.0, y: 40.0 })

  line <- rendered store Nothing
  assert "the connection line's path ends at `to` in the flow"
    (has "d=\"M 75,40L 100,100\"" line)

  custom <- rendered store (Just endsAt)
  assert "a custom connection line is told `to` in the flow, and `pointer` in the container"
    (has "d=\"to 100,100 pointer 300,250\"" custom)

  read <- renderMarkup (storeProvider (Just (storeToOpaque store)) [ element hooks {} ])
  assert "useConnection and useConnectionWith report `to` in the flow"
    (has "d=\"useConnection 100,100 useConnectionWith 100,100\"" read)

  store.dispatch (PatchState _ { transform = mkTransform 0.0 0.0 1.0 })
  unmoved <- rendered store Nothing
  assert "under the identity viewport, `to` is where the pointer is"
    (has "d=\"M 75,40L 300,250\"" unmoved)

  store.dispatch (PatchState _ { connection = NoConnection })
  idle <- store.getState
  assert "with no connection, the selector reports none"
    ( case selectConnection idle of
        NoConnection -> true
        ConnectionInProgress _ -> false
    )
