-- | Experimental middleware hooks. Each puts a function in one of the
-- | store's middleware maps, which the store runs a batch of changes
-- | through before it triggers them, so the function can drop, change, or
-- | pass the changes on.
-- |
-- | Mirrors
-- | `xyflow/packages/react/src/hooks/useOnNodesChangeMiddleware.ts`
-- | and `useOnEdgesChangeMiddleware.ts`, effect for effect:
-- |
-- |   * One key per hook instance, upstream's `useState(() => Symbol())`.
-- |   * On each change of `fn`, `map.set(key, fn)` into the map the store
-- |     holds then. A key already in the map keeps its position.
-- |   * On unmount, `map.delete(key)` from the map the store held at mount.
-- |
-- | Neither writes the store, so neither notifies a subscriber. See
-- | `React.Store.Middleware` for the map.
module React.Hook.Middleware
  ( UseMiddlewareHook(..)
  , useOnNodesChangeMiddleware
  , useOnEdgesChangeMiddleware
  , useOnNodesChangeMiddlewareEntry
  , useOnEdgesChangeMiddlewareEntry
  ) where

import Prelude

import Data.Newtype (class Newtype)
import Effect (Effect)
import Foreign (Foreign)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, UseMemo, coerceHook, useEffect, useMemo)
import React.Basic.Hooks as React
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Middleware (deleteMiddleware, freshMiddlewareKey, setMiddleware, setNativeMiddleware)
import React.Types.Store (MiddlewareKey, MiddlewareMap, ReactFlowState)
import System.Types.Edge (EdgeChange)
import System.Types.Node (NodeChange)

newtype UseMiddlewareHook fn hooks =
  UseMiddlewareHook
    ( UseEffect Unit
        ( UseEffect (UnsafeReference fn)
            ( UseMemo Unit MiddlewareKey
                (UseStoreApi hooks)
            )
        )
    )

derive instance newtypeUseMiddlewareHook ::
  Newtype (UseMiddlewareHook fn hooks) _

-- | The two effects, for one map and one way of putting `fn` in it.
useMiddleware
  :: forall n e c fn
   . (ReactFlowState n e -> MiddlewareMap c)
  -> (MiddlewareKey -> fn -> MiddlewareMap c -> Effect Unit)
  -> fn
  -> Hook (UseMiddlewareHook fn) Unit
useMiddleware mapOf set fn = coerceHook React.do
  store <- useStoreApi
  key <- useMemo unit \_ -> freshMiddlewareKey unit
  useEffect (UnsafeReference fn) do
    s <- store.getState
    set key fn (mapOf s)
    pure (pure unit)
  useEffect unit do
    s <- store.getState
    let mounted = mapOf s
    pure (deleteMiddleware key mounted)

-- | Register an interceptor on node-change dispatches for the lifetime
-- | of the calling component. The function receives every batch of
-- | `NodeChange n` headed for the reducer and may return a possibly
-- | filtered/transformed batch.
useOnNodesChangeMiddleware
  :: forall n
   . (Array (NodeChange n) -> Array (NodeChange n))
  -> Hook
       (UseMiddlewareHook (Array (NodeChange n) -> Array (NodeChange n)))
       Unit
useOnNodesChangeMiddleware =
  useMiddleware (_.onNodesChangeMiddlewareMap :: ReactFlowState n _ -> _) (setNativeMiddleware "nodes")

-- | Edge-change counterpart. See `useOnNodesChangeMiddleware`.
useOnEdgesChangeMiddleware
  :: forall e
   . (Array (EdgeChange e) -> Array (EdgeChange e))
  -> Hook
       (UseMiddlewareHook (Array (EdgeChange e) -> Array (EdgeChange e)))
       Unit
useOnEdgesChangeMiddleware =
  useMiddleware (_.onEdgesChangeMiddlewareMap :: ReactFlowState _ e -> _) (setNativeMiddleware "edges")

-- | `useOnNodesChangeMiddleware` for a function that is already
-- | JavaScript-shaped: the consumer's own, which goes in the map as itself,
-- | as upstream's hook puts it there.
useOnNodesChangeMiddlewareEntry :: Foreign -> Hook (UseMiddlewareHook Foreign) Unit
useOnNodesChangeMiddlewareEntry =
  useMiddleware (_.onNodesChangeMiddlewareMap :: ReactFlowState Foreign Foreign -> _) setMiddleware

-- | Edge-change counterpart of `useOnNodesChangeMiddlewareEntry`.
useOnEdgesChangeMiddlewareEntry :: Foreign -> Hook (UseMiddlewareHook Foreign) Unit
useOnEdgesChangeMiddlewareEntry =
  useMiddleware (_.onEdgesChangeMiddlewareMap :: ReactFlowState Foreign Foreign -> _) setMiddleware
