module Test.Boundary.UserNode (runUserNodeTests) where

import Prelude

import Boundary.Elements (JsInternalNode, JsNode, nodeIn)
import Boundary.Hooks as Hooks
import Boundary.Undefined (Undefinable, toUndefinable)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn1, runEffectFn1, runEffectFn2)
import Foreign (Foreign)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (createStore)
import System.Utils.Store (adoptUserNodes, defaultUpdateNodesOptions)
import System.Types.Ids (NodeId(..))
import Unsafe.Coerce (unsafeCoerce)
import Unsafe.Reference (unsafeRefEq)
import Effect.Exception (throw)

type Readings =
  { instance :: Undefinable JsInternalNode
  , hook :: Undefinable JsInternalNode
  }

type Session =
  { read :: Effect Readings
  , replace :: EffectFn1 JsNode Unit
  , internalReference :: Effect Foreign
  , readopt :: EffectFn1 Boolean Unit
  }

foreign import renderWithStore :: forall a. EffectFn2 Foreign (Effect a) a
foreign import checkUserNode :: EffectFn1 (EffectFn1 JsNode Session) Unit
foreign import consumerNode :: JsNode

runUserNodeTests :: Effect Unit
runUserNodeTests = do
  checkJsUserNodes
  let
    typed = (nodeIn consumerNode) { position = { x: 1.0, y: 2.0 } }
    initial = adoptUserNodes [ typed ] Map.empty Map.empty defaultUpdateNodesOptions
    unchanged = adoptUserNodes [ typed ] initial.nodeLookup initial.parentLookup defaultUpdateNodesOptions
  case Map.lookup (NodeId "ps") initial.nodeLookup, Map.lookup (NodeId "ps") unchanged.nodeLookup of
    Just first, Just next | unsafeRefEq first.internals.userNode typed && unsafeRefEq first next -> pure unit
    _, _ -> throw "PureScript originals and unchanged internal nodes must retain their actual references"

checkJsUserNodes :: Effect Unit
checkJsUserNodes = runEffectFn1 checkUserNode $ mkEffectFn1 \original -> do
  store <- createStore ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign)
    { nodes = Just [ nodeIn original ] })
  pure
    { read: runEffectFn2 renderWithStore (unsafeCoerce (Just store)) do
        flow <- Hooks.useReactFlow
        hook <- runEffectFn1 Hooks.useInternalNode "a"
        internal <- runEffectFn1 flow.getInternalNode "a"
        pure { instance: internal, hook }
    , replace: mkEffectFn1 \node -> store.dispatch (SetNodes [ nodeIn node ])
    , internalReference: do
        state <- store.getState
        pure $ unsafeCoerce $ toUndefinable $ Map.lookup (NodeId "a") state.nodeLookup
    , readopt: mkEffectFn1 \checkEquality -> do
        state <- store.getState
        let adopted = adoptUserNodes state.nodes state.nodeLookup state.parentLookup
              (defaultUpdateNodesOptions { checkEquality = checkEquality })
        store.dispatch (PatchState _ { nodeLookup = adopted.nodeLookup, parentLookup = adopted.parentLookup })
    }
