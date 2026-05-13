-- | `Effect`-typed shell around the pure reducer. Owns the single
-- | `Ref ReactFlowState`, the subscriber list, the middleware-key
-- | counter, and the `Effect_` interpreter that turns reducer-emitted
-- | descriptors into real side effects.
-- |
-- | Mirrors the runtime half of Zustand's `createStore` while keeping
-- | the public-facing contract (`getState`, `setState`, `subscribe`,
-- | `dispatch`) byte-compatible with upstream's `StoreApi`.
module React.Store.Shell
  ( Store
  , StoreApi
  , Subscribe(..)
  , createStore
  ) where

import Prelude

import Data.Array (filter) as Array
import Data.Foldable (for_, traverse_)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Aff.AVar as AffAVar
import Effect.Ref as Ref
import React.Store.Action (Action(..), Effect_(..))
import React.Store.InitialState (InitialStateOptions, initialState)
import React.Store.Reduce (reduce)
import React.Types.Store (MiddlewareKey(..), ReactFlowState)
import System.Constants (errorMessage)
import System.Utils.Store (panBy, updateNodeInternals)
import Web.HTML.HTMLDivElement (toHTMLElement)

-- | One subscriber. Each `subscribe` call captures its selector and
-- | `Eq` instance into a closure of type
-- | `ReactFlowState -> ReactFlowState -> Effect Unit`. The closure
-- | re-runs the selector on the prev/next state, compares, and fires
-- | the callback if the projection changed.
type Subscriber n e =
  { onUpdate :: ReactFlowState n e -> ReactFlowState n e -> Effect Unit
  , key :: Int
  }

-- | Rank-N polymorphic `subscribe` wrapped in a newtype so it can live
-- | inside the `Store` record (PS records don't permit polymorphic
-- | fields with class constraints).
newtype Subscribe n e = Subscribe
  ( forall a
     . Eq a
    => (ReactFlowState n e -> a)
    -> (a -> Effect Unit)
    -> Effect (Effect Unit)
  )

-- | The Zustand-compatible API surface. Consumers (hooks, the
-- | provider) see only this record — they never touch the internal
-- | Refs directly.
type Store n e =
  { getState :: Effect (ReactFlowState n e)
  , setState :: (ReactFlowState n e -> ReactFlowState n e) -> Effect Unit
  , subscribe :: Subscribe n e
  , dispatch :: Action n e -> Effect Unit
  , freshMiddlewareKey :: Effect MiddlewareKey
  }

type StoreApi n e = Store n e

createStore :: forall n e. InitialStateOptions n e -> Effect (Store n e)
createStore opts = do
  stateRef <- Ref.new (initialState opts)
  subsRef <- Ref.new ([] :: Array (Subscriber n e))
  nextSubKeyRef <- Ref.new 0
  middlewareKeyRef <- Ref.new 0

  let
    interpretEffect :: (Action n e -> Effect Unit) -> Effect_ n e -> Effect Unit
    interpretEffect dispatch_ eff = case eff of
      FireOnNodesChange cs -> do
        s <- Ref.read stateRef
        case s.onNodesChange of
          Just cb -> cb cs
          Nothing -> pure unit
      FireOnEdgesChange cs -> do
        s <- Ref.read stateRef
        case s.onEdgesChange of
          Just cb -> cb cs
          Nothing -> pure unit
      FireOnSelectionChange params -> do
        s <- Ref.read stateRef
        for_ s.onSelectionChangeHandlers \cb -> cb params
      FireOnConnect c -> do
        s <- Ref.read stateRef
        case s.onConnect of
          Just cb -> cb c
          Nothing -> pure unit
      -- onConnectStart/End fire with a DOM event; that event isn't
      -- available at the reducer level. The hook layer (ticket 031)
      -- raises these callbacks directly with the event in hand.
      FireOnConnectStart _ -> pure unit
      FireOnConnectEnd _ -> pure unit
      RunDomUpdateNodeInternals updates dopts -> do
        s <- Ref.read stateRef
        r <- updateNodeInternals updates s.nodeLookup s.parentLookup
          (map toHTMLElement s.domNode)
          s.nodeOrigin
          s.nodeExtent
          s.zIndexMode
        dispatch_
          ( MergeNodeInternalsResult
              { nodeLookup: r.nodeLookup
              , parentLookup: r.parentLookup
              , changes: r.changes
              , updatedInternals: r.updatedInternals
              , triggerFitView: dopts.triggerFitView
              }
          )
      RunPanBy delta -> do
        s <- Ref.read stateRef
        launchAff_ do
          _ <- panBy delta s.panZoom s.transform s.translateExtent s.width
            s.height
          pure unit
      RunSetCenter _ _ _ ->
        -- The hook in ticket 030 implements the returning Aff with its
        -- own AVar. This descriptor exists so middleware observers see
        -- the intent.
        pure unit
      ResolveFitView b -> do
        s <- Ref.read stateRef
        case s.fitViewResolver of
          Just avar -> launchAff_ (AffAVar.put b avar)
          Nothing -> pure unit
      LogError code -> do
        s <- Ref.read stateRef
        case s.onError of
          Just cb -> cb (errorCodeName code) (errorMessage code)
          Nothing -> pure unit

    notifySubscribers prev next = do
      subs <- Ref.read subsRef
      for_ subs \sub -> sub.onUpdate prev next

  let
    dispatch :: Action n e -> Effect Unit
    dispatch action = do
      prev <- Ref.read stateRef
      let res = reduce prev action
      Ref.write res.state stateRef
      notifySubscribers prev res.state
      traverse_ (interpretEffect dispatch) res.effects

    setState f = dispatch (PatchState f)
    getState = Ref.read stateRef

    subscribe = Subscribe \selector cb -> do
      key <- Ref.modify (_ + 1) nextSubKeyRef
      let
        onUpdate prev next =
          let
            prevV = selector prev
            nextV = selector next
          in
            if prevV == nextV then pure unit
            else cb nextV
      Ref.modify_ (\xs -> xs <> [ { onUpdate, key } ]) subsRef
      -- Zustand-compatible default: fire once with the current value.
      s <- Ref.read stateRef
      cb (selector s)
      pure (Ref.modify_ (Array.filter (\sub -> sub.key /= key)) subsRef)

    freshMiddlewareKey = do
      n <- Ref.modify (_ + 1) middlewareKeyRef
      pure (MiddlewareKey n)

  pure
    { getState
    , setState
    , subscribe
    , dispatch
    , freshMiddlewareKey
    }

-- | The first segment of `https://reactflow.dev/error#NNN` — the
-- | numeric tag. Used to satisfy the `OnError` signature
-- | `String -> String -> Effect Unit` (id, message).
errorCodeName :: forall a. a -> String
errorCodeName _ =
  -- Error tags carry richer payloads (some have String/HandleType
  -- arguments) so we don't pattern-match here; the message itself is
  -- the primary surface. The shell uses an empty id; the hook layer
  -- can override if a more granular tag is needed.
  ""
