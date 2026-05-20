-- | `useUpdateNodeInternals` — returns a function that re-measures the
-- | DOM dimensions of one or more nodes and pushes the result into the
-- | store. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useUpdateNodeInternals.ts`.
-- |
-- | **API divergence.** TS accepts `string | string[]`; PS accepts
-- | `Array String` only. Call sites that used to write
-- | `updateNodeInternals(id)` now write `updateNodeInternals [id]`.
-- |
-- | The function:
-- |   1. Reads the store's `domNode` (the `.react-flow` wrapper).
-- |   2. For each id, queries `.react-flow__node[data-id="<id>"]` to
-- |      find the wrapper element.
-- |   3. Builds an `InternalNodeUpdate { id, nodeElement, force: true }`
-- |      for each found element and inserts into a `Map String _`.
-- |   4. Defers the dispatch into a `requestAnimationFrame` so the
-- |      browser has a chance to lay out any handle changes before we
-- |      measure them — matches upstream behaviour.
module React.Hook.UpdateNodeInternals
  ( UseUpdateNodeInternals(..)
  , useUpdateNodeInternals
  ) where

import Prelude

import Data.Foldable (foldl)
import Data.Map (empty, insert) as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Nullable (Nullable, toMaybe)
import Data.Traversable (traverse)
import Effect (Effect)
import React.Basic.Hooks (Hook, UseMemo, coerceHook, useMemo)
import React.Basic.Hooks as React
import React.Hook.Store (UseStoreApi, useStoreApi)
import React.Store.Action (Action(..))
import React.Store.Shell (Store)
import System.FFI.AnimationFrame (requestAnimationFrame)
import System.Types.Node (InternalNodeUpdate)
import Web.HTML.HTMLDivElement (HTMLDivElement)

-- | One foreign import: query the `domNode` for a node-wrapper element
-- | by data-id. Returns a `Nullable` so the PS side can convert to
-- | `Maybe` at the seam (`toMaybe`).
foreign import querySelectorNodeImpl
  :: HTMLDivElement -> String -> Effect (Nullable HTMLDivElement)

querySelectorNode :: HTMLDivElement -> String -> Effect (Maybe HTMLDivElement)
querySelectorNode host nodeId = map toMaybe (querySelectorNodeImpl host nodeId)

newtype UseUpdateNodeInternals hooks =
  UseUpdateNodeInternals
    (UseMemo Unit (Array String -> Effect Unit) (UseStoreApi hooks))

derive instance newtypeUseUpdateNodeInternals ::
  Newtype (UseUpdateNodeInternals hooks) _

useUpdateNodeInternals
  :: Hook UseUpdateNodeInternals (Array String -> Effect Unit)
useUpdateNodeInternals = coerceHook React.do
  store <- (useStoreApi :: Hook UseStoreApi _)
  fn <- useMemo unit \_ -> mkFn store
  pure fn

mkFn :: forall n e. Store n e -> Array String -> Effect Unit
mkFn store ids = do
  s <- store.getState
  case s.domNode of
    Nothing -> pure unit
    Just hostDiv -> do
      pairs <- traverse (queryOne hostDiv) ids
      let
        updates =
          foldl insertUpdate (Map.empty :: _) pairs
      _ <- requestAnimationFrame do
        store.dispatch
          ( UpdateNodeInternals updates
              { triggerFitView: false }
          )
      pure unit
  where
  queryOne hostDiv nodeId = do
    mEl <- querySelectorNode hostDiv nodeId
    pure (Tuple nodeId mEl)

  insertUpdate acc (Tuple nodeId mEl) = case mEl of
    Nothing -> acc
    Just el -> Map.insert nodeId (mkUpdate nodeId el) acc

  mkUpdate :: String -> HTMLDivElement -> InternalNodeUpdate
  mkUpdate nodeId el =
    { id: nodeId
    , nodeElement: el
    , force: true
    }

-- | Internal tuple used while building the lookup map. Inlined here so
-- | the hook doesn't depend on `Data.Tuple` at the FFI seam.
data Tuple a b = Tuple a b
