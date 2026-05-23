-- | `<MiniMap />` — overview map of the flow with a click/wheel
-- | interaction surface. Mirrors `xyflow-main/.../MiniMap/MiniMap.tsx`.
module React.Additional.MiniMap
  ( miniMap
  , module React.Types.Component
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Map (isEmpty, lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (class Newtype)
import Data.Number.Format (toString) as NumberFormat
import Data.Nullable (Nullable, toMaybe, toNullable)
import Effect (Effect)
import Effect.Ref as Ref
import Effect.Unsafe (unsafePerformEffect)
import Foreign.Object (Object)
import Foreign.Object as Object
import React.Basic (Ref, ReactComponent, element)
import React.Basic.Events (handler, handler_, syntheticEvent)
import React.Basic.Hooks (UnsafeReference(..), memo, reactChildrenFromArray, reactChildrenToArray, reactComponentWithChildren, readRef, useEffect, useEffectAlways, useRef, writeRef)
import React.Basic.Hooks as React
import React.Additional.MiniMap.Nodes (miniMapNodes)
import React.FFI.DOM (path_, svg_, title_)
import React.Hook.Store (UseStoreApi, useStore, useStoreApi)
import React.Portal.Panel (panel)
import React.Types.Component
  ( MiniMapNodeProps
  , MiniMapNodesProps
  , MiniMapProps
  )
import React.Types.Store (ReactFlowState)
import System.Constants (AriaLabelConfig)
import System.Types.Connection (PanelPosition(..))
import System.Types.Geometry
  ( CoordinateExtent
  , Rect
  , Transform(..)
  )
import System.Types.PanZoom (PanZoomInstance)
import System.Utils.General (getBoundsOfRects)
import System.Utils.Graph (getInternalNodesBounds)
import System.XYMinimap (XYMinimapInstance, createXYMinimap)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Element (Element)
import Web.UIEvent.MouseEvent (MouseEvent)

showN :: Number -> String
showN = NumberFormat.toString

defaultWidth :: Number
defaultWidth = 200.0

defaultHeight :: Number
defaultHeight = 150.0

-- | Subscribe to the per-frame inputs the minimap viewport math depends
-- | on. Newtype-wrap for `Eq`; the `panZoom` and `ariaLabelConfig`
-- | fields use `UnsafeReference` for JS reference equality (both are
-- | records of functions / opaque foreign config).
newtype MMSlice = MMSlice
  { viewBB :: Rect
  , boundingRect :: Rect
  , rfId :: String
  , panZoom :: UnsafeReference (Maybe PanZoomInstance)
  , translateExtent :: CoordinateExtent
  , flowWidth :: Number
  , flowHeight :: Number
  , ariaLabelConfig :: UnsafeReference AriaLabelConfig
  }

derive instance newtypeMMSlice :: Newtype MMSlice _
derive newtype instance eqMMSlice :: Eq MMSlice

selector :: forall n e. ReactFlowState n e -> MMSlice
selector s =
  let
    Transform t = s.transform
    viewBB :: Rect
    viewBB =
      { x: -t.tx / t.scale
      , y: -t.ty / t.scale
      , width: s.width / t.scale
      , height: s.height / t.scale
      }
    boundingRect =
      if Map.isEmpty s.nodeLookup then viewBB
      else getBoundsOfRects
        (getInternalNodesBounds s.nodeLookup (Just (\n -> not n.hidden)))
        viewBB
  in
    MMSlice
      { viewBB
      , boundingRect
      , rfId: s.rfId
      , panZoom: UnsafeReference s.panZoom
      , translateExtent: s.translateExtent
      , flowWidth: s.width
      , flowHeight: s.height
      , ariaLabelConfig: UnsafeReference s.ariaLabelConfig
      }

-- | Bundle of inputs passed to `XYMinimap.update` whenever any of the
-- | per-render minimap options changes. Derived `Eq` via the simple
-- | fields plus the `CoordinateExtent` newtype (`Eq` already).
newtype UpdateDeps = UpdateDeps
  { pannable :: Boolean
  , zoomable :: Boolean
  , inversePan :: Boolean
  , zoomStep :: Number
  , translateExtent :: CoordinateExtent
  , flowWidth :: Number
  , flowHeight :: Number
  }

derive instance newtypeUpdateDeps :: Newtype UpdateDeps _
derive newtype instance eqUpdateDeps :: Eq UpdateDeps

toEffectRef :: forall a. Ref a -> Ref.Ref a
toEffectRef = unsafeCoerce

-- | Build the CSS-variable style record for the Panel wrapper. Each
-- | optional prop maps to one `--xy-minimap-*-props` custom property.
buildPanelStyle
  :: Maybe (Object String)
  -> Maybe String
  -> Maybe String
  -> Maybe String
  -> Maybe Number
  -> Maybe String
  -> Maybe String
  -> Maybe Number
  -> Number
  -> Object String
buildPanelStyle userStyle bgColor maskColor maskStrokeColor maskStrokeWidth
  nodeColor nodeStrokeColor nodeStrokeWidth viewScale =
  base
    # maybeInsert "--xy-minimap-background-color-props" bgColor
    # maybeInsert "--xy-minimap-mask-background-color-props" maskColor
    # maybeInsert "--xy-minimap-mask-stroke-color-props" maskStrokeColor
    # maybeInsert "--xy-minimap-mask-stroke-width-props"
        (map (\w -> show (w * viewScale)) maskStrokeWidth)
    # maybeInsert "--xy-minimap-node-background-color-props" nodeColor
    # maybeInsert "--xy-minimap-node-stroke-color-props" nodeStrokeColor
    # maybeInsert "--xy-minimap-node-stroke-width-props"
        (map show nodeStrokeWidth)
  where
  base = fromMaybe Object.empty userStyle

maybeInsert :: String -> Maybe String -> Object String -> Object String
maybeInsert k mv obj = case mv of
  Nothing -> obj
  Just v -> Object.insert k v obj

-- | The "is `nodeColor` callable as a string?" handling on the TS side
-- | maps to PS pattern matching: if the user supplies a function we
-- | leave it alone; the per-node mapping (`MiniMapNodes`) calls it.
-- | When the user instead wants a constant colour they wrap a constant
-- | function — same idea, slightly more verbose on the PS side.

miniMap :: forall n. ReactComponent (MiniMapProps n)
miniMap =
  unsafePerformEffect $ memo $ reactComponentWithChildren "MiniMap"
    \(props :: MiniMapProps n) -> React.do
      store <- (useStoreApi :: React.Hook UseStoreApi _)
      MMSlice slice <- useStore selector

      svgRef <- useRef (toNullable Nothing :: Nullable Element)
      viewScaleRef <- useRef 0.0
      instanceRef <- useRef (toNullable Nothing :: Nullable XYMinimapInstance)

      let
        elementWidth = defaultWidth
        elementHeight = defaultHeight
        scaledWidth = slice.boundingRect.width / elementWidth
        scaledHeight = slice.boundingRect.height / elementHeight
        viewScale = max scaledWidth scaledHeight
        viewWidth = viewScale * elementWidth
        viewHeight = viewScale * elementHeight
        offset = fromMaybe 5.0 props.offsetScale * viewScale
        x = slice.boundingRect.x - (viewWidth - slice.boundingRect.width) / 2.0 - offset
        y = slice.boundingRect.y - (viewHeight - slice.boundingRect.height) / 2.0 - offset
        width = viewWidth + offset * 2.0
        height = viewHeight + offset * 2.0
        labelledBy = "react-flow__minimap-desc-" <> slice.rfId
        UnsafeReference aria = slice.ariaLabelConfig
        ariaText = fromMaybe aria.minimapAriaLabel props."aria-label"
        pos = fromMaybe BottomRight props.position
        pannable = fromMaybe false props.pannable
        zoomable = fromMaybe false props.zoomable
        inversePan = fromMaybe false props.inversePan
        zoomStep = fromMaybe 1.0 props.zoomStep
        UnsafeReference mPanZoom = slice.panZoom

        deps :: UpdateDeps
        deps = UpdateDeps
          { pannable
          , zoomable
          , inversePan
          , zoomStep
          , translateExtent: slice.translateExtent
          , flowWidth: slice.flowWidth
          , flowHeight: slice.flowHeight
          }

      useEffectAlways do
        writeRef viewScaleRef viewScale
        pure (pure unit)

      -- Mount/destroy effect keyed on the panZoom reference.
      useEffect (UnsafeReference mPanZoom) do
        mSvg <- toMaybe <$> readRef svgRef
        case mSvg, mPanZoom of
          Just svg, Just pz -> do
            inst <- createXYMinimap
              { domNode: svg
              , panZoom: pz
              , getTransform: _.transform <$> store.getState
              , getViewScale: Ref.read (toEffectRef viewScaleRef)
              }
            writeRef instanceRef (toNullable (Just inst))
            pure do
              mInst <- toMaybe <$> readRef instanceRef
              for_ mInst _.destroy
              writeRef instanceRef (toNullable Nothing)
          _, _ -> pure (pure unit)

      -- Update effect keyed on the option bundle.
      useEffect deps do
        let UpdateDeps d = deps
        mInst <- toMaybe <$> readRef instanceRef
        for_ mInst \inst -> inst.update
          { translateExtent: d.translateExtent
          , width: d.flowWidth
          , height: d.flowHeight
          , inversePan: d.inversePan
          , pannable: d.pannable
          , zoomStep: d.zoomStep
          , zoomable: d.zoomable
          }
        pure (pure unit)

      let
        onSvgClick = case props.onClick of
          Nothing -> handler_ (pure unit)
          Just cb -> handler syntheticEvent \e -> do
            mInst <- toMaybe <$> readRef instanceRef
            case mInst of
              Nothing -> pure unit
              Just inst -> do
                mSvg <- toMaybe <$> readRef svgRef
                case mSvg of
                  Nothing -> pure unit
                  Just svg -> do
                    pos' <- inst.pointer svg (unsafeCoerce e)
                    cb (unsafeCoerce e :: MouseEvent) pos'

        onNodeClickHandler :: Maybe (MouseEvent -> String -> Effect Unit)
        onNodeClickHandler = case props.onNodeClick of
          Nothing -> Nothing
          Just cb -> Just \me nid -> do
            st <- store.getState
            case Map.lookup nid st.nodeLookup of
              Nothing -> pure unit
              Just internal -> cb me (unsafeCoerce internal)

        nodesElement = element miniMapNodes
          { nodeColor: props.nodeColor
          , nodeStrokeColor: props.nodeStrokeColor
          , nodeClassName: props.nodeClassName
          , nodeBorderRadius: fromMaybe 5.0 props.nodeBorderRadius
          , nodeStrokeWidth: props.nodeStrokeWidth
          , nodeComponent: props.nodeComponent
          , onClick: onNodeClickHandler
          }

        viewBB = slice.viewBB
        maskPath =
          "M" <> showN (x - offset) <> "," <> showN (y - offset)
            <> "h" <> showN (width + offset * 2.0)
            <> "v" <> showN (height + offset * 2.0)
            <> "h" <> showN (negate (width + offset * 2.0))
            <> "z M" <> showN viewBB.x <> "," <> showN viewBB.y
            <> "h" <> showN viewBB.width
            <> "v" <> showN viewBB.height
            <> "h" <> showN (negate viewBB.width)
            <> "z"

        maskRect =
          path_
            { className: "react-flow__minimap-mask"
            , d: maskPath
            , fillRule: "evenodd"
            , pointerEvents: "none"
            }
            []

        titleEl =
          if ariaText == "" then mempty
          else title_ { id: labelledBy } [ unsafeCoerce ariaText ]

        userExtras = reactChildrenToArray props.children

        svgChildren =
          [ titleEl, nodesElement, maskRect ] <> userExtras

        viewBoxStr = showN x <> " " <> showN y <> " " <> showN width <> " " <> showN height

        panelStyle = buildPanelStyle props.style props.bgColor props.maskColor
          props.maskStrokeColor props.maskStrokeWidth
          (maybeNodeColorString props.nodeColor)
          (maybeNodeColorString props.nodeStrokeColor)
          props.nodeStrokeWidth
          viewScale

        userPanelClass = fromMaybe "" props.className
        panelClassName = "react-flow__minimap"
          <> (if userPanelClass == "" then "" else " " <> userPanelClass)

        svgEl = svg_
          { width: elementWidth
          , height: elementHeight
          , viewBox: viewBoxStr
          , className: "react-flow__minimap-svg"
          , role: "img"
          , "aria-labelledby": labelledBy
          , ref: svgRef
          , onClick: onSvgClick
          }
          svgChildren

      pure $ element panel
        { position: pos
        , className: Just panelClassName
        , style: Just panelStyle
        , "aria-label": Nothing
        , "data-testid": Just "rf__minimap"
        , children: reactChildrenFromArray [ svgEl ]
        }

-- | The TS source accepts either a callback or a string for `nodeColor`
-- | etc. so it can stuff a constant straight into the CSS variable
-- | (`--xy-minimap-node-background-color-props`). The PS port always
-- | takes a callback, so the constant-string path becomes "user didn't
-- | supply, leave the variable unset" — `Nothing` here.
maybeNodeColorString :: forall a. Maybe a -> Maybe String
maybeNodeColorString _ = Nothing
