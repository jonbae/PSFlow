-- | What the store's `debug` logs show of a list of changes. Upstream logs
-- | the array it hands `onNodesChange` or `onEdgesChange`, so each surface
-- | logs the changes as its own callbacks receive them. A PureScript
-- | consumer's callbacks receive the PureScript changes, which the default
-- | logs as they are. The JS surface's `<ReactFlow />` and
-- | `<ReactFlowProvider />` provide the conversion their callbacks apply,
-- | and the store reads it once, when `<ReactFlowProvider />` creates it.
-- |
-- | The context is monomorphic, so each conversion takes the PureScript
-- | array as `Foreign`, as `React.Context.Store` carries `OpaqueStore`.
module React.Context.ChangeLog
  ( ChangeLog
  , changeLogContext
  , changeLogProvider
  , changesAsTheyAre
  , logChanges
  ) where

import Prelude

import Effect (Effect)
import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (JSX, ReactContext, provider)
import React.FFI.React (createContext)

type ChangeLog =
  { nodeChanges :: Foreign -> Foreign
  , edgeChanges :: Foreign -> Foreign
  }

-- | The PureScript surface's: the changes, unconverted.
changesAsTheyAre :: ChangeLog
changesAsTheyAre = { nodeChanges: identity, edgeChanges: identity }

changeLogContext :: ReactContext ChangeLog
changeLogContext = unsafePerformEffect (createContext changesAsTheyAre)

changeLogProvider :: ChangeLog -> Array JSX -> JSX
changeLogProvider = provider changeLogContext

-- | TS `console.log(message, changes)`.
foreign import logChanges :: String -> Foreign -> Effect Unit
