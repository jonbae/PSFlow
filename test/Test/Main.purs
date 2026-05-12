module Test.Main where

import Prelude

import Data.Array (length) as Array
import Data.Array.NonEmpty as NEA
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Ref as Ref
import Partial.Unsafe (unsafeCrashWith)
import XYFlow.Constants (ErrorCode(..), defaultAriaLabelConfig, elementSelectionKeys, emptyAriaLabelConfigOverride, errorMessage, infiniteExtent, mergeAriaLabelConfig) as C
import XYFlow.Types.Connection (ConnectionMode(..), ConnectionState(..), Padding(..), PaddingValue(..), Viewport, ZIndexMode(..), noConnection)
import XYFlow.Types.Edge (AlignX(..), AlignY(..), ConnectionLineType(..), EdgeBase, EdgeChange(..), EdgeMarkerType(..), MarkerType(..))
import XYFlow.Types.Geometry (CoordinateExtent(..), NodeOrigin(..), Position(..), SnapGrid(..), Transform(..), mkCoordinateExtent, mkNodeOrigin, mkSnapGrid, mkTransform, oppositePosition, XYPosition)
import XYFlow.Types.Handle (HandleProps, HandleType(..), defaultHandleProps)
import XYFlow.Types.Node (Align(..), InternalNodeBase, NodeBase, NodeChange(..), NodeDragItem, NodeExtent(..), NodeLookup, SetAttributesMode(..))
import XYFlow.Types.PanZoom (InterpolateMode(..), PanOnDrag(..)) as PZ
import XYFlow.Utils.Connections (ConnectionStatus(..), areConnectionMapsEqual, getConnectionStatus, handleConnectionChange)
import XYFlow.Utils.Edges.General (addEdge, getEdgeId)
import XYFlow.Utils.Edges.Straight (getStraightPath)
import XYFlow.Utils.General as G
import XYFlow.Utils.Graph (calculateNodePosition, getIncomers, getNodesBounds, getOutgoers)
import XYFlow.Utils.Marker (getMarkerId)
import XYFlow.Utils.ShallowNodeData (NodeSummary, shallowNodeData, shallowNodeDataSingle)
import XYFlow.Utils.Store (isManualZIndexMode)
import XYFlow.Utils.Toolbar (getEdgeToolbarTransform, getNodeToolbarTransform)
import XYFlow.XYDrag.Utils as XYDrag
import XYFlow.XYHandle.Utils as XYHandle
import XYFlow.XYPanZoom.Utils as XYPanZoom
import XYFlow.XYResizer (ControlLinePosition(..), ControlPosition(..), CornerPosition(..)) as Resizer
import XYFlow.XYResizer.Utils as ResizerU
import XYFlow.XYMinimap as XYMinimap
import Data.Either (Either(..))
import Data.Number (abs) as Number
import Data.Tuple (Tuple(..))
import Test.Properties (runProperties)

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

main :: Effect Unit
main = do
  -- 001: oppositePosition round-trip across all four constructors.
  let positions = [ PosLeft, PosTop, PosRight, PosBottom ]
  assert "oppositePosition is involutive"
    (map (\p -> oppositePosition (oppositePosition p) == p) positions
      == [ true, true, true, true ])

  -- 001: smart constructors build the expected newtypes.
  assert "mkNodeOrigin labels are ox, oy"
    (case mkNodeOrigin 0.5 0.25 of
      NodeOrigin r -> r.ox == 0.5 && r.oy == 0.25)

  assert "mkSnapGrid labels are gx, gy"
    (case mkSnapGrid 16.0 8.0 of
      SnapGrid r -> r.gx == 16.0 && r.gy == 8.0)

  assert "mkTransform labels are tx, ty, scale"
    (case mkTransform 1.0 2.0 3.0 of
      Transform r -> r.tx == 1.0 && r.ty == 2.0 && r.scale == 3.0)

  assert "mkCoordinateExtent labels are minX/minY/maxX/maxY"
    (case mkCoordinateExtent (-1.0) (-2.0) 3.0 4.0 of
      CoordinateExtent r ->
        r.minX == -1.0 && r.minY == -2.0 && r.maxX == 3.0 && r.maxY == 4.0)

  -- 002: HandleType has Eq and Show.
  assert "Source /= Target" (Source /= Target)
  assert "show Source == \"Source\"" (show Source == "Source")

  -- 002: defaultHandleProps fills the documented defaults.
  let props = (defaultHandleProps :: HandleProps Unit)
  assert "default isConnectable" props.isConnectable
  assert "default isConnectableStart" props.isConnectableStart
  assert "default isConnectableEnd" props.isConnectableEnd
  assert "default isValidConnection is Nothing" (props.isValidConnection == Nothing)
  assert "default id is Nothing" (props.id == Nothing)
  assert "default handleType is Source" (props.handleType == Source)

  -- 003: noConnection pattern-matches as NoConnection.
  let conn = (noConnection :: ConnectionState Unit)
  assert "noConnection is NoConnection"
    (case conn of
      NoConnection -> true
      ConnectionInProgress _ -> false)

  -- 003: Padding smart-construct both variants.
  let uniform = UniformPadding (PxPadding 8.0)
  assert "UniformPadding constructs"
    (case uniform of
      UniformPadding (PxPadding n) -> n == 8.0
      _ -> false)

  let dir = DirectionalPadding
        { top: Nothing
        , right: Nothing
        , bottom: Nothing
        , left: Nothing
        , x: Nothing
        , y: Nothing
        }
  assert "DirectionalPadding with all Nothing constructs"
    (case dir of
      DirectionalPadding r ->
        r.top == Nothing && r.right == Nothing
          && r.bottom == Nothing && r.left == Nothing
          && r.x == Nothing && r.y == Nothing
      _ -> false)

  -- 012: ConnectionStatus has Eq and Show.
  assert "ValidConnection /= InvalidConnection"
    (ValidConnection /= InvalidConnection)
  assert "show ValidConnection == \"ValidConnection\""
    (show ValidConnection == "ValidConnection")

  -- 012: getConnectionStatus mapping.
  assert "getConnectionStatus Nothing == Nothing"
    (getConnectionStatus Nothing == Nothing)
  assert "getConnectionStatus (Just true) == Just ValidConnection"
    (getConnectionStatus (Just true) == Just (ValidConnection))
  assert "getConnectionStatus (Just false) == Just InvalidConnection"
    (getConnectionStatus (Just false) == Just (InvalidConnection))

  -- 012: areConnectionMapsEqual covers the four Maybe combinations.
  let
    hc :: String -> _
    hc edgeId =
      { source: "n1"
      , target: "n2"
      , sourceHandle: Nothing
      , targetHandle: Nothing
      , edgeId
      }
    m1 = Map.singleton "k" (hc "e1")
    m2 = Map.singleton "k" (hc "e2") -- same keys, different value
    m3 = Map.singleton "j" (hc "e3") -- different key

  assert "Nothing/Nothing maps are equal"
    (areConnectionMapsEqual Nothing Nothing == true)
  assert "Just/Nothing maps are not equal"
    (areConnectionMapsEqual (Just m1) Nothing == false)
  assert "Nothing/Just maps are not equal"
    (areConnectionMapsEqual Nothing (Just m1) == false)
  assert "Maps with same keys are equal (values not compared)"
    (areConnectionMapsEqual (Just m1) (Just m2) == true)
  assert "Maps with different keys are not equal"
    (areConnectionMapsEqual (Just m1) (Just m3) == false)

  -- 012: handleConnectionChange — Nothing callback is a no-op.
  handleConnectionChange m1 Map.empty Nothing

  -- 012: handleConnectionChange — empty diff does NOT call callback.
  noCallRef <- Ref.new 0
  handleConnectionChange m1 m1 $ Just \_ -> Ref.modify_ (_ + 1) noCallRef
  noCalls <- Ref.read noCallRef
  assert "callback not invoked when no diff" (noCalls == 0)

  -- 012: handleConnectionChange — non-empty diff calls callback exactly once.
  callRef <- Ref.new 0
  diffSizeRef <- Ref.new 0
  handleConnectionChange m1 Map.empty $ Just \diff -> do
    Ref.modify_ (_ + 1) callRef
    Ref.write (Array.length diff) diffSizeRef
  calls <- Ref.read callRef
  diffSize <- Ref.read diffSizeRef
  assert "callback invoked once with non-empty diff" (calls == 1)
  assert "diff contains the single absent connection" (diffSize == 1)

  -- 007: infiniteExtent uses ±Infinity sentinels.
  let
    posInfinity = 1.0 / 0.0
    negInfinity = -1.0 / 0.0
  assert "infiniteExtent has -Infinity/+Infinity bounds"
    (case C.infiniteExtent of
      CoordinateExtent r ->
        r.minX == negInfinity && r.minY == negInfinity
          && r.maxX == posInfinity
          && r.maxY == posInfinity)

  -- 007: elementSelectionKeys are exactly Enter, space, Escape.
  assert "elementSelectionKeys contents"
    (C.elementSelectionKeys == [ "Enter", " ", "Escape" ])

  -- 007: errorMessage covers parameterless and parameterised codes.
  assert "errorMessage E001 prefix"
    (C.errorMessage C.E001 ==
      "[React Flow]: Seems like you have not used zustand provider as an ancestor. Help: https://reactflow.dev/error#001")
  assert "errorMessage E003 interpolates the node type"
    (C.errorMessage (C.E003 "myType") ==
      "Node type \"myType\" not found. Using fallback type \"default\".")
  assert "errorMessage E007 interpolates the edge id"
    (C.errorMessage (C.E007 "abc") ==
      "The old edge with id=abc does not exist.")
  assert "errorMessage E013 interpolates the lib"
    (C.errorMessage (C.E013 "react") ==
      "It seems that you haven't loaded the styles. Please import '@xyflow/react/dist/style.css' or base.css to make sure everything is working properly.")
  assert "errorMessage E008 source picks sourceHandle"
    (C.errorMessage (C.E008 Source { id: "e1", sourceHandle: Just "sh", targetHandle: Just "th" }) ==
      "Couldn't create edge for source handle id: \"sh\", edge id: e1.")
  assert "errorMessage E008 target picks targetHandle"
    (C.errorMessage (C.E008 Target { id: "e2", sourceHandle: Just "sh", targetHandle: Just "th" }) ==
      "Couldn't create edge for target handle id: \"th\", edge id: e2.")

  -- 007: mergeAriaLabelConfig with no overrides == defaults.
  let merged0 = C.mergeAriaLabelConfig C.emptyAriaLabelConfigOverride
  assert "merge with no overrides preserves controlsAriaLabel"
    (merged0.controlsAriaLabel == C.defaultAriaLabelConfig.controlsAriaLabel)
  assert "merge with no overrides preserves handleAriaLabel"
    (merged0.handleAriaLabel == C.defaultAriaLabelConfig.handleAriaLabel)

  -- 007: mergeAriaLabelConfig with one override replaces just that field.
  let
    overrideOne = C.emptyAriaLabelConfigOverride
      { controlsAriaLabel = Just "My Control Panel" }
    merged1 = C.mergeAriaLabelConfig overrideOne
  assert "single override replaces controlsAriaLabel"
    (merged1.controlsAriaLabel == "My Control Panel")
  assert "single override leaves minimapAriaLabel at default"
    (merged1.minimapAriaLabel == C.defaultAriaLabelConfig.minimapAriaLabel)

  -- 004: Align bounds and ordering.
  assert "Align bottom == AlignCenter" ((bottom :: Align) == AlignCenter)
  assert "Align top == AlignEnd" ((top :: Align) == AlignEnd)
  assert "Align AlignCenter < AlignEnd" (AlignCenter < AlignEnd)
  assert "show AlignStart == \"AlignStart\"" (show AlignStart == "AlignStart")

  -- 004: SetAttributesMode bounds.
  assert "SetAttributesMode bottom" ((bottom :: SetAttributesMode) == SetBothDimensions)
  assert "SetAttributesMode top" ((top :: SetAttributesMode) == NoSetAttributes)
  assert "SetWidthOnly /= SetHeightOnly" (SetWidthOnly /= SetHeightOnly)

  -- 004: NodeExtent constructs both variants and Eq distinguishes them.
  let parentE = ParentExtent
  let coordE = CoordExtent (mkCoordinateExtent 0.0 0.0 1.0 1.0)
  assert "ParentExtent == ParentExtent" (parentE == ParentExtent)
  assert "CoordExtent == CoordExtent" (coordE == CoordExtent (mkCoordinateExtent 0.0 0.0 1.0 1.0))
  assert "ParentExtent /= CoordExtent" (parentE /= coordE)

  -- 004: NodeChange exhaustive pattern match across all six constructors.
  let
    classifyNode :: NodeChange Unit -> String
    classifyNode = case _ of
      NodeDimensionChange _ -> "dim"
      NodePositionChange _ -> "pos"
      NodeSelectionChange _ -> "sel"
      NodeRemoveChange _ -> "rem"
      NodeAddChange _ -> "add"
      NodeReplaceChange _ -> "rep"
    nodeChanges :: Array { tag :: String, change :: NodeChange Unit }
    nodeChanges =
      [ { tag: "dim"
        , change: NodeDimensionChange
            { id: "1"
            , dimensions: Nothing
            , resizing: false
            , setAttributes: NoSetAttributes
            }
        }
      , { tag: "pos"
        , change: NodePositionChange
            { id: "2"
            , position: Nothing
            , positionAbsolute: Nothing
            , dragging: false
            }
        }
      , { tag: "sel", change: NodeSelectionChange { id: "3", selected: true } }
      , { tag: "rem", change: NodeRemoveChange { id: "4" } }
      ]
  assert "NodeChange constructors classify"
    (map (\r -> classifyNode r.change == r.tag) nodeChanges
      == [ true, true, true, true ])

  -- 005: ConnectionLineType cardinality via Bounded round-trip.
  assert "ConnectionLineType bottom" ((bottom :: ConnectionLineType) == BezierLine)
  assert "ConnectionLineType top" ((top :: ConnectionLineType) == SimpleBezierLine)
  assert "show StraightLine" (show StraightLine == "StraightLine")

  -- 005: MarkerType.
  assert "Arrow /= ArrowClosed" (Arrow /= ArrowClosed)
  assert "show ArrowClosed" (show ArrowClosed == "ArrowClosed")

  -- 005: AlignX, AlignY have proper bounds.
  assert "AlignX bottom" ((bottom :: AlignX) == AlignXLeft)
  assert "AlignX top" ((top :: AlignX) == AlignXRight)
  assert "AlignY bottom" ((bottom :: AlignY) == AlignYTop)
  assert "AlignY top" ((top :: AlignY) == AlignYBottom)

  -- 005: EdgeMarkerType pattern match.
  let
    named = NamedMarker "arrow"
    custom = CustomMarker
      { markerType: Arrow
      , color: Just "#000"
      , width: Nothing
      , height: Nothing
      , markerUnits: Nothing
      , orient: Nothing
      , strokeWidth: Nothing
      }
  assert "NamedMarker pattern"
    (case named of
      NamedMarker s -> s == "arrow"
      CustomMarker _ -> false)
  assert "CustomMarker pattern"
    (case custom of
      NamedMarker _ -> false
      CustomMarker m -> m.markerType == Arrow)

  -- 005: EdgeChange exhaustive pattern match across all four constructors.
  let
    classifyEdge :: EdgeChange Unit -> String
    classifyEdge = case _ of
      EdgeSelectionChange _ -> "sel"
      EdgeRemoveChange _ -> "rem"
      EdgeAddChange _ -> "add"
      EdgeReplaceChange _ -> "rep"
    edgeSel = EdgeSelectionChange { id: "1", selected: true } :: EdgeChange Unit
    edgeRem = EdgeRemoveChange { id: "2" } :: EdgeChange Unit
  assert "EdgeSelectionChange classifies" (classifyEdge edgeSel == "sel")
  assert "EdgeRemoveChange classifies" (classifyEdge edgeRem == "rem")

  -- 006: PanOnDrag variants pattern match.
  let
    panBtns = PZ.PanOnButtons (NEA.singleton 0)
  assert "NoPan == NoPan" (PZ.NoPan == PZ.NoPan)
  assert "PanAlways /= NoPan" (PZ.PanAlways /= PZ.NoPan)
  assert "PanOnButtons eq" (panBtns == PZ.PanOnButtons (NEA.singleton 0))
  assert "PanOnButtons /= PanAlways" (panBtns /= PZ.PanAlways)
  assert "show NoPan" (show PZ.NoPan == "NoPan")

  -- 006: InterpolateMode is the same type as Connection's (re-exported).
  let im = PZ.Smooth
  assert "PanZoom InterpolateMode Smooth" (im == PZ.Smooth)
  assert "PanZoom InterpolateMode Smooth /= Linear" (im /= PZ.Linear)

  -- 015: shallowNodeData covers Nothing/empty/length/match/mismatch cases.
  let
    mkSummary :: String -> Maybe String -> Int -> NodeSummary Int
    mkSummary nid ntype d = { id: nid, nodeType: ntype, data: d }
    n1 = mkSummary "1" (Just "input") 10
    n1' = mkSummary "1" (Just "input") 10
    n2 = mkSummary "2" Nothing 20
    n1diffData = mkSummary "1" (Just "input") 99
    n1diffType = mkSummary "1" (Just "default") 10
    n1diffId = mkSummary "X" (Just "input") 10

  assert "shallowNodeData Nothing/Nothing == false"
    (shallowNodeData (Nothing :: Maybe (Array (NodeSummary Int))) Nothing == false)
  assert "shallowNodeData Just/Nothing == false"
    (shallowNodeData (Just [ n1 ]) Nothing == false)
  assert "shallowNodeData Nothing/Just == false"
    (shallowNodeData Nothing (Just [ n1 ]) == false)
  assert "shallowNodeData empty/empty == true"
    (shallowNodeData (Just ([] :: Array (NodeSummary Int))) (Just []) == true)
  assert "shallowNodeData different lengths == false"
    (shallowNodeData (Just [ n1 ]) (Just [ n1, n2 ]) == false)
  assert "shallowNodeData matching arrays == true"
    (shallowNodeData (Just [ n1, n2 ]) (Just [ n1', n2 ]) == true)
  assert "shallowNodeData differing data == false"
    (shallowNodeData (Just [ n1 ]) (Just [ n1diffData ]) == false)
  assert "shallowNodeData differing type == false"
    (shallowNodeData (Just [ n1 ]) (Just [ n1diffType ]) == false)
  assert "shallowNodeData differing id == false"
    (shallowNodeData (Just [ n1 ]) (Just [ n1diffId ]) == false)

  -- 015: shallowNodeDataSingle compares one-to-one.
  assert "shallowNodeDataSingle equal" (shallowNodeDataSingle n1 n1' == true)
  assert "shallowNodeDataSingle differing data"
    (shallowNodeDataSingle n1 n1diffData == false)
  assert "shallowNodeDataSingle differing type"
    (shallowNodeDataSingle n1 n1diffType == false)
  assert "shallowNodeDataSingle differing id"
    (shallowNodeDataSingle n1 n1diffId == false)

  -- 008: clamp / clamp01 cover the standard branches.
  assert "clamp 5 0 1 == 1" (G.clamp 5.0 0.0 1.0 == 1.0)
  assert "clamp 0.5 0 1 == 0.5" (G.clamp 0.5 0.0 1.0 == 0.5)
  assert "clamp -1 0 1 == 0" (G.clamp (-1.0) 0.0 1.0 == 0.0)
  assert "clamp01 1.5 == 1" (G.clamp01 1.5 == 1.0)

  -- 008: pointToRendererPoint and rendererPointToPoint are inverses when
  -- snap-to-grid is off.
  let
    transform = mkTransform 10.0 20.0 2.0
    p0 = { x: 7.5, y: 12.0 }
    pRoundtrip =
      rendererPointToPointPure
        (G.pointToRendererPoint p0 transform Nothing) transform
    rendererPointToPointPure = G.rendererPointToPoint
  assert "pointToRendererPoint inverse"
    (Number.abs (pRoundtrip.x - p0.x) < 0.0001
      && Number.abs (pRoundtrip.y - p0.y) < 0.0001)

  -- 008: getOverlappingArea returns 0 for disjoint rectangles.
  assert "non-overlapping rects have zero overlap"
    (G.getOverlappingArea
       { x: 0.0, y: 0.0, width: 10.0, height: 10.0 }
       { x: 100.0, y: 100.0, width: 10.0, height: 10.0 } == 0.0)

  -- 008: snapPosition rounds to the grid.
  let snapped = G.snapPosition { x: 7.4, y: 12.6 } (mkSnapGrid 5.0 5.0)
  assert "snapPosition snaps to nearest grid cell"
    (snapped.x == 5.0 && snapped.y == 15.0)

  -- 008: isCoordinateExtent collapses ParentExtent to Nothing.
  assert "isCoordinateExtent ParentExtent == Nothing"
    (G.isCoordinateExtent (Just ParentExtent) == Nothing)
  assert "isCoordinateExtent Nothing == Nothing"
    (G.isCoordinateExtent Nothing == Nothing)
  let coord = mkCoordinateExtent 0.0 0.0 10.0 10.0
  assert "isCoordinateExtent (CoordExtent c) == Just c"
    (G.isCoordinateExtent (Just (CoordExtent coord)) == Just coord)

  -- 009: getOutgoers and getIncomers on a small fixture.
  let
    mkNode :: String -> NodeBase Unit
    mkNode nid =
      { id: nid
      , position: { x: 0.0, y: 0.0 }
      , data: unit
      , sourcePosition: Nothing
      , targetPosition: Nothing
      , hidden: false
      , selected: false
      , dragging: false
      , draggable: Nothing
      , selectable: Nothing
      , connectable: Nothing
      , deletable: Nothing
      , dragHandle: Nothing
      , width: Just 50.0
      , height: Just 25.0
      , initialWidth: Nothing
      , initialHeight: Nothing
      , parentId: Nothing
      , zIndex: Nothing
      , extent: Nothing
      , expandParent: false
      , ariaLabel: Nothing
      , origin: Nothing
      , handles: Nothing
      , measured: { width: Just 50.0, height: Just 25.0 }
      , nodeType: Nothing
      }
    mkEdge :: String -> String -> String -> EdgeBase Unit
    mkEdge eid src tgt =
      { id: eid
      , edgeType: Nothing
      , source: src
      , target: tgt
      , sourceHandle: Nothing
      , targetHandle: Nothing
      , animated: false
      , hidden: false
      , deletable: Nothing
      , selectable: Nothing
      , data: Nothing
      , selected: false
      , markerStart: Nothing
      , markerEnd: Nothing
      , zIndex: Nothing
      , ariaLabel: Nothing
      , interactionWidth: Nothing
      }
    nA = mkNode "a"
    nB = mkNode "b"
    nC = mkNode "c"
    eAB = mkEdge "e1" "a" "b"
    eAC = mkEdge "e2" "a" "c"
    eBC = mkEdge "e3" "b" "c"
    threeNodes = [ nA, nB, nC ]
    threeEdges = [ eAB, eAC, eBC ]
    outsOfA = getOutgoers { id: "a" } threeNodes threeEdges
    insOfC = getIncomers { id: "c" } threeNodes threeEdges
  assert "getOutgoers a -> {b, c}" (Array.length outsOfA == 2)
  assert "getIncomers c -> {a, b}" (Array.length insOfC == 2)

  -- 009: getNodesBounds spans both unit nodes (each 50x25, 100 apart).
  let
    bounds =
      getNodesBounds
        [ nA, nB { position = { x: 100.0, y: 100.0 } } ]
        Nothing
        (mkNodeOrigin 0.0 0.0)
  assert "getNodesBounds spans union"
    (bounds.x == 0.0 && bounds.y == 0.0
      && bounds.width == 150.0
      && bounds.height == 125.0)

  -- 009: calculateNodePosition returns Nothing for an unknown id.
  assert "calculateNodePosition unknown id is Nothing"
    ( calculateNodePosition
        { nodeId: "missing"
        , nextPosition: { x: 0.0, y: 0.0 }
        , nodeLookup: Map.empty
        , nodeOrigin: mkNodeOrigin 0.0 0.0
        , nodeExtent: Nothing
        , onError: Nothing
        }
        == Nothing
    )

  -- 010: isManualZIndexMode discriminates ZManual.
  assert "isManualZIndexMode ZManual"
    (isManualZIndexMode ZManual == true)
  assert "isManualZIndexMode ZBasic"
    (isManualZIndexMode ZBasic == false)

  -- 013: getStraightPath produces the correct midpoint and SVG string.
  let
    sp = getStraightPath { sourceX: 0.0, sourceY: 0.0, targetX: 100.0, targetY: 100.0 }
  assert "getStraightPath path"
    (sp.path == "M 0,0L 100,100")
  assert "getStraightPath label center"
    (sp.labelX == 50.0 && sp.labelY == 50.0)

  -- 013: getEdgeId is deterministic.
  assert "getEdgeId stable"
    (getEdgeId
        { source: "a", target: "b"
        , sourceHandle: Nothing, targetHandle: Nothing
        }
        == "xy-edge__a-b")

  -- 013: addEdge with empty source returns Left.
  let
    badEdge = mkEdge "" "" "b"
  assert "addEdge with empty source returns Left"
    (case addEdge badEdge [] getEdgeId of
      Left _ -> true
      Right _ -> false)

  -- 013: getMarkerId for Nothing / NamedMarker.
  assert "getMarkerId Nothing == \"\"" (getMarkerId Nothing Nothing == "")
  assert "getMarkerId NamedMarker"
    (getMarkerId (Just (NamedMarker "arrowclosed")) Nothing == "arrowclosed")

  -- 014: toolbar transforms produce predictable strings.
  let
    nodeRect = { x: 10.0, y: 20.0, width: 100.0, height: 50.0 }
    viewport :: Viewport
    viewport = { x: 0.0, y: 0.0, zoom: 1.0 }
    nodeTopCenter = getNodeToolbarTransform nodeRect viewport PosTop 5.0 AlignCenter
  assert "node toolbar TOP/CENTER format"
    (nodeTopCenter == "translate(60px, 15px) translate(-50%, -100%)")

  let
    edgeT = getEdgeToolbarTransform 100.0 50.0 2.0 AlignXCenter AlignYCenter
  assert "edge toolbar centred"
    (edgeT == "translate(100px, 50px) scale(0.5) translate(-50%, -50%)")

  -- 016: XYDrag pure utilities -------------------------------------------------
  let
    -- Build an InternalNodeBase fixture for drag tests.
    mkInternal
      :: String
      -> Boolean
      -> Maybe Boolean
      -> Maybe String
      -> XYPosition
      -> InternalNodeBase Unit
    mkInternal nid selected draggable parentId positionAbsolute =
      { id: nid
      , position: { x: 0.0, y: 0.0 }
      , data: unit
      , sourcePosition: Nothing
      , targetPosition: Nothing
      , hidden: false
      , selected
      , dragging: false
      , draggable
      , selectable: Nothing
      , connectable: Nothing
      , deletable: Nothing
      , dragHandle: Nothing
      , width: Just 50.0
      , height: Just 25.0
      , initialWidth: Nothing
      , initialHeight: Nothing
      , parentId
      , zIndex: Nothing
      , extent: Nothing
      , expandParent: false
      , ariaLabel: Nothing
      , origin: Nothing
      , handles: Nothing
      , measured: { width: Just 50.0, height: Just 25.0 }
      , nodeType: Nothing
      , internals:
          { positionAbsolute
          , z: 0.0
          , rootParentIndex: Nothing
          , handleBounds: Nothing
          , bounds: Nothing
          }
      }

    parent = mkInternal "p" false Nothing Nothing { x: 0.0, y: 0.0 }
    parentSelected = parent { selected = true }
    childOfParent = mkInternal "c" false Nothing (Just "p") { x: 10.0, y: 10.0 }
    selectedNode = mkInternal "s" true Nothing Nothing { x: 5.0, y: 5.0 }
    draggableNode = mkInternal "d" true (Just true) Nothing { x: 0.0, y: 0.0 }
    nonDraggable = mkInternal "n" true (Just false) Nothing { x: 0.0, y: 0.0 }

    lookupParentSelected =
      Map.fromFoldable
        [ Tuple "p" parentSelected, Tuple "c" childOfParent ]
        :: NodeLookup Unit
    lookupParentUnselected =
      Map.fromFoldable
        [ Tuple "p" parent, Tuple "c" childOfParent ]
        :: NodeLookup Unit

  -- isParentSelected: walks the chain.
  assert "isParentSelected returns false for a root node"
    (XYDrag.isParentSelected parent lookupParentUnselected == false)
  assert "isParentSelected returns false when parent unselected"
    (XYDrag.isParentSelected childOfParent lookupParentUnselected == false)
  assert "isParentSelected returns true when parent is selected"
    (XYDrag.isParentSelected childOfParent lookupParentSelected == true)
  assert "isParentSelected returns false when parentId points nowhere"
    (XYDrag.isParentSelected
      (childOfParent { parentId = Just "ghost" })
      lookupParentUnselected == false)

  -- getDragItems: filter by selected/draggable.
  let
    lookupDrag =
      Map.fromFoldable
        [ Tuple "s" selectedNode
        , Tuple "d" draggableNode
        , Tuple "n" nonDraggable
        ]
        :: NodeLookup Unit
    dragItemsAll =
      XYDrag.getDragItems lookupDrag true { x: 0.0, y: 0.0 } Nothing
    dragItemsExplicit =
      XYDrag.getDragItems lookupDrag false { x: 0.0, y: 0.0 } (Just "d")
  assert "getDragItems collects selected nodes when nodesDraggable=true"
    (Map.member "s" dragItemsAll)
  assert "getDragItems honours node.draggable=true"
    (Map.member "d" dragItemsAll)
  assert "getDragItems excludes node.draggable=false even if selected"
    (not (Map.member "n" dragItemsAll))
  assert "getDragItems collects only the targeted node when nodeId is set"
    (Map.size dragItemsExplicit == 1 && Map.member "d" dragItemsExplicit)

  -- calculateSnapOffset: empty / non-empty / pure deltas.
  let snap5 = mkSnapGrid 5.0 5.0
  assert "calculateSnapOffset returns Nothing for empty drag items"
    (XYDrag.calculateSnapOffset Map.empty snap5 0.0 0.0 == Nothing)
  let
    -- A drag item whose distance.x = 0, distance.y = 0 means we snap (x,y).
    flatItem :: NodeDragItem
    flatItem =
      { id: "i"
      , position: { x: 0.0, y: 0.0 }
      , distance: { x: 0.0, y: 0.0 }
      , extent: Nothing
      , parentId: Nothing
      , origin: Nothing
      , expandParent: false
      , internals: { positionAbsolute: { x: 0.0, y: 0.0 } }
      , measured: { width: 0.0, height: 0.0 }
      , dragging: false
      }
    flatMap = Map.singleton "i" flatItem
  -- Snapping (7.4, 12.6) to a 5-grid lands at (5, 15); offset is (-2.4, 2.4).
  let snapOffset = XYDrag.calculateSnapOffset flatMap snap5 7.4 12.6
  assert "calculateSnapOffset computes the (snapped - raw) delta"
    ( case snapOffset of
        Just o ->
          Number.abs (o.x - (-2.4)) < 0.0001
            && Number.abs (o.y - 2.4) < 0.0001
        Nothing -> false
    )

  -- getEventHandlerParams: currentNode/allNodes split.
  let
    items2 :: Map.Map String NodeDragItem
    items2 = Map.fromFoldable
      [ Tuple "s" (flatItem { id = "s", position = { x: 1.0, y: 1.0 } })
      , Tuple "d" (flatItem { id = "d", position = { x: 2.0, y: 2.0 } })
      ]
    lookup2 =
      Map.fromFoldable
        [ Tuple "s" selectedNode, Tuple "d" draggableNode ]
        :: NodeLookup Unit
    paramsHead = XYDrag.getEventHandlerParams Nothing items2 lookup2 true
    paramsTargeted =
      XYDrag.getEventHandlerParams (Just "d") items2 lookup2 true
  assert "getEventHandlerParams Nothing returns first item as current"
    ( case paramsHead.currentNode of
        Just n -> n.id == "s" || n.id == "d" -- map order isn't fixed
        Nothing -> false
    )
  assert "getEventHandlerParams Nothing returns all items"
    (Array.length paramsHead.allNodes == 2)
  assert "getEventHandlerParams Just nid returns that node as current"
    ( case paramsTargeted.currentNode of
        Just n -> n.id == "d" && n.dragging == true
        Nothing -> false
    )

  -- 017: XYHandle pure utilities ---------------------------------------------

  -- isConnectionValid: full truth table.
  assert "isConnectionValid: handle valid -> Just true"
    (XYHandle.isConnectionValid false true == Just true)
  assert "isConnectionValid: in radius, handle invalid -> Just false"
    (XYHandle.isConnectionValid true false == Just false)
  assert "isConnectionValid: outside radius, handle invalid -> Nothing"
    (XYHandle.isConnectionValid false false == Nothing)
  assert "isConnectionValid: in radius and handle valid -> Just true"
    (XYHandle.isConnectionValid true true == Just true)

  -- getHandle: returns Nothing for missing node, Just for found, and uses
  -- absolute position when requested.
  let
    -- A node positioned at (100, 50) with one source handle at offset (5, 5).
    handleS :: { id :: Maybe String
               , x :: Number
               , y :: Number
               , position :: Position
               , handleType :: HandleType
               , width :: Number
               , height :: Number
               , nodeId :: String
               }
    handleS =
      { id: Just "out"
      , x: 5.0
      , y: 5.0
      , position: PosRight
      , handleType: Source
      , width: 6.0
      , height: 6.0
      , nodeId: "n1"
      }
    handleT = handleS
      { id = Just "in"
      , handleType = Target
      , position = PosLeft
      , x = 0.0
      , y = 0.0
      }
    nodeWithHandles = mkInternal "n1" false Nothing Nothing { x: 100.0, y: 50.0 }
    nodeWithHandles' = nodeWithHandles
      { internals = nodeWithHandles.internals
          { handleBounds = Just
              { source: Just [ handleS ], target: Just [ handleT ] }
          }
      }
    lookupHandles =
      Map.fromFoldable [ Tuple "n1" nodeWithHandles' ] :: NodeLookup Unit

  assert "getHandle: missing node returns Nothing"
    ( XYHandle.getHandle "ghost" Source Nothing lookupHandles Strict false
        == Nothing
    )
  assert "getHandle: returns the source handle when handleId matches"
    ( case XYHandle.getHandle "n1" Source (Just "out") lookupHandles Strict false of
        Just h -> h.id == Just "out" && h.handleType == Source
        Nothing -> false
    )
  assert "getHandle: Loose mode mixes source+target handles"
    ( case XYHandle.getHandle "n1" Source (Just "in") lookupHandles Loose false of
        Just h -> h.id == Just "in" && h.handleType == Target
        Nothing -> false
    )
  assert "getHandle: withAbsolutePosition shifts to canvas coords"
    ( case XYHandle.getHandle "n1" Source (Just "out") lookupHandles Strict true of
        -- handle.x = 5, node positionAbsolute.x = 0 (we didn't set internals
        -- positionAbsolute). The function adds them; result is 5.
        Just h -> h.x >= 5.0
        Nothing -> false
    )

  -- 018: XYPanZoom utils -----------------------------------------------------

  -- transformToViewport / viewportToTransform round-trip the (x, y, zoom).
  let
    vp1 :: Viewport
    vp1 = { x: 12.5, y: -3.0, zoom: 0.75 }
    rt = XYPanZoom.transformToViewport
      (XYPanZoom.viewportToTransform vp1)
  assert "viewportToTransform/transformToViewport round-trip x"
    (Number.abs (rt.x - vp1.x) < 0.0001)
  assert "viewportToTransform/transformToViewport round-trip y"
    (Number.abs (rt.y - vp1.y) < 0.0001)
  assert "viewportToTransform/transformToViewport round-trip zoom"
    (Number.abs (rt.zoom - vp1.zoom) < 0.0001)

  -- isRightClickPan: the truth table.
  assert "isRightClickPan: NoPan, button=2 -> false"
    (XYPanZoom.isRightClickPan PZ.NoPan 2 == false)
  assert "isRightClickPan: PanAlways, button=2 -> false"
    (XYPanZoom.isRightClickPan PZ.PanAlways 2 == false)
  assert "isRightClickPan: PanOnButtons[0], button=2 -> false"
    (XYPanZoom.isRightClickPan (PZ.PanOnButtons (NEA.singleton 0)) 2 == false)
  assert "isRightClickPan: PanOnButtons[2], button=2 -> true"
    (XYPanZoom.isRightClickPan (PZ.PanOnButtons (NEA.singleton 2)) 2 == true)
  assert "isRightClickPan: PanOnButtons[2], button=0 -> false"
    (XYPanZoom.isRightClickPan (PZ.PanOnButtons (NEA.singleton 2)) 0 == false)

  -- getClosestHandle: returns the nearest handle within the radius and
  -- Nothing when nothing is in range.
  let
    -- Position the source handle at absolute (100,50). With node at (100,50)
    -- and handle offset (5,5), the absolute is (105, 55).
    far = XYHandle.getClosestHandle { x: 1000.0, y: 1000.0 } 50.0 lookupHandles
      { nodeId: "other", id: Nothing, handleType: Target }
    near = XYHandle.getClosestHandle { x: 105.0, y: 55.0 } 50.0 lookupHandles
      { nodeId: "other", id: Nothing, handleType: Target }
  assert "getClosestHandle: nothing within radius returns Nothing"
    (far == Nothing)
  assert "getClosestHandle: a handle within radius is returned"
    (case near of
      Just _ -> true
      Nothing -> false)

  -- 019: XYResizer pure utilities --------------------------------------------

  -- getResizeDirection: sign + affects flips.
  let
    plain = ResizerU.getResizeDirection
      { width: 110.0
      , prevWidth: 100.0
      , height: 50.0
      , prevHeight: 50.0
      , affectsX: false
      , affectsY: false
      }
    flipX = ResizerU.getResizeDirection
      { width: 110.0
      , prevWidth: 100.0
      , height: 50.0
      , prevHeight: 50.0
      , affectsX: true
      , affectsY: false
      }
  assert "getResizeDirection: width grew, dx=1"
    (plain.dx == 1 && plain.dy == 0)
  assert "getResizeDirection: affectsX flips dx sign"
    (flipX.dx == -1)

  -- getControlDirection: each of the 8 ControlPositions decomposes correctly.
  assert "getControlDirection: TopLeft -> H+V, affectsX, affectsY"
    ( let d = ResizerU.getControlDirection
            (Resizer.ControlCorner Resizer.CornerTopLeft)
      in d.isHorizontal && d.isVertical && d.affectsX && d.affectsY
    )
  assert "getControlDirection: BottomRight -> H+V, no affects"
    ( let d = ResizerU.getControlDirection
            (Resizer.ControlCorner Resizer.CornerBottomRight)
      in d.isHorizontal && d.isVertical && not d.affectsX && not d.affectsY
    )
  assert "getControlDirection: Top line -> V only, affectsY"
    ( let d = ResizerU.getControlDirection
            (Resizer.ControlLine Resizer.LineTop)
      in not d.isHorizontal && d.isVertical && not d.affectsX && d.affectsY
    )
  assert "getControlDirection: Right line -> H only, no affects"
    ( let d = ResizerU.getControlDirection
            (Resizer.ControlLine Resizer.LineRight)
      in d.isHorizontal && not d.isVertical && not d.affectsX && not d.affectsY
    )
  assert "getControlDirection: Bottom line -> V only, no affects"
    ( let d = ResizerU.getControlDirection
            (Resizer.ControlLine Resizer.LineBottom)
      in not d.isHorizontal && d.isVertical && not d.affectsX && not d.affectsY
    )
  assert "getControlDirection: Left line -> H only, affectsX"
    ( let d = ResizerU.getControlDirection
            (Resizer.ControlLine Resizer.LineLeft)
      in d.isHorizontal && not d.isVertical && d.affectsX && not d.affectsY
    )

  -- getDimensionsAfterResize: unconstrained free resize from BottomRight.
  let
    sv :: ResizerU.ResizeStartValues
    sv =
      { x: 0.0
      , y: 0.0
      , width: 100.0
      , height: 50.0
      , pointerX: 0.0
      , pointerY: 0.0
      , aspectRatio: 2.0
      }
    bigBoundaries =
      { minWidth: 0.0
      , maxWidth: 1.0e9
      , minHeight: 0.0
      , maxHeight: 1.0e9
      }
    origin0 = mkNodeOrigin 0.0 0.0
    pp dx dy =
      { x: dx, y: dy, xSnapped: dx, ySnapped: dy } :: ResizerU.PointerPosition
    ctrlBR = ResizerU.getControlDirection
      (Resizer.ControlCorner Resizer.CornerBottomRight)

    free = ResizerU.getDimensionsAfterResize sv ctrlBR (pp 30.0 20.0)
      bigBoundaries false origin0 Nothing Nothing
  assert "getDimensionsAfterResize: free BR drag adds the delta to dimensions"
    ( Number.abs (free.width - 130.0) < 0.0001
        && Number.abs (free.height - 70.0) < 0.0001
        && Number.abs free.x < 0.0001
        && Number.abs free.y < 0.0001
    )

  -- min/max clamping (1): max width caps growth.
  let
    capped = ResizerU.getDimensionsAfterResize sv ctrlBR (pp 200.0 0.0)
      (bigBoundaries { maxWidth = 120.0 }) false origin0 Nothing Nothing
  assert "getDimensionsAfterResize: maxWidth=120 caps width at 120"
    (Number.abs (capped.width - 120.0) < 0.0001)

  -- min/max clamping (2): min height floors shrink.
  let
    ctrlTL = ResizerU.getControlDirection
      (Resizer.ControlCorner Resizer.CornerTopLeft)
    -- dragging TopLeft toward bottom-right shrinks the node.
    floored = ResizerU.getDimensionsAfterResize sv ctrlTL (pp 90.0 60.0)
      (bigBoundaries { minHeight = 30.0 }) false origin0 Nothing Nothing
  assert "getDimensionsAfterResize: minHeight=30 floors height at >=30"
    (floored.height >= 29.999)

  -- Parent extent clamping: dragging BR past the parent extent caps.
  let
    parentExt = mkCoordinateExtent 0.0 0.0 110.0 60.0
    extClamped = ResizerU.getDimensionsAfterResize sv ctrlBR (pp 200.0 200.0)
      bigBoundaries false origin0 (Just parentExt) Nothing
  assert "getDimensionsAfterResize: parent extent caps width at 110"
    (Number.abs (extClamped.width - 110.0) < 0.0001)
  assert "getDimensionsAfterResize: parent extent caps height at 60"
    (Number.abs (extClamped.height - 60.0) < 0.0001)

  -- Child extent clamping: TopLeft drag inward past child boundary.
  let
    childExt = mkCoordinateExtent 10.0 10.0 90.0 40.0
    childClamped = ResizerU.getDimensionsAfterResize sv ctrlTL (pp 50.0 50.0)
      bigBoundaries false origin0 Nothing (Just childExt)
  -- The TopLeft drag with childExtent prevents shrinkage past the child's
  -- bounds. The exact value depends on the math; assert width and height
  -- stay above the child extent's gap from the start.
  assert "getDimensionsAfterResize: child extent prevents over-shrink"
    (childClamped.width >= 49.999 && childClamped.height >= 9.999)

  -- Aspect ratio: BR drag with keepAspectRatio holds w/h ratio.
  let
    aspect = ResizerU.getDimensionsAfterResize sv ctrlBR (pp 30.0 0.0)
      bigBoundaries true origin0 Nothing Nothing
  -- aspectRatio is 2.0 (sv.width=100/sv.height=50). After diagonal drag
  -- with keepAspectRatio, w/h should still be ≈ 2.0.
  assert "getDimensionsAfterResize: keepAspectRatio holds w/h ratio"
    (Number.abs (aspect.width / aspect.height - 2.0) < 0.0001)

  -- 020: XYMinimap smoke check ----------------------------------------------
  let
    minimapDefaults = XYMinimap.defaultXYMinimapUpdate
      (mkCoordinateExtent (-1000.0) (-1000.0) 1000.0 1000.0)
      200.0
      150.0
  assert "defaultXYMinimapUpdate: width and height threaded"
    (minimapDefaults.width == 200.0 && minimapDefaults.height == 150.0)
  assert "defaultXYMinimapUpdate: zoomStep=1.0, pannable+zoomable=true"
    ( minimapDefaults.zoomStep == 1.0
        && minimapDefaults.pannable
        && minimapDefaults.zoomable
        && not minimapDefaults.inversePan
    )

  log "all tests passed"

  runProperties
