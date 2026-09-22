-- | Helpers extracted from `React.Container.Pane`, separated so tests can
-- | import them without triggering the `React.Basic.Hooks` runtime chain
-- | (which transitively requires the npm `react` package).
-- |
-- | `autoPanLoop` is here for the other half of that reason: in TS it is a
-- | closure over the component's refs, so nothing outside a mounted `<Pane />`
-- | can run one frame of it. Taking its reads and writes as an argument record
-- | makes a frame something `spago test` can drive.
module React.Container.Pane.Internal
  ( paneIsDraggable
  , buildPaneClass
  , AutoPanEnv
  , autoPanLoop
  ) where

import Prelude

import Data.Array (filter) as Array
import Data.Array.NonEmpty (elem) as NEA
import Data.Maybe (Maybe(..))
import Data.String (joinWith) as String
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import System.FFI.Microtask (awaitMicrotask)
import System.Types.Geometry (XYPosition)
import System.Types.PanZoom (PanOnDrag(..))
import System.Utils.Dom (DOMRect)
import System.Utils.General (calcAutoPan)

buildPaneClass :: { draggable :: Boolean, dragging :: Boolean, isSelecting :: Boolean } -> String
buildPaneClass p =
  String.joinWith " " $ Array.filter (_ /= "")
    [ "react-flow__pane"
    , if p.draggable then "draggable" else ""
    , if p.dragging then "dragging" else ""
    , if p.isSelecting then "selection" else ""
    ]

paneIsDraggable :: PanOnDrag -> Boolean
paneIsDraggable = case _ of
  NoPan -> false
  PanAlways -> true
  PanOnButtons buttons -> NEA.elem 0 buttons

-- | Everything one lasso auto-pan frame reads or writes. In TS these are the
-- | component's own refs and props, closed over by `autoPan`; here they are an
-- | argument so a frame can be run outside a mounted `<Pane />`.
-- |
-- |   * `autoPanOnSelection` and `autoPanSpeed` are the props as of the render
-- |     that started the loop, which is what TS's closure captures too.
-- |   * `containerBounds`, `position` and `selectionInProgress` are read fresh
-- |     every frame — `position` twice, once to size the pan and again once it
-- |     has landed, as TS reads `position.current` on both sides of its
-- |     `await`.
-- |   * `scheduleFrame` asks for the next frame and stores its handle, which
-- |     is what `cleanupAutoPan` cancels when the gesture ends. It takes the
-- |     frame rather than returning the handle so that `RafHandle` — opaque,
-- |     and only obtainable from a real `window` — stays out of the record,
-- |     and a test can run the frame it was handed instead of installing a
-- |     frame clock over the global.
type AutoPanEnv =
  { autoPanOnSelection :: Boolean
  , autoPanSpeed :: Number
  , containerBounds :: Effect (Maybe DOMRect)
  , position :: Effect XYPosition
  , selectionInProgress :: Effect Boolean
  , panBy :: XYPosition -> Aff Boolean
  , commitUserSelectionRect :: Number -> Number -> Effect Unit
  , scheduleFrame :: Effect Unit -> Effect Unit
  }

-- | One lasso auto-pan frame, as `requestAnimationFrame` runs it. TS `autoPan`
-- | (`xyflow/packages/react/src/container/Pane/index.tsx`, `autoPan`).
-- |
-- | The frame pans, waits for the pan to land, and commits the selection rect
-- | only if the viewport actually moved *and* the gesture is still in
-- | progress; either way it then asks for the next frame. A pan the viewport
-- | refused — at a `translateExtent` boundary, or because the pointer is
-- | nowhere near an edge and the delta is zero — grows the rect by nothing,
-- | which is the difference between a lasso that stops where the viewport
-- | stops and one that keeps selecting nodes the pointer never reached.
-- |
-- | The next-frame request sits *inside* the continuation, so one pan is in
-- | flight at most. `System.XYDrag` learned what the two alternatives cost: a
-- | request beside the pan lets frames overtake each other, and one hoisted
-- | into a `where` clause builds the loop eagerly and overflows the stack.
-- | Self-reference is safe here because `autoPanLoop` is a top-level binding
-- | applied to an argument, not a recursive `let` value.
-- |
-- | `awaitMicrotask` is the `.then`. ps-flow's `panBy` completes synchronously,
-- | and an `Aff` bound after a synchronous one continues on the same stack —
-- | which for the first frame is inside the `onPointerMove` that started the
-- | loop, so the frame would commit its rect *before* the handler commits
-- | its own. A JavaScript `.then` callback never runs before its caller
-- | returns, and neither does this.
-- |
-- | **Fidelity note.** A gesture that ends between the pan and its
-- | continuation leaves no frame for `cleanupAutoPan` to cancel, and the
-- | continuation then asks for one the ended gesture no longer owns. TS has
-- | the same window and the same outcome — `autoPanId.current` is reassigned
-- | in both branches of the `.then`, after `cleanupAutoPan` has zeroed it — so
-- | the port keeps it rather than guarding a case upstream does not.
autoPanLoop :: AutoPanEnv -> Effect Unit
autoPanLoop env =
  when env.autoPanOnSelection do
    mBounds <- env.containerBounds
    case mBounds of
      Nothing -> pure unit
      Just bounds -> do
        pos <- env.position
        let
          delta = calcAutoPan pos
            { width: bounds.width, height: bounds.height }
            env.autoPanSpeed
            40.0
        launchAff_ do
          panned <- env.panBy delta
          awaitMicrotask
          liftEffect do
            inProgress <- env.selectionInProgress
            when (inProgress && panned) do
              landedAt <- env.position
              env.commitUserSelectionRect landedAt.x landedAt.y
            env.scheduleFrame (autoPanLoop env)
