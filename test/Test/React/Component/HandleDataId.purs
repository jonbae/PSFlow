-- | Which `data-id` and `data-handleid` a `<Handle />` renders.
-- |
-- | The local proxy for the map's "null handle id composing as `""` where
-- | upstream gives `"null"`" entry on
-- | [Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93).
-- | Upstream's `<Handle />` starts from `const handleId = id || null`, and
-- | writes `data-id={`${rfId}-${nodeId}-${handleId}-${type}`}`, so a handle
-- | with no id, or an empty one, has the `data-id` `1-a-null-source` and no
-- | `data-handleid`. ps-flow wrote `1-a--source`, while its own
-- | `System.XYHandle.handleSelector` looks for `1-a-null-source`, so a
-- | connection never found an id-less handle by its selector. It also kept
-- | an empty id as an id.
-- |
-- | The expected attributes are what a server render of upstream's own
-- | `<Handle />` writes for the same three handles.
module Test.React.Component.HandleDataId
  ( runHandleDataIdTests
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Data.Nullable (null)
import Data.String (Pattern(..), contains)
import Effect (Effect)
import Effect.Class.Console (log)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (JSX, element)
import React.Context.NodeId (nodeIdProvider)
import React.Context.Store (OpaqueStore, storeProvider)
import React.Handle (handle)
import React.Store.InitialState (InitialStateOptions, defaultInitialStateOptions)
import React.Store.Shell (Store, createStore)
import System.Types.Geometry (Position(..))
import System.Types.Handle (HandleType(..))
import Unsafe.Coerce (unsafeCoerce)

foreign import renderMarkup :: JSX -> Effect String

assert :: String -> Boolean -> Effect Unit
assert label cond =
  if cond then log ("ok  " <> label)
  else unsafeCrashWith ("FAIL " <> label)

storeToOpaque :: Store Unit Unit -> OpaqueStore
storeToOpaque = unsafeCoerce

-- | A handle with `id` on node `a`, rendered in a flow whose `rfId` is `1`.
renderHandle :: HandleType -> Maybe String -> Effect String
renderHandle handleType id = do
  store <- createStore (defaultInitialStateOptions :: InitialStateOptions Unit Unit)
  renderMarkup
    ( storeProvider (Just (storeToOpaque store))
        [ nodeIdProvider (Just "a")
            [ element handle
                { handleType
                , position: PosRight
                , id
                , isConnectable: Nothing
                , isConnectableStart: Nothing
                , isConnectableEnd: Nothing
                , onConnect: Nothing
                , isValidConnection: Nothing
                , className: Nothing
                , style: Nothing
                , innerRef: null
                }
            ]
        ]
    )

has :: String -> String -> Boolean
has needle = contains (Pattern needle)

runHandleDataIdTests :: Effect Unit
runHandleDataIdTests = do
  log "\n=== Handle: a missing id is written as null, as upstream writes it ==="

  noId <- renderHandle Source Nothing
  assert "a handle with no id has the data-id upstream's selector looks for"
    (has "data-id=\"1-a-null-source\"" noId)
  assert "a handle with no id has no data-handleid"
    (not (has "data-handleid" noId))

  emptyId <- renderHandle Source (Just "")
  assert "a handle with an empty id has the data-id of one with no id"
    (has "data-id=\"1-a-null-source\"" emptyId)
  assert "a handle with an empty id has no data-handleid"
    (not (has "data-handleid" emptyId))

  withId <- renderHandle Target (Just "h")
  assert "a handle with an id writes it in both attributes"
    (has "data-id=\"1-a-h-target\"" withId && has "data-handleid=\"h\"" withId)
