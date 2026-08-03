-- | React-layer node-prop aliases. The data structures themselves are
-- | defined once in `System.Types.Node`; this module re-exports them under
-- | the public names used by the upstream `@xyflow/react` API and adds
-- | React-only props (mouse handlers, wrapper props).
module React.Types.Nodes
  ( Node
  , InternalNode
  , NodeMouseHandler
  , NodeProps
  , SelectionDragHandler
  , OnNodeDrag
  , NodeWrapperProps
  , NodeTypesMap
  , ResizeObserver
  ) where

import Prelude

import Data.Maybe (Maybe)
import Effect (Effect)
import React.FFI.ResizeObserver (ResizeObserver) as RO
import System.Types.Geometry (CoordinateExtent, Position)
import System.Types.Node (InternalNodeBase, NodeBase, OnError)
import Web.UIEvent.MouseEvent (MouseEvent)

-- | The React-layer alias for `System.Types.Node.NodeBase`. Kept polymorphic
-- | in `n` (the user data row) to match the TS `Node<NodeData, NodeType>`.
type Node n = NodeBase n

-- | The React-layer alias for `System.Types.Node.InternalNodeBase`. Used
-- | inside the store (lookups, dragging, position-absolute resolution).
type InternalNode n = InternalNodeBase n

type NodeMouseHandler n = MouseEvent -> Node n -> Effect Unit

-- | Props passed into a user-supplied node component (and the built-in
-- | nodes in `React.Node.*`). Mirrors
-- | `xyflow-main/packages/react/src/types/nodes.ts NodeProps`.
-- |
-- | `data` is left polymorphic (`n`) so the user's data row is preserved
-- | end-to-end. Built-in node components instantiate this at
-- | `Foreign` and decode `.label` on render.
type NodeProps n =
  { id :: String
  , data :: n
  , width :: Maybe Number
  , height :: Maybe Number
  , sourcePosition :: Maybe Position
  , targetPosition :: Maybe Position
  , dragHandle :: Maybe String
  , parentId :: Maybe String
  , type :: String
  , dragging :: Boolean
  , zIndex :: Number
  , selectable :: Boolean
  , deletable :: Boolean
  , selected :: Boolean
  , draggable :: Boolean
  , isConnectable :: Boolean
  , positionAbsoluteX :: Number
  , positionAbsoluteY :: Number
  }

type SelectionDragHandler n = MouseEvent -> Array (Node n) -> Effect Unit

type OnNodeDrag n = MouseEvent -> Node n -> Array (Node n) -> Effect Unit

-- | Re-export of `React.FFI.ResizeObserver.ResizeObserver` (ticket 040).
-- | Shared `ResizeObserver` instance threaded by `NodeRenderer` into each
-- | `NodeWrapper` so all node measurements share one observer.
type ResizeObserver = RO.ResizeObserver

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
