-- | Smooth-step (orthogonal) edge path. Mirrors `smoothstep-edge.ts`.
module System.Utils.Edges.SmoothStep
  ( SmoothStepPathParams
  , GetSmoothStepPathParams
  , getSmoothStepPath
  ) where

import Prelude

import Data.Array (range, length, (!!)) as Array
import Data.Foldable (foldl)
import Data.Maybe (Maybe, fromMaybe)
import Data.Number (abs, pow, sqrt) as Number
import Data.Number.Format (toString) as NumberFormat
import System.Types.Geometry (Position(..), XYPosition)
import System.Utils.Edges.General (EdgePathResult, getEdgeCenter)

type SmoothStepPathParams =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: Position
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: Position
  , borderRadius :: Number
  , centerX :: Maybe Number
  , centerY :: Maybe Number
  , offset :: Number
  , stepPosition :: Number
  }

-- | TS-name alias for `SmoothStepPathParams` — see `GetBezierPathParams`.
type GetSmoothStepPathParams = SmoothStepPathParams

showN :: Number -> String
showN = NumberFormat.toString

handleDirection :: Position -> XYPosition
handleDirection = case _ of
  PosLeft -> { x: -1.0, y: 0.0 }
  PosRight -> { x: 1.0, y: 0.0 }
  PosTop -> { x: 0.0, y: -1.0 }
  PosBottom -> { x: 0.0, y: 1.0 }

distance :: XYPosition -> XYPosition -> Number
distance a b =
  Number.sqrt (Number.pow (b.x - a.x) 2.0 + Number.pow (b.y - a.y) 2.0)

-- | TS `getDirection` chooses ±1 along the dominant axis.
getDirection :: { source :: XYPosition, sourcePosition :: Position, target :: XYPosition } -> XYPosition
getDirection { source, sourcePosition, target } =
  case sourcePosition of
    PosLeft -> horizontal
    PosRight -> horizontal
    _ ->
      if source.y < target.y then { x: 0.0, y: 1.0 }
      else { x: 0.0, y: -1.0 }
  where
  horizontal =
    if source.x < target.x then { x: 1.0, y: 0.0 }
    else { x: -1.0, y: 0.0 }

data Axis = AxisX | AxisY

derive instance eqAxis :: Eq Axis

axisGet :: Axis -> XYPosition -> Number
axisGet AxisX p = p.x
axisGet AxisY p = p.y

axisOpposite :: Axis -> Axis
axisOpposite AxisX = AxisY
axisOpposite AxisY = AxisX

type GetPointsParams =
  { source :: XYPosition
  , sourcePosition :: Position
  , target :: XYPosition
  , targetPosition :: Position
  , center :: { x :: Maybe Number, y :: Maybe Number }
  , offset :: Number
  , stepPosition :: Number
  }

type PointsResult =
  { points :: Array XYPosition
  , centerX :: Number
  , centerY :: Number
  , defaultOffsetX :: Number
  , defaultOffsetY :: Number
  }

addV :: XYPosition -> XYPosition -> XYPosition
addV a b = { x: a.x + b.x, y: a.y + b.y }

scale :: Number -> XYPosition -> XYPosition
scale k v = { x: k * v.x, y: k * v.y }

setAxis :: Axis -> XYPosition -> Number -> XYPosition
setAxis AxisX v n = v { x = n }
setAxis AxisY v n = v { y = n }

getPoints :: GetPointsParams -> PointsResult
getPoints p =
  let
    sourceDir = handleDirection p.sourcePosition
    targetDir = handleDirection p.targetPosition
    sourceGapped = addV p.source (scale p.offset sourceDir)
    targetGapped = addV p.target (scale p.offset targetDir)
    dir = getDirection
      { source: sourceGapped
      , sourcePosition: p.sourcePosition
      , target: targetGapped
      }
    dirAxis = if dir.x /= 0.0 then AxisX else AxisY
    currDir = axisGet dirAxis dir

    defaultEdge = getEdgeCenter
      { sourceX: p.source.x
      , sourceY: p.source.y
      , targetX: p.target.x
      , targetY: p.target.y
      }
    defaultOffsetX = defaultEdge.offsetX
    defaultOffsetY = defaultEdge.offsetY

    sourceDirAccess = axisGet dirAxis sourceDir
    targetDirAccess = axisGet dirAxis targetDir

    initialResult =
      if sourceDirAccess * targetDirAccess == -1.0 then
        oppositeBranch p sourceGapped targetGapped dirAxis currDir sourceDir
      else
        sameOrMixedBranch p sourceGapped targetGapped dirAxis currDir
          sourceDir
          targetDir
  in
    { points: initialResult.pathPoints
    , centerX: initialResult.centerX
    , centerY: initialResult.centerY
    , defaultOffsetX
    , defaultOffsetY
    }

-- | Branch where source and target handle directions are opposite (most
-- | common case: top-bottom or left-right).
oppositeBranch
  :: GetPointsParams
  -> XYPosition
  -> XYPosition
  -> Axis
  -> Number
  -> XYPosition
  -> { pathPoints :: Array XYPosition, centerX :: Number, centerY :: Number }
oppositeBranch p sourceGapped targetGapped dirAxis currDir sourceDir =
  let
    centerX = case dirAxis of
      AxisX -> fromMaybe
        (sourceGapped.x + (targetGapped.x - sourceGapped.x) * p.stepPosition)
        p.center.x
      AxisY -> fromMaybe ((sourceGapped.x + targetGapped.x) / 2.0) p.center.x
    centerY = case dirAxis of
      AxisX -> fromMaybe ((sourceGapped.y + targetGapped.y) / 2.0) p.center.y
      AxisY -> fromMaybe
        (sourceGapped.y + (targetGapped.y - sourceGapped.y) * p.stepPosition)
        p.center.y
    verticalSplit =
      [ { x: centerX, y: sourceGapped.y }, { x: centerX, y: targetGapped.y } ]
    horizontalSplit =
      [ { x: sourceGapped.x, y: centerY }, { x: targetGapped.x, y: centerY } ]
    points =
      if axisGet dirAxis sourceDir == currDir then case dirAxis of
        AxisX -> verticalSplit
        AxisY -> horizontalSplit
      else case dirAxis of
        AxisX -> horizontalSplit
        AxisY -> verticalSplit
    pathPoints = buildPathPoints p.source p.target points
      { x: 0.0, y: 0.0 }
      { x: 0.0, y: 0.0 }
      sourceGapped
      targetGapped
  in
    { pathPoints, centerX, centerY }

-- | Branch where source and target handle directions are the same or
-- | perpendicular. The shape is a single L with optional gap-offset to avoid
-- | overlapping when the handle positions are equal.
sameOrMixedBranch
  :: GetPointsParams
  -> XYPosition
  -> XYPosition
  -> Axis
  -> Number
  -> XYPosition
  -> XYPosition
  -> { pathPoints :: Array XYPosition, centerX :: Number, centerY :: Number }
sameOrMixedBranch p sourceGapped targetGapped dirAxis currDir sourceDir targetDir =
  let
    sourceTarget = [ { x: sourceGapped.x, y: targetGapped.y } ]
    targetSource = [ { x: targetGapped.x, y: sourceGapped.y } ]

    samePosBasePoints = case dirAxis of
      AxisX ->
        if sourceDir.x == currDir then targetSource else sourceTarget
      AxisY ->
        if sourceDir.y == currDir then sourceTarget else targetSource

    -- gap-offset adjustment when source and target handles are on the same
    -- side and the on-axis distance is less than `offset`.
    { sourceGapOffset, targetGapOffset } =
      if p.sourcePosition == p.targetPosition then
        let
          diff = Number.abs (axisGet dirAxis p.source - axisGet dirAxis p.target)
        in
          if diff <= p.offset then
            let
              gapOffset = min (p.offset - 1.0) (p.offset - diff)
              srcSign =
                if axisGet dirAxis sourceGapped > axisGet dirAxis p.source then -1.0
                else 1.0
              tgtSign =
                if axisGet dirAxis targetGapped > axisGet dirAxis p.target then -1.0
                else 1.0
            in
              if axisGet dirAxis sourceDir == currDir then
                { sourceGapOffset:
                    setAxis dirAxis { x: 0.0, y: 0.0 } (srcSign * gapOffset)
                , targetGapOffset: { x: 0.0, y: 0.0 }
                }
              else
                { sourceGapOffset: { x: 0.0, y: 0.0 }
                , targetGapOffset:
                    setAxis dirAxis { x: 0.0, y: 0.0 } (tgtSign * gapOffset)
                }
          else
            { sourceGapOffset: { x: 0.0, y: 0.0 }
            , targetGapOffset: { x: 0.0, y: 0.0 }
            }
      else
        { sourceGapOffset: { x: 0.0, y: 0.0 }
        , targetGapOffset: { x: 0.0, y: 0.0 }
        }

    points =
      if p.sourcePosition /= p.targetPosition then
        let
          oppAxis = axisOpposite dirAxis
          isSameDir = axisGet dirAxis sourceDir == axisGet oppAxis targetDir
          sourceGtTargetOppo =
            axisGet oppAxis sourceGapped > axisGet oppAxis targetGapped
          sourceLtTargetOppo =
            axisGet oppAxis sourceGapped < axisGet oppAxis targetGapped
          flipSourceTarget =
            (axisGet dirAxis sourceDir == 1.0
              && ((not isSameDir && sourceGtTargetOppo)
                || (isSameDir && sourceLtTargetOppo)))
              ||
                (axisGet dirAxis sourceDir /= 1.0
                  && ((not isSameDir && sourceLtTargetOppo)
                    || (isSameDir && sourceGtTargetOppo)))
        in
          if flipSourceTarget then case dirAxis of
            AxisX -> sourceTarget
            AxisY -> targetSource
          else samePosBasePoints
      else samePosBasePoints

    sourceGapPoint = addV sourceGapped sourceGapOffset
    targetGapPoint = addV targetGapped targetGapOffset

    firstPoint = fromMaybe { x: 0.0, y: 0.0 } (points Array.!! 0)
    maxXDistance =
      max
        (Number.abs (sourceGapPoint.x - firstPoint.x))
        (Number.abs (targetGapPoint.x - firstPoint.x))
    maxYDistance =
      max
        (Number.abs (sourceGapPoint.y - firstPoint.y))
        (Number.abs (targetGapPoint.y - firstPoint.y))
    centerX =
      if maxXDistance >= maxYDistance then
        (sourceGapPoint.x + targetGapPoint.x) / 2.0
      else firstPoint.x
    centerY =
      if maxXDistance >= maxYDistance then firstPoint.y
      else (sourceGapPoint.y + targetGapPoint.y) / 2.0
    pathPoints = buildPathPoints p.source p.target points
      sourceGapOffset
      targetGapOffset
      sourceGapped
      targetGapped
  in
    { pathPoints, centerX, centerY }

-- | Sequence: source, optional gappedSource, ...points, optional gappedTarget,
-- | target — but only insert gappedSource/Target when they aren't equal to
-- | the adjacent inner point (to avoid duplicate bend points).
buildPathPoints
  :: XYPosition
  -> XYPosition
  -> Array XYPosition
  -> XYPosition
  -> XYPosition
  -> XYPosition
  -> XYPosition
  -> Array XYPosition
buildPathPoints source target points sourceGapOffset targetGapOffset sourceGapped targetGapped =
  let
    gappedSource = addV sourceGapped sourceGapOffset
    gappedTarget = addV targetGapped targetGapOffset
    headPt = fromMaybe { x: 0.0, y: 0.0 } (points Array.!! 0)
    tailPt = fromMaybe { x: 0.0, y: 0.0 }
      (points Array.!! (Array.length points - 1))
    prefix = if gappedSource.x /= headPt.x || gappedSource.y /= headPt.y then [ gappedSource ] else []
    suffix = if gappedTarget.x /= tailPt.x || gappedTarget.y /= tailPt.y then [ gappedTarget ] else []
  in
    [ source ] <> prefix <> points <> suffix <> [ target ]

-- | A single rounded bend: takes three consecutive points and a max corner
-- | radius. Reproduces TS `getBend`.
getBend :: XYPosition -> XYPosition -> XYPosition -> Number -> String
getBend a b c size =
  let
    bendSize = min (min (distance a b / 2.0) (distance b c / 2.0)) size
  in
    if (a.x == b.x && b.x == c.x) || (a.y == b.y && b.y == c.y) then
      "L" <> showN b.x <> " " <> showN b.y
    else if a.y == b.y then
      let
        xDir = if a.x < c.x then -1.0 else 1.0
        yDir = if a.y < c.y then 1.0 else -1.0
      in
        "L " <> showN (b.x + bendSize * xDir) <> "," <> showN b.y
          <> "Q "
          <> showN b.x
          <> ","
          <> showN b.y
          <> " "
          <> showN b.x
          <> ","
          <> showN (b.y + bendSize * yDir)
    else
      let
        xDir = if a.x < c.x then 1.0 else -1.0
        yDir = if a.y < c.y then -1.0 else 1.0
      in
        "L " <> showN b.x <> "," <> showN (b.y + bendSize * yDir)
          <> "Q "
          <> showN b.x
          <> ","
          <> showN b.y
          <> " "
          <> showN (b.x + bendSize * xDir)
          <> ","
          <> showN b.y

getSmoothStepPath :: SmoothStepPathParams -> EdgePathResult
getSmoothStepPath p =
  let
    res = getPoints
      { source: { x: p.sourceX, y: p.sourceY }
      , sourcePosition: p.sourcePosition
      , target: { x: p.targetX, y: p.targetY }
      , targetPosition: p.targetPosition
      , center: { x: p.centerX, y: p.centerY }
      , offset: p.offset
      , stepPosition: p.stepPosition
      }
    n = Array.length res.points
    head' = fromMaybe { x: 0.0, y: 0.0 } (res.points Array.!! 0)
    last' = fromMaybe { x: 0.0, y: 0.0 } (res.points Array.!! (n - 1))

    bends =
      if n < 3 then ""
      else
        foldl
          ( \acc i ->
              let
                a = fromMaybe { x: 0.0, y: 0.0 } (res.points Array.!! (i - 1))
                b = fromMaybe { x: 0.0, y: 0.0 } (res.points Array.!! i)
                c = fromMaybe { x: 0.0, y: 0.0 } (res.points Array.!! (i + 1))
              in
                acc <> getBend a b c p.borderRadius
          )
          ""
          (Array.range 1 (n - 2))

    path =
      "M" <> showN head'.x <> " " <> showN head'.y
        <> bends
        <> "L"
        <> showN last'.x
        <> " "
        <> showN last'.y
  in
    { path
    , labelX: res.centerX
    , labelY: res.centerY
    , offsetX: res.defaultOffsetX
    , offsetY: res.defaultOffsetY
    }

