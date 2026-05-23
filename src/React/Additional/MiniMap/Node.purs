-- | `<MiniMapNode />` — the per-node SVG rect inside the minimap.
-- | Mirrors `xyflow-main/.../MiniMap/MiniMapNode.tsx`.
module React.Additional.MiniMap.Node
  ( miniMapNode
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object as Object
import React.Basic (ReactComponent)
import React.Basic.Events (handler, handler_, syntheticEvent)
import React.Basic.Hooks (memo, reactComponent)
import React.FFI.DOM (rect_)
import React.Types.Component (MiniMapNodeProps)
import Unsafe.Coerce (unsafeCoerce)
import Web.UIEvent.MouseEvent (MouseEvent)

toForeignStyle :: Object String -> Foreign
toForeignStyle = unsafeCoerce

pickFill :: Maybe String -> Maybe (Object String) -> Maybe String
pickFill color style = case color of
  Just c -> Just c
  Nothing -> case style of
    Nothing -> Nothing
    Just s -> case Object.lookup "background" s of
      Just b -> Just b
      Nothing -> Object.lookup "backgroundColor" s

miniMapNode :: ReactComponent MiniMapNodeProps
miniMapNode =
  unsafePerformEffect $ memo $ reactComponent "MiniMapNode"
    \(props :: MiniMapNodeProps) ->
      let
        baseClass = "react-flow__minimap-node"
          <> (if props.selected then " selected" else "")
          <> (if props.className == "" then "" else " " <> props.className)
        styleObj = Object.empty
          # maybeInsert "fill" (pickFill props.color props.style)
          # maybeInsert "stroke" props.strokeColor
          # maybeInsert "strokeWidth" (map show props.strokeWidth)
        onClickHandler = case props.onClick of
          Nothing -> handler_ (pure unit)
          Just cb -> handler syntheticEvent \e ->
            cb (unsafeCoerce e :: MouseEvent) props.id
      in
        pure $ rect_
          { className: baseClass
          , x: props.x
          , y: props.y
          , rx: props.borderRadius
          , ry: props.borderRadius
          , width: props.width
          , height: props.height
          , style: toForeignStyle styleObj
          , shapeRendering: props.shapeRendering
          , onClick: onClickHandler
          }
          []

maybeInsert :: String -> Maybe String -> Object String -> Object String
maybeInsert k mv obj = case mv of
  Nothing -> obj
  Just v -> Object.insert k v obj
