-- | Thin FFI wrapper around `d3-drag`. Used by `XYFlow.XYDrag` and
-- | `XYFlow.XYResizer`. The configuration functions are designed to chain
-- | imperatively — each returns the same `D3DragBehavior` (post-mutation) so
-- | callers can sequence them in `Effect`.
module System.FFI.D3Drag
  ( D3DragBehavior
  , D3DragEvent
  , dragBehavior
  , setDragClickDistance
  , setDragOn
  , setDragFilter
  , applyDrag
  , dragSourceEvent
  ) where

import Prelude

import Effect (Effect)
import Foreign (Foreign)
import System.FFI.D3Selection (D3Selection)

-- | `d3.DragBehavior`. Opaque — only the configuration helpers below touch it.
foreign import data D3DragBehavior :: Type

-- | The wrapper d3 produces around the underlying `MouseEvent`/`TouchEvent` on
-- | drag callbacks. The PS layer only needs the `sourceEvent` field, exposed
-- | via `dragSourceEvent`.
foreign import data D3DragEvent :: Type

-- | `d3.drag()` — creates a fresh drag behavior. Effectful because d3
-- | allocates a closure-bound dispatcher.
foreign import dragBehavior :: Effect D3DragBehavior

-- | `behavior.clickDistance(n)` — sets the click-vs-drag threshold in pixels.
foreign import setDragClickDistance
  :: Number -> D3DragBehavior -> Effect D3DragBehavior

-- | `behavior.on(typename, fn)` — registers a handler for `start`, `drag`, or
-- | `end` (or any `.namespaced` form). The handler receives the d3 event.
foreign import setDragOn
  :: String
  -> (D3DragEvent -> Effect Unit)
  -> D3DragBehavior
  -> Effect D3DragBehavior

-- | `behavior.filter(fn)` — gates whether a pointer event begins a drag.
-- | Returning `false` from the predicate aborts. d3 catches sync exceptions,
-- | so the predicate is `Effect Boolean`.
foreign import setDragFilter
  :: (D3DragEvent -> Effect Boolean)
  -> D3DragBehavior
  -> Effect D3DragBehavior

-- | `selection.call(behavior)` — installs the drag behavior on the selected
-- | element. Equivalent to TS `d3Selection.call(d3DragInstance)`.
foreign import applyDrag :: D3Selection -> D3DragBehavior -> Effect Unit

-- | Reads `event.sourceEvent` from a d3 drag event. The result is opaque
-- | because it could be a `MouseEvent`, a `TouchEvent`, or `null` (synthetic
-- | events). Callers narrow with their own checks.
foreign import dragSourceEvent :: D3DragEvent -> Effect Foreign
