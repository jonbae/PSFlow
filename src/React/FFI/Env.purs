-- | Build-time constants exposed to PureScript. The lone export
-- | (`isDevelopment`) gates the development warnings: `true` where
-- | upstream's `process.env.NODE_ENV === 'development'` is, unless a bundler
-- | defines `IS_DEV` (esbuild: `--define:IS_DEV=false`, webpack:
-- | `new DefinePlugin({ IS_DEV: false })`), which then decides.
module React.FFI.Env
  ( isDevelopment
  ) where

foreign import isDevelopment :: Boolean
