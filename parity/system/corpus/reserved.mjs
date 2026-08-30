// The register of the thirty test-debt scenario ids.
//
// `tickets/081-interaction-corpus.md` renamed the test-debt ticket's `S1`–`S30`
// to semantic ids and published the table. `test-debt.mjs` writes all thirty
// (#60) and is the **only** source allowed to take one: it checks itself against
// this list in both directions, so a name here that nothing writes and a name
// written that is not here both fail.
//
// This register is half of what makes that citation mean anything (#58). The
// audit fails a row naming a scenario the corpus's **name space** — written ids
// plus these — does not hold, so a reserved id resolves and an invented one does
// not. What is reserved and what is written are counted apart everywhere they
// are reported, and they still are now that the two lists coincide: an id that
// is only reserved promises a scenario and drives nothing, and if one ever
// returns to that state it has to be legible as a promise rather than as
// coverage.
//
// The hazard is quiet. Several of the conformance seed's transcriptions land
// very close to a reserved scenario: upstream's own "dragging a node" *is*
// `drag-node-release` in outline, and its "connecting two nodes" *is*
// `connect-handle-to-handle`. A seed scenario that took one of those names
// would satisfy the pending gate with a scenario written for a different
// purpose, and the row the name was reserved for would count as driven while
// nothing drove it. So the seed refuses these names, and it refuses them
// whether or not #60 has written them yet.
//
// And the register outlives the writing, because it is what a name is checked
// *against*. A scenario deleted from `test-debt.mjs` without its rows being
// re-decided would otherwise stop being written at the same moment it stopped
// being reserved, and its rows would go from resolving to dangling in one
// commit with nothing having said so.
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
