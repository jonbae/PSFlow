// A Background given an explicit `bgColor` (#5259 — the CSS variable fallback).
//
// `Background.purs` emits `--xy-background-color-props` inline, so what the row
// is about is text in the `style` attribute of an element the `dom` section
// already records in full. Both a `bgColor` and a `color` are set because the
// fallback the row fixes is between them: one alone leaves the other's variable
// unwritten and the fallback untaken.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: { fitView: true, nodes: nodes(), edges: edges() },
  backgroundProps: { bgColor: '#101820', color: '#7ee787', gap: 24, size: 2, variant: 'dots' },
};
