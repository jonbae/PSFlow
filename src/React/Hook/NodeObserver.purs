-- | `useNodeObserver` — attaches a `ResizeObserver` to one node's wrapper
-- | element so size changes flow back through `UpdateNodeInternals` for
-- | remeasure. Mirrors
-- | `xyflow-main/packages/react/src/components/NodeWrapper/useNodeObserver.ts`.
-- |
-- | Has two modes, selected by `sharedObserver`:
-- |
-- |   * `Just shared` — the caller (a `NodeRenderer`) owns a single
-- |     `ResizeObserver` for all wrappers under it. The hook only
-- |     `observe`s / `unobserve`s the element; dispatch happens inside
-- |     the shared observer's callback (which reads `data-id` per entry
-- |     and batches `UpdateNodeInternals`).
-- |   * `Nothing` — fallback for `NodeWrapper`s mounted outside a
-- |     `NodeRenderer`. The hook creates and tears down its own
-- |     observer and dispatches `UpdateNodeInternals` per resize event.
module React.Hook.NodeObserver
  ( UseNodeObserverParams
  , UseNodeObserverHook(..)
  , useNodeObserver
  ) where

import Prelude

import Data.Map (singleton) as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable, toMaybe)
import React.Basic (Ref)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, coerceHook, readRef, useEffect)
import React.Basic.Hooks as React
import React.FFI.ResizeObserver (ResizeObserver, createResizeObserver, disconnect, observe, unobserve)
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import System.Types.Ids (NodeId)
import Web.HTML.HTMLDivElement (HTMLDivElement, toElement)

-- | Inputs the hook needs. `force` lets the consumer request a
-- | remeasure even when the dimensions look unchanged (matches TS's
-- | `force` flag). `sharedObserver` selects the shared/per-node mode.
type UseNodeObserverParams =
  { nodeId :: NodeId
  , wrapperRef :: Ref (Nullable HTMLDivElement)
  , force :: Boolean
  , sharedObserver :: Maybe ResizeObserver
  }

newtype UseNodeObserverHook hooks =
  UseNodeObserverHook
    ( UseEffect (UnsafeReference UseNodeObserverParams)
        (UseStoreApi hooks)
    )

derive instance newtypeUseNodeObserverHook ::
  Newtype (UseNodeObserverHook hooks) _

useNodeObserver
  :: UseNodeObserverParams
  -> Hook UseNodeObserverHook Unit
useNodeObserver params = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  useEffect (UnsafeReference params) do
    mDiv <- toMaybe <$> readRef params.wrapperRef
    case mDiv of
      Nothing -> pure (pure unit)
      Just divEl -> case params.sharedObserver of
        Just shared -> do
          observe shared (toElement divEl)
          pure (unobserve shared (toElement divEl))
        Nothing -> do
          observer <- createResizeObserver \_ -> do
            let
              update =
                { id: params.nodeId
                , nodeElement: divEl
                , force: params.force
                }
            store.dispatch
              ( UpdateNodeInternals
                  (Map.singleton params.nodeId update)
                  { triggerFitView: false }
              )
          observe observer (toElement divEl)
          pure (disconnect observer)
