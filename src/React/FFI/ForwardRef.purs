-- | `React.forwardRef` FFI, for the *wrappers* in `src/Boundary/`.
-- |
-- | React reserves `ref`. It strips one out of any props record
-- | `createElement` is given, and it passes `null` when the caller supplied
-- | none — so a ref is neither a props field nor, in general, a `Ref elem`,
-- | and reaching one at all needs a binding of its own.
-- |
-- | **One binding, and where the ref goes after it.** `forwardNullableRef`
-- | hands the render function whatever React handed it, which is why the type
-- | says no more than `Nullable Foreign`. The wrapper then passes it *down* as
-- | an ordinary field — `innerRef` — because the PureScript components
-- | underneath take it that way: `React.Portal.Panel`, `React.Handle` and
-- | `React.Container.ReactFlow` each put `props.innerRef` on their own
-- | element. `PanelProps.innerRef` documents the spelling.
-- |
-- | **Two bindings this module used to have.** A typed `forwardRef`, for a
-- | PureScript component that was itself a `forwardRef`, and an
-- | `elementWithNullableRef` for handing a ref on to one. Both existed for
-- | `React.Container.ReactFlow`'s `reactFlowWithRef`, and
-- | [#27](https://github.com/jonbae/PSFlow/issues/27) removed it: one
-- | `<ReactFlow />` takes the ref as `innerRef` now, so no PureScript
-- | component on this surface is a `forwardRef` and nothing needs to pass a
-- | ref through `createElement`. The typed one also had to call `null` a
-- | `Ref elem`, which it is not.
-- |
-- | Anything else needing `forwardRef` should import from here rather than
-- | duplicating the binding.
module React.FFI.ForwardRef
  ( forwardNullableRef
  ) where

import Data.Nullable (Nullable)
import Foreign (Foreign)
import React.Basic (JSX, ReactComponent)

foreign import forwardNullableRefImpl
  :: forall props
   . String
  -> (props -> Nullable Foreign -> JSX)
  -> ReactComponent props

-- | Wrap a render function in `React.forwardRef`. The display-name argument
-- | shows up in React DevTools.
forwardNullableRef
  :: forall props
   . String
  -> (props -> Nullable Foreign -> JSX)
  -> ReactComponent props
forwardNullableRef = forwardNullableRefImpl
