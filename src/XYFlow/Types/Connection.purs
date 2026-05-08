module XYFlow.Types.Connection
  ( Connection
  , HandleConnection
  , NodeConnection
  , IsValidConnection
  , Viewport
  , SelectionRect
  , ConnectionMode(..)
  , PanOnScrollMode(..)
  , SelectionMode(..)
  , PanelPosition(..)
  , ColorModeClass(..)
  , ColorMode(..)
  , ZIndexMode(..)
  , InterpolateMode(..)
  , KeyCode(..)
  , PaddingValue(..)
  , Padding(..)
  , ViewportHelperFunctionOptions
  , SetCenterOptions
  , FitBoundsOptions
  , ConnectionLookup
  , ConnectionState(..)
  , ConnectionInProgressData
  , noConnection
  , FinalConnectionState
  ) where

import Prelude

import Data.Array.NonEmpty (NonEmptyArray)
import Data.Enum (class BoundedEnum, class Enum, Cardinality(..))
import Data.Enum.Generic (genericFromEnum, genericPred, genericSucc, genericToEnum)
import Data.Generic.Rep (class Generic)
import Data.Map (Map)
import Data.Maybe (Maybe)
import Data.Show.Generic (genericShow)
import XYFlow.Types.Geometry (Position, XYPosition)
import XYFlow.Types.Handle (Handle)

type Connection =
  { source :: String
  , target :: String
  , sourceHandle :: Maybe String
  , targetHandle :: Maybe String
  }

type HandleConnection =
  { source :: String
  , target :: String
  , sourceHandle :: Maybe String
  , targetHandle :: Maybe String
  , edgeId :: String
  }

type NodeConnection = HandleConnection

-- TODO (ticket 005): widen to (Either EdgeBase Connection -> Boolean) once
-- EdgeBase lands. The TS signature is `EdgeBase | Connection -> boolean`.
type IsValidConnection = Connection -> Boolean

type Viewport = { x :: Number, y :: Number, zoom :: Number }

type SelectionRect =
  { x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  , startX :: Number
  , startY :: Number
  }

data ConnectionMode = Strict | Loose

derive instance eqConnectionMode :: Eq ConnectionMode
derive instance ordConnectionMode :: Ord ConnectionMode
derive instance genericConnectionMode :: Generic ConnectionMode _

instance showConnectionMode :: Show ConnectionMode where
  show = genericShow

instance boundedConnectionMode :: Bounded ConnectionMode where
  bottom = Strict
  top = Loose

instance enumConnectionMode :: Enum ConnectionMode where
  succ = genericSucc
  pred = genericPred

instance boundedEnumConnectionMode :: BoundedEnum ConnectionMode where
  cardinality = Cardinality 2
  toEnum = genericToEnum
  fromEnum = genericFromEnum

data PanOnScrollMode = Free | Vertical | Horizontal

derive instance eqPanOnScrollMode :: Eq PanOnScrollMode
derive instance ordPanOnScrollMode :: Ord PanOnScrollMode
derive instance genericPanOnScrollMode :: Generic PanOnScrollMode _

instance showPanOnScrollMode :: Show PanOnScrollMode where
  show = genericShow

instance boundedPanOnScrollMode :: Bounded PanOnScrollMode where
  bottom = Free
  top = Horizontal

instance enumPanOnScrollMode :: Enum PanOnScrollMode where
  succ = genericSucc
  pred = genericPred

instance boundedEnumPanOnScrollMode :: BoundedEnum PanOnScrollMode where
  cardinality = Cardinality 3
  toEnum = genericToEnum
  fromEnum = genericFromEnum

data SelectionMode = Partial | Full

derive instance eqSelectionMode :: Eq SelectionMode
derive instance ordSelectionMode :: Ord SelectionMode
derive instance genericSelectionMode :: Generic SelectionMode _

instance showSelectionMode :: Show SelectionMode where
  show = genericShow

instance boundedSelectionMode :: Bounded SelectionMode where
  bottom = Partial
  top = Full

instance enumSelectionMode :: Enum SelectionMode where
  succ = genericSucc
  pred = genericPred

instance boundedEnumSelectionMode :: BoundedEnum SelectionMode where
  cardinality = Cardinality 2
  toEnum = genericToEnum
  fromEnum = genericFromEnum

data PanelPosition
  = TopLeft
  | TopCenter
  | TopRight
  | BottomLeft
  | BottomCenter
  | BottomRight
  | CenterLeft
  | CenterRight

derive instance eqPanelPosition :: Eq PanelPosition
derive instance ordPanelPosition :: Ord PanelPosition
derive instance genericPanelPosition :: Generic PanelPosition _

instance showPanelPosition :: Show PanelPosition where
  show = genericShow

instance boundedPanelPosition :: Bounded PanelPosition where
  bottom = TopLeft
  top = CenterRight

instance enumPanelPosition :: Enum PanelPosition where
  succ = genericSucc
  pred = genericPred

instance boundedEnumPanelPosition :: BoundedEnum PanelPosition where
  cardinality = Cardinality 8
  toEnum = genericToEnum
  fromEnum = genericFromEnum

data ColorModeClass = Light | Dark

derive instance eqColorModeClass :: Eq ColorModeClass
derive instance ordColorModeClass :: Ord ColorModeClass
derive instance genericColorModeClass :: Generic ColorModeClass _

instance showColorModeClass :: Show ColorModeClass where
  show = genericShow

instance boundedColorModeClass :: Bounded ColorModeClass where
  bottom = Light
  top = Dark

instance enumColorModeClass :: Enum ColorModeClass where
  succ = genericSucc
  pred = genericPred

instance boundedEnumColorModeClass :: BoundedEnum ColorModeClass where
  cardinality = Cardinality 2
  toEnum = genericToEnum
  fromEnum = genericFromEnum

data ColorMode = LightMode | DarkMode | SystemMode

derive instance eqColorMode :: Eq ColorMode
derive instance ordColorMode :: Ord ColorMode
derive instance genericColorMode :: Generic ColorMode _

instance showColorMode :: Show ColorMode where
  show = genericShow

instance boundedColorMode :: Bounded ColorMode where
  bottom = LightMode
  top = SystemMode

instance enumColorMode :: Enum ColorMode where
  succ = genericSucc
  pred = genericPred

instance boundedEnumColorMode :: BoundedEnum ColorMode where
  cardinality = Cardinality 3
  toEnum = genericToEnum
  fromEnum = genericFromEnum

data ZIndexMode = ZAuto | ZBasic | ZManual

derive instance eqZIndexMode :: Eq ZIndexMode
derive instance ordZIndexMode :: Ord ZIndexMode
derive instance genericZIndexMode :: Generic ZIndexMode _

instance showZIndexMode :: Show ZIndexMode where
  show = genericShow

instance boundedZIndexMode :: Bounded ZIndexMode where
  bottom = ZAuto
  top = ZManual

instance enumZIndexMode :: Enum ZIndexMode where
  succ = genericSucc
  pred = genericPred

instance boundedEnumZIndexMode :: BoundedEnum ZIndexMode where
  cardinality = Cardinality 3
  toEnum = genericToEnum
  fromEnum = genericFromEnum

data InterpolateMode = Smooth | Linear

derive instance eqInterpolateMode :: Eq InterpolateMode
derive instance ordInterpolateMode :: Ord InterpolateMode
derive instance genericInterpolateMode :: Generic InterpolateMode _

instance showInterpolateMode :: Show InterpolateMode where
  show = genericShow

instance boundedInterpolateMode :: Bounded InterpolateMode where
  bottom = Smooth
  top = Linear

instance enumInterpolateMode :: Enum InterpolateMode where
  succ = genericSucc
  pred = genericPred

instance boundedEnumInterpolateMode :: BoundedEnum InterpolateMode where
  cardinality = Cardinality 2
  toEnum = genericToEnum
  fromEnum = genericFromEnum

data KeyCode
  = SingleKey String
  | MultiKey (NonEmptyArray String)

derive instance eqKeyCode :: Eq KeyCode
derive instance ordKeyCode :: Ord KeyCode
derive instance genericKeyCode :: Generic KeyCode _

instance showKeyCode :: Show KeyCode where
  show = genericShow

data PaddingValue
  = PxPadding Number
  | PctPadding Number
  | RatioPadding Number

derive instance eqPaddingValue :: Eq PaddingValue
derive instance ordPaddingValue :: Ord PaddingValue
derive instance genericPaddingValue :: Generic PaddingValue _

instance showPaddingValue :: Show PaddingValue where
  show = genericShow

data Padding
  = UniformPadding PaddingValue
  | DirectionalPadding
      { top :: Maybe PaddingValue
      , right :: Maybe PaddingValue
      , bottom :: Maybe PaddingValue
      , left :: Maybe PaddingValue
      , x :: Maybe PaddingValue
      , y :: Maybe PaddingValue
      }

derive instance eqPadding :: Eq Padding
derive instance ordPadding :: Ord Padding
derive instance genericPadding :: Generic Padding _

instance showPadding :: Show Padding where
  show = genericShow

type ViewportHelperFunctionOptions =
  { duration :: Maybe Int
  , ease :: Maybe (Number -> Number)
  , interpolate :: Maybe InterpolateMode
  }

type SetCenterOptions =
  { duration :: Maybe Int
  , ease :: Maybe (Number -> Number)
  , interpolate :: Maybe InterpolateMode
  , zoom :: Maybe Number
  }

type FitBoundsOptions =
  { duration :: Maybe Int
  , ease :: Maybe (Number -> Number)
  , interpolate :: Maybe InterpolateMode
  , padding :: Maybe Number
  }

type ConnectionLookup = Map String (Map String HandleConnection)

type ConnectionInProgressData node =
  { isValid :: Maybe Boolean
  , from :: XYPosition
  , fromHandle :: Handle
  , fromPosition :: Position
  , fromNode :: node
  , to :: XYPosition
  , toHandle :: Maybe Handle
  , toPosition :: Position
  , toNode :: Maybe node
  , pointer :: XYPosition
  }

data ConnectionState node
  = NoConnection
  | ConnectionInProgress (ConnectionInProgressData node)

derive instance eqConnectionState :: Eq node => Eq (ConnectionState node)

noConnection :: forall node. ConnectionState node
noConnection = NoConnection

type FinalConnectionState node = Maybe (ConnectionInProgressData node)
