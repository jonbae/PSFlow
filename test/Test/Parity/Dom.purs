-- | Live differential parity for the two event-target predicates upstream
-- | #4880, "Add type check for all event targets", changed.
-- |
-- | An event's target isn't always an element: a key event can target the
-- | document or the window, and a pointer event can target a text node.
-- | Before #4880, `isInputDOMNode` called `closest` on whatever it was given,
-- | and `hasSelector` called `matches`, so both threw on those. Since,
-- | `isInputDOMNode` answers `false` for anything that isn't an element, and
-- | `hasSelector` skips what can't `matches` and climbs to its parent.
-- |
-- | The domain is finite, so it is exhausted: every kind of target, inside or
-- | outside a `.nokey` or `.nodrag` region, reached through `event.target`
-- | or through `composedPath()`, as a shadow root reports it. Both sides are
-- | handed the same stand-in objects, and a throw is an answer.
module Test.Parity.Dom
  ( runDomParity
  ) where

import Prelude

import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Unsafe (unsafePerformEffect)
import System.Utils.Dom (isInputDOMNode) as PS
import System.XYDrag.Utils (hasSelector) as PS
import Test.Oracle (DomStandIn)
import Test.Oracle (hasSelector, isInputDOMNode) as Oracle
import Test.Parity.Util (allGreen, expectGreen, falsify, strMatch)
import Unsafe.Coerce (unsafeCoerce)

foreign import keyEvents :: Array DomStandIn
foreign import dragTargets :: Array DomStandIn
foreign import dragNode :: DomStandIn
foreign import standInLabel :: DomStandIn -> String
foreign import eventLabel :: DomStandIn -> String
foreign import withoutComposedPath :: DomStandIn -> DomStandIn

-- | Run a PSFlow predicate, reporting a throw as `"throws"`.
foreign import answer :: (Unit -> Boolean) -> String

psIsInputDOMNode :: DomStandIn -> String
psIsInputDOMNode event = answer \_ -> unsafePerformEffect (PS.isInputDOMNode (unsafeCoerce event))

psHasSelector :: DomStandIn -> String -> String
psHasSelector target selector =
  answer \_ -> unsafePerformEffect (PS.hasSelector (unsafeCoerce target) selector (unsafeCoerce dragNode))

runDomParity :: Effect Unit
runDomParity = do
  log "running event-target predicate parity (PSFlow vs live XYFlow)..."

  expectGreen "isInputDOMNode agrees over every target, through target and composedPath"
    ( allGreen
        ( map
            (\e -> strMatch ("isInputDOMNode, " <> eventLabel e) (psIsInputDOMNode e) (Oracle.isInputDOMNode e))
            keyEvents
        )
    )
  expectGreen "hasSelector agrees over every target, for .nodrag and .nokey"
    ( allGreen do
        target <- dragTargets
        selector <- [ ".nodrag", ".nokey", ".react-flow__node" ]
        pure
          ( strMatch ("hasSelector " <> standInLabel target <> " " <> selector)
              (psHasSelector target selector)
              (Oracle.hasSelector target selector dragNode)
          )
    )

  falsify "isInputDOMNode: XYFlow handed each event without its composedPath"
    ( allGreen
        ( map
            (\e -> strMatch (eventLabel e) (psIsInputDOMNode e) (Oracle.isInputDOMNode (withoutComposedPath e)))
            keyEvents
        )
    )
  falsify "hasSelector: XYFlow asked for .nodrag, PSFlow for .nokey"
    ( allGreen
        ( map
            (\t -> strMatch (standInLabel t) (psHasSelector t ".nokey") (Oracle.hasSelector t ".nodrag" dragNode))
            dragTargets
        )
    )

  log "event-target predicate parity passed"
