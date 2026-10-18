-- | `<ReactFlow />`'s rest props, as a JavaScript consumer passes them.
-- |
-- | The local proxy for `flow-custom-testid`, the last scenario that drove
-- | differently on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's wrapper is
-- |
-- |     <div data-testid="rf__wrapper" {...rest} onScroll={…} style={…} ref={ref}
-- |          className={cc(['react-flow', className, colorModeClassName])} id={id} role="application">
-- |
-- | so the rest replaces the test id, and `style`, `className`, `id`, and
-- | `role` are the wrapper's. The expected markup is what that renders.
module Test.Boundary.FlowWrapperAttributes
  ( runFlowWrapperAttributesTests
  ) where

import Prelude

import Boundary.Flow (JsFlowProps, reactFlow)
import Data.String (Pattern(..), contains)
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign (Foreign)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (ReactComponent)

foreign import renderWrapper :: ReactComponent JsFlowProps -> Foreign -> Effect String
foreign import noProps :: Foreign
foreign import customTestId :: Foreign
foreign import mixed :: Foreign
foreign import styled :: Foreign

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

has :: String -> String -> Boolean
has needle = contains (Pattern needle)

runFlowWrapperAttributesTests :: Effect Unit
runFlowWrapperAttributesTests = do
  log "\n=== ReactFlow's rest props reach the wrapper ==="

  bare <- renderWrapper reactFlow noProps
  assert "without a test id, the wrapper keeps upstream's" (has "data-testid=\"rf__wrapper\"" bare)
  assert "and carries no attribute a consumer didn't pass"
    (not (has "aria-label" bare) && not (has " id=" bare))

  custom <- renderWrapper reactFlow customTestId
  assert "a consumer's data-testid replaces rf__wrapper"
    (has "data-testid=\"psflow-custom-flow\"" custom && not (has "rf__wrapper" custom))

  wrapper <- renderWrapper reactFlow mixed
  assert "aria-label and a data attribute reach the wrapper"
    (has "aria-label=\"my flow\"" wrapper && has "data-owner=\"tests\"" wrapper)
  assert "id reaches the wrapper, as upstream sets it there" (has "id=\"flow-a\"" wrapper)
  assert "the wrapper's role wins over the consumer's"
    (has "role=\"application\"" wrapper && not (has "role=\"none\"" wrapper))
  assert "the consumer's className joins the wrapper's" (has "class=\"react-flow mine" wrapper)
  assert "members JsFlowProps names stay off the wrapper"
    (not (has "fitView" wrapper) && not (has "minZoom" wrapper) && not (has "fitview" wrapper))

  styledWrapper <- renderWrapper reactFlow styled
  assert "the consumer's style sits under the wrapper's sizing"
    ( has "background:red" styledWrapper
        && has "width:100%" styledWrapper
        && not (has "width:50%" styledWrapper)
    )
