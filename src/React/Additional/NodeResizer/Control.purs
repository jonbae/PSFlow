-- | `<NodeResizeControl />` — a single resize handle anchored to a
-- | corner or edge of its host node. Wires `System.XYResizer` into the
-- | React lifecycle. Mirrors `xyflow/.../NodeResizer/NodeResizeControl.tsx`.
module React.Additional.NodeResizer.Control
  ( nodeResizeControl
  , selectScale
  ) where

import Prelude

import Data.Array (length) as Array
import Data.Foldable (foldl, for_)
import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (class Newtype)
import Data.Number as Number
import Data.Number.Format (toString) as NumberFormat
import Data.Nullable (Nullable, toMaybe, toNullable)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object as Object
import React.Basic (ReactComponent)
import React.Basic.Hooks (UnsafeReference(..), memo, reactChildrenToArray, reactComponentWithChildren, readRef, useEffect, useRef, writeRef)
import React.Basic.Hooks as React
import React.Context.NodeId (useNodeId)
import React.FFI.DOM (div_)
import React.Hook.Store (UseStoreApi, useStore, useStoreApi)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import React.Types.Component (NodeResizeControlProps)
import React.Types.Store (ReactFlowState)
import System.Types.Geometry (NodeOrigin(..), Transform(..))
import System.Types.Ids (NodeId(..), parentToNode)
import System.Types.Node
  ( NodeChange(..)
  , ParentExpandChild
  )
import System.Utils.General (evaluateAbsolutePosition)
import System.Utils.Store (handleExpandParent)
import System.XYResizer
  ( ControlLinePosition(..)
  , ControlPosition(..)
  , CornerPosition(..)
  , ResizeControlDirection(..)
  , ResizeControlVariant(..)
  , XYResizerChange
  , XYResizerChildChange
  , XYResizerInstance
  , createXYResizer
  )
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML.HTMLDivElement (HTMLDivElement)

toForeignStyle :: Object String -> Foreign
toForeignStyle = unsafeCoerce

positionClassParts :: ControlPosition -> Array String
positionClassParts = case _ of
  ControlLine LineTop -> [ "top" ]
  ControlLine LineRight -> [ "right" ]
  ControlLine LineBottom -> [ "bottom" ]
  ControlLine LineLeft -> [ "left" ]
  ControlCorner CornerTopLeft -> [ "top", "left" ]
  ControlCorner CornerTopRight -> [ "top", "right" ]
  ControlCorner CornerBottomLeft -> [ "bottom", "left" ]
  ControlCorner CornerBottomRight -> [ "bottom", "right" ]

variantString :: ResizeControlVariant -> String
variantString = case _ of
  LineVariant -> "line"
  HandleVariant -> "handle"

defaultControlPosition :: ResizeControlVariant -> ControlPosition
defaultControlPosition = case _ of
  LineVariant -> ControlLine LineRight
  HandleVariant -> ControlCorner CornerBottomRight

selectScale :: Boolean -> forall n e. ReactFlowState n e -> Maybe String
selectScale enabled s =
  if enabled then
    let Transform t = s.transform
    in Just (NumberFormat.toString (max (1.0 / t.scale) 1.0))
  else Nothing

-- | Keys driving `XYResizer.update` re-runs. Callbacks are wrapped in
-- | `UnsafeReference` (cast through `Foreign`) so JS reference equality
-- | suffices.
newtype UpdDeps = UpdDeps
  { controlPosition :: ControlPosition
  , minWidth :: Number
  , minHeight :: Number
  , maxWidth :: Number
  , maxHeight :: Number
  , keepAspectRatio :: Boolean
  , onResizeStartRef :: Maybe (UnsafeReference Foreign)
  , onResizeRef :: Maybe (UnsafeReference Foreign)
  , onResizeEndRef :: Maybe (UnsafeReference Foreign)
  , shouldResizeRef :: Maybe (UnsafeReference Foreign)
  }

derive instance newtypeUpdDeps :: Newtype UpdDeps _
derive newtype instance eqUpdDeps :: Eq UpdDeps

opaque :: forall a. Maybe a -> Maybe (UnsafeReference Foreign)
opaque = map (UnsafeReference <<< unsafeCoerce)

buildChanges
  :: forall n e
   . Store n e
  -> NodeId
  -> XYResizerChange
  -> Array XYResizerChildChange
  -> Maybe ResizeControlDirection
  -> Effect (Array (NodeChange n))
buildChanges store nid change childChanges resizeDirection = do
  st <- store.getState
  let
    mNode = Map.lookup nid st.nodeLookup
    nodeOrigin = st.nodeOrigin
    initialPosition =
      { x: change.x, y: change.y }
    Tuple parentChanges nextPosition = case mNode of
      Nothing -> Tuple [] initialPosition
      Just node ->
        if node.expandParent /= Just true then Tuple [] initialPosition
        else case node.parentId of
          Nothing -> Tuple [] initialPosition
          Just parentId ->
            let
              origin = fromMaybe nodeOrigin node.origin
              NodeOrigin o = origin
              width = fromMaybe (fromMaybe 0.0 node.measured.width) change.width
              height = fromMaybe (fromMaybe 0.0 node.measured.height) change.height
              fallbackPos =
                { x: fromMaybe node.position.x change.x
                , y: fromMaybe node.position.y change.y
                }
              absolute = evaluateAbsolutePosition fallbackPos
                { width, height }
                (parentToNode parentId)
                st.nodeLookup
                origin
              child :: ParentExpandChild
              child =
                { id: node.id
                , parentId
                , rect:
                    { width
                    , height
                    , x: absolute.x
                    , y: absolute.y
                    }
                }
              parentEx = handleExpandParent [ child ] st.nodeLookup st.parentLookup nodeOrigin
              clampedX = case change.x of
                Just cx | cx /= 0.0 && not (Number.isNaN cx) -> Just (max (o.ox * width) cx)
                _ -> Nothing
              clampedY = case change.y of
                Just cy | cy /= 0.0 && not (Number.isNaN cy) -> Just (max (o.oy * height) cy)
                _ -> Nothing
            in
              Tuple parentEx { x: clampedX, y: clampedY }

    positionChange = case nextPosition.x, nextPosition.y of
      Just x, Just y ->
        [ NodePositionChange
            { id: nid
            , position: Just { x, y }
            , positionAbsolute: Nothing
            , dragging: Nothing
            }
        ]
      _, _ -> []

    dimensionChange = case change.width, change.height of
      Just w, Just h ->
        let
          setAttrs = case resizeDirection of
            Nothing -> Just { width: true, height: true }
            Just Horizontal -> Just { width: true, height: false }
            Just Vertical -> Just { width: false, height: true }
        in
          [ NodeDimensionChange
              { id: nid
              , dimensions: Just { width: w, height: h }
              , resizing: Just true
              , setAttributes: setAttrs
              }
          ]
      _, _ -> []

    childPositionChanges = map
      ( \cc -> NodePositionChange
          { id: cc.id
          , position: Just cc.position
          , positionAbsolute: Nothing
          , dragging: Nothing
          }
      )
      childChanges

  pure (parentChanges <> positionChange <> dimensionChange <> childPositionChanges)

nodeResizeControl :: ReactComponent NodeResizeControlProps
nodeResizeControl =
  unsafePerformEffect $ memo $ reactComponentWithChildren "NodeResizeControl"
    \(props :: NodeResizeControlProps) -> React.do
      contextNodeId <- useNodeId
      store <- (useStoreApi :: React.Hook UseStoreApi _)
      let
        nodeId = case props.nodeId of
          Just nid -> Just nid
          Nothing -> contextNodeId
        variant = fromMaybe HandleVariant props.variant
        autoScale = fromMaybe true props.autoScale
        isHandle = variant == HandleVariant
        scaleSelectorActive = isHandle && autoScale
        controlPosition = fromMaybe (defaultControlPosition variant) props.position
      mScale <- useStore (selectScale scaleSelectorActive)
      divRef <- useRef (toNullable Nothing :: Nullable HTMLDivElement)
      resizerRef <- useRef (toNullable Nothing :: Nullable XYResizerInstance)
      let
        deps = UpdDeps
          { controlPosition
          , minWidth: fromMaybe 10.0 props.minWidth
          , minHeight: fromMaybe 10.0 props.minHeight
          , maxWidth: fromMaybe 1.7976931348623157e308 props.maxWidth
          , maxHeight: fromMaybe 1.7976931348623157e308 props.maxHeight
          , keepAspectRatio: fromMaybe false props.keepAspectRatio
          , onResizeStartRef: opaque props.onResizeStart
          , onResizeRef: opaque props.onResize
          , onResizeEndRef: opaque props.onResizeEnd
          , shouldResizeRef: opaque props.shouldResize
          }
      useEffect deps do
        case nodeId of
          Nothing -> pure (pure unit)
          Just nid -> do
            mDom <- toMaybe <$> readRef divRef
            case mDom of
              Nothing -> pure (pure unit)
              Just dom -> do
                let UpdDeps d = deps
                mExisting <- toMaybe <$> readRef resizerRef
                inst <- case mExisting of
                  Just r -> pure r
                  Nothing -> do
                    r <- createXYResizer
                      { domNode: dom
                      , nodeId: NodeId nid
                      , getStoreItems: do
                          st <- store.getState
                          pure
                            { nodeLookup: st.nodeLookup
                            , nodeOrder: map _.id st.nodes
                            , transform: st.transform
                            , snapGrid: Just st.snapGrid
                            , snapToGrid: st.snapToGrid
                            , nodeOrigin: st.nodeOrigin
                            , paneDomNode: st.domNode
                            }
                      , onChange: \change childChanges -> do
                          changes <- buildChanges store (NodeId nid) change childChanges props.resizeDirection
                          when (Array.length changes > 0) do
                            store.dispatch (TriggerNodeChanges changes)
                      , onEnd: Just \final -> do
                          let dimChange = NodeDimensionChange
                                { id: NodeId nid
                                , dimensions: Just
                                    { width: final.width, height: final.height }
                                , resizing: Just false
                                , setAttributes: Nothing
                                }
                          store.dispatch (TriggerNodeChanges [ dimChange ])
                      }
                    writeRef resizerRef (toNullable (Just r))
                    pure r
                inst.update
                  { controlPosition: d.controlPosition
                  , boundaries:
                      { minWidth: d.minWidth
                      , minHeight: d.minHeight
                      , maxWidth: d.maxWidth
                      , maxHeight: d.maxHeight
                      }
                  , keepAspectRatio: d.keepAspectRatio
                  , resizeDirection: props.resizeDirection
                  , onResizeStart: props.onResizeStart
                  , onResize: props.onResize
                  , onResizeEnd: props.onResizeEnd
                  , shouldResize: props.shouldResize
                  }
                pure do
                  mFinal <- toMaybe <$> readRef resizerRef
                  for_ mFinal _.destroy
      let
        userClass = fromMaybe "" props.className
        posClasses = positionClassParts controlPosition
        className = foldl (\a c -> a <> " " <> c)
          "react-flow__resize-control nodrag" posClasses
          <> " " <> variantString variant
          <> (if userClass == "" then "" else " " <> userClass)
        baseStyle = fromMaybe Object.empty props.style
        styleWithScale = case mScale of
          Just s -> Object.insert "scale" s baseStyle
          Nothing -> baseStyle
        styleWithColor = case props.color of
          Nothing -> styleWithScale
          Just c ->
            let key = if isHandle then "backgroundColor" else "borderColor"
            in Object.insert key c styleWithScale
      pure $ div_
        { className
        , ref: divRef
        , style: toForeignStyle styleWithColor
        }
        (reactChildrenToArray props.children)
