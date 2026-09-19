-- | The auto-pan loop in `System.XYDrag`, one frame at a time.
-- |
-- | The local proxy for "Serialize the auto-pan loop the way upstream does,
-- | without breaking the drag" (#97). Upstream's `autoPan` asks for its next
-- | frame only after `await panBy(...)`, so one pan is in flight at most and
-- | the nodes move by the distance panned before the next frame begins. Three
-- | ports of that each broke it differently, and each fails a check here:
-- |
-- |   * asking for the next frame beside the pan rather than after it, which
-- |     `master` did — "asks for no frame while its pan is in flight";
-- |   * asking after the pan, but on the same stack as the `runOnRef` that
-- |     started it — "moves the node by the distance panned" and "leaves
-- |     `onEnd` the frame it asked for", because the continuation reads the
-- |     state from before the frame and its writes are then discarded;
-- |   * hoisting the next-frame request into a `where` clause, which builds
-- |     the loop eagerly and overflows the stack — every check, since
-- |     building the first frame never returns.
-- |
-- | The last two checks are the proxy for "Give auto-pan frames the grabbed
-- | node's id, so a single-node drag stops firing onSelectionDrag" (#100).
-- | TS reads `nodeId` from the scope `autoPan` was defined in; ps-flow passed
-- | `Nothing` and so reported every frame against the head of the drag items,
-- | as a selection drag.
-- |
-- | The net measures reproducibility and needs a browser and the vendored
-- | upstream. This runs in `spago test`, against a frame clock that counts
-- | requests and runs none of them.
module Test.System.XYDrag
  ( runXYDragTests
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_, makeAff, nonCanceler)
import Effect.Aff.AVar as AVar
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Ref (Ref)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import System.Constants (infiniteExtent)
import System.FFI.AnimationFrame (cancelAnimationFrame)
import System.FFI.Timer (setTimeout)
import System.Types.Geometry (NodeOrigin(..), Transform(..), XYPosition, mkSnapGrid)
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeBase, NodeDragItem, NodeLookup)
import System.XYDrag (DragState, PanBy, XYDragParams, autoPanLoop, initialDragState)
import System.XYDrag.Utils (getDragItems)
import Web.UIEvent.MouseEvent (MouseEvent)

type FrameClock =
  { requests :: Effect Int
  , cancelled :: Effect (Array Int)
  , restore :: Effect Unit
  }

foreign import installFrameClock :: Effect FrameClock

-- | Stands in for the `MouseEvent` the drag handler stores on the state. The
-- | drag callbacks only fire when `dragEvent` is a `Just`, and they pass it
-- | straight through, so nothing reads it.
foreign import stubMouseEvent :: MouseEvent

assert :: String -> Boolean -> Aff Unit
assert label cond = liftEffect $
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | Resume once every microtask queued so far has run.
settle :: Aff Unit
settle = makeAff \resume -> do
  _ <- setTimeout (resume (Right unit)) 0
  pure nonCanceler

-- | The dragged node, at (100, 100) and 50 × 25.
nodeId :: NodeId
nodeId = NodeId "n"

draggedNode :: InternalNodeBase Unit
draggedNode =
  { id: nodeId
  , position: { x: 100.0, y: 100.0 }
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: false
  , selected: true
  , dragging: false
  , draggable: Just true
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Just 50.0
  , height: Just 25.0
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: false
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Just 50.0, height: Just 25.0 }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  , internals:
      { positionAbsolute: { x: 100.0, y: 100.0 }
      , z: 0.0
      , rootParentIndex: Nothing
      , handleBounds: Nothing
      , bounds: Nothing
      }
  }

lookup :: NodeLookup Unit
lookup = Map.singleton nodeId draggedNode

-- | A second node dragged alongside the grabbed one. Its id sorts before
-- | `nodeId`, so it is the head of the drag items and therefore the node a
-- | frame reports when it carries no id of its own.
otherId :: NodeId
otherId = NodeId "a"

otherNode :: InternalNodeBase Unit
otherNode = draggedNode
  { id = otherId
  , position = { x: 300.0, y: 100.0 }
  , internals = draggedNode.internals
      { positionAbsolute = { x: 300.0, y: 100.0 } }
  }

multiLookup :: NodeLookup Unit
multiLookup = Map.insert otherId otherNode lookup

-- | Where the pointer grabbed the node, in flow coordinates. The viewport is
-- | the identity, so these are screen coordinates too.
grab :: XYPosition
grab = { x: 150.0, y: 120.0 }

-- | A drag already under way, with the pointer at `mouse` in an 800 × 600
-- | container. 40px from an edge is where auto-pan starts.
dragUnderWay :: XYPosition -> DragState
dragUnderWay = dragUnderWayIn lookup

-- | `dragUnderWay` over a given lookup, for the multi-node checks. Every node
-- | in the lookup is selected, so all of them are drag items.
dragUnderWayIn :: NodeLookup Unit -> XYPosition -> DragState
dragUnderWayIn nodeLookup mouse = initialDragState
  { lastPos = { x: Just grab.x, y: Just grab.y }
  , dragItems = getDragItems nodeLookup true grab (Just nodeId)
  , autoPanStarted = true
  , mousePosition = mouse
  , containerBounds = Just { left: 0.0, top: 0.0, width: 800.0, height: 600.0 }
  , dragStarted = true
  , dragEvent = Just stubMouseEvent
  }

awayFromEdges :: XYPosition
awayFromEdges = { x: 400.0, y: 300.0 }

-- | 10px from the left edge: velocity (40 − 10) / 40 at the default speed of
-- | 15, so each frame pans 11.25px right and the node moves 11.25 left.
nearLeftEdge :: XYPosition
nearLeftEdge = { x: 10.0, y: 300.0 }

type Recorded =
  { pans :: Ref Int
  , moved :: Ref (Maybe (Map.Map NodeId NodeDragItem))
  , nodeDrags :: Ref (Array NodeId)
  , selectionDrags :: Ref Int
  }

paramsWith :: NodeLookup Unit -> Recorded -> PanBy -> XYDragParams Unit Unit
paramsWith nodeLookup rec panBy =
  { getStoreItems: pure
      { nodes: []
      , nodeLookup
      , edges: []
      , nodeExtent: infiniteExtent
      , snapGrid: mkSnapGrid 15.0 15.0
      , snapToGrid: false
      , nodeOrigin: NodeOrigin { ox: 0.0, oy: 0.0 }
      , multiSelectionActive: false
      , domNode: Nothing
      , transform: Transform { tx: 0.0, ty: 0.0, scale: 1.0 }
      , autoPanOnNodeDrag: true
      , nodesDraggable: true
      , selectNodesOnDrag: true
      , nodeDragThreshold: 0.0
      , panBy: \delta -> liftEffect (Ref.modify_ (_ + 1) rec.pans) *> panBy delta
      , unselectNodesAndEdges: pure unit
      , onNodeDragStart: Nothing
      , onNodeDrag: Just (\_ cn _ -> Ref.modify_ (_ <> [ cn.id ]) rec.nodeDrags)
      , onNodeDragStop: Nothing
      , onSelectionDragStart: Nothing
      , onSelectionDrag: Just (\_ _ -> Ref.modify_ (_ + 1) rec.selectionDrags)
      , onSelectionDragStop: Nothing
      , updateNodePositions: \items _ -> Ref.write (Just items) rec.moved
      , autoPanSpeed: Nothing
      }
  , onDragStart: Nothing
  , onDrag: Nothing
  , onDragStop: Nothing
  , onNodeMouseDown: Nothing
  , autoPanSpeed: Nothing
  }

record :: Effect Recorded
record = do
  pans <- Ref.new 0
  moved <- Ref.new Nothing
  nodeDrags <- Ref.new []
  selectionDrags <- Ref.new 0
  pure { pans, moved, nodeDrags, selectionDrags }

movedTo :: Recorded -> Effect (Maybe XYPosition)
movedTo rec = do
  m <- Ref.read rec.moved
  pure (m >>= Map.lookup nodeId <#> _.position)

-- | Run one frame against a fresh frame clock, then hand the clock, the state
-- | and the recording to `check`.
withFrame
  :: XYPosition
  -> PanBy
  -> (FrameClock -> Ref DragState -> Recorded -> Aff Unit)
  -> Aff Unit
withFrame mouse = withFrameIn lookup (dragUnderWay mouse)

-- | `withFrame` over a given lookup and starting state. The frame carries the
-- | grabbed node id either way, which is what `onDragHandler` hands the loop.
withFrameIn
  :: NodeLookup Unit
  -> DragState
  -> PanBy
  -> (FrameClock -> Ref DragState -> Recorded -> Aff Unit)
  -> Aff Unit
withFrameIn nodeLookup st panBy check = do
  clock <- liftEffect installFrameClock
  rec <- liftEffect record
  stateRef <- liftEffect $ Ref.new st
  liftEffect $ autoPanLoop (paramsWith nodeLookup rec panBy) (Just nodeId) stateRef
  check clock stateRef rec
  liftEffect clock.restore

runXYDragTests :: Effect Unit
runXYDragTests = launchAff_ do
  log "running auto-pan loop tests..."

  -- Away from the edges there is nothing to wait for, so the next frame is
  -- asked for straight away. TS does the same: no `await` on that path.
  withFrame awayFromEdges (\_ -> pure true) \clock _ rec -> do
    requests <- liftEffect clock.requests
    pans <- liftEffect (Ref.read rec.pans)
    assert "a frame away from the edges asks for the next one straight away"
      (requests == 1)
    assert "a frame away from the edges does not pan" (pans == 0)

  -- Near an edge, the next frame waits for the pan. The pan is held open on
  -- an AVar to show that nothing is asked for in the meantime.
  gate <- AVar.empty
  withFrame nearLeftEdge (\_ -> AVar.take gate) \clock _ rec -> do
    pans <- liftEffect (Ref.read rec.pans)
    held <- liftEffect clock.requests
    assert "a frame near an edge pans" (pans == 1)
    assert "a frame near an edge asks for no frame while its pan is in flight"
      (held == 0)
    AVar.put true gate
    settle
    landed <- liftEffect clock.requests
    assert "a frame near an edge asks for the next one once its pan has landed"
      (landed == 1)

  -- ps-flow's own `panBy` completes synchronously, which is the case that
  -- decides whether the continuation runs inside the frame or after it.
  withFrame nearLeftEdge (\_ -> pure true) \clock stateRef rec -> do
    settle
    at <- liftEffect (movedTo rec)
    assert "a frame near an edge moves the node by the distance panned"
      (at == Just { x: 100.0 - 11.25, y: 100.0 })
    requests <- liftEffect clock.requests
    assert "a frame whose pan landed asks for exactly one next frame"
      (requests == 1)
    -- What `onEnd` does with the handle: it must be the frame the loop is
    -- waiting on, or the loop outlives the drag.
    liftEffect do
      s <- Ref.read stateRef
      for_ s.autoPanId cancelAnimationFrame
    cancelled <- liftEffect clock.cancelled
    assert "a frame leaves `onEnd` the handle of the frame it asked for"
      (cancelled == [ 1 ])

  -- A pan the viewport refused moves nothing, and the loop carries on.
  withFrame nearLeftEdge (\_ -> pure false) \clock _ rec -> do
    settle
    at <- liftEffect (movedTo rec)
    requests <- liftEffect clock.requests
    assert "a frame whose pan was refused moves nothing" (at == Nothing)
    assert "a frame whose pan was refused still asks for the next one"
      (requests == 1)

  -- The frame carries the grabbed node id, as TS's `autoPan` closure does.
  -- Without it `getEventHandlerParams` takes whichever drag item sorts first,
  -- and `updateNodes` fires `onSelectionDrag` because no id was given.
  withFrame nearLeftEdge (\_ -> pure true) \_ _ rec -> do
    settle
    selections <- liftEffect (Ref.read rec.selectionDrags)
    dragged <- liftEffect (Ref.read rec.nodeDrags)
    assert "a single-node auto-pan frame fires no onSelectionDrag"
      (selections == 0)
    assert "a single-node auto-pan frame reports the grabbed node to onNodeDrag"
      (dragged == [ nodeId ])

  -- Two nodes drag together and the grabbed one sorts second, so a frame that
  -- reported the head of the drag items would name the wrong node.
  withFrameIn multiLookup (dragUnderWayIn multiLookup nearLeftEdge)
    (\_ -> pure true)
    \_ _ rec -> do
      settle
      dragged <- liftEffect (Ref.read rec.nodeDrags)
      assert "a multi-node auto-pan frame reports the grabbed node, not the first"
        (dragged == [ nodeId ])
