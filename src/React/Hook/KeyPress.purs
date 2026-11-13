-- | `useKeyPress`: whether a key code is pressed. Mirrors
-- | `xyflow/packages/react/src/hooks/useKeyPress.ts`.
-- |
-- | A key code is one key, a combination such as `'Meta+s'`, or an array of
-- | either, any one of which counts. The hook listens for `keydown` and
-- | `keyup` on its target, the document unless the options name another, and
-- | for `blur` and `contextmenu` on the window, which release every key.
-- |
-- | The decisions are the pure `keyDown` and `keyUp`, over `PressedKeys`,
-- | which stand for upstream's two refs. Three upstream changes are among
-- | them:
-- |
-- | * A key is released even when an input is focused (#5090): `keyUp`
-- |   doesn't ask `isInputDOMNode`.
-- | * A key is pressed in an input when a modifier is held, Alt included,
-- |   and the press isn't swallowed when a button or link is focused, unless
-- |   a modifier is held (#5118).
-- | * `actInsideInputWithModifier` defaults to `true` (#5263), so the
-- |   multi-selection key works while an input is focused.
module React.Hook.KeyPress
  ( KeyPressTarget(..)
  , UseKeyPressOptions
  , defaultUseKeyPressOptions
  , UseKeyPressHook(..)
  , KeyMatcher
  , useKeyPress
  -- Public for testing.
  , WatchedKeys
  , watchedKeys
  , KeyEvent
  , PressedKeys
  , noKeysPressed
  , keyDown
  , keyUp
  ) where

import Prelude

import Data.Array (all, any, concat, elem, filter, length) as Array
import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Set (Set)
import Data.Set (delete, empty, insert, member, size) as Set
import Data.String (Pattern(..), Replacement(..), replace, split) as String
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import React.Basic.Hooks (Hook, UseEffect, UseRef, UseState, coerceHook, readRef, useEffect, useRef, useState, writeRef)
import React.Basic.Hooks as React
import System.Types.Connection (KeyCode(..))
import System.Utils.Dom (isInputDOMNode)
import Unsafe.Coerce (unsafeCoerce)
import Web.Event.Event (EventType(..), preventDefault)
import Web.Event.EventTarget (EventTarget, addEventListener, eventListener, removeEventListener)
import Web.HTML (window)
import Web.HTML.HTMLDocument (toEventTarget) as HTMLDocument
import Web.HTML.Window (document, toEventTarget) as Window
import Web.UIEvent.KeyboardEvent (KeyboardEvent, altKey, code, ctrlKey, key, metaKey, shiftKey, toEvent)

-- | Where the hook listens for `keydown` and `keyup`. Upstream's `target`
-- | option is `Window | Document | HTMLElement | ShadowRoot | null`, and
-- | `null` or none is the document.
data KeyPressTarget
  = OnDocument
  | OnWindow
  | On EventTarget

-- | Upstream's `UseKeyPressOptions`, with its defaults written in:
-- | `target ?? document`, `actInsideInputWithModifier ?? true`, and
-- | `preventDefault !== false`.
type UseKeyPressOptions =
  { target :: KeyPressTarget
  , actInsideInputWithModifier :: Boolean
  , preventDefault :: Boolean
  }

defaultUseKeyPressOptions :: UseKeyPressOptions
defaultUseKeyPressOptions =
  { target: OnDocument
  , actInsideInputWithModifier: true
  , preventDefault: true
  }

-- ─── The decisions ────────────────────────────────────────────────────────

-- | A key code as upstream's `useMemo` reads it: each alternative as the
-- | keys it combines, and every key flat. A key event is read by its `code`
-- | when the flat keys hold that code, and by its `key` otherwise, so both
-- | `'MetaLeft'` and `'Meta'` can be watched.
type WatchedKeys =
  { combinations :: Array (Array String)
  , keys :: Array String
  }

-- | Upstream splits each alternative with
-- | `kc.replace('+', '\n').replace('\n\n', '\n+').split('\n')`. A string
-- | pattern replaces its first match only, so `'a+b+c'` combines `'a'` and
-- | `'b+c'`, and `'a++'` combines `'a'` and `'+'`.
watchedKeys :: KeyCode -> WatchedKeys
watchedKeys keyCode =
  let
    alternatives = case keyCode of
      SingleKey k -> [ k ]
      MultiKey ks -> ks
    combine =
      String.split (String.Pattern "\n")
        <<< String.replace (String.Pattern "\n\n") (String.Replacement "\n+")
        <<< String.replace (String.Pattern "+") (String.Replacement "\n")
    combinations = map combine alternatives
  in
    { combinations, keys: Array.concat combinations }

-- | What the handlers read off a key event. `inInput` is
-- | `isInputDOMNode(event)`, and `interactive` says the event's target, or
-- | the first entry of its `composedPath()`, is a `<button>` or an `<a>`.
type KeyEvent =
  { key :: String
  , code :: String
  , ctrlKey :: Boolean
  , metaKey :: Boolean
  , shiftKey :: Boolean
  , altKey :: Boolean
  , inInput :: Boolean
  , interactive :: Boolean
  }

-- | Upstream's two refs: the keys held, and whether the last `keydown` held
-- | a modifier.
type PressedKeys =
  { keys :: Set String
  , modifierPressed :: Boolean
  }

noKeysPressed :: PressedKeys
noKeysPressed = { keys: Set.empty, modifierPressed: false }

keyOrCode :: WatchedKeys -> KeyEvent -> String
keyOrCode watched event =
  if Array.elem event.code watched.keys then event.code else event.key

-- | Whether a combination is held. On `keydown`, only a combination of as
-- | many keys as are held counts, so `'Meta'` isn't pressed by Meta+R; on
-- | `keyup`, any combination held counts.
isMatchingKey :: WatchedKeys -> Set String -> Boolean -> Boolean
isMatchingKey watched held isUp =
  Array.any (Array.all (\k -> Set.member k held))
    (Array.filter (\keys -> isUp || Array.length keys == Set.size held) watched.combinations)

-- | Upstream's `downHandler`. `press` sets the hook's answer to `true`.
keyDown
  :: forall r
   . { actInsideInputWithModifier :: Boolean, preventDefault :: Boolean | r }
  -> WatchedKeys
  -> KeyEvent
  -> PressedKeys
  -> { pressed :: PressedKeys, press :: Boolean, preventDefault :: Boolean }
keyDown options watched event pressed =
  let
    modifierPressed = event.ctrlKey || event.metaKey || event.shiftKey || event.altKey
    preventAction =
      (not modifierPressed || (modifierPressed && not options.actInsideInputWithModifier))
        && event.inInput
  in
    if preventAction then
      { pressed: pressed { modifierPressed = modifierPressed }, press: false, preventDefault: false }
    else
      let
        keys = Set.insert (keyOrCode watched event) pressed.keys
        matched = isMatchingKey watched keys false
      in
        { pressed: { keys, modifierPressed }
        , press: matched
        , preventDefault: matched && options.preventDefault && (modifierPressed || not event.interactive)
        }

-- | Upstream's `upHandler`. `release` sets the hook's answer to `false`.
-- | Releasing Meta releases every key, because a Mac sends no `keyup` for a
-- | key released while Meta is held.
keyUp :: WatchedKeys -> KeyEvent -> PressedKeys -> { pressed :: PressedKeys, release :: Boolean }
keyUp watched event pressed =
  let
    matched = isMatchingKey watched pressed.keys true
    keys
      | matched || event.key == "Meta" = Set.empty
      | otherwise = Set.delete (keyOrCode watched event) pressed.keys
  in
    { pressed: { keys, modifierPressed: false }, release: matched }

-- ─── The hook ─────────────────────────────────────────────────────────────

foreign import isInteractiveTarget :: KeyboardEvent -> Effect Boolean

readKeyEvent :: KeyboardEvent -> Effect KeyEvent
readKeyEvent event = do
  inInput <- isInputDOMNode event
  interactive <- isInteractiveTarget event
  pure
    { key: key event
    , code: code event
    , ctrlKey: ctrlKey event
    , metaKey: metaKey event
    , shiftKey: shiftKey event
    , altKey: altKey event
    , inInput
    , interactive
    }

newtype UseKeyPressHook hooks =
  UseKeyPressHook
    (UseEffect KeyMatcher (UseRef PressedKeys (UseState Boolean hooks)))

derive instance newtypeUseKeyPressHook :: Newtype (UseKeyPressHook hooks) _

-- | What the listeners depend on. Upstream's effect depends on the key code
-- | alone, so the options are read once, when the listeners are added.
newtype KeyMatcher = KeyMatcher (Maybe KeyCode)

derive newtype instance eqKeyMatcher :: Eq KeyMatcher

useKeyPress :: Maybe KeyCode -> UseKeyPressOptions -> Hook UseKeyPressHook Boolean
useKeyPress keyCode options = coerceHook React.do
  pressed /\ setPressed <- useState false
  held <- useRef noKeysPressed

  useEffect (KeyMatcher keyCode) case keyCode of
    Nothing -> pure (pure unit)
    Just code' -> do
      let watched = watchedKeys code'
      win <- window
      target <- case options.target of
        OnDocument -> HTMLDocument.toEventTarget <$> Window.document win
        OnWindow -> pure (Window.toEventTarget win)
        On t -> pure t

      down <- eventListener \e -> do
        let event = unsafeCoerce e :: KeyboardEvent
        facts <- readKeyEvent event
        r <- keyDown options watched facts <$> readRef held
        writeRef held r.pressed
        when r.preventDefault (preventDefault (toEvent event))
        when r.press (setPressed (const true))
      up <- eventListener \e -> do
        facts <- readKeyEvent (unsafeCoerce e)
        r <- keyUp watched facts <$> readRef held
        writeRef held r.pressed
        when r.release (setPressed (const false))
      reset <- eventListener \_ -> do
        p <- readRef held
        writeRef held p { keys = Set.empty }
        setPressed (const false)

      let
        windowTarget = Window.toEventTarget win
        listeners =
          [ { on: target, type_: "keydown", listener: down }
          , { on: target, type_: "keyup", listener: up }
          , { on: windowTarget, type_: "blur", listener: reset }
          , { on: windowTarget, type_: "contextmenu", listener: reset }
          ]
      for_ listeners \l -> addEventListener (EventType l.type_) l.listener false l.on
      pure (for_ listeners \l -> removeEventListener (EventType l.type_) l.listener false l.on)

  pure pressed
