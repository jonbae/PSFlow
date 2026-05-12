-- | Thin FFI wrapper around `d3-selection`. Only the surface needed by the
-- | XYFlow controllers (`XYDrag`, `XYHandle`, `XYPanZoom`, `XYMinimap`) is
-- | exposed. Everything is `Effect`-typed because every d3 call mutates
-- | internal state on the selection object.
module System.FFI.D3Selection
  ( D3Selection
  , d3Select
  , d3SelectionOnNull
  , d3Pointer
  ) where

import Prelude

import Effect (Effect)
import Foreign (Foreign)
import System.Types.Geometry (XYPosition)

-- | Opaque handle to a `d3.Selection`. The phantom is the selected element
-- | type, but at the FFI boundary we don't track it — callers know what they
-- | passed in.
foreign import data D3Selection :: Type

-- | `d3.select(domNode)`. Polymorphic over the input element type because
-- | callers pass `Element`, `HTMLDivElement`, or `HTMLElement` depending on
-- | context.
foreign import d3Select :: forall a. a -> Effect D3Selection

-- | `selection.on(typeName, null)` — clears event handlers for the given
-- | dotted typename (e.g. `".drag"`). Used by `destroy` cleanup paths.
foreign import d3SelectionOnNull :: D3Selection -> String -> Effect Unit

-- | `d3.pointer(event, container)` — converts a DOM event into coordinates
-- | relative to a container element. Polymorphic over the container type.
foreign import d3Pointer
  :: forall container. Foreign -> container -> Effect XYPosition
