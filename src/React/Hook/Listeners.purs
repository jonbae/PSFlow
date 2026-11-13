-- | Listener-registration hooks: `useOnViewportChange`,
-- | `useOnSelectionChange`, `useOnInitHandler`. Viewport slots have independent
-- | effects; selection registration follows component lifetime; init schedules
-- | once when eligible. Mirrors
-- | `xyflow/packages/react/src/hooks/useOn{Viewport,Selection,Init}Handler.ts`.
-- |
-- | Registration goes through named `Action` constructors
-- | (`SetViewportChangeStartHandler`, `SetViewportChangeHandler`,
-- | `SetViewportChangeEndHandler`, `AddSelectionChangeHandler`,
-- | `RemoveSelectionChangeHandler`). Each viewport slot is a separate source
-- | effect; only selection-change registration has an unmount cleanup.
module React.Hook.Listeners
  ( UseOnViewportChangeOptions
  , UseOnSelectionChangeOptions
  , UseListenerEffect(..)
  , UseViewportListenerEffects(..)
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
import System.FFI.Timer (setTimeout)

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

-- | Three independent effects, as in useOnViewportChange.ts. Each observes
-- | its callback payload by reference, sets its slot including absence, and
-- | returns no cleanup. A different slot is left alone when a handler changes.
newtype UseViewportListenerEffects hooks =
  UseViewportListenerEffects
    ( UseEffect (Maybe (UnsafeReference OnViewportChange))
        ( UseEffect (Maybe (UnsafeReference OnViewportChange))
            ( UseEffect (Maybe (UnsafeReference OnViewportChange))
                (UseStoreApi hooks)
            )
        )
    )

derive instance newtypeUseViewportListenerEffects ::
  Newtype (UseViewportListenerEffects hooks) _

useOnViewportChange
  :: UseOnViewportChangeOptions
  -> Hook UseViewportListenerEffects Unit
useOnViewportChange opts = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  useEffect (map UnsafeReference opts.onStart) do
    store.dispatch (SetViewportChangeStartHandler opts.onStart)
    pure (pure unit)
  useEffect (map UnsafeReference opts.onChange) do
    store.dispatch (SetViewportChangeHandler opts.onChange)
    pure (pure unit)
  useEffect (map UnsafeReference opts.onEnd) do
    store.dispatch (SetViewportChangeEndHandler opts.onEnd)
    pure (pure unit)

-- | Append a selection-change handler to the store's handler list. On
-- | unmount the handler is removed by JS reference identity. Multiple
-- | components may subscribe simultaneously; each gets its own slot.
-- |
-- | TS keys the effect on `[onChange]`, the handler itself, so a re-render
-- | with the same handler leaves the list alone. Keying on the options record
-- | re-registered on every render, since the record is new each time.
useOnSelectionChange
  :: forall n e
   . UseOnSelectionChangeOptions n e
  -> Hook
       (UseListenerEffect (Maybe (UnsafeReference (OnSelectionChangeFunc n e))))
       Unit
useOnSelectionChange opts = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  useEffect (map UnsafeReference opts.onChange) do
    case opts.onChange of
      Nothing -> pure (pure unit)
      Just cb -> do
        store.dispatch (AddSelectionChangeHandler cb)
        pure $ store.dispatch (RemoveSelectionChangeHandler cb)

-- | Schedules `onInit` exactly once when a handler and initialized viewport
-- | are both present, including a handler added after readiness. It receives
-- | the `ReactFlowInstance` so it can immediately drive viewport or
-- | state-mutation methods.
-- |
-- | Mirrors `xyflow/packages/react/src/hooks/useOnInitHandler.ts`.
-- | Preserve the source's setTimeout(fn, 1): the callback runs after commit,
-- | with the instance and handler captured when it was scheduled. The flag
-- | is written at scheduling time; source does not cancel this timer on unmount.
newtype UseOnInitHandler n e hooks =
  UseOnInitHandler
    ( UseEffect
        { onInit :: Maybe (UnsafeReference (ReactFlowInstance n e -> Effect Unit))
        , viewportInitialized :: Boolean
        }
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
  useEffect { onInit: map UnsafeReference mOnInit, viewportInitialized: rfInstance.viewportInitialized } do
    initialized <- readRef initRef
    when (not initialized && rfInstance.viewportInitialized) do
      case mOnInit of
        Just onInit -> do
          _ <- setTimeout (onInit rfInstance) 1
          writeRef initRef true
        Nothing -> pure unit
    pure (pure unit)

