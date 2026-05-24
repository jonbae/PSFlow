-- | Build-time constants exposed to PureScript. The lone export
-- | (`isDevelopment`) lets dev-only effects (warnings, console.error
-- | spam, sanity assertions) gate cleanly on a value the bundler can
-- | constant-fold via a `define` (esbuild: `--define:IS_DEV=false`,
-- | webpack: `new DefinePlugin({ IS_DEV: false })`). When neither side
-- | configures the flag the JS sidecar falls back to `true`, matching the
-- | TS upstream default where dev-mode warnings fire whenever
-- | `process.env.NODE_ENV === 'development'`.
module React.FFI.Env
  ( isDevelopment
  ) where

foreign import isDevelopment :: Boolean
