-- | `useKeyPress` — track whether a key (or any of an array of keys) is
-- | currently pressed. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useKeyPress.ts`.
-- |
-- | Subscribes to window `keydown`/`keyup` for the lifetime of the
-- | calling component. Returns the current pressed-state boolean.
-- |
-- | **Divergences from TS.** The TS source supports:
-- |   * `target?: Window | Document | HTMLElement` — we always listen
-- |     on `window`; targeting a custom element is deferred.
-- |   * `preventDefault?: boolean` — defaulting to `true` in TS,
-- |     defaulting to `false` here (we never `event.preventDefault()`).
-- |   * `actInsideInputWithModifier?: boolean` — supported, see field.
-- |
-- | If a node `KeyCode = Nothing`, the hook is a no-op and always
-- | returns `false`. This mirrors TS's "no keyCode → never pressed"
-- | behaviour and lets a `Maybe KeyCode` prop drop straight through.
module React.Hook.KeyPress
  ( UseKeyPressOptions
  , UseKeyPressHook(..)
  , KeyMatcher
  , useKeyPress
  ) where

import Prelude

import Data.Array (any) as Array
import Data.Array.NonEmpty (toArray) as NEA
import Data.Foldable (any) as F
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (class Newtype)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import React.Basic.Hooks (Hook, UseEffect, UseState, coerceHook, useEffect, useState)
import React.Basic.Hooks as React
import System.Types.Connection (KeyCode(..))
import System.Utils.Dom (isInputDOMNode)
import Web.Event.Event (EventType(..))
import Web.Event.EventTarget (addEventListener, eventListener, removeEventListener)
import Web.HTML (window)
import Web.HTML.Window (toEventTarget)
import Web.UIEvent.KeyboardEvent (KeyboardEvent, ctrlKey, fromEvent, key, metaKey)
import Web.UIEvent.KeyboardEvent.EventTypes as KE

-- | A scaled-down `UseKeyPressOptions`.
type UseKeyPressOptions =
  { -- | When `true`, the hook also fires while the user is typing into
    -- | an input field — provided one of `ctrl`/`meta` is held. Matches
    -- | TS semantics for power-user shortcuts.
    actInsideInputWithModifier :: Boolean
  }

newtype UseKeyPressHook hooks =
  UseKeyPressHook
    ( UseEffect KeyMatcher (UseState Boolean hooks) )

derive instance newtypeUseKeyPressHook :: Newtype (UseKeyPressHook hooks) _

-- | Internal — what we close over inside `useEffect`. Has its own `Eq`
-- | so `useEffect` re-runs when the keycode or option flag changes.
newtype KeyMatcher = KeyMatcher
  { codes :: Array String
  , actInsideInputWithModifier :: Boolean
  }

derive newtype instance eqKeyMatcher :: Eq KeyMatcher

useKeyPress
  :: Maybe KeyCode
  -> Maybe UseKeyPressOptions
  -> Hook UseKeyPressHook Boolean
useKeyPress mKeyCode mOpts = coerceHook React.do
  pressed /\ setPressed <- useState false
  let
    codes = case mKeyCode of
      Nothing -> []
      Just (SingleKey k) -> [ k ]
      Just (MultiKey ks) -> NEA.toArray ks
    opts = fromMaybe { actInsideInputWithModifier: false } mOpts
    matcher = KeyMatcher
      { codes, actInsideInputWithModifier: opts.actInsideInputWithModifier }

  useEffect matcher do
    case codes of
      [] -> pure (pure unit) -- nothing to listen for
      _ -> do
        win <- window
        let target = toEventTarget win

        let
          matchesEvent :: KeyboardEvent -> Boolean
          matchesEvent ev = F.any (_ == key ev) codes

          guarded :: (Boolean -> Effect Unit) -> KeyboardEvent -> Effect Unit
          guarded set ev = do
            inInput <- isInputDOMNode ev
            let withModifier = ctrlKey ev || metaKey ev
            let skip = inInput && not
                  (opts.actInsideInputWithModifier && withModifier)
            if skip then pure unit
            else if matchesEvent ev then set true *> pure unit
            else pure unit

        downListener <- eventListener \evt -> case fromEvent evt of
          Just ke -> guarded
            (\b -> setPressed (const b))
            ke
          Nothing -> pure unit
        upListener <- eventListener \evt -> case fromEvent evt of
          Just ke ->
            if Array.any (_ == key ke) codes then
              setPressed (const false)
            else pure unit
          Nothing -> pure unit

        addEventListener (EventType (eventTypeName KE.keydown))
          downListener false target
        addEventListener (EventType (eventTypeName KE.keyup))
          upListener false target

        pure do
          removeEventListener (EventType (eventTypeName KE.keydown))
            downListener false target
          removeEventListener (EventType (eventTypeName KE.keyup))
            upListener false target

  pure pressed

-- | Extract the `String` payload of an `EventType`. `web-events`
-- | exposes the constructor only with explicit pattern-matching.
eventTypeName :: EventType -> String
eventTypeName (EventType s) = s
