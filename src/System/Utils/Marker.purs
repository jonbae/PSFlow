-- | SVG marker id helpers. Mirrors `utils/marker.ts`.
-- |
-- | The TS implementation enumerates the keys of an `EdgeMarker` object via
-- | `Object.keys(marker).sort()` and joins `key=value` pairs with `&`. We
-- | replicate that exact ordering and skip-undefined behaviour by walking a
-- | hard-coded alphabetical list of fields.
module System.Utils.Marker
  ( MarkerConfig
  , getMarkerId
  , createMarkerIds
  ) where

import Prelude

import Data.Array (catMaybes, foldl, sortBy) as Array
import Data.Maybe (Maybe(..))
import Data.Number.Format (toString) as NumberFormat
import Data.Set (Set)
import Data.Set (empty, insert, member) as Set
import Data.String (joinWith) as String
import System.Types.Edge
  ( EdgeBase
  , EdgeMarker
  , EdgeMarkerType(..)
  , MarkerProps
  , MarkerType(..)
  )

type MarkerConfig =
  { id :: Maybe String
  , defaultColor :: Maybe String
  , defaultMarkerStart :: Maybe EdgeMarkerType
  , defaultMarkerEnd :: Maybe EdgeMarkerType
  }

showMarkerType :: MarkerType -> String
showMarkerType = case _ of
  Arrow -> "arrow"
  ArrowClosed -> "arrowclosed"

showN :: Number -> String
showN = NumberFormat.toString

-- | Build the `key=value&...` body for a custom marker. Field order matches
-- | `Object.keys().sort()` of the equivalent TS object: alphabetical by key
-- | (`color`, `height`, `markerUnits`, `orient`, `strokeWidth`, `type`,
-- | `width`). Keys whose value is `Nothing` are skipped, matching TS where
-- | `undefined` properties don't appear in `Object.keys`.
encodeMarker :: EdgeMarker -> String
encodeMarker m =
  String.joinWith "&"
    ( Array.catMaybes
        [ map (\v -> "color=" <> v) m.color
        , map (\v -> "height=" <> showN v) m.height
        , map (\v -> "markerUnits=" <> v) m.markerUnits
        , map (\v -> "orient=" <> v) m.orient
        , map (\v -> "strokeWidth=" <> showN v) m.strokeWidth
        , Just ("type=" <> showMarkerType m.markerType)
        , map (\v -> "width=" <> showN v) m.width
        ]
    )

getMarkerId :: Maybe EdgeMarkerType -> Maybe String -> String
getMarkerId marker mid = case marker of
  Nothing -> ""
  Just (NamedMarker s) -> s
  Just (CustomMarker em) ->
    let
      prefix = case mid of
        Just s -> s <> "__"
        Nothing -> ""
    in
      prefix <> encodeMarker em

createMarkerIds
  :: forall e. Array (EdgeBase e) -> MarkerConfig -> Array MarkerProps
createMarkerIds edges cfg =
  Array.sortBy (\a b -> compare a.id b.id)
    ( _.markers
        ( Array.foldl step { ids: Set.empty :: Set String, markers: [] } edges
        )
    )
  where
  step acc edge =
    let
      mStart = case edge.markerStart of
        Just _ -> edge.markerStart
        Nothing -> cfg.defaultMarkerStart
      mEnd = case edge.markerEnd of
        Just _ -> edge.markerEnd
        Nothing -> cfg.defaultMarkerEnd
      acc1 = absorb acc mStart
      acc2 = absorb acc1 mEnd
    in
      acc2

  absorb acc m = case m of
    Just (CustomMarker em) ->
      let
        markerId = getMarkerId (Just (CustomMarker em)) cfg.id
      in
        if Set.member markerId acc.ids then acc
        else
          { ids: Set.insert markerId acc.ids
          , markers: acc.markers <>
              [ { id: markerId
                , markerType: em.markerType
                , color:
                    case em.color of
                      Just c -> Just c
                      Nothing -> cfg.defaultColor
                , width: em.width
                , height: em.height
                , markerUnits: em.markerUnits
                , orient: em.orient
                , strokeWidth: em.strokeWidth
                }
              ]
          }
    _ -> acc
