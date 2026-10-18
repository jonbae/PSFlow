-- | The MiniMap mask's `d`, against the strings upstream renders.
-- |
-- | The local proxy for the mask rows on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | 26 of them across 19 scenarios. Upstream's `MiniMap.tsx` writes the path
-- | as a template literal broken across two source lines:
-- |
-- |     d={`M${x - offset},${y - offset}h${width + offset * 2}v${height + offset * 2}h${-width - offset * 2}z
-- |         M${viewBB.x},${viewBB.y}h${viewBB.width}v${viewBB.height}h${-viewBB.width}z`}
-- |
-- | so the subpaths are joined by a newline and eight spaces. JavaScript
-- | normalizes a CRLF in a template literal to LF, so a Windows checkout
-- | renders the same string. The expected values are the ones upstream's
-- | traces hold, in `click-connect-reverse-direction` and a fractional one.
module Test.React.Additional.MiniMapMask
  ( runMiniMapMaskTests
  ) where

import Prelude

import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Additional.MiniMap (maskPath)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

runMiniMapMaskTests :: Effect Unit
runMiniMapMaskTests = do
  log "\n=== The MiniMap mask path, as upstream renders it ==="

  assert "the two subpaths are joined by a newline and eight spaces"
    ( maskPath { x: -54.0, y: -174.0, width: 1388.0, height: 1068.0, offset: 10.0 }
        { x: 0.0, y: 0.0, width: 1280.0, height: 720.0 }
        == "M-64,-184h1408v1088h-1408z\n        M0,0h1280v720h-1280z"
    )

  assert "fractional coordinates print as JavaScript prints them"
    ( maskPath { x: -261.0, y: -137.5, width: 672.0, height: 512.0, offset: 16.0 }
        { x: -245.0, y: -61.5, width: 640.0, height: 360.0 }
        == "M-277,-153.5h704v544h-704z\n        M-245,-61.5h640v360h-640z"
    )
