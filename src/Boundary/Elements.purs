-- | The graph data types, crossing.
-- |
-- | `Node`, `Edge`, the node props a custom component receives, the change
-- | objects `onNodesChange`/`onEdgesChange` deliver, and `Connection`. These
-- | are the shapes a JavaScript consumer both hands in and gets back, so most
-- | of them convert **both directions** — and the two directions are not
-- | symmetric in what they can get wrong.
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
-- | Seven Booleans — a node's `hidden`, `selected`, `dragging` and
-- | `expandParent`, an edge's `animated`, `hidden` and `selected` — plus a
-- | node's `measured` record. Inbound they default (`false`, and an empty
-- | measurement); outbound they are **emitted always**, so a JavaScript
-- | consumer reading a node back sees `hidden: false` where upstream would
-- | have no such key. That is a real divergence, it is recorded as a region in
-- | `parity/boundary/regions.json`, and it is deliberately not fixed here:
-- | `Maybe`-ifying eight fields of the internals is churn ahead of the first
-- | green signal on the JS surface. The stale-region rule is what forces the
-- | cleanup once the net's `props` and `dom` sections are green.
-- |
-- | Absent optional fields are emitted as the key with the value `undefined`
-- | rather than omitted. Omitting them would read closer to upstream for
-- | nodes, whose objects upstream passes through from the consumer untouched
-- | — but deleting keys by content is exactly the content-aware filtering the
-- | spec keeps out of capture, and it belongs in the net's normalization where
-- | it is visible, not buried in a converter.
module Boundary.Elements
  ( JsCoordinateExtent
  , JsEdge
  , JsEdgeMarker
  , JsMeasured
  , JsNode
  , JsNodeHandle
  , JsNodeOrigin
  , JsNodeProps
  , JsNodeChange
  , JsEdgeChange
  , JsConnection
  , JsXYPosition
  , asCssObject
  , fromCssObject
  , coordinateExtentIn
  , coordinateExtentOut
  , connectionIn
  , connectionOut
  , edgeIn
  , edgeOut
  , edgeChangeIn
  , edgeChangeOut
  , keyCodeIn
  , nodeIn
  , nodeOut
  , nodeChangeIn
  , nodeChangeOut
  , nodeOriginIn
  , nodeOriginOut
  , nodePropsOut
  , nodeTypesIn
  , snapGridIn
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
import Boundary.Undefined (Undefinable, fromUndefinable, isNull, toUndefinable, undefined)
import Boundary.Untagged (asArray, asBoolean, asString, typeName)
import Data.Array (length) as Array
import Data.Array.NonEmpty (fromArray) as NEA
import Data.Int (round, toNumber) as Int
import Data.Maybe (Maybe(..), fromMaybe, fromMaybe', maybe)
import Data.Newtype (unwrap, wrap)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Effect.Exception.Unsafe (unsafeThrow)
import Effect.Uncurried (EffectFn1, mkEffectFn1)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object (mapWithKey) as Object
import React.Basic (JSX, ReactComponent, element)
import React.Types.Nodes (NodeProps, NodeTypesMap)
import System.Types.Connection (Connection, KeyCode(..))
import System.Types.Edge (EdgeBase, EdgeChange(..), EdgeMarker, EdgeMarkerType(..))
import System.Types.Geometry (CoordinateExtent, NodeOrigin, SnapGrid)
import System.Types.Node (NodeBase, NodeChange(..), NodeExtent(..), NodeHandle)
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

-- | The 28 fields of `System.Types.Node.NodeBaseRow`, in upstream's shapes.
-- |
-- | `extent` is `Foreign` because upstream's is `'parent' | CoordinateExtent`,
-- | narrowed at conversion time. `style` is `Foreign` because upstream's is
-- | `CSSProperties`, whose values are `string | number` — PureScript models it
-- | as `Object String`, which is wrong about the numbers and right about
-- | everything PSFlow does with it, which is spread it onto a DOM node.
type JsNode =
  { id :: String
  , position :: JsXYPosition
  , data :: Foreign
  , type :: Undefinable String
  , sourcePosition :: Undefinable String
  , targetPosition :: Undefinable String
  , hidden :: Undefinable Boolean
  , selected :: Undefinable Boolean
  , dragging :: Undefinable Boolean
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

-- | The 20 fields of `System.Types.Edge.EdgeBase`. `markerStart`/`markerEnd`
-- | are `Foreign` because upstream's `EdgeMarkerType` is `string | EdgeMarker`.
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
  }

-- | What a custom node component receives. Outbound only — a consumer's
-- | component is called with this, never asked to produce one.
-- |
-- | The PureScript record already calls the tag `type`; what crosses here is
-- | the `Maybe`s and the two `Position` sum types.
type JsNodeProps =
  { id :: String
  , data :: Foreign
  , width :: Undefinable Number
  , height :: Undefinable Number
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
keyCodeIn field u = fromUndefinable u >>= \raw ->
  case asString raw of
    Just s -> Just (SingleKey s)
    Nothing -> case asArray raw of
      Just entries -> map MultiKey (NEA.fromArray (map (readKey field) entries))
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
nodeIn n =
  { id: wrap n.id
  , position: n.position
  , data: n.data
  , sourcePosition: map (positionIn "node.sourcePosition") (fromUndefinable n.sourcePosition)
  , targetPosition: map (positionIn "node.targetPosition") (fromUndefinable n.targetPosition)
  , hidden: fromMaybe false (fromUndefinable n.hidden)
  , selected: fromMaybe false (fromUndefinable n.selected)
  , dragging: fromMaybe false (fromUndefinable n.dragging)
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
  , expandParent: fromMaybe false (fromUndefinable n.expandParent)
  , ariaLabel: fromUndefinable n.ariaLabel
  , origin: map (nodeOriginIn "node.origin") (fromUndefinable n.origin)
  , handles: map (map nodeHandleIn) (fromUndefinable n.handles)
  , measured: maybe emptyMeasured measuredIn (fromUndefinable n.measured)
  , nodeType: fromUndefinable n.type
  , className: fromUndefinable n.className
  , style: map asCssObject (fromUndefinable n.style)
  }

nodeOut :: NodeBase Foreign -> JsNode
nodeOut n =
  { id: unwrap n.id
  , position: n.position
  , data: n.data
  , type: toUndefinable n.nodeType
  , sourcePosition: toUndefinable (map positionOut n.sourcePosition)
  , targetPosition: toUndefinable (map positionOut n.targetPosition)
  , hidden: toUndefinable (Just n.hidden)
  , selected: toUndefinable (Just n.selected)
  , dragging: toUndefinable (Just n.dragging)
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
  , expandParent: toUndefinable (Just n.expandParent)
  , ariaLabel: toUndefinable n.ariaLabel
  , origin: toUndefinable (map nodeOriginOut n.origin)
  , handles: toUndefinable (map (map nodeHandleOut) n.handles)
  , measured: toUndefinable (Just (measuredOut n.measured))
  , className: toUndefinable n.className
  , style: toUndefinable (map fromCssObject n.style)
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

nodeHandleIn :: JsNodeHandle -> NodeHandle
nodeHandleIn h =
  { id: fromUndefinable h.id
  , x: h.x
  , y: h.y
  , position: positionIn "node.handles[].position" h.position
  , handleType: handleTypeIn "node.handles[].type" h.type
  , width: fromUndefinable h.width
  , height: fromUndefinable h.height
  }

nodeHandleOut :: NodeHandle -> JsNodeHandle
nodeHandleOut h =
  { id: toUndefinable h.id
  , x: h.x
  , y: h.y
  , position: positionOut h.position
  , type: handleTypeOut h.handleType
  , width: toUndefinable h.width
  , height: toUndefinable h.height
  }

-- `CSSProperties` in both directions, for the `style` field a node or an edge
-- carries — and, through `Boundary.Chrome`, the one each of the four chrome
-- components carries. PureScript's `Object String` is the same runtime object;
-- the coercion is where the type stops being true about numeric CSS values.
-- `Boundary.Flow` has its own pair of these for the connection-line styles,
-- because those are typed with the opaque `React.Types.Edges.Style` instead.
asCssObject :: Foreign -> Object String
asCssObject = unsafeCoerce

fromCssObject :: Object String -> Foreign
fromCssObject = unsafeCoerce

-- ────────────────────────────────────────────────────────────────────────
-- Edge
-- ────────────────────────────────────────────────────────────────────────

edgeIn :: JsEdge -> EdgeBase Foreign
edgeIn e =
  { id: e.id
  , edgeType: fromUndefinable e.type
  , source: wrap e.source
  , target: wrap e.target
  , sourceHandle: fromUndefinable e.sourceHandle
  , targetHandle: fromUndefinable e.targetHandle
  , animated: fromMaybe false (fromUndefinable e.animated)
  , hidden: fromMaybe false (fromUndefinable e.hidden)
  , deletable: fromUndefinable e.deletable
  , selectable: fromUndefinable e.selectable
  , data: fromUndefinable e.data
  , selected: fromMaybe false (fromUndefinable e.selected)
  , markerStart: map (markerIn "edge.markerStart") (fromUndefinable e.markerStart)
  , markerEnd: map (markerIn "edge.markerEnd") (fromUndefinable e.markerEnd)
  , zIndex: map Int.round (fromUndefinable e.zIndex)
  , label: fromUndefinable e.label
  , ariaLabel: fromUndefinable e.ariaLabel
  , interactionWidth: fromUndefinable e.interactionWidth
  , className: fromUndefinable e.className
  , style: map asCssObject (fromUndefinable e.style)
  }

edgeOut :: EdgeBase Foreign -> JsEdge
edgeOut e =
  { id: e.id
  , type: toUndefinable e.edgeType
  , source: unwrap e.source
  , target: unwrap e.target
  , sourceHandle: toUndefinable e.sourceHandle
  , targetHandle: toUndefinable e.targetHandle
  , animated: toUndefinable (Just e.animated)
  , hidden: toUndefinable (Just e.hidden)
  , deletable: toUndefinable e.deletable
  , selectable: toUndefinable e.selectable
  , data: toUndefinable e.data
  , selected: toUndefinable (Just e.selected)
  , markerStart: toUndefinable (map markerOut e.markerStart)
  , markerEnd: toUndefinable (map markerOut e.markerEnd)
  , zIndex: toUndefinable (map Int.toNumber e.zIndex)
  , label: toUndefinable e.label
  , ariaLabel: toUndefinable e.ariaLabel
  , interactionWidth: toUndefinable e.interactionWidth
  , className: toUndefinable e.className
  , style: toUndefinable (map fromCssObject e.style)
  }

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

edgeMarkerOut :: EdgeMarker -> JsEdgeMarker
edgeMarkerOut m =
  { type: markerTypeOut m.markerType
  , color: toUndefinable m.color
  , width: toUndefinable m.width
  , height: toUndefinable m.height
  , markerUnits: toUndefinable m.markerUnits
  , orient: toUndefinable m.orient
  , strokeWidth: toUndefinable m.strokeWidth
  }

-- ────────────────────────────────────────────────────────────────────────
-- Node props, and the node-type map that delivers them
-- ────────────────────────────────────────────────────────────────────────

nodePropsOut :: NodeProps Foreign -> JsNodeProps
nodePropsOut p =
  { id: p.id
  , data: p.data
  , width: toUndefinable p.width
  , height: toUndefinable p.height
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
  mkNodeComponentWrapper userComponent
    (mkEffectFn1 \psProps -> pure (element userComponent (nodePropsOut psProps)))

-- | React reads `displayName` and the component's identity off the function it
-- | is handed, so the wrapper has to be a real component rather than a call to
-- | the user's one — and it takes the wrapped component along so it can keep
-- | that name rather than replacing every custom node type in the React tree
-- | with one shared boundary name. One line of FFI, because `react-basic`'s
-- | `reactComponent` is in `Effect` and this is called from the pure prop
-- | conversion.
foreign import mkNodeComponentWrapper
  :: ReactComponent JsNodeProps
  -> EffectFn1 (NodeProps Foreign) JSX
  -> ReactComponent (NodeProps Foreign)

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
    , resizing: fromMaybe false (fromUndefinable c.resizing)
    , setAttributes: map setAttributesIn (fromUndefinable c.setAttributes)
    }
  "position" -> NodePositionChange
    { id: wrap (requiredMember c.type "id" c.id)
    , position: fromUndefinable c.position
    , positionAbsolute: fromUndefinable c.positionAbsolute
    , dragging: fromMaybe false (fromUndefinable c.dragging)
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
-- | it, which is what `Undefinable` says.
nodeChangeOut :: NodeChange Foreign -> JsNodeChange
nodeChangeOut = case _ of
  NodeDimensionChange c -> emptyNodeChange
    { type = "dimensions"
    , id = toUndefinable (Just (unwrap c.id))
    , dimensions = toUndefinable c.dimensions
    , resizing = toUndefinable (Just c.resizing)
    , setAttributes = toUndefinable (map setAttributesOut c.setAttributes)
    }
  NodePositionChange c -> emptyNodeChange
    { type = "position"
    , id = toUndefinable (Just (unwrap c.id))
    , position = toUndefinable c.position
    , positionAbsolute = toUndefinable c.positionAbsolute
    , dragging = toUndefinable (Just c.dragging)
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

edgeChangeOut :: EdgeChange Foreign -> JsEdgeChange
edgeChangeOut = case _ of
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
