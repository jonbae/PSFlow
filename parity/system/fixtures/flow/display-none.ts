// A flow that is displayed and then is not (#5455).
//
// The row is a warning that should *not* be printed: upstream's resize handler
// asks `checkVisibility()` before it measures, so a container with no box
// because it is hidden is skipped rather than reported as a container with no
// width and height. What is observed is therefore an **absence** in the
// `console` section, which is the only section an absence can be observed in.
//
// It hides *after* mounting rather than starting hidden, and the difference
// matters twice over. A flow that is hidden from the first paint never resolves
// its root, so every action in the scenario is recorded unresolved and the run
// says nothing about anything else; and the resize observer only fires on a
// change, so a box that was never anything but zero is a box that was never
// measured. Mounting first and then hiding is what puts the handler on the path
// the row is about.

import { edges, nodes } from '../shared/graph';

export default {
  flowProps: { fitView: true, nodes: nodes(), edges: edges() },
  afterMount: { style: { display: 'none' } },
};
