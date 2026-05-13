-- | The `BatchContext` provides per-render queues for buffering node and
-- | edge updates so multiple `setNodes` / `addNodes` calls in the same
-- | render cycle collapse to a single store dispatch. Mirrors
-- | `xyflow-main/packages/react/src/components/BatchProvider/`.
-- |
-- | The TS source parameterises queues on the concrete node/edge types;
-- | we use opaque placeholders here for the same reason as
-- | `React.Context.Store.OpaqueStore` — `ReactContext` is monomorphic.
-- | The actual consumer hooks cast at one seam.
module React.Context.Batch
  ( Queue
  , QueueItem(..)
  , BatchContext
  , OpaqueNodeBatch
  , OpaqueEdgeBatch
  , batchContext
  , useBatchContext
  , createQueue
  ) where

import Prelude

import Data.Array (snoc) as Array
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Ref as Ref
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactContext)
import React.Basic.Hooks (Hook, UseContext, useContext)
import React.FFI.React (createContext)
import System.Constants (ErrorCode(..), errorMessage)

-- | A queued payload. TS `QueueItem<T> = T[] | ((items: T[]) => T[])`.
-- | `QueueReplace` overwrites with a fresh array; `QueueUpdate` applies
-- | an updater to the current array.
data QueueItem a
  = QueueReplace (Array a)
  | QueueUpdate (Array a -> Array a)

-- | Imperative queue. The `push` operation enqueues an item and signals
-- | the flush. `reset` clears the queue (called after a flush). `get`
-- | returns the current accumulated items.
type Queue a =
  { push :: QueueItem a -> Effect Unit
  , reset :: Effect Unit
  , get :: Effect (Array (QueueItem a))
  }

-- | Phantom placeholders so `BatchContext` can be monomorphic. The
-- | provider (`React.Provider.Batch`, ticket 043) casts the real
-- | `Queue (Array (Node n))` / `Queue (Array (Edge e))` into these
-- | opaque shapes once.
foreign import data OpaqueNodeBatch :: Type
foreign import data OpaqueEdgeBatch :: Type

type BatchContext =
  { nodeQueue :: Queue OpaqueNodeBatch
  , edgeQueue :: Queue OpaqueEdgeBatch
  }

batchContext :: ReactContext (Maybe BatchContext)
batchContext = unsafePerformEffect (createContext Nothing)

-- | Asserts the provider is mounted. Throws with `errorMessage E001`
-- | (the standard "missing zustand provider" message) when used outside
-- | a `<BatchProvider>`, matching the TS behaviour.
useBatchContext :: Hook (UseContext (Maybe BatchContext)) BatchContext
useBatchContext = map unwrap (useContext batchContext)
  where
  unwrap = case _ of
    Just b -> b
    Nothing -> unsafeThrow (errorMessage E001)

-- | Build a `Queue` backed by a fresh `Ref (Array (QueueItem a))`. The
-- | `onPush` callback runs after every enqueue — it's the hook into the
-- | provider's "flush on next layout effect" loop.
createQueue :: forall a. Effect Unit -> Effect (Queue a)
createQueue onPush = do
  ref <- Ref.new []
  pure
    { push: \item -> do
        Ref.modify_ (\xs -> Array.snoc xs item) ref
        onPush
    , reset: Ref.write [] ref
    , get: Ref.read ref
    }
