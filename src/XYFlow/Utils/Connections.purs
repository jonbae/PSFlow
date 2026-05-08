module XYFlow.Utils.Connections
  ( ConnectionStatus(..)
  , areConnectionMapsEqual
  , handleConnectionChange
  , getConnectionStatus
  ) where

import Prelude

import Data.Array (fromFoldable, null) as Array
import Data.Generic.Rep (class Generic)
import Data.Map (Map)
import Data.Map (difference, keys, size, values) as Map
import Data.Maybe (Maybe(..))
import Data.Show.Generic (genericShow)
import Effect (Effect)
import XYFlow.Types.Connection (HandleConnection)

data ConnectionStatus
  = ValidConnection
  | InvalidConnection

derive instance eqConnectionStatus :: Eq ConnectionStatus
derive instance ordConnectionStatus :: Ord ConnectionStatus
derive instance genericConnectionStatus :: Generic ConnectionStatus _

instance showConnectionStatus :: Show ConnectionStatus where
  show = genericShow

areConnectionMapsEqual
  :: Maybe (Map String HandleConnection)
  -> Maybe (Map String HandleConnection)
  -> Boolean
areConnectionMapsEqual ma mb = case ma, mb of
  Nothing, Nothing -> true
  Just a, Just b -> Map.size a == Map.size b && Map.keys a == Map.keys b
  _, _ -> false

handleConnectionChange
  :: Map String HandleConnection
  -> Map String HandleConnection
  -> Maybe (Array HandleConnection -> Effect Unit)
  -> Effect Unit
handleConnectionChange a b = case _ of
  Nothing -> pure unit
  Just cb ->
    let
      diff = Array.fromFoldable (Map.values (Map.difference a b))
    in
      if Array.null diff then pure unit else cb diff

getConnectionStatus :: Maybe Boolean -> Maybe ConnectionStatus
getConnectionStatus = case _ of
  Nothing -> Nothing
  Just true -> Just ValidConnection
  Just false -> Just InvalidConnection
