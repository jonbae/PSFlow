-- | `useGlobalKeyHandler` — wires the global delete / multi-selection /
-- | pan-activation keys into store-level state changes. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useGlobalKeyHandler.ts`.
-- |
-- | Composes `useKeyPress` (ticket 031) for each tracked key and
-- | `useStoreApi` (ticket 027) for dispatch. The hook is `Unit`-valued
-- | — its purpose is to install the side effects, not return state.
-- |
-- | **Divergences.** The TS source dispatches `unselectNodesAndEdges`
-- | and a synthetic `delete` action that removes selected entries via
-- | the same change pipeline used by drag/select. PS does the same by
-- | constructing `NodeRemoveChange`/`EdgeRemoveChange` arrays inline and
-- | sending them through `TriggerNodeChanges` / `TriggerEdgeChanges`.
-- | The `multiSelectionActive` flag is set/cleared directly through
-- | `PatchState` because there is no dedicated action constructor for
-- | it yet (ticket 051 follow-up).
module React.Hook.GlobalKeyHandler
  ( UseGlobalKeyHandlerOptions
  , UseGlobalKeyHandlerHook(..)
  , useGlobalKeyHandler
  ) where

import Prelude

import Data.Array (mapMaybe) as Array
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import React.Basic.Hooks (Hook, UseEffect, coerceHook, useEffect)
import React.Basic.Hooks as React
import React.Hook.KeyPress (UseKeyPressHook, useKeyPress)
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import System.Types.Connection (KeyCode)
import System.Types.Edge (EdgeChange(..))
import System.Types.Node (NodeChange(..))

type UseGlobalKeyHandlerOptions =
  { deleteKeyCode :: Maybe KeyCode
  , multiSelectionKeyCode :: Maybe KeyCode
  }

-- | Composite hook tag: two `useKeyPress` chains followed by a single
-- | `useEffect` that fires the delete/multi-select dispatches when the
-- | tracked booleans transition.
newtype UseGlobalKeyHandlerHook hooks =
  UseGlobalKeyHandlerHook
    ( UseEffect { delete :: Boolean, multi :: Boolean }
        (UseKeyPressHook (UseKeyPressHook (UseStoreApi hooks)))
    )

derive instance newtypeUseGlobalKeyHandlerHook ::
  Newtype (UseGlobalKeyHandlerHook hooks) _

useGlobalKeyHandler
  :: UseGlobalKeyHandlerOptions
  -> Hook UseGlobalKeyHandlerHook Unit
useGlobalKeyHandler opts = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  deletePressed <- useKeyPress opts.deleteKeyCode Nothing
  multiPressed <- useKeyPress opts.multiSelectionKeyCode Nothing
  useEffect { delete: deletePressed, multi: multiPressed } do
    -- Multi-selection: mirror the boolean into store state. Match TS.
    store.dispatch
      (PatchState \s -> s { multiSelectionActive = multiPressed })
    -- Delete: when the boolean is `true` this render, emit a removal
    -- change for every currently-selected node and edge. The TS source
    -- gates this on a transition; we approximate by checking
    -- whether anything is selected at all.
    if deletePressed then do
      st <- store.getState
      let
        selectedNodeIds =
          Array.mapMaybe (\n -> if n.selected then Just n.id else Nothing)
            st.nodes
        selectedEdgeIds =
          Array.mapMaybe (\e -> if e.selected then Just e.id else Nothing)
            st.edges
      when (selectedNodeIds /= []) do
        store.dispatch
          ( TriggerNodeChanges
              (map (\i -> NodeRemoveChange { id: i }) selectedNodeIds)
          )
      when (selectedEdgeIds /= []) do
        store.dispatch
          ( TriggerEdgeChanges
              (map (\i -> EdgeRemoveChange { id: i }) selectedEdgeIds)
          )
    else pure unit
    pure (pure unit)

