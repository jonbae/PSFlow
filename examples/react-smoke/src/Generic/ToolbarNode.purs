-- | Port of xyflow's generic-test `ToolbarNode`
-- | (`xyflow/examples/react/src/generic-tests/node-toolbar/components/ToolbarNode.tsx`):
-- | a default-styled node that renders a `<NodeToolbar>` (three buttons) plus a
-- | left target `Handle` and a right source `Handle`. The toolbar's
-- | visibility/position/align come from the node's `data` payload.
-- |
-- | `data` is read back from the opaque `NodeProps Foreign` via `unsafeCoerce`;
-- | the `node-toolbar/general` fixture stores this exact `ToolbarData` record on
-- | each node (see `Generic.Fixture`), so the coercion is total. Component
-- | pattern: `React.Node.Default` (built-in default node) + `DragHandleNode`.
module Generic.ToolbarNode
  ( ToolbarData
  , toolbarNode
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Additional.NodeToolbar (nodeToolbar)
import React.Basic (JSX, ReactComponent, element, fragment)
import React.Basic.Hooks (reactChildrenFromArray, reactComponent)
import React.FFI.DOM (button_, div_, textContent)
import React.Handle (handle)
import React.Types.Nodes (NodeProps)
import System.Types.Geometry (Position(..))
import System.Types.Handle (HandleType(..))
import System.Types.Node (Align)
import Unsafe.Coerce (unsafeCoerce)

-- | The `data` payload every ToolbarNode fixture node carries. Mirrors the
-- | upstream `data` shape (`label`/`toolbarPosition`/`toolbarAlign`/
-- | `toolbarVisible`). `toolbarAlign`/`toolbarVisible` are `Maybe` so the
-- | `default-node` (toolbar shown only on selection) can leave them `Nothing`.
type ToolbarData =
  { label :: String
  , toolbarPosition :: Position
  , toolbarAlign :: Maybe Align
  , toolbarVisible :: Maybe Boolean
  }

toolbarNode :: ReactComponent (NodeProps Foreign)
toolbarNode = unsafePerformEffect $ reactComponent "ToolbarNode" \(props :: NodeProps Foreign) ->
  pure $
    let
      d = (unsafeCoerce props.data) :: ToolbarData

      btn :: String -> JSX
      btn label = button_ {} [ textContent label ]

      toolbar :: JSX
      toolbar = element nodeToolbar
        { nodeId: Nothing
        , isVisible: d.toolbarVisible
        , position: Just d.toolbarPosition
        , offset: Nothing
        , align: d.toolbarAlign
        , style: Nothing
        , className: Nothing
        , children: reactChildrenFromArray [ btn "delete", btn "copy", btn "expand" ]
        }

      mkHandle :: HandleType -> Position -> JSX
      mkHandle handleType position = element handle
        { handleType
        , position
        , id: Nothing
        , isConnectable: Nothing
        , isConnectableStart: Nothing
        , isConnectableEnd: Nothing
        , onConnect: Nothing
        , isValidConnection: Nothing
        , className: Nothing
        , style: Nothing
        }
    in
      fragment
        [ toolbar
        , div_ {} [ textContent d.label ]
        , mkHandle Target PosLeft
        , mkHandle Source PosRight
        ]
