-- | The wrapper the boundary puts around a consumer's component, converted
-- | twice.
-- |
-- | The local proxy for "Find why drag hover events split by capture since
-- | useStore moved to the synchronous lane" (#138). `Boundary.Flow` converts
-- | `nodeTypes` and `edgeTypes` on every render, and each conversion wrapped
-- | every consumer component in a new function. React reconciles by the
-- | component it is handed, so every custom node and edge was unmounted and
-- | mounted again on every render of the flow. Mid-drag, the element under
-- | the pointer was replaced each step, and the browser's `mouseover` from a
-- | detached element made React fire `onMouseEnter` up the tree: that was
-- | `drag-by-custom-drag-handle`'s `onPaneMouseEnter` where upstream fires
-- | `onNodeMouseLeave`. #133's synchronous lane moved those remounts relative
-- | to the pointer events, and the extra hover callbacks started splitting
-- | by capture.
-- |
-- | A wrapper made fresh on each call, which is what `mkComponentWrapper`
-- | did before the fix, fails the first check. The two after it hold the same
-- | cache for the other two props.
module Test.Boundary.Wrapper
  ( runWrapperTests
  ) where

import Prelude

import Boundary.Edges (edgeTypesIn)
import Boundary.Elements (nodeTypesIn)
import Boundary.Wrapper (mkComponentWrapper)
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Uncurried (mkEffectFn1)
import Foreign.Object as Object
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (JSX, ReactComponent)
import Unsafe.Coerce (unsafeCoerce)
import Unsafe.Reference (unsafeRefEq)

foreign import newUserComponent :: forall props. String -> Effect (ReactComponent props)
foreign import componentAt :: forall map props. String -> map -> ReactComponent props
foreign import displayNameOf :: forall props. ReactComponent props -> String

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

renderNothing :: forall props. props -> Effect JSX
renderNothing _ = pure (unsafeCoerce unit)

runWrapperTests :: Effect Unit
runWrapperTests = do
  log "\n=== Boundary.Wrapper: one wrapper per consumer component (#138) ==="

  dragHandle <- newUserComponent "DragHandleNode"
  other <- newUserComponent "OtherNode"

  let
    nodeWrapperOf :: forall p. ReactComponent p -> ReactComponent Unit
    nodeWrapperOf c = componentAt "custom" (nodeTypesIn (Object.singleton "custom" (unsafeCoerce c)))

    edgeWrapperOf :: forall p. ReactComponent p -> ReactComponent Unit
    edgeWrapperOf c = componentAt "custom" (edgeTypesIn (Object.singleton "custom" (unsafeCoerce c)))

  assert "converting nodeTypes again hands React the same component, so a custom node stays mounted"
    (unsafeRefEq (nodeWrapperOf dragHandle) (nodeWrapperOf dragHandle))
  assert "converting edgeTypes again hands React the same component, so a custom edge stays mounted"
    (unsafeRefEq (edgeWrapperOf dragHandle) (edgeWrapperOf dragHandle))

  let
    miniMapWrapperOf :: forall p. ReactComponent p -> ReactComponent Unit
    miniMapWrapperOf c = mkComponentWrapper "MiniMap.nodeComponent" c (mkEffectFn1 renderNothing)
  assert "the MiniMap's node component is wrapped once as well"
    (unsafeRefEq (miniMapWrapperOf dragHandle) (miniMapWrapperOf dragHandle))

  assert "a component registered as both a node type and an edge type gets a wrapper for each"
    (not (unsafeRefEq (nodeWrapperOf dragHandle) (edgeWrapperOf dragHandle)))
  assert "two consumer components get two wrappers"
    (not (unsafeRefEq (nodeWrapperOf dragHandle) (nodeWrapperOf other)))
  assert "the wrapper carries the consumer component's own name"
    (displayNameOf (nodeWrapperOf dragHandle) == "DragHandleNode")
