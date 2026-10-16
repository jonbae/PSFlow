-- | Which `ariaLabelConfig` entry the hidden node description shows.
-- |
-- | The local proxy for the map's "node-description string missing
-- | upstream's arrow-key sentence" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's two keys read backwards against their strings:
-- | `node.a11yDescription.keyboardDisabled` holds the sentence about the
-- | arrow keys, and `node.a11yDescription.default` the one without it. Its
-- | `<A11yDescriptions />` picks them backwards too:
-- |
-- |     disableKeyboardA11y
-- |       ? ariaLabelConfig['node.a11yDescription.default']
-- |       : ariaLabelConfig['node.a11yDescription.keyboardDisabled']
-- |
-- | so the default text is right, and a consumer who overrides a key sees it
-- | under the opposite setting from its name. ps-flow picked by the names'
-- | meaning, which lost the arrow-key sentence from every flow with keyboard
-- | a11y on and put each override under the other setting.
module Test.React.Container.NodeA11yDescription
  ( runNodeA11yDescriptionTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), contains)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (JSX, element)
import React.Container.A11yDescriptions (a11yDescriptions)
import React.Context.Store (OpaqueStore, storeProvider)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import System.Constants (AriaLabelConfig, defaultAriaLabelConfig)
import Unsafe.Coerce (unsafeCoerce)

foreign import renderMarkup :: JSX -> Effect String

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

storeToOpaque :: Store Unit Unit -> OpaqueStore
storeToOpaque = unsafeCoerce

-- | The text of the node description, rendered with `config` in the store.
nodeDescription :: AriaLabelConfig -> Boolean -> Effect String
nodeDescription config disableKeyboardA11y = do
  store <- createStore (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
  store.dispatch (PatchState _ { ariaLabelConfig = config })
  markup <- renderMarkup
    ( storeProvider (Just (storeToOpaque store))
        [ element a11yDescriptions { rfId: "1", disableKeyboardA11y } ]
    )
  if contains (Pattern "id=\"react-flow__node-desc-1\"") markup then pure markup
  else unsafeCrashWith ("FAIL the node description didn't render: " <> markup)

has :: String -> String -> Boolean
has needle = contains (Pattern needle)

runNodeA11yDescriptionTests :: Effect Unit
runNodeA11yDescriptionTests = do
  log "\n=== A11yDescriptions: the node description picks upstream's key ==="

  let arrowKeys = "You can then use the arrow keys to move the node around."

  keyboardOn <- nodeDescription defaultAriaLabelConfig false
  assert "with keyboard a11y on, the default description mentions the arrow keys"
    (has arrowKeys keyboardOn)

  keyboardOff <- nodeDescription defaultAriaLabelConfig true
  assert "with keyboard a11y off, the default description doesn't"
    (has "Press enter or space to select a node." keyboardOff && not (has arrowKeys keyboardOff))

  let
    overridden = defaultAriaLabelConfig
      { nodeA11yDescriptionDefault = "Override of default"
      , nodeA11yDescriptionKeyboardDisabled = "Override of keyboardDisabled"
      }

  overriddenOn <- nodeDescription overridden false
  assert "with keyboard a11y on, a consumer's node.a11yDescription.keyboardDisabled is shown"
    (has "Override of keyboardDisabled" overriddenOn)

  overriddenOff <- nodeDescription overridden true
  assert "with keyboard a11y off, a consumer's node.a11yDescription.default is shown"
    (has "Override of default" overriddenOff)
