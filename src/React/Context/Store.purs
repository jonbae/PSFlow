-- | The `StoreContext` is the conduit that connects every hook
-- | (`useStore`, `useReactFlow`, …) to the single `Store n e` owned by
-- | the root `<ReactFlowProvider />`. Mirrors
-- | `xyflow-main/packages/react/src/contexts/StoreContext.ts`.
-- |
-- | **Polymorphism wart.** `ReactContext` is monomorphic in PureScript
-- | (a `Type`, not a kind), but `Store n e` is polymorphic. We thread an
-- | opaque type `OpaqueStore` through the context and require the
-- | provider / consumer modules to `unsafeCoerce` at the seam exactly
-- | once each. The conversion happens inside `React.Hook.Store` (ticket
-- | 027); this module merely exposes the opaque placeholder.
module React.Context.Store
  ( OpaqueStore
  , storeContext
  , storeProvider
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Unsafe (unsafePerformEffect)
import React.Basic (JSX, ReactContext, provider)
import React.FFI.React (createContext)

-- | Phantom placeholder for `Store n e`. The hook layer casts to/from
-- | this with `unsafeCoerce` at one boundary. No representation, no
-- | runtime presence — it's a tag for the type system only.
foreign import data OpaqueStore :: Type

storeContext :: ReactContext (Maybe OpaqueStore)
storeContext = unsafePerformEffect (createContext Nothing)

-- | The matching provider. Callers in `React.Provider` (ticket 043)
-- | wrap a real `Store n e` and `unsafeCoerce` it into `OpaqueStore`
-- | before passing it here.
storeProvider :: Maybe OpaqueStore -> Array JSX -> JSX
storeProvider value children = provider storeContext value children
