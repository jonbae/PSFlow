-- | `useNodeObserver` — hands one node's wrapper element to the renderer's
-- | shared `ResizeObserver`, and re-measures the node when its type or a
-- | handle position changes. Mirrors
-- | `xyflow/packages/react/src/components/NodeWrapper/useNodeObserver.ts`.
-- |
-- | The node is observed until it is initialized, meaning it has dimensions
-- | and handle bounds, and again only if its element changes. Every
-- | `observe` call makes the observer report the element, and the shared
-- | observer's report is a forced `updateNodeInternals`, so observing on
-- | every render re-measures the node on every render. A re-measure after
-- | the initial `fitView` reads the handles at the fitted zoom, and their
-- | bounds pick up the rounding of the scaled layout.
-- |
-- | Upstream creates the node ref here and returns it, and `NodeWrapper`
-- | hands it to `useDrag`. This does the same.
module React.Hook.NodeObserver
  ( UseNodeObserverParams
  , UseNodeObserverHook(..)
  , useNodeObserver
  ) where

import Prelude

import Data.Foldable (for_)
import Data.Map (singleton) as Map
import Data.Maybe (Maybe(..), isJust)
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Data.Tuple (Tuple)
import Data.Tuple.Nested ((/\))
import React.Basic (Ref)
import React.Basic.Hooks (Hook, UseEffect, UseRef, coerceHook, readRef, useEffect, useEffectOnce, useRef, writeRef)
import React.Basic.Hooks as React
import React.FFI.ResizeObserver (ResizeObserver, observe, unobserve)
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import System.Types.Geometry (Position)
import System.Types.Ids (NodeId)
import System.Types.Node (InternalNodeBase)
import Unsafe.Reference (unsafeRefEq)
import Web.HTML.HTMLDivElement (HTMLDivElement, toElement)

-- | TS `{ node, nodeType, hasDimensions, resizeObserver }`.
type UseNodeObserverParams n =
  { node :: InternalNodeBase n
  , nodeType :: String
  , hasDimensions :: Boolean
  , resizeObserver :: Maybe ResizeObserver
  }

newtype UseNodeObserverHook hooks =
  UseNodeObserverHook
    ( UseEffect (Tuple NodeId (Tuple String (Tuple (Maybe Position) (Maybe Position))))
        ( UseEffect Unit
            ( UseEffect (Tuple Boolean (Maybe Boolean))
                ( UseRef String
                    ( UseRef (Maybe Position)
                        ( UseRef (Maybe Position)
                            ( UseRef (Nullable HTMLDivElement)
                                (UseRef (Nullable HTMLDivElement) (UseStoreApi hooks))
                            )
                        )
                    )
                )
            )
        )
    )

derive instance newtypeUseNodeObserverHook ::
  Newtype (UseNodeObserverHook hooks) _

useNodeObserver
  :: forall n
   . UseNodeObserverParams n
  -> Hook UseNodeObserverHook (Ref (Nullable HTMLDivElement))
useNodeObserver { node, nodeType, hasDimensions, resizeObserver } = coerceHook React.do
  store <- useStoreApi
  nodeRef <- useRef (toNullable Nothing :: Nullable HTMLDivElement)
  observedNode <- useRef (toNullable Nothing :: Nullable HTMLDivElement)
  prevSourcePosition <- useRef node.sourcePosition
  prevTargetPosition <- useRef node.targetPosition
  prevType <- useRef nodeType
  let
    isInitialized = hasDimensions && isJust node.internals.handleBounds

  useEffect (isInitialized /\ node.hidden) do
    mCurrent <- toMaybe <$> readRef nodeRef
    mObserved <- toMaybe <$> readRef observedNode
    for_ mCurrent \current -> do
      let
        observedIsCurrent = case mObserved of
          Just observed -> unsafeRefEq observed current
          Nothing -> false
      when (node.hidden /= Just true && (not isInitialized || not observedIsCurrent)) do
        for_ mObserved \observed ->
          for_ resizeObserver \ro -> unobserve ro (toElement observed)
        for_ resizeObserver \ro -> observe ro (toElement current)
        writeRef observedNode (toNullable (Just current))
    pure (pure unit)

  useEffectOnce do
    pure do
      mObserved <- toMaybe <$> readRef observedNode
      for_ mObserved \observed -> do
        for_ resizeObserver \ro -> unobserve ro (toElement observed)
        writeRef observedNode (toNullable Nothing)

  -- TS: "when the user programmatically changes the source or handle
  -- position, we need to update the internals to make sure the edges are
  -- updated correctly".
  useEffect (node.id /\ nodeType /\ node.sourcePosition /\ node.targetPosition) do
    mCurrent <- toMaybe <$> readRef nodeRef
    for_ mCurrent \current -> do
      typeBefore <- readRef prevType
      sourceBefore <- readRef prevSourcePosition
      targetBefore <- readRef prevTargetPosition
      let
        typeChanged = typeBefore /= nodeType
        sourcePosChanged = sourceBefore /= node.sourcePosition
        targetPosChanged = targetBefore /= node.targetPosition
      when (typeChanged || sourcePosChanged || targetPosChanged) do
        writeRef prevType nodeType
        writeRef prevSourcePosition node.sourcePosition
        writeRef prevTargetPosition node.targetPosition
        store.dispatch
          ( UpdateNodeInternals
              (Map.singleton node.id { id: node.id, nodeElement: current, force: true })
              { triggerFitView: false }
          )
    pure (pure unit)

  pure nodeRef
