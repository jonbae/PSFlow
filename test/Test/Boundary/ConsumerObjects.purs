module Test.Boundary.ConsumerObjects (runConsumerObjectsTests) where

import Prelude

import Boundary.Elements (JsEdge, JsEdgeChange, JsNode, JsNodeChange)
import Boundary.Utils (addEdge, applyEdgeChanges, applyNodeChanges)
import Data.Function.Uncurried (Fn2)
import Effect (Effect)
import Effect.Uncurried (EffectFn3, runEffectFn3)
import Foreign (Foreign)

foreign import checkConsumerObjects
  :: EffectFn3
       (Fn2 (Array JsNodeChange) (Array JsNode) (Array JsNode))
       (Fn2 (Array JsEdgeChange) (Array JsEdge) (Array JsEdge))
       (Fn2 Foreign (Array JsEdge) (Array JsEdge))
       Unit

runConsumerObjectsTests :: Effect Unit
runConsumerObjectsTests = runEffectFn3 checkConsumerObjects applyNodeChanges applyEdgeChanges addEdge
