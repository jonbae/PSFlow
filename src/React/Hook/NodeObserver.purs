-- | `useNodeObserver` — installs a `ResizeObserver` on a single node's
-- | wrapper element. When the size changes the hook builds a
-- | `Map String InternalNodeUpdate` payload for the observed node and
-- | dispatches `UpdateNodeInternals`, prompting the store to remeasure.
-- |
-- | Mirrors
-- | `xyflow-main/packages/react/src/components/NodeWrapper/useNodeObserver.ts`.
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
import React.FFI.ResizeObserver (createResizeObserver, disconnect, observe)
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import Web.HTML.HTMLDivElement (HTMLDivElement, toElement)

-- | Inputs the hook needs. `force` lets the consumer request a
-- | remeasure even when the dimensions look unchanged (matches TS's
-- | `force` flag).
type UseNodeObserverParams =
  { nodeId :: String
  , wrapperRef :: Ref (Nullable HTMLDivElement)
  , force :: Boolean
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
      Just divEl -> do
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
