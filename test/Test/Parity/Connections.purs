-- | Live differential parity for `System.Utils.Connections.getConnectionStatus`.
-- | PSFlow returns `Maybe ConnectionStatus`; XYFlow returns `'valid' | 'invalid'
-- | | null`. Both are projected to the same `"valid"/"invalid"/""` string for the
-- | comparison.
module Test.Parity.Connections
  ( runConnectionsParity
  ) where

import Prelude

import Data.Array.NonEmpty as NEA
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (log)
import System.Utils.Connections (ConnectionStatus(..), getConnectionStatus) as PS
import Test.Oracle as Oracle
import Test.Parity.Util (strMatch)
import Test.QuickCheck (quickCheck)
import Test.QuickCheck.Gen (Gen, elements)

csToStr :: Maybe PS.ConnectionStatus -> String
csToStr = case _ of
  Nothing -> ""
  Just PS.ValidConnection -> "valid"
  Just PS.InvalidConnection -> "invalid"

genMaybeBool :: Gen (Maybe Boolean)
genMaybeBool = elements (NEA.cons' (Just true) [ Just false, Nothing ])

runConnectionsParity :: Effect Unit
runConnectionsParity = do
  log "running connections parity properties (PSFlow vs live XYFlow)..."

  quickCheck do
    mb <- genMaybeBool
    pure
      ( strMatch "getConnectionStatus"
          (csToStr (PS.getConnectionStatus mb))
          (Oracle.getConnectionStatus mb)
      )

  log "connections parity passed"
