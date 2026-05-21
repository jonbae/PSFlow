-- | `<ConnectionLine />` — the SVG overlay that draws the in-progress
-- | connection while a user is wiring an edge. Mirrors
-- | `xyflow-main/packages/react/src/components/ConnectionLine/index.tsx`.
-- |
-- | Responsibilities:
-- |
-- |   1. Project the gating primitives (`width`, `height`,
-- |      `nodesConnectable`, in-progress flag, validity) plus an
-- |      `UnsafeReference` to the live `ConnectionInProgressData` from
-- |      the store via `useStore`. The reference wrapper preserves
-- |      drag-tick re-renders (the reducer hands out a fresh data
-- |      object each tick) without leaking an `Eq n` constraint into
-- |      the component signature.
-- |   2. Return `mempty` while no connection is in progress, the
-- |      viewport has zero width, or `nodesConnectable` is `false`.
-- |   3. Otherwise render `<svg><g>...</g></svg>` containing either the
-- |      user-supplied `connectionLineComponent` (if `Just`) or the
-- |      built-in path renderer for the active `ConnectionLineType`.
-- |
-- | **Fidelity notes.**
-- |   * `memo` is applied to the public export. As in the rest of the
-- |     port, default `Object.is` equality won't actually skip renders
-- |     for record props; matches the existing wrapper components.
-- |   * Path-function defaults (`curvature = 0.25`, `borderRadius = 5`,
-- |     `offset = 20`, `stepPosition = 0.5`) are passed explicitly here
-- |     because the PS `*PathParams` records don't carry destructuring
-- |     defaults; the values mirror the TS source defaults exactly.
module React.Component.ConnectionLine
  ( connectionLine
  ) where

import Prelude

import Data.Array (filter) as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Number.Format (toString) as NumberFormat
import Data.String.Common (joinWith) as String
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (JSX, ReactComponent)
import React.Basic.Hooks (UnsafeReference(..), memo, reactComponent)
import React.Basic.Hooks as React
import React.FFI.DOM (g_, path_)
import React.Hook.Store (useStore)
import React.Types.Component (ConnectionLineProps)
import React.Types.Edges (ConnectionStatus(..), Style)
import React.Types.Store (ReactFlowState)
import System.Types.Connection (ConnectionInProgressData, ConnectionState(..))
import System.Types.Edge (ConnectionLineType(..))
import System.Types.Geometry (Position)
import System.Types.Node (InternalNodeBase)
import System.Utils.Edges.Bezier (getBezierPath)
import System.Utils.Edges.SimpleBezier (getSimpleBezierPath)
import System.Utils.Edges.SmoothStep (getSmoothStepPath)
import System.Utils.Edges.Straight (getStraightPath)
import Unsafe.Coerce (unsafeCoerce)

-- | Locally-defined `<svg>` FFI; mirrors `EdgeWrapper.js`. Avoids
-- | touching `React.FFI.DOM`'s public surface for a tagged-but-untyped
-- | element wrapper.
foreign import svg_ :: forall p. Record p -> Array JSX -> JSX

-- | Style record coercion (matches `NodeWrapper.toForeignStyle`).
toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

emptyForeign :: Foreign
emptyForeign = toForeignStyle {}

styleOrEmpty :: Maybe Style -> Foreign
styleOrEmpty = case _ of
  Nothing -> emptyForeign
  Just s -> (unsafeCoerce s :: Foreign)

showN :: Number -> String
showN = NumberFormat.toString

joinSpace :: Array String -> String
joinSpace = String.joinWith " " <<< Array.filter (_ /= "")

-- ----------------------------------------------------------------------------
-- Slice
-- ----------------------------------------------------------------------------

type ConnectionLineSlice n =
  { nodesConnectable :: Boolean
  , width :: Number
  , height :: Number
  , inProgress :: Boolean
  , isValid :: Maybe Boolean
  , dataRef ::
      UnsafeReference
        (Maybe (ConnectionInProgressData (InternalNodeBase n)))
  }

selectSlice :: forall n e. ReactFlowState n e -> ConnectionLineSlice n
selectSlice s = case s.connection of
  NoConnection ->
    { nodesConnectable: s.nodesConnectable
    , width: s.width
    , height: s.height
    , inProgress: false
    , isValid: Nothing
    , dataRef: UnsafeReference Nothing
    }
  ConnectionInProgress d ->
    { nodesConnectable: s.nodesConnectable
    , width: s.width
    , height: s.height
    , inProgress: true
    , isValid: d.isValid
    , dataRef: UnsafeReference (Just d)
    }

-- ----------------------------------------------------------------------------
-- Class-name & path helpers
-- ----------------------------------------------------------------------------

-- | TS `getConnectionStatus(isValid)` returns the connection's validity tag
-- | as a string-renderable enum. The PS port has two parallel types named
-- | `ConnectionStatus`; the one carried by `ConnectionLineComponentProps` is
-- | `React.Types.Edges.ConnectionStatus` (`ConnectionValid`/`ConnectionInvalid`).
-- | Re-derive it here to avoid a needless conversion through the
-- | `System.Utils.Connections` variant.
connectionStatusOf :: Maybe Boolean -> Maybe ConnectionStatus
connectionStatusOf = case _ of
  Nothing -> Nothing
  Just true -> Just ConnectionValid
  Just false -> Just ConnectionInvalid

statusClassName :: Maybe ConnectionStatus -> String
statusClassName = case _ of
  Just ConnectionValid -> "valid"
  Just ConnectionInvalid -> "invalid"
  Nothing -> ""

type PathInput =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: Position
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: Position
  }

mkPath :: ConnectionLineType -> PathInput -> String
mkPath lineType p = case lineType of
  BezierLine ->
    _.path $ getBezierPath
      { sourceX: p.sourceX
      , sourceY: p.sourceY
      , sourcePosition: p.sourcePosition
      , targetX: p.targetX
      , targetY: p.targetY
      , targetPosition: p.targetPosition
      , curvature: 0.25
      }
  SimpleBezierLine ->
    _.path $ getSimpleBezierPath
      { sourceX: p.sourceX
      , sourceY: p.sourceY
      , sourcePosition: p.sourcePosition
      , targetX: p.targetX
      , targetY: p.targetY
      , targetPosition: p.targetPosition
      }
  StepLine ->
    _.path $ getSmoothStepPath
      { sourceX: p.sourceX
      , sourceY: p.sourceY
      , sourcePosition: p.sourcePosition
      , targetX: p.targetX
      , targetY: p.targetY
      , targetPosition: p.targetPosition
      , borderRadius: 0.0
      , centerX: Nothing
      , centerY: Nothing
      , offset: 20.0
      , stepPosition: 0.5
      }
  SmoothStepLine ->
    _.path $ getSmoothStepPath
      { sourceX: p.sourceX
      , sourceY: p.sourceY
      , sourcePosition: p.sourcePosition
      , targetX: p.targetX
      , targetY: p.targetY
      , targetPosition: p.targetPosition
      , borderRadius: 5.0
      , centerX: Nothing
      , centerY: Nothing
      , offset: 20.0
      , stepPosition: 0.5
      }
  StraightLine ->
    _.path $ getStraightPath
      { sourceX: p.sourceX
      , sourceY: p.sourceY
      , targetX: p.targetX
      , targetY: p.targetY
      }

-- ----------------------------------------------------------------------------
-- The component
-- ----------------------------------------------------------------------------

connectionLine :: forall n. ReactComponent (ConnectionLineProps n)
connectionLine =
  unsafePerformEffect $ memo $ reactComponent "ConnectionLine"
    \(props :: ConnectionLineProps n) -> React.do
      slice <- useStore selectSlice
      let
        lineType = fromMaybe BezierLine props.connectionLineType
        gate =
          slice.width > 0.0
            && slice.nodesConnectable
            && slice.inProgress
        UnsafeReference mData = slice.dataRef
      pure $
        if not gate then mempty
        else case mData of
          Nothing -> mempty
          Just d ->
            let
              status = connectionStatusOf slice.isValid
              gClass = joinSpace
                [ "react-flow__connection"
                , statusClassName status
                ]
              innerBody :: JSX
              innerBody = case props.connectionLineComponent of
                Just userComp ->
                  userComp
                    { connectionLineStyle: props.connectionLineStyle
                    , connectionLineType: lineType
                    , fromNode: d.fromNode
                    , fromHandle: d.fromHandle
                    , fromX: d.from.x
                    , fromY: d.from.y
                    , toX: d.to.x
                    , toY: d.to.y
                    , fromPosition: d.fromPosition
                    , toPosition: d.toPosition
                    , connectionStatus: status
                    , toNode: d.toNode
                    , toHandle: d.toHandle
                    , pointer: d.pointer
                    }
                Nothing ->
                  let
                    pathStr = mkPath lineType
                      { sourceX: d.from.x
                      , sourceY: d.from.y
                      , sourcePosition: d.fromPosition
                      , targetX: d.to.x
                      , targetY: d.to.y
                      , targetPosition: d.toPosition
                      }
                  in
                    path_
                      { d: pathStr
                      , fill: "none"
                      , className: "react-flow__connection-path"
                      , style: styleOrEmpty props.connectionLineStyle
                      }
                      []
            in
              svg_
                { style: styleOrEmpty props.connectionLineContainerStyle
                , width: showN slice.width
                , height: showN slice.height
                , className: "react-flow__connectionline react-flow__container"
                }
                [ g_ { className: gClass } [ innerBody ] ]
