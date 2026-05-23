-- | `<EdgeToolbar />` — anchored at a midpoint of an edge, rendered
-- | through `EdgeLabelRenderer`. Mirrors `xyflow-main/.../EdgeToolbar/EdgeToolbar.tsx`.
module React.Additional.EdgeToolbar
  ( edgeToolbar
  , module React.Types.Component
  ) where

import Prelude

import Data.Map (lookup) as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (class Newtype)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object as Object
import React.Basic (ReactComponent, element)
import React.Basic.Hooks (UnsafeReference(..), reactChildrenFromArray, reactChildrenToArray, reactComponentWithChildren)
import React.Basic.Hooks as React
import React.FFI.DOM (div_)
import React.Hook.Store (useStore)
import React.Portal.EdgeLabelRenderer (edgeLabelRenderer)
import React.Types.Component (EdgeToolbarProps)
import React.Types.Edges (Edge)
import React.Types.Store (ReactFlowState)
import System.Types.Edge (AlignX(..), AlignY(..))
import System.Types.Geometry (Transform(..))
import System.Utils.Toolbar (getEdgeToolbarTransform)
import Unsafe.Coerce (unsafeCoerce)

toForeignStyle :: Object String -> Foreign
toForeignStyle = unsafeCoerce

newtype EtSlice e = EtSlice
  { edge :: UnsafeReference (Maybe (Edge e))
  , zoom :: Number
  }

derive instance newtypeEtSlice :: Newtype (EtSlice e) _
derive newtype instance eqEtSlice :: Eq (EtSlice e)

selectorFor :: forall e n. String -> ReactFlowState n e -> EtSlice e
selectorFor edgeId s =
  let Transform t = s.transform
  in EtSlice
    { edge: UnsafeReference (Map.lookup edgeId s.edgeLookup)
    , zoom: t.scale
    }

edgeToolbar :: ReactComponent EdgeToolbarProps
edgeToolbar =
  unsafePerformEffect $ reactComponentWithChildren "EdgeToolbar"
    \(props :: EdgeToolbarProps) -> React.do
      EtSlice slice <- useStore (selectorFor props.edgeId)
      let
        UnsafeReference mEdge = slice.edge
        isActive = case props.isVisible of
          Just b -> b
          Nothing -> case mEdge of
            Just e -> e.selected
            Nothing -> false
      if not isActive then pure mempty
      else
        let
          alignX = fromMaybe AlignXCenter props.alignX
          alignY = fromMaybe AlignYCenter props.alignY
          transformStr = getEdgeToolbarTransform props.x props.y slice.zoom alignX alignY
          baseZIndex = case mEdge of
            Just e -> fromMaybe 0 e.zIndex
            Nothing -> 0
          zIndex = baseZIndex + 1
          userClass = fromMaybe "" props.className
          className = "react-flow__edge-toolbar"
            <> (if userClass == "" then "" else " " <> userClass)
          baseStyle = fromMaybe Object.empty props.style
          wrapperStyle = baseStyle
            # Object.insert "position" "absolute"
            # Object.insert "transform" transformStr
            # Object.insert "zIndex" (show zIndex)
            # Object.insert "pointerEvents" "all"
            # Object.insert "transformOrigin" "0 0"
          dataId = case mEdge of
            Just e -> e.id
            Nothing -> ""
          toolbarDiv = div_
            { style: toForeignStyle wrapperStyle
            , className
            , "data-id": dataId
            }
            (reactChildrenToArray props.children)
        in
          pure $ element edgeLabelRenderer
            { children: reactChildrenFromArray [ toolbarDiv ]
            }
