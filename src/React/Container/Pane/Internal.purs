-- | Pure helpers extracted from `React.Container.Pane`, separated so
-- | tests can import them without triggering the `React.Basic.Hooks`
-- | runtime chain (which transitively requires the npm `react`
-- | package).
module React.Container.Pane.Internal
  ( paneIsDraggable
  , buildPaneClass
  ) where

import Prelude

import Data.Array (filter) as Array
import Data.Array.NonEmpty (elem) as NEA
import Data.String (joinWith) as String
import System.Types.PanZoom (PanOnDrag(..))

buildPaneClass :: { draggable :: Boolean, dragging :: Boolean, isSelecting :: Boolean } -> String
buildPaneClass p =
  String.joinWith " " $ Array.filter (_ /= "")
    [ "react-flow__pane"
    , if p.draggable then "draggable" else ""
    , if p.dragging then "dragging" else ""
    , if p.isSelecting then "selection" else ""
    ]

paneIsDraggable :: PanOnDrag -> Boolean
paneIsDraggable = case _ of
  NoPan -> false
  PanAlways -> true
  PanOnButtons buttons -> NEA.elem 0 buttons
