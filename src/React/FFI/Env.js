// `IS_DEV` is a bundler-substituted boolean. Configure with esbuild's
// `--define:IS_DEV=false` or webpack DefinePlugin to suppress dev-time
// warnings in production builds. When unset, defaults to `true` so the
// PS port matches the TS upstream default (warnings fire unless explicitly
// silenced).
export const isDevelopment = typeof IS_DEV !== "undefined" ? IS_DEV : true;
