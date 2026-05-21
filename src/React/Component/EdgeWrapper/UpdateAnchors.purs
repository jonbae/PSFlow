-- | `<EdgeUpdateAnchors />` — renders the source/target reconnect
-- | handles for a selected edge. Mirrors
-- | `xyflow-main/packages/react/src/components/EdgeWrapper/EdgeUpdateAnchors.tsx`.
-- |
-- | A pointerdown on either anchor starts a fresh connection drag via
-- | `System.XYHandle.onPointerDown`, with reconnect-specific callbacks
-- | wrapped around the user's `onReconnect`/`onReconnectStart`/
-- | `onReconnectEnd` props. The wrapping callbacks also flip the
-- | parent `EdgeWrapper`'s `reconnecting`/`updateHover` flags so the
-- | wrapped edge body hides for the duration of the drag.
-- |
-- | **Fidelity gaps versus TS.**
-- |   * Touch reconnect is skipped — only the `Left MouseEvent` half of
-- |     `Either MouseEvent TouchEvent` is wired. Same deferment as
-- |     `React.Handle`.
-- |   * `panBy` is fire-and-forget — `Action PanBy` has no `Aff Boolean`
-- |     completion, so the adapter unconditionally reports `pure true`.
-- |     The auto-pan controller sees every dispatch as "panned",
-- |     visually correct because the reducer always applies the delta.
-- |   * The React-layer `IsValidConnection` carries an `edge :: Maybe
-- |     (Edge e)` field that the system-layer's `Connection -> Boolean`
-- |     doesn't expose. The adapter drops `edge` (validation predicates
-- |     during a reconnect drag only carry a candidate connection).
module React.Component.EdgeWrapper.UpdateAnchors
  ( EdgeUpdateAnchorsProps
  , edgeUpdateAnchors
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent, element)
import React.Basic.Events (EventHandler, SyntheticEvent, handler, handler_, syntheticEvent)
import React.Basic.Hooks (reactComponent)
import React.Basic.Hooks as React
import React.Edge.Anchor (edgeAnchor)
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import React.Types.Edges (Edge, OnReconnect, ReconnectHandleType(..))
import System.Types.Connection
  ( ConnectionState(..)
  , FinalConnectionState
  )
import System.Types.Geometry (Position)
import System.Types.Handle (Handle, HandleType(..))
import System.Types.Node (InternalNodeBase)
import System.XYHandle (xyHandle)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Element (Element)
import Web.Event.Event (currentTarget) as Event
import Web.UIEvent.MouseEvent (MouseEvent)
import Web.UIEvent.MouseEvent (button, toEvent) as ME

type EdgeUpdateAnchorsProps e n =
  { edge :: Edge e
  , isReconnectable :: ReconnectHandleType
  , reconnectRadius :: Maybe Number
  , onReconnect :: Maybe (OnReconnect e)
  , onReconnectStart :: Maybe (MouseEvent -> Edge e -> HandleType -> Effect Unit)
  , onReconnectEnd ::
      Maybe
        ( MouseEvent
        -> Edge e
        -> HandleType
        -> FinalConnectionState (InternalNodeBase n)
        -> Effect Unit
        )
  , sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  , sourcePosition :: Position
  , targetPosition :: Position
  , setUpdateHover :: Boolean -> Effect Unit
  , setReconnecting :: Boolean -> Effect Unit
  }

-- | Which node + handle id + handle type the reconnect drag should
-- | terminate on. A click on the *source* anchor floats the source
-- | endpoint and drags toward the *target* (the opposite handle); the
-- | inverse holds for the target anchor.
type OppositeHandle =
  { nodeId :: String, id :: Maybe String, handleType :: HandleType }

syntheticToMouse :: SyntheticEvent -> MouseEvent
syntheticToMouse = unsafeCoerce

currentTargetElement :: SyntheticEvent -> Maybe Element
currentTargetElement se =
  map unsafeCoerce
    (Event.currentTarget (ME.toEvent (syntheticToMouse se)))

-- | Fire-and-forget pan adapter. `Action PanBy` has no `Aff`-completing
-- | path; we dispatch and immediately report success. Acceptable
-- | because the reducer always applies the delta synchronously.
panByAdapter
  :: forall n e
   . Store n e
  -> { x :: Number, y :: Number }
  -> Aff Boolean
panByAdapter store delta =
  liftEffect (store.dispatch (PanBy delta)) *> pure true

-- | Pluck the source handle out of an in-progress connection state.
-- | Returns `Nothing` when no connection is in progress.
extractFromHandle
  :: forall node. ConnectionState node -> Maybe Handle
extractFromHandle = case _ of
  NoConnection -> Nothing
  ConnectionInProgress p -> Just p.fromHandle

edgeUpdateAnchors
  :: forall e n. ReactComponent (EdgeUpdateAnchorsProps e n)
edgeUpdateAnchors =
  unsafePerformEffect $ reactComponent "EdgeUpdateAnchors"
    \(props :: EdgeUpdateAnchorsProps e n) -> React.do
      store <- (useStoreApi :: React.Hook UseStoreApi _)
      let
        showSource = case props.isReconnectable of
          ReconnectAny -> true
          ReconnectOnly Source -> true
          ReconnectOnly Target -> false
        showTarget = case props.isReconnectable of
          ReconnectAny -> true
          ReconnectOnly Target -> true
          ReconnectOnly Source -> false

        sourceOpposite :: OppositeHandle
        sourceOpposite =
          { nodeId: props.edge.target
          , id: props.edge.targetHandle
          , handleType: Target
          }

        targetOpposite :: OppositeHandle
        targetOpposite =
          { nodeId: props.edge.source
          , id: props.edge.sourceHandle
          , handleType: Source
          }

        mkAnchorMouseDown :: OppositeHandle -> EventHandler
        mkAnchorMouseDown oppositeHandle = handler syntheticEvent \se -> do
          let me = syntheticToMouse se
          when (ME.button me == 0) do
            state <- store.getState
            case currentTargetElement se of
              Nothing -> pure unit
              Just el -> xyHandle.onPointerDown (Left me)
                { autoPanOnConnect: state.autoPanOnConnect
                , connectionMode: state.connectionMode
                , connectionRadius: state.connectionRadius
                , domNode: state.domNode
                , handleId: oppositeHandle.id
                , nodeId: oppositeHandle.nodeId
                , isTarget: oppositeHandle.handleType == Target
                , nodeLookup: state.nodeLookup
                , lib: state.lib
                , flowId: Just state.rfId
                , edgeUpdaterType: Just oppositeHandle.handleType
                , updateConnection: \cs -> store.dispatch (UpdateConnection cs)
                , panBy: panByAdapter store
                , cancelConnection: store.dispatch CancelConnection
                , onConnectStart: Just \evtUnion params' -> do
                    props.setReconnecting true
                    for_ props.onReconnectStart \cb ->
                      cb me props.edge oppositeHandle.handleType
                    for_ state.onConnectStart \cb -> cb evtUnion params'
                , onConnect: case props.onReconnect of
                    Just cb -> Just (\conn -> cb props.edge conn)
                    Nothing -> Nothing
                , onConnectEnd: state.onConnectEnd
                , isValidConnection: case state.isValidConnection of
                    Just iv -> \conn -> iv
                      { source: conn.source
                      , target: conn.target
                      , sourceHandle: conn.sourceHandle
                      , targetHandle: conn.targetHandle
                      , edge: Nothing
                      }
                    Nothing -> \_ -> true
                , onReconnectEnd: Just \evtUnion finalState -> do
                    props.setReconnecting false
                    for_ props.onReconnectEnd \cb -> case evtUnion of
                      Left me' -> cb me' props.edge oppositeHandle.handleType finalState
                      Right _ -> pure unit
                , getTransform: _.transform <$> store.getState
                , getFromHandle: do
                    s <- store.getState
                    pure (extractFromHandle s.connection)
                , autoPanSpeed: Just state.autoPanSpeed
                , dragThreshold: state.connectionDragThreshold
                , handleDomNode: el
                }

        onMouseEnter = handler_ (props.setUpdateHover true)
        onMouseOut = handler_ (props.setUpdateHover false)
        radius = props.reconnectRadius

      pure $
        ( if showSource then
            element edgeAnchor
              { position: props.sourcePosition
              , centerX: props.sourceX
              , centerY: props.sourceY
              , radius
              , onMouseDown: mkAnchorMouseDown sourceOpposite
              , onMouseEnter
              , onMouseOut
              , type: "source"
              }
          else mempty
        )
          <>
            ( if showTarget then
                element edgeAnchor
                  { position: props.targetPosition
                  , centerX: props.targetX
                  , centerY: props.targetY
                  , radius
                  , onMouseDown: mkAnchorMouseDown targetOpposite
                  , onMouseEnter
                  , onMouseOut
                  , type: "target"
                  }
              else mempty
            )
