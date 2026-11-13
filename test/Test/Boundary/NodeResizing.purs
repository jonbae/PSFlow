module Test.Boundary.NodeResizing (runNodeResizingTests) where

import Prelude
import Boundary.Elements (JsNode, JsNodeChange, JsInternalNode, nodeIn, nodeChangeIn)
import Boundary.Hooks as Hooks
import Boundary.Undefined (Undefinable)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn1, runEffectFn1, runEffectFn2)
import Foreign (Foreign)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (createStore)
import Unsafe.Coerce (unsafeCoerce)

type Session =
  { read :: Effect { nodes :: Array JsNode, internal :: Undefinable JsInternalNode }
  , change :: EffectFn1 JsNodeChange Unit
  }
foreign import checkResizing :: EffectFn1 (EffectFn1 JsNode Session) Unit
foreign import renderWithStore :: forall a. EffectFn2 Foreign (Effect a) a

runNodeResizingTests :: Effect Unit
runNodeResizingTests = runEffectFn1 checkResizing $ mkEffectFn1 \node -> do
  store <- createStore ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign)
    { defaultNodes = Just [ nodeIn node ] })
  pure
    { read: runEffectFn2 renderWithStore (unsafeCoerce (Just store)) do
        flow <- Hooks.useReactFlow
        nodes <- flow.getNodes
        internal <- runEffectFn1 flow.getInternalNode "resize"
        pure { nodes, internal }
    , change: mkEffectFn1 \change -> store.dispatch (TriggerNodeChanges [ nodeChangeIn change ])
    }
