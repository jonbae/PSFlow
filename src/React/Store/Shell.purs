-- | `Effect`-typed shell around the pure reducer. Owns the single
-- | `Ref ReactFlowState`, the subscriber list, the transition observers,
-- | and the `Effect_` interpreter that turns reducer-emitted descriptors
-- | into real side effects.
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

import Control.Monad.Rec.Class (Step(..), tailRecM)
import Data.Array (any, filter, length, null, partition, unsafeIndex) as Array
import Data.Foldable (for_, traverse_)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect (Effect)
import Partial.Unsafe (unsafePartial)
import Effect.Aff (launchAff_)
import Effect.Ref as Ref
import Effect.Class (liftEffect)
import React.Store.Action (Action(..), Effect_(..))
import React.Store.InitialState (InitialStateOptions, initialState)
import React.Store.Reduce (reduce)
import React.Store.FitViewResolver (resolveFitView)
import React.Store.Middleware (runNodesChangeMiddleware)
import React.Store.Partial (partial)
import React.Types.Store (ReactFlowState)
import System.Constants (errorMessage)
import System.Utils.Graph (fitViewport)
import System.Utils.Store (updateNodeInternals)
import Unsafe.Coerce (unsafeCoerce)
import Unsafe.Reference (unsafeRefEq)
import Web.HTML.HTMLDivElement (toHTMLElement)

-- | One subscriber. Each `subscribe` call captures its selector and
-- | `Eq` instance into a closure of type
-- | `ReactFlowState -> ReactFlowState -> Effect Unit`. The closure
-- | re-runs the selector on the prev/next state, compares, and fires
-- | the callback if the projection changed.
-- |
-- | The list is zustand's `Set` of listeners. `identity` is what the `Set`
-- | holds, the listener a caller handed over, so one listener is held
-- | once. `key` is its place in insertion order: keys only grow, and a
-- | listener that is removed and added again gets a new one, at the end.
type Subscriber n e =
  { onUpdate :: ReactFlowState n e -> ReactFlowState n e -> Effect Unit
  , identity :: Identity
  , key :: Int
  }

-- | A listener's reference, compared with `unsafeRefEq`.
foreign import data Identity :: Type

identityOf :: forall a. a -> Identity
identityOf = unsafeCoerce

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
  -- | Zustand's `getInitialState`: the state the store was created with. Its
  -- | `useStore` reads this one during a server render, where React asks for
  -- | the server snapshot.
  , getInitialState :: Effect (ReactFlowState n e)
  , setState :: (ReactFlowState n e -> ReactFlowState n e) -> Effect Unit
  , subscribe :: Subscribe n e
  -- | Zustand's own `subscribe(listener)`: the listener runs after every
  -- | dispatch that replaced the state, with no selector between them.
  -- | `React.Hook.Store.useStore` hands it to React's
  -- | `useSyncExternalStore`, which reads the slice itself. A selector here
  -- | would be the one captured when the subscription was made, and a
  -- | consumer's selector can change from render to render.
  , subscribeAll :: Effect Unit -> Effect (Effect Unit)
  -- | Zustand's `subscribe(listener)` as a JavaScript consumer reaches it
  -- | through `useStoreApi`: the listener is handed the state and the one
  -- | before it. Zustand passes its `state` variable as it is when each
  -- | listener runs, and the `previousState` of the `set` that notified, so
  -- | a listener that dispatches lets the next one see the newer state beside
  -- | the older previous one. This hands over the same two.
  -- |
  -- | All three kinds share one list, zustand's `Set`: a listener already
  -- | in it is not added again, and undoing any of its subscriptions
  -- | removes it. A listener is compared by reference, so
  -- | `Boundary.Store` hands over one function per JavaScript listener.
  , subscribeStates :: (ReactFlowState n e -> ReactFlowState n e -> Effect Unit) -> Effect (Effect Unit)
  , dispatch :: Action n e -> Effect Unit
  -- | Called with each state the store moves to, the one before it, and the
  -- | members upstream's `set` names for the update, as soon as the new
  -- | state is written and before any subscriber hears of it.
  -- | `Boundary.Store` keeps the JavaScript shape of each state with it.
  , observeTransitions :: (ReactFlowState n e -> ReactFlowState n e -> Array String -> Effect Unit) -> Effect Unit
  -- | Called before the store reads its state, for itself or for a caller
  -- | of `getState`. After `setState(next, true)`, upstream's state is the
  -- | consumer's object, which the consumer can write into at any time, and
  -- | upstream's internals read it as it then is. `Boundary.Store` brings the
  -- | state up to date with that object here, handed the state as it is.
  , beforeRead :: (ReactFlowState n e -> Effect Unit) -> Effect Unit
  }

type StoreApi n e = Store n e

createStore :: forall n e. InitialStateOptions n e -> Effect (Store n e)
createStore opts = do
  let firstState = initialState opts
  stateRef <- Ref.new firstState
  subsRef <- Ref.new ([] :: Array (Subscriber n e))
  nextSubKeyRef <- Ref.new 0
  observersRef <- Ref.new ([] :: Array (ReactFlowState n e -> ReactFlowState n e -> Array String -> Effect Unit))
  readHooksRef <- Ref.new ([] :: Array (ReactFlowState n e -> Effect Unit))

  let
    readState :: Effect (ReactFlowState n e)
    readState = do
      hooks <- Ref.read readHooksRef
      unless (Array.null hooks) do
        current <- Ref.read stateRef
        for_ hooks (_ $ current)
      Ref.read stateRef

    interpretEffect :: (Action n e -> Effect Unit) -> Effect_ n e -> Effect Unit
    interpretEffect dispatch_ eff = case eff of
      FireOnNodesChange cs -> do
        s <- readState
        case s.onNodesChange of
          Just cb -> cb cs
          Nothing -> pure unit
      FireOnEdgesChange cs -> do
        s <- readState
        case s.onEdgesChange of
          Just cb -> cb cs
          Nothing -> pure unit
      FireOnSelectionChange params -> do
        s <- readState
        for_ s.onSelectionChangeHandlers \cb -> cb params
      FireOnConnect c -> do
        s <- readState
        case s.onConnect of
          Just cb -> cb c
          Nothing -> pure unit
      -- onConnectStart/End fire with a DOM event; that event isn't
      -- available at the reducer level. The hook layer (ticket 031)
      -- raises these callbacks directly with the event in hand.
      FireOnConnectStart _ -> pure unit
      FireOnConnectEnd _ -> pure unit
      RunDomUpdateNodeInternals updates dopts -> do
        s <- readState
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
      RunTriggerNodeChanges changes -> dispatch_ (TriggerNodeChanges changes)
      RunNodesChangeMiddleware changes -> do
        s <- readState
        filtered <- runNodesChangeMiddleware s.onNodesChangeMiddlewareMap changes
        dispatch_ (TriggerNodeChanges filtered)
      RunSetCenter x y center -> do
        -- The store's setCenter is also used by NodeWrapper's focus path.
        -- Reading and invoking panZoom happens before its async continuation,
        -- just as in the upstream store action.
        s <- readState
        for_ s.panZoom \pz -> do
          let zoom = fromMaybe s.maxZoom center.zoom
          launchAff_ $ void $ pz.setViewport
            { x: s.width / 2.0 - x * zoom
            , y: s.height / 2.0 - y * zoom
            , zoom
            }
            (Just { duration: center.duration, ease: center.ease, interpolate: center.interpolate })
      -- No instance yet means the flow has not mounted its pane, and
      -- `createXYPanZoom` seeds the extent from the same state when it
      -- does. That is upstream's `panZoom?.` optional call.
      RunSetScaleExtent panZoom mn mx ->
        for_ panZoom \pz -> pz.setScaleExtent mn mx
      RunSetTranslateExtent panZoom ext ->
        for_ panZoom \pz -> pz.setTranslateExtent ext
      ResolveFitView fit -> do
        -- Mirror the React store's `resolveFitView`: apply the fitted
        -- viewport via `panZoom.setViewport` (which fires d3's zoom event,
        -- so `ZoomPane.onTransformChange` writes the new `state.transform`),
        -- then call the resolver's `resolve(true)` and clear it, as
        -- upstream's `set({ fitViewResolver: null })` does once the fit has
        -- settled.
        -- Without a pan-zoom instance upstream returns at once: the
        -- resolver stays in the store, unresolved, for the next fit.
        case fit.panZoom of
          Nothing -> pure unit
          Just pz -> launchAff_ do
            _ <- fitViewport
              { nodes: fit.nodes
              , width: fit.width
              , height: fit.height
              , panZoom: pz
              , minZoom: fit.minZoom
              , maxZoom: fit.maxZoom
              }
              fit.options
            for_ fit.resolver \resolver -> liftEffect (resolveFitView resolver true)
            liftEffect $ dispatch_ (Assign (partial { fitViewResolver: Nothing }))
      LogError code -> do
        s <- readState
        case s.onError of
          Just cb -> cb (errorCodeName code) (errorMessage code)
          Nothing -> pure unit

    -- zustand's `listeners.forEach(…)` over a `Set`, which visits each
    -- entry present when the walk reaches it: a listener removed before its
    -- turn is skipped, and one added during the walk is reached in it. The
    -- walk reads the list afresh at each step and goes on from the last key
    -- it visited.
    notifySubscribers prev next = flip tailRecM (-1) \after -> do
      subs <- Ref.read subsRef
      case firstAfter after subs of
        Nothing -> pure (Done unit)
        Just sub -> do
          sub.onUpdate prev next
          pure (Loop sub.key)

    -- `listeners.add(listener)`: a listener the `Set` holds already stays
    -- where it is. `listeners.delete(listener)` removes it whichever
    -- subscription is undone.
    addSubscriber identity onUpdate = do
      subs <- Ref.read subsRef
      unless (Array.any (\sub -> unsafeRefEq sub.identity identity) subs) do
        key <- Ref.modify (_ + 1) nextSubKeyRef
        Ref.write (subs <> [ { onUpdate, identity, key } ]) subsRef
      pure (Ref.modify_ (Array.filter (\sub -> not (unsafeRefEq sub.identity identity))) subsRef)

  let
    dispatch :: Action n e -> Effect Unit
    dispatch action = do
      prev <- readState
      let res = reduce prev action
      Ref.write res.state stateRef
      unless (unsafeRefEq prev res.state) do
        observers <- Ref.read observersRef
        for_ observers \observe -> observe prev res.state res.writes
      -- Upstream calls `resolveFitView()` before the `set` that clears the
      -- queue, so the viewport is set before any subscriber hears of it.
      let effects = Array.partition runsBeforeSet res.effects
      traverse_ (interpretEffect dispatch) effects.yes
      notifySubscribers prev res.state
      traverse_ (interpretEffect dispatch) effects.no

    setState f = dispatch (PatchState f)
    getState = readState

    subscribe = Subscribe \selector cb -> do
      let
        onUpdate prev next =
          let
            prevV = selector prev
            nextV = selector next
          in
            if prevV == nextV then pure unit
            else cb nextV
      unsubscribe <- addSubscriber (identityOf onUpdate) onUpdate
      -- No fire on subscribe. Zustand's `subscribe` does not call back with
      -- the current value; only `subscribeWithSelector` under an explicit
      -- `fireImmediately` does, and upstream never asks for it. The one
      -- caller, `React.Hook.Store.useStore`, seeds its own `useState` from
      -- `store.getState` before this runs, so firing here was a second
      -- `setValue` with a value the consumer already held.
      --
      -- It was also nondeterministic. Every consumer's subscription lands in
      -- its own `useEffect`, so the extra `setValue`s arrived in mount order
      -- and React batched them differently run to run — which is what put 52
      -- of 94 scenarios into `callbacks | ordered differently` against their
      -- own second capture. See "Diagnose why ps-flow does not reproduce
      -- itself on 52 of 94 scenarios" (#94).
      pure unsubscribe

    -- Zustand notifies when `!Object.is(nextState, state)`, and so does
    -- this: a dispatch whose reducer handed the same state back is not a
    -- change. Listeners share the selector subscribers' list, so the two
    -- kinds run in the order they subscribed, as zustand's one `Set` does.
    subscribeAll listener =
      addSubscriber (identityOf listener) \prev next -> unless (unsafeRefEq prev next) listener

    subscribeStates listener =
      addSubscriber (identityOf listener) \prev next -> unless (unsafeRefEq prev next) do
        current <- Ref.read stateRef
        listener current prev

    observeTransitions observer = Ref.modify_ (_ <> [ observer ]) observersRef

    beforeRead hook = Ref.modify_ (_ <> [ hook ]) readHooksRef

    runsBeforeSet = case _ of
      ResolveFitView _ -> true
      _ -> false

  pure
    { getState
    , getInitialState: pure firstState
    , setState
    , subscribe
    , subscribeAll
    , subscribeStates
    , dispatch
    , observeTransitions
    , beforeRead
    }

-- | The first subscriber whose key is greater than `after`. Keys grow along
-- | the list, so this is a binary search.
firstAfter :: forall n e. Int -> Array (Subscriber n e) -> Maybe (Subscriber n e)
firstAfter after subs = go 0 (Array.length subs)
  where
  at i = unsafePartial (Array.unsafeIndex subs i)
  go low high
    | low >= high = if low < Array.length subs then Just (at low) else Nothing
    | otherwise =
        let
          mid = (low + high) / 2
        in
          if (at mid).key > after then go low mid else go (mid + 1) high

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
