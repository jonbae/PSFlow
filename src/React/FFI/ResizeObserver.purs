-- | Hand-rolled FFI shim around the browser `ResizeObserver` API. Used
-- | by the node-wrapper resize hook (`React.Hook.NodeObserver`) and the
-- | flow-container resize hook (`React.Hook.ResizeHandler`).
-- |
-- | Avoids the additional `web-resize-observer` Spago dependency — the
-- | surface area we need is small enough to wrap directly. Mirrors the
-- | `System.FFI.AnimationFrame` template (a few thin imports, one
-- | opaque foreign type).
module React.FFI.ResizeObserver
  ( ResizeObserver
  , ResizeObserverEntry
  , createResizeObserver
  , observe
  , unobserve
  , disconnect
  ) where

import Prelude

import Effect (Effect)
import Web.DOM.Element (Element)

-- | Opaque handle to a JS `ResizeObserver` instance. Lifecycle is
-- | managed by the calling hook (typically a `useEffect` that
-- | `disconnect`s on cleanup).
foreign import data ResizeObserver :: Type

-- | One entry in the observer's callback array. We expose only the two
-- | fields the React-Flow hooks actually consume — the contained
-- | bounding rect (in CSS pixels) and the observed element. Other
-- | fields (`borderBoxSize`, `contentBoxSize`) are intentionally
-- | omitted; add as needed.
type ResizeObserverEntry =
  { contentRect ::
      { x :: Number
      , y :: Number
      , width :: Number
      , height :: Number
      , top :: Number
      , right :: Number
      , bottom :: Number
      , left :: Number
      }
  , target :: Element
  }

foreign import createResizeObserver
  :: (Array ResizeObserverEntry -> Effect Unit) -> Effect ResizeObserver

foreign import observe :: ResizeObserver -> Element -> Effect Unit

foreign import unobserve :: ResizeObserver -> Element -> Effect Unit

foreign import disconnect :: ResizeObserver -> Effect Unit
