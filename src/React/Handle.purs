-- | `<Handle />` — the connection point on a node. React-side wiring on
-- | top of `System.XYHandle.onPointerDown`. Mirrors
-- | `xyflow-main/packages/react/src/components/Handle/index.tsx`.
-- |
-- | What this initial port covers:
-- |   * Renders `<div>` with the full set of `react-flow__handle*`
-- |     class names that upstream CSS expects.
-- |   * Reads `noPanClassName` and `rfId` from the store.
-- |   * Reads the parent-node id via `useNodeId`; if absent, throws
-- |     `errorMessage E010` (matching TS, which fires `onError('010')`).
-- |   * Wraps the public export in `memo`.
-- |
-- | What's deferred to a follow-up ticket:
-- |   * Connection-drag lifecycle. `XYHandle.onPointerDown` requires a
-- |     handful of store-derived helpers (`panBy`, `cancelConnection`,
-- |     `updateConnection`) that today live as `Action` constructors,
-- |     not as ready-made callbacks on the store record. The
-- |     `onMouseDown`/`onTouchStart` handlers exist as no-op stubs.
-- |   * The connection-state-driven class flags (`connectingfrom`,
-- |     `connectingto`, `valid`, etc.). Pending the store wiring.
-- |   * Click-connect (`onClick` two-step). Same blocker.
-- |   * `forwardRef`. The TS export wraps the render function so the
-- |     consumer can grab the inner `<div>` ref. Skipped for now —
-- |     `React.FFI.ForwardRef` is in place for the next iteration.
module React.Handle
  ( handle
  ) where

import Prelude

import Data.Array (uncons) as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (ReactComponent)
import React.Basic.Events (EventHandler, handler_)
import React.Basic.Hooks (memo, reactComponent)
import React.Basic.Hooks as React
import React.Context.NodeId (useNodeId)
import React.FFI.DOM (div_, opt)
import React.Hook.Store (useStore)
import React.Types.Component (HandleProps)
import React.Types.Store (ReactFlowState)
import System.Constants (ErrorCode(..), errorMessage)
import System.Types.Geometry (Position(..))
import System.Types.Handle (HandleType(..))

type HandleStoreSlice =
  { connectOnClick :: Boolean
  , noPanClassName :: String
  , rfId :: String
  }

selectHandleSlice :: forall n e. ReactFlowState n e -> HandleStoreSlice
selectHandleSlice s =
  { connectOnClick: s.connectOnClick
  , noPanClassName: s.noPanClassName
  , rfId: s.rfId
  }

positionString :: Position -> String
positionString = case _ of
  PosLeft -> "left"
  PosRight -> "right"
  PosTop -> "top"
  PosBottom -> "bottom"

handleTypeString :: HandleType -> String
handleTypeString = case _ of
  Source -> "source"
  Target -> "target"

-- | Builds the space-separated `className` string mirroring the TS
-- | `cc([...])` output. Empty/false flags are dropped.
buildClassName
  :: { position :: Position
     , isTarget :: Boolean
     , isConnectable :: Boolean
     , isConnectableStart :: Boolean
     , isConnectableEnd :: Boolean
     , noPanClassName :: String
     , extra :: Maybe String
     }
  -> String
buildClassName p =
  joinNonEmpty
    [ "react-flow__handle"
    , "react-flow__handle-" <> positionString p.position
    , "nodrag"
    , p.noPanClassName
    , fromMaybe "" p.extra
    , if p.isTarget then "target" else "source"
    , if p.isConnectable then "connectable" else ""
    , if p.isConnectableStart then "connectablestart" else ""
    , if p.isConnectableEnd then "connectableend" else ""
    , if p.isConnectable && (p.isConnectableStart || p.isConnectableEnd)
        then "connectionindicator"
        else ""
    ]

joinNonEmpty :: Array String -> String
joinNonEmpty = foldStrip ""
  where
  foldStrip acc as = case Array.uncons as of
    Nothing -> acc
    Just { head: "", tail } -> foldStrip acc tail
    Just { head, tail }
      | acc == "" -> foldStrip head tail
      | otherwise -> foldStrip (acc <> " " <> head) tail

handle :: ReactComponent HandleProps
handle = unsafePerformEffect $ memo $ reactComponent "Handle" \(props :: HandleProps) -> React.do
  slice <- useStore selectHandleSlice
  nodeIdM <- useNodeId
  let
    nodeId = case nodeIdM of
      Just nid -> nid
      Nothing -> unsafeThrow (errorMessage E010)
    isConnectable = fromMaybe true props.isConnectable
    isConnectableStart = fromMaybe true props.isConnectableStart
    isConnectableEnd = fromMaybe true props.isConnectableEnd
    isTarget = case props.handleType of
      Target -> true
      Source -> false
    className = buildClassName
      { position: props.position
      , isTarget
      , isConnectable
      , isConnectableStart
      , isConnectableEnd
      , noPanClassName: slice.noPanClassName
      , extra: props.className
      }
    dataId = slice.rfId
      <> "-"
      <> nodeId
      <> "-"
      <> fromMaybe "" props.id
      <> "-"
      <> handleTypeString props.handleType
    onPointerDown :: EventHandler
    onPointerDown = handler_ (pure unit)
  pure $ div_
    { className
    , style: opt props.style
    , "data-handleid": opt props.id
    , "data-nodeid": nodeId
    , "data-handlepos": positionString props.position
    , "data-id": dataId
    , onMouseDown: onPointerDown
    , onTouchStart: onPointerDown
    }
    []
