-- | A controller's state, read and written through one `Ref`.
-- |
-- | TS's `XYDrag` and `XYHandle` keep their state in closure variables. A
-- | write to one stays made whatever happens next: when a consumer callback
-- | later in the same handler throws, as a falsy `onNodeDragStart` or
-- | `onConnectStart` does, and when a step runs inside another, which sees
-- | what the outer one has written so far. `get` here reads the `Ref` and
-- | `modify_` writes it at once, so a step behaves the same way.
module System.Utils.RefState
  ( RefState
  , runOnRef
  , execOnRef
  ) where

import Prelude

import Control.Lazy (class Lazy)
import Control.Monad.State.Class (class MonadState)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Class (class MonadEffect)
import Effect.Ref (Ref)
import Effect.Ref as Ref

newtype RefState s a = RefState (Ref s -> Effect a)

instance functorRefState :: Functor (RefState s) where
  map f (RefState m) = RefState \ref -> map f (m ref)

instance applyRefState :: Apply (RefState s) where
  apply = ap

instance applicativeRefState :: Applicative (RefState s) where
  pure a = RefState \_ -> pure a

instance bindRefState :: Bind (RefState s) where
  bind (RefState m) f = RefState \ref -> m ref >>= \a -> runOnRef ref (f a)

instance monadRefState :: Monad (RefState s)

instance monadEffectRefState :: MonadEffect (RefState s) where
  liftEffect effect = RefState \_ -> effect

instance monadStateRefState :: MonadState s (RefState s) where
  state f = RefState \ref -> do
    Tuple a next <- f <$> Ref.read ref
    Ref.write next ref
    pure a

instance lazyRefState :: Lazy (RefState s a) where
  defer f = RefState \ref -> runOnRef ref (f unit)

-- | Run a step against the `Ref`. Building the `Effect` builds nothing of the
-- | step, so an auto-pan frame can hand `requestAnimationFrame` a frame that
-- | itself asks for the next one.
runOnRef :: forall s a. Ref s -> RefState s a -> Effect a
runOnRef ref (RefState m) = pure unit >>= \_ -> m ref

-- | Run a step from `start`, and read the state it leaves.
execOnRef :: forall s a. RefState s a -> s -> Effect s
execOnRef step start = do
  ref <- Ref.new start
  _ <- runOnRef ref step
  Ref.read ref
