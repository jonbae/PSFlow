-- | Where `<NodeToolbar />` portals to, and the style it writes there.
-- |
-- | The local proxy for the map's "`NodeToolbar` portalling to the wrong
-- | host and dropping its `z-index`" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `<NodeToolbarPortal />` portals into
-- | `state.domNode?.querySelector('.react-flow__renderer')`, and ps-flow
-- | portalled into `domNode` itself. Upstream's wrapper style is
-- | `{ position: 'absolute', transform, zIndex, ...style }`. ps-flow wrote
-- | `zIndex` with `show`, so `1.0`, which isn't a CSS integer and which a
-- | browser drops; it wrote its own keys over the consumer's style; and it
-- | floored the z-index at `0`, where `Math.max` doesn't.
module Test.React.Additional.NodeToolbarPortal
  ( runNodeToolbarPortalTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Foreign.Object (Object)
import Foreign.Object as Object
import Partial.Unsafe (unsafeCrashWith)
import React.Additional.NodeToolbar (toolbarWrapperStyle, toolbarZIndex)
import React.Additional.NodeToolbar.Portal (selectTarget)
import React.Basic.Hooks (UnsafeReference(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import Unsafe.Coerce (unsafeCoerce)

foreign import renderer :: forall a. a
foreign import fakeRoot :: forall a. a
foreign import sameRef :: forall a b. a -> b -> Boolean

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

entries :: Object String -> Array (Tuple String String)
entries = Object.toUnfoldable

runNodeToolbarPortalTests :: Effect Unit
runNodeToolbarPortalTests = do
  log "\n=== NodeToolbar: the renderer is the portal's host, and the z-index survives ==="

  let
    state = (initialState (defaultInitialStateOptions :: InitialStateOptions Unit Unit))
      { domNode = Just (unsafeCoerce fakeRoot) }
  assert "the toolbar portals into the flow's .react-flow__renderer"
    ( case selectTarget state of
        Just (UnsafeReference el) -> sameRef el renderer
        Nothing -> false
    )

  assert "the z-index is written as JavaScript writes the number"
    (Object.lookup "zIndex" (toolbarWrapperStyle Nothing "t" 1.0) == Just "1")
  assert "the consumer's style wins, and its keys come after upstream's"
    ( entries (toolbarWrapperStyle (Just (Object.fromFoldable [ Tuple "zIndex" "5", Tuple "color" "red" ])) "t" 1.0)
        == [ Tuple "position" "absolute", Tuple "transform" "t", Tuple "zIndex" "5", Tuple "color" "red" ]
    )

  assert "the z-index is one above the highest node's"
    (toolbarZIndex [ 0.0, 1000.0 ] == 1001.0)
  assert "the z-index isn't floored at 0, as Math.max's isn't"
    (toolbarZIndex [ -5.0 ] == -4.0)
