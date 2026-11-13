module Test.System.XYResizer (runXYResizerTests) where

import Prelude

import Boundary.Callbacks (JsOnNodesChange, JsOnResize, JsOnResizeStart, JsOnResizeEnd, JsShouldResize, onNodesChangeIn, onResizeIn, onResizeStartIn, onResizeEndIn, shouldResizeIn)
import Boundary.Elements (JsNode, nodeIn, nodeOriginIn, snapGridIn)
import Boundary.Enums (controlPositionIn, resizeDirectionIn)
import Boundary.Undefined (Undefinable, fromUndefinable, toUndefinable, pruneUndefined)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn1, mkEffectFn2, runEffectFn1, runEffectFn2)
import Foreign (Foreign)
import System.Types.Geometry (Transform(..))
import System.Types.Ids (NodeId(..))
import System.Utils.Store (adoptUserNodes, defaultUpdateNodesOptions)
import System.XYResizer (ResizeBoundaries, createXYResizer)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (createStore)
import React.Store.Action (Action(..))
import Unsafe.Coerce (unsafeCoerce)
import Web.HTML.HTMLDivElement (HTMLDivElement)

type JsUpdate =
  { controlPosition :: String, boundaries :: ResizeBoundaries, keepAspectRatio :: Boolean
  , resizeDirection :: Undefinable String
  , onResizeStart :: Undefinable JsOnResizeStart, onResize :: Undefinable JsOnResize
  , onResizeEnd :: Undefinable JsOnResizeEnd, shouldResize :: Undefinable JsShouldResize
  }

type JsStore =
  { nodes :: Array JsNode, transform :: { x :: Number, y :: Number, scale :: Number }
  , snapGrid :: Undefinable (Array Number), snapToGrid :: Boolean
  , nodeOrigin :: Array Number, paneDomNode :: Undefinable HTMLDivElement
  }

type JsParams =
  { domNode :: HTMLDivElement, nodeId :: String, getStoreItems :: Effect JsStore
  , onChange :: EffectFn2 Foreign Foreign Unit, onEnd :: EffectFn1 Foreign Unit
  }

type JsInstance = { update :: EffectFn1 JsUpdate Unit, destroy :: Effect Unit }

foreign import checkLifecycle :: EffectFn1 (EffectFn1 JsParams JsInstance) Unit
foreign import checkControl :: EffectFn2 Foreign (EffectFn1 Number Unit) Unit
foreign import checkParentControl :: EffectFn1 (EffectFn2 (Array JsNode) JsOnNodesChange Foreign) Unit
foreign import controlNode :: JsNode

-- Only adaptation at the test seam. Adoption, pointer math, the controller,
-- d3 behavior and public resize callback converters are production code.
runXYResizerTests :: Effect Unit
runXYResizerTests = do
  checkCore
  store <- createStore ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign)
    { nodes = Just [ nodeIn controlNode ] })
  runEffectFn2 checkControl (unsafeCoerce (Just store)) $ mkEffectFn1 \scale ->
    store.dispatch (PatchState _ { transform = Transform { tx: 0.0, ty: 0.0, scale } })
  runEffectFn1 checkParentControl $ mkEffectFn2 \nodes onChanges -> do
    parentStore <- createStore ((defaultInitialStateOptions :: InitialStateOptions Foreign Foreign)
      { nodes = Just (map nodeIn nodes) })
    parentStore.dispatch (PatchState _ { onNodesChange = Just (onNodesChangeIn onChanges) })
    pure (unsafeCoerce (Just parentStore))

checkCore :: Effect Unit
checkCore = runEffectFn1 checkLifecycle $ mkEffectFn1 \p -> do
  instance_ <- createXYResizer
    { domNode: p.domNode, nodeId: NodeId p.nodeId
    , getStoreItems: do
        s <- p.getStoreItems
        let adopted = adoptUserNodes (map nodeIn s.nodes) Map.empty Map.empty defaultUpdateNodesOptions
        pure
          { nodeLookup: adopted.nodeLookup
          , nodeOrder: map (NodeId <<< _.id) s.nodes
          , transform: Transform { tx: s.transform.x, ty: s.transform.y, scale: s.transform.scale }
          , snapGrid: map (snapGridIn "resize test grid") (fromUndefinable s.snapGrid)
          , snapToGrid: s.snapToGrid
          , nodeOrigin: nodeOriginIn "resize test origin" s.nodeOrigin
          , paneDomNode: fromUndefinable s.paneDomNode
          }
    , onChange: \change children -> runEffectFn2 p.onChange
        (unsafeCoerce (pruneUndefined
          { x: toUndefinable change.x, y: toUndefinable change.y
          , width: toUndefinable change.width, height: toUndefinable change.height }))
        (unsafeCoerce children)
    , onEnd: Just \final -> runEffectFn1 p.onEnd (unsafeCoerce final)
    }
  pure
    { update: mkEffectFn1 \u -> instance_.update
        { controlPosition: controlPositionIn "resize test position" u.controlPosition
        , boundaries: u.boundaries, keepAspectRatio: u.keepAspectRatio
        , resizeDirection: map (resizeDirectionIn "resize test direction") (fromUndefinable u.resizeDirection)
        , onResizeStart: map onResizeStartIn (fromUndefinable u.onResizeStart)
        , onResize: map onResizeIn (fromUndefinable u.onResize)
        , onResizeEnd: map onResizeEndIn (fromUndefinable u.onResizeEnd)
        , shouldResize: map shouldResizeIn (fromUndefinable u.shouldResize)
        }
    , destroy: instance_.destroy
    }
