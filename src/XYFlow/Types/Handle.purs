module XYFlow.Types.Handle
  ( HandleType(..)
  , Handle
  , HandleProps
  , defaultHandleProps
  ) where

import Prelude

import Data.Enum (class BoundedEnum, class Enum, Cardinality(..))
import Data.Enum.Generic (genericFromEnum, genericPred, genericSucc, genericToEnum)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import XYFlow.Types.Geometry (Position(..))

data HandleType
  = Source
  | Target

derive instance eqHandleType :: Eq HandleType
derive instance ordHandleType :: Ord HandleType
derive instance genericHandleType :: Generic HandleType _

instance showHandleType :: Show HandleType where
  show = genericShow

instance boundedHandleType :: Bounded HandleType where
  bottom = Source
  top = Target

instance enumHandleType :: Enum HandleType where
  succ = genericSucc
  pred = genericPred

instance boundedEnumHandleType :: BoundedEnum HandleType where
  cardinality = Cardinality 2
  toEnum = genericToEnum
  fromEnum = genericFromEnum

-- | The TS field `type` is renamed to `handleType` because `type` is a
-- | PureScript keyword. All other fields match the TS shape.
type Handle =
  { id :: Maybe String
  , nodeId :: String
  , x :: Number
  , y :: Number
  , position :: Position
  , handleType :: HandleType
  , width :: Number
  , height :: Number
  }

-- | `validate` is the type of the `isValidConnection` callback. The
-- | downstream React layer specialises it to `IsValidConnection` from
-- | `XYFlow.Types.Connection`. Parameterising here breaks the otherwise
-- | mutual-import cycle between the Handle and Connection modules.
type HandleProps validate =
  { handleType :: HandleType
  , position :: Position
  , isConnectable :: Boolean
  , isConnectableStart :: Boolean
  , isConnectableEnd :: Boolean
  , isValidConnection :: Maybe validate
  , id :: Maybe String
  }

defaultHandleProps :: forall v. HandleProps v
defaultHandleProps =
  { handleType: Source
  , position: PosTop
  , isConnectable: true
  , isConnectableStart: true
  , isConnectableEnd: true
  , isValidConnection: Nothing
  , id: Nothing
  }
