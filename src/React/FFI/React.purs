-- | Centralised FFI hooks into the React runtime. At ticket 025 this
-- | module is minimal — `createContext` is the only entry point the
-- | context modules need. Later tickets extend it with `forwardRef`,
-- | `memo`, `createPortal`, etc. (see ticket 023 §"Requires FFI").
-- |
-- | `react-basic` already exports `createContext`; this module re-exports
-- | the symbol so React.Context.* can import a single, framework-port
-- | seam instead of importing `React.Basic` directly.
module React.FFI.React
  ( module ReexportReactBasic
  ) where

import React.Basic
  ( JSX
  , ReactContext
  , consumer
  , createContext
  , provider
  ) as ReexportReactBasic
