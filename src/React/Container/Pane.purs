-- | `<Pane />` — the pan/select interaction surface that hosts nodes,
-- | edges, and the user-selection lasso. Mirrors
-- | `xyflow-main/packages/react/src/container/Pane/index.tsx`.
-- |
-- | Responsibilities:
-- |
-- |   1. Render a `<div class="react-flow__pane">` with conditional
-- |      `draggable` / `dragging` / `selection` modifier classes.
-- |   2. In selection mode, translate raw pointer events into
-- |      a `userSelectionRect` that grows with the pointer.
-- |   3. Update the selected node/edge sets every frame via
-- |      `getNodeSelectionChanges` / `getEdgeSelectionChanges`,
-- |      dispatched as `TriggerNodeChanges` / `TriggerEdgeChanges`.
-- |   4. Walk `connectionLookup` to mark edges incident to selected
-- |      nodes (mirrors TS — there is no `getEdgesInside` util).
-- |   5. Run an `autoPanOnSelection` rAF loop when the pointer is near
-- |      the pane edges during a lasso drag.
-- |   6. Render the `<UserSelection />` lasso overlay as the last
-- |      child.
-- |
-- | **Fidelity notes.**
-- |   * `.nokey` closest-ancestor opt-out is dropped — no consumers in
-- |     the PS port yet. Reinstate when a real use case appears.
-- |   * The rAF auto-pan loop dispatches `PanBy` fire-and-forget. The
-- |     loop therefore always commits the rect on the next frame
-- |     regardless of whether d3 reported the pan as accepted; the
-- |     `panned`-boolean reach-through of the upstream `.then((panned)
-- |     => …)` is not plumbed back through the dispatch surface.
-- |   * `wrapHandler` `unsafeCoerce`s the synthetic event to
-- |     `MouseEvent`. The wheel handler routes through the same
-- |     `wrapHandler` for the target-equality guard, then re-casts to
-- |     `WheelEvent` before calling `onPaneScroll`.
module React.Container.Pane
  ( pane
  , module React.Container.Pane.Internal
  , module React.Types.Component
  ) where

import Prelude

import Data.Array.NonEmpty (elem) as NEA
import Data.Either (Either(..))
import Data.Foldable (foldl, for_)
import Data.Map (lookup, values) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Number (sqrt)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Data.Set (Set)
import Data.Set as Set
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (ReactComponent, element)
import React.Basic.Events (EventHandler, handler, handler_, syntheticEvent)
import React.Basic.Hooks (Ref, memo, reactChildrenToArray, reactComponentWithChildren, readRef, useEffectOnce, useRef, writeRef)
import React.Basic.Hooks as React
import React.Component.UserSelection (userSelection)
import React.Container.Pane.Internal (buildPaneClass, paneIsDraggable)
import React.FFI.DOM (div_)
import React.Hook.Store (UseStoreApi, useStore, useStoreApi)
import React.Store.Action (Action(..))
import React.Store.Changes (getEdgeSelectionChanges, getNodeSelectionChanges)
import React.Types.Component (PaneProps)
import React.Types.Store (ReactFlowState)
import System.FFI.AnimationFrame (RafHandle, cancelAnimationFrame, requestAnimationFrame)
import System.Types.Connection (ConnectionState(..), SelectionMode(..))
import System.Types.PanZoom (PanOnDrag(..))
import System.Utils.Dom (DOMRect, elementBoundingRect, getEventPosition)
import System.Utils.General (areSetsEqual, calcAutoPan, pointToRendererPoint, rendererPointToPoint)
import System.Utils.Graph (getNodesInside)
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML.HTMLDivElement (HTMLDivElement)
import Web.UIEvent.MouseEvent (MouseEvent)
import Web.UIEvent.WheelEvent (WheelEvent)

-- ----------------------------------------------------------------------------
-- FFI
-- ----------------------------------------------------------------------------

foreign import eventTargetMatchesRefImpl
  :: forall a b. a -> b -> Effect Boolean

foreign import setPointerCaptureImpl     :: forall a. a -> Effect Unit
foreign import releasePointerCaptureImpl :: forall a. a -> Effect Unit
foreign import stopPropagationImpl       :: forall a. a -> Effect Unit
foreign import preventDefaultImpl        :: forall a. a -> Effect Unit
foreign import eventButtonImpl           :: forall a. a -> Effect Int
foreign import eventIsPrimaryImpl        :: forall a. a -> Effect Boolean

toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

-- ----------------------------------------------------------------------------
-- Store slice
-- ----------------------------------------------------------------------------

type PaneSlice =
  { userSelectionActive :: Boolean
  , elementsSelectable :: Boolean
  , connectionInProgress :: Boolean
  , dragging :: Boolean
  , autoPanSpeed :: Number
  }

selectSlice :: forall n e. ReactFlowState n e -> PaneSlice
selectSlice s =
  { userSelectionActive: s.userSelectionActive
  , elementsSelectable: s.elementsSelectable
  , connectionInProgress: case s.connection of
      ConnectionInProgress _ -> true
      NoConnection -> false
  , dragging: s.paneDragging
  , autoPanSpeed: s.autoPanSpeed
  }

-- ----------------------------------------------------------------------------
-- Edge selection: walk `connectionLookup` for selected nodes, gather
-- the incident edge ids whose selectable flag is true. Mirrors TS
-- lines 226–236 — there is no `getEdgesInside` system util.
-- ----------------------------------------------------------------------------

collectIncidentEdgeIds
  :: forall n e
   . ReactFlowState n e
  -> Set String
  -> Set String
collectIncidentEdgeIds state selectedNodeIds =
  let
    edgesSelectableDefault =
      fromMaybe true (state.defaultEdgeOptions >>= _.selectable)
    addEdgesForNode acc nodeId = case Map.lookup nodeId state.connectionLookup of
      Nothing -> acc
      Just handleMap -> foldl (addEdgeIfSelectable edgesSelectableDefault) acc (Map.values handleMap)
  in
    foldl addEdgesForNode Set.empty (Set.toUnfoldable selectedNodeIds :: Array String)
  where
  addEdgeIfSelectable
    :: Boolean
    -> Set String
    -> { edgeId :: String, source :: String, target :: String, sourceHandle :: Maybe String, targetHandle :: Maybe String }
    -> Set String
  addEdgeIfSelectable dflt acc conn = case Map.lookup conn.edgeId state.edgeLookup of
    Nothing -> acc
    Just edge ->
      if fromMaybe dflt edge.selectable then Set.insert conn.edgeId acc
      else acc

-- ----------------------------------------------------------------------------
-- Auto-pan loop helpers
-- ----------------------------------------------------------------------------

cleanupAutoPan
  :: { handleRef :: Ref (Nullable RafHandle)
     , startedRef :: Ref Boolean
     }
  -> Effect Unit
cleanupAutoPan refs = do
  mh <- readRef refs.handleRef
  case toMaybe mh of
    Just h -> cancelAnimationFrame h
    Nothing -> pure unit
  writeRef refs.handleRef (toNullable Nothing)
  writeRef refs.startedRef false

-- ----------------------------------------------------------------------------
-- Wrap a click/context handler to fire only when the event target IS
-- the container itself. TS lines 53-63.
-- ----------------------------------------------------------------------------

wrapMouseHandler
  :: forall a
   . Ref (Nullable HTMLDivElement)
  -> (MouseEvent -> Effect Unit)
  -> a
  -> Effect Unit
wrapMouseHandler containerRef h se = do
  match <- eventTargetMatchesRefImpl se containerRef
  when match (h (unsafeCoerce se))

-- ----------------------------------------------------------------------------
-- The component
-- ----------------------------------------------------------------------------

pane :: ReactComponent PaneProps
pane =
  unsafePerformEffect $ memo $ reactComponentWithChildren "Pane"
    \(props :: PaneProps) -> React.do
      slice <- useStore selectSlice
      store <- (useStoreApi :: React.Hook UseStoreApi _)

      container              <- useRef (toNullable Nothing :: Nullable HTMLDivElement)
      containerBoundsRef     <- useRef (toNullable Nothing :: Nullable DOMRect)
      selectedNodeIdsRef     <- useRef (Set.empty :: Set String)
      selectedEdgeIdsRef     <- useRef (Set.empty :: Set String)
      selectionInProgressRef <- useRef false
      positionRef            <- useRef { x: 0.0, y: 0.0 }
      autoPanHandleRef       <- useRef (toNullable Nothing :: Nullable RafHandle)
      autoPanStartedRef      <- useRef false

      let
        autoPanRefs =
          { handleRef: autoPanHandleRef
          , startedRef: autoPanStartedRef
          }

        isSelectionEnabled = slice.elementsSelectable
          && (props.isSelecting || slice.userSelectionActive)

        draggable = paneIsDraggable props.panOnDrag

        -- ---- commitUserSelectionRect ----------------------------------------
        commitUserSelectionRect :: Number -> Number -> Effect Unit
        commitUserSelectionRect mouseX mouseY = do
          st <- store.getState
          case st.userSelectionRect of
            Nothing -> pure unit
            Just rect -> do
              let
                screenStart = rendererPointToPoint
                  { x: rect.startX, y: rect.startY }
                  st.transform
                nextRectBare =
                  { x: if mouseX < screenStart.x then mouseX else screenStart.x
                  , y: if mouseY < screenStart.y then mouseY else screenStart.y
                  , width: abs (mouseX - screenStart.x)
                  , height: abs (mouseY - screenStart.y)
                  }
                nextRect =
                  { startX: rect.startX
                  , startY: rect.startY
                  , x: nextRectBare.x
                  , y: nextRectBare.y
                  , width: nextRectBare.width
                  , height: nextRectBare.height
                  }
                nextNodes = getNodesInside st.nodeLookup nextRectBare st.transform
                  { partially: props.selectionMode == Partial
                  , excludeNonSelectable: true
                  }
                nextNodeIds :: Set String
                nextNodeIds = Set.fromFoldable (map _.id nextNodes)
                nextEdgeIds = collectIncidentEdgeIds st nextNodeIds

              prevNodeIds <- readRef selectedNodeIdsRef
              prevEdgeIds <- readRef selectedEdgeIdsRef

              when (not (areSetsEqual prevNodeIds nextNodeIds)) do
                let r = getNodeSelectionChanges st.nodeLookup nextNodeIds false
                store.dispatch (TriggerNodeChanges r.changes)

              when (not (areSetsEqual prevEdgeIds nextEdgeIds)) do
                let r = getEdgeSelectionChanges st.edgeLookup nextEdgeIds
                store.dispatch (TriggerEdgeChanges r.changes)

              writeRef selectedNodeIdsRef nextNodeIds
              writeRef selectedEdgeIdsRef nextEdgeIds

              store.setState \s -> s
                { userSelectionRect = Just nextRect
                , userSelectionActive = true
                , nodesSelectionActive = false
                }

        -- ---- autoPan loop ---------------------------------------------------
        autoPan :: Effect Unit
        autoPan = do
          when props.autoPanOnSelection do
            mb <- readRef containerBoundsRef
            case toMaybe mb of
              Nothing -> pure unit
              Just bounds -> do
                pos <- readRef positionRef
                let delta = calcAutoPan pos
                      { width: bounds.width, height: bounds.height }
                      slice.autoPanSpeed
                      40.0
                store.dispatch (PanBy delta)
                commitUserSelectionRect pos.x pos.y
                next <- requestAnimationFrame autoPan
                writeRef autoPanHandleRef (toNullable (Just next))

        -- ---- onClick --------------------------------------------------------
        onClick :: MouseEvent -> Effect Unit
        onClick me = do
          inProgress <- readRef selectionInProgressRef
          if inProgress || slice.connectionInProgress then do
            writeRef selectionInProgressRef false
          else do
            for_ props.onPaneClick \cb -> cb me
            store.dispatch ResetSelectedElements
            store.setState \s -> s { nodesSelectionActive = false }

        -- ---- onContextMenu --------------------------------------------------
        onContextMenu :: MouseEvent -> Effect Unit
        onContextMenu me = case props.panOnDrag of
          PanOnButtons buttons | NEA.elem 2 buttons -> preventDefaultImpl me
          _ -> for_ props.onPaneContextMenu \cb -> cb me

        -- ---- onPaneScroll wrapper -------------------------------------------
        onWheel :: WheelEvent -> Effect Unit
        onWheel we = for_ props.onPaneScroll \cb -> cb we

        -- ---- onClickCapture -------------------------------------------------
        onClickCapture :: forall a. a -> Effect Unit
        onClickCapture se = do
          inProgress <- readRef selectionInProgressRef
          when inProgress do
            stopPropagationImpl se
            writeRef selectionInProgressRef false

        -- ---- onPointerDownCapture (TS lines 145-181) -----------------------
        onPointerDownCapture :: forall a. a -> Effect Unit
        onPointerDownCapture se = do
          st <- store.getState
          mBounds <- case st.domNode of
            Just dn -> Just <$> elementBoundingRect dn
            Nothing -> pure Nothing
          writeRef containerBoundsRef (toNullable mBounds)
          case mBounds of
            Nothing -> pure unit
            Just bounds -> do
              targetIsContainer <- eventTargetMatchesRefImpl se container
              let
                isSelectionActive =
                  (props.selectionOnDrag && targetIsContainer)
                    || props.selectionKeyPressed
              button <- eventButtonImpl se
              isPrimary <- eventIsPrimaryImpl se
              when
                ( props.isSelecting
                    && isSelectionActive
                    && button == 0
                    && isPrimary
                ) do
                setPointerCaptureImpl se
                writeRef selectionInProgressRef false
                pos <- getEventPosition (Left (unsafeCoerce se :: MouseEvent))
                  (Just bounds)
                let
                  startScreen = pointToRendererPoint
                    { x: pos.x, y: pos.y }
                    st.transform
                    Nothing
                store.setState \s -> s
                  { userSelectionRect = Just
                      { width: 0.0
                      , height: 0.0
                      , startX: startScreen.x
                      , startY: startScreen.y
                      , x: pos.x
                      , y: pos.y
                      }
                  }
                when (not targetIsContainer) do
                  stopPropagationImpl se
                  preventDefaultImpl se

        -- ---- onPointerMove (TS lines 282-312) ------------------------------
        onPointerMove :: forall a. a -> Effect Unit
        onPointerMove se = do
          st <- store.getState
          mBounds <- readRef containerBoundsRef
          case toMaybe mBounds, st.userSelectionRect of
            Just bounds, Just rect -> do
              pos <- getEventPosition (Left (unsafeCoerce se :: MouseEvent))
                (Just bounds)
              writeRef positionRef { x: pos.x, y: pos.y }
              let
                screenStart = rendererPointToPoint
                  { x: rect.startX, y: rect.startY }
                  st.transform
              inProgress <- readRef selectionInProgressRef
              if not inProgress then do
                let
                  required =
                    if props.selectionKeyPressed then 0.0
                    else props.paneClickDistance
                  dx = pos.x - screenStart.x
                  dy = pos.y - screenStart.y
                  distance = sqrt (dx * dx + dy * dy)
                if distance <= required then pure unit
                else do
                  store.dispatch ResetSelectedElements
                  for_ props.onSelectionStart \cb ->
                    cb (unsafeCoerce se :: MouseEvent)
                  writeRef selectionInProgressRef true
                  started <- readRef autoPanStartedRef
                  when (not started) do
                    writeRef autoPanStartedRef true
                    autoPan
                  commitUserSelectionRect pos.x pos.y
              else do
                started <- readRef autoPanStartedRef
                when (not started) do
                  writeRef autoPanStartedRef true
                  autoPan
                commitUserSelectionRect pos.x pos.y
            _, _ -> pure unit

        -- ---- onPointerUp (TS lines 314-343) --------------------------------
        onPointerUp :: forall a. a -> Effect Unit
        onPointerUp se = do
          button <- eventButtonImpl se
          when (button == 0) do
            releasePointerCaptureImpl se
            st <- store.getState
            targetIsContainer <- eventTargetMatchesRefImpl se container
            when
              ( not slice.userSelectionActive
                  && targetIsContainer
                  && st.userSelectionRect /= Nothing
              ) do
              onClick (unsafeCoerce se :: MouseEvent)
            store.setState \s -> s
              { userSelectionActive = false
              , userSelectionRect = Nothing
              }
            inProgress <- readRef selectionInProgressRef
            when inProgress do
              for_ props.onSelectionEnd \cb ->
                cb (unsafeCoerce se :: MouseEvent)
              nodeIds <- readRef selectedNodeIdsRef
              store.setState \s -> s
                { nodesSelectionActive = Set.size nodeIds > 0
                }
            cleanupAutoPan autoPanRefs

        -- ---- onPointerCancel -----------------------------------------------
        onPointerCancel :: forall a. a -> Effect Unit
        onPointerCancel se = do
          releasePointerCaptureImpl se
          cleanupAutoPan autoPanRefs

        -- ---- handler builders ----------------------------------------------
        mkPaneMouseHandler :: Maybe (MouseEvent -> Effect Unit) -> EventHandler
        mkPaneMouseHandler mcb = handler syntheticEvent \se ->
          for_ mcb \cb -> cb (unsafeCoerce se :: MouseEvent)

        onClickHandler :: EventHandler
        onClickHandler =
          if isSelectionEnabled then handler_ (pure unit)
          else handler syntheticEvent (wrapMouseHandler container onClick)

        onContextMenuHandler :: EventHandler
        onContextMenuHandler = handler syntheticEvent
          (wrapMouseHandler container onContextMenu)

        onWheelHandler :: EventHandler
        onWheelHandler = handler syntheticEvent \se -> do
          match <- eventTargetMatchesRefImpl se container
          when match (onWheel (unsafeCoerce se :: WheelEvent))

        onPointerEnterHandler :: EventHandler
        onPointerEnterHandler =
          if isSelectionEnabled then handler_ (pure unit)
          else mkPaneMouseHandler props.onPaneMouseEnter

        onPointerMoveHandler :: EventHandler
        onPointerMoveHandler =
          if isSelectionEnabled then handler syntheticEvent onPointerMove
          else mkPaneMouseHandler props.onPaneMouseMove

        onPointerUpHandler :: EventHandler
        onPointerUpHandler =
          if isSelectionEnabled then handler syntheticEvent onPointerUp
          else handler_ (pure unit)

        onPointerCancelHandler :: EventHandler
        onPointerCancelHandler =
          if isSelectionEnabled then handler syntheticEvent onPointerCancel
          else handler_ (pure unit)

        onPointerDownCaptureHandler :: EventHandler
        onPointerDownCaptureHandler =
          if isSelectionEnabled then handler syntheticEvent onPointerDownCapture
          else handler_ (pure unit)

        onClickCaptureHandler :: EventHandler
        onClickCaptureHandler =
          if isSelectionEnabled then handler syntheticEvent onClickCapture
          else handler_ (pure unit)

        onPointerLeaveHandler :: EventHandler
        onPointerLeaveHandler = mkPaneMouseHandler props.onPaneMouseLeave

      useEffectOnce do
        pure (cleanupAutoPan autoPanRefs)

      let
        className = buildPaneClass
          { draggable
          , dragging: slice.dragging
          , isSelecting: props.isSelecting
          }

        styleObj = toForeignStyle
          { position: "absolute"
          , width: "100%"
          , height: "100%"
          , top: 0
          , left: 0
          }

        userChildren = reactChildrenToArray props.children
        allChildren = userChildren <> [ element userSelection { ignored: Nothing } ]

      pure $
        div_
          { ref: container
          , className: className
          , style: styleObj
          , onClick: onClickHandler
          , onContextMenu: onContextMenuHandler
          , onWheel: onWheelHandler
          , onPointerEnter: onPointerEnterHandler
          , onPointerMove: onPointerMoveHandler
          , onPointerUp: onPointerUpHandler
          , onPointerCancel: onPointerCancelHandler
          , onPointerDownCapture: onPointerDownCaptureHandler
          , onClickCapture: onClickCaptureHandler
          , onPointerLeave: onPointerLeaveHandler
          }
          allChildren

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------

abs :: Number -> Number
abs n = if n < 0.0 then -n else n
