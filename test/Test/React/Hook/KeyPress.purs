-- | `useKeyPress`'s decisions, one key event at a time, as upstream's
-- | `downHandler` and `upHandler` make them.
-- |
-- | Three upstream changes each have cases here, and
-- | `parity/boundary/key-press.test.mjs` holds the mounted hook to upstream's
-- | through `index.js`:
-- |
-- | * #5090: a key is released even when an input is focused.
-- | * #5118: Alt counts as a modifier, and a press on a focused button or link
-- |   isn't swallowed unless a modifier is held.
-- | * #5263: `actInsideInputWithModifier` defaults to `true`, so the
-- |   multi-selection key works while an input is focused.
module Test.React.Hook.KeyPress
  ( runKeyPressTests
  ) where

import Prelude

import Data.Array (foldl, snoc) as Array
import Data.Set as Set
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Hook.KeyPress (KeyEvent, PressedKeys, UseKeyPressOptions, defaultUseKeyPressOptions, keyDown, keyUp, noKeysPressed, watchedKeys)
import System.Types.Connection (KeyCode(..))

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

data Step = Down KeyEvent | Up KeyEvent | Reset

-- | A key event outside any input, with no modifier held.
press :: String -> String -> KeyEvent
press key code =
  { key
  , code
  , ctrlKey: false
  , metaKey: false
  , shiftKey: false
  , altKey: false
  , inInput: false
  , interactive: false
  }

-- | Run the steps from no keys held, and report after each step what the
-- | hook answers and whether the event's default was prevented.
run :: UseKeyPressOptions -> KeyCode -> Array Step -> Array String
run options keyCode steps = (Array.foldl step start steps).trace
  where
  watched = watchedKeys keyCode
  start = { held: noKeysPressed, answer: false, trace: [] }

  step
    :: { held :: PressedKeys, answer :: Boolean, trace :: Array String }
    -> Step
    -> { held :: PressedKeys, answer :: Boolean, trace :: Array String }
  step s = case _ of
    Down event ->
      let
        r = keyDown options watched event s.held
        answer = s.answer || r.press
      in
        { held: r.pressed, answer, trace: Array.snoc s.trace (shown answer r.preventDefault) }
    Up event ->
      let
        r = keyUp watched event s.held
        answer = s.answer && not r.release
      in
        { held: r.pressed, answer, trace: Array.snoc s.trace (shown answer false) }
    Reset ->
      { held: s.held { keys = Set.empty }, answer: false, trace: Array.snoc s.trace (shown false false) }

  shown answer prevented =
    (if answer then "pressed" else "released") <> (if prevented then ", prevented" else "")

defaults :: UseKeyPressOptions
defaults = defaultUseKeyPressOptions

runKeyPressTests :: Effect Unit
runKeyPressTests = do
  log "\n=== useKeyPress: each key event as upstream's handlers decide it ==="

  -- #5090
  assert "a key pressed outside an input is released by a keyup inside one"
    ( run defaults (SingleKey "a")
        [ Down (press "a" "KeyA"), Up ((press "a" "KeyA") { inInput = true }) ]
        == [ "pressed, prevented", "released" ]
    )

  -- #5118
  assert "Alt held in an input counts as a modifier, so the key is pressed"
    ( run defaults (SingleKey "a")
        [ Down ((press "a" "KeyA") { altKey = true, inInput = true }) ]
        == [ "pressed, prevented" ]
    )
  assert "a key pressed on a focused button or link isn't swallowed"
    ( run defaults (SingleKey "Enter")
        [ Down ((press "Enter" "Enter") { interactive = true }) ]
        == [ "pressed" ]
    )
  assert "unless a modifier is held"
    ( run defaults (SingleKey "Meta+Enter")
        [ Down ((press "Meta" "MetaLeft") { metaKey = true, interactive = true })
        , Down ((press "Enter" "Enter") { metaKey = true, interactive = true })
        ]
        == [ "released", "pressed, prevented" ]
    )
  assert "preventDefault: false swallows nothing"
    ( run defaults { preventDefault = false } (SingleKey "a") [ Down (press "a" "KeyA") ]
        == [ "pressed" ]
    )

  -- #5263
  assert "with no options, the multi-selection key is pressed while an input is focused"
    ( run defaults (SingleKey "Meta")
        [ Down ((press "Meta" "MetaLeft") { metaKey = true, inInput = true }) ]
        == [ "pressed, prevented" ]
    )
  assert "with actInsideInputWithModifier: false, as the delete key has it, it isn't"
    ( run defaults { actInsideInputWithModifier = false } (SingleKey "Meta")
        [ Down ((press "Meta" "MetaLeft") { metaKey = true, inInput = true }) ]
        == [ "released" ]
    )
  assert "a key without a modifier is never pressed in an input"
    ( run defaults (SingleKey "Backspace")
        [ Down ((press "Backspace" "Backspace") { inInput = true }) ]
        == [ "released" ]
    )

  -- The rest of upstream's handlers.
  assert "a code is matched by the event's code, so Space is pressed though its key is a space"
    ( run defaults (SingleKey "Space") [ Down (press " " "Space"), Up (press " " "Space") ]
        == [ "pressed, prevented", "released" ]
    )
  assert "a combination is pressed once all its keys are held"
    ( run defaults (SingleKey "Meta+s")
        [ Down ((press "Meta" "MetaLeft") { metaKey = true })
        , Down ((press "s" "KeyS") { metaKey = true })
        , Up ((press "s" "KeyS") { metaKey = true })
        ]
        == [ "released", "pressed, prevented", "released" ]
    )
  assert "a single key isn't pressed while another key is held"
    ( run defaults (SingleKey "Shift")
        [ Down (press "a" "KeyA"), Down ((press "Shift" "ShiftLeft") { shiftKey = true }) ]
        == [ "released", "released" ]
    )
  assert "any alternative of an array counts"
    ( run defaults (MultiKey [ "Meta", "Control" ])
        [ Down ((press "Control" "ControlLeft") { ctrlKey = true }) ]
        == [ "pressed, prevented" ]
    )
  assert "an empty array listens for no key, whatever the event's code"
    ( run defaults (MultiKey []) [ Down (press "" "") ] == [ "released" ] )
  assert "releasing Meta releases every key, for the keyup a Mac doesn't send"
    ( run defaults (SingleKey "a")
        [ Down ((press "Meta" "MetaLeft") { metaKey = true })
        , Down ((press "s" "KeyS") { metaKey = true })
        , Up (press "Meta" "MetaLeft")
        , Down (press "a" "KeyA")
        ]
        == [ "released", "released", "released", "pressed, prevented" ]
    )
  assert "a blur or context menu releases the key"
    ( run defaults (SingleKey "a") [ Down (press "a" "KeyA"), Reset, Up (press "a" "KeyA") ]
        == [ "pressed, prevented", "released", "released" ]
    )
  assert "'a+b+c' combines a with b+c, as upstream's first-match replace has it"
    ( (watchedKeys (SingleKey "a+b+c")).combinations == [ [ "a", "b+c" ] ]
        && (watchedKeys (SingleKey "a++")).combinations == [ [ "a", "+" ] ]
    )
