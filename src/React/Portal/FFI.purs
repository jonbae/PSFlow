-- | FFI shim around `react-dom`'s `createPortal`. The single binding is
-- | curried so callers can write `createPortal jsx el` to render `jsx`
-- | into the DOM `Element` `el` while keeping React's component tree
-- | wiring intact.
module React.Portal.FFI
  ( createPortal
  ) where

import React.Basic (JSX)
import Web.DOM.Element (Element)

foreign import createPortal :: JSX -> Element -> JSX
