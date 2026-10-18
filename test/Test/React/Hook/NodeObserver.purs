-- | When `useNodeObserver` observes a node, and when it re-measures one, as
-- | upstream's hook does.
-- |
-- | The local proxy for `React.Hook.NodeObserver` on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
-- | which about 1,100 handle-geometry rows showed: on a flow that mounts with
-- | `fitView`, upstream's handle sits at `cx` 75 and ps-flow's at
-- | 75.00001857790781. Upstream observes a node until it is measured, and
-- | `observe` makes the shared observer report the node, which is a forced
-- | re-measure. ps-flow's hook keyed its effect on a record it built on every
-- | render, so every render unobserved and observed the node again and
-- | re-measured it at the zoom of the moment, including the fitted one.
-- |
-- | Like `Test.React.Hook.Store`, this runs the hook outside React, because
-- | `spago test` has no DOM. The renderer in `NodeObserver.js` commits each
-- | render's effects the way React does.
module Test.React.Hook.NodeObserver
  ( runNodeObserverTests
  ) where

import Prelude

import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Nullable (Nullable)
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (Ref)
import React.Basic.Hooks (Hook)
import React.Context.Store (OpaqueStore)
import React.FFI.ResizeObserver (ResizeObserver)
import React.Hook.NodeObserver (useNodeObserver)
import React.Store.Action (Action(..))
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions, initialState)
import React.Store.Shell (Store, createStore)
import System.Types.Geometry (Position(..))
import System.Types.Ids (NodeId(..))
import System.Types.Node (InternalNodeBase, NodeBase)
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML.HTMLDivElement (HTMLDivElement)

type Renderer =
  { render :: Effect (Ref (Nullable HTMLDivElement)) -> Effect (Ref (Nullable HTMLDivElement))
  , commit :: Effect Unit
  , unmount :: Effect Unit
  }

type RecordingObserver =
  { observer :: ResizeObserver
  , log :: Effect (Array String)
  }

foreign import newCommittingRenderer :: Maybe OpaqueStore -> Effect Renderer
foreign import newRecordingObserver :: Effect RecordingObserver
foreign import element :: String -> HTMLDivElement
foreign import attach :: Ref (Nullable HTMLDivElement) -> HTMLDivElement -> Effect Unit

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

-- | A `Hook` is an `Effect` with a phantom tag, run here outside React.
runHook :: forall hooks a. Hook hooks a -> Effect a
runHook = unsafeCoerce

userNode :: NodeBase Unit
userNode =
  { id: NodeId "a"
  , position: { x: 0.0, y: 0.0 }
  , data: unit
  , sourcePosition: Nothing
  , targetPosition: Nothing
  , hidden: Nothing
  , selected: Nothing
  , dragging: Nothing
  , draggable: Nothing
  , selectable: Nothing
  , connectable: Nothing
  , deletable: Nothing
  , dragHandle: Nothing
  , width: Nothing
  , height: Nothing
  , initialWidth: Nothing
  , initialHeight: Nothing
  , parentId: Nothing
  , zIndex: Nothing
  , extent: Nothing
  , expandParent: Nothing
  , ariaLabel: Nothing
  , origin: Nothing
  , handles: Nothing
  , measured: { width: Nothing, height: Nothing }
  , nodeType: Nothing
  , className: Nothing
  , style: Nothing
  }

-- | The node as the store holds it before it is measured.
unmeasured :: InternalNodeBase Unit
unmeasured =
  case Map.lookup (NodeId "a") (initialState (defaultInitialStateOptions { nodes = Just [ userNode ] })).nodeLookup of
    Just node -> node
    Nothing -> unsafeCrashWith "the node didn't adopt"

-- | The node after `updateNodeInternals` has read its handles.
measured :: InternalNodeBase Unit
measured = unmeasured { internals { handleBounds = Just { source: [], target: [] } } }

-- | A node's wrapper, rendered by a renderer with a recording store and
-- | observer. `renderWith` is one render and its commit, as `NodeWrapper`
-- | would do it with these props.
type Mounted =
  { renderWith :: InternalNodeBase Unit -> String -> Boolean -> Effect Unit
  , observed :: Effect (Array String)
  , remeasures :: Effect (Array String)
  , unmount :: Effect Unit
  }

mount :: HTMLDivElement -> Effect Mounted
mount el = do
  store <- createStore (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
  dispatched <- Ref.new ([] :: Array String)
  let
    recordUpdate :: Action Unit Unit -> Effect Unit
    recordUpdate = case _ of
      UpdateNodeInternals updates _ ->
        Ref.modify_ (\xs -> xs <> map (\u -> unwrap u.id <> (if u.force then " forced" else "")) updates) dispatched
      _ -> pure unit

    recording :: Store Unit Unit
    recording = store { dispatch = recordUpdate }
  observer <- newRecordingObserver
  renderer <- newCommittingRenderer (Just (unsafeCoerce recording))
  pure
    { renderWith: \node nodeType hasDimensions -> do
        ref <- renderer.render
          ( runHook
              ( useNodeObserver
                  { node, nodeType, hasDimensions, resizeObserver: Just observer.observer }
              )
          )
        attach ref el
        renderer.commit
    , observed: observer.log
    , remeasures: Ref.read dispatched
    , unmount: renderer.unmount
    }

runNodeObserverTests :: Effect Unit
runNodeObserverTests = do
  log "\n=== useNodeObserver: when a node is observed and re-measured ==="

  let el = element "a"
  wrapper <- mount el
  wrapper.renderWith unmeasured "default" false
  first <- wrapper.observed
  assert "a node is observed on its first render"
    (first == [ "observe a" ])

  wrapper.renderWith unmeasured "default" false
  wrapper.renderWith unmeasured "default" false
  beforeMeasure <- wrapper.observed
  assert "a re-render before it is measured doesn't observe it again"
    (beforeMeasure == [ "observe a" ])

  wrapper.renderWith measured "default" true
  wrapper.renderWith measured "default" true
  wrapper.renderWith measured "default" true
  afterMeasure <- wrapper.observed
  assert "re-renders after it is measured, such as the fitView's, don't observe it again"
    (afterMeasure == [ "observe a" ])

  none <- wrapper.remeasures
  assert "nothing re-measures a node whose type and handle positions are unchanged"
    (none == [])

  wrapper.renderWith (measured { sourcePosition = Just PosRight }) "default" true
  moved <- wrapper.remeasures
  assert "a changed source position forces a re-measure"
    (moved == [ "a forced" ])

  wrapper.renderWith (measured { sourcePosition = Just PosRight }) "default" true
  same <- wrapper.remeasures
  assert "an unchanged source position doesn't force another"
    (same == [ "a forced" ])

  wrapper.renderWith (measured { sourcePosition = Just PosRight }) "input" true
  retyped <- wrapper.remeasures
  assert "a changed type forces a re-measure"
    (retyped == [ "a forced", "a forced" ])

  wrapper.renderWith measured "input" true
  movedBack <- wrapper.remeasures
  assert "moving the source position back forces another"
    (movedBack == [ "a forced", "a forced", "a forced" ])

  wrapper.unmount
  gone <- wrapper.observed
  assert "unmounting unobserves the node"
    (gone == [ "observe a", "unobserve a" ])

  hidden <- mount (element "h")
  hidden.renderWith (unmeasured { hidden = Just true }) "default" false
  hiddenLog <- hidden.observed
  assert "a hidden node isn't observed"
    (hiddenLog == [])
