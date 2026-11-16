// Whether ps-flow's development warnings fire. Upstream's gate is
// `process.env.NODE_ENV === 'development'`, which a consumer's bundler
// substitutes and which Node reads from its environment, so this makes the
// same check; the package build leaves `process.env.NODE_ENV` in place for
// that substitution. `IS_DEV`, a bundler-substituted boolean, overrides it
// when it is defined: esbuild's `--define:IS_DEV=false` or webpack's
// DefinePlugin.
export const isDevelopment =
  typeof IS_DEV !== "undefined" ? IS_DEV : process.env.NODE_ENV === "development";
