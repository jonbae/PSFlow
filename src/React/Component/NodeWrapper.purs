-- | `<NodeWrapper />` — the per-node React wrapper. Mirrors
-- | `xyflow-main/packages/react/src/components/NodeWrapper/index.tsx`.
-- |
-- | Responsibilities:
-- |
-- |   1. Project the current node + parent flag from the store via
-- |      `useStore` (slice carries `UnsafeReference (InternalNode n)`
-- |      so the slice re-renders the wrapper only when the reducer
-- |      produces a new node object).
-- |   2. Resolve the user-supplied node component from
-- |      `props.nodeTypes` with fallback to `builtinNodeTypes`. On
-- |      miss, fire `onError "003"` and substitute the built-in
-- |      `defaultNode`.
-- |   3. Mount `useDrag` (drag controller) and `useNodeObserver`
-- |      (`ResizeObserver` → `UpdateNodeInternals` dispatch). Both
-- |      receive the local `useRef`'d `<div>` element.
-- |   4. Mount `useMoveSelectedNodes` for arrow-key nudging.
-- |   5. Render a `<div>` with the standard `react-flow__node*` class
-- |      names, computed inline style, data attrs, click / mouse /
-- |      keyboard / focus handlers, and wrap the resolved user
-- |      component in `<NodeIdContext.Provider value={id}>`.
-- |
-- | **Fidelity notes.**
-- |   * `memo` is applied to the public export. The default `Object.is`
-- |     equality won't actually skip renders for record props
-- |     (records are freshly allocated each call); same gap as
-- |     `React.Handle` and the built-in edge ports.
-- |   * `forwardRef` to the inner `<div>` is deferred — the local
-- |     `useRef` is only fed to `useDrag` and `useNodeObserver`.
-- |   * `node.style.width` / `node.style.height` string fallbacks for
-- |     inline dimensions are deferred (`Style` is `Foreign` with no
-- |     typed accessor yet).
-- |   * `node.domAttributes` spread, `node.className`, `node.ariaRole`
-- |     aren't carried on `NodeBase` yet.
-- |   * Keyboard `:focus-visible` guard is dropped (no PS Web binding);
-- |     auto-pan fires on any focus when `autoPanOnNodeFocus` is on.
-- |   * `ariaLiveMessage` on arrow-key nudges is deferred (the
-- |     `AriaLabelConfig` method isn't surfaced through the wrapper
-- |     in a form that's ready for this call site).
-- |   * `panBy` returns `Aff Boolean` but `Action PanBy` is
-- |     fire-and-forget — the adapter reports success unconditionally.
module React.Component.NodeWrapper
  ( nodeWrapper
  ) where

import Prelude

import Data.Array (elem, fromFoldable, null) as Array
import Data.Foldable (for_)
import Data.Map (lookup, singleton, values) as Map
import Data.Maybe (Maybe(..), fromMaybe, isJust)
import Data.Nullable (Nullable, toNullable)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object (lookup) as Object
import React.Basic (ReactComponent, element)
import React.Basic.Events (EventHandler, handler, handler_, syntheticEvent)
import React.Basic.Hooks (UnsafeReference(..), memo, reactComponent, useRef)
import React.Basic.Hooks as React
import React.Component.NodeWrapper.Util (arrowKeyDiffs, builtinNodeTypes, getNodeInlineStyleDimensions)
import React.Context.NodeId (nodeIdProvider)
import React.FFI.DOM (div_, opt)
import React.Hook.Drag (useDrag)
import React.Hook.MoveSelectedNodes (useMoveSelectedNodes)
import React.Hook.NodeObserver (useNodeObserver)
import React.Hook.Store (UseStoreApi, useStore, useStoreApi)
import React.Node.Util (handleNodeClick)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import React.Types.Nodes
  ( InternalNode
  , Node
  , NodeMouseHandler
  , NodeProps
  , NodeTypesMap
  , NodeWrapperProps
  )
import React.Types.Store (ReactFlowState)
import System.Constants (ErrorCode(..), elementSelectionKeys, errorMessage)
import System.Types.Geometry (Transform(..))
import System.Types.Node (OnError)
import System.Utils.Dom (isInputDOMNode)
import System.Utils.General (getNodeDimensions, nodeHasDimensions)
import System.Utils.Graph (getNodesInside)
import System.XYDrag (DragStoreItems)
import Unsafe.Coerce (unsafeCoerce)
import Web.Event.Event (preventDefault)
import Web.HTML.HTMLDivElement (HTMLDivElement, toElement)
import Web.UIEvent.KeyboardEvent (KeyboardEvent)
import Web.UIEvent.KeyboardEvent
  ( key
  , shiftKey
  , toEvent
  ) as KE
import Web.UIEvent.MouseEvent (MouseEvent)

-- | Bridge to merge two `Foreign` style objects ({...base, ...override}).
foreign import mergeStyles :: Foreign -> Foreign -> Foreign

-- | Bridge so the styled wrapper can pass a typed `style` PS record to
-- | React without forcing the record's row through PS's `Lacks` constraints.
toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

emptyForeign :: Foreign
emptyForeign = unsafeCoerce ({} :: {})

-- ----------------------------------------------------------------------------
-- Slice + node-type resolution
-- ----------------------------------------------------------------------------

type NodeWrapperSlice n =
  { node :: UnsafeReference (InternalNode n)
  , isParent :: Boolean
  }

selectNodeSlice
  :: forall n e. String -> ReactFlowState n e -> NodeWrapperSlice n
selectNodeSlice nodeId state =
  { node: UnsafeReference (fromMaybe (placeholderNode nodeId) (Map.lookup nodeId state.nodeLookup))
  , isParent: case Map.lookup nodeId state.parentLookup of
      Just _ -> true
      Nothing -> false
  }

placeholderNode :: forall n. String -> InternalNode n
placeholderNode nodeId =
  { id: nodeId
  , position: { x: 0.0, y: 0.0 }
  , data: (unsafeCoerce {} :: n)
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: true
  , selected: false
  , dragging: false
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
  , expandParent: false
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Nothing, height: Nothing }
  , nodeType: Nothing
  , internals:
      { positionAbsolute: { x: 0.0, y: 0.0 }
      , z: 0.0
      , rootParentIndex: Nothing
      , handleBounds: Nothing
      , bounds: Nothing
      }
  }

nodeTypesAsObject
  :: Maybe NodeTypesMap
  -> Object (ReactComponent (NodeProps Foreign))
nodeTypesAsObject = case _ of
  Nothing -> unsafeCoerce ({} :: {})
  Just t -> unsafeCoerce t

resolveNodeComponent
  :: Maybe NodeTypesMap
  -> Maybe OnError
  -> String
  -> Effect { nodeType :: String, component :: ReactComponent (NodeProps Foreign) }
resolveNodeComponent mTypes mOnError nodeType = do
  let typesObj = nodeTypesAsObject mTypes
  case Object.lookup nodeType typesObj of
    Just c -> pure { nodeType, component: c }
    Nothing -> case Object.lookup nodeType builtinNodeTypes of
      Just c -> pure { nodeType, component: c }
      Nothing -> do
        for_ mOnError \cb -> cb "003" (errorMessage (E003 nodeType))
        case Object.lookup "default" builtinNodeTypes of
          Just c -> pure { nodeType: "default", component: c }
          Nothing ->
            -- Unreachable: the registry always carries "default".
            pure { nodeType: "default", component: unsafeCoerce {} }

-- ----------------------------------------------------------------------------
-- Drag-store-items adapter
-- ----------------------------------------------------------------------------

-- | Build the snapshot the drag controller reads each tick. Wraps the
-- | store actions in the closure shapes the system-layer expects.
mkDragStoreItems
  :: forall n e
   . Store n e
  -> Effect (DragStoreItems n e)
mkDragStoreItems store = do
  s <- store.getState
  pure
    { nodes: s.nodes
    , nodeLookup: s.nodeLookup
    , edges: s.edges
    , nodeExtent: s.nodeExtent
    , snapGrid: s.snapGrid
    , snapToGrid: s.snapToGrid
    , nodeOrigin: s.nodeOrigin
    , multiSelectionActive: s.multiSelectionActive
    , domNode: map toElement s.domNode
    , transform: s.transform
    , autoPanOnNodeDrag: s.autoPanOnNodeDrag
    , nodesDraggable: s.nodesDraggable
    , selectNodesOnDrag: s.selectNodesOnDrag
    , nodeDragThreshold: s.nodeDragThreshold
    , panBy: panByAdapter store
    , unselectNodesAndEdges:
        store.dispatch
          (UnselectNodesAndEdges { nodes: Nothing, edges: Nothing })
    , onError: s.onError
    , onNodeDragStart: s.onNodeDragStart
    , onNodeDrag: s.onNodeDrag
    , onNodeDragStop: s.onNodeDragStop
    , onSelectionDragStart: s.onSelectionDragStart
    , onSelectionDrag: s.onSelectionDrag
    , onSelectionDragStop: s.onSelectionDragStop
    , updateNodePositions: \items dragging ->
        store.dispatch
          ( UpdateNodePositions
              (Array.fromFoldable (Map.values items))
              dragging
          )
    , autoPanSpeed: Just s.autoPanSpeed
    }

panByAdapter
  :: forall n e
   . Store n e
  -> { x :: Number, y :: Number }
  -> Aff Boolean
panByAdapter store delta =
  liftEffect (store.dispatch (PanBy delta)) *> pure true

-- ----------------------------------------------------------------------------
-- Class-name and props for the wrapping <div>
-- ----------------------------------------------------------------------------

buildNodeClassName
  :: { nodeType :: String
     , noPanClassName :: String
     , isDraggable :: Boolean
     , isSelectable :: Boolean
     , isParent :: Boolean
     , selected :: Boolean
     , dragging :: Boolean
     }
  -> String
buildNodeClassName p = joinSpace
  [ "react-flow__node"
  , "react-flow__node-" <> p.nodeType
  , if p.isDraggable then p.noPanClassName else ""
  , if p.selected then "selected" else ""
  , if p.isSelectable then "selectable" else ""
  , if p.isParent then "parent" else ""
  , if p.isDraggable then "draggable" else ""
  , if p.dragging then "dragging" else ""
  ]

foreign import joinSpace :: Array String -> String

mkNodeProps
  :: forall n
   . InternalNode n
  -> String
  -> Boolean
  -> Boolean
  -> Boolean
  -> Boolean
  -> NodeProps Foreign
mkNodeProps node nodeType _selectable _draggable _connectable dragging =
  { id: node.id
  , data: (unsafeCoerce node.data) :: Foreign
  , selected: node.selected
  , type: nodeType
  , isConnectable: _connectable
  , xPos: node.internals.positionAbsolute.x
  , yPos: node.internals.positionAbsolute.y
  , zIndex: node.internals.z
  , dragging
  , targetPosition: node.targetPosition
  , sourcePosition: node.sourcePosition
  , dragHandle: node.dragHandle
  }

-- ----------------------------------------------------------------------------
-- The component
-- ----------------------------------------------------------------------------

nodeWrapper :: forall n. ReactComponent (NodeWrapperProps n)
nodeWrapper =
  unsafePerformEffect $ memo $ reactComponent "NodeWrapper"
    \(props :: NodeWrapperProps n) -> React.do
      slice <- useStore (selectNodeSlice props.id)
      let
        UnsafeReference node = slice.node
        nodeTypeInit = fromMaybe "default" node.nodeType
        resolved = unsafePerformEffect
          (resolveNodeComponent props.nodeTypes props.onError nodeTypeInit)
        nodeType = resolved.nodeType
        userComponent = resolved.component

        isDraggable = case node.draggable of
          Just b -> b
          Nothing -> props.nodesDraggable
        isSelectable = case node.selectable of
          Just b -> b
          Nothing -> props.elementsSelectable
        isConnectable = case node.connectable of
          Just b -> b
          Nothing -> props.nodesConnectable
        isFocusable = props.nodesFocusable
        userNode :: Node n
        userNode = (unsafeCoerce node) :: Node n
        hasDims = nodeHasDimensions userNode

      store <- (useStoreApi :: React.Hook UseStoreApi _)
      nodeRef <- useRef (toNullable Nothing :: Nullable HTMLDivElement)

      dragging <- useDrag
        { wrapperRef: nodeRef
        , nodeId: if node.hidden || not isDraggable then Nothing else Just props.id
        , noDragClassName: Just props.noDragClassName
        , handleSelector: node.dragHandle
        , isSelectable
        , nodeClickDistance: fromMaybe 0.0 props.nodeClickDistance
        , autoPanSpeed: Nothing
        , getStoreItems: mkDragStoreItems store
        , onDragStart: Nothing
        , onDragEnd: Nothing
        }

      _ <- useNodeObserver
        { nodeId: props.id
        , wrapperRef: nodeRef
        , force: false
        }

      moveSelectedNodes <- useMoveSelectedNodes

      let
        hasPointerEvents =
          isSelectable
            || isDraggable
            || isJust props.onClick
            || isJust props.onMouseEnter
            || isJust props.onMouseMove
            || isJust props.onMouseLeave

        inlineDims = getNodeInlineStyleDimensions node
        dims = fromMaybe { width: 0.0, height: 0.0 } (getNodeDimensions node)

        baseStyle :: Foreign
        baseStyle = toForeignStyle
          { zIndex: node.internals.z
          , transform:
              "translate("
                <> show node.internals.positionAbsolute.x
                <> "px,"
                <> show node.internals.positionAbsolute.y
                <> "px)"
          , pointerEvents: if hasPointerEvents then "all" else "none"
          , visibility: if hasDims then "visible" else "hidden"
          , width: inlineDims.width
          , height: inlineDims.height
          }

        mergedStyle :: Foreign
        mergedStyle = mergeStyles baseStyle emptyForeign

        fireMouseHandler :: Maybe (NodeMouseHandler n) -> MouseEvent -> Effect Unit
        fireMouseHandler mCb me = case mCb of
          Just cb -> cb me userNode
          Nothing -> pure unit

        onMouseEnterHandler :: EventHandler
        onMouseEnterHandler = handler syntheticEvent \se ->
          fireMouseHandler props.onMouseEnter ((unsafeCoerce se) :: MouseEvent)

        onMouseMoveHandler :: EventHandler
        onMouseMoveHandler = handler syntheticEvent \se ->
          fireMouseHandler props.onMouseMove ((unsafeCoerce se) :: MouseEvent)

        onMouseLeaveHandler :: EventHandler
        onMouseLeaveHandler = handler syntheticEvent \se ->
          fireMouseHandler props.onMouseLeave ((unsafeCoerce se) :: MouseEvent)

        onContextMenuHandler :: EventHandler
        onContextMenuHandler = handler syntheticEvent \se ->
          fireMouseHandler props.onContextMenu ((unsafeCoerce se) :: MouseEvent)

        onDoubleClickHandler :: EventHandler
        onDoubleClickHandler = handler syntheticEvent \se ->
          fireMouseHandler props.onDoubleClick ((unsafeCoerce se) :: MouseEvent)

        onClickHandler :: EventHandler
        onClickHandler = handler syntheticEvent \se -> do
          let me = (unsafeCoerce se) :: MouseEvent
          st <- store.getState
          when
            ( isSelectable
                &&
                  ( not st.selectNodesOnDrag
                      || not isDraggable
                      || st.nodeDragThreshold > 0.0
                  )
            )
            do
              handleNodeClick { id: props.id, store, unselect: false }
          fireMouseHandler props.onClick me

        onKeyDownHandler :: KeyboardEvent -> Effect Unit
        onKeyDownHandler ke = do
          inputFocused <- isInputDOMNode ke
          unless (inputFocused || props.disableKeyboardA11y) do
            let
              k = KE.key ke
              shift = KE.shiftKey ke
            if Array.elem k elementSelectionKeys && isSelectable then
              handleNodeClick
                { id: props.id
                , store
                , unselect: k == "Escape"
                }
            else case Map.lookup k arrowKeyDiffs of
              Just delta
                | isDraggable && node.selected -> do
                    preventDefault (KE.toEvent ke)
                    moveSelectedNodes delta (if shift then 4.0 else 1.0)
              _ -> pure unit

        onKeyDownEventHandler :: EventHandler
        onKeyDownEventHandler = handler syntheticEvent \se ->
          onKeyDownHandler ((unsafeCoerce se) :: KeyboardEvent)

        onFocusHandler :: EventHandler
        onFocusHandler = handler_ do
          unless props.disableKeyboardA11y do
            st <- store.getState
            when st.autoPanOnNodeFocus do
              let
                Transform t = st.transform
                paneRect =
                  { x: 0.0, y: 0.0, width: st.width, height: st.height }
                visible = getNodesInside
                  (Map.singleton props.id node)
                  paneRect
                  st.transform
                  { partially: true, excludeNonSelectable: false }
              when (Array.null visible) do
                let
                  cx = node.position.x + dims.width / 2.0
                  cy = node.position.y + dims.height / 2.0
                store.dispatch
                  ( SetCenter cx cy
                      { duration: Nothing
                      , ease: Nothing
                      , interpolate: Nothing
                      , zoom: Just t.scale
                      }
                  )

      pure $
        if node.hidden then mempty
        else
          div_
            { className: buildNodeClassName
                { nodeType
                , noPanClassName: props.noPanClassName
                , isDraggable
                , isSelectable
                , isParent: slice.isParent
                , selected: node.selected
                , dragging
                }
            , ref: nodeRef
            , style: mergedStyle
            , "data-id": props.id
            , "data-testid": "rf__node-" <> props.id
            , onMouseEnter: onMouseEnterHandler
            , onMouseMove: onMouseMoveHandler
            , onMouseLeave: onMouseLeaveHandler
            , onContextMenu: onContextMenuHandler
            , onClick: onClickHandler
            , onDoubleClick: onDoubleClickHandler
            , onKeyDown: if isFocusable then onKeyDownEventHandler else handler_ (pure unit)
            , onFocus: if isFocusable then onFocusHandler else handler_ (pure unit)
            , tabIndex: if isFocusable then 0 else -1
            , role: if isFocusable then "group" else ""
            , "aria-roledescription": "node"
            , "aria-label": opt node.ariaLabel
            }
            [ nodeIdProvider (Just props.id)
                [ element userComponent
                    (mkNodeProps node nodeType isSelectable isDraggable isConnectable dragging)
                ]
            ]

