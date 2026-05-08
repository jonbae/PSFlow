module XYFlow.Types.Geometry
  ( XYPosition
  , XYZPosition
  , Dimensions
  , Rect
  , Box
  , Transform(..)
  , mkTransform
  , CoordinateExtent(..)
  , mkCoordinateExtent
  , NodeOrigin(..)
  , mkNodeOrigin
  , SnapGrid(..)
  , mkSnapGrid
  , Position(..)
  , oppositePosition
  ) where

import Prelude

import Data.Enum (class BoundedEnum, class Enum, Cardinality(..))
import Data.Enum.Generic (genericFromEnum, genericPred, genericSucc, genericToEnum)
import Data.Generic.Rep (class Generic)
import Data.Newtype (class Newtype)
import Data.Show.Generic (genericShow)

type XYPosition = { x :: Number, y :: Number }

type XYZPosition = { x :: Number, y :: Number, z :: Number }

type Dimensions = { width :: Number, height :: Number }

type Rect = { x :: Number, y :: Number, width :: Number, height :: Number }

type Box = { x :: Number, y :: Number, x2 :: Number, y2 :: Number }

newtype Transform = Transform { tx :: Number, ty :: Number, scale :: Number }

derive instance newtypeTransform :: Newtype Transform _
derive newtype instance eqTransform :: Eq Transform
derive newtype instance ordTransform :: Ord Transform
derive newtype instance showTransform :: Show Transform

mkTransform :: Number -> Number -> Number -> Transform
mkTransform tx ty scale = Transform { tx, ty, scale }

newtype CoordinateExtent = CoordinateExtent
  { minX :: Number, minY :: Number, maxX :: Number, maxY :: Number }

derive instance newtypeCoordinateExtent :: Newtype CoordinateExtent _
derive newtype instance eqCoordinateExtent :: Eq CoordinateExtent
derive newtype instance ordCoordinateExtent :: Ord CoordinateExtent
derive newtype instance showCoordinateExtent :: Show CoordinateExtent

mkCoordinateExtent :: Number -> Number -> Number -> Number -> CoordinateExtent
mkCoordinateExtent minX minY maxX maxY =
  CoordinateExtent { minX, minY, maxX, maxY }

newtype NodeOrigin = NodeOrigin { ox :: Number, oy :: Number }

derive instance newtypeNodeOrigin :: Newtype NodeOrigin _
derive newtype instance eqNodeOrigin :: Eq NodeOrigin
derive newtype instance ordNodeOrigin :: Ord NodeOrigin
derive newtype instance showNodeOrigin :: Show NodeOrigin

mkNodeOrigin :: Number -> Number -> NodeOrigin
mkNodeOrigin ox oy = NodeOrigin { ox, oy }

newtype SnapGrid = SnapGrid { gx :: Number, gy :: Number }

derive instance newtypeSnapGrid :: Newtype SnapGrid _
derive newtype instance eqSnapGrid :: Eq SnapGrid
derive newtype instance ordSnapGrid :: Ord SnapGrid
derive newtype instance showSnapGrid :: Show SnapGrid

mkSnapGrid :: Number -> Number -> SnapGrid
mkSnapGrid gx gy = SnapGrid { gx, gy }

data Position
  = PosLeft
  | PosTop
  | PosRight
  | PosBottom

derive instance eqPosition :: Eq Position
derive instance ordPosition :: Ord Position
derive instance genericPosition :: Generic Position _

instance showPosition :: Show Position where
  show = genericShow

instance boundedPosition :: Bounded Position where
  bottom = PosLeft
  top = PosBottom

instance enumPosition :: Enum Position where
  succ = genericSucc
  pred = genericPred

instance boundedEnumPosition :: BoundedEnum Position where
  cardinality = Cardinality 4
  toEnum = genericToEnum
  fromEnum = genericFromEnum

oppositePosition :: Position -> Position
oppositePosition = case _ of
  PosLeft -> PosRight
  PosRight -> PosLeft
  PosTop -> PosBottom
  PosBottom -> PosTop
