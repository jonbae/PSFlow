-- | Listener-registration hooks: `useOnViewportChange`,
-- | `useOnSelectionChange`, `useOnInitHandler`. Each installs a
-- | callback into a slot or list on the `ReactFlowState` for the
-- | lifetime of the calling component. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useOn{Viewport,Selection,Init}Handler.ts`.
-- |
-- | Registration goes through named `Action` constructors
-- | (`InstallViewportListeners`, `UninstallViewportListeners`,
-- | `AddSelectionChangeHandler`, `RemoveSelectionChangeHandler`). The
-- | atomic 3-slot patching and ref-equality clear logic for viewport
-- | listeners lives in `React.Store.Reduce`.
module React.Hook.Listeners
  ( UseOnViewportChangeOptions
  , UseOnSelectionChangeOptions
  , UseListenerEffect(..)
  , UseOnInitHandler(..)
  , useOnViewportChange
  , useOnSelectionChange
  , useOnInitHandler
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Effect (Effect)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, UseRef, coerceHook, readRef, useEffect, useRef, writeRef)
import React.Basic.Hooks as React
import React.Hook.ReactFlow (UseReactFlow, useReactFlow)
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import React.Types.General (OnSelectionChangeFunc, OnViewportChange)
import React.Types.Instance (ReactFlowInstance)

-- | TS `UseOnViewportChangeOptions`.
type UseOnViewportChangeOptions =
  { onStart :: Maybe OnViewportChange
  , onChange :: Maybe OnViewportChange
  , onEnd :: Maybe OnViewportChange
  }

-- | TS `UseOnSelectionChangeOptions`.
type UseOnSelectionChangeOptions n e =
  { onChange :: Maybe (OnSelectionChangeFunc n e)
  }

-- | Composite hook-effect tag for the listener hooks. The chain is
-- | `useStoreApi` followed by one `useEffect`.
newtype UseListenerEffect deps hooks =
  UseListenerEffect (UseEffect deps (UseStoreApi hooks))

derive instance newtypeUseListenerEffect ::
  Newtype (UseListenerEffect deps hooks) _

-- | Register up-to-three viewport-change callbacks (start, change, end)
-- | for the lifetime of the calling component. Each slot is overwritten
-- | on mount and cleared on unmount. If a slot is `Nothing` it is
-- | preserved as-is rather than overwritten — i.e. passing
-- | `{ onStart: Just _, onChange: Nothing, onEnd: Nothing }` only
-- | installs an `onStart` listener and leaves any previously installed
-- | `onChange`/`onEnd` slot alone.
-- |
-- | TS sets all three slots unconditionally on every render. PS chooses
-- | the safer "only touch slots you provided" semantics — pass an empty
-- | `{ Nothing, Nothing, Nothing }` record to install no listeners.
useOnViewportChange
  :: UseOnViewportChangeOptions
  -> Hook (UseListenerEffect (UnsafeReference UseOnViewportChangeOptions)) Unit
useOnViewportChange opts = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  useEffect (UnsafeReference opts) do
    store.dispatch
      ( InstallViewportListeners
          { onStart: opts.onStart
          , onChange: opts.onChange
          , onEnd: opts.onEnd
          }
      )
    pure $ store.dispatch
      ( UninstallViewportListeners
          { onStart: opts.onStart
          , onChange: opts.onChange
          , onEnd: opts.onEnd
          }
      )

-- | Append a selection-change handler to the store's handler list. On
-- | unmount the handler is removed by JS reference identity. Multiple
-- | components may subscribe simultaneously; each gets its own slot.
useOnSelectionChange
  :: forall n e
   . UseOnSelectionChangeOptions n e
  -> Hook
       (UseListenerEffect (UnsafeReference (UseOnSelectionChangeOptions n e)))
       Unit
useOnSelectionChange opts = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  useEffect (UnsafeReference opts) do
    case opts.onChange of
      Nothing -> pure (pure unit)
      Just cb -> do
        store.dispatch (AddSelectionChangeHandler cb)
        pure $ store.dispatch (RemoveSelectionChangeHandler cb)

-- | Fires `onInit` exactly once when `viewportInitialized` flips to
-- | `true`. Subsequent transitions are ignored. The callback receives
-- | the `ReactFlowInstance` so it can immediately drive viewport or
-- | state-mutation methods.
-- |
-- | Mirrors `xyflow-main/packages/react/src/hooks/useOnInitHandler.ts`.
-- | TS schedules the callback through `setTimeout(fn, 1)` to dodge a
-- | corner-case where the instance is read mid-commit; the PS port
-- | fires inside `useEffect`, which already runs post-commit, so the
-- | extra microtask delay is unnecessary.
newtype UseOnInitHandler n e hooks =
  UseOnInitHandler
    ( UseEffect (UnsafeReference Boolean)
        ( UseRef Boolean
            (UseReactFlow n e hooks)
        )
    )

derive instance newtypeUseOnInitHandler ::
  Newtype (UseOnInitHandler n e hooks) _

useOnInitHandler
  :: forall n e
   . Maybe (ReactFlowInstance n e -> Effect Unit)
  -> Hook (UseOnInitHandler n e) Unit
useOnInitHandler mOnInit = coerceHook React.do
  rfInstance <- useReactFlow
  initRef <- useRef false
  useEffect (UnsafeReference rfInstance.viewportInitialized) do
    initialized <- readRef initRef
    when (not initialized && rfInstance.viewportInitialized) do
      case mOnInit of
        Just onInit -> do
          onInit rfInstance
          writeRef initRef true
        Nothing -> pure unit
    pure (pure unit)

