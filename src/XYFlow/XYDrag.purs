-- | Node drag controller — port of
-- | `xyflow-main/packages/system/src/xydrag/XYDrag.ts`.
-- |
-- | The TS `XYDrag` is a factory that captures mutable state (`lastPos`,
-- | `dragItems`, `autoPanId`, …) in a closure and returns an object with
-- | `update`/`destroy` methods. The PS port uses `Ref` for that state and
-- | returns the controller in `Effect`. d3-drag wiring goes through
-- | `XYFlow.FFI.D3Drag`.
-- |
-- | Type-parameter divergence from TS: the TS source has a single
-- | `<OnNodeDrag>` parameter that abstracts the user callback shape.
-- | `NodeBase`/`EdgeBase` are referenced unparameterized (effectively `<any>`).
-- | The PS equivalents are parameterized (`NodeBase nodeData`,
-- | `EdgeBase edgeData`), so the port threads two parameters through the
-- | store and the params record.
module XYFlow.XYDrag
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

import Data.Either (Either)
import Data.Foldable (foldM, for_, traverse_)
import Data.Map (Map)
import Data.Map (empty, lookup, size, toUnfoldable) as Map
import Data.Maybe (Maybe(..), fromMaybe, isNothing)
import Data.Number (sqrt)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Foreign (Foreign)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Element (Element)
import Web.TouchEvent.TouchEvent (TouchEvent)
import Web.UIEvent.MouseEvent (MouseEvent)
import XYFlow.FFI.AnimationFrame
  ( RafHandle
  , cancelAnimationFrame
  , requestAnimationFrame
  )
import XYFlow.FFI.D3Drag
  ( D3DragEvent
  , applyDrag
  , dragBehavior
  , dragSourceEvent
  , setDragClickDistance
  , setDragFilter
  , setDragOn
  )
import XYFlow.FFI.D3Selection
  ( D3Selection
  , d3Select
  , d3SelectionOnNull
  )
import XYFlow.Types.Edge (EdgeBase)
import XYFlow.Types.Geometry
  ( CoordinateExtent
  , NodeOrigin
  , SnapGrid
  , Transform(..)
  , XYPosition
  )
import XYFlow.Types.Node
  ( NodeBase
  , NodeDragItem
  , NodeLookup
  , OnError
  )
import XYFlow.Utils.Dom
  ( DOMRect
  , elementBoundingRect
  , getEventPosition
  , getPointerPosition
  )
import XYFlow.Utils.General (calcAutoPan, snapPosition)
import XYFlow.Utils.Graph (calculateNodePosition)
import XYFlow.XYDrag.Utils
  ( calculateSnapOffset
  , getDragItems
  , getEventHandlerParams
  , hasSelector
  )

-- | TS `(event, dragItems, node, nodes) => void`.
type OnDrag nodeData =
  MouseEvent
  -> Map String NodeDragItem
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
type UpdateNodePositions = Map String NodeDragItem -> Boolean -> Effect Unit

-- | Per-node-element configuration applied via `XYDragInstance.update`.
type DragUpdateParams =
  { noDragClassName :: Maybe String
  , handleSelector :: Maybe String
  , isSelectable :: Boolean
  , nodeId :: Maybe String
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
  , onError :: Maybe OnError
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
  , onNodeMouseDown :: Maybe (String -> Effect Unit)
  , autoPanSpeed :: Maybe Number
  }

type XYDragInstance =
  { update :: DragUpdateParams -> Effect Unit
  , destroy :: Effect Unit
  }

-- | Mutable closure state. Each field is a `Ref` so that nested handlers
-- | (start, drag, end, autoPan) share the same cell — exactly the TS pattern.
type DragState =
  { lastPos :: Ref { x :: Maybe Number, y :: Maybe Number }
  , autoPanId :: Ref (Maybe RafHandle)
  , dragItems :: Ref (Map String NodeDragItem)
  , autoPanStarted :: Ref Boolean
  , mousePosition :: Ref XYPosition
  , containerBounds :: Ref (Maybe DOMRect)
  , dragStarted :: Ref Boolean
  , d3Selection :: Ref (Maybe D3Selection)
  , abortDrag :: Ref Boolean
  , nodePositionsChanged :: Ref Boolean
  , dragEvent :: Ref (Maybe MouseEvent)
  }

defaultDragState :: Effect DragState
defaultDragState = do
  lastPos <- Ref.new { x: Nothing, y: Nothing }
  autoPanId <- Ref.new Nothing
  dragItems <- Ref.new (Map.empty :: Map String NodeDragItem)
  autoPanStarted <- Ref.new false
  mousePosition <- Ref.new { x: 0.0, y: 0.0 }
  containerBounds <- Ref.new Nothing
  dragStarted <- Ref.new false
  d3Selection <- Ref.new Nothing
  abortDrag <- Ref.new false
  nodePositionsChanged <- Ref.new false
  dragEvent <- Ref.new Nothing
  pure
    { lastPos
    , autoPanId
    , dragItems
    , autoPanStarted
    , mousePosition
    , containerBounds
    , dragStarted
    , d3Selection
    , abortDrag
    , nodePositionsChanged
    , dragEvent
    }

-- | The d3 source event is `Foreign`. The TS source narrows with
-- | `as MouseEvent`; PS does the same via `unsafeCoerce` at the boundary.
foreignAsMouseEvent :: Foreign -> MouseEvent
foreignAsMouseEvent = unsafeCoerce

foreignAsTouchOrMouse :: Foreign -> Either MouseEvent TouchEvent
foreignAsTouchOrMouse = unsafeCoerce

-- | TS `event.sourceEvent.type === 'touchmove' && event.sourceEvent.touches.length > 1`.
-- | Implemented in JS because PS's `TouchEvent` binding doesn't expose
-- | `touches.length` portably.
foreign import isMultiTouchSourceEvent :: Foreign -> Effect Boolean

-- | `event.button === 0` for left-click. Returns `true` when the button bit
-- | is unset (matches the TS `!event.button` truthy-check).
foreign import mouseButtonIsZero :: MouseEvent -> Effect Boolean

-- | `event.target as Element`.
foreign import mouseEventTarget :: MouseEvent -> Effect Element

-- | TS `Math.round` rounds half-away-from-zero; PS's `round` rounds to even.
-- | Used in `updateNodes` to mirror the TS exactly.
foreign import roundHalfAway :: Number -> Number

-- | Construct the controller. Allocates `Ref` cells for closure state and
-- | returns the `update`/`destroy` interface. Subsequent `update` calls
-- | re-bind the d3 drag behavior on a (possibly new) DOM node.
createXYDrag
  :: forall nodeData edgeData
   . XYDragParams nodeData edgeData
  -> Effect XYDragInstance
createXYDrag params = do
  state <- defaultDragState

  let
    destroy :: Effect Unit
    destroy = do
      mSel <- Ref.read state.d3Selection
      for_ mSel \sel -> d3SelectionOnNull sel ".drag"

    update :: DragUpdateParams -> Effect Unit
    update upd = do
      sel <- d3Select upd.domNode
      Ref.write (Just sel) state.d3Selection
      behavior <- dragBehavior
      _ <- setDragClickDistance upd.nodeClickDistance behavior
      _ <- setDragOn "start" (onStart params state upd) behavior
      _ <- setDragOn "drag" (onDragHandler params state upd) behavior
      _ <- setDragOn "end" (onEnd params state upd) behavior
      _ <- setDragFilter (filterPredicate upd) behavior
      applyDrag sel behavior

  pure { update, destroy }

-- ----------------------------------------------------------------------------
-- Lifecycle handlers
-- ----------------------------------------------------------------------------

onStart
  :: forall n e
   . XYDragParams n e
  -> DragState
  -> DragUpdateParams
  -> D3DragEvent
  -> Effect Unit
onStart params state upd ev = do
  store <- params.getStoreItems
  src <- dragSourceEvent ev
  bounds <- case store.domNode of
    Just el -> Just <$> elementBoundingRect el
    Nothing -> pure Nothing
  Ref.write bounds state.containerBounds
  Ref.write false state.abortDrag
  Ref.write false state.nodePositionsChanged
  Ref.write (Just (foreignAsMouseEvent src)) state.dragEvent
  when (store.nodeDragThreshold == 0.0) (startDrag params state upd ev)
  pp <- getPointerPosition (foreignAsTouchOrMouse src)
    { transform: store.transform
    , snapGrid: store.snapGrid
    , snapToGrid: store.snapToGrid
    , containerBounds: bounds
    }
  Ref.write { x: Just pp.x, y: Just pp.y } state.lastPos
  mp <- getEventPosition (foreignAsTouchOrMouse src) bounds
  Ref.write mp state.mousePosition

onDragHandler
  :: forall n e
   . XYDragParams n e
  -> DragState
  -> DragUpdateParams
  -> D3DragEvent
  -> Effect Unit
onDragHandler params state upd ev = do
  store <- params.getStoreItems
  src <- dragSourceEvent ev
  bounds <- Ref.read state.containerBounds
  pp <- getPointerPosition (foreignAsTouchOrMouse src)
    { transform: store.transform
    , snapGrid: store.snapGrid
    , snapToGrid: store.snapToGrid
    , containerBounds: bounds
    }
  Ref.write (Just (foreignAsMouseEvent src)) state.dragEvent

  multi <- isMultiTouchSourceEvent src
  let
    deletedDuringDrag = case upd.nodeId of
      Just nid -> isNothing (Map.lookup nid store.nodeLookup)
      Nothing -> false
  when (multi || deletedDuringDrag) (Ref.write true state.abortDrag)

  aborted <- Ref.read state.abortDrag
  when (not aborted) do
    panStarted <- Ref.read state.autoPanStarted
    started <- Ref.read state.dragStarted
    when (not panStarted && store.autoPanOnNodeDrag && started) do
      Ref.write true state.autoPanStarted
      autoPan params state

    when (not started) do
      curMP <- getEventPosition (foreignAsTouchOrMouse src) bounds
      origMP <- Ref.read state.mousePosition
      let
        dx = curMP.x - origMP.x
        dy = curMP.y - origMP.y
        dist = sqrt (dx * dx + dy * dy)
      when (dist > store.nodeDragThreshold) (startDrag params state upd ev)

    lp <- Ref.read state.lastPos
    items <- Ref.read state.dragItems
    started2 <- Ref.read state.dragStarted
    let moved = lp.x /= Just pp.xSnapped || lp.y /= Just pp.ySnapped
    when (moved && Map.size items > 0 && started2) do
      mp <- getEventPosition (foreignAsTouchOrMouse src) bounds
      Ref.write mp state.mousePosition
      updateNodes params state (Just upd) { x: pp.x, y: pp.y }

onEnd
  :: forall n e
   . XYDragParams n e
  -> DragState
  -> DragUpdateParams
  -> D3DragEvent
  -> Effect Unit
onEnd params state upd ev = do
  src <- dragSourceEvent ev
  started <- Ref.read state.dragStarted
  aborted <- Ref.read state.abortDrag
  unless (not started || aborted) do
    Ref.write false state.autoPanStarted
    Ref.write false state.dragStarted
    mPan <- Ref.read state.autoPanId
    for_ mPan cancelAnimationFrame
    Ref.write Nothing state.autoPanId
    items <- Ref.read state.dragItems
    when (Map.size items > 0) do
      store <- params.getStoreItems
      changed <- Ref.read state.nodePositionsChanged
      when changed do
        store.updateNodePositions items false
        Ref.write false state.nodePositionsChanged
      let
        mouseEv = foreignAsMouseEvent src
        eventArgs = getEventHandlerParams upd.nodeId items store.nodeLookup
          false
      for_ eventArgs.currentNode \cn -> do
        for_ params.onDragStop \cb ->
          cb mouseEv items cn eventArgs.allNodes
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
  -> DragState
  -> DragUpdateParams
  -> D3DragEvent
  -> Effect Unit
startDrag params state upd ev = do
  store <- params.getStoreItems
  src <- dragSourceEvent ev
  Ref.write true state.dragStarted

  let
    deselectFirst =
      (not store.selectNodesOnDrag || not upd.isSelectable)
        && not store.multiSelectionActive
  case upd.nodeId of
    Just nid | deselectFirst -> do
      let alreadySelected = case Map.lookup nid store.nodeLookup of
            Just n -> n.selected
            Nothing -> false
      when (not alreadySelected) store.unselectNodesAndEdges
    _ -> pure unit

  case upd.nodeId of
    Just nid | upd.isSelectable && store.selectNodesOnDrag ->
      for_ params.onNodeMouseDown \cb -> cb nid
    _ -> pure unit

  bounds <- Ref.read state.containerBounds
  pp <- getPointerPosition (foreignAsTouchOrMouse src)
    { transform: store.transform
    , snapGrid: store.snapGrid
    , snapToGrid: store.snapToGrid
    , containerBounds: bounds
    }
  Ref.write { x: Just pp.x, y: Just pp.y } state.lastPos

  let
    items = getDragItems store.nodeLookup store.nodesDraggable
      { x: pp.x, y: pp.y } upd.nodeId
  Ref.write items state.dragItems

  when (Map.size items > 0) do
    let
      eventArgs = getEventHandlerParams upd.nodeId items store.nodeLookup true
      mouseEv = foreignAsMouseEvent src
    for_ eventArgs.currentNode \cn -> do
      for_ params.onDragStart \cb ->
        cb mouseEv items cn eventArgs.allNodes
      for_ store.onNodeDragStart \cb ->
        cb mouseEv cn eventArgs.allNodes
    when (isNothing upd.nodeId) do
      for_ store.onSelectionDragStart \cb ->
        cb mouseEv eventArgs.allNodes

-- | Recursive auto-pan loop. Reads container bounds and mouse position from
-- | `Ref`s, computes pan velocity via `calcAutoPan`, fires the async
-- | `panBy` and re-schedules itself on the next animation frame.
autoPan
  :: forall n e
   . XYDragParams n e
  -> DragState
  -> Effect Unit
autoPan params state = do
  bounds <- Ref.read state.containerBounds
  case bounds of
    Nothing -> pure unit
    Just b -> do
      store <- params.getStoreItems
      if not store.autoPanOnNodeDrag then do
        Ref.write false state.autoPanStarted
        mId <- Ref.read state.autoPanId
        for_ mId cancelAnimationFrame
        Ref.write Nothing state.autoPanId
      else do
        mp <- Ref.read state.mousePosition
        let
          speed = fromMaybe 15.0 store.autoPanSpeed
          mv = calcAutoPan mp { width: b.width, height: b.height } speed 40.0
          Transform t = store.transform
        when (mv.x /= 0.0 || mv.y /= 0.0) do
          lp <- Ref.read state.lastPos
          let
            newLp =
              { x: Just ((fromMaybe 0.0 lp.x) - mv.x / t.scale)
              , y: Just ((fromMaybe 0.0 lp.y) - mv.y / t.scale)
              }
          Ref.write newLp state.lastPos
          launchAff_ do
            ok <- store.panBy { x: mv.x, y: mv.y }
            liftEffect $ when ok do
              lpCurrent <- Ref.read state.lastPos
              for_ (xyOf lpCurrent) \xy ->
                updateNodes params state Nothing xy
        handle <- requestAnimationFrame (autoPan params state)
        Ref.write (Just handle) state.autoPanId
  where
  xyOf r = case r.x, r.y of
    Just x, Just y -> Just { x, y }
    _, _ -> Nothing

updateNodes
  :: forall n e
   . XYDragParams n e
  -> DragState
  -> Maybe DragUpdateParams
  -> XYPosition
  -> Effect Unit
updateNodes params state mUpd pos = do
  store <- params.getStoreItems
  Ref.write { x: Just pos.x, y: Just pos.y } state.lastPos

  items <- Ref.read state.dragItems
  let
    isMultiDrag = Map.size items > 1
    multiSnap =
      if isMultiDrag && store.snapToGrid then
        calculateSnapOffset items store.snapGrid pos.x pos.y
      else Nothing

    entries :: Array (Tuple String NodeDragItem)
    entries = Map.toUnfoldable items

    -- One iteration: compute next position via `calculateNodePosition` and
    -- thread a Boolean accumulator that records whether anything moved.
    step acc (Tuple id dragItem) = case Map.lookup id store.nodeLookup of
      Nothing -> pure acc
      Just _ -> do
        let
          stepNext = case multiSnap of
            Just off ->
              { x: roundHalfAway ((pos.x - dragItem.distance.x) + off.x)
              , y: roundHalfAway ((pos.y - dragItem.distance.y) + off.y)
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
          , onError: store.onError
          } of
          Nothing -> pure acc
          Just r -> pure
            ( acc
                || (r.position.x /= dragItem.position.x)
                || (r.position.y /= dragItem.position.y)
            )

  hasChange <- foldM step false entries

  when hasChange do
    Ref.write true state.nodePositionsChanged
    store.updateNodePositions items true
    mEv <- Ref.read state.dragEvent
    traverse_
      ( \ev -> do
          let
            nodeId = case mUpd of
              Just u -> u.nodeId
              Nothing -> Nothing
            eventArgs = getEventHandlerParams nodeId items store.nodeLookup true
          for_ eventArgs.currentNode \cn -> do
            for_ params.onDrag \cb -> cb ev items cn eventArgs.allNodes
            for_ store.onNodeDrag \cb -> cb ev cn eventArgs.allNodes
          when (isNothing nodeId) do
            for_ store.onSelectionDrag \cb -> cb ev eventArgs.allNodes
      )
      mEv
