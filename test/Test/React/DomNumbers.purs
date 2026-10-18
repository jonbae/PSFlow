-- | Numbers in strings the DOM reads, formatted as JavaScript formats them.
-- |
-- | The local proxy for six sites on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | which 56 `transform` rows on edge labels showed: upstream writes
-- | `translate(-1.796875 63)` and ps-flow wrote `translate(-1.796875 63.0)`.
-- | Upstream builds each string with a template literal, or hands React a
-- | number to stringify, and both print a whole number without a fraction.
-- | `show` prints `63.0`. Every check uses whole numbers for that reason.
module Test.React.DomNumbers
  ( runDomNumbersTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign.Object as Object
import Partial.Unsafe (unsafeCrashWith)
import React.Additional.MiniMap (buildPanelStyle)
import React.Additional.NodeResizer.Control (selectScale)
import React.Component.NodeWrapper.Util (nodeTransform)
import React.Container.Viewport (viewportTransform)
import React.Edge.Text (labelTransform)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import System.Constants (defaultAriaLabelConfig)
import System.Types.Geometry (Transform(..))

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

runDomNumbersTests :: Effect Unit
runDomNumbersTests = do
  log "\n=== Numbers in DOM strings, as JavaScript formats them ==="

  -- The row on the report: a 103.59375 by 26 label at (50, 76).
  assert "an edge label's transform"
    (labelTransform 50.0 76.0 103.59375 26.0 == "translate(-1.796875 63)")
  assert "the viewport's transform"
    (viewportTransform (Transform { tx: 10.0, ty: 20.0, scale: 1.0 }) == "translate(10px,20px) scale(1)")
  assert "a node's transform"
    (nodeTransform { x: 0.0, y: 150.0 } == "translate(0px,150px)")
  assert "the aria-live message for a moved node"
    ( defaultAriaLabelConfig.nodeA11yDescriptionAriaLiveMessage { direction: "right", x: 5.0, y: 20.0 }
        == "Moved selected node right. New position, x: 5, y: 20"
    )

  let
    panel = buildPanelStyle Nothing Nothing Nothing Nothing (Just 1.0) Nothing Nothing (Just 2.0) 5.0
  assert "the minimap's mask stroke width, scaled to the view"
    (Object.lookup "--xy-minimap-mask-stroke-width-props" panel == Just "5")
  assert "the minimap's node stroke width"
    (Object.lookup "--xy-minimap-node-stroke-width-props" panel == Just "2")

  let
    zoomedTo scale =
      (initialState (defaultInitialStateOptions :: InitialStateOptions Unit Unit))
        { transform = Transform { tx: 0.0, ty: 0.0, scale } }
  assert "a resize handle's scale when zoomed out"
    (selectScale true (zoomedTo 0.5) == Just "2")
  assert "a resize handle's scale when zoomed in"
    (selectScale true (zoomedTo 2.0) == Just "1")
