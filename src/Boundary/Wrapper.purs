-- | Putting a converter between ps-flow's renderer and a consumer's own
-- | component.
-- |
-- | Three props on this surface hold components the consumer wrote and ps-flow
-- | renders: `nodeTypes` (stage 1), and `edgeTypes` and `MiniMap.nodeComponent`
-- | (stage 4). Each needs the same thing — the user's component wrapped so
-- | that what reaches it is the JS-shaped props record rather than the
-- | PureScript one the renderer builds — and the wrapper has to be a **real
-- | component function** rather than a call, because React reads
-- | `displayName`, reconciliation identity and every stack frame off the
-- | function it is handed.
-- |
-- | `react-basic`'s `reactComponent` builds one, but in `Effect`, and every
-- | prop conversion that needs this is pure. So the two lines that make a
-- | component out of a render function live in FFI here, once, instead of
-- | three times in three converter modules.
-- |
-- | It is deliberately polymorphic in both props types. The wrapper reads
-- | neither of them — it applies the render function it was handed — so a
-- | monomorphic copy per prop would be three copies of one line that can drift
-- | apart, which is the failure the boundary's own registers exist to catch.
module Boundary.Wrapper
  ( mkComponentWrapper
  ) where

import Effect.Uncurried (EffectFn1)
import React.Basic (JSX, ReactComponent)

-- | `mkComponentWrapper prop wrapped render` is a component that renders
-- | `render` and calls itself whatever `wrapped` is called.
-- |
-- | It is the same component every time it is asked for the same `prop` and
-- | `wrapped`, because React reconciles by component identity: a new wrapper
-- | per render remounted every custom node and edge on every render. So
-- | `render` must depend on nothing but `wrapped` and `prop` — the one it was
-- | first handed is the one every later call gets.
foreign import mkComponentWrapper
  :: forall js ps
   . String
  -> ReactComponent js
  -> EffectFn1 ps JSX
  -> ReactComponent ps
