module System.Types.Handle
  ( HandleType(..)
  , Handle
  , SourceHandle(..)
  , TargetHandle(..)
  , mkSourceHandle
  , mkTargetHandle
  , unSourceHandle
  , unTargetHandle
  , HandleProps
  , defaultHandleProps
  ) where

import Prelude

import Data.Enum (class BoundedEnum, class Enum, Cardinality(..))
import Data.Enum.Generic (genericFromEnum, genericPred, genericSucc, genericToEnum)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import System.Types.Geometry (Position(..))

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

-- | A `Handle` whose value-level `handleType` has been verified to be
-- | `Source`. Lets connection-validation signatures encode the
-- | source-vs-target distinction at the type level instead of as a
-- | runtime branch.
newtype SourceHandle = SourceHandle Handle

derive newtype instance eqSourceHandle :: Eq SourceHandle
derive newtype instance showSourceHandle :: Show SourceHandle

-- | A `Handle` whose value-level `handleType` has been verified to be
-- | `Target`.
newtype TargetHandle = TargetHandle Handle

derive newtype instance eqTargetHandle :: Eq TargetHandle
derive newtype instance showTargetHandle :: Show TargetHandle

mkSourceHandle :: Handle -> Maybe SourceHandle
mkSourceHandle h = case h.handleType of
  Source -> Just (SourceHandle h)
  Target -> Nothing

mkTargetHandle :: Handle -> Maybe TargetHandle
mkTargetHandle h = case h.handleType of
  Target -> Just (TargetHandle h)
  Source -> Nothing

unSourceHandle :: SourceHandle -> Handle
unSourceHandle (SourceHandle h) = h

unTargetHandle :: TargetHandle -> Handle
unTargetHandle (TargetHandle h) = h

-- | `validate` is the type of the `isValidConnection` callback. The
-- | downstream React layer specialises it to `IsValidConnection` from
-- | `System.Types.Connection`. Parameterising here breaks the otherwise
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
