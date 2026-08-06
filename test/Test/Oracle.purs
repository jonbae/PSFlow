-- | The single XYFlow-coupled module in the test suite. Wraps the FFI in
-- | `Test.Oracle.js` (which imports the `@psflow/oracle` bundle) behind
-- | PureScript signatures that mirror the PSFlow functions under parity test,
-- | so a property can write `PS.getBezierPath p` and `Oracle.getBezierPath p`
-- | over the *same* input value.
-- |
-- | The only XYFlow-shape knowledge expressible in PureScript lives here: the
-- | `posStr` translation of the `Position` sum type into XYFlow's lowercase
-- | string, and the newtype→plain-array translations (`Transform`,
-- | `SnapGrid`, `CoordinateExtent`). These are stable; an upstream change to
-- | the math touches the bundle, not this file.
module Test.Oracle
  ( getEdgeCenter
  , getBezierEdgeCenter
  , getStraightPath
  , getBezierPath
  , getSimpleBezierPath
  , getSmoothStepPath
  , clamp
  , getBoundsOfBoxes
  , rectToBox
  , boxToRect
  , getBoundsOfRects
  , getOverlappingArea
  , snapPosition
  , clampPosition
  , pointToRendererPoint
  , rendererPointToPoint
  , getViewportForBounds
  , getNodeToolbarTransform
  , getEdgeToolbarTransform
  , getMarkerId
  , getConnectionStatus
  , OracleNode
  , OracleEdge
  , getOutgoers
  , getIncomers
  , getConnectedEdges
  ) where

import Data.Functor (map)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (Nullable, toMaybe, toNullable)
import System.Types.Connection (Padding(..), PaddingValue(..), Viewport)
import System.Types.Edge (AlignX(..), AlignY(..), EdgeMarkerType(..), MarkerType(..))
import System.Types.Geometry
  ( Box
  , CoordinateExtent(..)
  , Position(..)
  , Rect
  , SnapGrid(..)
  , Transform(..)
  , XYPosition
  )
import System.Types.Node (Align(..))
import System.Utils.Edges.Bezier (BezierControlPoints, BezierPathParams)
import System.Utils.Edges.General (EdgeCenter, EdgePathResult)
import System.Utils.Edges.SimpleBezier (SimpleBezierPathParams)
import System.Utils.Edges.SmoothStep (SmoothStepPathParams)
import System.Utils.Edges.Straight (StraightPathParams)

-- | `Position` → XYFlow's lowercase string. The only XYFlow enum knowledge in
-- | PureScript; matches `enum Position { Left = 'left', … }` upstream.
posStr :: Position -> String
posStr = case _ of
  PosLeft -> "left"
  PosTop -> "top"
  PosRight -> "right"
  PosBottom -> "bottom"

-- | `Align` → XYFlow's `'start' | 'center' | 'end'`.
alignStr :: Align -> String
alignStr = case _ of
  AlignStart -> "start"
  AlignCenter -> "center"
  AlignEnd -> "end"

-- | `AlignX` → XYFlow's `'left' | 'center' | 'right'`.
alignXStr :: AlignX -> String
alignXStr = case _ of
  AlignXLeft -> "left"
  AlignXCenter -> "center"
  AlignXRight -> "right"

-- | `AlignY` → XYFlow's `'top' | 'center' | 'bottom'`.
alignYStr :: AlignY -> String
alignYStr = case _ of
  AlignYTop -> "top"
  AlignYCenter -> "center"
  AlignYBottom -> "bottom"

-- | `MarkerType` → XYFlow's `'arrow' | 'arrowclosed'` (the `type` field of a
-- | custom `EdgeMarker`).
markerTypeStr :: MarkerType -> String
markerTypeStr = case _ of
  Arrow -> "arrow"
  ArrowClosed -> "arrowclosed"

-- ─── Edge centers ─────────────────────────────────────────────────────────

type EdgeCenterArgs =
  { sourceX :: Number, sourceY :: Number, targetX :: Number, targetY :: Number }

foreign import getEdgeCenterImpl :: EdgeCenterArgs -> EdgeCenter

getEdgeCenter :: EdgeCenterArgs -> EdgeCenter
getEdgeCenter = getEdgeCenterImpl

foreign import getBezierEdgeCenterImpl :: BezierControlPoints -> EdgeCenter

getBezierEdgeCenter :: BezierControlPoints -> EdgeCenter
getBezierEdgeCenter = getBezierEdgeCenterImpl

-- ─── Edge paths ───────────────────────────────────────────────────────────

foreign import getStraightPathImpl :: StraightPathParams -> EdgePathResult

getStraightPath :: StraightPathParams -> EdgePathResult
getStraightPath = getStraightPathImpl

type BezierArgs =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: String
  , curvature :: Number
  }

foreign import getBezierPathImpl :: BezierArgs -> EdgePathResult

getBezierPath :: BezierPathParams -> EdgePathResult
getBezierPath p = getBezierPathImpl
  { sourceX: p.sourceX
  , sourceY: p.sourceY
  , sourcePosition: posStr p.sourcePosition
  , targetX: p.targetX
  , targetY: p.targetY
  , targetPosition: posStr p.targetPosition
  , curvature: p.curvature
  }

type SimpleBezierArgs =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: String
  }

foreign import getSimpleBezierPathImpl :: SimpleBezierArgs -> EdgePathResult

getSimpleBezierPath :: SimpleBezierPathParams -> EdgePathResult
getSimpleBezierPath p = getSimpleBezierPathImpl
  { sourceX: p.sourceX
  , sourceY: p.sourceY
  , sourcePosition: posStr p.sourcePosition
  , targetX: p.targetX
  , targetY: p.targetY
  , targetPosition: posStr p.targetPosition
  }

type SmoothStepArgs =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: String
  , borderRadius :: Number
  , centerX :: Nullable Number
  , centerY :: Nullable Number
  , offset :: Number
  , stepPosition :: Number
  }

foreign import getSmoothStepPathImpl :: SmoothStepArgs -> EdgePathResult

getSmoothStepPath :: SmoothStepPathParams -> EdgePathResult
getSmoothStepPath p = getSmoothStepPathImpl
  { sourceX: p.sourceX
  , sourceY: p.sourceY
  , sourcePosition: posStr p.sourcePosition
  , targetX: p.targetX
  , targetY: p.targetY
  , targetPosition: posStr p.targetPosition
  , borderRadius: p.borderRadius
  , centerX: toNullable p.centerX
  , centerY: toNullable p.centerY
  , offset: p.offset
  , stepPosition: p.stepPosition
  }

-- ─── Geometry ─────────────────────────────────────────────────────────────

foreign import clampImpl :: Number -> Number -> Number -> Number

clamp :: Number -> Number -> Number -> Number
clamp = clampImpl

foreign import getBoundsOfBoxesImpl :: Box -> Box -> Box

getBoundsOfBoxes :: Box -> Box -> Box
getBoundsOfBoxes = getBoundsOfBoxesImpl

foreign import rectToBoxImpl :: Rect -> Box

rectToBox :: Rect -> Box
rectToBox = rectToBoxImpl

foreign import boxToRectImpl :: Box -> Rect

boxToRect :: Box -> Rect
boxToRect = boxToRectImpl

foreign import getBoundsOfRectsImpl :: Rect -> Rect -> Rect

getBoundsOfRects :: Rect -> Rect -> Rect
getBoundsOfRects = getBoundsOfRectsImpl

foreign import getOverlappingAreaImpl :: Rect -> Rect -> Number

getOverlappingArea :: Rect -> Rect -> Number
getOverlappingArea = getOverlappingAreaImpl

foreign import snapPositionImpl :: XYPosition -> Array Number -> XYPosition

snapPosition :: XYPosition -> SnapGrid -> XYPosition
snapPosition pos (SnapGrid g) = snapPositionImpl pos [ g.gx, g.gy ]

type DimsArg = { width :: Nullable Number, height :: Nullable Number }

foreign import clampPositionImpl
  :: XYPosition -> Array (Array Number) -> DimsArg -> XYPosition

clampPosition
  :: XYPosition
  -> CoordinateExtent
  -> { width :: Maybe Number, height :: Maybe Number }
  -> XYPosition
clampPosition pos (CoordinateExtent e) dims = clampPositionImpl pos
  [ [ e.minX, e.minY ], [ e.maxX, e.maxY ] ]
  { width: toNullable dims.width, height: toNullable dims.height }

foreign import pointToRendererPointImpl
  :: XYPosition -> Array Number -> Boolean -> Array Number -> XYPosition

pointToRendererPoint :: XYPosition -> Transform -> Maybe SnapGrid -> XYPosition
pointToRendererPoint p (Transform t) mGrid = case mGrid of
  Nothing -> pointToRendererPointImpl p [ t.tx, t.ty, t.scale ] false [ 1.0, 1.0 ]
  Just (SnapGrid g) ->
    pointToRendererPointImpl p [ t.tx, t.ty, t.scale ] true [ g.gx, g.gy ]

foreign import rendererPointToPointImpl :: XYPosition -> Array Number -> XYPosition

rendererPointToPoint :: XYPosition -> Transform -> XYPosition
rendererPointToPoint p (Transform t) = rendererPointToPointImpl p [ t.tx, t.ty, t.scale ]

-- ─── fitView viewport ─────────────────────────────────────────────────────

-- | Upstream's `PaddingWithUnit` (`number | \`${number}px\` | \`${number}%\``)
-- | and `Padding` (a `PaddingWithUnit` or a per-side record), opaque here
-- | because neither is expressible as a PureScript type. The third piece of
-- | XYFlow-shape knowledge in this module, alongside `posStr` and the
-- | newtype→array translations.
foreign import data JsPaddingValue :: Type
foreign import data JsPadding :: Type

foreign import paddingValueImpl :: String -> Number -> JsPaddingValue
foreign import uniformPaddingImpl :: JsPaddingValue -> JsPadding

type DirectionalArg =
  { top :: Nullable JsPaddingValue
  , right :: Nullable JsPaddingValue
  , bottom :: Nullable JsPaddingValue
  , left :: Nullable JsPaddingValue
  , x :: Nullable JsPaddingValue
  , y :: Nullable JsPaddingValue
  }

foreign import directionalPaddingImpl :: DirectionalArg -> JsPadding

-- | `PaddingValue` → `PaddingWithUnit`. The *bare number* form is upstream's
-- | ratio padding (`(viewport - viewport / (1 + p)) * 0.5`); `px` and `%` are
-- | strings it re-parses with `parseFloat`, so the empty unit means "leave it
-- | a number".
paddingValue :: PaddingValue -> JsPaddingValue
paddingValue = case _ of
  RatioPadding r -> paddingValueImpl "" r
  PxPadding px -> paddingValueImpl "px" px
  PctPadding pct -> paddingValueImpl "%" pct

padding :: Padding -> JsPadding
padding = case _ of
  UniformPadding pv -> uniformPaddingImpl (paddingValue pv)
  DirectionalPadding d -> directionalPaddingImpl
    { top: toNullable (map paddingValue d.top)
    , right: toNullable (map paddingValue d.right)
    , bottom: toNullable (map paddingValue d.bottom)
    , left: toNullable (map paddingValue d.left)
    , x: toNullable (map paddingValue d.x)
    , y: toNullable (map paddingValue d.y)
    }

foreign import getViewportForBoundsImpl
  :: Rect -> Number -> Number -> Number -> Number -> JsPadding -> Viewport

getViewportForBounds
  :: Rect -> Number -> Number -> Number -> Number -> Padding -> Viewport
getViewportForBounds bounds width height minZoom maxZoom p =
  getViewportForBoundsImpl bounds width height minZoom maxZoom (padding p)

-- ─── Toolbar transforms ───────────────────────────────────────────────────

foreign import getNodeToolbarTransformImpl
  :: Rect -> Viewport -> String -> Number -> String -> String

getNodeToolbarTransform :: Rect -> Viewport -> Position -> Number -> Align -> String
getNodeToolbarTransform rect viewport position offset align =
  getNodeToolbarTransformImpl rect viewport (posStr position) offset (alignStr align)

foreign import getEdgeToolbarTransformImpl
  :: Number -> Number -> Number -> String -> String -> String

getEdgeToolbarTransform :: Number -> Number -> Number -> AlignX -> AlignY -> String
getEdgeToolbarTransform x y zoom alignX alignY =
  getEdgeToolbarTransformImpl x y zoom (alignXStr alignX) (alignYStr alignY)

-- ─── Markers ──────────────────────────────────────────────────────────────

-- | Tagged carrier for an `EdgeMarkerType`. The JS side reconstructs upstream's
-- | `EdgeMarkerType` (a bare string for a named marker, or an `EdgeMarker`
-- | object with absent `Nothing` fields omitted so `Object.keys` matches).
type MarkerArg =
  { tag :: String
  , named :: Nullable String
  , markerType :: Nullable String
  , color :: Nullable String
  , width :: Nullable Number
  , height :: Nullable Number
  , markerUnits :: Nullable String
  , orient :: Nullable String
  , strokeWidth :: Nullable Number
  }

encMarker :: EdgeMarkerType -> MarkerArg
encMarker = case _ of
  NamedMarker s ->
    { tag: "named"
    , named: toNullable (Just s)
    , markerType: toNullable (Nothing :: Maybe String)
    , color: toNullable (Nothing :: Maybe String)
    , width: toNullable (Nothing :: Maybe Number)
    , height: toNullable (Nothing :: Maybe Number)
    , markerUnits: toNullable (Nothing :: Maybe String)
    , orient: toNullable (Nothing :: Maybe String)
    , strokeWidth: toNullable (Nothing :: Maybe Number)
    }
  CustomMarker em ->
    { tag: "custom"
    , named: toNullable (Nothing :: Maybe String)
    , markerType: toNullable (Just (markerTypeStr em.markerType))
    , color: toNullable em.color
    , width: toNullable em.width
    , height: toNullable em.height
    , markerUnits: toNullable em.markerUnits
    , orient: toNullable em.orient
    , strokeWidth: toNullable em.strokeWidth
    }

foreign import getMarkerIdImpl :: Nullable MarkerArg -> Nullable String -> String

getMarkerId :: Maybe EdgeMarkerType -> Maybe String -> String
getMarkerId marker mid =
  getMarkerIdImpl (toNullable (map encMarker marker)) (toNullable mid)

-- ─── Connections ──────────────────────────────────────────────────────────

foreign import getConnectionStatusImpl :: Nullable Boolean -> Nullable String

-- | XYFlow returns `'valid' | 'invalid' | null`; we surface `null` as `""` so
-- | the property can compare against PSFlow's `Maybe ConnectionStatus` mapped
-- | through the same projection.
getConnectionStatus :: Maybe Boolean -> String
getConnectionStatus mb =
  fromMaybe "" (toMaybe (getConnectionStatusImpl (toNullable mb)))

-- ─── Graph traversal ──────────────────────────────────────────────────────
-- These read only string ids, so the oracle takes minimal shapes and the
-- impls return just the matched ids (the parity property compares id sets).

type OracleNode = { id :: String }
type OracleEdge = { id :: String, source :: String, target :: String }

foreign import getOutgoersImpl
  :: OracleNode -> Array OracleNode -> Array OracleEdge -> Array String

getOutgoers :: OracleNode -> Array OracleNode -> Array OracleEdge -> Array String
getOutgoers = getOutgoersImpl

foreign import getIncomersImpl
  :: OracleNode -> Array OracleNode -> Array OracleEdge -> Array String

getIncomers :: OracleNode -> Array OracleNode -> Array OracleEdge -> Array String
getIncomers = getIncomersImpl

foreign import getConnectedEdgesImpl
  :: Array OracleNode -> Array OracleEdge -> Array String

getConnectedEdges :: Array OracleNode -> Array OracleEdge -> Array String
getConnectedEdges = getConnectedEdgesImpl
