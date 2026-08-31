-- | `<EdgeWrapper />` — the per-edge React wrapper. Mirrors
-- | `xyflow-main/packages/react/src/components/EdgeWrapper/index.tsx`.
-- |
-- | Responsibilities:
-- |
-- |   1. Project the current edge from the store via `useStore`, with
-- |      `defaultEdgeOptions` merged on top.
-- |   2. Resolve the user-supplied edge component from
-- |      `props.edgeTypes` with fallback to `builtinEdgeTypes`. On
-- |      miss, fire `onError "011"` and substitute the built-in
-- |      `bezierEdgeInternal`.
-- |   3. Compute the endpoint coordinates and z-index via a second
-- |      `useStore` selector (so the wrapper only re-renders when the
-- |      relevant primitives actually move).
-- |   4. Render an SVG `<svg><g>` with the standard `react-flow__edge*`
-- |      class names, a11y attributes, and per-edge event handlers.
-- |      Conditionally renders the user edge body and
-- |      `<EdgeUpdateAnchors>` (when reconnect is enabled).
-- |
-- | **Fidelity notes.**
-- |   * `memo` is applied to the public export. The default `Object.is`
-- |     equality won't actually skip renders for record props
-- |     (records are freshly allocated each call); this matches the
-- |     existing `React.Handle` / built-in edge port idiom.
-- |   * The `<g>` carries a `useRef` of its own, which deselecting the
-- |     edge blurs. It is **not** a `forwardRef` and TS's is not either:
-- |     `EdgeWrapper` is internal, nothing hands it a ref, and the note
-- |     that used to stand here called it a deferred `forwardRef` and
-- |     pointed at `Handle.purs`. The real gap was the ref itself —
-- |     there was none, so neither of TS's two `edgeRef.current?.blur()`
-- |     calls had anything to call, and a deselected edge kept the focus
-- |     ring and the keyboard. See [#27](https://github.com/jonbae/PSFlow/issues/27).
-- |   * `edge.ariaRole` / `edge.domAttributes` / `edge.reconnectable`
-- |     aren't carried on `EdgeBase`; the wrapper substitutes
-- |     "img"/"group" for `role`, skips the dom-attribute spread, and
-- |     keys reconnect off the global `edgesReconnectable` flag alone.
-- |   * The component resolution lookup uses the `unsafePerformEffect`
-- |     pattern: a fresh resolution happens each render, and the
-- |     `onError` callback fires on every miss. Acceptable because
-- |     `nodeTypes`/`edgeTypes` are expected to be stable references.
module React.Component.EdgeWrapper
  ( edgeWrapper
  ) where

import Prelude

import Data.Array (elem) as Array
import Data.Foldable (for_)
import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe, isNothing)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object (lookup) as Object
import React.Basic (JSX, ReactComponent, element)
import React.Basic.Events (EventHandler, handler, handler_, syntheticEvent)
import React.Basic.Hooks (UnsafeReference(..), memo, reactComponent, readRef, useRef, useState)
import React.Basic.Hooks as React
import React.Component.EdgeWrapper.UpdateAnchors (edgeUpdateAnchors)
import React.Component.EdgeWrapper.Util (EdgePositionSlice, builtinEdgeTypes, nullPosition)
import React.Edge.Bezier (bezierEdgeInternal)
import React.FFI.DOM (blurElement, g_, opt)
import React.Hook.Store (UseStoreApi, useStore, useStoreApi)
import React.Store.Action (Action(..))
import React.Types.Edges
  ( DefaultEdgeOptions
  , Edge
  , EdgeMouseHandler
  , EdgeProps
  , EdgeTypesMap
  , EdgeWrapperProps
  , ReconnectHandleType(..)
  )
import React.Types.Store (ReactFlowState)
import System.Constants (ErrorCode(..), elementSelectionKeys, errorMessage)
import System.Types.Edge (EdgeMarkerType)
import System.Types.Geometry (Position)
import Data.Newtype (unwrap)
import System.Types.Ids (NodeId(..))
import System.Types.Node (OnError)
import System.Utils.Edges.General (getElevatedEdgeZIndex)
import System.Utils.Edges.Positions (getEdgePosition)
import System.Utils.Marker (getMarkerId)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Element (Element)
import Web.UIEvent.KeyboardEvent (KeyboardEvent)
import Web.UIEvent.KeyboardEvent (key) as KE
import Web.UIEvent.MouseEvent (MouseEvent)

-- | Tag-wrapped `React.createElement('svg', …)`. Lives next door in
-- | `EdgeWrapper.js`; defined locally because `React.FFI.DOM` doesn't
-- | export an `svg_` and we want the per-edge `zIndex` style applied
-- | on the outer SVG element.
foreign import svg_ :: forall p. Record p -> Array JSX -> JSX

-- ----------------------------------------------------------------------------
-- Slices and helpers
-- ----------------------------------------------------------------------------

type EdgeSlice e =
  { edge :: UnsafeReference (Edge e)
  , defaultEdgeOptions :: UnsafeReference (Maybe (DefaultEdgeOptions e))
  }

selectEdgeSlice
  :: forall n e. String -> ReactFlowState n e -> EdgeSlice e
selectEdgeSlice edgeId state =
  { edge: UnsafeReference (fromMaybe (placeholderEdge edgeId) (Map.lookup edgeId state.edgeLookup))
  , defaultEdgeOptions: UnsafeReference state.defaultEdgeOptions
  }

-- | Sentinel returned by the slice selector when the edge has been
-- | removed from the store between dispatch and re-render. The
-- | wrapper's `hidden: true` flag ensures it skips the render path.
placeholderEdge :: forall e. String -> Edge e
placeholderEdge edgeId =
  { id: edgeId
  , edgeType: Nothing
  , source: NodeId ""
  , target: NodeId ""
  , sourceHandle: Nothing
  , targetHandle: Nothing
  , animated: false
  , hidden: true
  , deletable: Nothing
  , selectable: Nothing
  , data: Nothing
  , selected: false
  , markerStart: Nothing
  , markerEnd: Nothing
  , zIndex: Nothing
  , label: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | TS `edge = { ...defaultEdgeOptions, ...edge }`. Per-edge fields
-- | take precedence; defaults fill gaps.
applyDefaults
  :: forall e
   . Maybe (DefaultEdgeOptions e)
  -> Edge e
  -> Edge e
applyDefaults Nothing edge = edge
applyDefaults (Just defaults) edge =
  edge
    { animated = edge.animated || fromMaybe false defaults.animated
    , hidden = edge.hidden || fromMaybe false defaults.hidden
    , deletable = orElse edge.deletable defaults.deletable
    , selectable = orElse edge.selectable defaults.selectable
    , data = orElse edge.data defaults.data
    , zIndex = orElse edge.zIndex defaults.zIndex
    , ariaLabel = orElse edge.ariaLabel defaults.ariaLabel
    , interactionWidth = orElse edge.interactionWidth defaults.interactionWidth
    }
  where
  orElse :: forall a. Maybe a -> Maybe a -> Maybe a
  orElse (Just x) _ = Just x
  orElse Nothing y = y

selectEdgePosition
  :: forall n e
   . String
  -> ReactFlowState n e
  -> EdgePositionSlice
selectEdgePosition edgeId state =
  case Map.lookup edgeId state.edgeLookup of
    Nothing -> nullPosition
    Just edge ->
      case Map.lookup edge.source state.nodeLookup,
        Map.lookup edge.target state.nodeLookup of
        Just src, Just tgt ->
          let
            z = getElevatedEdgeZIndex
              { selected: edge.selected
              , zIndex: fromMaybe 0 edge.zIndex
              , sourceNode: src
              , targetNode: tgt
              , elevateOnSelect: state.elevateEdgesOnSelect
              , zIndexMode: state.zIndexMode
              }
            mPos = getEdgePosition
              { id: edgeId
              , sourceNode: src
              , targetNode: tgt
              , sourceHandle: edge.sourceHandle
              , targetHandle: edge.targetHandle
              , connectionMode: state.connectionMode
              }
          in
            case mPos of
              Just p ->
                { zIndex: z
                , sourceX: Just p.sourceX
                , sourceY: Just p.sourceY
                , targetX: Just p.targetX
                , targetY: Just p.targetY
                , sourcePosition: Just p.sourcePosition
                , targetPosition: Just p.targetPosition
                }
              Nothing -> nullPosition { zIndex = z }
        _, _ -> nullPosition { zIndex = fromMaybe 0 edge.zIndex }

edgeTypesAsObject
  :: Maybe EdgeTypesMap
  -> Object (ReactComponent (EdgeProps Foreign))
edgeTypesAsObject = case _ of
  Nothing -> emptyObject
  Just t -> unsafeCoerce t
  where
  emptyObject :: Object (ReactComponent (EdgeProps Foreign))
  emptyObject = unsafeCoerce ({} :: {})

-- | Resolve `edgeTypes[edgeType] ?? builtinEdgeTypes[edgeType]`.
-- | Reports `error011` to `onError` on substitution.
resolveEdgeComponent
  :: Maybe EdgeTypesMap
  -> Maybe OnError
  -> String
  -> Effect { edgeType :: String, component :: ReactComponent (EdgeProps Foreign) }
resolveEdgeComponent mTypes mOnError edgeType = do
  let
    typesObj = edgeTypesAsObject mTypes
  case Object.lookup edgeType typesObj of
    Just c -> pure { edgeType, component: c }
    Nothing -> case Object.lookup edgeType builtinEdgeTypes of
      Just c -> pure { edgeType, component: c }
      Nothing -> do
        for_ mOnError \cb -> cb "011" (errorMessage (E011 edgeType))
        pure
          { edgeType: "default"
          , component: (unsafeCoerce bezierEdgeInternal) :: ReactComponent (EdgeProps Foreign)
          }

-- | TS `cc(['react-flow__edge', `react-flow__edge-${type}`, …flags, edge.className])`.
buildEdgeClassName
  :: { edgeType :: String
     , noPanClassName :: String
     , selected :: Boolean
     , animated :: Boolean
     , selectable :: Boolean
     , inactive :: Boolean
     , updating :: Boolean
     , className :: String
     }
  -> String
buildEdgeClassName p = joinSpace
  [ "react-flow__edge"
  , "react-flow__edge-" <> p.edgeType
  , p.noPanClassName
  , if p.selected then "selected" else ""
  , if p.animated then "animated" else ""
  , if p.inactive then "inactive" else ""
  , if p.updating then "updating" else ""
  , if p.selectable then "selectable" else ""
  , p.className
  ]

-- | Concatenate the non-empty entries of `xs` with single-space
-- | separators. Mirrors `classcat`'s output.
foreign import joinSpace :: Array String -> String

mkEdgeProps
  :: forall e
   . Edge e
  -> Number
  -> Number
  -> Number
  -> Number
  -> Position
  -> Position
  -> Maybe String
  -> Maybe String
  -> EdgeProps Foreign
mkEdgeProps edge sx sy tx ty sp tp mStart mEnd =
  { id: edge.id
  , type: edge.edgeType
  , animated: edge.animated
  , data: (unsafeCoerce edge.data) :: Maybe Foreign
  -- Thread the per-edge `style` (`Maybe (Object String)`) through to the
  -- `.react-flow__edge-path` via `BaseEdge`'s `style`. The opaque `Style` and
  -- `Object String` share a runtime rep (a plain CSS-prop object), so coerce.
  , style: unsafeCoerce edge.style
  , selected: edge.selected
  , source: unwrap edge.source
  , target: unwrap edge.target
  , selectable: edge.selectable
  , deletable: edge.deletable
  , sourceX: sx
  , sourceY: sy
  , targetX: tx
  , targetY: ty
  , sourcePosition: sp
  , targetPosition: tp
  , label: edge.label
  , labelStyle: Nothing
  , labelShowBg: Nothing
  , labelBgStyle: Nothing
  , labelBgPadding: Nothing
  , labelBgBorderRadius: Nothing
  , sourceHandleId: edge.sourceHandle
  , targetHandleId: edge.targetHandle
  , markerStart: mStart
  , markerEnd: mEnd
  , pathOptions: Nothing
  , interactionWidth: edge.interactionWidth
  }

markerUrl :: EdgeMarkerType -> Maybe String -> String
markerUrl m rfId = "url('#" <> getMarkerId (Just m) rfId <> "')"

-- ----------------------------------------------------------------------------
-- The component
-- ----------------------------------------------------------------------------

edgeWrapper :: forall n e. ReactComponent (EdgeWrapperProps n e)
edgeWrapper =
  unsafePerformEffect $ memo $ reactComponent "EdgeWrapper"
    \(props :: EdgeWrapperProps n e) -> React.do
      slice <- useStore (selectEdgeSlice props.id)
      let
        UnsafeReference edgeFromStore = slice.edge
        UnsafeReference defaultOpts = slice.defaultEdgeOptions
        edge = applyDefaults defaultOpts edgeFromStore
        edgeTypeInit = fromMaybe "default" edge.edgeType
        resolved = unsafePerformEffect
          (resolveEdgeComponent props.edgeTypes props.onError edgeTypeInit)
        edgeType = resolved.edgeType
        edgeComponent = resolved.component

      store <- (useStoreApi :: React.Hook UseStoreApi _)
      -- The edge's own `<g>`, so deselecting it can take focus off it. Not a
      -- ref handed down from a parent: TS's `EdgeWrapper` is a plain component
      -- holding a `useRef` of its own, and this mirrors that.
      edgeRef <- useRef (toNullable Nothing :: Nullable Element)
      updateHover /\ setUpdateHover <- useState false
      reconnecting /\ setReconnecting <- useState false

      positionSlice <- useStore (selectEdgePosition props.id)

      let
        isFocusable = props.edgesFocusable
        isReconnectable :: Maybe ReconnectHandleType
        isReconnectable = case props.onReconnect of
          Nothing -> Nothing
          Just _ -> if props.edgesReconnectable then Just ReconnectAny else Nothing

        -- TS: `edge.selectable || (elementsSelectable && edge.selectable === undefined)`.
        -- An explicit `selectable: false` wins over the global `elementsSelectable`
        -- default; only an *absent* `selectable` inherits it.
        isSelectable = fromMaybe false edge.selectable
          || (props.elementsSelectable && isNothing edge.selectable)

        markerStartUrl = case edge.markerStart of
          Just m -> Just (markerUrl m props.rfId)
          Nothing -> Nothing
        markerEndUrl = case edge.markerEnd of
          Just m -> Just (markerUrl m props.rfId)
          Nothing -> Nothing

        hide = edge.hidden
          || isNothing positionSlice.sourceX
          || isNothing positionSlice.sourceY
          || isNothing positionSlice.targetX
          || isNothing positionSlice.targetY

        -- TS spells this `edgeRef.current?.blur()`, at both of the call sites
        -- below. Deselecting an edge leaves the browser's focus on its `<g>`,
        -- so without this the edge loses its selection and keeps its focus
        -- ring, and the next Escape or Enter still reaches it.
        blurEdge :: Effect Unit
        blurEdge = readRef edgeRef >>= toMaybe >>> flip for_ blurElement

        onClickHandler :: EventHandler
        onClickHandler = handler syntheticEvent \se -> do
          state <- store.getState
          let me = (unsafeCoerce se) :: MouseEvent
          when isSelectable do
            store.dispatch
              (PatchState (\s -> s { nodesSelectionActive = false }))
            if edge.selected && state.multiSelectionActive then do
              store.dispatch
                (UnselectNodesAndEdges { nodes: Nothing, edges: Just [ edge ] })
              blurEdge
            else
              store.dispatch (AddSelectedEdges [ props.id ])
          fireEdgeHandler props.onClick me edge

        onDoubleClickHandler = handler syntheticEvent \se ->
          fireEdgeHandler props.onDoubleClick ((unsafeCoerce se) :: MouseEvent) edge
        onContextMenuHandler = handler syntheticEvent \se ->
          fireEdgeHandler props.onContextMenu ((unsafeCoerce se) :: MouseEvent) edge
        onMouseEnterHandler = handler syntheticEvent \se ->
          fireEdgeHandler props.onMouseEnter ((unsafeCoerce se) :: MouseEvent) edge
        onMouseMoveHandler = handler syntheticEvent \se ->
          fireEdgeHandler props.onMouseMove ((unsafeCoerce se) :: MouseEvent) edge
        onMouseLeaveHandler = handler syntheticEvent \se ->
          fireEdgeHandler props.onMouseLeave ((unsafeCoerce se) :: MouseEvent) edge

        onKeyDownHandler :: EventHandler
        onKeyDownHandler = handler syntheticEvent \se -> do
          let
            ke = (unsafeCoerce se) :: KeyboardEvent
            k = KE.key ke
          when
            ( not (fromMaybe false props.disableKeyboardA11y)
                && Array.elem k elementSelectionKeys
                && isSelectable
            )
            do
              if k == "Escape" then do
                blurEdge
                store.dispatch
                  (UnselectNodesAndEdges { nodes: Nothing, edges: Just [ edge ] })
              else
                store.dispatch (AddSelectedEdges [ props.id ])

      pure $
        if hide then mempty
        else
          svg_
            { style: { zIndex: positionSlice.zIndex } }
            [ g_
                { className: buildEdgeClassName
                    { edgeType
                    , noPanClassName: props.noPanClassName
                    , selected: edge.selected
                    , animated: edge.animated
                    , selectable: isSelectable
                    , inactive: not isSelectable && isNothing props.onClick
                    , updating: updateHover
                    , className: fromMaybe "" edge.className
                    }
                , ref: edgeRef
                , onClick: onClickHandler
                , onDoubleClick: onDoubleClickHandler
                , onContextMenu: onContextMenuHandler
                , onMouseEnter: onMouseEnterHandler
                , onMouseMove: onMouseMoveHandler
                , onMouseLeave: onMouseLeaveHandler
                , onKeyDown: if isFocusable then onKeyDownHandler else handler_ (pure unit)
                , tabIndex: if isFocusable then 0 else -1
                , role: if isFocusable then "group" else "img"
                , "aria-roledescription": "edge"
                , "data-id": props.id
                , "data-testid": "rf__edge-" <> props.id
                , "aria-label": opt edge.ariaLabel
                }
                ( case positionSlice.sourceX,
                    positionSlice.sourceY,
                    positionSlice.targetX,
                    positionSlice.targetY,
                    positionSlice.sourcePosition,
                    positionSlice.targetPosition of
                    Just sx, Just sy, Just tx, Just ty, Just sp, Just tp ->
                      let
                        edgeBody :: JSX
                        edgeBody =
                          if reconnecting then mempty
                          else element edgeComponent
                            (mkEdgeProps edge sx sy tx ty sp tp markerStartUrl markerEndUrl)
                        anchors :: JSX
                        anchors = case isReconnectable of
                          Just rh -> element edgeUpdateAnchors
                            { edge
                            , isReconnectable: rh
                            , reconnectRadius: props.reconnectRadius
                            , onReconnect: props.onReconnect
                            , onReconnectStart: props.onReconnectStart
                            , onReconnectEnd: props.onReconnectEnd
                            , sourceX: sx
                            , sourceY: sy
                            , targetX: tx
                            , targetY: ty
                            , sourcePosition: sp
                            , targetPosition: tp
                            , setUpdateHover: \b -> setUpdateHover (const b)
                            , setReconnecting: \b -> setReconnecting (const b)
                            }
                          Nothing -> mempty
                      in
                        [ edgeBody, anchors ]
                    _, _, _, _, _, _ -> []
                )
            ]

fireEdgeHandler
  :: forall e
   . Maybe (EdgeMouseHandler e)
  -> MouseEvent
  -> Edge e
  -> Effect Unit
fireEdgeHandler mCb me edge = case mCb of
  Just cb -> cb me edge
  Nothing -> pure unit
