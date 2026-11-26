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
      "does, and ps-flow's internals use a boolean, number, string or callback member as written, as " +
      "upstream's do. A structured member written with a value ps-flow cannot convert, such as " +
      "`setState({ nodes: 'x' })`, keeps its previous value internally and for readers such as " +
      '`getNodes()`, and development builds warn; upstream stores the value everywhere and fails later.',
  },
  {
    id: 'store-default-view',
    accepted: 'Store residual parity',
    text:
      "Until `setState(next, true)` replaces it, the state `useStoreApi()`'s `getState()` returns holds " +
      "its members as accessor properties, where upstream's holds data properties; each reads and writes " +
      'as upstream\'s does. A key assigned directly to that state that it did not already have stays on ' +
      "that one object: ps-flow's internals do not read it, so a callback assigned that way is not " +
      'called, and later states do not carry it.',
  },
  {
    id: 'styles-warning',
    accepted: 'Step 3 I',
    text:
      'The development warning for missing styles is upstream\'s, word for word, and so names ' +
      '`@xyflow/react/dist/style.css`. ps-flow\'s stylesheets are `ps-flow/dist/style.css` and ' +
      '`ps-flow/dist/base.css`, byte-identical to upstream\'s.',
  },
];
