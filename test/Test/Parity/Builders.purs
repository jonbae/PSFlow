-- | Builders for the PSFlow-side node and edge values the parity properties
-- | run through. Deliberately not called fixtures: a **fixture** in this repo
-- | is a flow definition both implementations import and holds no code, and
-- | this is PSFlow-only code.
-- |
-- | `NodeBase` is thirty fields and `EdgeBase` seventeen, of which any one
-- | property reads a handful; these builders fill in the rest once so a
-- | property can say what it varies by record-updating what it got back. They
-- | live in their own module because three parity modules need them and a
-- | second copy is a second thing to drift.
-- |
-- | Nothing here is XYFlow-shaped — that translation is `Test.Oracle`'s. These
-- | are PSFlow values, and a property builds its oracle argument from the same
-- | generated description rather than from these.
module Test.Parity.Builders
  ( mkNode
  , mkEdge
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import System.Types.Edge (EdgeBase)
import System.Types.Ids (NodeId(..))
import System.Types.Node (NodeBase)

-- | A node at the origin, measured 50×25 — dimensions that matter only to the
-- | bounds properties, which override them.
mkNode :: String -> NodeBase Unit
mkNode nid =
  { id: NodeId nid
  , position: { x: 0.0, y: 0.0 }
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: false
  , selected: false
  , dragging: false
  , draggable: Nothing
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Just 50.0
  , height: Just 25.0
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: false
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Just 50.0, height: Just 25.0 }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

mkEdge :: String -> String -> String -> EdgeBase Unit
mkEdge eid src tgt =
  { id: eid
  , edgeType: Nothing
  , source: NodeId src
  , target: NodeId tgt
  , sourceHandle: Nothing
  , targetHandle: Nothing
  , animated: false
  , hidden: false
  , deletable: Nothing
  , selectable: Nothing
  , data: Nothing
  , selected: false
  , markerStart: Nothing
  , markerEnd: Nothing
  , zIndex: Nothing
  , label: Nothing
  , ariaLabel: Nothing
  , interactionWidth: Nothing
  , className: Nothing
  , style: Nothing
  }
