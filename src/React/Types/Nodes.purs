-- | React-layer node-prop aliases. The data structures themselves are
-- | defined once in `System.Types.Node`; this module re-exports them under
-- | the public names used by the upstream `@xyflow/react` API and adds
-- | React-only props (mouse handlers, wrapper props).
module React.Types.Nodes
  ( Node
  , InternalNode
  , NodeMouseHandler
  , SelectionDragHandler
  , OnNodeDrag
  , NodeWrapperProps
  , NodeTypesMap
  , ResizeObserver
  ) where

import Prelude

import Data.Maybe (Maybe)
import Effect (Effect)
import System.Types.Geometry (CoordinateExtent)
import System.Types.Node (InternalNodeBase, NodeBase, OnError)
import Web.UIEvent.MouseEvent (MouseEvent)

-- | The React-layer alias for `System.Types.Node.NodeBase`. Kept polymorphic
-- | in `n` (the user data row) to match the TS `Node<NodeData, NodeType>`.
type Node n = NodeBase n

-- | The React-layer alias for `System.Types.Node.InternalNodeBase`. Used
-- | inside the store (lookups, dragging, position-absolute resolution).
type InternalNode n = InternalNodeBase n

type NodeMouseHandler n = MouseEvent -> Node n -> Effect Unit

type SelectionDragHandler n = MouseEvent -> Array (Node n) -> Effect Unit

type OnNodeDrag n = MouseEvent -> Node n -> Array (Node n) -> Effect Unit

-- | Opaque placeholder for the DOM `ResizeObserver`. The real binding lands
-- | with ticket 031 (`useNodeObserver`). Until then prop records only need a
-- | type to mention.
foreign import data ResizeObserver :: Type

-- | Opaque placeholder for `Record<string, ComponentType<NodeProps>>`. The
-- | renderer ticket (033) replaces it with a record of React components.
foreign import data NodeTypesMap :: Type

-- | Props for the internal `NodeWrapper` component. Mirrors
-- | `xyflow-main/packages/react/src/types/nodes.ts NodeWrapperProps`.
type NodeWrapperProps n =
  { id :: String
  , nodesConnectable :: Boolean
  , elementsSelectable :: Boolean
  , nodesDraggable :: Boolean
  , nodesFocusable :: Boolean
  , onClick :: Maybe (NodeMouseHandler n)
  , onDoubleClick :: Maybe (NodeMouseHandler n)
  , onMouseEnter :: Maybe (NodeMouseHandler n)
  , onMouseMove :: Maybe (NodeMouseHandler n)
  , onMouseLeave :: Maybe (NodeMouseHandler n)
  , onContextMenu :: Maybe (NodeMouseHandler n)
  , resizeObserver :: Maybe ResizeObserver
  , noDragClassName :: String
  , noPanClassName :: String
  , rfId :: String
  , disableKeyboardA11y :: Boolean
  , nodeTypes :: Maybe NodeTypesMap
  , nodeExtent :: Maybe CoordinateExtent
  , onError :: Maybe OnError
  , nodeClickDistance :: Maybe Number
  }
