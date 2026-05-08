-- | Pure geometric and coordinate utilities ported from
-- | `xyflow-main/packages/system/src/utils/general.ts`.
-- |
-- | Divergence note: the TypeScript module imports `getNodePositionWithOrigin`
-- | from `utils/graph.ts`, while `graph.ts` re-imports ten functions from
-- | `general.ts`. PureScript modules cannot be mutually recursive, so
-- | `getNodePositionWithOrigin` is colocated here. `XYFlow.Utils.Graph`
-- | re-exports it for ticket-009 consumers.
module XYFlow.Utils.General
  ( clamp
  , clamp01
  , clampPosition
  , clampPositionToParent
  , calcAutoPan
  , getBoundsOfBoxes
  , rectToBox
  , boxToRect
  , nodeToRect
  , nodeToBox
  , getBoundsOfRects
  , getOverlappingArea
  , isNumeric
  , devWarn
  , snapPosition
  , pointToRendererPoint
  , rendererPointToPoint
  , getViewportForBounds
  , isMacOs
  , isCoordinateExtent
  , getNodeDimensions
  , nodeHasDimensions
  , evaluateAbsolutePosition
  , areSetsEqual
  , getNodePositionWithOrigin
  , identityTransform
  ) where

import Prelude hiding (clamp)

import Control.Alt ((<|>))
import Data.Array (foldr) as Array
import Data.Either (Either(..))
import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Number (abs, floor, isFinite, isNaN) as Number
import Data.Set (Set)
import Effect (Effect)
import Effect.Console (warn) as Console
import XYFlow.Types.Connection (Padding(..), PaddingValue(..), Viewport)
import XYFlow.Types.Geometry
  ( Box
  , CoordinateExtent(..)
  , Dimensions
  , NodeOrigin(..)
  , Rect
  , SnapGrid(..)
  , Transform(..)
  , XYPosition
  , mkTransform
  )
import XYFlow.Types.Node
  ( InternalNodeBase
  , NodeBase
  , NodeExtent(..)
  , NodeLookup
  )

-- | Default pan-zoom transform. Mirrors the TS literal `[0, 0, 1]` used as the
-- | default `Transform` value in many callsites.
identityTransform :: Transform
identityTransform = mkTransform 0.0 0.0 1.0

-- | Total `clamp` with explicit min/max. The TS version defaults to `[0, 1]`;
-- | here we expose `clamp01` for that case to keep the core total.
clamp :: Number -> Number -> Number -> Number
clamp val mn mx = min (max val mn) mx

clamp01 :: Number -> Number
clamp01 v = clamp v 0.0 1.0

clampPosition
  :: XYPosition
  -> CoordinateExtent
  -> { width :: Maybe Number, height :: Maybe Number }
  -> XYPosition
clampPosition position (CoordinateExtent ext) dims =
  { x: clamp position.x ext.minX (ext.maxX - fromMaybe 0.0 dims.width)
  , y: clamp position.y ext.minY (ext.maxY - fromMaybe 0.0 dims.height)
  }

clampPositionToParent
  :: forall n
   . XYPosition
  -> Dimensions
  -> InternalNodeBase n
  -> XYPosition
clampPositionToParent childPosition childDimensions parent =
  let
    parentDims = getNodeDimensions parent
    parentX = parent.internals.positionAbsolute.x
    parentY = parent.internals.positionAbsolute.y
    extent = CoordinateExtent
      { minX: parentX
      , minY: parentY
      , maxX: parentX + parentDims.width
      , maxY: parentY + parentDims.height
      }
  in
    clampPosition childPosition extent
      { width: Just childDimensions.width
      , height: Just childDimensions.height
      }

calcAutoPan
  :: XYPosition
  -> Dimensions
  -> Number
  -> Number
  -> { x :: Number, y :: Number }
calcAutoPan pos bounds speed distance =
  { x: velocity pos.x distance (bounds.width - distance) * speed
  , y: velocity pos.y distance (bounds.height - distance) * speed
  }
  where
  velocity value mn mx
    | value < mn = clamp (Number.abs (value - mn)) 1.0 mn / mn
    | value > mx = -(clamp (Number.abs (value - mx)) 1.0 mn) / mn
    | otherwise = 0.0

getBoundsOfBoxes :: Box -> Box -> Box
getBoundsOfBoxes a b =
  { x: min a.x b.x
  , y: min a.y b.y
  , x2: max a.x2 b.x2
  , y2: max a.y2 b.y2
  }

rectToBox :: Rect -> Box
rectToBox r = { x: r.x, y: r.y, x2: r.x + r.width, y2: r.y + r.height }

boxToRect :: Box -> Rect
boxToRect b = { x: b.x, y: b.y, width: b.x2 - b.x, height: b.y2 - b.y }

-- | TS dispatches on the `internals` field via `isInternalNodeBase`. We make
-- | the choice explicit at the type level via `Either`.
nodeToRect
  :: forall n
   . Either (NodeBase n) (InternalNodeBase n)
  -> NodeOrigin
  -> Rect
nodeToRect en origin =
  let
    pos = case en of
      Right internal -> internal.internals.positionAbsolute
      Left node -> getNodePositionWithOrigin node origin
    dims = case en of
      Right internal -> getNodeDimensions internal
      Left node -> getNodeDimensions node
  in
    { x: pos.x, y: pos.y, width: dims.width, height: dims.height }

nodeToBox
  :: forall n
   . Either (NodeBase n) (InternalNodeBase n)
  -> NodeOrigin
  -> Box
nodeToBox en origin =
  let r = nodeToRect en origin
  in { x: r.x, y: r.y, x2: r.x + r.width, y2: r.y + r.height }

getBoundsOfRects :: Rect -> Rect -> Rect
getBoundsOfRects a b = boxToRect (getBoundsOfBoxes (rectToBox a) (rectToBox b))

getOverlappingArea :: Rect -> Rect -> Number
getOverlappingArea a b =
  let
    xOverlap = max 0.0
      (min (a.x + a.width) (b.x + b.width) - max a.x b.x)
    yOverlap = max 0.0
      (min (a.y + a.height) (b.y + b.height) - max a.y b.y)
    -- The TS source applies Math.ceil to mirror display-pixel semantics.
    ceilNum n = -(Number.floor (-n))
  in
    ceilNum (xOverlap * yOverlap)

isNumeric :: Number -> Boolean
isNumeric n = not (Number.isNaN n) && Number.isFinite n

-- | TS reads `process.env.NODE_ENV`. PS takes an explicit `isDev` flag and
-- | writes via `Effect.Console.warn`.
devWarn :: Boolean -> String -> String -> Effect Unit
devWarn isDev id message =
  if isDev then
    Console.warn ("[React Flow]: " <> message <> " Help: https://reactflow.dev/error#" <> id)
  else pure unit

snapPosition :: XYPosition -> SnapGrid -> XYPosition
snapPosition position (SnapGrid g) =
  { x: g.gx * roundHalfAwayFromZero (position.x / g.gx)
  , y: g.gy * roundHalfAwayFromZero (position.y / g.gy)
  }

-- | TS uses `Math.round`, which rounds half away from zero (banker's rounding
-- | is `Data.Int.round`). Match TS by hand.
roundHalfAwayFromZero :: Number -> Number
roundHalfAwayFromZero n =
  if n >= 0.0 then Number.floor (n + 0.5)
  else -(Number.floor ((-n) + 0.5))

pointToRendererPoint
  :: XYPosition
  -> Transform
  -> Boolean
  -> SnapGrid
  -> XYPosition
pointToRendererPoint p (Transform t) snapToGrid grid =
  let
    pos = { x: (p.x - t.tx) / t.scale, y: (p.y - t.ty) / t.scale }
  in
    if snapToGrid then snapPosition pos grid else pos

rendererPointToPoint :: XYPosition -> Transform -> XYPosition
rendererPointToPoint p (Transform t) =
  { x: p.x * t.scale + t.tx, y: p.y * t.scale + t.ty }

getViewportForBounds
  :: Rect
  -> Number
  -> Number
  -> Number
  -> Number
  -> Padding
  -> Viewport
getViewportForBounds bounds width height minZoom maxZoom padding =
  let
    p = parsePaddings padding width height
    xZoom = (width - p.x) / bounds.width
    yZoom = (height - p.y) / bounds.height
    zoom = min xZoom yZoom
    clampedZoom = clamp zoom minZoom maxZoom
    boundsCenterX = bounds.x + bounds.width / 2.0
    boundsCenterY = bounds.y + bounds.height / 2.0
    x0 = width / 2.0 - boundsCenterX * clampedZoom
    y0 = height / 2.0 - boundsCenterY * clampedZoom
    newPadding = calculateAppliedPaddings bounds x0 y0 clampedZoom width height
    offset =
      { left: min (newPadding.left - p.left) 0.0
      , top: min (newPadding.top - p.top) 0.0
      , right: min (newPadding.right - p.right) 0.0
      , bottom: min (newPadding.bottom - p.bottom) 0.0
      }
  in
    { x: x0 - offset.left + offset.right
    , y: y0 - offset.top + offset.bottom
    , zoom: clampedZoom
    }

-- | Read a `PaddingValue` against the given viewport extent. Mirrors the TS
-- | `parsePadding` but pattern-matches on the ADT instead of parsing strings.
parsePadding :: PaddingValue -> Number -> Number
parsePadding pv viewport = case pv of
  RatioPadding r -> Number.floor ((viewport - viewport / (1.0 + r)) * 0.5)
  PxPadding px -> Number.floor px
  PctPadding pct -> Number.floor (viewport * pct * 0.01)

type ParsedPaddings =
  { top :: Number
  , bottom :: Number
  , left :: Number
  , right :: Number
  , x :: Number
  , y :: Number
  }

parsePaddings :: Padding -> Number -> Number -> ParsedPaddings
parsePaddings padding width height = case padding of
  UniformPadding pv ->
    let
      paddingY = parsePadding pv height
      paddingX = parsePadding pv width
    in
      { top: paddingY
      , right: paddingX
      , bottom: paddingY
      , left: paddingX
      , x: paddingX * 2.0
      , y: paddingY * 2.0
      }
  DirectionalPadding d ->
    let
      pickV side fallback =
        case side of
          Just v -> parsePadding v fallback
          Nothing -> case d.y of
            Just v -> parsePadding v fallback
            Nothing -> 0.0
      pickH side fallback =
        case side of
          Just v -> parsePadding v fallback
          Nothing -> case d.x of
            Just v -> parsePadding v fallback
            Nothing -> 0.0
      top = pickV d.top height
      bottom = pickV d.bottom height
      left = pickH d.left width
      right = pickH d.right width
    in
      { top, right, bottom, left, x: left + right, y: top + bottom }

calculateAppliedPaddings
  :: Rect
  -> Number
  -> Number
  -> Number
  -> Number
  -> Number
  -> { left :: Number, top :: Number, right :: Number, bottom :: Number }
calculateAppliedPaddings bounds x y zoom width height =
  let
    t = mkTransform x y zoom
    topLeft = rendererPointToPoint { x: bounds.x, y: bounds.y } t
    bottomRight = rendererPointToPoint
      { x: bounds.x + bounds.width, y: bounds.y + bounds.height }
      t
  in
    { left: Number.floor topLeft.x
    , top: Number.floor topLeft.y
    , right: Number.floor (width - bottomRight.x)
    , bottom: Number.floor (height - bottomRight.y)
    }

-- | Reads `navigator.userAgent`. The DOM-touching call is wrapped in
-- | `Effect Boolean`; callers thread it through their effect stack.
foreign import isMacOsImpl :: Effect Boolean

isMacOs :: Effect Boolean
isMacOs = isMacOsImpl

-- | TS type-guard `(extent?) => extent is CoordinateExtent` becomes a total
-- | conversion: `Nothing` and `Just ParentExtent` both collapse to `Nothing`.
isCoordinateExtent :: Maybe NodeExtent -> Maybe CoordinateExtent
isCoordinateExtent = case _ of
  Just (CoordExtent c) -> Just c
  _ -> Nothing

-- | Row-polymorphic so it accepts both `NodeBase` and `InternalNodeBase`
-- | (which are flat records sharing the same dimension fields).
getNodeDimensions
  :: forall r
   . { measured :: { width :: Maybe Number, height :: Maybe Number }
     , width :: Maybe Number
     , height :: Maybe Number
     , initialWidth :: Maybe Number
     , initialHeight :: Maybe Number
     | r
     }
  -> Dimensions
getNodeDimensions node =
  { width:
      fromMaybe 0.0
        (firstJust [ node.measured.width, node.width, node.initialWidth ])
  , height:
      fromMaybe 0.0
        (firstJust [ node.measured.height, node.height, node.initialHeight ])
  }

nodeHasDimensions :: forall n. NodeBase n -> Boolean
nodeHasDimensions node =
  hasJust [ node.measured.width, node.width, node.initialWidth ]
    && hasJust [ node.measured.height, node.height, node.initialHeight ]

-- | Mirror of TS `a ?? b ?? c`: pick the first `Just` in left-to-right order.
firstJust :: forall a. Array (Maybe a) -> Maybe a
firstJust = Array.foldr (<|>) Nothing

hasJust :: forall a. Array (Maybe a) -> Boolean
hasJust arr = case firstJust arr of
  Just _ -> true
  Nothing -> false

-- | Pure version of TS `evaluateAbsolutePosition`. If the parent id is absent
-- | from the lookup, the original position is returned unchanged.
evaluateAbsolutePosition
  :: forall n
   . XYPosition
  -> Dimensions
  -> String
  -> NodeLookup n
  -> NodeOrigin
  -> XYPosition
evaluateAbsolutePosition position dimensions parentId lookup defaultOrigin =
  case Map.lookup parentId lookup of
    Nothing -> position
    Just parent ->
      let
        NodeOrigin origin = fromMaybe defaultOrigin parent.origin
        parentX = parent.internals.positionAbsolute.x
        parentY = parent.internals.positionAbsolute.y
      in
        { x: position.x + parentX - dimensions.width * origin.ox
        , y: position.y + parentY - dimensions.height * origin.oy
        }

areSetsEqual :: Set String -> Set String -> Boolean
areSetsEqual = (==)

-- | Convert a node's logical position to its origin-corrected position.
-- | TS uses a `[number, number]` origin tuple — we use the labelled
-- | `NodeOrigin` newtype.
getNodePositionWithOrigin :: forall n. NodeBase n -> NodeOrigin -> XYPosition
getNodePositionWithOrigin node defaultOrigin =
  let
    dims = getNodeDimensions node
    NodeOrigin origin = fromMaybe defaultOrigin node.origin
  in
    { x: node.position.x - dims.width * origin.ox
    , y: node.position.y - dims.height * origin.oy
    }

