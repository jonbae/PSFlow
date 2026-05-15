-- | The `NodeIdContext` carries the current node's id down to descendant
-- | components so that primitives like `<Handle />` can resolve "which
-- | node am I inside?" without a prop drill. Mirrors
-- | `xyflow-main/packages/react/src/contexts/NodeIdContext.ts`.
module React.Context.NodeId
  ( nodeIdContext
  , useNodeId
  , nodeIdProvider
  ) where


import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactContext, provider)
import React.Basic.Hooks (Hook, UseContext, useContext)
import React.FFI.React (createContext)

-- | Module-level context value. Created exactly once via
-- | `unsafePerformEffect` — `React.createContext` is referentially
-- | transparent for this purpose, and any other approach would force
-- | every consumer hook into `Effect` for no benefit. Matches the
-- | convention used by `react-basic-hooks`'s own examples.
nodeIdContext :: ReactContext (Maybe String)
nodeIdContext = unsafePerformEffect (createContext Nothing)

useNodeId :: Hook (UseContext (Maybe String)) (Maybe String)
useNodeId = useContext nodeIdContext

-- | Wraps `children` in a `<NodeIdContext.Provider value={id}>`. The TS
-- | source uses JSX directly; this is the PS equivalent helper.
nodeIdProvider :: Maybe String -> Array JSX -> JSX
nodeIdProvider value children = provider nodeIdContext value children
