module System.Types.Edge
  ( EdgeBase
  , EdgeAriaLabel(..)
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
  , EdgePathOptions
  , EdgeReconnectable(..)
  , rememberUserEdge
  , originalUserEdge
  , edgeOwnsKey
  ) where

import Prelude

import Data.Enum (class BoundedEnum, class Enum, Cardinality(..))
import Data.Enum.Generic (genericFromEnum, genericPred, genericSucc, genericToEnum)
import Data.Generic.Rep (class Generic)
import Data.Function.Uncurried (Fn2)
import Data.Map (Map)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable)
import Data.Show.Generic (genericShow)
import Foreign (Foreign)
import Foreign.Object (Object)
import System.Types.Geometry (Position)
import System.Types.Handle (HandleType)
import System.Types.Ids (NodeId)
import System.Types.Opaque (Opaque)

-- | TS field `type` is renamed to `edgeType` for internal consistency with the
-- | `edgeTypes` lookup map it indexes into — *not* because `type` is unusable
-- | as a label: PureScript accepts it (`React.Types.Edges.EdgeProps` declares
-- | `type :: String`). Realigning this field with upstream behind a marshalling
-- | layer is ticket 072. `animated`, `hidden`, `selected`, `deletable`, and
-- | `selectable` are `Maybe Boolean`, because absence means something an
-- | explicit `false` doesn't: it's a key a consumer reads back as absent, and
-- | all but `selected` inherit from `defaultEdgeOptions` when they're absent,
-- | because upstream spreads it under the edge.
-- |
-- | `label` carries the string form PSFlow's built-in edge components already
-- | render. `className` (rendered on the edge `<g>`) and `style` (rendered on the
-- | `.react-flow__edge-path`) mirror the presentational fields carried by
-- | `NodeBase` (ticket 060). `style` is `Maybe (Object String)` — not `Foreign`
-- | — so the record keeps a derivable `Eq` for memoization/tests.
-- |
-- | `ariaLabel` holds three states. See `EdgeAriaLabel`.
-- |
-- | The ten fields after `style` are the rest of upstream's React `Edge`:
-- | `focusable`, `reconnectable`, `ariaRole` and `domAttributes`, the five
-- | label options `EdgeText` draws with, and the `pathOptions` the built-in
-- | bending edges read (upstream reads it with `'pathOptions' in edge`, off
-- | whichever built-in variant the edge is). `<EdgeWrapper />` reads each of
-- | them, and each one inherits from `defaultEdgeOptions` when it is absent.
type EdgeBase edgeData =
  { id :: String
  , edgeType :: Maybe String
  , source :: NodeId
  , target :: NodeId
  , sourceHandle :: Maybe String
  , targetHandle :: Maybe String
  , animated :: Maybe Boolean
  , hidden :: Maybe Boolean
  , deletable :: Maybe Boolean
  , selectable :: Maybe Boolean
  , data :: Maybe edgeData
  , selected :: Maybe Boolean
  , markerStart :: Maybe EdgeMarkerType
  , markerEnd :: Maybe EdgeMarkerType
  , zIndex :: Maybe Int
  , label :: Maybe String
  , ariaLabel :: Maybe EdgeAriaLabel
  , interactionWidth :: Maybe Number
  , className :: Maybe String
  , style :: Maybe (Object String)
  , focusable :: Maybe Boolean
  , reconnectable :: Maybe EdgeReconnectable
  , ariaRole :: Maybe String
  , domAttributes :: Maybe Opaque
  , labelStyle :: Maybe (Object String)
  , labelShowBg :: Maybe Boolean
  , labelBgStyle :: Maybe (Object String)
  , labelBgPadding :: Maybe { x :: Number, y :: Number }
  , labelBgBorderRadius :: Maybe Number
  , pathOptions :: Maybe EdgePathOptions
  }

-- | Upstream's `boolean | HandleType`. `false` is a value of its own, not an
-- | absent field: an edge's `reconnectable: false` overrides the flow's
-- | `edgesReconnectable`, where an absent one inherits it.
data EdgeReconnectable
  = ReconnectableFlag Boolean
  | ReconnectableEnd HandleType

derive instance eqEdgeReconnectable :: Eq EdgeReconnectable
derive instance genericEdgeReconnectable :: Generic EdgeReconnectable _
instance showEdgeReconnectable :: Show EdgeReconnectable where
  show = genericShow

-- | The union of the three built-in `pathOptions` records. An edge does not
-- | know which built-in will draw it until its `type` is resolved, and each
-- | variant reads only its own members: `curvature` for a bezier edge, and
-- | `offset`, `borderRadius` and `stepPosition` for the step variants.
type EdgePathOptions =
  { curvature :: Maybe Number
  , offset :: Maybe Number
  , borderRadius :: Maybe Number
  , stepPosition :: Maybe Number
  }

-- | The consumer's own edge object, kept beside the decoded record the way
-- | `System.Types.Node.rememberUserNode` keeps a node's. Upstream's store
-- | holds the consumer's objects, so a store read hands those back.
foreign import rememberUserEdge :: forall e. Fn2 Foreign (EdgeBase e) (EdgeBase e)
foreign import originalUserEdge :: forall e. EdgeBase e -> Nullable Foreign

-- | Whether the consumer's edge object, if there was one, has `key` as an own
-- | property. Upstream merges `{ ...defaultEdgeOptions, ...edge }`, and an
-- | edge written as `{ type: undefined }` owns `type`: the spread copies its
-- | `undefined` over the default. A decoded `Nothing` cannot say which of the
-- | two the consumer wrote, and this can. `key` is the consumer's spelling.
foreign import edgeOwnsKey :: forall e. String -> EdgeBase e -> Boolean

-- | An edge's `ariaLabel` when the consumer set one. `Nothing` on the field
-- | is an absent label.
-- |
-- | TS types it `ariaLabel?: string`, but `<EdgeWrapper />` also reads
-- | `null`: `edge.ariaLabel === null ? undefined : edge.ariaLabel || ...`.
-- | `null` renders no `aria-label`, and absence renders a default one, so a
-- | `Maybe String` can't hold both. `AriaLabelOff` is the consumer's `null`.
data EdgeAriaLabel
  = AriaLabelOff
  | AriaLabel String

derive instance eqEdgeAriaLabel :: Eq EdgeAriaLabel
derive instance genericEdgeAriaLabel :: Generic EdgeAriaLabel _
instance showEdgeAriaLabel :: Show EdgeAriaLabel where
  show = genericShow

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
