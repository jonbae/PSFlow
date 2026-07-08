-- | Node drag controller — port of
-- | `xyflow-main/packages/system/src/xydrag/XYDrag.ts`.
-- |
-- | The TS `XYDrag` is a factory that captures mutable state (`lastPos`,
-- | `dragItems`, `autoPanId`, …) in a closure and returns an object with
-- | `update`/`destroy` methods. The PS port collapses that state into a
-- | plain `DragState` record and lifts the lifecycle handlers (`onStart`,
-- | `onDragHandler`, `onEnd`, `startDrag`, `autoPan`, `updateNodes`) to
-- | `StateT DragState Effect`. A single outer `Ref DragState` carries the
-- | snapshot across the d3-callback boundary via `runOnRef`. d3-drag
-- | wiring goes through `System.FFI.D3Drag`.
-- |
-- | Type-parameter divergence from TS: the TS source has a single
-- | `<OnNodeDrag>` parameter that abstracts the user callback shape.
-- | `NodeBase`/`EdgeBase` are referenced unparameterized (effectively `<any>`).
-- | The PS equivalents are parameterized (`NodeBase nodeData`,
-- | `EdgeBase edgeData`), so the port threads two parameters through the
-- | store and the params record.
module System.XYDrag
  ( DragUpdateParams
  , DragStoreItems
  , XYDragParams
  , XYDragInstance
  , OnDrag
  , OnNodeDrag
  , OnSelectionDrag
  , PanBy
  , UpdateNodePositions
  , createXYDrag
  ) where

import Prelude

import Control.Monad.Except (runExcept)
import Control.Monad.State (StateT, get, modify_, runStateT)
import Data.Either (Either(..))
import Data.Foldable (foldM, for_, traverse_)
import Data.Map (Map)
import Data.Map (empty, insert, lookup, size, toUnfoldable) as Map
import Data.Maybe (Maybe(..), fromMaybe, isNothing)
import Data.Number (sqrt)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Foreign (Foreign, unsafeReadTagged)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Element (Element)
import Web.TouchEvent.TouchEvent (TouchEvent)
import Web.UIEvent.MouseEvent (MouseEvent)
import System.FFI.AnimationFrame
  ( RafHandle
  , cancelAnimationFrame
  , requestAnimationFrame
  )
import System.FFI.D3Drag
  ( D3DragEvent
  , applyDrag
  , dragBehavior
  , dragSourceEvent
  , setDragClickDistance
  , setDragFilter
  , setDragOn
  )
import System.FFI.D3Selection
  ( D3Selection
  , d3Select
  , d3SelectionOnNull
  )
import System.Types.Edge (EdgeBase)
import System.Types.Geometry
  ( CoordinateExtent
  , NodeOrigin
  , SnapGrid
  , Transform(..)
  , XYPosition
  )
import System.Types.Ids (NodeId)
import System.Types.Node
  ( NodeBase
  , NodeDragItem
  , NodeLookup
  )
import System.Utils.Dom
  ( DOMRect
  , elementBoundingRect
  , getEventPosition
  , getPointerPosition
  )
import System.Utils.General (calcAutoPan, roundHalfAwayFromZero, snapPosition)
import System.Utils.Graph (calculateNodePosition)
import System.XYDrag.Utils
  ( calculateSnapOffset
  , getDragItems
  , getEventHandlerParams
  , hasSelector
  )

-- | TS `(event, dragItems, node, nodes) => void`.
type OnDrag nodeData =
  MouseEvent
  -> Map NodeId NodeDragItem
  -> NodeBase nodeData
  -> Array (NodeBase nodeData)
  -> Effect Unit

-- | TS `(event, node, nodes) => void`.
type OnNodeDrag nodeData =
  MouseEvent
  -> NodeBase nodeData
  -> Array (NodeBase nodeData)
  -> Effect Unit

-- | TS `(event, nodes) => void`.
type OnSelectionDrag nodeData =
  MouseEvent
  -> Array (NodeBase nodeData)
  -> Effect Unit

-- | TS `({ x, y }) => Promise<boolean>`.
type PanBy = XYPosition -> Aff Boolean

-- | TS `(items, dragging) => void`.
type UpdateNodePositions = Map NodeId NodeDragItem -> Boolean -> Effect Unit

-- | Per-node-element configuration applied via `XYDragInstance.update`.
type DragUpdateParams =
  { noDragClassName :: Maybe String
  , handleSelector :: Maybe String
  , isSelectable :: Boolean
  , nodeId :: Maybe NodeId
  , domNode :: Element
  , nodeClickDistance :: Number
  }

-- | The store snapshot the controller reads on every drag tick. TS uses a
-- | thunk `getStoreItems()`; PS uses `Effect`.
type DragStoreItems nodeData edgeData =
  { nodes :: Array (NodeBase nodeData)
  , nodeLookup :: NodeLookup nodeData
  , edges :: Array (EdgeBase edgeData)
  , nodeExtent :: CoordinateExtent
  , snapGrid :: SnapGrid
  , snapToGrid :: Boolean
  , nodeOrigin :: NodeOrigin
  , multiSelectionActive :: Boolean
  , domNode :: Maybe Element
  , transform :: Transform
  , autoPanOnNodeDrag :: Boolean
  , nodesDraggable :: Boolean
  , selectNodesOnDrag :: Boolean
  , nodeDragThreshold :: Number
  , panBy :: PanBy
  , unselectNodesAndEdges :: Effect Unit
  , onNodeDragStart :: Maybe (OnNodeDrag nodeData)
  , onNodeDrag :: Maybe (OnNodeDrag nodeData)
  , onNodeDragStop :: Maybe (OnNodeDrag nodeData)
  , onSelectionDragStart :: Maybe (OnSelectionDrag nodeData)
  , onSelectionDrag :: Maybe (OnSelectionDrag nodeData)
  , onSelectionDragStop :: Maybe (OnSelectionDrag nodeData)
  , updateNodePositions :: UpdateNodePositions
  , autoPanSpeed :: Maybe Number
  }

type XYDragParams nodeData edgeData =
  { getStoreItems :: Effect (DragStoreItems nodeData edgeData)
  , onDragStart :: Maybe (OnDrag nodeData)
  , onDrag :: Maybe (OnDrag nodeData)
  , onDragStop :: Maybe (OnDrag nodeData)
  , onNodeMouseDown :: Maybe (NodeId -> Effect Unit)
  , autoPanSpeed :: Maybe Number
  }

type XYDragInstance =
  { update :: DragUpdateParams -> Effect Unit
  , destroy :: Effect Unit
  }

-- | Plain-record closure state. Lifecycle handlers run as
-- | `StateT DragState Effect` and a single outer `Ref DragState`
-- | carries the snapshot across the d3-callback boundary via `runOnRef`.
-- | Mirrors the shape `System.XYHandle` uses for its drag lifecycle.
type DragState =
  { lastPos :: { x :: Maybe Number, y :: Maybe Number }
  , autoPanId :: Maybe RafHandle
  , dragItems :: Map NodeId NodeDragItem
  , autoPanStarted :: Boolean
  , mousePosition :: XYPosition
  , containerBounds :: Maybe DOMRect
  , dragStarted :: Boolean
  , d3Selection :: Maybe D3Selection
  , abortDrag :: Boolean
  , nodePositionsChanged :: Boolean
  , dragEvent :: Maybe MouseEvent
  }

initialDragState :: DragState
initialDragState =
  { lastPos: { x: Nothing, y: Nothing }
  , autoPanId: Nothing
  , dragItems: Map.empty
  , autoPanStarted: false
  , mousePosition: { x: 0.0, y: 0.0 }
  , containerBounds: Nothing
  , dragStarted: false
  , d3Selection: Nothing
  , abortDrag: false
  , nodePositionsChanged: false
  , dragEvent: Nothing
  }

-- | Run a `StateT DragState Effect a` against an outer `Ref` and write
-- | the new state back. Forms the bridge from the d3-event `Effect`
-- | boundary (and rAF / aff callbacks) to the pure-state interior.
runOnRef :: forall a. Ref DragState -> StateT DragState Effect a -> Effect a
runOnRef ref st = do
  s0 <- Ref.read ref
  Tuple a s1 <- runStateT st s0
  Ref.write s1 ref
  pure a

-- | The d3 source event arrives as `Foreign`. We attempt a tag-check via
-- | `Foreign.unsafeReadTagged` and only fall back to `unsafeCoerce` (the
-- | original TS-equivalent pattern) when the runtime tag isn't a literal
-- | match — `PointerEvent` and other MouseEvent subtypes that d3 forwards
-- | won't read as exactly `"MouseEvent"`. The check is best-effort
-- | telemetry rather than a hard refusal so the drag stays uninterrupted.
foreignAsMouseEvent :: Foreign -> MouseEvent
foreignAsMouseEvent f = case runExcept (unsafeReadTagged "MouseEvent" f) of
  Right me -> me
  Left _ -> unsafeCoerce f

foreignAsTouchOrMouse :: Foreign -> Either MouseEvent TouchEvent
foreignAsTouchOrMouse f = case runExcept (unsafeReadTagged "TouchEvent" f) of
  Right te -> Right te
  Left _ -> Left (foreignAsMouseEvent f)

-- | TS `event.sourceEvent.type === 'touchmove' && event.sourceEvent.touches.length > 1`.
-- | Implemented in JS because PS's `TouchEvent` binding doesn't expose
-- | `touches.length` portably.
foreign import isMultiTouchSourceEvent :: Foreign -> Effect Boolean

-- | `event.button === 0` for left-click. Returns `true` when the button bit
-- | is unset (matches the TS `!event.button` truthy-check).
foreign import mouseButtonIsZero :: MouseEvent -> Effect Boolean

-- | `event.target as Element`.
foreign import mouseEventTarget :: MouseEvent -> Effect Element

-- TS `Math.round` rounds half-away-from-zero; PS's `round` rounds to even.
-- The pure equivalent lives in `System.Utils.General.roundHalfAwayFromZero`
-- and is imported above.

-- | Construct the controller. Allocates a single `Ref DragState` and
-- | returns the `update`/`destroy` interface. Subsequent `update` calls
-- | re-bind the d3 drag behavior on a (possibly new) DOM node. Each d3
-- | callback enters the StateT interior via `runOnRef stateRef`.
createXYDrag
  :: forall nodeData edgeData
   . XYDragParams nodeData edgeData
  -> Effect XYDragInstance
createXYDrag params = do
  stateRef <- Ref.new initialDragState

  let
    destroy :: Effect Unit
    destroy = do
      s <- Ref.read stateRef
      for_ s.d3Selection \sel -> d3SelectionOnNull sel ".drag"

    update :: DragUpdateParams -> Effect Unit
    update upd = do
      sel <- d3Select upd.domNode
      Ref.modify_ (_ { d3Selection = Just sel }) stateRef
      behavior <- dragBehavior
      _ <- setDragClickDistance upd.nodeClickDistance behavior
      _ <- setDragOn "start" (\ev -> runOnRef stateRef (onStart params upd ev)) behavior
      _ <- setDragOn "drag" (\ev -> runOnRef stateRef (onDragHandler params stateRef upd ev)) behavior
      _ <- setDragOn "end" (\ev -> runOnRef stateRef (onEnd params upd ev)) behavior
      _ <- setDragFilter (filterPredicate upd) behavior
      applyDrag sel behavior

  pure { update, destroy }

-- ----------------------------------------------------------------------------
-- Lifecycle handlers
-- ----------------------------------------------------------------------------

onStart
  :: forall n e
   . XYDragParams n e
  -> DragUpdateParams
  -> D3DragEvent
  -> StateT DragState Effect Unit
onStart params upd ev = do
  store <- liftEffect params.getStoreItems
  src <- liftEffect (dragSourceEvent ev)
  bounds <- liftEffect $ case store.domNode of
    Just el -> Just <$> elementBoundingRect el
    Nothing -> pure Nothing
  modify_ _
    { containerBounds = bounds
    , abortDrag = false
    , nodePositionsChanged = false
    , dragEvent = Just (foreignAsMouseEvent src)
    }
  when (store.nodeDragThreshold == 0.0) (startDrag params upd ev)
  pp <- liftEffect $ getPointerPosition (foreignAsTouchOrMouse src)
    { transform: store.transform
    , snapGrid: store.snapGrid
    , snapToGrid: store.snapToGrid
    , containerBounds: bounds
    }
  mp <- liftEffect $ getEventPosition (foreignAsTouchOrMouse src) bounds
  modify_ _
    { lastPos = { x: Just pp.x, y: Just pp.y }
    , mousePosition = mp
    }

onDragHandler
  :: forall n e
   . XYDragParams n e
  -> Ref DragState
  -> DragUpdateParams
  -> D3DragEvent
  -> StateT DragState Effect Unit
onDragHandler params stateRef upd ev = do
  store <- liftEffect params.getStoreItems
  src <- liftEffect (dragSourceEvent ev)
  s0 <- get
  pp <- liftEffect $ getPointerPosition (foreignAsTouchOrMouse src)
    { transform: store.transform
    , snapGrid: store.snapGrid
    , snapToGrid: store.snapToGrid
    , containerBounds: s0.containerBounds
    }
  modify_ _ { dragEvent = Just (foreignAsMouseEvent src) }

  multi <- liftEffect (isMultiTouchSourceEvent src)
  let
    deletedDuringDrag = case upd.nodeId of
      Just nid -> isNothing (Map.lookup nid store.nodeLookup)
      Nothing -> false
  when (multi || deletedDuringDrag) (modify_ _ { abortDrag = true })

  s1 <- get
  when (not s1.abortDrag) do
    when (not s1.autoPanStarted && store.autoPanOnNodeDrag && s1.dragStarted) do
      modify_ _ { autoPanStarted = true }
      autoPanStep params stateRef

    when (not s1.dragStarted) do
      curMP <- liftEffect $ getEventPosition (foreignAsTouchOrMouse src) s1.containerBounds
      let
        dx = curMP.x - s1.mousePosition.x
        dy = curMP.y - s1.mousePosition.y
        dist = sqrt (dx * dx + dy * dy)
      when (dist > store.nodeDragThreshold) (startDrag params upd ev)

    s2 <- get
    let moved = s2.lastPos.x /= Just pp.xSnapped || s2.lastPos.y /= Just pp.ySnapped
    when (moved && Map.size s2.dragItems > 0 && s2.dragStarted) do
      mp <- liftEffect $ getEventPosition (foreignAsTouchOrMouse src) s2.containerBounds
      modify_ _ { mousePosition = mp }
      updateNodes params (Just upd) { x: pp.x, y: pp.y }

onEnd
  :: forall n e
   . XYDragParams n e
  -> DragUpdateParams
  -> D3DragEvent
  -> StateT DragState Effect Unit
onEnd params upd ev = do
  src <- liftEffect (dragSourceEvent ev)
  s0 <- get
  unless (not s0.dragStarted || s0.abortDrag) do
    liftEffect (for_ s0.autoPanId cancelAnimationFrame)
    modify_ _
      { autoPanStarted = false
      , dragStarted = false
      , autoPanId = Nothing
      }
    when (Map.size s0.dragItems > 0) do
      store <- liftEffect params.getStoreItems
      when s0.nodePositionsChanged do
        liftEffect (store.updateNodePositions s0.dragItems false)
        modify_ _ { nodePositionsChanged = false }
      let
        mouseEv = foreignAsMouseEvent src
        eventArgs = getEventHandlerParams upd.nodeId s0.dragItems
          store.nodeLookup
          false
      liftEffect do
        for_ eventArgs.currentNode \cn -> do
          for_ params.onDragStop \cb ->
            cb mouseEv s0.dragItems cn eventArgs.allNodes
          for_ store.onNodeDragStop \cb ->
            cb mouseEv cn eventArgs.allNodes
        when (isNothing upd.nodeId) do
          for_ store.onSelectionDragStop \cb ->
            cb mouseEv eventArgs.allNodes

-- | The `.filter` predicate gating drag start. Mirrors TS:
-- |   `!event.button && (no noDragClassName || !target.matches('.X'))
-- |                  && (no handleSelector || target.matches(sel))`.
filterPredicate
  :: DragUpdateParams
  -> D3DragEvent
  -> Effect Boolean
filterPredicate upd ev = do
  src <- dragSourceEvent ev
  let me = foreignAsMouseEvent src
  btnZero <- mouseButtonIsZero me
  notNoDrag <- case upd.noDragClassName of
    Nothing -> pure true
    Just cls -> do
      target <- mouseEventTarget me
      matches <- hasSelector target ("." <> cls) upd.domNode
      pure (not matches)
  matchesHandle <- case upd.handleSelector of
    Nothing -> pure true
    Just sel -> do
      target <- mouseEventTarget me
      hasSelector target sel upd.domNode
  pure (btnZero && notNoDrag && matchesHandle)

-- ----------------------------------------------------------------------------
-- startDrag, autoPan, updateNodes — shared implementation.
-- ----------------------------------------------------------------------------

startDrag
  :: forall n e
   . XYDragParams n e
  -> DragUpdateParams
  -> D3DragEvent
  -> StateT DragState Effect Unit
startDrag params upd ev = do
  store <- liftEffect params.getStoreItems
  src <- liftEffect (dragSourceEvent ev)
  modify_ _ { dragStarted = true }

  let
    deselectFirst =
      (not store.selectNodesOnDrag || not upd.isSelectable)
        && not store.multiSelectionActive
  liftEffect $ case upd.nodeId of
    Just nid | deselectFirst -> do
      let alreadySelected = case Map.lookup nid store.nodeLookup of
            Just n -> n.selected
            Nothing -> false
      when (not alreadySelected) store.unselectNodesAndEdges
    _ -> pure unit

  liftEffect $ case upd.nodeId of
    Just nid | upd.isSelectable && store.selectNodesOnDrag ->
      for_ params.onNodeMouseDown \cb -> cb nid
    _ -> pure unit

  s <- get
  pp <- liftEffect $ getPointerPosition (foreignAsTouchOrMouse src)
    { transform: store.transform
    , snapGrid: store.snapGrid
    , snapToGrid: store.snapToGrid
    , containerBounds: s.containerBounds
    }

  let
    items = getDragItems store.nodeLookup store.nodesDraggable
      { x: pp.x, y: pp.y } upd.nodeId
  modify_ _
    { lastPos = { x: Just pp.x, y: Just pp.y }
    , dragItems = items
    }

  when (Map.size items > 0) do
    let
      eventArgs = getEventHandlerParams upd.nodeId items store.nodeLookup true
      mouseEv = foreignAsMouseEvent src
    liftEffect do
      for_ eventArgs.currentNode \cn -> do
        for_ params.onDragStart \cb ->
          cb mouseEv items cn eventArgs.allNodes
        for_ store.onNodeDragStart \cb ->
          cb mouseEv cn eventArgs.allNodes
      when (isNothing upd.nodeId) do
        for_ store.onSelectionDragStart \cb ->
          cb mouseEv eventArgs.allNodes

-- | Recursive auto-pan loop. `autoPanStep` runs inside the StateT and
-- | re-schedules itself via `autoPanLoop`, which re-enters the StateT
-- | at each rAF tick. The launched `panBy` aff callback also re-enters
-- | via `runOnRef` once `panBy` resolves.
autoPanLoop
  :: forall n e
   . XYDragParams n e
  -> Ref DragState
  -> Effect Unit
autoPanLoop params stateRef = runOnRef stateRef (autoPanStep params stateRef)

autoPanStep
  :: forall n e
   . XYDragParams n e
  -> Ref DragState
  -> StateT DragState Effect Unit
autoPanStep params stateRef = do
  s <- get
  case s.containerBounds of
    Nothing -> pure unit
    Just b -> do
      store <- liftEffect params.getStoreItems
      if not store.autoPanOnNodeDrag then do
        liftEffect (for_ s.autoPanId cancelAnimationFrame)
        modify_ _ { autoPanStarted = false, autoPanId = Nothing }
      else do
        let
          speed = fromMaybe 15.0 store.autoPanSpeed
          mv = calcAutoPan s.mousePosition
            { width: b.width, height: b.height }
            speed
            40.0
          Transform t = store.transform
        when (mv.x /= 0.0 || mv.y /= 0.0) do
          let
            newLp =
              { x: Just ((fromMaybe 0.0 s.lastPos.x) - mv.x / t.scale)
              , y: Just ((fromMaybe 0.0 s.lastPos.y) - mv.y / t.scale)
              }
          modify_ _ { lastPos = newLp }
          liftEffect $ launchAff_ do
            ok <- store.panBy { x: mv.x, y: mv.y }
            liftEffect $ when ok $ runOnRef stateRef do
              s2 <- get
              case xyOf s2.lastPos of
                Just xy -> updateNodes params Nothing xy
                Nothing -> pure unit
        handle <- liftEffect $ requestAnimationFrame (autoPanLoop params stateRef)
        modify_ _ { autoPanId = Just handle }
  where
  xyOf r = case r.x, r.y of
    Just x, Just y -> Just { x, y }
    _, _ -> Nothing

updateNodes
  :: forall n e
   . XYDragParams n e
  -> Maybe DragUpdateParams
  -> XYPosition
  -> StateT DragState Effect Unit
updateNodes params mUpd pos = do
  store <- liftEffect params.getStoreItems
  modify_ _ { lastPos = { x: Just pos.x, y: Just pos.y } }

  s <- get
  let
    items = s.dragItems
    isMultiDrag = Map.size items > 1
    multiSnap =
      if isMultiDrag && store.snapToGrid then
        calculateSnapOffset items store.snapGrid pos.x pos.y
      else Nothing

    entries :: Array (Tuple NodeId NodeDragItem)
    entries = Map.toUnfoldable items

    -- One iteration: compute next position via `calculateNodePosition` and
    -- thread a Boolean accumulator that records whether anything moved.
    step :: Boolean -> Tuple NodeId NodeDragItem -> StateT DragState Effect Boolean
    step acc (Tuple id dragItem) = case Map.lookup id store.nodeLookup of
      Nothing -> pure acc
      Just _ -> do
        let
          stepNext = case multiSnap of
            Just off ->
              { x: roundHalfAwayFromZero ((pos.x - dragItem.distance.x) + off.x)
              , y: roundHalfAwayFromZero ((pos.y - dragItem.distance.y) + off.y)
              }
            Nothing ->
              if store.snapToGrid then
                snapPosition
                  { x: pos.x - dragItem.distance.x
                  , y: pos.y - dragItem.distance.y
                  }
                  store.snapGrid
              else
                { x: pos.x - dragItem.distance.x
                , y: pos.y - dragItem.distance.y
                }
        case calculateNodePosition
          { nodeId: id
          , nextPosition: stepNext
          , nodeLookup: store.nodeLookup
          , nodeOrigin: store.nodeOrigin
          , nodeExtent: Just store.nodeExtent
          } of
          -- `Left _` is `NodeNotFound` (see System.Utils.Graph.NodeError):
          -- treat an absent node as "did not move", exactly as the previous
          -- `Nothing` branch did.
          Left _ -> pure acc
          Right r -> do
            -- Persist the computed coordinates back into the drag item (TS mutates
            -- `dragItem.position` / `dragItem.internals.positionAbsolute`); the
            -- live store dispatch below and the drag-end commit read from
            -- `dragItems`, so without this the node never actually moves.
            modify_ \st ->
              st
                { dragItems =
                    Map.insert id
                      ( dragItem
                          { position = r.position
                          , internals = dragItem.internals
                              { positionAbsolute = r.positionAbsolute }
                          }
                      )
                      st.dragItems
                }
            pure
              ( acc
                  || (r.position.x /= dragItem.position.x)
                  || (r.position.y /= dragItem.position.y)
              )

  hasChange <- foldM step false entries

  when hasChange do
    modify_ _ { nodePositionsChanged = true }
    s2 <- get
    liftEffect (store.updateNodePositions s2.dragItems true)
    liftEffect $ traverse_
      ( \ev -> do
          let
            nodeId = case mUpd of
              Just u -> u.nodeId
              Nothing -> Nothing
            eventArgs = getEventHandlerParams nodeId s2.dragItems store.nodeLookup true
          for_ eventArgs.currentNode \cn -> do
            for_ params.onDrag \cb -> cb ev s2.dragItems cn eventArgs.allNodes
            for_ store.onNodeDrag \cb -> cb ev cn eventArgs.allNodes
          when (isNothing nodeId) do
            for_ store.onSelectionDrag \cb -> cb ev eventArgs.allNodes
      )
      s2.dragEvent
