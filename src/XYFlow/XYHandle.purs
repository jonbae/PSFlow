-- | Connection-handle pointer interaction controller — port of
-- | `xyflow-main/packages/system/src/xyhandle/XYHandle.ts`.
-- |
-- | Exports a singleton `xyHandle :: XYHandleInstance` plus the parameter
-- | record types. `onPointerDown` is heavily effectful: it allocates `Ref`
-- | cells for closure state, registers DOM listeners on the document/host,
-- | and schedules an auto-pan rAF loop. `isValid` is `Effect`-typed because
-- | it queries the DOM via `querySelector`/`elementFromPoint`.
module XYFlow.XYHandle
  ( OnPointerDownParams
  , IsValidParams
  , HandleValidationResult
  , XYHandleInstance
  , OnConnectStart
  , OnConnectStartParams
  , OnConnect
  , OnConnectEnd
  , OnReconnectEnd
  , xyHandle
  ) where

import Prelude

import Control.Monad.State (StateT, get, modify_, runStateT)
import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Nullable (Nullable, toMaybe)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Web.DOM.Document (Document)
import Web.DOM.Element (Element)
import Web.HTML.HTMLDivElement (HTMLDivElement)
import Web.TouchEvent.TouchEvent (TouchEvent)
import Web.UIEvent.MouseEvent (MouseEvent)
import XYFlow.FFI.AnimationFrame
  ( RafHandle
  , cancelAnimationFrame
  , requestAnimationFrame
  )
import XYFlow.Types.Connection
  ( Connection
  , ConnectionInProgressData
  , ConnectionMode(..)
  , ConnectionState(..)
  , FinalConnectionState
  , IsValidConnection
  )
import XYFlow.Types.Geometry
  ( Position(..)
  , Transform
  , XYPosition
  , oppositePosition
  )
import XYFlow.Types.Handle (Handle, HandleType(..))
import XYFlow.Types.Node (InternalNodeBase, NodeLookup)
import XYFlow.Utils.Dom
  ( ShadowRoot
  , elementBoundingRect
  , getEventPosition
  , getHostForElement
  )
import XYFlow.Utils.Edges.Positions (getHandlePosition)
import XYFlow.Utils.General (calcAutoPan, pointToRendererPoint, rendererPointToPoint)
import XYFlow.XYHandle.Utils
  ( HandleRef
  , getClosestHandle
  , getHandle
  , getHandleType
  , isConnectionValid
  )

-- | TS `OnConnectStart` and friends are not yet defined in
-- | `XYFlow.Types.Connection`. They are introduced here at first use.
type OnConnectStartParams =
  { nodeId :: Maybe String
  , handleId :: Maybe String
  , handleType :: Maybe HandleType
  }

type OnConnectStart =
  Either MouseEvent TouchEvent
  -> OnConnectStartParams
  -> Effect Unit

type OnConnect = Connection -> Effect Unit

type OnConnectEnd nodeData =
  Either MouseEvent TouchEvent
  -> FinalConnectionState (InternalNodeBase nodeData)
  -> Effect Unit

type OnReconnectEnd nodeData =
  Either MouseEvent TouchEvent
  -> FinalConnectionState (InternalNodeBase nodeData)
  -> Effect Unit

type OnPointerDownParams nodeData =
  { autoPanOnConnect :: Boolean
  , connectionMode :: ConnectionMode
  , connectionRadius :: Number
  , domNode :: Maybe HTMLDivElement
  , handleId :: Maybe String
  , nodeId :: String
  , isTarget :: Boolean
  , nodeLookup :: NodeLookup nodeData
  , lib :: String
  , flowId :: Maybe String
  , edgeUpdaterType :: Maybe HandleType
  , updateConnection :: ConnectionState (InternalNodeBase nodeData) -> Effect Unit
  , panBy :: XYPosition -> Aff Boolean
  , cancelConnection :: Effect Unit
  , onConnectStart :: Maybe OnConnectStart
  , onConnect :: Maybe OnConnect
  , onConnectEnd :: Maybe (OnConnectEnd nodeData)
  , isValidConnection :: IsValidConnection
  , onReconnectEnd :: Maybe (OnReconnectEnd nodeData)
  , getTransform :: Effect Transform
  , getFromHandle :: Effect (Maybe Handle)
  , autoPanSpeed :: Maybe Number
  , dragThreshold :: Number
  , handleDomNode :: Element
  }

type IsValidParams nodeData =
  { handle :: Maybe HandleRef
  , connectionMode :: ConnectionMode
  , fromNodeId :: String
  , fromHandleId :: Maybe String
  , fromType :: HandleType
  , isValidConnection :: IsValidConnection
  , doc :: Either Document ShadowRoot
  , lib :: String
  , flowId :: Maybe String
  , nodeLookup :: NodeLookup nodeData
  }

type HandleValidationResult =
  { handleDomNode :: Maybe Element
  , isValid :: Boolean
  , connection :: Maybe Connection
  , toHandle :: Maybe Handle
  }

type XYHandleInstance =
  { onPointerDown
      :: forall nodeData
       . Either MouseEvent TouchEvent
      -> OnPointerDownParams nodeData
      -> Effect Unit
  , isValid
      :: forall nodeData
       . Either MouseEvent TouchEvent
      -> IsValidParams nodeData
      -> Effect HandleValidationResult
  }

-- | Singleton matching the TS module-level export.
xyHandle :: XYHandleInstance
xyHandle = { onPointerDown, isValid: isValidHandle }

-- | Closure state for `onPointerDown`. The TS source threads these values
-- | through nested handlers via captured locals; here the lifecycle handlers
-- | run as `StateT HandleDragState Effect` and the only true `Effect`
-- | boundary is the d3 callback registration, where a single outer
-- | `Ref HandleDragState` carries the snapshot across calls.
type HandleDragState =
  { autoPanId :: Maybe RafHandle
  , closestHandle :: Maybe Handle
  , connectionStarted :: Boolean
  , position :: XYPosition
  , autoPanStarted :: Boolean
  , connection :: Maybe Connection
  , isValid :: Maybe Boolean
  , resultHandleDomNode :: Maybe Element
  }

initialDragState :: XYPosition -> HandleDragState
initialDragState startPos =
  { autoPanId: Nothing
  , closestHandle: Nothing
  , connectionStarted: false
  , position: startPos
  , autoPanStarted: false
  , connection: Nothing
  , isValid: Nothing
  , resultHandleDomNode: Nothing
  }

-- | Run a `StateT HandleDragState Effect a` against an outer `Ref` and write
-- | the new state back. Forms the bridge from the d3-event `Effect` boundary
-- | to the pure-state interior.
runOnRef :: forall a. Ref HandleDragState -> StateT HandleDragState Effect a -> Effect a
runOnRef ref st = do
  s0 <- Ref.read ref
  Tuple a s1 <- runStateT st s0
  Ref.write s1 ref
  pure a

-- | Strict-mode rule: a from-handle of one side may only connect to a
-- | to-handle of the *opposite* side. Defined in terms of phantom-typed
-- | helpers exported from `XYFlow.Types.Handle`: dispatching once on
-- | `fromT` lets the inner branches treat the candidate as a typed
-- | `SourceHandle`/`TargetHandle`, so any future call site that takes the
-- | typed pair gets compile-time enforcement.
isStrictlyOpposite :: HandleType -> HandleType -> Boolean
isStrictlyOpposite fromT toT = case fromT, toT of
  Source, Target -> true
  Target, Source -> true
  _, _ -> false

-- ----------------------------------------------------------------------------
-- onPointerDown
-- ----------------------------------------------------------------------------

onPointerDown
  :: forall nodeData
   . Either MouseEvent TouchEvent
  -> OnPointerDownParams nodeData
  -> Effect Unit
onPointerDown event params = do
  doc <- getHostForElement Nothing
  -- Containers and starting handle resolution.
  containerBounds <- case params.domNode of
    Just el -> Just <$> elementBoundingRect el
    Nothing -> pure Nothing

  evPos <- getEventPosition event Nothing
  hType <- getHandleType params.edgeUpdaterType (Just params.handleDomNode)

  case containerBounds, hType of
    Just bounds, Just handleType -> do
      let
        mFromInternal = getHandle params.nodeId handleType params.handleId
          params.nodeLookup params.connectionMode false
      case mFromInternal of
        Nothing -> pure unit
        Just fromHandleInternal -> do
          let
            fromHandle :: Handle
            fromHandle = fromHandleInternal
              { nodeId = params.nodeId
              , handleType = handleType
              , position = fromHandleInternal.position
              }

          mFromInternalNode <- pure (Map.lookup params.nodeId params.nodeLookup)
          case mFromInternalNode of
            Nothing -> pure unit
            Just fromInternalNode -> do
              startPos <- getEventPosition event (Just bounds)
              stateRef <- Ref.new (initialDragState startPos)
              -- `previousConnection` stays in its own `Ref` because its type
              -- is parametric in `nodeData`; `HandleDragState` is monomorphic.

              let
                from = getHandlePosition fromInternalNode (Just fromHandle)
                  PosLeft true
                initialConnection :: ConnectionInProgressData (InternalNodeBase nodeData)
                initialConnection =
                  { isValid: Nothing
                  , from
                  , fromHandle
                  , fromPosition: fromHandle.position
                  , fromNode: fromInternalNode
                  , to: startPos
                  , toHandle: Nothing
                  , toPosition: oppositePosition fromHandle.position
                  , toNode: Nothing
                  , pointer: startPos
                  }
              previousConnection <- Ref.new initialConnection

              let
                startConnection :: StateT HandleDragState Effect Unit
                startConnection = do
                  modify_ _ { connectionStarted = true }
                  prev <- liftEffect (Ref.read previousConnection)
                  liftEffect (params.updateConnection (ConnectionInProgress prev))
                  liftEffect $ for_ params.onConnectStart \cb -> cb event
                    { nodeId: Just params.nodeId
                    , handleId: params.handleId
                    , handleType: Just handleType
                    }

              when (params.dragThreshold == 0.0)
                (runOnRef stateRef startConnection)

              let
                -- `requestAnimationFrame` takes `Effect Unit`, so the rAF
                -- loop has to re-enter the StateT at each tick. Eta-expanded
                -- to break the mutual-recursion-on-values cycle with
                -- `autoPanStep`.
                autoPan :: Unit -> Effect Unit
                autoPan _ = runOnRef stateRef autoPanStep

                autoPanStep :: StateT HandleDragState Effect Unit
                autoPanStep =
                  if not params.autoPanOnConnect then pure unit
                  else do
                    s <- get
                    let
                      speed = fromMaybe 15.0 params.autoPanSpeed
                      mv = calcAutoPan s.position
                        { width: bounds.width, height: bounds.height }
                        speed
                        40.0
                    liftEffect $ launchAff_ do
                      _ <- params.panBy { x: mv.x, y: mv.y }
                      pure unit
                    handle <- liftEffect (requestAnimationFrame (autoPan unit))
                    modify_ _ { autoPanId = Just handle }

                onPointerMove :: Either MouseEvent TouchEvent -> Effect Unit
                onPointerMove ev = do
                  evPos2 <- getEventPosition ev Nothing
                  proceed <- runOnRef stateRef do
                    s <- get
                    let
                      dx = evPos2.x - evPos.x
                      dy = evPos2.y - evPos.y
                      threshold = params.dragThreshold
                      moved = dx * dx + dy * dy > threshold * threshold
                    if s.connectionStarted then pure true
                    else if moved then do
                      startConnection
                      pure true
                    else pure false

                  when proceed do
                    mFromHandleNow <- params.getFromHandle
                    case mFromHandleNow of
                      Nothing -> onPointerUp ev
                      Just _ -> stepMove ev

                stepMove :: Either MouseEvent TouchEvent -> Effect Unit
                stepMove ev = do
                  transform <- params.getTransform
                  curPos <- getEventPosition ev (Just bounds)
                  let
                    rendererPos = pointToRendererPoint curPos transform Nothing
                    fromHandleRef :: HandleRef
                    fromHandleRef =
                      { nodeId: params.nodeId
                      , id: params.handleId
                      , handleType
                      }
                    closest = getClosestHandle rendererPos
                      params.connectionRadius
                      params.nodeLookup
                      fromHandleRef

                  result <- isValidHandle ev
                    { handle: case closest of
                        Just h -> Just
                          { nodeId: h.nodeId
                          , id: h.id
                          , handleType: h.handleType
                          }
                        Nothing -> Nothing
                    , connectionMode: params.connectionMode
                    , fromNodeId: params.nodeId
                    , fromHandleId: params.handleId
                    , fromType: if params.isTarget then Target else Source
                    , isValidConnection: params.isValidConnection
                    , doc
                    , lib: params.lib
                    , flowId: params.flowId
                    , nodeLookup: params.nodeLookup
                    }

                  let validNow = isConnectionValid (isJust closest) result.isValid

                  runOnRef stateRef do
                    modify_ _
                      { position = curPos
                      , closestHandle = closest
                      , resultHandleDomNode = result.handleDomNode
                      , connection = result.connection
                      , isValid = validNow
                      }
                    s <- get
                    when (not s.autoPanStarted) do
                      liftEffect (autoPan unit)
                      modify_ _ { autoPanStarted = true }

                  prev <- Ref.read previousConnection
                  let
                    fromInternalNode' = Map.lookup params.nodeId
                      params.nodeLookup
                    fresh = case fromInternalNode' of
                      Just fn -> getHandlePosition fn (Just fromHandle)
                        PosLeft true
                      Nothing -> prev.from
                    nextTo = case result.toHandle, validNow of
                      Just toH, Just true ->
                        rendererPointToPoint
                          { x: toH.x, y: toH.y }
                          transform
                      _, _ -> curPos
                    nextToPosition = case validNow, result.toHandle of
                      Just true, Just toH -> toH.position
                      _, _ -> oppositePosition fromHandle.position
                    nextToNode = case result.toHandle of
                      Just toH -> Map.lookup toH.nodeId params.nodeLookup
                      Nothing -> Nothing
                    next :: ConnectionInProgressData (InternalNodeBase nodeData)
                    next = prev
                      { from = fresh
                      , isValid = validNow
                      , to = nextTo
                      , toHandle = result.toHandle
                      , toPosition = nextToPosition
                      , toNode = nextToNode
                      , pointer = curPos
                      }
                  params.updateConnection (ConnectionInProgress next)
                  Ref.write next previousConnection

                onPointerUp :: Either MouseEvent TouchEvent -> Effect Unit
                onPointerUp ev = do
                  multi <- isMultiTouchEvent ev
                  unless multi $ runOnRef stateRef do
                    s <- get
                    when s.connectionStarted do
                      liftEffect $ case s.connection, s.isValid of
                        Just conn, Just true
                          | isJust s.closestHandle
                              || isJust s.resultHandleDomNode ->
                              for_ params.onConnect \cb -> cb conn
                        _, _ -> pure unit

                      prev <- liftEffect (Ref.read previousConnection)
                      let
                        final :: FinalConnectionState (InternalNodeBase nodeData)
                        final = Just prev
                      liftEffect $ for_ params.onConnectEnd \cb -> cb ev final
                      when (isJust params.edgeUpdaterType) $ liftEffect $
                        for_ params.onReconnectEnd \cb -> cb ev final

                    liftEffect params.cancelConnection
                    liftEffect $ for_ s.autoPanId cancelAnimationFrame
                    -- Clear the in-flight flags so a stale snapshot can't
                    -- leak across a re-bound listener.
                    modify_ _
                      { autoPanId = Nothing
                      , autoPanStarted = false
                      , isValid = Nothing
                      , connection = Nothing
                      , resultHandleDomNode = Nothing
                      }
                    liftEffect $ removeDocListeners doc onPointerMove onPointerUp

              -- Wire listeners. The TS source casts both as `EventListener`.
              addDocListeners doc onPointerMove onPointerUp
    _, _ -> pure unit

-- ----------------------------------------------------------------------------
-- isValidHandle (TS internal `isValidHandle` is exposed via xyHandle.isValid)
-- ----------------------------------------------------------------------------

isValidHandle
  :: forall nodeData
   . Either MouseEvent TouchEvent
  -> IsValidParams nodeData
  -> Effect HandleValidationResult
isValidHandle event p = do
  -- Locate the handle's DOM node by data attributes.
  mHandleDomNode <- case p.handle of
    Just h -> querySelectorOnDoc p.doc
      (handleSelector p.lib p.flowId h)
    Nothing -> pure Nothing

  pos <- getEventPosition event Nothing
  mBelow <- elementFromPointOnDoc p.doc pos.x pos.y
  belowIsHandleClass <- case mBelow of
    Just el -> classListContains el (p.lib <> "-flow__handle")
    Nothing -> pure false

  let
    handleToCheck = case mBelow, belowIsHandleClass of
      Just el, true -> Just el
      _, _ -> mHandleDomNode

  case handleToCheck of
    Nothing -> pure
      { handleDomNode: handleToCheck
      , isValid: false
      , connection: Nothing
      , toHandle: Nothing
      }
    Just el -> do
      mHandleType <- getHandleType Nothing (Just el)
      mNid <- getAttribute el "data-nodeid"
      mHid <- getAttribute el "data-handleid"
      connectable <- classListContains el "connectable"
      connectableEnd <- classListContains el "connectableend"
      case mNid, mHandleType of
        Just nid, Just hType -> do
          let
            isTarget = p.fromType == Target
            connection :: Connection
            connection =
              { source: if isTarget then nid else p.fromNodeId
              , sourceHandle: if isTarget then mHid else p.fromHandleId
              , target: if isTarget then p.fromNodeId else nid
              , targetHandle: if isTarget then p.fromHandleId else mHid
              }
            modeOk = case p.connectionMode of
              Strict -> isStrictlyOpposite p.fromType hType
              Loose ->
                nid /= p.fromNodeId || mHid /= p.fromHandleId
            isConnectableNow = connectable && connectableEnd
            preIsValid = isConnectableNow && modeOk
            isValidNow = preIsValid && p.isValidConnection connection
            mTo = getHandle nid hType mHid p.nodeLookup p.connectionMode true
          pure
            { handleDomNode: handleToCheck
            , isValid: isValidNow
            , connection: Just connection
            , toHandle: mTo
            }
        _, _ -> pure
          { handleDomNode: handleToCheck
          , isValid: false
          , connection: Nothing
          , toHandle: Nothing
          }

-- | Build the CSS selector matching the TS template literal:
-- |   `.${lib}-flow__handle[data-id="${flowId}-${nodeId}-${handleId}-${type}"]`
handleSelector :: String -> Maybe String -> HandleRef -> String
handleSelector lib flowId h =
  "." <> lib <> "-flow__handle[data-id=\""
    <> fromMaybe "" flowId
    <> "-"
    <> h.nodeId
    <> "-"
    <> fromMaybe "null" h.id
    <> "-"
    <> handleTypeTag h.handleType
    <> "\"]"
  where
  handleTypeTag = case _ of
    Source -> "source"
    Target -> "target"

-- ----------------------------------------------------------------------------
-- FFI imports — DOM operations not covered by our existing utility modules.
-- ----------------------------------------------------------------------------

foreign import classListContains :: Element -> String -> Effect Boolean
foreign import isMultiTouchEvent
  :: Either MouseEvent TouchEvent -> Effect Boolean

foreign import getAttributeImpl
  :: Element -> String -> Effect (Nullable String)
foreign import querySelectorOnDocImpl
  :: { tag :: String, value :: Element }
  -> String
  -> Effect (Nullable Element)
foreign import elementFromPointOnDocImpl
  :: { tag :: String, value :: Element }
  -> Number
  -> Number
  -> Effect (Nullable Element)

getAttribute :: Element -> String -> Effect (Maybe String)
getAttribute el name = map toMaybe (getAttributeImpl el name)

querySelectorOnDoc
  :: Either Document ShadowRoot
  -> String
  -> Effect (Maybe Element)
querySelectorOnDoc d sel = map toMaybe (querySelectorOnDocImpl (docTag d) sel)

elementFromPointOnDoc
  :: Either Document ShadowRoot
  -> Number
  -> Number
  -> Effect (Maybe Element)
elementFromPointOnDoc d x y =
  map toMaybe (elementFromPointOnDocImpl (docTag d) x y)

-- | Tag the host as `"doc"` or `"shadow"` so the JS side can call the right
-- | API. The wrapper carries `Element` opaquely — the JS layer treats it as
-- | the actual host object.
docTag
  :: Either Document ShadowRoot
  -> { tag :: String, value :: Element }
docTag = case _ of
  Left d -> { tag: "doc", value: docCoerce d }
  Right sr -> { tag: "shadow", value: shadowCoerce sr }

foreign import docCoerce :: Document -> Element
foreign import shadowCoerce :: ShadowRoot -> Element

-- | Listener wiring. We pass the handlers as unary `Effect`-returning
-- | callbacks; the JS layer adapts them to `EventListener`.
foreign import addDocListenersImpl
  :: { tag :: String, value :: Element }
  -> (Either MouseEvent TouchEvent -> Effect Unit)
  -> (Either MouseEvent TouchEvent -> Effect Unit)
  -> Effect Unit

foreign import removeDocListenersImpl
  :: { tag :: String, value :: Element }
  -> (Either MouseEvent TouchEvent -> Effect Unit)
  -> (Either MouseEvent TouchEvent -> Effect Unit)
  -> Effect Unit

addDocListeners
  :: Either Document ShadowRoot
  -> (Either MouseEvent TouchEvent -> Effect Unit)
  -> (Either MouseEvent TouchEvent -> Effect Unit)
  -> Effect Unit
addDocListeners d move up = addDocListenersImpl (docTag d) move up

removeDocListeners
  :: Either Document ShadowRoot
  -> (Either MouseEvent TouchEvent -> Effect Unit)
  -> (Either MouseEvent TouchEvent -> Effect Unit)
  -> Effect Unit
removeDocListeners d move up = removeDocListenersImpl (docTag d) move up

