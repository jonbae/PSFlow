-- | `<NodeRenderer />` — fans out over the visible node IDs and mounts
-- | one `<NodeWrapper />` per ID. Allocates a single `ResizeObserver`
-- | (shared by every wrapper under this renderer) so node measurements
-- | go through one batched dispatch instead of one observer per node.
-- |
-- | Mirrors `xyflow-main/packages/react/src/container/NodeRenderer/index.tsx`
-- | + `…/NodeRenderer/useResizeObserver.ts`.
-- |
-- | **Fidelity notes.**
-- |   * `memo` is applied to the public export, matching TS
-- |     (`export const NodeRenderer = memo(NodeRendererComponent)`).
-- |     Ticket 040 text says "no memo", but TS uses it — TS is
-- |     authoritative; the ID-array subscription keeps re-renders rare
-- |     either way.
-- |   * TS's `useState(() => new ResizeObserver(...))` lazy init is
-- |     translated to `useMemo unit \_ -> unsafePerformEffect …` — PS's
-- |     `useState` is eager, and `useMemo` with a constant dep runs the
-- |     constructor exactly once per mount.
-- |   * `useEffectOnce` registers the `disconnect` cleanup so the
-- |     observer is torn down on unmount.
-- |   * The shared observer's callback reads `data-id` per entry via
-- |     `Web.DOM.Element.getAttribute`. Entries without `data-id` or
-- |     without a div coercion are silently skipped — TS would have
-- |     produced `undefined` and inserted garbage; PS is stricter.
module React.Container.NodeRenderer
  ( nodeRenderer
  ) where

import Prelude

import Data.Foldable (foldM)
import Data.Map (Map)
import Data.Map (empty, insert, isEmpty) as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype, unwrap)
import Effect (Effect)
import Effect.Ref as Ref
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (JSX, ReactComponent, element, keyed)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, UseMemo, coerceHook, memo, reactComponent, useEffectOnce, useMemo)
import React.Basic.Hooks as React
import React.Component.NodeWrapper (nodeWrapper)
import React.FFI.DOM (div_)
import React.FFI.ResizeObserver (ResizeObserver, createResizeObserver, disconnect)
import React.Hook.Store (UseStoreApi, useStore, useStoreApi)
import React.Hook.VisibleIds (useVisibleNodeIds)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import React.Types.Component (NodeRendererProps)
import React.Types.Store (ReactFlowState)
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeUpdate, OnError)
import Unsafe.Coerce (unsafeCoerce)
import Web.DOM.Element (getAttribute)
import Web.HTML.HTMLDivElement (fromElement)

toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

-- | Mirrors TS `containerStyle` (`styles/utils.ts`). Same five fields
-- | as the inline literal in `ZoomPane`.
containerStyle :: Foreign
containerStyle = toForeignStyle
  { position: "absolute"
  , width: "100%"
  , height: "100%"
  , top: 0
  , left: 0
  }

-- ----------------------------------------------------------------------------
-- Flags slice
-- ----------------------------------------------------------------------------

type NodeFlagsSlice =
  { nodesDraggable :: Boolean
  , nodesConnectable :: Boolean
  , nodesFocusable :: Boolean
  , elementsSelectable :: Boolean
  , onError :: UnsafeReference (Maybe OnError)
  }

selectFlags :: forall n e. ReactFlowState n e -> NodeFlagsSlice
selectFlags s =
  { nodesDraggable: s.nodesDraggable
  , nodesConnectable: s.nodesConnectable
  , nodesFocusable: s.nodesFocusable
  , elementsSelectable: s.elementsSelectable
  , onError: UnsafeReference s.onError
  }

-- ----------------------------------------------------------------------------
-- Shared ResizeObserver
-- ----------------------------------------------------------------------------

-- | Allocate the per-renderer `ResizeObserver`. Walks each entry,
-- | resolves `data-id` + the underlying `HTMLDivElement`, and batches
-- | all updates into a single `UpdateNodeInternals` dispatch.
mkSharedObserver
  :: forall n e
   . Store n e
  -> Effect ResizeObserver
mkSharedObserver store =
  createResizeObserver \entries -> do
    updatesRef <- Ref.new (Map.empty :: Map NodeId InternalNodeUpdate)
    _ <- foldM
      ( \_ entry -> do
          mDataId <- getAttribute "data-id" entry.target
          let mDivEl = fromElement entry.target
          case mDataId, mDivEl of
            Just nodeId, Just divEl ->
              Ref.modify_
                ( Map.insert (NodeId nodeId)
                    { id: NodeId nodeId
                    , nodeElement: divEl
                    , force: true
                    }
                )
                updatesRef
            _, _ -> pure unit
      )
      unit
      entries
    updates <- Ref.read updatesRef
    when (not (Map.isEmpty updates)) do
      store.dispatch
        (UpdateNodeInternals updates { triggerFitView: false })

-- | Hook-effect tag for the composite chain: `useStoreApi` →
-- | `useMemo unit (\_ -> RO)` → `useEffectOnce disconnect`.
newtype UseResizeObserver hooks =
  UseResizeObserver
    ( UseEffect Unit
        (UseMemo Unit ResizeObserver
            (UseStoreApi hooks)
        )
    )

derive instance newtypeUseResizeObserver ::
  Newtype (UseResizeObserver hooks) _

useResizeObserver :: Hook UseResizeObserver ResizeObserver
useResizeObserver = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  observer <- useMemo unit \_ ->
    unsafePerformEffect (mkSharedObserver store)
  useEffectOnce do
    pure (disconnect observer)
  pure observer

-- ----------------------------------------------------------------------------
-- The component
-- ----------------------------------------------------------------------------

nodeRenderer :: forall n. ReactComponent (NodeRendererProps n)
nodeRenderer =
  unsafePerformEffect $ memo $ reactComponent "NodeRenderer"
    \(props :: NodeRendererProps n) -> React.do
      flags <- useStore selectFlags
      nodeIds <- useVisibleNodeIds props.onlyRenderVisibleElements
      observer <- useResizeObserver
      let
        UnsafeReference onError = flags.onError
        children :: Array JSX
        children = map
          ( \nodeId ->
              let nodeIdStr = unwrap nodeId
              in keyed nodeIdStr $ element nodeWrapper
                { id: nodeIdStr
                , nodeTypes: props.nodeTypes
                , nodeExtent: props.nodeExtent
                , onClick: props.onNodeClick
                , onMouseEnter: props.onNodeMouseEnter
                , onMouseMove: props.onNodeMouseMove
                , onMouseLeave: props.onNodeMouseLeave
                , onContextMenu: props.onNodeContextMenu
                , onDoubleClick: props.onNodeDoubleClick
                , noDragClassName: props.noDragClassName
                , noPanClassName: props.noPanClassName
                , rfId: props.rfId
                , disableKeyboardA11y: props.disableKeyboardA11y
                , resizeObserver: Just observer
                , nodesDraggable: flags.nodesDraggable
                , nodesConnectable: flags.nodesConnectable
                , nodesFocusable: flags.nodesFocusable
                , elementsSelectable: flags.elementsSelectable
                , nodeClickDistance: props.nodeClickDistance
                , onError
                }
          )
          nodeIds
      pure $
        div_
          { className: "react-flow__nodes"
          , style: containerStyle
          }
          children
