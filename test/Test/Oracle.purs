-- | The single XYFlow-coupled module in the test suite. Wraps the FFI in
-- | `Test.Oracle.js` (which imports the `@psflow/oracle` bundle) behind
-- | PureScript signatures that mirror the PSFlow functions under parity test,
-- | so a property can write `PS.getBezierPath p` and `Oracle.getBezierPath p`
-- | over the *same* input value.
-- |
-- | The only XYFlow-shape knowledge expressible in PureScript lives here: the
-- | `posStr` translation of the `Position` sum type into XYFlow's lowercase
-- | string, the newtype→plain-array translations (`Transform`, `SnapGrid`,
-- | `CoordinateExtent`, `NodeOrigin`), and the `Oracle*` records naming the
-- | fields upstream reads off a node, an edge or a change. These are stable;
-- | an upstream change to the math touches the bundle, not this file.
-- |
-- | Where a PSFlow type collapses onto a small XYFlow shape the wrapper takes
-- | the PSFlow type directly (`getMarkerId`, `snapPosition`). Where it does not
-- | — a `NodeBase` is thirty fields of which upstream reads seven — the wrapper
-- | takes an `Oracle*` record and the property module builds both sides from
-- | one generated description, as `Test.Parity.Graph` already does.
module Test.Oracle
  ( getEdgeCenter
  , getBezierEdgeCenter
  , getStraightPath
  , getBezierPath
  , getSimpleBezierPath
  , getSmoothStepPath
  , clamp
  , getBoundsOfBoxes
  , rectToBox
  , boxToRect
  , getBoundsOfRects
  , getOverlappingArea
  , snapPosition
  , clampPosition
  , pointToRendererPoint
  , rendererPointToPoint
  , getViewportForBounds
  , getNodeToolbarTransform
  , getEdgeToolbarTransform
  , getMarkerId
  , getConnectionStatus
  , OracleNode
  , OracleEdge
  , getOutgoers
  , getIncomers
  , getConnectedEdges
  , OracleBoundsNode
  , getNodesBounds
  , getNodePositionWithOrigin
  , nodeToRect
  , nodeToBox
  , isNode
  , isEdge
  , OracleEdgeShape
  , OracleConnection
  , OracleEdgeResult
  , addEdge
  , reconnectEdge
  , OracleChangeNode
  , OracleChangeEdge
  , OracleNodeChange
  , OracleEdgeChange
  , setAttributesArg
  , applyNodeChanges
  , applyEdgeChanges
  , areSetsEqual
  , DomStandIn
  , isInputDOMNode
  , hasSelector
  , OracleNodeHandle
  , OracleAdoptNode
  , OracleAdoptOptions
  , AdoptedHandle
  , AdoptedNode
  , Adoption
  , adoptUserNodes
  , FakeElement
  , FakeDocument
  , OracleHandleElement
  , handleElement
  , plainElement
  , fakeDocument
  , OracleIsValidArgs
  , OracleIsValidResult
  , isValidHandle
  ) where

import Data.Functor (map)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (Nullable, toMaybe, toNullable)
import Foreign (Foreign)
import System.Types.Connection (Padding(..), PaddingValue(..), Viewport)
import System.Types.Edge (AlignX(..), AlignY(..), EdgeMarkerType(..), MarkerType(..))
import System.Types.Geometry
  ( Box
  , CoordinateExtent(..)
  , Dimensions
  , NodeOrigin(..)
  , Position(..)
  , Rect
  , SnapGrid(..)
  , Transform(..)
  , XYPosition
  )
import System.Types.Node (Align(..), SetAttributesMode)
import System.Utils.Edges.Bezier (BezierControlPoints, BezierPathParams)
import System.Utils.Edges.General (EdgeCenter, EdgePathResult)
import System.Utils.Edges.SimpleBezier (SimpleBezierPathParams)
import System.Utils.Edges.SmoothStep (SmoothStepPathParams)
import System.Utils.Edges.Straight (StraightPathParams)

-- | `Position` → XYFlow's lowercase string. The only XYFlow enum knowledge in
-- | PureScript; matches `enum Position { Left = 'left', … }` upstream.
posStr :: Position -> String
posStr = case _ of
  PosLeft -> "left"
  PosTop -> "top"
  PosRight -> "right"
  PosBottom -> "bottom"

-- | `Align` → XYFlow's `'start' | 'center' | 'end'`.
alignStr :: Align -> String
alignStr = case _ of
  AlignStart -> "start"
  AlignCenter -> "center"
  AlignEnd -> "end"

-- | `AlignX` → XYFlow's `'left' | 'center' | 'right'`.
alignXStr :: AlignX -> String
alignXStr = case _ of
  AlignXLeft -> "left"
  AlignXCenter -> "center"
  AlignXRight -> "right"

-- | `AlignY` → XYFlow's `'top' | 'center' | 'bottom'`.
alignYStr :: AlignY -> String
alignYStr = case _ of
  AlignYTop -> "top"
  AlignYCenter -> "center"
  AlignYBottom -> "bottom"

-- | `MarkerType` → XYFlow's `'arrow' | 'arrowclosed'` (the `type` field of a
-- | custom `EdgeMarker`).
markerTypeStr :: MarkerType -> String
markerTypeStr = case _ of
  Arrow -> "arrow"
  ArrowClosed -> "arrowclosed"

-- ─── Edge centers ─────────────────────────────────────────────────────────

type EdgeCenterArgs =
  { sourceX :: Number, sourceY :: Number, targetX :: Number, targetY :: Number }

foreign import getEdgeCenterImpl :: EdgeCenterArgs -> EdgeCenter

getEdgeCenter :: EdgeCenterArgs -> EdgeCenter
getEdgeCenter = getEdgeCenterImpl

foreign import getBezierEdgeCenterImpl :: BezierControlPoints -> EdgeCenter

getBezierEdgeCenter :: BezierControlPoints -> EdgeCenter
getBezierEdgeCenter = getBezierEdgeCenterImpl

-- ─── Edge paths ───────────────────────────────────────────────────────────

foreign import getStraightPathImpl :: StraightPathParams -> EdgePathResult

getStraightPath :: StraightPathParams -> EdgePathResult
getStraightPath = getStraightPathImpl

type BezierArgs =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: String
  , curvature :: Number
  }

foreign import getBezierPathImpl :: BezierArgs -> EdgePathResult

getBezierPath :: BezierPathParams -> EdgePathResult
getBezierPath p = getBezierPathImpl
  { sourceX: p.sourceX
  , sourceY: p.sourceY
  , sourcePosition: posStr p.sourcePosition
  , targetX: p.targetX
  , targetY: p.targetY
  , targetPosition: posStr p.targetPosition
  , curvature: p.curvature
  }

type SimpleBezierArgs =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: String
  }

foreign import getSimpleBezierPathImpl :: SimpleBezierArgs -> EdgePathResult

getSimpleBezierPath :: SimpleBezierPathParams -> EdgePathResult
getSimpleBezierPath p = getSimpleBezierPathImpl
  { sourceX: p.sourceX
  , sourceY: p.sourceY
  , sourcePosition: posStr p.sourcePosition
  , targetX: p.targetX
  , targetY: p.targetY
  , targetPosition: posStr p.targetPosition
  }

type SmoothStepArgs =
  { sourceX :: Number
  , sourceY :: Number
  , sourcePosition :: String
  , targetX :: Number
  , targetY :: Number
  , targetPosition :: String
  , borderRadius :: Number
  , centerX :: Nullable Number
  , centerY :: Nullable Number
  , offset :: Number
  , stepPosition :: Number
  }

foreign import getSmoothStepPathImpl :: SmoothStepArgs -> EdgePathResult

getSmoothStepPath :: SmoothStepPathParams -> EdgePathResult
getSmoothStepPath p = getSmoothStepPathImpl
  { sourceX: p.sourceX
  , sourceY: p.sourceY
  , sourcePosition: posStr p.sourcePosition
  , targetX: p.targetX
  , targetY: p.targetY
  , targetPosition: posStr p.targetPosition
  , borderRadius: p.borderRadius
  , centerX: toNullable p.centerX
  , centerY: toNullable p.centerY
  , offset: p.offset
  , stepPosition: p.stepPosition
  }

-- ─── Geometry ─────────────────────────────────────────────────────────────

foreign import clampImpl :: Number -> Number -> Number -> Number

clamp :: Number -> Number -> Number -> Number
clamp = clampImpl

foreign import getBoundsOfBoxesImpl :: Box -> Box -> Box

getBoundsOfBoxes :: Box -> Box -> Box
getBoundsOfBoxes = getBoundsOfBoxesImpl

foreign import rectToBoxImpl :: Rect -> Box

rectToBox :: Rect -> Box
rectToBox = rectToBoxImpl

foreign import boxToRectImpl :: Box -> Rect

boxToRect :: Box -> Rect
boxToRect = boxToRectImpl

foreign import getBoundsOfRectsImpl :: Rect -> Rect -> Rect

getBoundsOfRects :: Rect -> Rect -> Rect
getBoundsOfRects = getBoundsOfRectsImpl

foreign import getOverlappingAreaImpl :: Rect -> Rect -> Number

getOverlappingArea :: Rect -> Rect -> Number
getOverlappingArea = getOverlappingAreaImpl

foreign import snapPositionImpl :: XYPosition -> Array Number -> XYPosition

snapPosition :: XYPosition -> SnapGrid -> XYPosition
snapPosition pos (SnapGrid g) = snapPositionImpl pos [ g.gx, g.gy ]

type DimsArg = { width :: Nullable Number, height :: Nullable Number }

foreign import clampPositionImpl
  :: XYPosition -> Array (Array Number) -> DimsArg -> XYPosition

clampPosition
  :: XYPosition
  -> CoordinateExtent
  -> { width :: Maybe Number, height :: Maybe Number }
  -> XYPosition
clampPosition pos (CoordinateExtent e) dims = clampPositionImpl pos
  [ [ e.minX, e.minY ], [ e.maxX, e.maxY ] ]
  { width: toNullable dims.width, height: toNullable dims.height }

foreign import pointToRendererPointImpl
  :: XYPosition -> Array Number -> Boolean -> Array Number -> XYPosition

pointToRendererPoint :: XYPosition -> Transform -> Maybe SnapGrid -> XYPosition
pointToRendererPoint p (Transform t) mGrid = case mGrid of
  Nothing -> pointToRendererPointImpl p [ t.tx, t.ty, t.scale ] false [ 1.0, 1.0 ]
  Just (SnapGrid g) ->
    pointToRendererPointImpl p [ t.tx, t.ty, t.scale ] true [ g.gx, g.gy ]

foreign import rendererPointToPointImpl :: XYPosition -> Array Number -> XYPosition

rendererPointToPoint :: XYPosition -> Transform -> XYPosition
rendererPointToPoint p (Transform t) = rendererPointToPointImpl p [ t.tx, t.ty, t.scale ]

-- ─── fitView viewport ─────────────────────────────────────────────────────

-- | Upstream's `PaddingWithUnit` (`number | \`${number}px\` | \`${number}%\``)
-- | and `Padding` (a `PaddingWithUnit` or a per-side record), opaque here
-- | because neither is expressible as a PureScript type. The third piece of
-- | XYFlow-shape knowledge in this module, alongside `posStr` and the
-- | newtype→array translations.
foreign import data JsPaddingValue :: Type
foreign import data JsPadding :: Type

foreign import paddingValueImpl :: String -> Number -> JsPaddingValue
foreign import uniformPaddingImpl :: JsPaddingValue -> JsPadding

type DirectionalArg =
  { top :: Nullable JsPaddingValue
  , right :: Nullable JsPaddingValue
  , bottom :: Nullable JsPaddingValue
  , left :: Nullable JsPaddingValue
  , x :: Nullable JsPaddingValue
  , y :: Nullable JsPaddingValue
  }

foreign import directionalPaddingImpl :: DirectionalArg -> JsPadding

-- | `PaddingValue` → `PaddingWithUnit`. The *bare number* form is upstream's
-- | ratio padding (`(viewport - viewport / (1 + p)) * 0.5`); `px` and `%` are
-- | strings it re-parses with `parseFloat`, so the empty unit means "leave it
-- | a number".
paddingValue :: PaddingValue -> JsPaddingValue
paddingValue = case _ of
  RatioPadding r -> paddingValueImpl "" r
  PxPadding px -> paddingValueImpl "px" px
  PctPadding pct -> paddingValueImpl "%" pct

padding :: Padding -> JsPadding
padding = case _ of
  UniformPadding pv -> uniformPaddingImpl (paddingValue pv)
  DirectionalPadding d -> directionalPaddingImpl
    { top: toNullable (map paddingValue d.top)
    , right: toNullable (map paddingValue d.right)
    , bottom: toNullable (map paddingValue d.bottom)
    , left: toNullable (map paddingValue d.left)
    , x: toNullable (map paddingValue d.x)
    , y: toNullable (map paddingValue d.y)
    }

foreign import getViewportForBoundsImpl
  :: Rect -> Number -> Number -> Number -> Number -> JsPadding -> Viewport

getViewportForBounds
  :: Rect -> Number -> Number -> Number -> Number -> Padding -> Viewport
getViewportForBounds bounds width height minZoom maxZoom p =
  getViewportForBoundsImpl bounds width height minZoom maxZoom (padding p)

-- ─── Toolbar transforms ───────────────────────────────────────────────────

foreign import getNodeToolbarTransformImpl
  :: Rect -> Viewport -> String -> Number -> String -> String

getNodeToolbarTransform :: Rect -> Viewport -> Position -> Number -> Align -> String
getNodeToolbarTransform rect viewport position offset align =
  getNodeToolbarTransformImpl rect viewport (posStr position) offset (alignStr align)

foreign import getEdgeToolbarTransformImpl
  :: Number -> Number -> Number -> String -> String -> String

getEdgeToolbarTransform :: Number -> Number -> Number -> AlignX -> AlignY -> String
getEdgeToolbarTransform x y zoom alignX alignY =
  getEdgeToolbarTransformImpl x y zoom (alignXStr alignX) (alignYStr alignY)

-- ─── Markers ──────────────────────────────────────────────────────────────

-- | Tagged carrier for an `EdgeMarkerType`. The JS side reconstructs upstream's
-- | `EdgeMarkerType` (a bare string for a named marker, or an `EdgeMarker`
-- | object with absent `Nothing` fields omitted so `Object.keys` matches).
type MarkerArg =
  { tag :: String
  , named :: Nullable String
  , markerType :: Nullable String
  , color :: Nullable String
  , width :: Nullable Number
  , height :: Nullable Number
  , markerUnits :: Nullable String
  , orient :: Nullable String
  , strokeWidth :: Nullable Number
  }

encMarker :: EdgeMarkerType -> MarkerArg
encMarker = case _ of
  NamedMarker s ->
    { tag: "named"
    , named: toNullable (Just s)
    , markerType: toNullable (Nothing :: Maybe String)
    , color: toNullable (Nothing :: Maybe String)
    , width: toNullable (Nothing :: Maybe Number)
    , height: toNullable (Nothing :: Maybe Number)
    , markerUnits: toNullable (Nothing :: Maybe String)
    , orient: toNullable (Nothing :: Maybe String)
    , strokeWidth: toNullable (Nothing :: Maybe Number)
    }
  CustomMarker em ->
    { tag: "custom"
    , named: toNullable (Nothing :: Maybe String)
    , markerType: toNullable (Just (markerTypeStr em.markerType))
    , color: toNullable em.color
    , width: toNullable em.width
    , height: toNullable em.height
    , markerUnits: toNullable em.markerUnits
    , orient: toNullable em.orient
    , strokeWidth: toNullable em.strokeWidth
    }

foreign import getMarkerIdImpl :: Nullable MarkerArg -> Nullable String -> String

getMarkerId :: Maybe EdgeMarkerType -> Maybe String -> String
getMarkerId marker mid =
  getMarkerIdImpl (toNullable (map encMarker marker)) (toNullable mid)

-- ─── Connections ──────────────────────────────────────────────────────────

foreign import getConnectionStatusImpl :: Nullable Boolean -> Nullable String

-- | XYFlow returns `'valid' | 'invalid' | null`; we surface `null` as `""` so
-- | the property can compare against PSFlow's `Maybe ConnectionStatus` mapped
-- | through the same projection.
getConnectionStatus :: Maybe Boolean -> String
getConnectionStatus mb =
  fromMaybe "" (toMaybe (getConnectionStatusImpl (toNullable mb)))

-- ─── Graph traversal ──────────────────────────────────────────────────────
-- These read only string ids, so the oracle takes minimal shapes and the
-- impls return just the matched ids (the parity property compares id sets).

type OracleNode = { id :: String }
type OracleEdge = { id :: String, source :: String, target :: String }

foreign import getOutgoersImpl
  :: OracleNode -> Array OracleNode -> Array OracleEdge -> Array String

getOutgoers :: OracleNode -> Array OracleNode -> Array OracleEdge -> Array String
getOutgoers = getOutgoersImpl

foreign import getIncomersImpl
  :: OracleNode -> Array OracleNode -> Array OracleEdge -> Array String

getIncomers :: OracleNode -> Array OracleNode -> Array OracleEdge -> Array String
getIncomers = getIncomersImpl

foreign import getConnectedEdgesImpl
  :: Array OracleNode -> Array OracleEdge -> Array String

getConnectedEdges :: Array OracleNode -> Array OracleEdge -> Array String
getConnectedEdges = getConnectedEdgesImpl

-- ─── Node bounds ──────────────────────────────────────────────────────────

-- | Upstream's `NodeBase` as far as `getNodesBounds` reads it: a position, the
-- | three-deep dimension fallback (`measured` → `width`/`height` →
-- | `initialWidth`/`initialHeight`), and a per-node origin override. Every
-- | optional field is `Nullable` because upstream reads all of them with `??`.
type OracleBoundsNode =
  { id :: String
  , position :: XYPosition
  , width :: Nullable Number
  , height :: Nullable Number
  , initialWidth :: Nullable Number
  , initialHeight :: Nullable Number
  , measured :: { width :: Nullable Number, height :: Nullable Number }
  , origin :: Nullable (Array Number)
  }

foreign import getNodesBoundsImpl :: Array OracleBoundsNode -> Array Number -> Rect

getNodesBounds :: Array OracleBoundsNode -> NodeOrigin -> Rect
getNodesBounds nodes (NodeOrigin o) = getNodesBoundsImpl nodes [ o.ox, o.oy ]

foreign import getNodePositionWithOriginImpl :: OracleBoundsNode -> Array Number -> XYPosition
foreign import nodeToRectImpl :: OracleBoundsNode -> Array Number -> Rect
foreign import nodeToBoxImpl :: OracleBoundsNode -> Array Number -> Box

getNodePositionWithOrigin :: OracleBoundsNode -> NodeOrigin -> XYPosition
getNodePositionWithOrigin node (NodeOrigin o) = getNodePositionWithOriginImpl node [ o.ox, o.oy ]

nodeToRect :: OracleBoundsNode -> NodeOrigin -> Rect
nodeToRect node (NodeOrigin o) = nodeToRectImpl node [ o.ox, o.oy ]

nodeToBox :: OracleBoundsNode -> NodeOrigin -> Box
nodeToBox node (NodeOrigin o) = nodeToBoxImpl node [ o.ox, o.oy ]

-- ─── Shape guards ─────────────────────────────────────────────────────────

-- | `isNode` / `isEdge` read own-property *names*, so the argument is the one
-- | thing in this module that carries no PSFlow type: whatever the property
-- | built, handed to both sides unchanged.
foreign import isNodeImpl :: Foreign -> Boolean

isNode :: Foreign -> Boolean
isNode = isNodeImpl

foreign import isEdgeImpl :: Foreign -> Boolean

isEdge :: Foreign -> Boolean
isEdge = isEdgeImpl

-- ─── Edge list mutation ───────────────────────────────────────────────────

-- | Upstream's `EdgeBase` as far as `addEdge` / `reconnectEdge` read it, plus
-- | `animated` — a field neither function touches, carried so a rebuild that
-- | dropped the rest of the edge would show up in the comparison.
type OracleEdgeShape =
  { id :: String
  , source :: String
  , target :: String
  , sourceHandle :: Nullable String
  , targetHandle :: Nullable String
  , animated :: Boolean
  }

type OracleConnection =
  { source :: String
  , target :: String
  , sourceHandle :: Nullable String
  , targetHandle :: Nullable String
  }

-- | `errored` is upstream's `onError` callback turned into a value. PSFlow
-- | reports the same refusals as `Left`, so the property can compare the two
-- | channels as well as the returned arrays.
type OracleEdgeResult = { edges :: Array OracleEdgeShape, errored :: Boolean }

foreign import addEdgeImpl
  :: OracleEdgeShape -> Array OracleEdgeShape -> OracleEdgeResult

addEdge :: OracleEdgeShape -> Array OracleEdgeShape -> OracleEdgeResult
addEdge = addEdgeImpl

foreign import reconnectEdgeImpl
  :: OracleEdgeShape
  -> OracleConnection
  -> Array OracleEdgeShape
  -> Boolean
  -> OracleEdgeResult

reconnectEdge
  :: OracleEdgeShape
  -> OracleConnection
  -> Array OracleEdgeShape
  -> Boolean
  -> OracleEdgeResult
reconnectEdge = reconnectEdgeImpl

-- ─── Changes ──────────────────────────────────────────────────────────────

-- | The node fields `applyChange` writes, plus the id it dispatches on.
-- | `resizing` is absent: upstream's dimensions branch sets it and PSFlow's
-- | does not, because `NodeBase` has no such field — so it is unobserved here
-- | rather than compared and passing.
type OracleChangeNode =
  { id :: String
  , position :: XYPosition
  , selected :: Boolean
  , dragging :: Nullable Boolean
  , width :: Nullable Number
  , height :: Nullable Number
  , measured :: { width :: Nullable Number, height :: Nullable Number }
  }

type OracleChangeEdge = { id :: String, selected :: Boolean, animated :: Boolean }

-- | Tagged carrier for a `NodeChange`. `tag` names upstream's `type`
-- | discriminant, which PSFlow spends a constructor on instead.
-- |
-- | `resizing` is total because PSFlow models it that way; the `Nullable`
-- | fields are the ones upstream itself guards with `typeof … !== 'undefined'`,
-- | and the JS side omits them rather than passing null.
-- | `setAttributes` carries upstream's `boolean | 'width' | 'height'` as one of
-- | `"true" | "false" | "width" | "height"` — see `setAttributesArg`.
type OracleNodeChange =
  { tag :: String
  , id :: String
  , selected :: Boolean
  , position :: Nullable XYPosition
  , dragging :: Nullable Boolean
  , dimensions :: Nullable Dimensions
  , setAttributes :: Nullable String
  , resizing :: Nullable Boolean
  , item :: Nullable OracleChangeNode
  , index :: Nullable Int
  }

type OracleEdgeChange =
  { tag :: String
  , id :: String
  , selected :: Boolean
  , item :: Nullable OracleChangeEdge
  , index :: Nullable Int
  }

-- | `SetAttributesMode` → upstream's `boolean | 'width' | 'height'`, as the
-- | string tag the JS side turns back into the union. PSFlow's fourth case —
-- | both axes off — is upstream's plain `false`, which its `if
-- | (change.setAttributes)` guard treats exactly like an absent field.
setAttributesArg :: SetAttributesMode -> Nullable String
setAttributesArg mode = toNullable
  ( map
      ( \sa -> case sa.width, sa.height of
          true, true -> "true"
          true, false -> "width"
          false, true -> "height"
          false, false -> "false"
      )
      mode
  )

foreign import applyNodeChangesImpl
  :: Array OracleNodeChange -> Array OracleChangeNode -> Array OracleChangeNode

applyNodeChanges
  :: Array OracleNodeChange -> Array OracleChangeNode -> Array OracleChangeNode
applyNodeChanges = applyNodeChangesImpl

foreign import applyEdgeChangesImpl
  :: Array OracleEdgeChange -> Array OracleChangeEdge -> Array OracleChangeEdge

applyEdgeChanges
  :: Array OracleEdgeChange -> Array OracleChangeEdge -> Array OracleChangeEdge
applyEdgeChanges = applyEdgeChangesImpl

-- ─── Set equality ─────────────────────────────────────────────────────────

foreign import areSetsEqualImpl :: Array String -> Array String -> Boolean

-- | Upstream's `areSetsEqual`, over two sets built from the arrays.
areSetsEqual :: Array String -> Array String -> Boolean
areSetsEqual = areSetsEqualImpl

-- ─── DOM predicates ───────────────────────────────────────────────────────

-- | A stand-in for a DOM event, element, document or window, built in
-- | JavaScript by the property's own FFI and handed to both sides.
foreign import data DomStandIn :: Type

foreign import isInputDOMNodeImpl :: DomStandIn -> String

-- | Upstream's `isInputDOMNode`, as `"true"`, `"false"` or `"throws"`.
isInputDOMNode :: DomStandIn -> String
isInputDOMNode = isInputDOMNodeImpl

foreign import hasSelectorImpl :: DomStandIn -> String -> DomStandIn -> String

-- | Upstream's `hasSelector`, as `"true"`, `"false"` or `"throws"`.
hasSelector :: DomStandIn -> String -> DomStandIn -> String
hasSelector = hasSelectorImpl

-- ─── Adoption ─────────────────────────────────────────────────────────────

-- | A static handle a user node declares, in the members upstream's
-- | `parseHandles` reads. `id` is a tag — `"unset"`, `"null"` or
-- | `"set:<id>"` — because upstream tells an absent id from a `null` one.
type OracleNodeHandle =
  { id :: String
  , type :: String
  , position :: String
  , x :: Number
  , y :: Number
  , width :: Nullable Number
  , height :: Nullable Number
  }

-- | A user node in the members `adoptUserNodes` reads. The JS side omits each
-- | null member, so upstream sees it absent, as PSFlow's `Nothing` is, and
-- | builds one node per record, so handing back a record from an earlier
-- | round hands upstream the same object.
type OracleAdoptNode =
  { id :: String
  , position :: XYPosition
  , parentId :: Nullable String
  , zIndex :: Nullable Int
  , selected :: Nullable Boolean
  , hidden :: Nullable Boolean
  , extentParent :: Boolean
  , measured :: Nullable Dimensions
  , handles :: Nullable (Array OracleNodeHandle)
  }

-- | `zIndexMode` is upstream's `'basic' | 'auto' | 'manual'`.
type OracleAdoptOptions =
  { nodeOrigin :: Array Number
  , elevateNodesOnSelect :: Boolean
  , zIndexMode :: String
  }

-- | A handle as adoption leaves it in `internals.handleBounds`.
type AdoptedHandle =
  { id :: String
  , nodeId :: String
  , type :: String
  , position :: String
  , x :: Number
  , y :: Number
  , width :: Number
  , height :: Number
  }

-- | What adoption leaves in one internal node, in the members a reader of
-- | `nodeLookup` reads.
type AdoptedNode =
  { id :: String
  , x :: Number
  , y :: Number
  , z :: Number
  , rootParentIndex :: Nullable Int
  , handleBounds ::
      Nullable
        { source :: Nullable (Array AdoptedHandle)
        , target :: Nullable (Array AdoptedHandle)
        }
  }

-- | One round's result: the internal nodes and parent lookup, each sorted by
-- | id, and what `adoptUserNodes` returned.
type Adoption =
  { nodes :: Array AdoptedNode
  , parents :: Array { parentId :: String, children :: Array String }
  , nodesInitialized :: Boolean
  , hasSelectedNodes :: Boolean
  }

foreign import adoptUserNodesImpl
  :: OracleAdoptOptions -> Array (Array OracleAdoptNode) -> Array Adoption

-- | Adopt each round in turn into the same two lookups, as the store adopts
-- | every `setNodes`, and report what each round left.
adoptUserNodes :: OracleAdoptOptions -> Array (Array OracleAdoptNode) -> Array Adoption
adoptUserNodes = adoptUserNodesImpl

-- ─── Handle validation ────────────────────────────────────────────────────

-- | A stand-in element and document, built here and handed to both sides.
foreign import data FakeElement :: Type
foreign import data FakeDocument :: Type

-- | A handle element as upstream's `<Handle />` renders it. `handleId` is
-- | its `data-handleid`: `id || null`, so an empty id renders as none.
type OracleHandleElement =
  { tag :: String
  , nodeId :: String
  , handleId :: Nullable String
  , type :: String
  , connectable :: Boolean
  , connectableEnd :: Boolean
  }

foreign import handleElementImpl :: String -> String -> OracleHandleElement -> FakeElement

handleElement :: String -> String -> OracleHandleElement -> FakeElement
handleElement = handleElementImpl

foreign import plainElementImpl :: String -> FakeElement

-- | An element that is no handle.
plainElement :: String -> FakeElement
plainElement = plainElementImpl

foreign import fakeDocumentImpl :: Array FakeElement -> Nullable FakeElement -> FakeDocument

-- | A document whose `querySelector` finds the handle element with that
-- | selector, and whose `elementFromPoint` answers with `below`.
fakeDocument :: Array FakeElement -> Maybe FakeElement -> FakeDocument
fakeDocument elements below = fakeDocumentImpl elements (toNullable below)

-- | `isValidConnection` accepts a connection whose target is one of
-- | `validTargets`. `handle` is the closest handle, by the tag convention
-- | `OracleNodeHandle` uses for its id.
type OracleIsValidArgs =
  { handle :: Nullable { nodeId :: String, id :: String, type :: String }
  , pointer :: XYPosition
  , connectionMode :: String
  , fromNodeId :: String
  , fromHandleId :: Nullable String
  , fromType :: String
  , validTargets :: Array String
  , doc :: FakeDocument
  , lib :: String
  , flowId :: String
  }

-- | `handleDomNode` is the tag of the element the check settled on.
type OracleIsValidResult =
  { handleDomNode :: Nullable String
  , isValid :: Boolean
  , connection ::
      Nullable
        { source :: String
        , sourceHandle :: Nullable String
        , target :: String
        , targetHandle :: Nullable String
        }
  , toHandle :: Nullable AdoptedHandle
  }

foreign import isValidHandleImpl
  :: Array OracleAdoptNode -> OracleIsValidArgs -> OracleIsValidResult

-- | `XYHandle.isValid` over the internal nodes one adoption of the nodes
-- | leaves.
isValidHandle :: Array OracleAdoptNode -> OracleIsValidArgs -> OracleIsValidResult
isValidHandle = isValidHandleImpl
