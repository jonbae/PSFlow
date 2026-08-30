// The one control the driver renders that is not part of a fixture's flow.
//
// Named here rather than in `src/Flow.tsx` because two sides of the harness
// need the same string and neither can import the other's: the driver is `.tsx`
// compiled by esbuild into a bundle, and the corpus is `.mjs` run by node. A
// scenario that spelled the id out would go on resolving to nothing the day the
// driver renamed it — recorded as an unresolved action, which reads as a
// divergence in the library rather than as a corpus that has gone stale.

/**
 * `data-testid` of the button that applies a fixture's `afterMount` props.
 *
 * Rendered only for a fixture that declares them, `position: fixed` and outside
 * `<ReactFlow>`, so it is in no `dom` section and displaces no layout.
 */
export const AFTER_MOUNT = "psflow-after-mount";
