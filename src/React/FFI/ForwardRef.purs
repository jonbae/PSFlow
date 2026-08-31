-- | `React.forwardRef` FFI, and the two things a *wrapper* needs beside it.
-- |
-- | `forwardRef` is the typed one, for a component that uses the ref it is
-- | handed: `React.Container.ReactFlow`'s `reactFlowWithRef` puts it on the
-- | outer `<div>`.
-- |
-- | The other two exist for the boundary module, where a wrapper is handed a
-- | ref for a component one level down and never looks at it. React reserves
-- | `ref`, strips it out of any props record `createElement` is given, and
-- | passes `null` when the caller supplied none — so forwarding one is neither
-- | a props field nor a `Ref elem`, and both of those facts need their own
-- | binding. Boundary stage 4 is what needed them: `<Panel />`, `<Handle />`
-- | and `<ReactFlowWithRef />` accepted a ref and dropped it until then.
-- |
-- | Anything else needing `forwardRef` should import from here rather than
-- | duplicating the binding.
module React.FFI.ForwardRef
  ( forwardRef
  , forwardNullableRef
  , elementWithNullableRef
  ) where

import Data.Nullable (Nullable)
import Foreign (Foreign)
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

-- | `React.forwardRef`, handing the render function whatever React handed it —
-- | `null` when the caller passed no ref, and otherwise an object or a
-- | callback, which is why the type says no more than `Foreign`.
-- |
-- | The typed `forwardRef` above is for a component that *uses* the ref.
-- | `Boundary.Chrome` and `Boundary.NodeChrome` do not: they pass it down to a
-- | PureScript component that puts it on a DOM node and reads nothing out of
-- | it, and `Ref elem` would make them invent an `elem` they never look at —
-- | and would type `null` as if it were a ref.
foreign import forwardNullableRefImpl
  :: forall props
   . String
  -> (props -> Nullable Foreign -> JSX)
  -> ReactComponent props

forwardNullableRef
  :: forall props
   . String
  -> (props -> Nullable Foreign -> JSX)
  -> ReactComponent props
forwardNullableRef = forwardNullableRefImpl

-- | `React.createElement(component, { …props, ref })`.
-- |
-- | The one way to hand a ref *on* to another component: `React.Basic`'s
-- | `element` takes a props record, and a `ref` inside one is removed by
-- | `createElement` before the component sees it — so a ref cannot travel as
-- | an ordinary field and a wrapper that wants to forward one needs this.
-- |
-- | `Boundary.Flow` is the caller: `ReactFlowWithRef` crosses as a
-- | `forwardRef` whose ref belongs to the PureScript `forwardRef` underneath
-- | it, and without this the wrapper would accept a ref and drop it, which is
-- | the exact failure the component exists to fix.
foreign import elementWithNullableRef
  :: forall props
   . ReactComponent props
  -> props
  -> Nullable Foreign
  -> JSX
