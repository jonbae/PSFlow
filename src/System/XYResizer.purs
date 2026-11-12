-- | Node-resize controller, preserving XYResizer.ts's update and gesture scopes.
module System.XYResizer (module Types, createXYResizer) where

import Prelude hiding (min, max)

import Data.Either (Either(..))
import Data.Array as Array
import Data.Foldable (for_)
import Data.Function.Uncurried (Fn2, runFn2)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Number as Number
import Effect (Effect)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Effect.Uncurried (EffectFn3, runEffectFn3)
import Foreign (Foreign)
import Record as Record
import Type.Proxy (Proxy(..))
import System.FFI.D3Drag (D3DragEvent, applyDrag, dragBehavior, dragSourceEvent, setDragOn)
import System.FFI.D3Selection (d3Select, d3SelectionOnNull)
import System.Types.Geometry (CoordinateExtent(..), NodeOrigin(..), mkSnapGrid)
import System.Types.Ids (parentToNode)
import System.Types.Node (InternalNodeBase, NodeExtent(..))
import System.Utils.Dom (DOMRect, PointerPosition, elementBoundingRect, getPointerPosition)
import System.Utils.Number (min, max)
import System.XYResizer.Types (ControlLinePosition(..), ControlPosition(..), CornerPosition(..), OnResize, OnResizeEnd, OnResizeStart, RequiredXYResizerChange, ResizeBoundaries, ResizeControlDirection(..), ResizeControlVariant(..), ResizeDragEvent(..), ResizeParams, ResizeParamsWithDirection, ResizerStoreItems, ShouldResize, XYResizerChange, XYResizerChildChange, XYResizerInstance, XYResizerParams, XYResizerUpdateParams, xyResizerHandlePositions, xyResizerLinePositions) as Types
import System.XYResizer.Types (ResizeParams, ResizeParamsWithDirection, ResizeDragEvent(..), ResizeControlDirection(..), ResizerStoreItems, XYResizerChildChange, XYResizerInstance, XYResizerParams, XYResizerUpdateParams)
import System.XYResizer.Utils (ControlDirection, ResizeStartValues, getControlDirection, getDimensionsAfterResize, getResizeDirection)
import Unsafe.Coerce (unsafeCoerce)

-- Native property operations only. All resize decisions and state reads live here.
foreign import hasProperty :: Fn2 String Foreign Boolean
foreign import writeProperty :: forall a b. EffectFn3 String a b Unit

initPrevValues :: ResizeParams
initPrevValues = { width: 0.0, height: 0.0, x: 0.0, y: 0.0 }

initStartValues :: ResizeStartValues
initStartValues = { width: 0.0, height: 0.0, x: 0.0, y: 0.0, pointerX: 0.0, pointerY: 0.0, aspectRatio: 1.0 }

type ResizerState n =
  { prevValues :: Ref ResizeParams
  , startValues :: Ref ResizeStartValues
  , node :: Ref (Maybe (InternalNodeBase n))
  , containerBounds :: Ref (Maybe DOMRect)
  , childNodes :: Ref (Array XYResizerChildChange)
  , parentNode :: Ref (Maybe (InternalNodeBase n))
  , nodeExtent :: Ref (Maybe CoordinateExtent)
  , childExtent :: Ref (Maybe CoordinateExtent)
  , resizeDetected :: Ref Boolean
  }

type ResizeOptions =
  { controlDirection :: ControlDirection
  , boundaries :: Types.ResizeBoundaries
  , resizeDirection :: Maybe ResizeControlDirection
  , keepAspectRatio :: Boolean
  }

newGestureState :: forall n. Effect (ResizerState n)
newGestureState = do
  prevValues <- Ref.new initPrevValues
  startValues <- Ref.new initStartValues
  node <- Ref.new Nothing
  containerBounds <- Ref.new Nothing
  childNodes <- Ref.new []
  parentNode <- Ref.new Nothing
  nodeExtent <- Ref.new Nothing
  childExtent <- Ref.new Nothing
  resizeDetected <- Ref.new false
  pure { prevValues, startValues, node, containerBounds, childNodes, parentNode, nodeExtent, childExtent, resizeDetected }

pointerPosition :: forall n. D3DragEvent -> ResizerStoreItems n -> Maybe DOMRect -> Effect PointerPosition
pointerPosition event store containerBounds = do
  source <- dragSourceEvent event
  getPointerPosition
    (if runFn2 hasProperty "clientX" source then Left (unsafeCoerce source) else Right (unsafeCoerce source))
    { transform: store.transform
    , snapGrid: fromMaybe (mkSnapGrid 0.0 0.0) store.snapGrid
    , snapToGrid: store.snapToGrid
    , containerBounds
    }

createXYResizer :: forall n. XYResizerParams n -> Effect XYResizerInstance
createXYResizer params = do
  selection <- d3Select params.domNode
  -- Geometry options are factory-scoped; d3's active gesture retains the
  -- callbacks and state from its update, but observes later geometry options.
  options <- Ref.new (Nothing :: Maybe ResizeOptions)
  let
    update upd = do
      state <- newGestureState
      Ref.write (Just
        { controlDirection: getControlDirection upd.controlPosition
        , boundaries: upd.boundaries, keepAspectRatio: upd.keepAspectRatio
        , resizeDirection: upd.resizeDirection
        }) options
      behavior <- dragBehavior
      _ <- setDragOn "start" (onStart params state upd) behavior
      _ <- setDragOn "drag" (onDrag params state options upd) behavior
      _ <- setDragOn "end" (onEnd params state upd) behavior
      applyDrag selection behavior
  pure { update, destroy: d3SelectionOnNull selection ".drag" }

onStart :: forall n. XYResizerParams n -> ResizerState n -> XYResizerUpdateParams -> D3DragEvent -> Effect Unit
onStart params state upd event = do
  store <- params.getStoreItems
  let found = Map.lookup params.nodeId store.nodeLookup
  Ref.write found state.node
  for_ found \node -> do
    bounds <- case store.paneDomNode of
      Nothing -> pure Nothing
      Just pane -> Just <$> elementBoundingRect pane
    Ref.write bounds state.containerBounds
    pointer <- pointerPosition event store bounds
    let previous =
          { width: fromMaybe 0.0 node.measured.width, height: fromMaybe 0.0 node.measured.height
          , x: node.position.x, y: node.position.y
          }
    Ref.write previous state.prevValues
    Ref.write
      { width: previous.width, height: previous.height, x: previous.x, y: previous.y
      , pointerX: pointer.xSnapped, pointerY: pointer.ySnapped
      , aspectRatio: previous.width / previous.height
      } state.startValues
    let
      parent = case node.parentId of
        Just pid | node.extent == Just ParentExtent || node.expandParent == Just true -> Map.lookup (parentToNode pid) store.nodeLookup
        _ -> Nothing
      extent = case node.extent, parent of
        Just ParentExtent, Just p -> Just $ CoordinateExtent
          { minX: 0.0, minY: 0.0, maxX: fromMaybe Number.nan p.measured.width, maxY: fromMaybe Number.nan p.measured.height }
        Just (CoordExtent e), _ -> Just e
        _, _ -> Nothing
    Ref.write parent state.parentNode
    Ref.write extent state.nodeExtent
    Ref.write [] state.childNodes
    Ref.write Nothing state.childExtent
    for_ store.nodeOrder \childId -> for_ (Map.lookup childId store.nodeLookup) \child ->
      when (map parentToNode child.parentId == Just params.nodeId) do
        Ref.modify_ (_ <> [ { id: childId, position: { x: child.position.x, y: child.position.y }, extent: child.extent } ]) state.childNodes
        when (child.extent == Just ParentExtent || child.expandParent == Just true) do
          let
            NodeOrigin childOrigin = fromMaybe store.nodeOrigin child.origin
            width = fromMaybe 0.0 child.measured.width
            height = fromMaybe 0.0 child.measured.height
            x = node.position.x + child.position.x
            y = node.position.y + child.position.y
            childBounds =
              { minX: x - childOrigin.ox * width, minY: y - childOrigin.oy * height
              , maxX: x + width - childOrigin.ox * width, maxY: y + height - childOrigin.oy * height
              }
          Ref.modify_ (Just <<< CoordinateExtent <<< case _ of
            Nothing -> childBounds
            Just (CoordinateExtent old) ->
              { minX: min childBounds.minX old.minX, minY: min childBounds.minY old.minY
              , maxX: max childBounds.maxX old.maxX, maxY: max childBounds.maxY old.maxY
              }) state.childExtent
    for_ upd.onResizeStart \callback -> callback (ResizeDragEvent (unsafeCoerce event)) previous

onDrag :: forall n. XYResizerParams n -> ResizerState n -> Ref (Maybe ResizeOptions) -> XYResizerUpdateParams -> D3DragEvent -> Effect Unit
onDrag params state options upd event = do
  store <- params.getStoreItems
  bounds <- Ref.read state.containerBounds
  pointer <- pointerPosition event store bounds
  nodeMaybe <- Ref.read state.node
  optionsMaybe <- Ref.read options
  case nodeMaybe, optionsMaybe of
    Just node, Just opts -> do
      previous <- Ref.read state.prevValues
      start <- Ref.read state.startValues
      extent <- Ref.read state.nodeExtent
      childExtent <- Ref.read state.childExtent
      let
        origin@(NodeOrigin o) = fromMaybe store.nodeOrigin node.origin
        next = getDimensionsAfterResize start opts.controlDirection pointer opts.boundaries opts.keepAspectRatio origin extent childExtent
        widthChanged = next.width /= previous.width
        heightChanged = next.height /= previous.height
        xChanged = next.x /= previous.x && widthChanged
        yChanged = next.y /= previous.y && heightChanged
      when (xChanged || yChanged || widthChanged || heightChanged) do
        let
          positionChanged = xChanged || yChanged || o.ox == 1.0 || o.oy == 1.0
          dimensionsChanged = widthChanged || heightChanged
          change =
            { x: if positionChanged then Just (if xChanged then next.x else previous.x) else Nothing
            , y: if positionChanged then Just (if yChanged then next.y else previous.y) else Nothing
            , width: if dimensionsChanged then Just (if widthChanged && opts.resizeDirection /= Just Vertical then next.width else previous.width) else Nothing
            , height: if dimensionsChanged then Just (if heightChanged && opts.resizeDirection /= Just Horizontal then next.height else previous.height) else Nothing
            }
          updated =
            { x: fromMaybe previous.x change.x, y: fromMaybe previous.y change.y
            , width: fromMaybe previous.width change.width, height: fromMaybe previous.height change.height
            }
        Ref.write updated state.prevValues
        children <- Ref.read state.childNodes
        let childChanges = if positionChanged then children else []
        for_ childChanges \child -> runEffectFn3 writeProperty "position" child
          { x: child.position.x - (next.x - previous.x) + o.ox * (next.width - previous.width)
          , y: child.position.y - (next.y - previous.y) + o.oy * (next.height - previous.height)
          }
        parent <- Ref.read state.parentNode
        for_ parent \_ -> when (node.expandParent == Just true) do
          let xLimit = o.ox * fromMaybe 0.0 change.width
          case change.x of
            Just x | x /= 0.0 && x < xLimit -> do
              Ref.modify_ (_ { x = xLimit }) state.prevValues
              Ref.modify_ (\s -> s { x = s.x - (x - xLimit) }) state.startValues
            _ -> pure unit
          let yLimit = o.oy * fromMaybe 0.0 change.height
          case change.y of
            Just y | y /= 0.0 && y < yLimit -> do
              Ref.modify_ (_ { y = yLimit }) state.prevValues
              Ref.modify_ (\s -> s { y = s.y - (y - yLimit) }) state.startValues
            _ -> pure unit
        corrected <- Ref.read state.prevValues
        let
          direction = getResizeDirection
            { width: corrected.width, prevWidth: previous.width, height: corrected.height, prevHeight: previous.height
            , affectsX: opts.controlDirection.affectsX, affectsY: opts.controlDirection.affectsY
            }
          nextValues :: ResizeParamsWithDirection
          nextValues = Record.insert (Proxy :: Proxy "direction") direction corrected
        allowed <- case upd.shouldResize of
          Nothing -> pure true
          Just callback -> callback (ResizeDragEvent (unsafeCoerce event)) nextValues
        when allowed do
          Ref.write true state.resizeDetected
          for_ upd.onResize \callback -> callback (ResizeDragEvent (unsafeCoerce event)) nextValues
          -- Source creates a fresh changes array, retaining its owned child
          -- records across drag events (their positions are mutated above).
          params.onChange change (Array.slice 0 (Array.length childChanges) childChanges)
    _, _ -> pure unit

onEnd :: forall n. XYResizerParams n -> ResizerState n -> XYResizerUpdateParams -> D3DragEvent -> Effect Unit
onEnd params state upd event = do
  detected <- Ref.read state.resizeDetected
  when detected do
    previous <- Ref.read state.prevValues
    for_ upd.onResizeEnd \callback -> callback (ResizeDragEvent (unsafeCoerce event)) previous
    for_ params.onEnd \callback -> callback previous
    Ref.write false state.resizeDetected
