-- | `useGlobalKeyHandler` — wires the global delete and multi-selection
-- | keys into the store. Mirrors
-- | `xyflow/packages/react/src/hooks/useGlobalKeyHandler.ts`.
-- |
-- | Composes `useKeyPress` (ticket 031) for each tracked key,
-- | `useStoreApi` (ticket 027) for the store, and `useReactFlow` for
-- | `deleteElements`. The hook is `Unit`-valued — its purpose is to
-- | install the side effects, not return state.
-- |
-- | As upstream's, it runs two effects, each keyed on one key: pressing
-- | the multi-selection key while the delete key is held doesn't delete
-- | again.
module React.Hook.GlobalKeyHandler
  ( UseGlobalKeyHandlerOptions
  , UseGlobalKeyHandlerHook(..)
  , useGlobalKeyHandler
  , deleteSelectedElements
  ) where

import Prelude

import Data.Array (filter) as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import React.Basic.Hooks (Hook, UseEffect, coerceHook, useEffect)
import React.Basic.Hooks as React
import React.Hook.KeyPress (UseKeyPressHook, useKeyPress)
import React.Hook.ReactFlow (UseReactFlow, useReactFlow)
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import React.Types.Instance (DeleteElementsOptions)
import System.Types.Connection (KeyCode)

type UseGlobalKeyHandlerOptions =
  { deleteKeyCode :: Maybe KeyCode
  , multiSelectionKeyCode :: Maybe KeyCode
  }

-- | Composite hook tag: `useStoreApi`, `useReactFlow`, two `useKeyPress`
-- | chains, then one `useEffect` per tracked key.
newtype UseGlobalKeyHandlerHook n e hooks =
  UseGlobalKeyHandlerHook
    ( UseEffect Boolean
        ( UseEffect Boolean
            (UseKeyPressHook (UseKeyPressHook (UseReactFlow n e (UseStoreApi hooks))))
        )
    )

derive instance newtypeUseGlobalKeyHandlerHook ::
  Newtype (UseGlobalKeyHandlerHook n e hooks) _

useGlobalKeyHandler
  :: forall n e
   . UseGlobalKeyHandlerOptions
  -> Hook (UseGlobalKeyHandlerHook n e) Unit
useGlobalKeyHandler opts = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi (Store n e))
  flow <- useReactFlow
  deletePressed <- useKeyPress opts.deleteKeyCode Nothing
  multiPressed <- useKeyPress opts.multiSelectionKeyCode Nothing
  useEffect deletePressed do
    when deletePressed (deleteSelectedElements store flow.deleteElements)
    pure (pure unit)
  useEffect multiPressed do
    store.dispatch
      (PatchState \s -> s { multiSelectionActive = multiPressed })
    pure (pure unit)

-- | The body of upstream's delete-key effect:
-- |
-- |     const { edges, nodes } = store.getState();
-- |     deleteElements({ nodes: nodes.filter(selected), edges: edges.filter(selected) });
-- |     store.setState({ nodesSelectionActive: false });
-- |
-- | `deleteElements` is `useReactFlow`'s, so the deletion goes through
-- | `onBeforeDelete`, leaves the undeletable elements, takes the deleted
-- | nodes' connected edges with it, and fires `onEdgesDelete`,
-- | `onNodesDelete`, and `onDelete`. Upstream doesn't await it, and
-- | neither does this.
deleteSelectedElements
  :: forall n e r
   . Store n e
  -> (DeleteElementsOptions n e -> Aff r)
  -> Effect Unit
deleteSelectedElements store deleteElements = do
  s <- store.getState
  launchAff_
    ( void
        ( deleteElements
            { nodes: Just (map Right (Array.filter selected s.nodes))
            , edges: Just (map Right (Array.filter selected s.edges))
            }
        )
    )
  store.setState \st -> st { nodesSelectionActive = false }
  where
  selected :: forall a. { selected :: Maybe Boolean | a } -> Boolean
  selected item = item.selected == Just true
