-- | Listener-registration hooks: `useOnViewportChange`,
-- | `useOnSelectionChange`, `useOnInitHandler`. Each installs a
-- | callback into a slot or list on the `ReactFlowState` for the
-- | lifetime of the calling component. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useOn{Viewport,Selection,Init}Handler.ts`.
-- |
-- | **Storage strategy: `PatchState` for now.** The store does not yet
-- | expose dedicated `Action` constructors for listener registration —
-- | we therefore reach into `s.onViewportChangeStart` /
-- | `s.onSelectionChangeHandlers` etc. directly via
-- | `dispatch (PatchState f)`. Ticket 051 tracks the follow-up that
-- | replaces this with named actions for a cleaner audit trail.
-- |
-- | **Reference-equality removal.** `useOnSelectionChange` appends a
-- | callback to an array and removes it again on unmount. We identify
-- | the registered entry by JS reference equality via
-- | `Unsafe.Reference.unsafeRefEq` — same approach the TS source uses
-- | (`filter(h => h !== cb)`).
module React.Hook.Listeners
  ( UseOnViewportChangeOptions
  , UseOnSelectionChangeOptions
  , UseListenerEffect(..)
  , useOnViewportChange
  , useOnSelectionChange
  , useOnInitHandler
  ) where

import Prelude

import Data.Array (filter, snoc) as Array
import Data.Maybe (Maybe(..), maybe)
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.Exception.Unsafe (unsafeThrow)
import React.Basic.Hooks (Hook, UnsafeReference(..), UseEffect, coerceHook, useEffect)
import React.Basic.Hooks as React
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import React.Types.General (OnSelectionChangeFunc, OnViewportChange)
import Unsafe.Reference (unsafeRefEq)

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
    -- Install all three slots in one `PatchState` so they update
    -- atomically.
    let
      install = \s -> s
        { onViewportChangeStart =
            maybe s.onViewportChangeStart Just opts.onStart
        , onViewportChange =
            maybe s.onViewportChange Just opts.onChange
        , onViewportChangeEnd =
            maybe s.onViewportChangeEnd Just opts.onEnd
        }
    store.dispatch (PatchState install)
    pure do
      -- On unmount: only clear the slots we set. We identify "we set
      -- it" by reference-comparing the stored callback against the one
      -- we installed. If the user has since installed another
      -- listener (different reference) we leave it alone.
      let
        clearIf mInstalled mCurrent =
          case mInstalled, mCurrent of
            Just installed, Just current ->
              if unsafeRefEq installed current then Nothing else mCurrent
            _, _ -> mCurrent
        uninstall = \s -> s
          { onViewportChangeStart =
              clearIf opts.onStart s.onViewportChangeStart
          , onViewportChange =
              clearIf opts.onChange s.onViewportChange
          , onViewportChangeEnd =
              clearIf opts.onEnd s.onViewportChangeEnd
          }
      store.dispatch (PatchState uninstall)

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
        store.dispatch
          ( PatchState \s -> s
              { onSelectionChangeHandlers =
                  Array.snoc s.onSelectionChangeHandlers cb
              }
          )
        pure do
          store.dispatch
            ( PatchState \s -> s
                { onSelectionChangeHandlers =
                    Array.filter (\h -> not (unsafeRefEq h cb))
                      s.onSelectionChangeHandlers
                }
            )

-- | Fires `onInit` exactly once when `viewportInitialized` flips to
-- | `true`. Subsequent transitions are ignored.
-- |
-- | **DEFERRED — body stub.** Needs `useReactFlow` (ticket 030) to
-- | obtain the `ReactFlowInstance` passed to the callback. The
-- | signature is stable; the body throws at render time so any
-- | accidental use before ticket 030 lands is caught loudly.
useOnInitHandler
  :: forall instance_
   . Maybe (instance_ -> Effect Unit)
  -> Hook UseStoreApi Unit
useOnInitHandler _ = React.do
  _ <- (useStoreApi :: Hook UseStoreApi _)
  pure
    ( unsafeThrow
        "useOnInitHandler: implementation deferred to ticket 030 (useReactFlow)"
    )
