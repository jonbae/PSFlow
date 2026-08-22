// Ids the corpus's *other* sources have already been promised.
//
// `tickets/081-interaction-corpus.md` renamed the test-debt ticket's `S1`–`S30`
// to semantic ids and published the table. Those thirty scenarios are the
// corpus's second source and land with the behavioural coverage work (#60);
// until then the names are spoken for, and `gate-pending` will cite them by
// name — it fails when the scenario it names is absent from the corpus.
//
// The hazard is quiet. Several of the conformance seed's transcriptions land
// very close to a reserved scenario: upstream's own "dragging a node" *is*
// `drag-node-release` in outline, and its "connecting two nodes" *is*
// `connect-handle-to-handle`. A seed scenario that took one of those names
// would satisfy the pending gate with a scenario written for a different
// purpose, and the row the name was reserved for would count as driven while
// nothing drove it. So the seed refuses the name and #60 decides, when it gets
// there, whether a seed scenario already covers the row or a new one is needed.
//
// The `S`-numbers stay as a cross-reference, because
// `tickets/080-test-debt-dispositions.md` still reads in them.

export const RESERVED = Object.freeze({
  "drag-node-release": "S1",
  "drag-node-escape-mid-gesture": "S2",
  "drag-node-autopan": "S3",
  "drag-node-no-select-on-drag": "S4",
  "drag-child-expand-parent": "S5",
  "selection-box-from-node": "S6",
  "selection-box-then-click-node": "S7",
  "selection-box-mid-gesture": "S8",
  "arrow-key-selected-node": "S9",
  "flow-props-change-after-mount": "S10",
  "connect-handle-to-handle": "S11",
  "connect-then-keyboard-move": "S12",
  "connect-second-touch-point": "S13",
  "probe-node-connections": "S14",
  "viewport-helpers-with-options": "S15",
  "pan-gesture-complete": "S16",
  "fitview-onnodeschange-variants": "S17",
  "uncontrolled-update-node": "S18",
  "keyboard-focus-node": "S19",
  "minimap-all-nodes-hidden": "S20",
  "minimap-custom-mask-colors": "S21",
  "controls-horizontal": "S22",
  "panel-center-positions": "S23",
  "background-custom-bgcolor": "S24",
  "flow-custom-testid": "S25",
  "custom-edge-baseedge-path": "S26",
  "pinch-over-nowheel-node": "S27",
  "selection-box-touch": "S28",
  "drag-unmeasured-node": "S29",
  "mount-in-display-none": "S30",
});
