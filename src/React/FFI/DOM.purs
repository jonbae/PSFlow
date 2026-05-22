-- | Minimal SVG/HTML element FFI for the React-renderer tickets
-- | (032 — built-in edges, 033 — built-in nodes, 034 — `Handle`).
-- |
-- | Each binding is a thin wrapper over `React.createElement(tag, props,
-- | ...children)`. Props rows are untyped — callers pass plain records,
-- | JS-side spreads them onto the element. Type checking SVG attributes
-- | per-tag is deferred to a future migration to `react-basic-dom`.
-- |
-- | `textContent` produces a raw-text JSX node from a string, equivalent
-- | to inlining `{label}` inside an SVG `<text>` element.
module React.FFI.DOM
  ( div_
  , span_
  , g_
  , path_
  , text_
  , rect_
  , circle_
  , foreignObject_
  , svg_
  , defs_
  , marker_
  , polyline_
  , symbol_
  , textContent
  , opt
  ) where

import Prelude

import Data.Maybe (Maybe)
import Data.Nullable (toNullable)
import React.Basic (JSX)
import Unsafe.Coerce (unsafeCoerce)

foreign import div_ :: forall p. Record p -> Array JSX -> JSX
foreign import span_ :: forall p. Record p -> Array JSX -> JSX
foreign import g_ :: forall p. Record p -> Array JSX -> JSX
foreign import path_ :: forall p. Record p -> Array JSX -> JSX
foreign import text_ :: forall p. Record p -> Array JSX -> JSX
foreign import rect_ :: forall p. Record p -> Array JSX -> JSX
foreign import circle_ :: forall p. Record p -> Array JSX -> JSX
foreign import foreignObject_ :: forall p. Record p -> Array JSX -> JSX
foreign import svg_ :: forall p. Record p -> Array JSX -> JSX
foreign import defs_ :: forall p. Record p -> Array JSX -> JSX
foreign import marker_ :: forall p. Record p -> Array JSX -> JSX
foreign import polyline_ :: forall p. Record p -> Array JSX -> JSX
foreign import symbol_ :: forall p. Record p -> Array JSX -> JSX

-- | A bare string rendered as a React text child. React accepts strings
-- | directly as JSX children, so the cast is sound.
textContent :: String -> JSX
textContent = unsafeCoerce

-- | Convert a `Maybe a` into something the untyped DOM-prop records can
-- | accept. `Nothing` becomes JS `null` (which React treats the same as
-- | a missing/undefined prop); `Just x` becomes `x`. Used pervasively
-- | by the built-in edge/node/handle components.
opt :: forall a. Maybe a -> a
opt = unsafeCoerce <<< toNullable
