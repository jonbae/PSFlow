-- | What `<Attribution />` renders.
-- |
-- | The local proxy for the map's "attribution panel wrapping its link in a
-- | `<span>`" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream passes `data-message` to `<Panel />`, which spreads it onto its
-- | own `<div>`, and the link is the panel's only child. ps-flow's `Panel`
-- | had no way to take the attribute, so `Attribution` wrapped the link in a
-- | `<span>` that carried it.
-- |
-- | The markup is compared whole, so it also checks upstream's class order,
-- | `cc(['react-flow__panel', className, ...positionClasses])`. The net
-- | sorts class tokens and can't see that order.
module Test.React.Container.AttributionPanel
  ( runAttributionPanelTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (JSX, element)
import React.Container.Attribution (attribution)
import System.Types.Connection (PanelPosition(..))

foreign import renderMarkup :: JSX -> Effect String

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | Upstream's `<Attribution />` at `position`, as `renderToStaticMarkup`
-- | writes it.
upstreamMarkup :: String -> String
upstreamMarkup position =
  "<div class=\"react-flow__panel react-flow__attribution "
    <> position
    <> "\" data-message=\"Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev\">"
    <> "<a href=\"https://reactflow.dev\" target=\"_blank\" rel=\"noopener noreferrer\" aria-label=\"React Flow attribution\">React Flow</a>"
    <> "</div>"

runAttributionPanelTests :: Effect Unit
runAttributionPanelTests = do
  log "\n=== Attribution: the notice sits on the panel, and the link is its only child ==="

  atDefault <- renderMarkup (element attribution { proOptions: Nothing, position: Nothing })
  assert "the attribution renders upstream's markup at its default position"
    (atDefault == upstreamMarkup "bottom right")

  atTopLeft <- renderMarkup (element attribution { proOptions: Nothing, position: Just TopLeft })
  assert "the attribution renders upstream's markup at a position it's given"
    (atTopLeft == upstreamMarkup "top left")

  hidden <- renderMarkup
    (element attribution { proOptions: Just { hideAttribution: true, account: Nothing }, position: Nothing })
  assert "proOptions.hideAttribution renders nothing"
    (hidden == "")
