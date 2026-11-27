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
    accepted: 'Store residual parity',
    text:
      "A structured store member written with a value of the wrong shape, such as " +
      "`setState({ nodes: 'x' })`, reads back as written, and ps-flow's internals hold it as written " +
      "and read it where upstream's code reads it, so they fail or go on where upstream's do. Two " +
      'differences remain. An array ps-flow can read only in part, such as `[node, null]`, is held ' +
      "whole, so ps-flow's code reads even its readable items as written values and can fail on one " +
      "where upstream's goes on. And while `nodes` or `edges` holds a written value, ps-flow walks the " +
      'lookups in id order, where upstream walks them in the order they were filled.',
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
