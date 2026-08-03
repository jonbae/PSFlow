module System.Types.Edge
  ( EdgeBase
  , ConnectionLineType(..)
  , MarkerType(..)
  , EdgeMarker
  , EdgeMarkerType(..)
  , MarkerProps
  , EdgePosition
  , EdgeLookup
  , SmoothStepPathOptions
  , StepPathOptions
  , BezierPathOptions
  , EdgeToolbarBaseProps
  , AlignX(..)
  , AlignY(..)
  , EdgeChange(..)
  ) where

import Prelude

import Data.Enum (class BoundedEnum, class Enum, Cardinality(..))
import Data.Enum.Generic (genericFromEnum, genericPred, genericSucc, genericToEnum)
import Data.Generic.Rep (class Generic)
import Data.Map (Map)
import Data.Maybe (Maybe)
import Data.Show.Generic (genericShow)
import Foreign.Object (Object)
import System.Types.Geometry (Position)
import System.Types.Ids (NodeId)

-- | TS field `type` is renamed to `edgeType` for internal consistency with the
-- | `edgeTypes` lookup map it indexes into — *not* because `type` is unusable
-- | as a label: PureScript accepts it (`React.Types.Edges.EdgeProps` declares
-- | `type :: String`). Realigning this field with upstream behind a marshalling
-- | layer is ticket 072. `animated`, `hidden`, `selected`
-- | have a clear `false` default and are plain `Boolean`. `deletable` and
-- | `selectable` keep their tri-state `Maybe Boolean` because absence means
-- | "inherit from store default".
-- |
-- | `className` (rendered on the edge `<g>`) and `style` (rendered on the
-- | `.react-flow__edge-path`) mirror the presentational fields carried by
-- | `NodeBase` (ticket 060). `style` is `Maybe (Object String)` — not `Foreign`
-- | — so the record keeps a derivable `Eq` for memoization/tests.
type EdgeBase edgeData =
  { id :: String
  , edgeType :: Maybe String
  , source :: NodeId
  , target :: NodeId
  , sourceHandle :: Maybe String
  , targetHandle :: Maybe String
  , animated :: Boolean
  , hidden :: Boolean
  , deletable :: Maybe Boolean
  , selectable :: Maybe Boolean
  , data :: Maybe edgeData
  , selected :: Boolean
  , markerStart :: Maybe EdgeMarkerType
  , markerEnd :: Maybe EdgeMarkerType
  , zIndex :: Maybe Int
  , ariaLabel :: Maybe String
  , interactionWidth :: Maybe Number
  , className :: Maybe String
  , style :: Maybe (Object String)
  }

data ConnectionLineType
  = BezierLine
  | StraightLine
  | StepLine
  | SmoothStepLine
  | SimpleBezierLine

derive instance eqConnectionLineType :: Eq ConnectionLineType
derive instance ordConnectionLineType :: Ord ConnectionLineType
derive instance genericConnectionLineType :: Generic ConnectionLineType _

instance showConnectionLineType :: Show ConnectionLineType where
  show = genericShow

instance boundedConnectionLineType :: Bounded ConnectionLineType where
  bottom = BezierLine
  top = SimpleBezierLine

instance enumConnectionLineType :: Enum ConnectionLineType where
  succ = genericSucc
  pred = genericPred

instance boundedEnumConnectionLineType :: BoundedEnum ConnectionLineType where
  cardinality = Cardinality 5
  toEnum = genericToEnum
  fromEnum = genericFromEnum

data MarkerType = Arrow | ArrowClosed

derive instance eqMarkerType :: Eq MarkerType
derive instance ordMarkerType :: Ord MarkerType
derive instance genericMarkerType :: Generic MarkerType _

instance showMarkerType :: Show MarkerType where
  show = genericShow

instance boundedMarkerType :: Bounded MarkerType where
  bottom = Arrow
  top = ArrowClosed

instance enumMarkerType :: Enum MarkerType where
  succ = genericSucc
  pred = genericPred

instance boundedEnumMarkerType :: BoundedEnum MarkerType where
  cardinality = Cardinality 2
  toEnum = genericToEnum
  fromEnum = genericFromEnum

-- | TS field `type` is renamed to `markerType`.
type EdgeMarker =
  { markerType :: MarkerType
  , color :: Maybe String
  , width :: Maybe Number
  , height :: Maybe Number
  , markerUnits :: Maybe String
  , orient :: Maybe String
  , strokeWidth :: Maybe Number
  }

-- | TS `string | EdgeMarker` becomes a tagged sum: `NamedMarker` references a
-- | built-in marker by id; `CustomMarker` carries a full configuration.
data EdgeMarkerType
  = NamedMarker String
  | CustomMarker EdgeMarker

derive instance eqEdgeMarkerType :: Eq EdgeMarkerType

-- | Flat record; the TS `EdgeMarker & { id }` intersection becomes explicit
-- | fields.
type MarkerProps =
  { id :: String
  , markerType :: MarkerType
  , color :: Maybe String
  , width :: Maybe Number
  , height :: Maybe Number
  , markerUnits :: Maybe String
  , orient :: Maybe String
  , strokeWidth :: Maybe Number
  }

type EdgePosition =
  { sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  , sourcePosition :: Position
  , targetPosition :: Position
  }

type EdgeLookup edgeData = Map String (EdgeBase edgeData)

type SmoothStepPathOptions =
  { offset :: Maybe Number
  , borderRadius :: Maybe Number
  , stepPosition :: Maybe Number
  }

type StepPathOptions = { offset :: Maybe Number }

type BezierPathOptions = { curvature :: Maybe Number }

type EdgeToolbarBaseProps =
  { x :: Number
  , y :: Number
  , isVisible :: Boolean
  , alignX :: AlignX
  , alignY :: AlignY
  }

data AlignX = AlignXLeft | AlignXCenter | AlignXRight

derive instance eqAlignX :: Eq AlignX
derive instance ordAlignX :: Ord AlignX
derive instance genericAlignX :: Generic AlignX _

instance showAlignX :: Show AlignX where
  show = genericShow

instance boundedAlignX :: Bounded AlignX where
  bottom = AlignXLeft
  top = AlignXRight

instance enumAlignX :: Enum AlignX where
  succ = genericSucc
  pred = genericPred

instance boundedEnumAlignX :: BoundedEnum AlignX where
  cardinality = Cardinality 3
  toEnum = genericToEnum
  fromEnum = genericFromEnum

data AlignY = AlignYTop | AlignYCenter | AlignYBottom

derive instance eqAlignY :: Eq AlignY
derive instance ordAlignY :: Ord AlignY
derive instance genericAlignY :: Generic AlignY _

instance showAlignY :: Show AlignY where
  show = genericShow

instance boundedAlignY :: Bounded AlignY where
  bottom = AlignYTop
  top = AlignYBottom

instance enumAlignY :: Enum AlignY where
  succ = genericSucc
  pred = genericPred

instance boundedEnumAlignY :: BoundedEnum AlignY where
  cardinality = Cardinality 3
  toEnum = genericToEnum
  fromEnum = genericFromEnum

-- | Constructors are duplicated rather than reused from `NodeChange` to keep
-- | the nominal sum types separate.
data EdgeChange edgeData
  = EdgeSelectionChange
      { id :: String
      , selected :: Boolean
      }
  | EdgeRemoveChange
      { id :: String }
  | EdgeAddChange
      { item :: EdgeBase edgeData
      , index :: Maybe Int
      }
  | EdgeReplaceChange
      { id :: String
      , item :: EdgeBase edgeData
      }
