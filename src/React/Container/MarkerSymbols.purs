-- | SVG arrowhead "symbols" inserted as children of `<marker>` elements
-- | by `MarkerDefinitions`. Mirrors
-- | `xyflow-main/packages/react/src/container/EdgeRenderer/MarkerSymbols.tsx`.
-- |
-- | **Divergence from TS.** The TS source exposes a `MarkerSymbols`
-- | object (keyed on `MarkerType` strings) plus a `useMarkerSymbol`
-- | hook that returns the matching component or fires `onError "009"`
-- | on miss. PS's `MarkerType` is a closed ADT (`Arrow` /
-- | `ArrowClosed`), so the lookup is total and a hook is unnecessary.
-- | We export a pure `markerSymbol :: MarkerType -> SymbolProps -> JSX`
-- | instead. (Ticket-040 calls for a `Component MarkerSymbolsProps`,
-- | but TS has no such component — it's a lookup table.)
module React.Container.MarkerSymbols
  ( SymbolProps
  , arrowSymbol
  , arrowClosedSymbol
  , markerSymbol
  ) where

import Data.Maybe (Maybe(..))
import Foreign (Foreign)
import React.Basic (JSX)
import React.FFI.DOM (polyline_)
import System.Types.Edge (MarkerType(..))
import Unsafe.Coerce (unsafeCoerce)

-- | Inputs to a single arrowhead symbol. `color = Nothing` produces no
-- | `stroke` (TS's `none` default). `strokeWidth = Nothing` defaults to
-- | `1` (TS's destructuring default).
type SymbolProps =
  { color :: Maybe String
  , strokeWidth :: Maybe Number
  }

toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

-- | `<polyline>` for the open arrow. Matches TS exactly: `class="arrow"`,
-- | `points="-5,-4 0,0 -5,4"`, `stroke-linecap="round"`,
-- | `stroke-linejoin="round"`, `fill="none"`, inline style with
-- | `strokeWidth` (and `stroke` when `color` is set).
arrowSymbol :: SymbolProps -> JSX
arrowSymbol p =
  polyline_
    { className: "arrow"
    , style: case p.color of
        Just c -> toForeignStyle
          { strokeWidth: case p.strokeWidth of
              Just w -> w
              Nothing -> 1.0
          , stroke: c
          }
        Nothing -> toForeignStyle
          { strokeWidth: case p.strokeWidth of
              Just w -> w
              Nothing -> 1.0
          }
    , strokeLinecap: "round"
    , fill: "none"
    , strokeLinejoin: "round"
    , points: "-5,-4 0,0 -5,4"
    }
    []

-- | `<polyline>` for the closed arrow. Same as `arrowSymbol` but the
-- | points list is closed (`-5,-4 0,0 -5,4 -5,-4`) and the inline style
-- | also sets `fill: color` (when color is set) so the polygon is
-- | filled.
arrowClosedSymbol :: SymbolProps -> JSX
arrowClosedSymbol p =
  polyline_
    { className: "arrowclosed"
    , style: case p.color of
        Just c -> toForeignStyle
          { strokeWidth: case p.strokeWidth of
              Just w -> w
              Nothing -> 1.0
          , stroke: c
          , fill: c
          }
        Nothing -> toForeignStyle
          { strokeWidth: case p.strokeWidth of
              Just w -> w
              Nothing -> 1.0
          }
    , strokeLinecap: "round"
    , strokeLinejoin: "round"
    , points: "-5,-4 0,0 -5,4 -5,-4"
    }
    []

-- | Total lookup. PS's `MarkerType` is closed, so this never misses —
-- | the TS `onError "009"` branch is unreachable here.
markerSymbol :: MarkerType -> SymbolProps -> JSX
markerSymbol = case _ of
  Arrow -> arrowSymbol
  ArrowClosed -> arrowClosedSymbol
