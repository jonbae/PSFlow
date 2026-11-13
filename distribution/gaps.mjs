// Where ps-flow's JavaScript surface knowingly differs from upstream's, as the
// published declarations state it.
//
// ps-flow publishes upstream's declarations, generated from the vendored
// source. Two kinds of entry change what they say:
//
//   * An **overlay** edits one generated file: `find` must occur exactly once
//     in it, or the build fails. Like a region in `parity/system/regions.json`,
//     an overlay that stops matching is stale, and the build says so rather
//     than publishing upstream's text unchanged. Use an overlay only where the
//     difference has a place in a type or its documentation.
//   * A **note** is written into the header of `dist/index.d.ts`, so a
//     consumer reading the declarations reads every difference in one place.
//     A difference with an overlay has a note too, which points at it.
//
// Every entry names the work that accepted it. Removing a difference removes
// its entry in the same change.

export const OVERLAYS = [
  {
    id: 'store-replace',
    accepted: 'Step 3 G, precise exclusions',
    file: 'react/hooks/useStore.d.ts',
    find: 'replace?: boolean | undefined) => void;',
    replace: 'replace?: false | undefined) => void;',
    reason:
      "ps-flow's `setState` merges into the state and throws on `replace: true`: its internals read a " +
      'complete state record, which a replacement could leave incomplete.',
  },
  {
    id: 'store-exclusions',
    accepted: 'Step 3 G, precise exclusions',
    file: 'react/hooks/useStore.d.ts',
    find: ' * such as {@link useReactFlow}, {@link useViewport}, etc.\n */\ndeclare function useStoreApi',
    replace: [
      ' * such as {@link useReactFlow}, {@link useViewport}, etc.',
      ' *',
      ' * ps-flow: `setState` merges as zustand does and throws on `replace: true`. It also throws',
      ' * when a write gives a member a value outside its declared type, when a write supplies a',
      ' * `panZoom`, `fitViewResolver` or middleware map that the store did not hand out, and when',
      ' * a consumer calls a store callback that PureScript code installed.',
      ' */',
      'declare function useStoreApi',
    ].join('\n'),
    reason: "The exclusions a type cannot express, on the hook that hands out the store.",
  },
];

export const NOTES = [
  {
    id: 'store-writes',
    accepted: 'Step 3 G, precise exclusions',
    text:
      "`useStoreApi()`'s `setState` merges and refuses `replace: true`, which its type says. Its " +
      'documentation lists the other writes ps-flow refuses.',
  },
  {
    id: 'default-edge-options-keys',
    accepted: 'Step 3 H, precise exclusions',
    text:
      '`defaultEdgeOptions` merges the 23 members `DefaultEdgeOptions` declares. Upstream spreads ' +
      'every key at run time, so a key outside the type, such as `pathOptions`, reaches upstream\'s ' +
      'edges and not ps-flow\'s.',
  },
  {
    id: 'uncontrolled-rebuilt-nodes',
    accepted: 'Step 3 H, precise exclusions',
    text:
      'In an uncontrolled flow, a node that ps-flow\'s own `applyNodeChanges` rebuilt has no ' +
      'consumer object behind it. A later handler receives the members ps-flow models, without ' +
      'keys the consumer added outside them.',
  },
  {
    id: 'styles-warning',
    accepted: 'Step 3 I',
    text:
      'The development warning for missing styles is upstream\'s, word for word, and so names ' +
      '`@xyflow/react/dist/style.css`. ps-flow\'s stylesheets are `ps-flow/dist/style.css` and ' +
      '`ps-flow/dist/base.css`, byte-identical to upstream\'s.',
  },
  {
    id: 'module-formats',
    accepted: 'Step 3 I',
    text:
      'ps-flow is published as one ES module. Upstream also publishes a UMD build for `require` ' +
      'and a browser global; ps-flow has neither. Node versions that load ES modules through ' +
      '`require` can still `require("ps-flow")`.',
  },
];
