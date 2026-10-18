-- | `<BaseEdge />`'s rest props, as a JavaScript consumer passes them.
-- |
-- | The local proxy for the `BaseEdge` pass-through that
-- | `custom-edge-baseedge-path` and `mount-baseline--edges-base-edge-path`
-- | report on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's component is
-- |
-- |     <path {...props} d={path} fill="none" className={cc(['react-flow__edge-path', props.className])} />
-- |
-- | after destructuring the label members and `interactionWidth`, so any
-- | other prop reaches the visible path, and `d`, `fill`, and `className` are
-- | its own. The expected markup is what that line renders.
module Test.Boundary.BaseEdgeAttributes
  ( runBaseEdgeAttributesTests
  ) where

import Prelude

import Boundary.Edges (JsBaseEdgeProps, baseEdge)
import Data.Array (head)
import Data.Maybe (fromMaybe)
import Data.String (Pattern(..), contains, split)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (ReactComponent)

foreign import renderWith :: ReactComponent JsBaseEdgeProps -> JsBaseEdgeProps -> Effect String
foreign import fixtureProps :: JsBaseEdgeProps
foreign import labelledProps :: JsBaseEdgeProps
foreign import pathOnly :: JsBaseEdgeProps

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | The visible path's opening tag: everything before the first `>`.
visiblePath :: String -> String
visiblePath markup = fromMaybe "" (head (split (Pattern ">") markup))

runBaseEdgeAttributesTests :: Effect Unit
runBaseEdgeAttributesTests = do
  log "\n=== BaseEdge's rest props reach the visible path ==="

  bare <- renderWith baseEdge pathOnly
  assert "a bare path renders upstream's two paths and nothing else"
    ( bare ==
        """<path d="M0,0 L10,10" fill="none" class="react-flow__edge-path"></path>"""
          <> """<path d="M0,0 L10,10" fill="none" stroke-opacity="0" stroke-width="20" class="react-flow__edge-interaction"></path>"""
    )

  fixture <- renderWith baseEdge fixtureProps
  let path = visiblePath fixture
  assert "the fixture's presentation attributes reach the visible path"
    ( contains (Pattern "stroke-dasharray=\"6 3\"") path
        && contains (Pattern "stroke-linecap=\"round\"") path
        && contains (Pattern "stroke-width=\"3\"") path
    )
  assert "pathLength reaches the visible path" (contains (Pattern "pathLength=\"100\"") path)
  assert "a data attribute reaches the visible path under its own name"
    (contains (Pattern "data-psflow-edge=\"base-edge-path\"") path)
  assert "aria-label reaches the visible path" (contains (Pattern "aria-label=\"edge with path attributes\"") path)
  assert "the modelled members still reach it"
    (contains (Pattern "id=\"custom-1\"") path && contains (Pattern "marker-end=\"url(#arrow)\"") path)
  assert "the interaction path carries none of them"
    (not (contains (Pattern "stroke-dasharray") (fixture `after` path)))

  labelled <- renderWith baseEdge labelledProps
  let labelledPath = visiblePath labelled
  assert "the members BaseEdge destructures stay off the path"
    ( not (contains (Pattern "label=") labelledPath)
        && not (contains (Pattern "labelX") labelledPath)
        && not (contains (Pattern "interactionWidth") labelledPath)
    )
  assert "BaseEdge's fill wins over the consumer's" (contains (Pattern "fill=\"none\"") labelledPath && not (contains (Pattern "red") labelledPath))
  assert "the consumer's className joins BaseEdge's"
    (contains (Pattern "class=\"react-flow__edge-path mine\"") labelledPath)
  where
  after whole prefix = case split (Pattern prefix) whole of
    [ _, rest ] -> rest
    _ -> whole
