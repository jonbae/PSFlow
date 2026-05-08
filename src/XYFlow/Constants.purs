module XYFlow.Constants
  ( ErrorCode(..)
  , Error008Edge
  , errorMessage
  , infiniteExtent
  , elementSelectionKeys
  , AriaLabelConfig
  , AriaLabelConfigOverride
  , defaultAriaLabelConfig
  , emptyAriaLabelConfigOverride
  , mergeAriaLabelConfig
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import XYFlow.Types.Geometry (CoordinateExtent, mkCoordinateExtent)
import XYFlow.Types.Handle (HandleType(..))

-- | Error codes carry their parameters on the constructor rather than via a
-- | side helper. This collapses the TS pattern of `errorMessages.error003(t)`
-- | into a single total `errorMessage` function and lets the compiler enforce
-- | that callers pass the right arguments for each code.
data ErrorCode
  = E001
  | E002
  | E003 String
  | E004
  | E005
  | E006
  | E007 String
  | E008 HandleType Error008Edge
  | E009 String
  | E010
  | E011 String
  | E012 String
  | E013 String
  | E014
  | E015

type Error008Edge =
  { id :: String
  , sourceHandle :: Maybe String
  , targetHandle :: Maybe String
  }

errorMessage :: ErrorCode -> String
errorMessage = case _ of
  E001 ->
    "[React Flow]: Seems like you have not used zustand provider as an ancestor. Help: https://reactflow.dev/error#001"
  E002 ->
    "It looks like you've created a new nodeTypes or edgeTypes object. If this wasn't on purpose please define the nodeTypes/edgeTypes outside of the component or memoize them."
  E003 nodeType ->
    "Node type \"" <> nodeType <> "\" not found. Using fallback type \"default\"."
  E004 ->
    "The React Flow parent container needs a width and a height to render the graph."
  E005 ->
    "Only child nodes can use a parent extent."
  E006 ->
    "Can't create edge. An edge needs a source and a target."
  E007 edgeId ->
    "The old edge with id=" <> edgeId <> " does not exist."
  E008 handleType edge ->
    let
      handleStr = case handleType of
        Source -> "source"
        Target -> "target"
      handleId = case handleType of
        Source -> fromMaybe "" edge.sourceHandle
        Target -> fromMaybe "" edge.targetHandle
    in
      "Couldn't create edge for " <> handleStr <> " handle id: \""
        <> handleId
        <> "\", edge id: "
        <> edge.id
        <> "."
  E009 markerType ->
    "Marker type \"" <> markerType <> "\" doesn't exist."
  E010 ->
    "Handle: No node id found. Make sure to only use a Handle inside a custom Node."
  E011 edgeType ->
    "Edge type \"" <> edgeType <> "\" not found. Using fallback type \"default\"."
  E012 nodeId ->
    "Node with id \"" <> nodeId <> "\" does not exist, it may have been removed. This can happen when a node is deleted before the \"onNodeClick\" handler is called."
  E013 lib ->
    "It seems that you haven't loaded the styles. Please import '@xyflow/" <> lib <> "/dist/style.css' or base.css to make sure everything is working properly."
  E014 ->
    "useNodeConnections: No node ID found. Call useNodeConnections inside a custom Node or provide a node ID."
  E015 ->
    "It seems that you are trying to drag a node that is not initialized. Please use onNodesChange as explained in the docs."

-- | Sentinel extent representing "no bounds". `(-1.0/0.0)` and `(1.0/0.0)`
-- | produce -Infinity and +Infinity in IEEE-754, matching the TS source.
infiniteExtent :: CoordinateExtent
infiniteExtent =
  mkCoordinateExtent (-1.0 / 0.0) (-1.0 / 0.0) (1.0 / 0.0) (1.0 / 0.0)

elementSelectionKeys :: Array String
elementSelectionKeys = [ "Enter", " ", "Escape" ]

-- | TS keys are dot-paths (e.g. `node.a11yDescription.default`) which would
-- | not be valid PS labels. Each is camelCased into a flat field name.
type AriaLabelConfig =
  { nodeA11yDescriptionDefault :: String
  , nodeA11yDescriptionKeyboardDisabled :: String
  , nodeA11yDescriptionAriaLiveMessage ::
      { direction :: String, x :: Number, y :: Number } -> String
  , edgeA11yDescriptionDefault :: String
  , controlsAriaLabel :: String
  , controlsZoomInAriaLabel :: String
  , controlsZoomOutAriaLabel :: String
  , controlsFitViewAriaLabel :: String
  , controlsInteractiveAriaLabel :: String
  , minimapAriaLabel :: String
  , handleAriaLabel :: String
  }

type AriaLabelConfigOverride =
  { nodeA11yDescriptionDefault :: Maybe String
  , nodeA11yDescriptionKeyboardDisabled :: Maybe String
  , nodeA11yDescriptionAriaLiveMessage ::
      Maybe ({ direction :: String, x :: Number, y :: Number } -> String)
  , edgeA11yDescriptionDefault :: Maybe String
  , controlsAriaLabel :: Maybe String
  , controlsZoomInAriaLabel :: Maybe String
  , controlsZoomOutAriaLabel :: Maybe String
  , controlsFitViewAriaLabel :: Maybe String
  , controlsInteractiveAriaLabel :: Maybe String
  , minimapAriaLabel :: Maybe String
  , handleAriaLabel :: Maybe String
  }

defaultAriaLabelConfig :: AriaLabelConfig
defaultAriaLabelConfig =
  { nodeA11yDescriptionDefault:
      "Press enter or space to select a node. Press delete to remove it and escape to cancel."
  , nodeA11yDescriptionKeyboardDisabled:
      "Press enter or space to select a node. You can then use the arrow keys to move the node around. Press delete to remove it and escape to cancel."
  , nodeA11yDescriptionAriaLiveMessage:
      \{ direction, x, y } ->
        "Moved selected node " <> direction
          <> ". New position, x: "
          <> show x
          <> ", y: "
          <> show y
  , edgeA11yDescriptionDefault:
      "Press enter or space to select an edge. You can then press delete to remove it or escape to cancel."
  , controlsAriaLabel: "Control Panel"
  , controlsZoomInAriaLabel: "Zoom In"
  , controlsZoomOutAriaLabel: "Zoom Out"
  , controlsFitViewAriaLabel: "Fit View"
  , controlsInteractiveAriaLabel: "Toggle Interactivity"
  , minimapAriaLabel: "Mini Map"
  , handleAriaLabel: "Handle"
  }

emptyAriaLabelConfigOverride :: AriaLabelConfigOverride
emptyAriaLabelConfigOverride =
  { nodeA11yDescriptionDefault: Nothing
  , nodeA11yDescriptionKeyboardDisabled: Nothing
  , nodeA11yDescriptionAriaLiveMessage: Nothing
  , edgeA11yDescriptionDefault: Nothing
  , controlsAriaLabel: Nothing
  , controlsZoomInAriaLabel: Nothing
  , controlsZoomOutAriaLabel: Nothing
  , controlsFitViewAriaLabel: Nothing
  , controlsInteractiveAriaLabel: Nothing
  , minimapAriaLabel: Nothing
  , handleAriaLabel: Nothing
  }

mergeAriaLabelConfig :: AriaLabelConfigOverride -> AriaLabelConfig
mergeAriaLabelConfig o =
  { nodeA11yDescriptionDefault:
      fromMaybe defaultAriaLabelConfig.nodeA11yDescriptionDefault
        o.nodeA11yDescriptionDefault
  , nodeA11yDescriptionKeyboardDisabled:
      fromMaybe defaultAriaLabelConfig.nodeA11yDescriptionKeyboardDisabled
        o.nodeA11yDescriptionKeyboardDisabled
  , nodeA11yDescriptionAriaLiveMessage:
      fromMaybe defaultAriaLabelConfig.nodeA11yDescriptionAriaLiveMessage
        o.nodeA11yDescriptionAriaLiveMessage
  , edgeA11yDescriptionDefault:
      fromMaybe defaultAriaLabelConfig.edgeA11yDescriptionDefault
        o.edgeA11yDescriptionDefault
  , controlsAriaLabel:
      fromMaybe defaultAriaLabelConfig.controlsAriaLabel o.controlsAriaLabel
  , controlsZoomInAriaLabel:
      fromMaybe defaultAriaLabelConfig.controlsZoomInAriaLabel
        o.controlsZoomInAriaLabel
  , controlsZoomOutAriaLabel:
      fromMaybe defaultAriaLabelConfig.controlsZoomOutAriaLabel
        o.controlsZoomOutAriaLabel
  , controlsFitViewAriaLabel:
      fromMaybe defaultAriaLabelConfig.controlsFitViewAriaLabel
        o.controlsFitViewAriaLabel
  , controlsInteractiveAriaLabel:
      fromMaybe defaultAriaLabelConfig.controlsInteractiveAriaLabel
        o.controlsInteractiveAriaLabel
  , minimapAriaLabel:
      fromMaybe defaultAriaLabelConfig.minimapAriaLabel o.minimapAriaLabel
  , handleAriaLabel:
      fromMaybe defaultAriaLabelConfig.handleAriaLabel o.handleAriaLabel
  }
