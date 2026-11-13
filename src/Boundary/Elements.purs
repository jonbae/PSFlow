-- | The graph data types, crossing.
-- |
-- | `Node`, `Edge`, the node props a custom component receives, the change
-- | objects `onNodesChange`/`onEdgesChange` deliver, and `Connection`. These
-- | are the shapes a JavaScript consumer both hands in and gets back, so most
-- | of them convert **both directions** — and the two directions are not
-- | symmetric in what they can get wrong.
-- |
-- | Boundary stage 2 added the shapes a **handler** carries: the internal node
-- | and measured handle a connection state names, the viewport, and the
-- | `{ nodes, edges }` bag three callbacks share. They live here rather than in
-- | `Boundary.Callbacks` because each is a record with two directions or two
-- | callers, which is what this module is for; the handler *types* and their
-- | converters are that module's.
-- |
-- | **Inbound is compiler-checked.** Building a PureScript record forces a
-- | value for every field, so a field added to `NodeBaseRow` breaks this
-- | module until someone reads it off the JavaScript object.
-- |
-- | **Outbound is not.** Nothing makes the JS-shaped record name every field
-- | the PureScript record has; a field added to `NodeBaseRow` and forgotten
-- | here is silently dropped on the way out, and the repo's generators vary 5
-- | of the node record's 28 fields, so a round-trip property would pass over
-- | it. That asymmetry is why `parity/boundary/drift.mjs` exists: it compares
-- | the two type declarations' label sets directly and fails on the field that
-- | appears in one and not the other.
-- |
-- | ## Fields PureScript makes required and upstream leaves optional
-- |
-- | A node's `measured` record. The seven Booleans that were required are
-- | `Maybe Boolean`s that cross only when they're set: an edge's `animated`,
-- | `hidden`, and `selected`, and a node's `hidden`, `selected`, `dragging`,
-- | and `expandParent`. Every reader treats an unset one as `false`, as
-- | upstream's does. `measured` defaults inbound to an empty measurement, and
-- | `nodeOut` omits it while it's empty, because upstream's node has no
-- | `measured` until it's measured.
-- |
-- | Absent optional fields are emitted as the key with the value `undefined`
-- | rather than omitted. Omitting them would read closer to upstream for
-- | nodes, whose objects upstream passes through from the consumer untouched
-- | — but deleting keys by content is exactly the content-aware filtering the
-- | spec keeps out of capture, and it belongs in the net's normalization where
-- | it is visible, not buried in a converter.
module Boundary.Elements
  ( JsCoordinateExtent
  , JsDefaultEdgeOptions
  , JsEdge
  , JsEdgeMarker
  , JsEdgePathOptions
  , JsGraphSelection
  , JsHandle
  , JsInternalNode
  , JsMeasured
  , JsNode
  , JsNodeBounds
  , JsNodeHandle
  , JsNodeHandleBounds
  , JsNodeInternals
  , JsNodeOrigin
  , JsNodeProps
  , JsNodeRow
  , JsNodeChange
  , JsEdgeChange
  , JsConnection
  , JsViewport
  , JsXYPosition
  , asCssObject
  , asCssStyle
  , fromCssStyle
  , fromCssObject
  , coordinateExtentIn
  , coordinateExtentOut
  , defaultEdgeOptionsIn
  , defaultEdgeOptionsOut
  , connectionIn
  , connectionOut
  , connectionParamsOut
  , edgeIn
  , edgeIdentityOut
  , edgeOut
  , edgePathOptionsOut
  , edgeReconnectableIn
  , edgeReconnectableOut
  , edgeAriaLabelIn
  , edgeAriaLabelOut
  , edgeChangeIn
  , edgeChangeOut
  , graphSelectionOut
  , handleIn
  , handleOut
  , internalNodeIn
  , internalNodeOut
  , keyCodeIn
  , keyCodeValueIn
  , labelBgPaddingIn
  , labelBgPaddingOut
  , nodeExtentIn
  , nodeIdentityOut
  , nodeIn
  , nodeOut
  , nodeChangeIn
  , nodeChangeOut
  , nodeOriginIn
  , nodeOriginOut
  , nodePropsOut
  , nodeTypesIn
  , snapGridIn
  , viewportIn
  , viewportOut
  ) where

import Prelude

import Boundary.Enums
  ( handleTypeIn
  , handleTypeOut
  , markerTypeIn
  , markerTypeOut
  , positionIn
  , positionOut
  )
import Boundary.Original (originalOf, remembering)
import Boundary.Undefined (Undefinable, defined, fromUndefinable, isNull, nullUndefinable, pruneUndefined, toUndefinable, undefined)
import Boundary.Untagged (asArray, asBoolean, asString, typeName)
import Boundary.Wrapper (mkComponentWrapper)
import Data.Array (length) as Array
import Data.Array.NonEmpty (fromArray) as NEA
import Data.Int (round, toNumber) as Int
import Data.Maybe (Maybe(..), fromMaybe', maybe)
import Data.Newtype (unwrap, wrap)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Data.Function.Uncurried (Fn2, runFn2)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (mkEffectFn1)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Object (Object)
import Foreign.Object (mapWithKey) as Object
import Record (insert) as Record
import Record.Unsafe (unsafeSet)
import Type.Proxy (Proxy(..))
import React.Basic (ReactComponent, element)
import React.Types.Edges (DefaultEdgeOptions, Style)
import React.Types.Nodes (NodeProps, NodeTypesMap)
import System.Types.Connection (Connection, KeyCode(..), Viewport, edgeDefaultsOf)
import System.Types.Edge
  ( EdgeAriaLabel(..)
  , EdgeBase
  , EdgeChange(..)
  , EdgeMarker
  , EdgeMarkerType(..)
  , EdgePathOptions
  , EdgeReconnectable(..)
  , originalUserEdge
  , rememberDefaultEdgeOptions
  , rememberUserEdge
  )
import System.Types.Geometry (CoordinateExtent, NodeOrigin, SnapGrid)
import System.Types.Handle (Handle, HandleIdField(..), SourceHandle(..), TargetHandle(..), unSourceHandle, unTargetHandle)
import System.Types.Node
  ( InternalNodeBase
  , NodeBase
  , NodeBounds
  , NodeChange(..)
  , NodeExtent(..)
  , NodeHandle
  , NodeHandleBounds
  , NodeInternals
  , originalUserNode
  , rememberUserNode
  )
import System.Types.Opaque (opaque, unOpaque)
import Unsafe.Coerce (unsafeCoerce)

-- ────────────────────────────────────────────────────────────────────────
-- The JS-shaped records
--
-- Every optional field is `Undefinable`, which is how the value actually
-- arrives: a JavaScript object literal simply has no such key, and reading it
-- gives `undefined`. The record type is therefore a claim about what the
-- fields mean *if present*, not that they are.
-- ────────────────────────────────────────────────────────────────────────

type JsXYPosition = { x :: Number, y :: Number }

-- | Upstream `NodeOrigin` is `[number, number]`; the PureScript newtype names
-- | the components `ox`/`oy`.
type JsNodeOrigin = Array Number

-- | Upstream `CoordinateExtent` is `[[minX, minY], [maxX, maxY]]`.
type JsCoordinateExtent = Array (Array Number)

type JsMeasured =
  { width :: Undefinable Number
  , height :: Undefinable Number
  }

-- | Upstream `NodeHandle` — a `Handle` without `nodeId` and with the
-- | dimensions optional. Its type tag is `type`; PureScript calls it
-- | `handleType` to leave `type` for the node's own tag.
type JsNodeHandle =
  { id :: Undefinable String
  , x :: Number
  , y :: Number
  , position :: String
  , type :: String
  , width :: Undefinable Number
  , height :: Undefinable Number
  }

-- | The 32 fields of `System.Types.Node.NodeBaseRow`, in upstream's shapes.
-- |
-- | `extent` is `Foreign` because upstream's is `'parent' | CoordinateExtent`,
-- | narrowed at conversion time. `style` is `Foreign` because upstream's is
-- | `CSSProperties`, whose values are `string | number` — PureScript models it
-- | as `Object String`, which is wrong about the numbers and right about
-- | everything PSFlow does with it, which is spread it onto a DOM node.
-- |
-- | Written as an open row for the same reason `NodeBaseRow` is: upstream's
-- | `InternalNode` is this record plus `internals`, and a second copy of 28
-- | fields is a second thing to drift. `JsInternalNode` extends it below.
type JsNodeRow =
  ( id :: String
  , position :: JsXYPosition
  , data :: Foreign
  , type :: Undefinable String
  , sourcePosition :: Undefinable String
  , targetPosition :: Undefinable String
  , hidden :: Undefinable Boolean
  , selected :: Undefinable Boolean
  , dragging :: Undefinable Boolean
  , resizing :: Undefinable Boolean
  , draggable :: Undefinable Boolean
  , selectable :: Undefinable Boolean
  , connectable :: Undefinable Boolean
  , deletable :: Undefinable Boolean
  , dragHandle :: Undefinable String
  , width :: Undefinable Number
  , height :: Undefinable Number
  , initialWidth :: Undefinable Number
  , initialHeight :: Undefinable Number
  , parentId :: Undefinable String
  , zIndex :: Undefinable Number
  , extent :: Undefinable Foreign
  , expandParent :: Undefinable Boolean
  , ariaLabel :: Undefinable String
  , origin :: Undefinable JsNodeOrigin
  , handles :: Undefinable (Array JsNodeHandle)
  , measured :: Undefinable JsMeasured
  , className :: Undefinable String
  , style :: Undefinable Foreign
  , focusable :: Undefinable Boolean
  , ariaRole :: Undefinable String
  , domAttributes :: Undefinable Foreign
  )

type JsNode = { | JsNodeRow }

-- | Upstream `InternalNode` — a node plus the measurements ps-flow's store
-- | keeps beside it. A JavaScript consumer never builds one; it arrives as
-- | `fromNode` / `toNode` on the connection state a connection handler is
-- | handed, which is the only place on this surface an internal node crosses.
type JsInternalNode = { internals :: JsNodeInternals | JsNodeRow }

-- | Upstream's internals, including the actual original consumer node.
type JsNodeInternals =
  { positionAbsolute :: JsXYPosition
  , z :: Number
  , rootParentIndex :: Undefinable Number
  , handleBounds :: Undefinable JsNodeHandleBounds
  , bounds :: Undefinable JsNodeBounds
  , userNode :: JsNode
  }

-- | A measured node with no handle of a side holds `null` there, as the
-- | upstream DOM query returns. The bounds object itself is separately optional.
type JsNodeHandleBounds =
  { source :: Nullable (Array JsHandle)
  , target :: Nullable (Array JsHandle)
  }

type JsNodeBounds =
  { x :: Number
  , y :: Number
  , width :: Undefinable Number
  , height :: Undefinable Number
  }

-- | Upstream `Handle` — a `NodeHandle` that knows which node it belongs to and
-- | has been measured. Its type tag is `type`, renamed for the same reason
-- | `JsNodeHandle`'s is.
type JsHandle =
  { id :: Undefinable String
  , nodeId :: String
  , x :: Number
  , y :: Number
  , position :: String
  , type :: String
  , width :: Number
  , height :: Number
  }

-- | `{ x, y, zoom }` on both sides, so the conversions below are the identity
-- | — but writing the fields out rather than coercing is what gives the drift
-- | gate a declaration to compare `System.Types.Connection.Viewport` against.
type JsViewport = { x :: Number, y :: Number, zoom :: Number }

-- | The `{ nodes, edges }` bag upstream hands `onDelete`, `onSelectionChange`
-- | and `onBeforeDelete`. One shape, three callbacks, and the last of them
-- | reads it back in.
type JsGraphSelection =
  { nodes :: Array JsNode
  , edges :: Array JsEdge
  }

type JsEdgeMarker =
  { type :: String
  , color :: Undefinable String
  , width :: Undefinable Number
  , height :: Undefinable Number
  , markerUnits :: Undefinable String
  , orient :: Undefinable String
  , strokeWidth :: Undefinable Number
  }

-- | The 30 fields of `System.Types.Edge.EdgeBase`. `markerStart`/`markerEnd`
-- | are `Foreign` because upstream's `EdgeMarkerType` is `string | EdgeMarker`,
-- | and `reconnectable` is because upstream's is `boolean | HandleType`.
type JsEdge =
  { id :: String
  , type :: Undefinable String
  , source :: String
  , target :: String
  , sourceHandle :: Undefinable String
  , targetHandle :: Undefinable String
  , animated :: Undefinable Boolean
  , hidden :: Undefinable Boolean
  , deletable :: Undefinable Boolean
  , selectable :: Undefinable Boolean
  , data :: Undefinable Foreign
  , selected :: Undefinable Boolean
  , markerStart :: Undefinable Foreign
  , markerEnd :: Undefinable Foreign
  , zIndex :: Undefinable Number
  , label :: Undefinable String
  , ariaLabel :: Undefinable String
  , interactionWidth :: Undefinable Number
  , className :: Undefinable String
  , style :: Undefinable Foreign
  , focusable :: Undefinable Boolean
  , reconnectable :: Undefinable Foreign
  , ariaRole :: Undefinable String
  , domAttributes :: Undefinable Foreign
  , labelStyle :: Undefinable Foreign
  , labelShowBg :: Undefinable Boolean
  , labelBgStyle :: Undefinable Foreign
  , labelBgPadding :: Undefinable (Array Number)
  , labelBgBorderRadius :: Undefinable Number
  , pathOptions :: Undefinable JsEdgePathOptions
  }

-- | The union of the three built-in variants' `pathOptions`. See
-- | `System.Types.Edge.EdgePathOptions`.
type JsEdgePathOptions =
  { curvature :: Undefinable Number
  , offset :: Undefinable Number
  , borderRadius :: Undefinable Number
  , stepPosition :: Undefinable Number
  }

-- | What a custom node component receives. Outbound only — a consumer's
-- | component is called with this, never asked to produce one.
-- |
-- | The PureScript record already calls the tag `type`; what crosses here is
-- | the `Maybe`s and the two `Position` sum types.
type JsNodeProps =
  { id :: String
  , data :: Foreign
  , width :: Number
  , height :: Number
  , sourcePosition :: Undefinable String
  , targetPosition :: Undefinable String
  , dragHandle :: Undefinable String
  , parentId :: Undefinable String
  , type :: String
  , dragging :: Boolean
  , zIndex :: Number
  , selectable :: Boolean
  , deletable :: Boolean
  , selected :: Boolean
  , draggable :: Boolean
  , isConnectable :: Boolean
  , positionAbsoluteX :: Number
  , positionAbsoluteY :: Number
  }

-- | Upstream's `NodeChange` is a six-member union discriminated by `type`, and
-- | a consumer reads that tag. PureScript's `NodeChange` is a sum, so the tag
-- | is the constructor; crossing it means writing the tag back out as a field.
-- | The union is flattened into one record with `Undefinable` members, which
-- | is what the runtime object of a discriminated union looks like anyway.
type JsNodeChange =
  { type :: String
  , id :: Undefinable String
  , dimensions :: Undefinable { width :: Number, height :: Number }
  , resizing :: Undefinable Boolean
  , setAttributes :: Undefinable Foreign
  , position :: Undefinable JsXYPosition
  , positionAbsolute :: Undefinable JsXYPosition
  , dragging :: Undefinable Boolean
  , selected :: Undefinable Boolean
  , item :: Undefinable JsNode
  , index :: Undefinable Number
  }

type JsEdgeChange =
  { type :: String
  , id :: Undefinable String
  , selected :: Undefinable Boolean
  , item :: Undefinable JsEdge
  , index :: Undefinable Number
  }

-- | `Connection`'s handles are `string | null` upstream, not
-- | `string | undefined` — the one place on this surface where `null` is the
-- | absent value, and so the one place `Nullable` is right.
type JsConnection =
  { source :: String
  , target :: String
  , sourceHandle :: Nullable String
  , targetHandle :: Nullable String
  }

-- ────────────────────────────────────────────────────────────────────────
-- Small shared shapes
-- ────────────────────────────────────────────────────────────────────────

-- | `[ox, oy]` in, `NodeOrigin { ox, oy }` out.
nodeOriginIn :: String -> JsNodeOrigin -> NodeOrigin
nodeOriginIn field = case _ of
  [ ox, oy ] -> wrap { ox, oy }
  other -> unsafeThrow $ pairError field "[originX, originY]" other

nodeOriginOut :: NodeOrigin -> JsNodeOrigin
nodeOriginOut o = [ (unwrap o).ox, (unwrap o).oy ]

-- | `[gx, gy]` in, `SnapGrid { gx, gy }` out.
snapGridIn :: String -> Array Number -> SnapGrid
snapGridIn field = case _ of
  [ gx, gy ] -> wrap { gx, gy }
  other -> unsafeThrow $ pairError field "[gridX, gridY]" other

-- | `[[minX, minY], [maxX, maxY]]`.
coordinateExtentIn :: String -> JsCoordinateExtent -> CoordinateExtent
coordinateExtentIn field = case _ of
  [ [ minX, minY ], [ maxX, maxY ] ] -> wrap { minX, minY, maxX, maxY }
  _ ->
    unsafeThrow $
      "ps-flow: `" <> field
        <> "` must be [[minX, minY], [maxX, maxY]]."

coordinateExtentOut :: CoordinateExtent -> JsCoordinateExtent
coordinateExtentOut e =
  [ [ (unwrap e).minX, (unwrap e).minY ]
  , [ (unwrap e).maxX, (unwrap e).maxY ]
  ]

pairError :: String -> String -> Array Number -> String
pairError field shape got =
  "ps-flow: `" <> field <> "` must be " <> shape
    <> " — exactly two numbers, got "
    <> show (Array.length got)
    <> "."

-- | Upstream `KeyCode` is `string | string[]`, and the prop is typed
-- | `KeyCode | null` — three states, because `null` **disables the key** while
-- | absence means *use the default*, and the defaults are not nothing
-- | (`"Backspace"` for delete, `"Shift"` for selection). `Maybe KeyCode` holds
-- | two of the three.
-- |
-- | So `null` is refused rather than folded in with absence. Folding it in is
-- | worse than ignoring the prop: a consumer writing `deleteKeyCode={null}` to
-- | switch deletion off would get deletion **on**, bound to Backspace — the
-- | opposite of what they asked for, silently. Refusing it is the same
-- | decision as the deferred props, one level down: a prop you set either
-- | works or throws.
-- |
-- | An empty array *is* folded into `Nothing`, because it names no key and so
-- | can never match one, which is what absence already does.
keyCodeIn :: String -> Undefinable Foreign -> Maybe KeyCode
keyCodeIn field u
  | isNull u =
      unsafeThrow $
        "ps-flow: `" <> field
          <> "` was set to null, which upstream reads as \"disable this key\". "
          <> "ps-flow cannot express that yet — its key-code type has no "
          <> "disabled state, so a null would silently fall back to the "
          <> "default key instead. Omit the prop to get the default, or pass "
          <> "the key you want."
keyCodeIn field u = map (keyCodeValueIn field) (fromUndefinable u)

-- | The same conversion with the null guard removed, for the one caller that
-- | must not have it.
-- |
-- | `useKeyPress`'s first parameter *defaults* to `null` upstream, so there
-- | `null` and absent mean the same thing — listen for no key — and both are
-- | ps-flow's `Nothing`. The guard above exists because on the five key-code
-- | *props* the two differ, `null` meaning "disable this key" against absence
-- | meaning "use the default"; where there is no default to fall back to,
-- | there is nothing to warn about.
keyCodeValueIn :: String -> Foreign -> KeyCode
keyCodeValueIn field raw =
  case asString raw of
    Just s -> SingleKey s
    Nothing -> case asArray raw of
      Just entries ->
        case NEA.fromArray (map (readKey field) entries) of
          Just nea -> MultiKey nea
          -- Upstream's empty array listens for nothing, and so does
          -- `SingleKey ""`: no `KeyboardEvent.key` is the empty string, so the
          -- matcher never fires. `MultiKey` cannot say it — its array is
          -- non-empty by construction — and answering `Nothing` is not
          -- available either, because the caller has already established that
          -- a key code *was* supplied.
          Nothing -> SingleKey ""
      Nothing ->
        unsafeThrow $
          "ps-flow: `" <> field <> "` must be a string or an array of strings, got "
            <> typeName raw
            <> "."

readKey :: String -> Foreign -> String
readKey field raw = case asString raw of
  Just s -> s
  Nothing ->
    unsafeThrow $
      "ps-flow: every entry of `" <> field <> "` must be a string, got "
        <> typeName raw
        <> "."

-- ────────────────────────────────────────────────────────────────────────
-- Node
-- ────────────────────────────────────────────────────────────────────────

nodeIn :: JsNode -> NodeBase Foreign
nodeIn n = runFn2 rememberUserNode (unsafeCoerce n)
  { id: wrap n.id
  , position: n.position
  , data: n.data
  , sourcePosition: map (positionIn "node.sourcePosition") (fromUndefinable n.sourcePosition)
  , targetPosition: map (positionIn "node.targetPosition") (fromUndefinable n.targetPosition)
  , hidden: fromUndefinable n.hidden
  , selected: fromUndefinable n.selected
  , dragging: fromUndefinable n.dragging
  , resizing: fromUndefinable n.resizing
  , draggable: fromUndefinable n.draggable
  , selectable: fromUndefinable n.selectable
  , connectable: fromUndefinable n.connectable
  , deletable: fromUndefinable n.deletable
  , dragHandle: fromUndefinable n.dragHandle
  , width: fromUndefinable n.width
  , height: fromUndefinable n.height
  , initialWidth: fromUndefinable n.initialWidth
  , initialHeight: fromUndefinable n.initialHeight
  , parentId: map wrap (fromUndefinable n.parentId)
  , zIndex: map Int.round (fromUndefinable n.zIndex)
  , extent: map nodeExtentIn (fromUndefinable n.extent)
  , expandParent: fromUndefinable n.expandParent
  , ariaLabel: fromUndefinable n.ariaLabel
  , origin: map (nodeOriginIn "node.origin") (fromUndefinable n.origin)
  , handles: map (map nodeHandleIn) (fromUndefinable n.handles)
  , measured: maybe emptyMeasured measuredIn (fromUndefinable n.measured)
  , nodeType: fromUndefinable n.type
  , className: fromUndefinable n.className
  , style: map asCssObject (fromUndefinable n.style)
  , focusable: fromUndefinable n.focusable
  , ariaRole: fromUndefinable n.ariaRole
  , domAttributes: map opaque (fromUndefinable n.domAttributes)
  }

-- | A consumer's node, as upstream hands it back: only the keys that hold a
-- | value. See `pruneUndefined`.
-- |
-- | `measured` is written only after the node is measured. Upstream's
-- | `applyNodeChanges` adds it to the consumer's node with a dimension change,
-- | so a node that hasn't been measured has no `measured` key.
nodeOut :: NodeBase Foreign -> JsNode
nodeOut n = pruneUndefined
  { id: unwrap n.id
  , position: n.position
  , data: n.data
  , type: toUndefinable n.nodeType
  , sourcePosition: toUndefinable (map positionOut n.sourcePosition)
  , targetPosition: toUndefinable (map positionOut n.targetPosition)
  , hidden: toUndefinable n.hidden
  , selected: toUndefinable n.selected
  , dragging: toUndefinable n.dragging
  , resizing: toUndefinable n.resizing
  , draggable: toUndefinable n.draggable
  , selectable: toUndefinable n.selectable
  , connectable: toUndefinable n.connectable
  , deletable: toUndefinable n.deletable
  , dragHandle: toUndefinable n.dragHandle
  , width: toUndefinable n.width
  , height: toUndefinable n.height
  , initialWidth: toUndefinable n.initialWidth
  , initialHeight: toUndefinable n.initialHeight
  , parentId: toUndefinable (map unwrap n.parentId)
  , zIndex: toUndefinable (map Int.toNumber n.zIndex)
  , extent: toUndefinable (map nodeExtentOut n.extent)
  , expandParent: toUndefinable n.expandParent
  , ariaLabel: toUndefinable n.ariaLabel
  , origin: toUndefinable (map nodeOriginOut n.origin)
  , handles: toUndefinable (map (map nodeHandleOut) n.handles)
  , measured: if n.measured == emptyMeasured then undefined else defined (measuredOut n.measured)
  , className: toUndefinable n.className
  , style: toUndefinable (map fromCssObject n.style)
  , focusable: toUndefinable n.focusable
  , ariaRole: toUndefinable n.ariaRole
  , domAttributes: toUndefinable (map unOpaque n.domAttributes)
  }

-- | A node plus its `internals`. `nodeOut` is *not* reused here: it returns a
-- | closed `JsNode`, and this record is the same row with one more field, so
-- | the fields are written once more rather than being merged — which is what
-- | keeps `JsNodeRow` the single declaration the drift gate reads.
-- |
-- | Pruned at the top level, where upstream spreads the consumer's node.
-- | `measured` keeps both its keys, because upstream builds it as
-- | `{ width: userNode.measured?.width, height: userNode.measured?.height }`.
internalNodeOut :: InternalNodeBase Foreign -> JsInternalNode
internalNodeOut n = case toMaybe (originalUserNode n.internals.userNode) of
  Nothing -> converted
  -- Upstream builds the internal node as `{ ...userNode, measured, internals }`,
  -- so a key only the consumer's node has is on the internal node too.
  Just original -> runFn2 spreadUnder original converted
  where
  converted = internalNodeFields n

internalNodeFields :: InternalNodeBase Foreign -> JsInternalNode
internalNodeFields n = pruneUndefined
  { id: unwrap n.id
  , position: n.position
  , data: n.data
  , type: toUndefinable n.nodeType
  , sourcePosition: toUndefinable (map positionOut n.sourcePosition)
  , targetPosition: toUndefinable (map positionOut n.targetPosition)
  , hidden: toUndefinable n.hidden
  , selected: toUndefinable n.selected
  , dragging: toUndefinable n.dragging
  , resizing: toUndefinable n.resizing
  , draggable: toUndefinable n.draggable
  , selectable: toUndefinable n.selectable
  , connectable: toUndefinable n.connectable
  , deletable: toUndefinable n.deletable
  , dragHandle: toUndefinable n.dragHandle
  , width: toUndefinable n.width
  , height: toUndefinable n.height
  , initialWidth: toUndefinable n.initialWidth
  , initialHeight: toUndefinable n.initialHeight
  , parentId: toUndefinable (map unwrap n.parentId)
  , zIndex: toUndefinable (map Int.toNumber n.zIndex)
  , extent: toUndefinable (map nodeExtentOut n.extent)
  , expandParent: toUndefinable n.expandParent
  , ariaLabel: toUndefinable n.ariaLabel
  , origin: toUndefinable (map nodeOriginOut n.origin)
  , handles: toUndefinable (map (map nodeHandleOut) n.handles)
  , measured: toUndefinable (Just (measuredOut n.measured))
  , className: toUndefinable n.className
  , style: toUndefinable (map fromCssObject n.style)
  , focusable: toUndefinable n.focusable
  , ariaRole: toUndefinable n.ariaRole
  , domAttributes: toUndefinable (map unOpaque n.domAttributes)
  , internals: nodeInternalsOut n.internals
  }

-- | Upstream's `adoptUserNodes` builds `internals` with `positionAbsolute`,
-- | `z`, and `handleBounds`, which is `undefined` until the node is measured.
-- | `rootParentIndex` is written only on a parent node, and `bounds` never
-- | is. So the two optional keys are pruned, and `handleBounds` is set on the
-- | pruned record whether or not it holds a value.
nodeInternalsOut :: NodeInternals Foreign -> JsNodeInternals
nodeInternalsOut i =
  unsafeSet "handleBounds" (toUndefinable (map handleBoundsOut i.handleBounds)) $ pruneUndefined
    { positionAbsolute: i.positionAbsolute
    , z: i.z
    , rootParentIndex: toUndefinable (map Int.toNumber i.rootParentIndex)
    , bounds: toUndefinable (map nodeBoundsOut i.bounds)
    , userNode: maybe (nodeOut i.userNode) unsafeCoerce (toMaybe (originalUserNode i.userNode))
    }

-- | The way back, for a JavaScript consumer writing an internal node into the
-- | store with `setState`. Upstream stores whatever it is handed; the base
-- | node converts as `nodeIn` does, and `internals.userNode` keeps the
-- | consumer's own node as `nodeIn` keeps any other.
internalNodeIn :: JsInternalNode -> InternalNodeBase Foreign
internalNodeIn n =
  Record.insert (Proxy :: Proxy "internals") (nodeInternalsIn n.internals)
    (nodeIn (unsafeCoerce n :: JsNode))

nodeInternalsIn :: JsNodeInternals -> NodeInternals Foreign
nodeInternalsIn i =
  { positionAbsolute: i.positionAbsolute
  , z: i.z
  , rootParentIndex: map Int.round (fromUndefinable i.rootParentIndex)
  , handleBounds: map handleBoundsIn (fromUndefinable i.handleBounds)
  , bounds: map nodeBoundsIn (fromUndefinable i.bounds)
  , userNode: nodeIn i.userNode
  }

handleBoundsIn :: JsNodeHandleBounds -> NodeHandleBounds
handleBoundsIn b =
  { source: map (map (SourceHandle <<< handleIn "internals.handleBounds.source")) (toMaybe b.source)
  , target: map (map (TargetHandle <<< handleIn "internals.handleBounds.target")) (toMaybe b.target)
  }

nodeBoundsIn :: JsNodeBounds -> NodeBounds
nodeBoundsIn b =
  { x: b.x
  , y: b.y
  , width: fromUndefinable b.width
  , height: fromUndefinable b.height
  }

handleIn :: String -> JsHandle -> Handle
handleIn field h =
  { id: handleIdIn h.id
  , nodeId: wrap h.nodeId
  , x: h.x
  , y: h.y
  , position: positionIn (field <> ".position") h.position
  , handleType: handleTypeIn (field <> ".type") h.type
  , width: h.width
  , height: h.height
  }

handleBoundsOut :: NodeHandleBounds -> JsNodeHandleBounds
handleBoundsOut b =
  { source: toNullable (map (map (handleOut <<< unSourceHandle)) b.source)
  , target: toNullable (map (map (handleOut <<< unTargetHandle)) b.target)
  }

nodeBoundsOut :: NodeBounds -> JsNodeBounds
nodeBoundsOut b =
  { x: b.x
  , y: b.y
  , width: toUndefinable b.width
  , height: toUndefinable b.height
  }

handleOut :: Handle -> JsHandle
handleOut h =
  { id: handleIdOut h.id
  , nodeId: unwrap h.nodeId
  , x: h.x
  , y: h.y
  , position: positionOut h.position
  , type: handleTypeOut h.handleType
  , width: h.width
  , height: h.height
  }

emptyMeasured :: { width :: Maybe Number, height :: Maybe Number }
emptyMeasured = { width: Nothing, height: Nothing }

measuredIn :: JsMeasured -> { width :: Maybe Number, height :: Maybe Number }
measuredIn m =
  { width: fromUndefinable m.width
  , height: fromUndefinable m.height
  }

measuredOut :: { width :: Maybe Number, height :: Maybe Number } -> JsMeasured
measuredOut m =
  { width: toUndefinable m.width
  , height: toUndefinable m.height
  }

nodeExtentIn :: Foreign -> NodeExtent
nodeExtentIn raw = case asString raw of
  Just "parent" -> ParentExtent
  Just other ->
    unsafeThrow $
      "ps-flow: `node.extent` accepts the string \"parent\" or a coordinate "
        <> "extent, got "
        <> show other
        <> "."
  Nothing -> case asArray raw of
    Just _ -> CoordExtent (coordinateExtentIn "node.extent" (unsafeCoerce raw))
    Nothing ->
      unsafeThrow $
        "ps-flow: `node.extent` accepts the string \"parent\" or "
          <> "[[minX, minY], [maxX, maxY]], got "
          <> typeName raw
          <> "."

nodeExtentOut :: NodeExtent -> Foreign
nodeExtentOut = case _ of
  ParentExtent -> unsafeCoerce "parent"
  CoordExtent e -> unsafeCoerce (coordinateExtentOut e)

-- | A handle's `id` in its three states. Upstream copies a `node.handles`
-- | entry's `id` as the consumer wrote it, and a measured handle's `null`
-- | crosses as `null`.
handleIdIn :: Undefinable String -> HandleIdField
handleIdIn u
  | isNull u = HandleIdNull
  | otherwise = maybe HandleIdUnset HandleIdSet (fromUndefinable u)

handleIdOut :: HandleIdField -> Undefinable String
handleIdOut = case _ of
  HandleIdUnset -> undefined
  HandleIdNull -> nullUndefinable
  HandleIdSet s -> defined s

nodeHandleIn :: JsNodeHandle -> NodeHandle
nodeHandleIn h =
  { id: handleIdIn h.id
  , x: h.x
  , y: h.y
  , position: positionIn "node.handles[].position" h.position
  , handleType: handleTypeIn "node.handles[].type" h.type
  , width: fromUndefinable h.width
  , height: fromUndefinable h.height
  }

nodeHandleOut :: NodeHandle -> JsNodeHandle
nodeHandleOut h =
  { id: handleIdOut h.id
  , x: h.x
  , y: h.y
  , position: positionOut h.position
  , type: handleTypeOut h.handleType
  , width: toUndefinable h.width
  , height: toUndefinable h.height
  }

-- `CSSProperties`, which ps-flow models with two types depending on where it
-- appears, so the crossing needs both. One runtime object either way — a
-- `style` prop is spread onto a DOM node and nothing on this surface reads it —
-- which is what makes every one of these a coercion rather than a conversion.
--
-- `Object String` is the node's, the edge's and the four chrome components'.
-- The type stops being true about numeric CSS values there; a JavaScript
-- consumer's `{ width: 4 }` arrives and is spread unread.
asCssObject :: Foreign -> Object String
asCssObject = unsafeCoerce

fromCssObject :: Object String -> Foreign
fromCssObject = unsafeCoerce

-- The opaque `React.Types.Edges.Style`, which is what the connection-line
-- props and `<Handle />` carry instead. It went one way only until boundary
-- stage 4: `edgeTypes` and `connectionLineComponent` hand a consumer's own
-- component the styles ps-flow resolved for it, so the way back is needed now.
asCssStyle :: Foreign -> Style
asCssStyle = unsafeCoerce

fromCssStyle :: Style -> Foreign
fromCssStyle = unsafeCoerce

-- ────────────────────────────────────────────────────────────────────────
-- Edge
-- ────────────────────────────────────────────────────────────────────────

edgeIn :: JsEdge -> EdgeBase Foreign
edgeIn e = runFn2 rememberUserEdge (unsafeCoerce e)
  { id: e.id
  , edgeType: fromUndefinable e.type
  , source: wrap e.source
  , target: wrap e.target
  , sourceHandle: fromUndefinable e.sourceHandle
  , targetHandle: fromUndefinable e.targetHandle
  , animated: fromUndefinable e.animated
  , hidden: fromUndefinable e.hidden
  , deletable: fromUndefinable e.deletable
  , selectable: fromUndefinable e.selectable
  , data: fromUndefinable e.data
  , selected: fromUndefinable e.selected
  , markerStart: map (markerIn "edge.markerStart") (fromUndefinable e.markerStart)
  , markerEnd: map (markerIn "edge.markerEnd") (fromUndefinable e.markerEnd)
  , zIndex: map Int.round (fromUndefinable e.zIndex)
  , label: fromUndefinable e.label
  , ariaLabel: edgeAriaLabelIn e.ariaLabel
  , interactionWidth: fromUndefinable e.interactionWidth
  , className: fromUndefinable e.className
  , style: map asCssObject (fromUndefinable e.style)
  , focusable: fromUndefinable e.focusable
  , reconnectable: map (edgeReconnectableIn "edge.reconnectable") (fromUndefinable e.reconnectable)
  , ariaRole: fromUndefinable e.ariaRole
  , domAttributes: map opaque (fromUndefinable e.domAttributes)
  , labelStyle: map asCssObject (fromUndefinable e.labelStyle)
  , labelShowBg: fromUndefinable e.labelShowBg
  , labelBgStyle: map asCssObject (fromUndefinable e.labelBgStyle)
  , labelBgPadding: map (labelBgPaddingIn "edge.labelBgPadding") (fromUndefinable e.labelBgPadding)
  , labelBgBorderRadius: fromUndefinable e.labelBgBorderRadius
  , pathOptions: map edgePathOptionsIn (fromUndefinable e.pathOptions)
  }

-- | Polymorphic in the edge's data, where `nodeIn`/`nodeOut` are not: every
-- | edge that crosses carries `Foreign` data bar one, and that one is
-- | `<Handle isValidConnection>`, whose `IsValidConnection Unit` says the
-- | predicate never reads it. `unsafeToForeign` is what the field crosses as
-- | either way — `data` is the consumer's own value, handed back unread.
edgeOut :: forall e. EdgeBase e -> JsEdge
edgeOut e = pruneUndefined
  { id: e.id
  , type: toUndefinable e.edgeType
  , source: unwrap e.source
  , target: unwrap e.target
  , sourceHandle: toUndefinable e.sourceHandle
  , targetHandle: toUndefinable e.targetHandle
  , animated: toUndefinable e.animated
  , hidden: toUndefinable e.hidden
  , deletable: toUndefinable e.deletable
  , selectable: toUndefinable e.selectable
  , data: toUndefinable (map unsafeToForeign e.data)
  , selected: toUndefinable e.selected
  , markerStart: toUndefinable (map markerOut e.markerStart)
  , markerEnd: toUndefinable (map markerOut e.markerEnd)
  , zIndex: toUndefinable (map Int.toNumber e.zIndex)
  , label: toUndefinable e.label
  , ariaLabel: edgeAriaLabelOut e.ariaLabel
  , interactionWidth: toUndefinable e.interactionWidth
  , className: toUndefinable e.className
  , style: toUndefinable (map fromCssObject e.style)
  , focusable: toUndefinable e.focusable
  , reconnectable: toUndefinable (map edgeReconnectableOut e.reconnectable)
  , ariaRole: toUndefinable e.ariaRole
  , domAttributes: toUndefinable (map unOpaque e.domAttributes)
  , labelStyle: toUndefinable (map fromCssObject e.labelStyle)
  , labelShowBg: toUndefinable e.labelShowBg
  , labelBgStyle: toUndefinable (map fromCssObject e.labelBgStyle)
  , labelBgPadding: toUndefinable (map labelBgPaddingOut e.labelBgPadding)
  , labelBgBorderRadius: toUndefinable e.labelBgBorderRadius
  , pathOptions: toUndefinable (map edgePathOptionsOut e.pathOptions)
  }

-- | The consumer's own edge object when this record was decoded from one,
-- | and `edgeOut`'s copy otherwise. Upstream's store holds the consumer's
-- | edges, so a raw store read hands the same objects back.
edgeIdentityOut :: forall e. EdgeBase e -> JsEdge
edgeIdentityOut e = maybe (edgeOut e) unsafeCoerce (toMaybe (originalUserEdge e))

-- | The node counterpart of `edgeIdentityOut`.
nodeIdentityOut :: NodeBase Foreign -> JsNode
nodeIdentityOut n = maybe (nodeOut n) unsafeCoerce (toMaybe (originalUserNode n))

-- | `boolean | HandleType`.
edgeReconnectableIn :: String -> Foreign -> EdgeReconnectable
edgeReconnectableIn field raw = case asBoolean raw of
  Just flag -> ReconnectableFlag flag
  Nothing -> case asString raw of
    Just s -> ReconnectableEnd (handleTypeIn field s)
    Nothing ->
      unsafeThrow $
        "ps-flow: `" <> field <> "` must be a boolean, \"source\" or \"target\", got "
          <> typeName raw
          <> "."

edgeReconnectableOut :: EdgeReconnectable -> Foreign
edgeReconnectableOut = case _ of
  ReconnectableFlag flag -> unsafeToForeign flag
  ReconnectableEnd end -> unsafeToForeign (handleTypeOut end)

-- | `labelBgPadding` is `[number, number]` upstream and `{ x, y }` in
-- | ps-flow's label records.
labelBgPaddingIn :: String -> Array Number -> { x :: Number, y :: Number }
labelBgPaddingIn field = case _ of
  [ x, y ] -> { x, y }
  _ ->
    unsafeThrow $
      "ps-flow: `" <> field <> "` must be [paddingX, paddingY]."

labelBgPaddingOut :: { x :: Number, y :: Number } -> Array Number
labelBgPaddingOut p = [ p.x, p.y ]

edgePathOptionsIn :: JsEdgePathOptions -> EdgePathOptions
edgePathOptionsIn o =
  { curvature: fromUndefinable o.curvature
  , offset: fromUndefinable o.offset
  , borderRadius: fromUndefinable o.borderRadius
  , stepPosition: fromUndefinable o.stepPosition
  }

edgePathOptionsOut :: EdgePathOptions -> JsEdgePathOptions
edgePathOptionsOut o = pruneUndefined
  { curvature: toUndefinable o.curvature
  , offset: toUndefinable o.offset
  , borderRadius: toUndefinable o.borderRadius
  , stepPosition: toUndefinable o.stepPosition
  }

-- | An edge's `ariaLabel`, where `null` turns the label off and absence
-- | gives the default one, so the two can't fold together as they do on
-- | every other field. See `EdgeAriaLabel`.
edgeAriaLabelIn :: Undefinable String -> Maybe EdgeAriaLabel
edgeAriaLabelIn u
  | isNull u = Just AriaLabelOff
  | otherwise = map AriaLabel (fromUndefinable u)

-- | Hands a consumer's `null` back as `null`, as upstream hands back their
-- | own object.
edgeAriaLabelOut :: Maybe EdgeAriaLabel -> Undefinable String
edgeAriaLabelOut = case _ of
  Nothing -> undefined
  Just AriaLabelOff -> nullUndefinable
  Just (AriaLabel s) -> defined s

-- | `string | EdgeMarker`: the string names a built-in marker, the object
-- | configures one.
markerIn :: String -> Foreign -> EdgeMarkerType
markerIn field raw = case asString raw of
  Just s -> NamedMarker s
  Nothing -> CustomMarker (edgeMarkerIn field (unsafeCoerce raw))

markerOut :: EdgeMarkerType -> Foreign
markerOut = case _ of
  NamedMarker s -> unsafeCoerce s
  CustomMarker m -> unsafeCoerce (edgeMarkerOut m)

edgeMarkerIn :: String -> JsEdgeMarker -> EdgeMarker
edgeMarkerIn field m =
  { markerType: markerTypeIn (field <> ".type") m.type
  , color: fromUndefinable m.color
  , width: fromUndefinable m.width
  , height: fromUndefinable m.height
  , markerUnits: fromUndefinable m.markerUnits
  , orient: fromUndefinable m.orient
  , strokeWidth: fromUndefinable m.strokeWidth
  }

-- | The consumer's own marker object, so pruned as `edgeOut` is.
edgeMarkerOut :: EdgeMarker -> JsEdgeMarker
edgeMarkerOut m = pruneUndefined
  { type: markerTypeOut m.markerType
  , color: toUndefinable m.color
  , width: toUndefinable m.width
  , height: toUndefinable m.height
  , markerUnits: toUndefinable m.markerUnits
  , orient: toUndefinable m.orient
  , strokeWidth: toUndefinable m.strokeWidth
  }

-- ────────────────────────────────────────────────────────────────────────
-- Default edge options
-- ────────────────────────────────────────────────────────────────────────

-- | Upstream's `DefaultEdgeOptions`, which is `Edge` without its identity
-- | fields and `selected`: the 23 members below. Each converts as the
-- | matching `JsEdge` member does, because upstream spreads this object under
-- | every edge it renders and under every connection `onConnect` receives.
type JsDefaultEdgeOptions =
  { type :: Undefinable String
  , animated :: Undefinable Boolean
  , hidden :: Undefinable Boolean
  , deletable :: Undefinable Boolean
  , selectable :: Undefinable Boolean
  , data :: Undefinable Foreign
  , markerStart :: Undefinable Foreign
  , markerEnd :: Undefinable Foreign
  , zIndex :: Undefinable Number
  , ariaLabel :: Undefinable String
  , interactionWidth :: Undefinable Number
  , label :: Undefinable String
  , labelStyle :: Undefinable Foreign
  , labelShowBg :: Undefinable Boolean
  , labelBgStyle :: Undefinable Foreign
  , labelBgPadding :: Undefinable (Array Number)
  , labelBgBorderRadius :: Undefinable Number
  , style :: Undefinable Foreign
  , className :: Undefinable String
  , reconnectable :: Undefinable Foreign
  , focusable :: Undefinable Boolean
  , ariaRole :: Undefinable String
  , domAttributes :: Undefinable Foreign
  }

-- | Remembers the consumer's object, which is what upstream's store holds
-- | and what `defaultEdgeOptionsOut` hands back.
defaultEdgeOptionsIn :: JsDefaultEdgeOptions -> DefaultEdgeOptions Foreign
defaultEdgeOptionsIn js =
  runFn2 rememberDefaultEdgeOptions (unsafeToForeign js) (decodeDefaultEdgeOptions js)

decodeDefaultEdgeOptions :: JsDefaultEdgeOptions -> DefaultEdgeOptions Foreign
decodeDefaultEdgeOptions = remembering \o ->
  { edgeType: fromUndefinable o.type
  , animated: fromUndefinable o.animated
  , hidden: fromUndefinable o.hidden
  , deletable: fromUndefinable o.deletable
  , selectable: fromUndefinable o.selectable
  , data: fromUndefinable o.data
  , markerStart: map (markerIn "defaultEdgeOptions.markerStart") (fromUndefinable o.markerStart)
  , markerEnd: map (markerIn "defaultEdgeOptions.markerEnd") (fromUndefinable o.markerEnd)
  , zIndex: map Int.round (fromUndefinable o.zIndex)
  , ariaLabel: edgeAriaLabelIn o.ariaLabel
  , interactionWidth: fromUndefinable o.interactionWidth
  , label: fromUndefinable o.label
  , labelStyle: map asCssObject (fromUndefinable o.labelStyle)
  , labelShowBg: fromUndefinable o.labelShowBg
  , labelBgStyle: map asCssObject (fromUndefinable o.labelBgStyle)
  , labelBgPadding:
      map (labelBgPaddingIn "defaultEdgeOptions.labelBgPadding") (fromUndefinable o.labelBgPadding)
  , labelBgBorderRadius: fromUndefinable o.labelBgBorderRadius
  , style: map asCssObject (fromUndefinable o.style)
  , className: fromUndefinable o.className
  , reconnectable:
      map (edgeReconnectableIn "defaultEdgeOptions.reconnectable") (fromUndefinable o.reconnectable)
  , focusable: fromUndefinable o.focusable
  , ariaRole: fromUndefinable o.ariaRole
  , domAttributes: map opaque (fromUndefinable o.domAttributes)
  }

-- | The consumer's own object when there is one, and a pruned conversion
-- | when the options were built in PureScript.
defaultEdgeOptionsOut :: forall e. DefaultEdgeOptions e -> JsDefaultEdgeOptions
defaultEdgeOptionsOut o = case originalOf o of
  Just original -> unsafeCoerce original
  Nothing -> pruneUndefined
    { type: toUndefinable o.edgeType
    , animated: toUndefinable o.animated
    , hidden: toUndefinable o.hidden
    , deletable: toUndefinable o.deletable
    , selectable: toUndefinable o.selectable
    , data: toUndefinable (map unsafeToForeign o.data)
    , markerStart: toUndefinable (map markerOut o.markerStart)
    , markerEnd: toUndefinable (map markerOut o.markerEnd)
    , zIndex: toUndefinable (map Int.toNumber o.zIndex)
    , ariaLabel: edgeAriaLabelOut o.ariaLabel
    , interactionWidth: toUndefinable o.interactionWidth
    , label: toUndefinable o.label
    , labelStyle: toUndefinable (map fromCssObject o.labelStyle)
    , labelShowBg: toUndefinable o.labelShowBg
    , labelBgStyle: toUndefinable (map fromCssObject o.labelBgStyle)
    , labelBgPadding: toUndefinable (map labelBgPaddingOut o.labelBgPadding)
    , labelBgBorderRadius: toUndefinable o.labelBgBorderRadius
    , style: toUndefinable (map fromCssObject o.style)
    , className: toUndefinable o.className
    , reconnectable: toUndefinable (map edgeReconnectableOut o.reconnectable)
    , focusable: toUndefinable o.focusable
    , ariaRole: toUndefinable o.ariaRole
    , domAttributes: toUndefinable (map unOpaque o.domAttributes)
    }

-- ────────────────────────────────────────────────────────────────────────
-- Node props, and the node-type map that delivers them
-- ────────────────────────────────────────────────────────────────────────

nodePropsOut :: NodeProps Foreign -> JsNodeProps
nodePropsOut p =
  { id: p.id
  , data: p.data
  , width: p.width
  , height: p.height
  , sourcePosition: toUndefinable (map positionOut p.sourcePosition)
  , targetPosition: toUndefinable (map positionOut p.targetPosition)
  , dragHandle: toUndefinable p.dragHandle
  , parentId: toUndefinable p.parentId
  , type: p.type
  , dragging: p.dragging
  , zIndex: p.zIndex
  , selectable: p.selectable
  , deletable: p.deletable
  , selected: p.selected
  , draggable: p.draggable
  , isConnectable: p.isConnectable
  , positionAbsoluteX: p.positionAbsoluteX
  , positionAbsoluteY: p.positionAbsoluteY
  }

-- | `nodeTypes` is the one prop whose *values* are consumer code that PSFlow
-- | calls, so crossing it is not a data conversion — every component in the
-- | map is wrapped so that what reaches it is `JsNodeProps` rather than the
-- | PureScript record the renderer builds.
-- |
-- | The map is an ordinary object at runtime on both sides (`NodeTypesMap` is
-- | opaque in PureScript precisely so the renderer can treat it as one), so
-- | the wrapping is a `mapWithKey` and a coercion back.
nodeTypesIn :: Object (ReactComponent JsNodeProps) -> NodeTypesMap
nodeTypesIn types =
  unsafeCoerce (Object.mapWithKey (\_ c -> wrapNodeComponent c) types)

wrapNodeComponent
  :: ReactComponent JsNodeProps
  -> ReactComponent (NodeProps Foreign)
wrapNodeComponent userComponent =
  mkComponentWrapper "nodeTypes" userComponent
    (mkEffectFn1 \psProps -> pure (element userComponent (nodePropsOut psProps)))

-- ────────────────────────────────────────────────────────────────────────
-- Changes, and connections
-- ────────────────────────────────────────────────────────────────────────

-- | The tag a change arrived with names no variant. Refused rather than
-- | dropped: a change ps-flow discarded in silence is indistinguishable from a
-- | change the library looked at and decided made no difference, and upstream
-- | gains change kinds between releases.
-- |
-- | The message names the tag it got and not the tags it knows. A written-out
-- | list is one more thing to go stale, and this one would go stale *silently*:
-- | the match below is on a `String` with a catch-all, so a seventh member
-- | added to the sum reaches this branch instead of failing to compile, and the
-- | list would then be wrong at exactly the moment someone read it.
unknownChange :: forall a. String -> String -> a
unknownChange what tag =
  unsafeThrow $
    "ps-flow: `" <> tag <> "` is not a " <> what <> "-change type."

-- | A member the change's own kind must carry — the id of the node a `select`
-- | selects, the item an `add` adds. Absent, there is nothing to apply, and
-- | filling it in with a default would act on the wrong element rather than
-- | say so.
requiredMember :: forall a. String -> String -> Undefinable a -> a
requiredMember tag member = fromMaybe' throw <<< fromUndefinable
  where
  throw _ =
    unsafeThrow $
      "ps-flow: a `" <> tag <> "` change must carry `" <> member <> "`."

-- | Inbound, for `applyNodeChanges`. The tag is a field on the way in and the
-- | constructor on the way out, so this is `nodeChangeOut` read backwards —
-- | with the difference that the JS side's `Undefinable` members are only
-- | optional *across* the union, and each variant needs its own.
nodeChangeIn :: JsNodeChange -> NodeChange Foreign
nodeChangeIn c = case c.type of
  "dimensions" -> NodeDimensionChange
    { id: wrap (requiredMember c.type "id" c.id)
    , dimensions: fromUndefinable c.dimensions
    , resizing: fromUndefinable c.resizing
    , setAttributes: map setAttributesIn (fromUndefinable c.setAttributes)
    }
  "position" -> NodePositionChange
    { id: wrap (requiredMember c.type "id" c.id)
    , position: fromUndefinable c.position
    , positionAbsolute: fromUndefinable c.positionAbsolute
    , dragging: fromUndefinable c.dragging
    }
  "select" -> NodeSelectionChange
    { id: wrap (requiredMember c.type "id" c.id)
    , selected: requiredMember c.type "selected" c.selected
    }
  "remove" -> NodeRemoveChange
    { id: wrap (requiredMember c.type "id" c.id) }
  "add" -> NodeAddChange
    { item: nodeIn (requiredMember c.type "item" c.item)
    , index: map Int.round (fromUndefinable c.index)
    }
  "replace" -> NodeReplaceChange
    { id: wrap (requiredMember c.type "id" c.id)
    , item: nodeIn (requiredMember c.type "item" c.item)
    }
  other -> unknownChange "node" other

-- | The six-member node-change union. `type` carries the tag a consumer
-- | switches on; every other field is present only on the members that have
-- | it, which is what `Undefinable` says. Upstream builds each change with
-- | only the keys it sets, such as `{ id, type: 'select', selected }`, so the
-- | fields a member doesn't set are pruned rather than sent as `undefined`.
nodeChangeOut :: NodeChange Foreign -> JsNodeChange
nodeChangeOut = pruneUndefined <<< case _ of
  NodeDimensionChange c -> emptyNodeChange
    { type = "dimensions"
    , id = toUndefinable (Just (unwrap c.id))
    , dimensions = toUndefinable c.dimensions
    , resizing = toUndefinable c.resizing
    , setAttributes = toUndefinable (map setAttributesOut c.setAttributes)
    }
  NodePositionChange c -> emptyNodeChange
    { type = "position"
    , id = toUndefinable (Just (unwrap c.id))
    , position = toUndefinable c.position
    , positionAbsolute = toUndefinable c.positionAbsolute
    , dragging = toUndefinable c.dragging
    }
  NodeSelectionChange c -> emptyNodeChange
    { type = "select"
    , id = toUndefinable (Just (unwrap c.id))
    , selected = toUndefinable (Just c.selected)
    }
  NodeRemoveChange c -> emptyNodeChange
    { type = "remove"
    , id = toUndefinable (Just (unwrap c.id))
    }
  NodeAddChange c -> emptyNodeChange
    { type = "add"
    , item = toUndefinable (Just (nodeOut c.item))
    , index = toUndefinable (map Int.toNumber c.index)
    }
  NodeReplaceChange c -> emptyNodeChange
    { type = "replace"
    , id = toUndefinable (Just (unwrap c.id))
    , item = toUndefinable (Just (nodeOut c.item))
    }

emptyNodeChange :: JsNodeChange
emptyNodeChange =
  { type: ""
  , id: undefined
  , dimensions: undefined
  , resizing: undefined
  , setAttributes: undefined
  , position: undefined
  , positionAbsolute: undefined
  , dragging: undefined
  , selected: undefined
  , item: undefined
  , index: undefined
  }

-- | Upstream's `setAttributes` is `boolean | 'width' | 'height'`: `true` means
-- | both dimensions, the strings mean one each. PureScript models it as a pair
-- | of Booleans, so the four inhabited combinations map back onto the three
-- | upstream forms plus `false`.
setAttributesOut :: { width :: Boolean, height :: Boolean } -> Foreign
setAttributesOut m = case m.width, m.height of
  true, true -> unsafeCoerce true
  true, false -> unsafeCoerce "width"
  false, true -> unsafeCoerce "height"
  false, false -> unsafeCoerce false

setAttributesIn :: Foreign -> { width :: Boolean, height :: Boolean }
setAttributesIn raw = case asBoolean raw of
  Just b -> { width: b, height: b }
  Nothing -> case asString raw of
    Just "width" -> { width: true, height: false }
    Just "height" -> { width: false, height: true }
    _ ->
      unsafeThrow $
        "ps-flow: a dimension change's `setAttributes` must be a boolean, "
          <> "\"width\" or \"height\", got "
          <> typeName raw
          <> "."

edgeChangeIn :: JsEdgeChange -> EdgeChange Foreign
edgeChangeIn c = case c.type of
  "select" -> EdgeSelectionChange
    { id: requiredMember c.type "id" c.id
    , selected: requiredMember c.type "selected" c.selected
    }
  "remove" -> EdgeRemoveChange
    { id: requiredMember c.type "id" c.id }
  "add" -> EdgeAddChange
    { item: edgeIn (requiredMember c.type "item" c.item)
    , index: map Int.round (fromUndefinable c.index)
    }
  "replace" -> EdgeReplaceChange
    { id: requiredMember c.type "id" c.id
    , item: edgeIn (requiredMember c.type "item" c.item)
    }
  other -> unknownChange "edge" other

-- | Pruned as `nodeChangeOut` is.
edgeChangeOut :: EdgeChange Foreign -> JsEdgeChange
edgeChangeOut = pruneUndefined <<< case _ of
  EdgeSelectionChange c -> emptyEdgeChange
    { type = "select"
    , id = toUndefinable (Just c.id)
    , selected = toUndefinable (Just c.selected)
    }
  EdgeRemoveChange c -> emptyEdgeChange
    { type = "remove"
    , id = toUndefinable (Just c.id)
    }
  EdgeAddChange c -> emptyEdgeChange
    { type = "add"
    , item = toUndefinable (Just (edgeOut c.item))
    , index = toUndefinable (map Int.toNumber c.index)
    }
  EdgeReplaceChange c -> emptyEdgeChange
    { type = "replace"
    , id = toUndefinable (Just c.id)
    , item = toUndefinable (Just (edgeOut c.item))
    }

emptyEdgeChange :: JsEdgeChange
emptyEdgeChange =
  { type: ""
  , id: undefined
  , selected: undefined
  , item: undefined
  , index: undefined
  }

-- | `toMaybe` reads `undefined` as absent as well as `null`, which is what a
-- | consumer hand-writing a connection gives — upstream's own `addEdge`
-- | deletes a null handle on the way in for the same reason.
connectionIn :: JsConnection -> Connection
connectionIn c =
  { source: wrap c.source
  , target: wrap c.target
  , sourceHandle: toMaybe c.sourceHandle
  , targetHandle: toMaybe c.targetHandle
  }

connectionOut :: Connection -> JsConnection
connectionOut c =
  { source: unwrap c.source
  , target: unwrap c.target
  , sourceHandle: toNullable c.sourceHandle
  , targetHandle: toNullable c.targetHandle
  }

-- | What upstream's `onConnect` receives: `{ ...defaultEdgeOptions,
-- | ...connection }`. The connection's own four members win, as the spread
-- | writes them last. See `System.Types.Connection.withEdgeDefaults`.
-- |
-- | Typed `JsConnection` because the merged object is one, with the default
-- | options' members beside the four.
connectionParamsOut :: Connection -> JsConnection
connectionParamsOut c = case toMaybe (edgeDefaultsOf c) of
  Nothing -> connectionOut c
  Just defaults ->
    runFn2 spreadUnder
      (defaultEdgeOptionsOut (unsafeCoerce defaults :: DefaultEdgeOptions Foreign))
      (connectionOut c)

foreign import spreadUnder :: forall a b c. Fn2 a b c

-- ────────────────────────────────────────────────────────────────────────
-- The viewport, and the two-array selection bag
-- ────────────────────────────────────────────────────────────────────────

viewportIn :: JsViewport -> Viewport
viewportIn v = { x: v.x, y: v.y, zoom: v.zoom }

viewportOut :: Viewport -> JsViewport
viewportOut v = { x: v.x, y: v.y, zoom: v.zoom }

-- | Upstream hands these three callbacks the consumer's own node and edge
-- | objects, so a node or edge decoded from one crosses back as that object.
graphSelectionOut
  :: { nodes :: Array (NodeBase Foreign), edges :: Array (EdgeBase Foreign) }
  -> JsGraphSelection
graphSelectionOut s =
  { nodes: map nodeIdentityOut s.nodes
  , edges: map edgeIdentityOut s.edges
  }
