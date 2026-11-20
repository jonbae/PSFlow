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

export const OVERLAYS = [];

export const NOTES = [
  {
    id: 'store-unreadable-members',
    accepted: 'Full JavaScript store compatibility',
    text:
      "`useStoreApi()`'s `getState()` reads back every value written into the store, as upstream's " +
      'does. A boolean, number or string member also holds that value internally, but ps-flow compares ' +
      "it through PureScript's `Ord`, which can answer differently from `Math.min`/`Math.max` for " +
      '`undefined` or `NaN`. A structured member written with a value ps-flow cannot convert, such as ' +
      "`setState({ nodes: 'x' })`, keeps its previous value internally and for readers such as " +
      '`getNodes()`, and development builds warn; upstream stores the value everywhere and fails later. ' +
      'A store callback written as a falsy value other than `null` or `undefined` counts as set.',
  },
  {
    id: 'store-replacement',
    accepted: 'Full JavaScript store compatibility',
    text:
      '`setState(next, true)` makes `getState()` return `next` itself, with its member properties ' +
      'turned into accessors; a sealed `next` is copied instead. A member the replacement left out ' +
      'comes back when its value changes or on `reset`, where upstream also brings back one it rewrites ' +
      'with an unchanged value.',
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
