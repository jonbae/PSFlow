module XYFlow.Types.Node
  ( NodeBase
  , InternalNodeBase
  , NodeInternals
  , NodeHandleBounds
  , NodeBounds
  , NodeDragItem
  , NodeProps
  , NodeHandle
  , NodeExtent(..)
  , Align(..)
  , NodeLookup
  , ParentLookup
  , SetAttributesMode(..)
  , NodeChange(..)
  , InternalNodeUpdate
  , OnError
  , ParentExpandChild
  ) where

import Prelude

import Data.Enum (class BoundedEnum, class Enum, Cardinality(..))
import Data.Enum.Generic (genericFromEnum, genericPred, genericSucc, genericToEnum)
import Data.Generic.Rep (class Generic)
import Data.Map (Map)
import Data.Maybe (Maybe)
import Data.Show.Generic (genericShow)
import Effect (Effect)
import Web.HTML.HTMLDivElement (HTMLDivElement)
import XYFlow.Types.Geometry
  ( CoordinateExtent
  , Dimensions
  , NodeOrigin
  , Position
  , Rect
  , XYPosition
  )
import XYFlow.Types.Handle (Handle, HandleType)

-- | TS field `type` is renamed to `nodeType` because `type` is a PureScript
-- | keyword. The type tag is a runtime string (`Maybe String`) rather than a
-- | phantom type since node types are user-defined runtime values.
type NodeBase nodeData =
  { id :: String
  , position :: XYPosition
  , data :: nodeData
  , sourcePosition :: Maybe Position
  , targetPosition :: Maybe Position
  , hidden :: Boolean
  , selected :: Boolean
  , dragging :: Boolean
  , draggable :: Maybe Boolean
  , selectable :: Maybe Boolean
  , connectable :: Maybe Boolean
  , deletable :: Maybe Boolean
  , dragHandle :: Maybe String
  , width :: Maybe Number
  , height :: Maybe Number
  , initialWidth :: Maybe Number
  , initialHeight :: Maybe Number
  , parentId :: Maybe String
  , zIndex :: Maybe Int
  , extent :: Maybe NodeExtent
  , expandParent :: Boolean
  , ariaLabel :: Maybe String
  , origin :: Maybe NodeOrigin
  , handles :: Maybe (Array NodeHandle)
  , measured :: { width :: Maybe Number, height :: Maybe Number }
  , nodeType :: Maybe String
  }

-- | The TS reference-equality `userNode` field is intentionally omitted —
-- | PureScript has no reference equality. Functions that need the original
-- | user node should accept it as a separate parameter.
type NodeInternals =
  { positionAbsolute :: XYPosition
  , z :: Number
  , rootParentIndex :: Maybe Int
  , handleBounds :: Maybe NodeHandleBounds
  , bounds :: Maybe NodeBounds
  }

-- | Flat record duplicating all `NodeBase` fields plus `internals`.
-- | Modeled as a flat record (not a row-extension of `NodeBase`) so consumers
-- | aren't forced into row-polymorphic signatures.
type InternalNodeBase nodeData =
  { id :: String
  , position :: XYPosition
  , data :: nodeData
  , sourcePosition :: Maybe Position
  , targetPosition :: Maybe Position
  , hidden :: Boolean
  , selected :: Boolean
  , dragging :: Boolean
  , draggable :: Maybe Boolean
  , selectable :: Maybe Boolean
  , connectable :: Maybe Boolean
  , deletable :: Maybe Boolean
  , dragHandle :: Maybe String
  , width :: Maybe Number
  , height :: Maybe Number
  , initialWidth :: Maybe Number
  , initialHeight :: Maybe Number
  , parentId :: Maybe String
  , zIndex :: Maybe Int
  , extent :: Maybe NodeExtent
  , expandParent :: Boolean
  , ariaLabel :: Maybe String
  , origin :: Maybe NodeOrigin
  , handles :: Maybe (Array NodeHandle)
  , measured :: { width :: Maybe Number, height :: Maybe Number }
  , nodeType :: Maybe String
  , internals :: NodeInternals
  }

-- | Source/target handle bounds. The outer optionality on `NodeHandleBounds`
-- | itself (`Maybe NodeHandleBounds`) carries the "not yet parsed"
-- | distinction; the inner arrays use the empty case for "parsed, no
-- | handles of this side". Three nesting levels of optionality collapsed
-- | to one.
type NodeHandleBounds =
  { source :: Array Handle
  , target :: Array Handle
  }

type NodeBounds =
  { x :: Number
  , y :: Number
  , width :: Maybe Number
  , height :: Maybe Number
  }

type NodeDragItem =
  { id :: String
  , position :: XYPosition
  , distance :: XYPosition
  , measured :: { width :: Number, height :: Number }
  , internals :: { positionAbsolute :: XYPosition }
  , extent :: Maybe NodeExtent
  , parentId :: Maybe String
  , origin :: Maybe NodeOrigin
  , expandParent :: Boolean
  , dragging :: Boolean
  }

type NodeProps nodeData =
  { id :: String
  , data :: nodeData
  , width :: Maybe Number
  , height :: Maybe Number
  , sourcePosition :: Maybe Position
  , targetPosition :: Maybe Position
  , dragHandle :: Maybe String
  , parentId :: Maybe String
  , nodeType :: String
  , dragging :: Boolean
  , zIndex :: Int
  , selectable :: Boolean
  , deletable :: Boolean
  , selected :: Boolean
  , draggable :: Boolean
  , isConnectable :: Boolean
  , positionAbsoluteX :: Number
  , positionAbsoluteY :: Number
  }

-- | `Handle` minus `nodeId`, with `width`/`height` made optional.
type NodeHandle =
  { id :: Maybe String
  , x :: Number
  , y :: Number
  , position :: Position
  , handleType :: HandleType
  , width :: Maybe Number
  , height :: Maybe Number
  }

data NodeExtent
  = ParentExtent
  | CoordExtent CoordinateExtent

derive instance eqNodeExtent :: Eq NodeExtent
derive instance genericNodeExtent :: Generic NodeExtent _

instance showNodeExtent :: Show NodeExtent where
  show = genericShow

data Align = AlignCenter | AlignStart | AlignEnd

derive instance eqAlign :: Eq Align
derive instance ordAlign :: Ord Align
derive instance genericAlign :: Generic Align _

instance showAlign :: Show Align where
  show = genericShow

instance boundedAlign :: Bounded Align where
  bottom = AlignCenter
  top = AlignEnd

instance enumAlign :: Enum Align where
  succ = genericSucc
  pred = genericPred

instance boundedEnumAlign :: BoundedEnum Align where
  cardinality = Cardinality 3
  toEnum = genericToEnum
  fromEnum = genericFromEnum

type NodeLookup nodeData = Map String (InternalNodeBase nodeData)

type ParentLookup nodeData = Map String (Map String (InternalNodeBase nodeData))

-- | TS `boolean | 'width' | 'height'` is a 4-value type. Constructors are
-- | named to make intent explicit.
data SetAttributesMode
  = SetBothDimensions
  | SetWidthOnly
  | SetHeightOnly
  | NoSetAttributes

derive instance eqSetAttributesMode :: Eq SetAttributesMode
derive instance ordSetAttributesMode :: Ord SetAttributesMode
derive instance genericSetAttributesMode :: Generic SetAttributesMode _

instance showSetAttributesMode :: Show SetAttributesMode where
  show = genericShow

instance boundedSetAttributesMode :: Bounded SetAttributesMode where
  bottom = SetBothDimensions
  top = NoSetAttributes

instance enumSetAttributesMode :: Enum SetAttributesMode where
  succ = genericSucc
  pred = genericPred

instance boundedEnumSetAttributesMode :: BoundedEnum SetAttributesMode where
  cardinality = Cardinality 4
  toEnum = genericToEnum
  fromEnum = genericFromEnum

-- | The TS `type: 'dimensions' | 'position' | ...` discriminant disappears —
-- | the constructor is the tag.
data NodeChange nodeData
  = NodeDimensionChange
      { id :: String
      , dimensions :: Maybe Dimensions
      , resizing :: Boolean
      , setAttributes :: SetAttributesMode
      }
  | NodePositionChange
      { id :: String
      , position :: Maybe XYPosition
      , positionAbsolute :: Maybe XYPosition
      , dragging :: Boolean
      }
  | NodeSelectionChange
      { id :: String
      , selected :: Boolean
      }
  | NodeRemoveChange
      { id :: String }
  | NodeAddChange
      { item :: NodeBase nodeData
      , index :: Maybe Int
      }
  | NodeReplaceChange
      { id :: String
      , item :: NodeBase nodeData
      }

-- | Used by the store reconciliation pipeline to push a measured DOM element
-- | back into a node. `force` opts out of the dimension-equality short-circuit.
type InternalNodeUpdate =
  { id :: String
  , nodeElement :: HTMLDivElement
  , force :: Boolean
  }

-- | Error reporting callback. Maps the TS `OnError = (id, msg) => void` to
-- | a curried `Effect`-returning function. Callers wrap in `Maybe` when the
-- | callback is optional.
type OnError = String -> String -> Effect Unit

-- | Records that a child node has expanded its parent. Consumed by
-- | `handleExpandParent` and produced by `updateNodeInternals`.
type ParentExpandChild =
  { id :: String
  , parentId :: String
  , rect :: Rect
  }
