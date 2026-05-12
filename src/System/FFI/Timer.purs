-- | FFI wrappers for `window.setTimeout` and `window.clearTimeout`. Used by
-- | `System.XYPanZoom`'s end-handler debouncing.
module System.FFI.Timer
  ( TimeoutId
  , setTimeout
  , clearTimeout
  ) where

import Prelude

import Effect (Effect)

-- | Opaque handle around the JS timeout id. The underlying value is an `Int`
-- | in browsers and `NodeJS.Timeout` in Node — we don't differentiate.
foreign import data TimeoutId :: Type

foreign import setTimeoutImpl :: Effect Unit -> Int -> Effect TimeoutId
foreign import clearTimeoutImpl :: TimeoutId -> Effect Unit

setTimeout :: Effect Unit -> Int -> Effect TimeoutId
setTimeout = setTimeoutImpl

clearTimeout :: TimeoutId -> Effect Unit
clearTimeout = clearTimeoutImpl
