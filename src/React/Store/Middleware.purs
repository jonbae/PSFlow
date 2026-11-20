-- | The change middleware maps: upstream's `onNodesChangeMiddlewareMap` and
-- | `onEdgesChangeMiddlewareMap`.
-- |
-- | Upstream keeps one live JavaScript `Map<symbol, fn>` per store. Its hooks
-- | write into that map in place, with no store update, and its store reads
-- | the map's values in insertion order each time it runs them. A consumer
-- | reads the same map from `getState()`, and can set entries into it or
-- | write a `Map` of its own with `setState`. So ps-flow holds the same kind
-- | of map, and both PureScript and JavaScript functions sit in it:
-- |
-- |   * A function the PureScript hooks register goes in as a JavaScript
-- |     adapter, so the map reads the way upstream's does from JavaScript.
-- |     The adapter remembers its PureScript function, which is what runs.
-- |   * Any other function is a consumer's, taking and returning upstream's
-- |     change objects. It runs through the converters `Boundary.Store`
-- |     registers before JavaScript can reach a map.
module React.Store.Middleware
  ( freshMiddlewareMap
  , freshMiddlewareKey
  , setMiddleware
  , setNativeMiddleware
  , deleteMiddleware
  , hasMiddleware
  , runNodesChangeMiddleware
  , nodesChangeMiddlewareFrom
  , ChangeConverters
  , registerChangeConverters
  ) where

import Prelude

import Effect (Effect)
import Effect.Uncurried (EffectFn2, EffectFn3, EffectFn4, runEffectFn2, runEffectFn3, runEffectFn4)
import Foreign (Foreign)
import React.Types.Store (MiddlewareKey, MiddlewareMap)
import System.Types.Edge (EdgeChange)
import System.Types.Node (NodeChange)

-- | A new, empty map. `getInitialState` makes one on every call, and
-- | `reset` writes that new map into the state, as upstream's does.
foreign import freshMiddlewareMap :: forall c. Unit -> MiddlewareMap c

-- | Upstream's `Symbol()`, one per hook instance.
foreign import freshMiddlewareKey :: Unit -> MiddlewareKey

foreign import setMiddlewareImpl :: forall c. EffectFn3 MiddlewareKey Foreign (MiddlewareMap c) Unit

-- | `map.set(key, fn)` for a function that is already JavaScript-shaped:
-- | a consumer's, from `experimental_useOnNodesChangeMiddleware`.
setMiddleware :: forall c. MiddlewareKey -> Foreign -> MiddlewareMap c -> Effect Unit
setMiddleware = runEffectFn3 setMiddlewareImpl

foreign import setNativeMiddlewareImpl
  :: forall c. EffectFn4 String MiddlewareKey (Array c -> Array c) (MiddlewareMap c) Unit

-- | `map.set(key, fn)` for a PureScript function, which goes in as its
-- | adapter. `kind` names the converters the adapter uses when JavaScript
-- | calls it: `"nodes"` or `"edges"`. One function always gets the same
-- | adapter, so the map reads back the same value for it.
setNativeMiddleware :: forall c. String -> MiddlewareKey -> (Array c -> Array c) -> MiddlewareMap c -> Effect Unit
setNativeMiddleware = runEffectFn4 setNativeMiddlewareImpl

foreign import deleteMiddlewareImpl :: forall c. EffectFn2 MiddlewareKey (MiddlewareMap c) Unit

-- | `map.delete(key)`.
deleteMiddleware :: forall c. MiddlewareKey -> MiddlewareMap c -> Effect Unit
deleteMiddleware = runEffectFn2 deleteMiddlewareImpl

-- | Whether the map holds anything, read when it is asked. The reducer asks
-- | inside the action, where upstream reads the map too.
foreign import hasMiddleware :: forall c. MiddlewareMap c -> Boolean

foreign import runNodesChangeMiddlewareImpl
  :: forall n. EffectFn2 (MiddlewareMap (NodeChange n)) (Array (NodeChange n)) (Array (NodeChange n))

-- | Upstream's `for (const middleware of map.values()) changes =
-- | middleware(changes)`. A `Effect`, because a consumer's middleware is
-- | JavaScript and can do anything, including writing the store.
runNodesChangeMiddleware
  :: forall n. MiddlewareMap (NodeChange n) -> Array (NodeChange n) -> Effect (Array (NodeChange n))
runNodesChangeMiddleware = runEffectFn2 runNodesChangeMiddlewareImpl

-- | A map holding these PureScript functions, in order, for tests.
foreign import nodesChangeMiddlewareFrom
  :: forall n. Array (Array (NodeChange n) -> Array (NodeChange n)) -> MiddlewareMap (NodeChange n)

-- | Upstream's change objects, both ways, for one kind of change.
type ChangeConverters c =
  { toJs :: Array c -> Foreign
  , fromJs :: Foreign -> Array c
  }

foreign import registerChangeConvertersImpl
  :: forall n e. EffectFn2 (ChangeConverters (NodeChange n)) (ChangeConverters (EdgeChange e)) Unit

-- | What a consumer's middleware, and JavaScript calling a PureScript one,
-- | converts through. `Boundary` registers these before it hands a map to
-- | JavaScript or takes one from it, which is the only way a consumer's
-- | function can be in a map.
registerChangeConverters
  :: forall n e. ChangeConverters (NodeChange n) -> ChangeConverters (EdgeChange e) -> Effect Unit
registerChangeConverters = runEffectFn2 registerChangeConvertersImpl
