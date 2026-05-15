-- | `React.forwardRef` FFI.
-- |
-- | Used by `React.Handle` (ticket 034) to expose the inner `<div>` ref
-- | through the component's props. Other tickets that need `forwardRef`
-- | should import from here rather than duplicating the binding.
-- |
-- | `Ref` is the type already exported by `React.Basic`; we re-export it
-- | so callers don't need a second import line.
module React.FFI.ForwardRef
  ( forwardRef
  ) where

import React.Basic (JSX, Ref, ReactComponent)

foreign import forwardRefImpl
  :: forall props elem
   . String
  -> (props -> Ref elem -> JSX)
  -> ReactComponent props

-- | Wrap a render function in `React.forwardRef`. The display-name
-- | argument shows up in React DevTools.
forwardRef
  :: forall props elem
   . String
  -> (props -> Ref elem -> JSX)
  -> ReactComponent props
forwardRef = forwardRefImpl
