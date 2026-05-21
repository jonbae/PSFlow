-- | React-layer edge type aliases and prop records. The edge data structure
-- | itself comes from `System.Types.Edge`; this module surfaces the same
-- | name `Edge` (mirroring upstream `@xyflow/react`) and adds React-only
-- | prop bundles (event handlers, base-edge SVG path props, per-variant
-- | edge props).
module React.Types.Edges
  ( Edge
  , EdgeMouseHandler
  , EdgeLabelOptions
  , DefaultEdgeOptions
  , EdgeWrapperProps
  , EdgeTypesMap
  , OnReconnect
  , ReconnectHandleType(..)
  , EdgeProps
  , BaseEdgeProps
  , EdgeComponentProps
  , BezierEdgeProps
  , SmoothStepEdgeProps
  , StepEdgeProps
  , StraightEdgeProps
  , SimpleBezierEdgeProps
  , EdgeTextProps
  , ConnectionLineComponentProps
  , ConnectionStatus(..)
  , PathOptions
  , Style
  ) where

import Prelude

import Data.Maybe (Maybe)
import Effect (Effect)
import React.Types.Nodes (InternalNode)
import System.Types.Connection (Connection, FinalConnectionState)
import System.Types.Edge
  ( BezierPathOptions
  , ConnectionLineType
  , EdgeBase
  , SmoothStepPathOptions
  , StepPathOptions
  )
import System.Types.Geometry (Position, XYPosition)
import System.Types.Handle (Handle, HandleType)
import System.Types.Node (InternalNodeBase, OnError)
import Web.UIEvent.MouseEvent (MouseEvent)

-- | The React-layer alias for `System.Types.Edge.EdgeBase`. Polymorphic in
-- | the user data row to match the TS `Edge<EdgeData, EdgeType>`.
type Edge e = EdgeBase e

type EdgeMouseHandler e = MouseEvent -> Edge e -> Effect Unit

-- | Opaque CSS-style placeholder. The React-renderer ticket will replace
-- | this with a `CSSProperties` foreign type from `react-basic`.
foreign import data Style :: Type

-- | Label-related options that show up on edges, EdgeText, and BaseEdge.
type EdgeLabelOptions =
  { label :: Maybe String
  , labelStyle :: Maybe Style
  , labelShowBg :: Maybe Boolean
  , labelBgStyle :: Maybe Style
  , labelBgPadding :: Maybe { x :: Number, y :: Number }
  , labelBgBorderRadius :: Maybe Number
  }

-- | TS allows `boolean | HandleType` — we encode the boolean side as
-- | `ReconnectAny` (true) / absence-of-key (false).
data ReconnectHandleType = ReconnectAny | ReconnectOnly HandleType

derive instance eqReconnectHandleType :: Eq ReconnectHandleType
derive instance ordReconnectHandleType :: Ord ReconnectHandleType

type OnReconnect e = Edge e -> Connection -> Effect Unit

type DefaultEdgeOptions e =
  { animated :: Maybe Boolean
  , hidden :: Maybe Boolean
  , deletable :: Maybe Boolean
  , selectable :: Maybe Boolean
  , focusable :: Maybe Boolean
  , data :: Maybe e
  , zIndex :: Maybe Int
  , ariaLabel :: Maybe String
  , interactionWidth :: Maybe Number
  , reconnectable :: Maybe ReconnectHandleType
  }

-- | Opaque placeholder for `Record<string, ComponentType<EdgeProps>>`.
foreign import data EdgeTypesMap :: Type

type EdgeWrapperProps n e =
  { id :: String
  , edgesFocusable :: Boolean
  , edgesReconnectable :: Boolean
  , elementsSelectable :: Boolean
  , noPanClassName :: String
  , onClick :: Maybe (EdgeMouseHandler e)
  , onDoubleClick :: Maybe (EdgeMouseHandler e)
  , onReconnect :: Maybe (OnReconnect e)
  , onContextMenu :: Maybe (EdgeMouseHandler e)
  , onMouseEnter :: Maybe (EdgeMouseHandler e)
  , onMouseMove :: Maybe (EdgeMouseHandler e)
  , onMouseLeave :: Maybe (EdgeMouseHandler e)
  , reconnectRadius :: Maybe Number
  , onReconnectStart :: Maybe (MouseEvent -> Edge e -> HandleType -> Effect Unit)
  , onReconnectEnd ::
      Maybe
        ( MouseEvent
        -> Edge e
        -> HandleType
        -> FinalConnectionState (InternalNodeBase n)
        -> Effect Unit
        )
  , rfId :: Maybe String
  , edgeTypes :: Maybe EdgeTypesMap
  , onError :: Maybe OnError
  , disableKeyboardA11y :: Maybe Boolean
  }

-- | Opaque per-variant edge path options. The TS source uses a union but
-- | individual edges typically carry one of `BezierPathOptions`,
-- | `SmoothStepPathOptions`, or `StepPathOptions`. Kept opaque on the
-- | generic `EdgeProps` record; the per-variant records below use the
-- | concrete System types.
foreign import data PathOptions :: Type

type EdgeProps e =
  { id :: String
  , edgeType :: Maybe String
  , animated :: Boolean
  , data :: Maybe e
  , style :: Maybe Style
  , selected :: Boolean
  , source :: String
  , target :: String
  , selectable :: Maybe Boolean
  , deletable :: Maybe Boolean
  , sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  , sourcePosition :: Position
  , targetPosition :: Position
  , label :: Maybe String
  , labelStyle :: Maybe Style
  , labelShowBg :: Maybe Boolean
  , labelBgStyle :: Maybe Style
  , labelBgPadding :: Maybe { x :: Number, y :: Number }
  , labelBgBorderRadius :: Maybe Number
  , sourceHandleId :: Maybe String
  , targetHandleId :: Maybe String
  , markerStart :: Maybe String
  , markerEnd :: Maybe String
  , pathOptions :: Maybe PathOptions
  , interactionWidth :: Maybe Number
  }

type BaseEdgeProps =
  { id :: Maybe String
  , path :: String
  , labelX :: Maybe Number
  , labelY :: Maybe Number
  , label :: Maybe String
  , labelStyle :: Maybe Style
  , labelShowBg :: Maybe Boolean
  , labelBgStyle :: Maybe Style
  , labelBgPadding :: Maybe { x :: Number, y :: Number }
  , labelBgBorderRadius :: Maybe Number
  , style :: Maybe Style
  , markerEnd :: Maybe String
  , markerStart :: Maybe String
  , interactionWidth :: Maybe Number
  , className :: Maybe String
  }

type EdgeComponentProps =
  { id :: Maybe String
  , sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  , sourcePosition :: Position
  , targetPosition :: Position
  , markerStart :: Maybe String
  , markerEnd :: Maybe String
  , interactionWidth :: Maybe Number
  , style :: Maybe Style
  , sourceHandleId :: Maybe String
  , targetHandleId :: Maybe String
  , label :: Maybe String
  , labelStyle :: Maybe Style
  , labelShowBg :: Maybe Boolean
  , labelBgStyle :: Maybe Style
  , labelBgPadding :: Maybe { x :: Number, y :: Number }
  , labelBgBorderRadius :: Maybe Number
  }

type BezierEdgeProps =
  { id :: Maybe String
  , sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  , sourcePosition :: Position
  , targetPosition :: Position
  , markerStart :: Maybe String
  , markerEnd :: Maybe String
  , interactionWidth :: Maybe Number
  , style :: Maybe Style
  , sourceHandleId :: Maybe String
  , targetHandleId :: Maybe String
  , label :: Maybe String
  , labelStyle :: Maybe Style
  , labelShowBg :: Maybe Boolean
  , labelBgStyle :: Maybe Style
  , labelBgPadding :: Maybe { x :: Number, y :: Number }
  , labelBgBorderRadius :: Maybe Number
  , pathOptions :: Maybe BezierPathOptions
  }

type SmoothStepEdgeProps =
  { id :: Maybe String
  , sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  , sourcePosition :: Position
  , targetPosition :: Position
  , markerStart :: Maybe String
  , markerEnd :: Maybe String
  , interactionWidth :: Maybe Number
  , style :: Maybe Style
  , sourceHandleId :: Maybe String
  , targetHandleId :: Maybe String
  , label :: Maybe String
  , labelStyle :: Maybe Style
  , labelShowBg :: Maybe Boolean
  , labelBgStyle :: Maybe Style
  , labelBgPadding :: Maybe { x :: Number, y :: Number }
  , labelBgBorderRadius :: Maybe Number
  , pathOptions :: Maybe SmoothStepPathOptions
  }

type StepEdgeProps =
  { id :: Maybe String
  , sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  , sourcePosition :: Position
  , targetPosition :: Position
  , markerStart :: Maybe String
  , markerEnd :: Maybe String
  , interactionWidth :: Maybe Number
  , style :: Maybe Style
  , sourceHandleId :: Maybe String
  , targetHandleId :: Maybe String
  , label :: Maybe String
  , labelStyle :: Maybe Style
  , labelShowBg :: Maybe Boolean
  , labelBgStyle :: Maybe Style
  , labelBgPadding :: Maybe { x :: Number, y :: Number }
  , labelBgBorderRadius :: Maybe Number
  , pathOptions :: Maybe StepPathOptions
  }

type StraightEdgeProps =
  { id :: Maybe String
  , sourceX :: Number
  , sourceY :: Number
  , targetX :: Number
  , targetY :: Number
  , markerStart :: Maybe String
  , markerEnd :: Maybe String
  , interactionWidth :: Maybe Number
  , style :: Maybe Style
  , sourceHandleId :: Maybe String
  , targetHandleId :: Maybe String
  , label :: Maybe String
  , labelStyle :: Maybe Style
  , labelShowBg :: Maybe Boolean
  , labelBgStyle :: Maybe Style
  , labelBgPadding :: Maybe { x :: Number, y :: Number }
  , labelBgBorderRadius :: Maybe Number
  }

type SimpleBezierEdgeProps = EdgeComponentProps

type EdgeTextProps =
  { x :: Number
  , y :: Number
  , label :: Maybe String
  , labelStyle :: Maybe Style
  , labelShowBg :: Maybe Boolean
  , labelBgStyle :: Maybe Style
  , labelBgPadding :: Maybe { x :: Number, y :: Number }
  , labelBgBorderRadius :: Maybe Number
  }

-- | Connection validity tag shown on the connection-line during drag.
data ConnectionStatus = ConnectionValid | ConnectionInvalid

derive instance eqConnectionStatus :: Eq ConnectionStatus
derive instance ordConnectionStatus :: Ord ConnectionStatus

instance showConnectionStatus :: Show ConnectionStatus where
  show ConnectionValid = "valid"
  show ConnectionInvalid = "invalid"

type ConnectionLineComponentProps n =
  { connectionLineStyle :: Maybe Style
  , connectionLineType :: ConnectionLineType
  , fromNode :: InternalNode n
  , fromHandle :: Handle
  , fromX :: Number
  , fromY :: Number
  , toX :: Number
  , toY :: Number
  , fromPosition :: Position
  , toPosition :: Position
  , connectionStatus :: Maybe ConnectionStatus
  , toNode :: Maybe (InternalNode n)
  , toHandle :: Maybe Handle
  , pointer :: XYPosition
  }
