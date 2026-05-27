-- | `<Handle />` — the connection point on a node. React-side wiring on
-- | top of `System.XYHandle.onPointerDown` / `System.XYHandle.isValid`.
-- | Mirrors `xyflow-main/packages/react/src/components/Handle/index.tsx`.
-- |
-- | This module is the React-layer twin of `System.XYHandle`: the system
-- | layer owns the pointer-drag state machine and the click-connect
-- | validity check, this module owns the React glue (event handlers,
-- | store reads, dispatch, visual-class flags).
-- |
-- | The wiring pattern matches
-- | `React.Component.EdgeWrapper.UpdateAnchors`, which solved the same
-- | "synthetic event -> XYHandle.onPointerDown" problem for reconnect
-- | drags. A few small helpers (`syntheticToMouse`, `currentTargetElement`,
-- | `panByAdapter`, `extractFromHandle`) are duplicated here rather than
-- | extracted to a shared module — if a third caller appears, lift them.
module React.Handle
  ( handle
  ) where

import Prelude

import Data.Array (uncons) as Array
import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Events (EventHandler, SyntheticEvent, handler, syntheticEvent)
import React.Basic.Hooks (memo, reactComponent)
import React.Basic.Hooks as React
import React.Context.NodeId (useNodeId)
import React.FFI.DOM (div_, opt)
import React.Hook.Store (UseStoreApi, useStore, useStoreApi)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import React.Types.Component (HandleProps)
import React.Types.Edges (DefaultEdgeOptions)
import React.Types.General (IsValidConnection) as RG
import React.Types.Store (ReactFlowState, ConnectionClickStartHandle)
import System.Constants (ErrorCode(..), errorMessage)
import System.Types.Connection
  ( Connection
  , ConnectionMode(..)
  , ConnectionState(..)
  )
import System.Types.Edge (EdgeBase)
import System.Types.Geometry (Position(..))
import System.Types.Handle (Handle, HandleType(..))
import System.Types.Ids (NodeId(..))
import System.Utils.Dom (getHostForElement)
import System.Utils.Edges.General (addEdge, getEdgeId)
import System.XYHandle (xyHandle)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Element (Element)
import Web.Event.Event (currentTarget) as Event
import Web.UIEvent.MouseEvent (MouseEvent)
import Web.UIEvent.MouseEvent (button, toEvent) as ME

type HandleStoreSlice =
  { connectOnClick :: Boolean
  , noPanClassName :: String
  , rfId :: String
  }

selectHandleSlice :: forall n e. ReactFlowState n e -> HandleStoreSlice
selectHandleSlice s =
  { connectOnClick: s.connectOnClick
  , noPanClassName: s.noPanClassName
  , rfId: s.rfId
  }

-- | The seven visual-class flags. Mirrors TS `connectingSelector`.
-- | Record-of-Booleans satisfies `useStore`'s `Eq` constraint.
type ConnectingFlags =
  { connectingFrom :: Boolean
  , connectingTo :: Boolean
  , clickConnecting :: Boolean
  , isPossibleEndHandle :: Boolean
  , connectionInProcess :: Boolean
  , clickConnectionInProcess :: Boolean
  , valid :: Boolean
  }

selectConnectingFlags
  :: forall n e
   . NodeId
  -> Maybe String
  -> HandleType
  -> ReactFlowState n e
  -> ConnectingFlags
selectConnectingFlags nodeId handleId hType state =
  case state.connection of
    NoConnection ->
      { connectingFrom: false
      , connectingTo: false
      , clickConnecting
      , isPossibleEndHandle: case state.connectionClickStartHandle of
          Just s -> case state.connectionMode of
            Strict -> s.handleType /= hType
            Loose -> nodeId /= NodeId s.nodeId || handleId /= s.id
          Nothing -> false
      , connectionInProcess: false
      , clickConnectionInProcess
      , valid: false
      }
    ConnectionInProgress p ->
      let
        fromMatches =
          p.fromHandle.nodeId == nodeId
            && p.fromHandle.id == handleId
            && p.fromHandle.handleType == hType
        toMatches = case p.toHandle of
          Just t -> t.nodeId == nodeId
            && t.id == handleId
            && t.handleType == hType
          Nothing -> false
      in
        { connectingFrom: fromMatches
        , connectingTo: toMatches
        , clickConnecting
        , isPossibleEndHandle: case state.connectionMode of
            Strict -> p.fromHandle.handleType /= hType
            Loose -> nodeId /= p.fromHandle.nodeId
              || handleId /= p.fromHandle.id
        , connectionInProcess: true
        , clickConnectionInProcess
        , valid: toMatches && p.isValid == Just true
        }
  where
  clickConnecting = case state.connectionClickStartHandle of
    Just s -> NodeId s.nodeId == nodeId
      && s.id == handleId
      && s.handleType == hType
    Nothing -> false

  clickConnectionInProcess = isJust state.connectionClickStartHandle

positionString :: Position -> String
positionString = case _ of
  PosLeft -> "left"
  PosRight -> "right"
  PosTop -> "top"
  PosBottom -> "bottom"

handleTypeString :: HandleType -> String
handleTypeString = case _ of
  Source -> "source"
  Target -> "target"

-- | Builds the space-separated `className` string mirroring the TS
-- | `cc([...])` output. Empty/false flags are dropped.
buildClassName
  :: { position :: Position
     , isTarget :: Boolean
     , isConnectable :: Boolean
     , isConnectableStart :: Boolean
     , isConnectableEnd :: Boolean
     , noPanClassName :: String
     , extra :: Maybe String
     , flags :: ConnectingFlags
     }
  -> String
buildClassName p =
  joinNonEmpty
    [ "react-flow__handle"
    , "react-flow__handle-" <> positionString p.position
    , "nodrag"
    , p.noPanClassName
    , fromMaybe "" p.extra
    , if p.isTarget then "target" else "source"
    , if p.isConnectable then "connectable" else ""
    , if p.isConnectableStart then "connectablestart" else ""
    , if p.isConnectableEnd then "connectableend" else ""
    , if p.flags.clickConnecting then "clickconnecting" else ""
    , if p.flags.connectingFrom then "connectingfrom" else ""
    , if p.flags.connectingTo then "connectingto" else ""
    , if p.flags.valid then "valid" else ""
    , if indicatorOn then "connectionindicator" else ""
    ]
  where
  inProcess = p.flags.connectionInProcess
  clickInProcess = p.flags.clickConnectionInProcess
  endSlotOk = if inProcess || clickInProcess then p.isConnectableEnd
  else p.isConnectableStart
  indicatorOn = p.isConnectable
    && (not inProcess || p.flags.isPossibleEndHandle)
    && endSlotOk

joinNonEmpty :: Array String -> String
joinNonEmpty = foldStrip ""
  where
  foldStrip acc as = case Array.uncons as of
    Nothing -> acc
    Just { head: "", tail } -> foldStrip acc tail
    Just { head, tail }
      | acc == "" -> foldStrip head tail
      | otherwise -> foldStrip (acc <> " " <> head) tail

-- ---------------------------------------------------------------------------
-- Local helpers — duplicates of the ones in
-- `React.Component.EdgeWrapper.UpdateAnchors`. Promote to a shared module if
-- a third caller appears.
-- ---------------------------------------------------------------------------

syntheticToMouse :: SyntheticEvent -> MouseEvent
syntheticToMouse = unsafeCoerce

currentTargetElement :: SyntheticEvent -> Maybe Element
currentTargetElement se =
  map unsafeCoerce
    (Event.currentTarget (ME.toEvent (syntheticToMouse se)))

-- | Fire-and-forget pan adapter. `Action PanBy` has no `Aff`-completing
-- | path; we dispatch and immediately report success. Acceptable because
-- | the reducer applies the delta synchronously.
panByAdapter
  :: forall n e
   . Store n e
  -> { x :: Number, y :: Number }
  -> Aff Boolean
panByAdapter store delta =
  liftEffect (store.dispatch (PanBy delta)) *> pure true

extractFromHandle :: forall node. ConnectionState node -> Maybe Handle
extractFromHandle = case _ of
  NoConnection -> Nothing
  ConnectionInProgress p -> Just p.fromHandle

-- | Adapt a React-layer `IsValidConnection e` (record carrying
-- | `edge :: Maybe (Edge e)`) to the system-layer `Connection -> Boolean`
-- | shape that `XYHandle.onPointerDown` expects. During a fresh drag
-- | there's no candidate edge, so we pass `edge: Nothing`.
liftValidConn :: forall e. RG.IsValidConnection e -> Connection -> Boolean
liftValidConn iv conn = iv
  { source: conn.source
  , target: conn.target
  , sourceHandle: conn.sourceHandle
  , targetHandle: conn.targetHandle
  , edge: Nothing
  }

-- ---------------------------------------------------------------------------
-- onConnect: merge defaultEdgeOptions, dispatch SetEdges if hasDefaultEdges,
-- fire store + prop callbacks.
-- ---------------------------------------------------------------------------

connectionToEdge
  :: forall e
   . Maybe (DefaultEdgeOptions e)
  -> Connection
  -> EdgeBase e
connectionToEdge mDefaults conn =
  { id: getEdgeId conn
  , edgeType: Nothing
  , source: conn.source
  , target: conn.target
  , sourceHandle: conn.sourceHandle
  , targetHandle: conn.targetHandle
  , animated: fromMaybe false (_.animated =<< mDefaults)
  , hidden: fromMaybe false (_.hidden =<< mDefaults)
  , deletable: _.deletable =<< mDefaults
  , selectable: _.selectable =<< mDefaults
  , data: _.data =<< mDefaults
  , selected: false
  , markerStart: Nothing
  , markerEnd: Nothing
  , zIndex: _.zIndex =<< mDefaults
  , ariaLabel: _.ariaLabel =<< mDefaults
  , interactionWidth: _.interactionWidth =<< mDefaults
  }

-- | The reusable "user dropped a valid connection" path. Used by both
-- | drag (`onPointerDown` -> XYHandle -> onConnect cb) and click-connect
-- | step 2 (`onClick` -> XYHandle.isValid -> here).
onConnectExtended
  :: forall n e
   . Store n e
  -> Maybe (Connection -> Effect Unit)
  -> Connection
  -> Effect Unit
onConnectExtended store mPropOnConnect conn = do
  state <- store.getState
  when state.hasDefaultEdges do
    let
      edge = connectionToEdge state.defaultEdgeOptions conn
    case addEdge edge state.edges getEdgeId of
      Right next -> store.dispatch (SetEdges next)
      Left _ -> pure unit
  for_ state.onConnect \cb -> cb conn
  for_ mPropOnConnect \cb -> cb conn

-- ---------------------------------------------------------------------------
-- The component
-- ---------------------------------------------------------------------------

handle :: ReactComponent HandleProps
handle = unsafePerformEffect $ memo $ reactComponent "Handle" \(props :: HandleProps) -> React.do
  slice <- useStore selectHandleSlice
  store <- (useStoreApi :: React.Hook UseStoreApi _)
  nodeIdM <- useNodeId
  let
    nodeIdStr = case nodeIdM of
      Just nid -> nid
      Nothing -> unsafeThrow (errorMessage E010)
    nodeId = NodeId nodeIdStr
    handleId = props.id
    handleType = props.handleType
  flags <- useStore (selectConnectingFlags nodeId handleId handleType)
  let
    isConnectable = fromMaybe true props.isConnectable
    isConnectableStart = fromMaybe true props.isConnectableStart
    isConnectableEnd = fromMaybe true props.isConnectableEnd
    isTarget = case handleType of
      Target -> true
      Source -> false
    className = buildClassName
      { position: props.position
      , isTarget
      , isConnectable
      , isConnectableStart
      , isConnectableEnd
      , noPanClassName: slice.noPanClassName
      , extra: props.className
      , flags
      }
    dataId = slice.rfId
      <> "-"
      <> nodeIdStr
      <> "-"
      <> fromMaybe "" handleId
      <> "-"
      <> handleTypeString handleType

    onPointerDown :: EventHandler
    onPointerDown = handler syntheticEvent \se -> do
      let me = syntheticToMouse se
      when (isConnectableStart && ME.button me == 0) do
        state <- store.getState
        case currentTargetElement se of
          Nothing -> pure unit
          Just el -> xyHandle.onPointerDown (Left me)
            { autoPanOnConnect: state.autoPanOnConnect
            , connectionMode: state.connectionMode
            , connectionRadius: state.connectionRadius
            , domNode: state.domNode
            , handleId
            , nodeId
            , isTarget
            , nodeLookup: state.nodeLookup
            , lib: state.lib
            , flowId: Just state.rfId
            , edgeUpdaterType: Nothing
            , updateConnection: \cs -> store.dispatch (UpdateConnection cs)
            , panBy: panByAdapter store
            , cancelConnection: store.dispatch CancelConnection
            , onConnectStart: state.onConnectStart
            , onConnect: Just (onConnectExtended store props.onConnect)
            , onConnectEnd: state.onConnectEnd
            , isValidConnection: case props.isValidConnection of
                Just iv -> liftValidConn iv
                Nothing -> case state.isValidConnection of
                  Just iv -> liftValidConn iv
                  Nothing -> \_ -> true
            , onReconnectEnd: Nothing
            , getTransform: _.transform <$> store.getState
            , getFromHandle: do
                s <- store.getState
                pure (extractFromHandle s.connection)
            , autoPanSpeed: Just state.autoPanSpeed
            , dragThreshold: state.connectionDragThreshold
            , handleDomNode: el
            }

    onClick :: EventHandler
    onClick = handler syntheticEvent \se -> do
      let me = syntheticToMouse se
      state <- store.getState
      let
        canStart = isConnectableStart
        haveStart = isJust state.connectionClickStartHandle
      when (canStart || haveStart) do
        case state.connectionClickStartHandle of
          Nothing -> do
            for_ state.onClickConnectStart \cb -> cb (Left me)
              { nodeId: Just nodeId
              , handleId
              , handleType: Just handleType
              }
            store.dispatch
              ( PatchState
                  ( _
                      { connectionClickStartHandle = Just
                          { nodeId: nodeIdStr
                          , id: handleId
                          , handleType
                          } :: Maybe ConnectionClickStartHandle
                      }
                  )
              )
          Just startHandle -> do
            host <- getHostForElement Nothing
            result <- xyHandle.isValid (Left me)
              { handle: Just
                  { nodeId
                  , id: handleId
                  , handleType
                  }
              , connectionMode: state.connectionMode
              , fromNodeId: NodeId startHandle.nodeId
              , fromHandleId: startHandle.id
              , fromType: startHandle.handleType
              , isValidConnection: case props.isValidConnection of
                  Just iv -> liftValidConn iv
                  Nothing -> case state.isValidConnection of
                    Just iv -> liftValidConn iv
                    Nothing -> \_ -> true
              , doc: host
              , lib: state.lib
              , flowId: Just state.rfId
              , nodeLookup: state.nodeLookup
              }
            case result.isValid, result.connection of
              true, Just conn -> onConnectExtended store props.onConnect conn
              _, _ -> pure unit
            -- Fire onClickConnectEnd with the (now-final) connection state.
            -- `FinalConnectionState` is `Maybe ConnectionInProgressData`, so
            -- extract the in-progress payload (or `Nothing` if the click
            -- happened with no active drag).
            let
              finalState = case state.connection of
                NoConnection -> Nothing
                ConnectionInProgress p -> Just p
            for_ state.onClickConnectEnd \cb -> cb (Left me) finalState
            store.dispatch
              ( PatchState (_ { connectionClickStartHandle = Nothing }) )

  pure $ div_
    { className
    , style: opt props.style
    , "data-handleid": opt handleId
    , "data-nodeid": nodeIdStr
    , "data-handlepos": positionString props.position
    , "data-id": dataId
    , onMouseDown: onPointerDown
    , onTouchStart: onPointerDown
    , onClick: if slice.connectOnClick then onClick else handler syntheticEvent \_ -> pure unit
    }
    []
