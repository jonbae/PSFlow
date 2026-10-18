-- | Where `<Background />` puts its pattern.
-- |
-- | The local proxy for the background rows on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | 13 scenarios with a `pattern` upstream has under the `<svg>` and a `defs`
-- | ps-flow had in its place. Upstream's `Background.tsx` renders
-- |
-- |     <svg className="react-flow__background" … data-testid="rf__background">
-- |       <pattern id={_patternId} …>…</pattern>
-- |       <rect x="0" y="0" width="100%" height="100%" fill={`url(#${_patternId})`} />
-- |     </svg>
-- |
-- | with no `<defs>`, so the pattern is the svg's first child.
module Test.React.Additional.BackgroundPattern
  ( runBackgroundPatternTests
  ) where

import Prelude

import Boundary.Chrome (JsBackgroundProps, background)
import Boundary.Flow (JsFlowProps, reactFlow)
import Data.String (Pattern(..), contains)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (ReactComponent)

foreign import renderBackground
  :: ReactComponent JsFlowProps -> ReactComponent JsBackgroundProps -> JsBackgroundProps -> Effect String
foreign import noProps :: JsBackgroundProps
foreign import dots :: JsBackgroundProps

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

has :: String -> String -> Boolean
has needle = contains (Pattern needle)

runBackgroundPatternTests :: Effect Unit
runBackgroundPatternTests = do
  log "\n=== Background's pattern sits directly in its svg ==="

  svg <- renderBackground reactFlow background noProps
  assert "the background renders" (has "data-testid=\"rf__background\"" svg)
  assert "the pattern is the svg's first child" (has "data-testid=\"rf__background\"><pattern " svg)
  assert "no defs wraps it" (not (has "<defs" svg))
  assert "the rect follows the pattern and fills with it"
    (has "</pattern><rect x=\"0\" y=\"0\" width=\"100%\" height=\"100%\" fill=\"url(#pattern-1)\">" svg)

  dotted <- renderBackground reactFlow background dots
  assert "a dot pattern with an id sits the same way"
    ( has "data-testid=\"rf__background\"><pattern id=\"pattern-12\"" dotted
        && has "<circle" dotted
        && not (has "<defs" dotted)
    )
