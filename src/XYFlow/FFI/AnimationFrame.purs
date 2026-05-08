-- | FFI wrappers for `window.requestAnimationFrame` and
-- | `window.cancelAnimationFrame`. Used by the auto-pan loops in
-- | `XYFlow.XYDrag` and `XYFlow.XYHandle`.
module XYFlow.FFI.AnimationFrame
  ( RafHandle
  , requestAnimationFrame
  , cancelAnimationFrame
  ) where

import Prelude

import Effect (Effect)

-- | Opaque newtype-style wrapper around the `Int` token `requestAnimationFrame`
-- | returns. Wrapped to prevent arithmetic mistakes — handles only flow back to
-- | `cancelAnimationFrame`.
newtype RafHandle = RafHandle Int

foreign import requestAnimationFrameImpl :: Effect Unit -> Effect Int
foreign import cancelAnimationFrameImpl :: Int -> Effect Unit

requestAnimationFrame :: Effect Unit -> Effect RafHandle
requestAnimationFrame action = map RafHandle (requestAnimationFrameImpl action)

cancelAnimationFrame :: RafHandle -> Effect Unit
cancelAnimationFrame (RafHandle n) = cancelAnimationFrameImpl n
