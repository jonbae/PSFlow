# System parity

The dual-run net over 103 scenario(s), against vendored `@xyflow/react` 12.11.0.

Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice.

**103 of 103 scenario(s) failed.**

A failing net is the expected state while the divergence backlog is being worked: the scenarios below
are recording what the two implementations actually do, and a difference is fixed in the port or
claimed by a region — never by loosening what the net looks at.

| scenario | verdict | failure classes | differences |
|---|---|---|---|
| `mount-baseline--edges-general` | **failed** | unclaimed-difference | 28 |
| `mount-baseline--node-toolbar-general` | **failed** | unclaimed-difference | 13 |
| `mount-baseline--nodes-general` | **failed** | unclaimed-difference | 6 |
| `mount-baseline--pane-general` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--pane-non-defaults` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--chrome-background` | **failed** | unclaimed-difference | 5 |
| `mount-baseline--chrome-controls` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--chrome-minimap-colors` | **failed** | unclaimed-difference | 4 |
| `mount-baseline--chrome-minimap-hidden-nodes` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--chrome-panels` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--edges-base-edge-path` | **failed** | driving-divergence, unclaimed-difference | 64 |
| `mount-baseline--fitview-uncontrolled` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--flow-chrome-defaults` | **failed** | unclaimed-difference | 4 |
| `mount-baseline--flow-custom-testid` | **failed** | unclaimed-difference | 4 |
| `mount-baseline--flow-display-none` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--flow-limits-change` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--flow-not-selectable` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--flow-props-change` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--nodes-autopan` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-connections` | **failed** | unclaimed-difference | 14 |
| `mount-baseline--nodes-expand-parent` | **failed** | unclaimed-difference | 9 |
| `mount-baseline--nodes-no-select-on-drag` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--nodes-nowheel` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-props-record` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--nodes-tall` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-unmeasured` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--viewport-controlled` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--viewport-helpers` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--viewport-pan-on-scroll` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--examples-color-mode` | **failed** | unclaimed-difference | 3 |
| `click-selects-edge` | **failed** | unclaimed-difference | 28 |
| `multi-select-edges-with-modifier` | **failed** | unclaimed-difference | 28 |
| `click-unselectable-edge` | **failed** | unclaimed-difference | 28 |
| `delete-key-removes-edge` | **failed** | unclaimed-difference | 31 |
| `delete-key-spares-undeletable-edge` | **failed** | unclaimed-difference | 29 |
| `click-inside-interaction-width` | **failed** | unclaimed-difference | 28 |
| `click-selects-node` | **failed** | unclaimed-difference | 6 |
| `shift-drag-selects-nodes` | **failed** | unclaimed-difference | 13 |
| `click-unselectable-node` | **failed** | unclaimed-difference | 6 |
| `drag-moves-node` | **failed** | unclaimed-difference | 6 |
| `drag-does-not-move-undraggable-node` | **failed** | unclaimed-difference | 6 |
| `drag-by-custom-drag-handle` | **failed** | unclaimed-difference | 6 |
| `delete-key-removes-node-and-edges` | **failed** | unclaimed-difference | 22 |
| `delete-key-spares-undeletable-node` | **failed** | unclaimed-difference | 7 |
| `connect-source-handle-to-target-handle` | **failed** | unclaimed-difference | 41 |
| `connect-output-to-output-handle` | **failed** | unclaimed-difference | 41 |
| `connect-input-to-input-handle` | **failed** | unclaimed-difference | 40 |
| `connect-to-unconnectable-handle` | **failed** | unclaimed-difference | 41 |
| `drag-pans-the-pane` | **failed** | unclaimed-difference | 3 |
| `wheel-zooms-the-pane` | **failed** | unclaimed-difference | 3 |
| `wheel-zooms-out-to-min` | **failed** | unclaimed-difference | 3 |
| `wheel-zooms-in-to-max` | **failed** | unclaimed-difference | 3 |
| `wheel-pans-with-panonscroll` | **failed** | unclaimed-difference | 2 |
| `click-reveals-default-toolbar` | **failed** | unclaimed-difference | 13 |
| `select-dark-color-mode` | **failed** | unclaimed-difference | 3 |
| `drag-node-release` | **failed** | unclaimed-difference | 36 |
| `drag-node-escape-mid-gesture` | **failed** | unclaimed-difference | 23 |
| `drag-node-autopan` | **failed** | self-inconsistent, unclaimed-difference | 226 |
| `drag-node-no-select-on-drag` | **failed** | unclaimed-difference | 3 |
| `drag-child-expand-parent` | **failed** | unclaimed-difference | 9 |
| `drag-unmeasured-node` | **failed** | unclaimed-difference | 8 |
| `selection-box-from-node` | **failed** | unclaimed-difference | 6 |
| `selection-box-then-click-node` | **failed** | unclaimed-difference | 18 |
| `selection-box-mid-gesture` | **failed** | unclaimed-difference | 3 |
| `selection-box-touch` | **failed** | unclaimed-difference | 30 |
| `arrow-key-selected-node` | **failed** | self-inconsistent, unclaimed-difference | 34 |
| `keyboard-focus-node` | **failed** | unclaimed-difference | 2 |
| `connect-handle-to-handle` | **failed** | unclaimed-difference | 72 |
| `connect-then-keyboard-move` | **failed** | unclaimed-difference | 38 |
| `connect-second-touch-point` | **failed** | unclaimed-difference | 14 |
| `probe-node-connections` | **failed** | unclaimed-difference | 47 |
| `viewport-helpers-with-options` | **failed** | unclaimed-difference | 3 |
| `pan-gesture-complete` | **failed** | unclaimed-difference | 3 |
| `fitview-onnodeschange-variants` | **failed** | unclaimed-difference | 5 |
| `uncontrolled-update-node` | **failed** | unclaimed-difference | 3 |
| `flow-props-change-after-mount` | **failed** | unclaimed-difference | 3 |
| `mount-in-display-none` | **failed** | unclaimed-difference | 4 |
| `minimap-all-nodes-hidden` | **failed** | unclaimed-difference | 2 |
| `minimap-custom-mask-colors` | **failed** | unclaimed-difference | 4 |
| `controls-horizontal` | **failed** | unclaimed-difference | 3 |
| `panel-center-positions` | **failed** | unclaimed-difference | 3 |
| `background-custom-bgcolor` | **failed** | unclaimed-difference | 5 |
| `flow-custom-testid` | **failed** | driving-divergence, unclaimed-difference | 26 |
| `custom-edge-baseedge-path` | **failed** | driving-divergence, unclaimed-difference | 89 |
| `pinch-over-nowheel-node` | **failed** | unclaimed-difference | 2 |
| `minimap-default-click` | **failed** | unclaimed-difference | 4 |
| `controls-default-zoom` | **failed** | unclaimed-difference | 4 |
| `wheel-zoom-from-identity-viewport` | **failed** | unclaimed-difference | 4 |
| `pane-drag-from-identity-viewport` | **failed** | unclaimed-difference | 4 |
| `drag-node-reports-changes` | **failed** | self-inconsistent, unclaimed-difference | 154 |
| `click-connect-reverse-direction` | **failed** | unclaimed-difference | 35 |
| `connect-drag-holding-source` | **failed** | unclaimed-difference | 35 |
| `connect-drag-released-on-pane` | **failed** | unclaimed-difference | 37 |
| `node-props-record-parented` | **failed** | unclaimed-difference | 4 |
| `wheel-zooms-to-changed-limits` | **failed** | unclaimed-difference | 4 |
| `drag-pans-into-changed-extent` | **failed** | unclaimed-difference | 2 |
| `pan-after-controlled-viewport-change` | **failed** | unclaimed-difference | 3 |
| `ctrl-wheel-pinches-with-panonscroll` | **failed** | unclaimed-difference | 2 |
| `pane-click-keeps-selection-when-not-selectable` | **failed** | unclaimed-difference | 3 |
| `click-selects-node--probe-flow-node` | **failed** | unclaimed-difference | 29 |
| `wheel-zooms-the-pane--probe-flow-node` | **failed** | unclaimed-difference | 26 |
| `mount-baseline--edges-general--probe-edge` | **failed** | unclaimed-difference | 4 |
| `connect-source-handle-to-target-handle--probe-connection-line` | **failed** | unclaimed-difference | 6 |

Every trace behind this report is on disk under `parity/system/traces` — four per scenario, two sides captured
twice each. They are the artifact: re-diffing them costs seconds and no browser.

---

# System parity run — mount-baseline--edges-general

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--edges-general

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 28 unclaimed difference(s).

## Unclaimed differences

### callbacks (26)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |
| `callbacks/4/args/0/1/id` | differs | 2 | 10 |
| `callbacks/4/args/0/2/id` | differs | 3 | 11 |
| `callbacks/4/args/0/3/id` | differs | 4 | 12 |
| `callbacks/4/args/0/3/dimensions/width` | differs | 150 | 200 |
| `callbacks/4/args/0/3/dimensions/height` | differs | 37 | 100 |
| `callbacks/4/args/0/4/id` | differs | 5 | 12-a |
| `callbacks/4/args/0/4/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/4/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/5/id` | differs | 6 | 12-b |
| `callbacks/4/args/0/5/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/5/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/6/id` | differs | 7 | 2 |
| `callbacks/4/args/0/7/id` | differs | 8 | 3 |
| `callbacks/4/args/0/8/id` | differs | 9 | 4 |
| `callbacks/4/args/0/9/id` | differs | 10 | 5 |
| `callbacks/4/args/0/10/id` | differs | 11 | 6 |
| `callbacks/4/args/0/11/id` | differs | 12 | 7 |
| `callbacks/4/args/0/11/dimensions/width` | differs | 200 | 150 |
| `callbacks/4/args/0/11/dimensions/height` | differs | 100 | 37 |
| `callbacks/4/args/0/12/id` | differs | 12-a | 8 |
| `callbacks/4/args/0/12/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/12/dimensions/height` | differs | 50 | 37 |
| `callbacks/4/args/0/13/id` | differs | 12-b | 9 |
| `callbacks/4/args/0/13/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/13/dimensions/height` | differs | 50 | 37 |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--node-toolbar-general

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--node-toolbar-general

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 13 unclaimed difference(s).

## Unclaimed differences

### callbacks (12)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |
| `callbacks/4/args/0/1/id` | differs | node-start-top | node-center-bottom |
| `callbacks/4/args/0/2/id` | differs | node-center-top | node-center-left |
| `callbacks/4/args/0/3/id` | differs | node-end-top | node-center-right |
| `callbacks/4/args/0/4/id` | differs | node-start-right | node-center-top |
| `callbacks/4/args/0/5/id` | differs | node-center-right | node-end-bottom |
| `callbacks/4/args/0/6/id` | differs | node-end-right | node-end-left |
| `callbacks/4/args/0/7/id` | differs | node-start-bottom | node-end-right |
| `callbacks/4/args/0/8/id` | differs | node-center-bottom | node-end-top |
| `callbacks/4/args/0/9/id` | differs | node-end-bottom | node-start-bottom |
| `callbacks/4/args/0/11/id` | differs | node-center-left | node-start-right |
| `callbacks/4/args/0/12/id` | differs | node-end-left | node-start-top |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"default-node","type":"ToolbarNode","data":{"label":"toolbar top","toolbarPosition":"top"},"position":{"x":0,"y":-200},"className":"react-flow__node-defa… | — |


---

# System parity run — mount-baseline--nodes-general

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--nodes-general

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 6 unclaimed difference(s).

## Unclaimed differences

### callbacks (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |


---

# System parity run — mount-baseline--pane-general

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--pane-general

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--pane-non-defaults

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--pane-non-defaults

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--chrome-background

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--chrome-background

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 5 unclaimed difference(s).

## Unclaimed differences

### dom (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"10","y":"27","width":"48","height":"48","patternUnits":"userSpaceOnUse","patternTransform":"translate(-25,-25)"… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"10","y":"27","width":"48","height":"48","patternUnits":"userSpaceOnUse","p… |

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--chrome-controls

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--chrome-controls

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--chrome-minimap-colors

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--chrome-minimap-colors

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[1]/children/svg[0]/children/path[0]/attrs/d` | differs | M-277,-153.5h704v544h-704z⏎        M-245,-61.5h640v360h-640z | M-277,-153.5h704v544h-704z M-245,-61.5h640v360h-640z |

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--chrome-minimap-hidden-nodes

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--chrome-minimap-hidden-nodes

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[1]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-184h1408v1088h-1408z⏎        M0,0h1280v720h-1280z | M-64,-184h1408v1088h-1408z M0,0h1280v720h-1280z |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","hidden":true} | — |


---

# System parity run — mount-baseline--chrome-panels

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--chrome-panels

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--edges-base-edge-path

**Failed:** driving-divergence, unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--edges-base-edge-path

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 driving divergence(s), 61 unclaimed difference(s).

**The inputs differed.** The driving log records what was done *to* each side — the target, whether
it resolved, the box it resolved to — and it does not agree. Selectors resolve against each side's
own render, so the pointer follows a divergence: two sides that place a node five pixels apart both
drag successfully while the two runs were not one experiment. Until the log agrees, every section
below it is a **consequence of the driving divergence**. None of them is suppressed —
a real divergence is exactly what would be hiding down there.

## Unclaimed differences

### driving (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `driving/0/resolved` | differs | true | false |
| `driving/0/box` | differs | {"x":0,"y":0,"width":1280,"height":720} | null |
| `driving/0/dispatched` | differs | {"route":"/tests/generic/edges/base-edge-path"} | null |

### dom (1) — consequence of the driving divergence

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root` | differs | {"tag":"div","attrs":{"data-testid":"rf__wrapper","class":"light react-flow","role":"application","style":"height: 100%; overflow: hidden; position: relative; … | null |

### callbacks (1) — consequence of the driving divergence

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (52) — consequence of the driving divergence

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |
| `api/queries/getNodes/1` | left only | {"id":"Node-2","data":{"label":"Node-2"},"position":{"x":-140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/getNodes/2` | left only | {"id":"Node-3","data":{"label":"Node-3"},"position":{"x":140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/getNode/id` | left only | Node-1 | — |
| `api/queries/getNode/data` | left only | {"label":"Node-1"} | — |
| `api/queries/getNode/position` | left only | {"x":0,"y":0} | — |
| `api/queries/getNode/type` | left only | input | — |
| `api/queries/getNode/measured` | left only | {"width":150,"height":37} | — |
| `api/queries/getNode/@undefined` | right only | — | true |
| `api/queries/getInternalNode/id` | left only | Node-1 | — |
| `api/queries/getInternalNode/data` | left only | {"label":"Node-1"} | — |
| `api/queries/getInternalNode/position` | left only | {"x":0,"y":0} | — |
| `api/queries/getInternalNode/type` | left only | input | — |
| `api/queries/getInternalNode/measured` | left only | {"width":150,"height":37} | — |
| `api/queries/getInternalNode/internals` | left only | {"positionAbsolute":{"x":0,"y":0},"handleBounds":{"source":[{"id":null,"type":"source","nodeId":"Node-1","position":"bottom","x":71,"y":32,"width":8,"height":8… | — |
| `api/queries/getInternalNode/@undefined` | right only | — | true |
| `api/queries/getEdges/0` | left only | {"id":"custom-1","type":"pathAttributes","source":"Node-1","target":"Node-2"} | — |
| `api/queries/getEdges/1` | left only | {"id":"custom-2","type":"pathAttributes","source":"Node-1","target":"Node-3","label":"custom"} | — |
| `api/queries/getEdges/2` | left only | {"id":"default-1","type":"default","source":"Node-2","target":"Node-3"} | — |
| `api/queries/getEdge/id` | left only | custom-1 | — |
| `api/queries/getEdge/type` | left only | pathAttributes | — |
| `api/queries/getEdge/source` | left only | Node-1 | — |
| `api/queries/getEdge/target` | left only | Node-2 | — |
| `api/queries/getEdge/@undefined` | right only | — | true |
| `api/queries/getIntersectingNodes/0` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |
| `api/queries/getIntersectingNodes/1` | left only | {"id":"Node-2","data":{"label":"Node-2"},"position":{"x":-140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/getIntersectingNodes/2` | left only | {"id":"Node-3","data":{"label":"Node-3"},"position":{"x":140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/isNodeIntersecting` | differs | true | false |
| `api/queries/getNodesBounds/x` | differs | -140 | 0 |
| `api/queries/getNodesBounds/width` | differs | 430 | 0 |
| `api/queries/getNodesBounds/height` | differs | 177 | 0 |
| `api/queries/getHandleConnections/0` | left only | {"edgeId":"custom-1","source":"Node-1","target":"Node-2","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/getHandleConnections/1` | left only | {"edgeId":"custom-2","source":"Node-1","target":"Node-3","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/getNodeConnections/0` | left only | {"edgeId":"custom-1","source":"Node-1","target":"Node-2","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/getNodeConnections/1` | left only | {"edgeId":"custom-2","source":"Node-1","target":"Node-3","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/toObject/nodes/0` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |
| `api/queries/toObject/nodes/1` | left only | {"id":"Node-2","data":{"label":"Node-2"},"position":{"x":-140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/toObject/nodes/2` | left only | {"id":"Node-3","data":{"label":"Node-3"},"position":{"x":140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/toObject/edges/0` | left only | {"id":"custom-1","type":"pathAttributes","source":"Node-1","target":"Node-2"} | — |
| `api/queries/toObject/edges/1` | left only | {"id":"custom-2","type":"pathAttributes","source":"Node-1","target":"Node-3","label":"custom"} | — |
| `api/queries/toObject/edges/2` | left only | {"id":"default-1","type":"default","source":"Node-2","target":"Node-3"} | — |
| `api/queries/toObject/viewport/x` | differs | 490 | 0 |
| `api/queries/toObject/viewport/y` | differs | 183 | 0 |
| `api/queries/toObject/viewport/zoom` | differs | 2 | 1 |
| `api/queries/getZoom` | differs | 2 | 1 |
| `api/queries/getViewport/x` | differs | 490 | 0 |
| `api/queries/getViewport/y` | differs | 183 | 0 |
| `api/queries/getViewport/zoom` | differs | 2 | 1 |
| `api/queries/screenToFlowPosition/x` | differs | -245 | 0 |
| `api/queries/screenToFlowPosition/y` | differs | -91.5 | 0 |
| `api/queries/flowToScreenPosition/x` | differs | 490 | 0 |
| `api/queries/flowToScreenPosition/y` | differs | 183 | 0 |

### console (7) — consequence of the driving divergence

| path | kind | upstream | psflow |
|---|---|---|---|
| `console/1` | right only | — | {"level":"pageerror","text":"Failed pattern match at System.Utils.Edges.SmoothStep (line 39, column 19 - line 43, column 34): String"} |
| `console/2` | right only | — | {"level":"pageerror","text":"Failed pattern match at System.Utils.Edges.SmoothStep (line 39, column 19 - line 43, column 34): String"} |
| `console/3` | right only | — | {"level":"pageerror","text":"Failed pattern match at System.Utils.Edges.SmoothStep (line 39, column 19 - line 43, column 34): String"} |
| `console/4` | right only | — | {"level":"pageerror","text":"Failed pattern match at System.Utils.Edges.SmoothStep (line 39, column 19 - line 43, column 34): String"} |
| `console/5` | right only | — | {"level":"error","text":"The above error occurred in the <PathAttributeEdge> component:\n\n    at PathAttributeEdge (http://127.0.0.1:56822/parity/driver/dist/… |
| `console/6` | right only | — | {"level":"error","text":"The above error occurred in the <PathAttributeEdge> component:\n\n    at PathAttributeEdge (http://127.0.0.1:56822/parity/driver/dist/… |
| `console/7` | right only | — | {"level":"pageerror","text":"Failed pattern match at System.Utils.Edges.SmoothStep (line 39, column 19 - line 43, column 34): String"} |


---

# System parity run — mount-baseline--fitview-uncontrolled

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--fitview-uncontrolled

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--flow-chrome-defaults

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--flow-chrome-defaults

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-184h1408v1088h-1408z⏎        M0,0h1280v720h-1280z | M-64,-184h1408v1088h-1408z M0,0h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"0","width":"20","height":"20","patternUnits":"userSpaceOnUse","patternTransform":"translate(-11,-11)"},… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"0","width":"20","height":"20","patternUnits":"userSpaceOnUse","pat… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |


---

# System parity run — mount-baseline--flow-custom-testid

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--flow-custom-testid

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/attrs/data-testid` | differs | psflow-custom-flow | rf__wrapper |

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--flow-display-none

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--flow-display-none

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--flow-limits-change

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--flow-limits-change

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--flow-not-selectable

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--flow-not-selectable

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","selected":true,"measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--flow-props-change

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--flow-props-change

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--nodes-autopan

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--nodes-autopan

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--nodes-connections

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--nodes-connections

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 14 unclaimed difference(s).

## Unclaimed differences

### callbacks (13)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |
| `callbacks/4/args/0/0/id` | differs | hub | down-1 |
| `callbacks/4/args/0/0/dimensions/width` | differs | 24 | 49 |
| `callbacks/4/args/0/1/id` | differs | up-1 | down-2 |
| `callbacks/4/args/0/1/dimensions/width` | differs | 29 | 49 |
| `callbacks/4/args/0/2/id` | differs | up-2 | down-3 |
| `callbacks/4/args/0/2/dimensions/width` | differs | 29 | 49 |
| `callbacks/4/args/0/3/id` | differs | down-1 | hub |
| `callbacks/4/args/0/3/dimensions/width` | differs | 49 | 24 |
| `callbacks/4/args/0/4/id` | differs | down-2 | up-1 |
| `callbacks/4/args/0/4/dimensions/width` | differs | 49 | 29 |
| `callbacks/4/args/0/5/id` | differs | down-3 | up-2 |
| `callbacks/4/args/0/5/dimensions/width` | differs | 49 | 29 |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"hub","type":"connections","data":{"label":"hub"},"position":{"x":160,"y":160},"measured":{"width":24,"height":18}} | — |


---

# System parity run — mount-baseline--nodes-expand-parent

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--nodes-expand-parent

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 9 unclaimed difference(s).

## Unclaimed differences

### callbacks (8)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |
| `callbacks/4/args/0/0/id` | differs | parent | child |
| `callbacks/4/args/0/0/dimensions/width` | differs | 320 | 150 |
| `callbacks/4/args/0/0/dimensions/height` | differs | 220 | 37 |
| `callbacks/4/args/0/1/id` | differs | child | outside |
| `callbacks/4/args/0/2/id` | differs | outside | parent |
| `callbacks/4/args/0/2/dimensions/width` | differs | 150 | 320 |
| `callbacks/4/args/0/2/dimensions/height` | differs | 37 | 220 |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"parent","data":{"label":"parent"},"position":{"x":0,"y":0},"style":{"width":320,"height":220,"backgroundColor":"rgba(80, 120, 200, 0.12)"},"measured":{"… | — |


---

# System parity run — mount-baseline--nodes-no-select-on-drag

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--nodes-no-select-on-drag

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--nodes-nowheel

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--nodes-nowheel

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"nowheel","data":{"label":"nowheel"},"position":{"x":0,"y":0},"className":"nowheel","style":{"width":400,"height":320},"measured":{"width":400,"height":3… | — |


---

# System parity run — mount-baseline--nodes-props-record

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--nodes-props-record

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### api (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"props-parent","type":"propsRecord","data":{"label":"props-parent"},"position":{"x":100,"y":200},"width":300,"height":200,"measured":{"width":300,"height… | — |


---

# System parity run — mount-baseline--nodes-tall

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--nodes-tall

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--nodes-unmeasured

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--nodes-unmeasured

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","selected":true,"measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--viewport-controlled

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--viewport-controlled

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--viewport-helpers

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--viewport-helpers

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--viewport-pan-on-scroll

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--viewport-pan-on-scroll

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — mount-baseline--examples-color-mode

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--examples-color-mode

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### dom (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[1]/children/svg[0]/children/path[0]/attrs/d` | differs | M-161.65853658536585,-110.96341463414635h723.3170731707318v558.9268292682927h-723.3170731707318z⏎        M-128.78048780487805,-16.439024390243905h657.560975609… | M-161.65853658536585,-110.96341463414635h723.3170731707318v558.9268292682927h-723.3170731707318z M-128.78048780487805,-16.439024390243905h657.5609756097562v369… |
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"17.091988130563806","y":"32","width":"38.931750741839764","height":"38.931750741839764","patternUnits":"userSpa… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"17.091988130563806","y":"32","width":"38.931750741839764","height":"38.931… |


---

# System parity run — click-selects-edge

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — click-selects-edge

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 28 unclaimed difference(s).

## Unclaimed differences

### callbacks (26)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/1/id` | differs | 2 | 10 |
| `callbacks/4/args/0/2/id` | differs | 3 | 11 |
| `callbacks/4/args/0/3/id` | differs | 4 | 12 |
| `callbacks/4/args/0/3/dimensions/width` | differs | 150 | 200 |
| `callbacks/4/args/0/3/dimensions/height` | differs | 37 | 100 |
| `callbacks/4/args/0/4/id` | differs | 5 | 12-a |
| `callbacks/4/args/0/4/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/4/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/5/id` | differs | 6 | 12-b |
| `callbacks/4/args/0/5/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/5/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/6/id` | differs | 7 | 2 |
| `callbacks/4/args/0/7/id` | differs | 8 | 3 |
| `callbacks/4/args/0/8/id` | differs | 9 | 4 |
| `callbacks/4/args/0/9/id` | differs | 10 | 5 |
| `callbacks/4/args/0/10/id` | differs | 11 | 6 |
| `callbacks/4/args/0/11/id` | differs | 12 | 7 |
| `callbacks/4/args/0/11/dimensions/width` | differs | 200 | 150 |
| `callbacks/4/args/0/11/dimensions/height` | differs | 100 | 37 |
| `callbacks/4/args/0/12/id` | differs | 12-a | 8 |
| `callbacks/4/args/0/12/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/12/dimensions/height` | differs | 50 | 37 |
| `callbacks/4/args/0/13/id` | differs | 12-b | 9 |
| `callbacks/4/args/0/13/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/13/dimensions/height` | differs | 50 | 37 |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — multi-select-edges-with-modifier

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — multi-select-edges-with-modifier

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 28 unclaimed difference(s).

## Unclaimed differences

### callbacks (26)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/1/id` | differs | 2 | 10 |
| `callbacks/4/args/0/2/id` | differs | 3 | 11 |
| `callbacks/4/args/0/3/id` | differs | 4 | 12 |
| `callbacks/4/args/0/3/dimensions/width` | differs | 150 | 200 |
| `callbacks/4/args/0/3/dimensions/height` | differs | 37 | 100 |
| `callbacks/4/args/0/4/id` | differs | 5 | 12-a |
| `callbacks/4/args/0/4/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/4/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/5/id` | differs | 6 | 12-b |
| `callbacks/4/args/0/5/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/5/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/6/id` | differs | 7 | 2 |
| `callbacks/4/args/0/7/id` | differs | 8 | 3 |
| `callbacks/4/args/0/8/id` | differs | 9 | 4 |
| `callbacks/4/args/0/9/id` | differs | 10 | 5 |
| `callbacks/4/args/0/10/id` | differs | 11 | 6 |
| `callbacks/4/args/0/11/id` | differs | 12 | 7 |
| `callbacks/4/args/0/11/dimensions/width` | differs | 200 | 150 |
| `callbacks/4/args/0/11/dimensions/height` | differs | 100 | 37 |
| `callbacks/4/args/0/12/id` | differs | 12-a | 8 |
| `callbacks/4/args/0/12/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/12/dimensions/height` | differs | 50 | 37 |
| `callbacks/4/args/0/13/id` | differs | 12-b | 9 |
| `callbacks/4/args/0/13/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/13/dimensions/height` | differs | 50 | 37 |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

20 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (10) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — click-unselectable-edge

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — click-unselectable-edge

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 28 unclaimed difference(s).

## Unclaimed differences

### callbacks (26)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/1/id` | differs | 2 | 10 |
| `callbacks/4/args/0/2/id` | differs | 3 | 11 |
| `callbacks/4/args/0/3/id` | differs | 4 | 12 |
| `callbacks/4/args/0/3/dimensions/width` | differs | 150 | 200 |
| `callbacks/4/args/0/3/dimensions/height` | differs | 37 | 100 |
| `callbacks/4/args/0/4/id` | differs | 5 | 12-a |
| `callbacks/4/args/0/4/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/4/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/5/id` | differs | 6 | 12-b |
| `callbacks/4/args/0/5/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/5/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/6/id` | differs | 7 | 2 |
| `callbacks/4/args/0/7/id` | differs | 8 | 3 |
| `callbacks/4/args/0/8/id` | differs | 9 | 4 |
| `callbacks/4/args/0/9/id` | differs | 10 | 5 |
| `callbacks/4/args/0/10/id` | differs | 11 | 6 |
| `callbacks/4/args/0/11/id` | differs | 12 | 7 |
| `callbacks/4/args/0/11/dimensions/width` | differs | 200 | 150 |
| `callbacks/4/args/0/11/dimensions/height` | differs | 100 | 37 |
| `callbacks/4/args/0/12/id` | differs | 12-a | 8 |
| `callbacks/4/args/0/12/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/12/dimensions/height` | differs | 50 | 37 |
| `callbacks/4/args/0/13/id` | differs | 12-b | 9 |
| `callbacks/4/args/0/13/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/13/dimensions/height` | differs | 50 | 37 |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — delete-key-removes-edge

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — delete-key-removes-edge

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 31 unclaimed difference(s).

## Unclaimed differences

### callbacks (29)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/13` | left only | {"name":"onBeforeDelete","args":[{"nodes":[],"edges":[{"id":"edge-with-class","source":"1","target":"2","className":"edge-class-test","selected":true}]}]} | — |
| `callbacks/14` | left only | {"name":"onEdgesDelete","args":[[{"id":"edge-with-class","source":"1","target":"2","className":"edge-class-test","selected":true}]]} | — |
| `callbacks/16` | left only | {"name":"onDelete","args":[{"nodes":[],"edges":[{"id":"edge-with-class","source":"1","target":"2","className":"edge-class-test","selected":true}]}]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/1/id` | differs | 2 | 10 |
| `callbacks/4/args/0/2/id` | differs | 3 | 11 |
| `callbacks/4/args/0/3/id` | differs | 4 | 12 |
| `callbacks/4/args/0/3/dimensions/width` | differs | 150 | 200 |
| `callbacks/4/args/0/3/dimensions/height` | differs | 37 | 100 |
| `callbacks/4/args/0/4/id` | differs | 5 | 12-a |
| `callbacks/4/args/0/4/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/4/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/5/id` | differs | 6 | 12-b |
| `callbacks/4/args/0/5/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/5/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/6/id` | differs | 7 | 2 |
| `callbacks/4/args/0/7/id` | differs | 8 | 3 |
| `callbacks/4/args/0/8/id` | differs | 9 | 4 |
| `callbacks/4/args/0/9/id` | differs | 10 | 5 |
| `callbacks/4/args/0/10/id` | differs | 11 | 6 |
| `callbacks/4/args/0/11/id` | differs | 12 | 7 |
| `callbacks/4/args/0/11/dimensions/width` | differs | 200 | 150 |
| `callbacks/4/args/0/11/dimensions/height` | differs | 100 | 37 |
| `callbacks/4/args/0/12/id` | differs | 12-a | 8 |
| `callbacks/4/args/0/12/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/12/dimensions/height` | differs | 50 | 37 |
| `callbacks/4/args/0/13/id` | differs | 12-b | 9 |
| `callbacks/4/args/0/13/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/13/dimensions/height` | differs | 50 | 37 |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

12 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (7) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — delete-key-spares-undeletable-edge

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — delete-key-spares-undeletable-edge

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 29 unclaimed difference(s).

## Unclaimed differences

### callbacks (27)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/13` | left only | {"name":"onBeforeDelete","args":[{"nodes":[],"edges":[]}]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/1/id` | differs | 2 | 10 |
| `callbacks/4/args/0/2/id` | differs | 3 | 11 |
| `callbacks/4/args/0/3/id` | differs | 4 | 12 |
| `callbacks/4/args/0/3/dimensions/width` | differs | 150 | 200 |
| `callbacks/4/args/0/3/dimensions/height` | differs | 37 | 100 |
| `callbacks/4/args/0/4/id` | differs | 5 | 12-a |
| `callbacks/4/args/0/4/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/4/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/5/id` | differs | 6 | 12-b |
| `callbacks/4/args/0/5/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/5/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/6/id` | differs | 7 | 2 |
| `callbacks/4/args/0/7/id` | differs | 8 | 3 |
| `callbacks/4/args/0/8/id` | differs | 9 | 4 |
| `callbacks/4/args/0/9/id` | differs | 10 | 5 |
| `callbacks/4/args/0/10/id` | differs | 11 | 6 |
| `callbacks/4/args/0/11/id` | differs | 12 | 7 |
| `callbacks/4/args/0/11/dimensions/width` | differs | 200 | 150 |
| `callbacks/4/args/0/11/dimensions/height` | differs | 100 | 37 |
| `callbacks/4/args/0/12/id` | differs | 12-a | 8 |
| `callbacks/4/args/0/12/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/12/dimensions/height` | differs | 50 | 37 |
| `callbacks/4/args/0/13/id` | differs | 12-b | 9 |
| `callbacks/4/args/0/13/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/13/dimensions/height` | differs | 50 | 37 |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — click-inside-interaction-width

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — click-inside-interaction-width

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 28 unclaimed difference(s).

## Unclaimed differences

### callbacks (26)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/1/id` | differs | 2 | 10 |
| `callbacks/4/args/0/2/id` | differs | 3 | 11 |
| `callbacks/4/args/0/3/id` | differs | 4 | 12 |
| `callbacks/4/args/0/3/dimensions/width` | differs | 150 | 200 |
| `callbacks/4/args/0/3/dimensions/height` | differs | 37 | 100 |
| `callbacks/4/args/0/4/id` | differs | 5 | 12-a |
| `callbacks/4/args/0/4/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/4/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/5/id` | differs | 6 | 12-b |
| `callbacks/4/args/0/5/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/5/dimensions/height` | differs | 37 | 50 |
| `callbacks/4/args/0/6/id` | differs | 7 | 2 |
| `callbacks/4/args/0/7/id` | differs | 8 | 3 |
| `callbacks/4/args/0/8/id` | differs | 9 | 4 |
| `callbacks/4/args/0/9/id` | differs | 10 | 5 |
| `callbacks/4/args/0/10/id` | differs | 11 | 6 |
| `callbacks/4/args/0/11/id` | differs | 12 | 7 |
| `callbacks/4/args/0/11/dimensions/width` | differs | 200 | 150 |
| `callbacks/4/args/0/11/dimensions/height` | differs | 100 | 37 |
| `callbacks/4/args/0/12/id` | differs | 12-a | 8 |
| `callbacks/4/args/0/12/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/12/dimensions/height` | differs | 50 | 37 |
| `callbacks/4/args/0/13/id` | differs | 12-b | 9 |
| `callbacks/4/args/0/13/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/13/dimensions/height` | differs | 50 | 37 |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — click-selects-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — click-selects-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 6 unclaimed difference(s).

## Unclaimed differences

### callbacks (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — shift-drag-selects-nodes

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — shift-drag-selects-nodes

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 13 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[1]/children/div[0]/attrs/style` | left only | height: 137px; width: 350px; | — |

### callbacks (10)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/10` | left only | {"name":"onSelectionChange","args":[{"nodes":[{"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-cla… | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onSelectionStart#1","onNodesChange#2","onEdgesChange#1"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onSelectionStart#1","onNodesChange#2","onEdgesChange#1"… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |
| `callbacks/9/args/0/nodes/0/selected` | right only | — | true |
| `callbacks/9/args/0/nodes/1/selected` | right only | — | true |
| `callbacks/9/args/0/nodes/2/selected` | right only | — | true |
| `callbacks/9/args/0/edges/0` | right only | — | {"id":"1-2","type":"default","source":"Node-1","target":"Node-2","selected":true,"label":"edge"} |
| `callbacks/9/args/0/edges/1` | right only | — | {"id":"1-3","type":"default","source":"Node-1","target":"Node-3","selected":true,"label":"edge"} |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

4 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (3) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — click-unselectable-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — click-unselectable-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 6 unclaimed difference(s).

## Unclaimed differences

### callbacks (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-moves-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — drag-moves-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 6 unclaimed difference(s).

## Unclaimed differences

### callbacks (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":194.2073170731707,"y":194.2073170731707},"type":"input","className":"playwright-test-class-123","style… | — |

## Normalization

30 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (15) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-does-not-move-undraggable-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — drag-does-not-move-undraggable-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 6 unclaimed difference(s).

## Unclaimed differences

### callbacks (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

22 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (11) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-by-custom-drag-handle

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — drag-by-custom-drag-handle

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 6 unclaimed difference(s).

## Unclaimed differences

### callbacks (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

44 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (22) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — delete-key-removes-node-and-edges

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — delete-key-removes-node-and-edges

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 22 unclaimed difference(s).

## Unclaimed differences

### callbacks (9)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/15` | left only | {"name":"onBeforeDelete","args":[{"nodes":[{"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-… | — |
| `callbacks/16` | left only | {"name":"onEdgesDelete","args":[[{"id":"1-2","type":"default","source":"Node-1","target":"Node-2","label":"edge"},{"id":"1-3","type":"default","source":"Node-1… | — |
| `callbacks/17` | left only | {"name":"onEdgesChange","args":[[{"id":"1-2","type":"remove"},{"id":"1-3","type":"remove"}]]} | — |
| `callbacks/18` | left only | {"name":"onNodesDelete","args":[[{"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","styl… | — |
| `callbacks/20` | left only | {"name":"onDelete","args":[{"nodes":[{"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","… | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |

### api (13)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-2","type":"output","data":{"label":"Node-2"},"position":{"x":-100,"y":100},"measured":{"width":150,"height":37}} | — |
| `api/queries/getEdges/0` | right only | — | {"id":"1-2","type":"default","source":"Node-1","target":"Node-2","label":"edge"} |
| `api/queries/getEdges/1` | right only | — | {"id":"1-3","type":"default","source":"Node-1","target":"Node-3","label":"edge"} |
| `api/queries/getEdge/@undefined` | left only | true | — |
| `api/queries/getEdge/id` | right only | — | 1-2 |
| `api/queries/getEdge/type` | right only | — | default |
| `api/queries/getEdge/source` | right only | — | Node-1 |
| `api/queries/getEdge/target` | right only | — | Node-2 |
| `api/queries/getEdge/label` | right only | — | edge |
| `api/queries/getNodeConnections/0` | right only | — | {"edgeId":"1-2","source":"Node-1","target":"Node-2","sourceHandle":null,"targetHandle":null} |
| `api/queries/toObject/edges/0` | right only | — | {"id":"1-2","type":"default","source":"Node-1","target":"Node-2","label":"edge"} |
| `api/queries/toObject/edges/1` | right only | — | {"id":"1-3","type":"default","source":"Node-1","target":"Node-3","label":"edge"} |

## Normalization

12 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (7) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — delete-key-spares-undeletable-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — delete-key-spares-undeletable-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 7 unclaimed difference(s).

## Unclaimed differences

### callbacks (5)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/15` | left only | {"name":"onBeforeDelete","args":[{"nodes":[],"edges":[]}]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — connect-source-handle-to-target-handle

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — connect-source-handle-to-target-handle

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 41 unclaimed difference(s).

## Unclaimed differences

### callbacks (39)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |
| `callbacks/14/args/0/@class` | differs | MouseEvent | SyntheticBaseEvent |
| `callbacks/14/args/0/_reactName` | right only | — | onMouseDown |
| `callbacks/14/args/0/_targetInst` | right only | — | null |
| `callbacks/14/args/0/type` | right only | — | mousedown |
| `callbacks/14/args/0/nativeEvent` | right only | — | {"@class":"MouseEvent","isTrusted":true} |
| `callbacks/14/args/0/target` | right only | — | {"@ref":"DIV"} |
| `callbacks/14/args/0/currentTarget` | right only | — | null |
| `callbacks/14/args/0/eventPhase` | right only | — | 3 |
| `callbacks/14/args/0/bubbles` | right only | — | true |
| `callbacks/14/args/0/cancelable` | right only | — | true |
| `callbacks/14/args/0/defaultPrevented` | right only | — | false |
| `callbacks/14/args/0/view` | right only | — | {"@ref":"Window"} |
| `callbacks/14/args/0/detail` | right only | — | 1 |
| `callbacks/14/args/0/screenX` | right only | — | 614 |
| `callbacks/14/args/0/screenY` | right only | — | 69 |
| `callbacks/14/args/0/clientX` | right only | — | 614 |
| `callbacks/14/args/0/clientY` | right only | — | 69 |
| `callbacks/14/args/0/pageX` | right only | — | 614 |
| `callbacks/14/args/0/pageY` | right only | — | 69 |
| `callbacks/14/args/0/ctrlKey` | right only | — | false |
| `callbacks/14/args/0/shiftKey` | right only | — | false |
| `callbacks/14/args/0/altKey` | right only | — | false |
| `callbacks/14/args/0/metaKey` | right only | — | false |
| `callbacks/14/args/0/getModifierState` | right only | — | {"@ref":"function"} |
| `callbacks/14/args/0/button` | right only | — | 0 |
| `callbacks/14/args/0/buttons` | right only | — | 1 |
| `callbacks/14/args/0/relatedTarget` | right only | — | null |
| `callbacks/14/args/0/movementX` | right only | — | 0 |
| `callbacks/14/args/0/movementY` | right only | — | 0 |
| `callbacks/14/args/0/isDefaultPrevented` | right only | — | {"@ref":"function"} |
| `callbacks/14/args/0/isPropagationStopped` | right only | — | {"@ref":"function"} |
| `callbacks/21/args/1/fromNode/internals/handleBounds/target` | differs | null | [] |
| `callbacks/21/args/1/fromNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |
| `callbacks/21/args/1/toNode/internals/handleBounds/source` | differs | null | [] |
| `callbacks/21/args/1/toNode/internals/userNode` | left only | {"id":"Node-4","data":{"label":"Node-4"},"position":{"x":0,"y":200},"type":"output","measured":{"width":150,"height":37}} | — |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

25 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (13) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — connect-output-to-output-handle

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — connect-output-to-output-handle

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 41 unclaimed difference(s).

## Unclaimed differences

### callbacks (39)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |
| `callbacks/12/args/0/@class` | differs | MouseEvent | SyntheticBaseEvent |
| `callbacks/12/args/0/_reactName` | right only | — | onMouseDown |
| `callbacks/12/args/0/_targetInst` | right only | — | null |
| `callbacks/12/args/0/type` | right only | — | mousedown |
| `callbacks/12/args/0/nativeEvent` | right only | — | {"@class":"MouseEvent","isTrusted":true} |
| `callbacks/12/args/0/target` | right only | — | {"@ref":"DIV"} |
| `callbacks/12/args/0/currentTarget` | right only | — | null |
| `callbacks/12/args/0/eventPhase` | right only | — | 3 |
| `callbacks/12/args/0/bubbles` | right only | — | true |
| `callbacks/12/args/0/cancelable` | right only | — | true |
| `callbacks/12/args/0/defaultPrevented` | right only | — | false |
| `callbacks/12/args/0/view` | right only | — | {"@ref":"Window"} |
| `callbacks/12/args/0/detail` | right only | — | 1 |
| `callbacks/12/args/0/screenX` | right only | — | 511 |
| `callbacks/12/args/0/screenY` | right only | — | 136 |
| `callbacks/12/args/0/clientX` | right only | — | 511 |
| `callbacks/12/args/0/clientY` | right only | — | 136 |
| `callbacks/12/args/0/pageX` | right only | — | 511 |
| `callbacks/12/args/0/pageY` | right only | — | 136 |
| `callbacks/12/args/0/ctrlKey` | right only | — | false |
| `callbacks/12/args/0/shiftKey` | right only | — | false |
| `callbacks/12/args/0/altKey` | right only | — | false |
| `callbacks/12/args/0/metaKey` | right only | — | false |
| `callbacks/12/args/0/getModifierState` | right only | — | {"@ref":"function"} |
| `callbacks/12/args/0/button` | right only | — | 0 |
| `callbacks/12/args/0/buttons` | right only | — | 1 |
| `callbacks/12/args/0/relatedTarget` | right only | — | null |
| `callbacks/12/args/0/movementX` | right only | — | 0 |
| `callbacks/12/args/0/movementY` | right only | — | 0 |
| `callbacks/12/args/0/isDefaultPrevented` | right only | — | {"@ref":"function"} |
| `callbacks/12/args/0/isPropagationStopped` | right only | — | {"@ref":"function"} |
| `callbacks/15/args/1/fromNode/internals/handleBounds/source` | differs | null | [] |
| `callbacks/15/args/1/fromNode/internals/userNode` | left only | {"id":"Node-2","type":"output","data":{"label":"Node-2"},"position":{"x":-100,"y":100},"measured":{"width":150,"height":37}} | — |
| `callbacks/15/args/1/toNode/internals/handleBounds/source` | differs | null | [] |
| `callbacks/15/args/1/toNode/internals/userNode` | left only | {"id":"Node-4","data":{"label":"Node-4"},"position":{"x":0,"y":200},"type":"output","measured":{"width":150,"height":37}} | — |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

21 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (11) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — connect-input-to-input-handle

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — connect-input-to-input-handle

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 40 unclaimed difference(s).

## Unclaimed differences

### callbacks (38)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |
| `callbacks/14/args/0/@class` | differs | MouseEvent | SyntheticBaseEvent |
| `callbacks/14/args/0/_reactName` | right only | — | onMouseDown |
| `callbacks/14/args/0/_targetInst` | right only | — | null |
| `callbacks/14/args/0/type` | right only | — | mousedown |
| `callbacks/14/args/0/nativeEvent` | right only | — | {"@class":"MouseEvent","isTrusted":true} |
| `callbacks/14/args/0/target` | right only | — | {"@ref":"DIV"} |
| `callbacks/14/args/0/currentTarget` | right only | — | null |
| `callbacks/14/args/0/eventPhase` | right only | — | 3 |
| `callbacks/14/args/0/bubbles` | right only | — | true |
| `callbacks/14/args/0/cancelable` | right only | — | true |
| `callbacks/14/args/0/defaultPrevented` | right only | — | false |
| `callbacks/14/args/0/view` | right only | — | {"@ref":"Window"} |
| `callbacks/14/args/0/detail` | right only | — | 1 |
| `callbacks/14/args/0/screenX` | right only | — | 614 |
| `callbacks/14/args/0/screenY` | right only | — | 69 |
| `callbacks/14/args/0/clientX` | right only | — | 614 |
| `callbacks/14/args/0/clientY` | right only | — | 69 |
| `callbacks/14/args/0/pageX` | right only | — | 614 |
| `callbacks/14/args/0/pageY` | right only | — | 69 |
| `callbacks/14/args/0/ctrlKey` | right only | — | false |
| `callbacks/14/args/0/shiftKey` | right only | — | false |
| `callbacks/14/args/0/altKey` | right only | — | false |
| `callbacks/14/args/0/metaKey` | right only | — | false |
| `callbacks/14/args/0/getModifierState` | right only | — | {"@ref":"function"} |
| `callbacks/14/args/0/button` | right only | — | 0 |
| `callbacks/14/args/0/buttons` | right only | — | 1 |
| `callbacks/14/args/0/relatedTarget` | right only | — | null |
| `callbacks/14/args/0/movementX` | right only | — | 0 |
| `callbacks/14/args/0/movementY` | right only | — | 0 |
| `callbacks/14/args/0/isDefaultPrevented` | right only | — | {"@ref":"function"} |
| `callbacks/14/args/0/isPropagationStopped` | right only | — | {"@ref":"function"} |
| `callbacks/19/args/1/fromNode/internals/handleBounds/target` | differs | null | [] |
| `callbacks/19/args/1/fromNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |
| `callbacks/19/args/1/toNode/internals/userNode` | left only | {"id":"Node-3","data":{"label":"Node-3"},"position":{"x":100,"y":100},"measured":{"width":150,"height":37}} | — |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

25 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (13) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — connect-to-unconnectable-handle

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — connect-to-unconnectable-handle

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 41 unclaimed difference(s).

## Unclaimed differences

### callbacks (39)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |
| `callbacks/14/args/0/@class` | differs | MouseEvent | SyntheticBaseEvent |
| `callbacks/14/args/0/_reactName` | right only | — | onMouseDown |
| `callbacks/14/args/0/_targetInst` | right only | — | null |
| `callbacks/14/args/0/type` | right only | — | mousedown |
| `callbacks/14/args/0/nativeEvent` | right only | — | {"@class":"MouseEvent","isTrusted":true} |
| `callbacks/14/args/0/target` | right only | — | {"@ref":"DIV"} |
| `callbacks/14/args/0/currentTarget` | right only | — | null |
| `callbacks/14/args/0/eventPhase` | right only | — | 3 |
| `callbacks/14/args/0/bubbles` | right only | — | true |
| `callbacks/14/args/0/cancelable` | right only | — | true |
| `callbacks/14/args/0/defaultPrevented` | right only | — | false |
| `callbacks/14/args/0/view` | right only | — | {"@ref":"Window"} |
| `callbacks/14/args/0/detail` | right only | — | 1 |
| `callbacks/14/args/0/screenX` | right only | — | 614 |
| `callbacks/14/args/0/screenY` | right only | — | 69 |
| `callbacks/14/args/0/clientX` | right only | — | 614 |
| `callbacks/14/args/0/clientY` | right only | — | 69 |
| `callbacks/14/args/0/pageX` | right only | — | 614 |
| `callbacks/14/args/0/pageY` | right only | — | 69 |
| `callbacks/14/args/0/ctrlKey` | right only | — | false |
| `callbacks/14/args/0/shiftKey` | right only | — | false |
| `callbacks/14/args/0/altKey` | right only | — | false |
| `callbacks/14/args/0/metaKey` | right only | — | false |
| `callbacks/14/args/0/getModifierState` | right only | — | {"@ref":"function"} |
| `callbacks/14/args/0/button` | right only | — | 0 |
| `callbacks/14/args/0/buttons` | right only | — | 1 |
| `callbacks/14/args/0/relatedTarget` | right only | — | null |
| `callbacks/14/args/0/movementX` | right only | — | 0 |
| `callbacks/14/args/0/movementY` | right only | — | 0 |
| `callbacks/14/args/0/isDefaultPrevented` | right only | — | {"@ref":"function"} |
| `callbacks/14/args/0/isPropagationStopped` | right only | — | {"@ref":"function"} |
| `callbacks/17/args/1/fromNode/internals/handleBounds/target` | differs | null | [] |
| `callbacks/17/args/1/fromNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |
| `callbacks/17/args/1/toNode/internals/handleBounds/source` | differs | null | [] |
| `callbacks/17/args/1/toNode/internals/userNode` | left only | {"id":"notConnectable","type":"output","data":{"label":"notConnectable"},"position":{"x":0,"y":300},"connectable":false,"measured":{"width":150,"height":37}} | — |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

23 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (12) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-pans-the-pane

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — drag-pans-the-pane

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

6 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (3) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — wheel-zooms-the-pane

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — wheel-zooms-the-pane

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

4 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (2) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — wheel-zooms-out-to-min

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — wheel-zooms-out-to-min

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

4 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (2) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — wheel-zooms-in-to-max

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — wheel-zooms-in-to-max

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

4 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (2) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — wheel-pans-with-panonscroll

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — wheel-pans-with-panonscroll

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

4 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (2) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — click-reveals-default-toolbar

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — click-reveals-default-toolbar

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 13 unclaimed difference(s).

## Unclaimed differences

### callbacks (12)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/1/id` | differs | node-start-top | node-center-bottom |
| `callbacks/4/args/0/2/id` | differs | node-center-top | node-center-left |
| `callbacks/4/args/0/3/id` | differs | node-end-top | node-center-right |
| `callbacks/4/args/0/4/id` | differs | node-start-right | node-center-top |
| `callbacks/4/args/0/5/id` | differs | node-center-right | node-end-bottom |
| `callbacks/4/args/0/6/id` | differs | node-end-right | node-end-left |
| `callbacks/4/args/0/7/id` | differs | node-start-bottom | node-end-right |
| `callbacks/4/args/0/8/id` | differs | node-center-bottom | node-end-top |
| `callbacks/4/args/0/9/id` | differs | node-end-bottom | node-start-bottom |
| `callbacks/4/args/0/11/id` | differs | node-center-left | node-start-right |
| `callbacks/4/args/0/12/id` | differs | node-end-left | node-start-top |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"default-node","type":"ToolbarNode","data":{"label":"toolbar top","toolbarPosition":"top"},"position":{"x":0,"y":-200},"className":"react-flow__node-defa… | — |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — select-dark-color-mode

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — select-dark-color-mode

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### dom (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[1]/children/svg[0]/children/path[0]/attrs/d` | differs | M-161.65853658536585,-110.96341463414635h723.3170731707318v558.9268292682927h-723.3170731707318z⏎        M-128.78048780487805,-16.439024390243905h657.560975609… | M-161.65853658536585,-110.96341463414635h723.3170731707318v558.9268292682927h-723.3170731707318z M-128.78048780487805,-16.439024390243905h657.5609756097562v369… |
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"17.091988130563806","y":"32","width":"38.931750741839764","height":"38.931750741839764","patternUnits":"userSpa… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"17.091988130563806","y":"32","width":"38.931750741839764","height":"38.931… |


---

# System parity run — drag-node-release

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — drag-node-release

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 36 unclaimed difference(s).

## Unclaimed differences

### dom (6)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[0]/attrs/d` | differs | M133.2621951219512,78.84146341463415 C133.2621951219512,87.92073170731707 -25,87.92073170731707 -25,97 | M133.2621951219512,78.84146341463415 C133.2621951219512,126.76219512195122 91.52439024390242,126.76219512195122 91.52439024390242,174.6829268292683 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[1]/attrs/d` | differs | M133.2621951219512,78.84146341463415 C133.2621951219512,87.92073170731707 -25,87.92073170731707 -25,97 | M133.2621951219512,78.84146341463415 C133.2621951219512,126.76219512195122 91.52439024390242,126.76219512195122 91.52439024390242,174.6829268292683 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/g[0]/attrs/transform` | differs | translate(44.490082508180194 82.58003060410662) | translate(102.7522776301314 121.42149401874079) |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[1]/attrs/cx` | differs | -25 | 91.52439024390242 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[1]/attrs/cy` | differs | 87 | 164.6829268292683 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-2/attrs/style` | differs | pointer-events: all; transform: translate(-100px, 100px); visibility: visible; z-index: 0; | pointer-events: all; transform: translate(16.5244px, 177.683px); visibility: visible; z-index: 0; |

### callbacks (17)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |
| `callbacks/20/args/2/1` | right only | — | {"id":"Node-2","position":{"x":-100,"y":100},"data":{"label":"Node-2"},"type":"output","selected":true,"dragging":true,"measured":{"width":150,"height":37}} |
| `callbacks/23/args/0/1` | right only | — | {"type":"position","id":"Node-2","position":{"x":-76.69512195121952,"y":115.53658536585365},"dragging":true} |
| `callbacks/24/args/2/1` | right only | — | {"id":"Node-2","position":{"x":-76.69512195121952,"y":115.53658536585365},"data":{"label":"Node-2"},"type":"output","selected":false,"dragging":true,"measured"… |
| `callbacks/26/args/0/1` | right only | — | {"type":"position","id":"Node-2","position":{"x":-53.39024390243904,"y":131.0731707317073},"dragging":true} |
| `callbacks/27/args/2/1` | right only | — | {"id":"Node-2","position":{"x":-53.39024390243904,"y":131.0731707317073},"data":{"label":"Node-2"},"type":"output","selected":false,"dragging":true,"measured":… |
| `callbacks/29/args/0/1` | right only | — | {"type":"position","id":"Node-2","position":{"x":-30.085365853658544,"y":146.60975609756096},"dragging":true} |
| `callbacks/30/args/2/1` | right only | — | {"id":"Node-2","position":{"x":-30.085365853658544,"y":146.60975609756096},"data":{"label":"Node-2"},"type":"output","selected":false,"dragging":true,"measured… |
| `callbacks/32/args/0/1` | right only | — | {"type":"position","id":"Node-2","position":{"x":-6.7804878048780495,"y":162.14634146341461},"dragging":true} |
| `callbacks/33/args/2/1` | right only | — | {"id":"Node-2","position":{"x":-6.7804878048780495,"y":162.14634146341461},"data":{"label":"Node-2"},"type":"output","selected":false,"dragging":true,"measured… |
| `callbacks/35/args/0/1` | right only | — | {"type":"position","id":"Node-2","position":{"x":16.524390243902417,"y":177.6829268292683},"dragging":true} |
| `callbacks/36/args/2/1` | right only | — | {"id":"Node-2","position":{"x":16.524390243902417,"y":177.6829268292683},"data":{"label":"Node-2"},"type":"output","selected":false,"dragging":true,"measured":… |
| `callbacks/37/args/0/1` | right only | — | {"type":"position","id":"Node-2","position":{"x":16.524390243902417,"y":177.6829268292683},"dragging":false} |
| `callbacks/38/args/2/1` | right only | — | {"id":"Node-2","position":{"x":16.524390243902417,"y":177.6829268292683},"data":{"label":"Node-2"},"type":"output","selected":false,"dragging":false,"measured"… |

### api (13)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/1/position/x` | differs | -100 | 16.524390243902417 |
| `api/queries/getNodes/1/position/y` | differs | 100 | 177.6829268292683 |
| `api/queries/getNodes/1/dragging` | right only | — | false |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":58.26219512195121,"y":38.84146341463414},"type":"input","className":"playwright-test-class-123","style… | — |
| `api/queries/getIntersectingNodes/1/position/x` | differs | -100 | 16.524390243902417 |
| `api/queries/getIntersectingNodes/1/position/y` | differs | 100 | 177.6829268292683 |
| `api/queries/getIntersectingNodes/1/dragging` | right only | — | false |
| `api/queries/getNodesBounds/x` | differs | -100 | 0 |
| `api/queries/getNodesBounds/width` | differs | 400 | 300 |
| `api/queries/toObject/nodes/1/position/x` | differs | -100 | 16.524390243902417 |
| `api/queries/toObject/nodes/1/position/y` | differs | 100 | 177.6829268292683 |
| `api/queries/toObject/nodes/1/dragging` | right only | — | false |

## Normalization

42 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (21) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-node-escape-mid-gesture

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — drag-node-escape-mid-gesture

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 23 unclaimed difference(s).

## Unclaimed differences

### callbacks (21)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/23` | right only | — | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… |
| `callbacks/24` | right only | — | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |
| `callbacks/22/args/0/screenX` | differs | 794 | 734 |
| `callbacks/22/args/0/screenY` | differs | 171 | 131 |
| `callbacks/22/args/0/clientX` | differs | 794 | 734 |
| `callbacks/22/args/0/clientY` | differs | 171 | 131 |
| `callbacks/22/args/0/pageX` | differs | 794 | 734 |
| `callbacks/22/args/0/pageY` | differs | 171 | 131 |
| `callbacks/22/args/1/id` | differs | Node-3 | Node-1 |
| `callbacks/22/args/1/data/label` | differs | Node-3 | Node-1 |
| `callbacks/22/args/1/position/x` | differs | 100 | 116.52439024390242 |
| `callbacks/22/args/1/position/y` | differs | 100 | 77.68292682926828 |
| `callbacks/22/args/1/type` | right only | — | input |
| `callbacks/22/args/1/selected` | right only | — | false |
| `callbacks/22/args/1/dragging` | right only | — | true |
| `callbacks/22/args/1/className` | right only | — | playwright-test-class-123 |
| `callbacks/22/args/1/style` | right only | — | {"backgroundColor":"red"} |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":174.78658536585363,"y":116.52439024390243},"type":"input","className":"playwright-test-class-123","sty… | — |

## Normalization

20 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (11) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-node-autopan

**Failed:** self-inconsistent, unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | **disagrees with itself** | 109 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(2000px, 2000px) scale(1); | transform: translate(1380px, 1600px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[0]/attrs/d` | differs | M-2065,-2253 C-2065,-1078 -25,-1078 -25,97 | M-1375,-1573 C-1375,-738 -25,-738 -25,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[1]/attrs/d` | differs | M-2065,-2253 C-2065,-1078 -25,-1078 -25,97 | M-1375,-1573 C-1375,-738 -25,-738 -25,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cx` | differs | -2065 | -1375 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cy` | differs | -2243 | -1563 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/path[0]/attrs/d` | differs | M-2065,-2253 C-2065,-1078 175,-1078 175,97 | M-1375,-1573 C-1375,-738 175,-738 175,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/path[1]/attrs/d` | differs | M-2065,-2253 C-2065,-1078 175,-1078 175,97 | M-1375,-1573 C-1375,-738 175,-738 175,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[0]/attrs/cx` | differs | -2065 | -1375 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[0]/attrs/cy` | differs | -2243 | -1563 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-1/attrs/style` | differs | pointer-events: all; transform: translate(-2140px, -2293px); visibility: visible; z-index: 1000; | pointer-events: all; transform: translate(-1450px, -1613px); visibility: visible; z-index: 1000; |
| `callbacks/48` | left only | {"name":"onMoveStart","args":[null,{"x":1380,"y":1580,"zoom":1}]} | — |
| `callbacks/49` | left only | {"name":"onViewportChange","args":[{"x":1720,"y":1930,"zoom":1}]} | — |
| `callbacks/50` | left only | {"name":"onMove","args":[null,{"x":1720,"y":1930,"zoom":1}]} | — |
| `callbacks/51` | left only | {"name":"onMoveEnd","args":[null,{"x":1720,"y":1930,"zoom":1}]} | — |
| `callbacks/56` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"Node-1","position":{"x":-1790,"y":-1943},"data":{"label":"Node-1"},"type":"input",… | — |
| `callbacks/57` | left only | {"name":"onMoveStart","args":[null,{"x":1720,"y":1930,"zoom":1}]} | — |
| `callbacks/58` | left only | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/59` | left only | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/60` | left only | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/61` | left only | {"name":"onNodesChange","args":[[{"type":"position","id":"Node-1","position":{"x":-2140,"y":-2293},"dragging":true}]]} | — |
| `callbacks/62` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"Node-1","position":{"x":-2140,"y":-2293},"data":{"label":"Node-1"},"type":"input",… | — |
| `callbacks/63` | left only | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… | — |
| `callbacks/64` | left only | {"name":"onNodesChange","args":[[{"type":"position","id":"Node-1","position":{"x":-2140,"y":-2293},"dragging":false}]]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… |
| `callbacks/23/args/0/x` | differs | 680 | 690 |
| `callbacks/24/args/1/x` | differs | 680 | 690 |
| `callbacks/25/args/1/x` | differs | 680 | 690 |
| `callbacks/26/args/0/0/position/x` | differs | -749 | -410 |
| `callbacks/26/args/0/0/position/y` | differs | -692 | -572 |
| `callbacks/27/args/1/position/x` | differs | -749 | -410 |
| `callbacks/27/args/1/position/y` | differs | -692 | -572 |
| `callbacks/27/args/2/0/position/x` | differs | -749 | -410 |
| `callbacks/27/args/2/0/position/y` | differs | -692 | -572 |
| `callbacks/28/args/1/position/x` | differs | -749 | -409 |
| `callbacks/28/args/1/position/y` | differs | -692 | -352 |
| `callbacks/30/args/0/0/position/x` | differs | -750 | -760 |
| `callbacks/31/args/1/position/x` | differs | -750 | -760 |
| `callbacks/31/args/2/0/position/x` | differs | -750 | -760 |
| `callbacks/32/args/1/x` | differs | 680 | 690 |
| `callbacks/33/args/0/y` | differs | 1240 | 1250 |
| `callbacks/34/args/1/y` | differs | 1240 | 1250 |
| `callbacks/35/args/1/y` | differs | 1240 | 1250 |
| `callbacks/36/args/0/0/position/x` | differs | -1100 | -759 |
| `callbacks/36/args/0/0/position/y` | differs | -1252 | -913 |
| `callbacks/37/args/1/position/x` | differs | -1100 | -759 |
| `callbacks/37/args/1/position/y` | differs | -1252 | -913 |
| `callbacks/37/args/2/0/position/x` | differs | -1100 | -759 |
| `callbacks/37/args/2/0/position/y` | differs | -1252 | -913 |
| `callbacks/38/args/0/screenX` | differs | 5 | 6 |
| `callbacks/38/args/0/screenY` | differs | 6 | 5 |
| `callbacks/38/args/0/clientX` | differs | 5 | 6 |
| `callbacks/38/args/0/clientY` | differs | 6 | 5 |
| `callbacks/38/args/0/pageX` | differs | 5 | 6 |
| `callbacks/38/args/0/pageY` | differs | 6 | 5 |
| `callbacks/38/args/1/position/x` | differs | -1100 | -760 |
| `callbacks/38/args/1/position/y` | differs | -1252 | -912 |
| `callbacks/39/args/1/y` | differs | 1240 | 1250 |
| `callbacks/40/args/0/y` | differs | 1580 | 1600 |
| `callbacks/41/args/1/y` | differs | 1580 | 1600 |
| `callbacks/42/args/1/y` | differs | 1580 | 1600 |
| `callbacks/43/args/0/0/position/x` | differs | -1450 | -1099 |
| `callbacks/43/args/0/0/position/y` | differs | -1592 | -1263 |
| `callbacks/44/args/1/position/x` | differs | -1450 | -1099 |
| `callbacks/44/args/1/position/y` | differs | -1592 | -1263 |
| `callbacks/44/args/2/0/position/x` | differs | -1450 | -1099 |
| `callbacks/44/args/2/0/position/y` | differs | -1592 | -1263 |
| `callbacks/46/args/0/0/position/x` | differs | -1449 | -1100 |
| `callbacks/46/args/0/0/position/y` | differs | -1593 | -1263 |
| `callbacks/47/args/1/position/x` | differs | -1449 | -1100 |
| `callbacks/47/args/1/position/y` | differs | -1593 | -1263 |
| `callbacks/47/args/2/0/position/x` | differs | -1449 | -1100 |
| `callbacks/47/args/2/0/position/y` | differs | -1593 | -1263 |
| `callbacks/52/args/0/0/position/x` | differs | -1789 | -1450 |
| `callbacks/52/args/0/0/position/y` | differs | -1943 | -1613 |
| `callbacks/53/args/1/position/x` | differs | -1789 | -1450 |
| `callbacks/53/args/1/position/y` | differs | -1943 | -1613 |
| `callbacks/53/args/2/0/position/x` | differs | -1789 | -1450 |
| `callbacks/53/args/2/0/position/y` | differs | -1943 | -1613 |
| `callbacks/55/args/0/0/position/x` | differs | -1790 | -1450 |
| `callbacks/55/args/0/0/position/y` | differs | -1943 | -1613 |
| `callbacks/55/args/0/0/dragging` | differs | true | false |
| `callbacks/65/args/1/position/x` | differs | -2140 | -1450 |
| `callbacks/65/args/1/position/y` | differs | -2293 | -1613 |
| `callbacks/65/args/2/0/position/x` | differs | -2140 | -1450 |
| `callbacks/65/args/2/0/position/y` | differs | -2293 | -1613 |
| `api/queries/getNodes/0/position/x` | differs | -2140 | -1450 |
| `api/queries/getNodes/0/position/y` | differs | -2293 | -1613 |
| `api/queries/getNode/position/x` | differs | -2140 | -1450 |
| `api/queries/getNode/position/y` | differs | -2293 | -1613 |
| `api/queries/getInternalNode/position/x` | differs | -2140 | -1450 |
| `api/queries/getInternalNode/position/y` | differs | -2293 | -1613 |
| `api/queries/getInternalNode/internals/positionAbsolute/x` | differs | -2140 | -1450 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | -2293 | -1613 |
| `api/queries/getIntersectingNodes/0/position/x` | differs | -2140 | -1450 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | -2293 | -1613 |
| `api/queries/getNodesBounds/x` | differs | -2140 | -1450 |
| `api/queries/getNodesBounds/y` | differs | -2293 | -1613 |
| `api/queries/getNodesBounds/width` | differs | 2390 | 1700 |
| `api/queries/getNodesBounds/height` | differs | 2430 | 1750 |
| `api/queries/toObject/nodes/0/position/x` | differs | -2140 | -1450 |
| `api/queries/toObject/nodes/0/position/y` | differs | -2293 | -1613 |
| `api/queries/toObject/viewport/x` | differs | 2000 | 1380 |
| `api/queries/toObject/viewport/y` | differs | 2000 | 1600 |
| `api/queries/getViewport/x` | differs | 2000 | 1380 |
| `api/queries/getViewport/y` | differs | 2000 | 1600 |
| `api/queries/screenToFlowPosition/x` | differs | -2000 | -1380 |
| `api/queries/screenToFlowPosition/y` | differs | -2000 | -1600 |
| `api/queries/flowToScreenPosition/x` | differs | 2000 | 1380 |
| `api/queries/flowToScreenPosition/y` | differs | 2000 | 1600 |

**psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — drag-node-autopan

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 117 unclaimed difference(s).

## Unclaimed differences

### dom (10)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(1380px, 1600px) scale(1); | transform: translate(2000px, 2000px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[0]/attrs/d` | differs | M-1375,-1573 C-1375,-738 -25,-738 -25,97 | M-2065,-2253 C-2065,-1078 -25,-1078 -25,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[1]/attrs/d` | differs | M-1375,-1573 C-1375,-738 -25,-738 -25,97 | M-2065,-2253 C-2065,-1078 -25,-1078 -25,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cx` | differs | -1375 | -2065 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cy` | differs | -1563 | -2243 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/path[0]/attrs/d` | differs | M-1375,-1573 C-1375,-738 175,-738 175,97 | M-2065,-2253 C-2065,-1078 175,-1078 175,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/path[1]/attrs/d` | differs | M-1375,-1573 C-1375,-738 175,-738 175,97 | M-2065,-2253 C-2065,-1078 175,-1078 175,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[0]/attrs/cx` | differs | -1375 | -2065 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[0]/attrs/cy` | differs | -1563 | -2243 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-1/attrs/style` | differs | pointer-events: all; transform: translate(-1450px, -1613px); visibility: visible; z-index: 1000; | pointer-events: all; transform: translate(-2140px, -2293px); visibility: visible; z-index: 1000; |

### callbacks (81)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/42` | right only | — | {"name":"onMoveEnd","args":[null,{"x":1380,"y":1580,"zoom":1}]} |
| `callbacks/48` | right only | — | {"name":"onMoveStart","args":[null,{"x":1380,"y":1580,"zoom":1}]} |
| `callbacks/49` | right only | — | {"name":"onViewportChange","args":[{"x":1720,"y":1930,"zoom":1}]} |
| `callbacks/50` | right only | — | {"name":"onMove","args":[null,{"x":1720,"y":1930,"zoom":1}]} |
| `callbacks/51` | right only | — | {"name":"onMoveEnd","args":[null,{"x":1720,"y":1930,"zoom":1}]} |
| `callbacks/56` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"Node-1","position":{"x":-1790,"y":-1943},"data":{"label":"Node-1"},"type":"input",… |
| `callbacks/57` | right only | — | {"name":"onMoveStart","args":[null,{"x":1720,"y":1930,"zoom":1}]} |
| `callbacks/58` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/59` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/60` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/61` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"Node-1","position":{"x":-2140,"y":-2293},"dragging":true}]]} |
| `callbacks/62` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"Node-1","position":{"x":-2140,"y":-2293},"data":{"label":"Node-1"},"type":"input",… |
| `callbacks/63` | right only | — | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… |
| `callbacks/64` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"Node-1","position":{"x":-2140,"y":-2293},"dragging":false}]]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… |
| `callbacks/20/args/1/x` | differs | 340 | 0 |
| `callbacks/20/args/1/y` | differs | 560 | 220.00000000000003 |
| `callbacks/21/args/1/position/x` | differs | -409 | -749 |
| `callbacks/21/args/1/position/y` | differs | -352 | -692 |
| `callbacks/23/args/0/0/position/x` | differs | -410 | -749 |
| `callbacks/23/args/0/0/position/y` | differs | -572 | -692 |
| `callbacks/24/args/1/position/x` | differs | -410 | -749 |
| `callbacks/24/args/1/position/y` | differs | -572 | -692 |
| `callbacks/24/args/2/0/position/x` | differs | -410 | -749 |
| `callbacks/24/args/2/0/position/y` | differs | -572 | -692 |
| `callbacks/26/args/0/x` | differs | 690 | 680 |
| `callbacks/27/args/1/x` | differs | 690 | 680 |
| `callbacks/28/args/0/0/position/x` | differs | -760 | -750 |
| `callbacks/29/args/1/position/x` | differs | -760 | -750 |
| `callbacks/29/args/2/0/position/x` | differs | -760 | -750 |
| `callbacks/30/args/1/x` | differs | 690 | 340 |
| `callbacks/30/args/1/y` | differs | 900 | 560 |
| `callbacks/31/args/0/screenX` | differs | 6 | 5 |
| `callbacks/31/args/0/screenY` | differs | 5 | 6 |
| `callbacks/31/args/0/clientX` | differs | 6 | 5 |
| `callbacks/31/args/0/clientY` | differs | 5 | 6 |
| `callbacks/31/args/0/pageX` | differs | 6 | 5 |
| `callbacks/31/args/0/pageY` | differs | 5 | 6 |
| `callbacks/31/args/1/position/x` | differs | -760 | -1100 |
| `callbacks/31/args/1/position/y` | differs | -912 | -1252 |
| `callbacks/33/args/0/0/position/x` | differs | -759 | -1100 |
| `callbacks/33/args/0/0/position/y` | differs | -913 | -1252 |
| `callbacks/34/args/1/position/x` | differs | -759 | -1100 |
| `callbacks/34/args/1/position/y` | differs | -913 | -1252 |
| `callbacks/34/args/2/0/position/x` | differs | -759 | -1100 |
| `callbacks/34/args/2/0/position/y` | differs | -913 | -1252 |
| `callbacks/35/args/1/x` | differs | 690 | 680 |
| `callbacks/36/args/0/y` | differs | 1250 | 1240 |
| `callbacks/37/args/1/y` | differs | 1250 | 1240 |
| `callbacks/38/args/0/0/position/x` | differs | -1099 | -1450 |
| `callbacks/38/args/0/0/position/y` | differs | -1263 | -1592 |
| `callbacks/39/args/1/position/x` | differs | -1099 | -1450 |
| `callbacks/39/args/1/position/y` | differs | -1263 | -1592 |
| `callbacks/39/args/2/0/position/x` | differs | -1099 | -1450 |
| `callbacks/39/args/2/0/position/y` | differs | -1263 | -1592 |
| `callbacks/40/args/1/x` | differs | 1030 | 680 |
| `callbacks/40/args/1/y` | differs | 1250 | 900 |
| `callbacks/42/args/0/0/position/x` | differs | -1100 | -1449 |
| `callbacks/42/args/0/0/position/y` | differs | -1263 | -1593 |
| `callbacks/43/args/1/position/x` | differs | -1100 | -1449 |
| `callbacks/43/args/1/position/y` | differs | -1263 | -1593 |
| `callbacks/43/args/2/0/position/x` | differs | -1100 | -1449 |
| `callbacks/43/args/2/0/position/y` | differs | -1263 | -1593 |
| `callbacks/44/args/1/y` | differs | 1250 | 1240 |
| `callbacks/45/args/0/y` | differs | 1600 | 1580 |
| `callbacks/46/args/1/y` | differs | 1600 | 1580 |
| `callbacks/47/args/0/0/position/x` | differs | -1450 | -1789 |
| `callbacks/47/args/0/0/position/y` | differs | -1613 | -1943 |
| `callbacks/48/args/1/position/x` | differs | -1450 | -1789 |
| `callbacks/48/args/1/position/y` | differs | -1613 | -1943 |
| `callbacks/48/args/2/0/position/x` | differs | -1450 | -1789 |
| `callbacks/48/args/2/0/position/y` | differs | -1613 | -1943 |
| `callbacks/49/args/1/x` | differs | 1380 | 1030 |
| `callbacks/49/args/1/y` | differs | 1600 | 1240 |
| `callbacks/50/args/0/0/position/x` | differs | -1450 | -1790 |
| `callbacks/50/args/0/0/position/y` | differs | -1613 | -1943 |
| `callbacks/50/args/0/0/dragging` | differs | false | true |
| `callbacks/51/args/1/position/x` | differs | -1450 | -2140 |
| `callbacks/51/args/1/position/y` | differs | -1613 | -2293 |
| `callbacks/51/args/2/0/position/x` | differs | -1450 | -2140 |
| `callbacks/51/args/2/0/position/y` | differs | -1613 | -2293 |

### api (26)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0/position/x` | differs | -1450 | -2140 |
| `api/queries/getNodes/0/position/y` | differs | -1613 | -2293 |
| `api/queries/getNode/position/x` | differs | -1450 | -2140 |
| `api/queries/getNode/position/y` | differs | -1613 | -2293 |
| `api/queries/getInternalNode/position/x` | differs | -1450 | -2140 |
| `api/queries/getInternalNode/position/y` | differs | -1613 | -2293 |
| `api/queries/getInternalNode/internals/positionAbsolute/x` | differs | -1450 | -2140 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | -1613 | -2293 |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":-1450,"y":-1613},"type":"input","measured":{"width":150,"height":37},"selected":true,"dragging":false} | — |
| `api/queries/getIntersectingNodes/0/position/x` | differs | -1450 | -2140 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | -1613 | -2293 |
| `api/queries/getNodesBounds/x` | differs | -1450 | -2140 |
| `api/queries/getNodesBounds/y` | differs | -1613 | -2293 |
| `api/queries/getNodesBounds/width` | differs | 1700 | 2390 |
| `api/queries/getNodesBounds/height` | differs | 1750 | 2430 |
| `api/queries/toObject/nodes/0/position/x` | differs | -1450 | -2140 |
| `api/queries/toObject/nodes/0/position/y` | differs | -1613 | -2293 |
| `api/queries/toObject/viewport/x` | differs | 1380 | 2000 |
| `api/queries/toObject/viewport/y` | differs | 1600 | 2000 |
| `api/queries/getViewport/x` | differs | 1380 | 2000 |
| `api/queries/getViewport/y` | differs | 1600 | 2000 |
| `api/queries/screenToFlowPosition/x` | differs | -1380 | -2000 |
| `api/queries/screenToFlowPosition/y` | differs | -1600 | -2000 |
| `api/queries/flowToScreenPosition/x` | differs | 1380 | 2000 |
| `api/queries/flowToScreenPosition/y` | differs | 1600 | 2000 |

## Normalization

21 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (16) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-node-no-select-on-drag

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — drag-node-no-select-on-drag

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":60,"y":40},"type":"input","measured":{"width":150,"height":37},"dragging":false} | — |

## Normalization

36 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (18) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-child-expand-parent

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — drag-child-expand-parent

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 9 unclaimed difference(s).

## Unclaimed differences

### callbacks (8)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/0/id` | differs | parent | child |
| `callbacks/4/args/0/0/dimensions/width` | differs | 320 | 150 |
| `callbacks/4/args/0/0/dimensions/height` | differs | 220 | 37 |
| `callbacks/4/args/0/1/id` | differs | child | outside |
| `callbacks/4/args/0/2/id` | differs | outside | parent |
| `callbacks/4/args/0/2/dimensions/width` | differs | 150 | 320 |
| `callbacks/4/args/0/2/dimensions/height` | differs | 37 | 220 |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"parent","data":{"label":"parent"},"position":{"x":0,"y":0},"style":{"width":320,"height":220,"backgroundColor":"rgba(80, 120, 200, 0.12)"},"measured":{"… | — |

## Normalization

24 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (12) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-unmeasured-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — drag-unmeasured-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 8 unclaimed difference(s).

## Unclaimed differences

### callbacks (6)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/12` | left only | {"name":"onError","args":["015","It seems that you are trying to drag a node that is not initialized. Please use onNodesChange as explained in the docs."]} | — |
| `callbacks/16` | left only | {"name":"onError","args":["015","It seems that you are trying to drag a node that is not initialized. Please use onNodesChange as explained in the docs."]} | — |
| `callbacks/20` | left only | {"name":"onError","args":["015","It seems that you are trying to drag a node that is not initialized. Please use onNodesChange as explained in the docs."]} | — |
| `callbacks/24` | left only | {"name":"onError","args":["015","It seems that you are trying to drag a node that is not initialized. Please use onNodesChange as explained in the docs."]} | — |
| `callbacks/28` | left only | {"name":"onError","args":["015","It seems that you are trying to drag a node that is not initialized. Please use onNodesChange as explained in the docs."]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":50,"y":30},"type":"input","selected":true,"measured":{"width":150,"height":37},"dragging":false} | — |

## Normalization

18 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (12) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — selection-box-from-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — selection-box-from-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 6 unclaimed difference(s).

## Unclaimed differences

### callbacks (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onNodeMouseEnter#1","onNodeMouseMove#1","onSelectionSta… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onNodeMouseEnter#1","onNodeMouseMove#1","onSelectionSta… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

12 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (6) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — selection-box-then-click-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — selection-box-then-click-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 18 unclaimed difference(s).

## Unclaimed differences

### callbacks (16)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMov… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMov… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |
| `callbacks/19/args/2/0/id` | differs | notConnectable | Node-4 |
| `callbacks/19/args/2/0/data/label` | differs | notConnectable | Node-4 |
| `callbacks/19/args/2/0/position/y` | differs | 300 | 200 |
| `callbacks/19/args/2/0/connectable` | left only | false | — |
| `callbacks/19/args/2/0/selected` | right only | — | true |
| `callbacks/19/args/2/1` | right only | — | {"id":"notConnectable","position":{"x":0,"y":300},"data":{"label":"notConnectable"},"type":"output","dragging":true,"connectable":false,"measured":{"width":150… |
| `callbacks/21/args/2/0/id` | differs | notConnectable | Node-4 |
| `callbacks/21/args/2/0/data/label` | differs | notConnectable | Node-4 |
| `callbacks/21/args/2/0/position/y` | differs | 300 | 200 |
| `callbacks/21/args/2/0/connectable` | left only | false | — |
| `callbacks/21/args/2/0/selected` | differs | true | false |
| `callbacks/21/args/2/1` | right only | — | {"id":"notConnectable","position":{"x":0,"y":300},"data":{"label":"notConnectable"},"type":"output","selected":true,"dragging":false,"connectable":false,"measu… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

18 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (9) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — selection-box-mid-gesture

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — selection-box-mid-gesture

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onSelectionStart#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onSelectionStart#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

2 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (1) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — selection-box-touch

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — selection-box-touch

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 30 unclaimed difference(s).

## Unclaimed differences

### dom (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[1]` | left only | {"tag":"div","attrs":{"class":"nopan react-flow__container react-flow__nodesselection","style":"transform: translate(537.017px, 32px) scale(1.02983) translate(… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notConnectable/attrs/class` | differs | draggable nopan react-flow__node react-flow__node-output selectable selected | draggable dragging nopan react-flow__node react-flow__node-output selectable |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notConnectable/attrs/style` | differs | -webkit-tap-highlight-color: rgba(0, 0, 0, 0); pointer-events: all; touch-action: none; transform: translate(213.628px, 455.366px); visibility: visible; z-inde… | -webkit-tap-highlight-color: rgba(0, 0, 0, 0); pointer-events: all; touch-action: none; transform: translate(0px, 300px); visibility: visible; z-index: 0; |

### callbacks (12)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/11` | left only | {"name":"onNodesChange","args":[[{"id":"notConnectable","type":"position","position":{"x":116.52439024390243,"y":387.3932926829268},"dragging":true}]]} | — |
| `callbacks/12` | left only | {"name":"onNodeDrag","args":[{"@class":"TouchEvent","isTrusted":true},{"id":"notConnectable","type":"output","data":{"label":"notConnectable"},"position":{"x":… | — |
| `callbacks/14` | left only | {"name":"onNodesChange","args":[[{"id":"notConnectable","type":"select","selected":true}]]} | — |
| `callbacks/15` | left only | {"name":"onSelectionChange","args":[{"nodes":[{"id":"notConnectable","type":"output","data":{"label":"notConnectable"},"position":{"x":116.52439024390243,"y":3… | — |
| `callbacks/16` | left only | {"name":"onNodesChange","args":[[{"id":"notConnectable","type":"position","position":{"x":213.6280487804878,"y":455.36585365853654},"dragging":true}]]} | — |
| `callbacks/17` | left only | {"name":"onNodeDrag","args":[{"@class":"TouchEvent","isTrusted":true},{"id":"notConnectable","type":"output","data":{"label":"notConnectable"},"position":{"x":… | — |
| `callbacks/20` | left only | {"name":"onNodesChange","args":[[{"id":"notConnectable","type":"position","position":{"x":213.6280487804878,"y":455.36585365853654},"dragging":false}]]} | — |
| `callbacks/21` | left only | {"name":"onNodeDragStop","args":[{"@class":"TouchEvent","isTrusted":true},{"id":"notConnectable","type":"output","data":{"label":"notConnectable"},"position":{… | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onNodesChange#2","onNodeDragStart#1","onSelectionChange… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onNodesChange#2","onNodeDragStart#1","onSelectionChange… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |

### api (15)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/5/position/x` | differs | 213.6280487804878 | 0 |
| `api/queries/getNodes/5/position/y` | differs | 455.36585365853654 | 300 |
| `api/queries/getNodes/5/selected` | differs | true | false |
| `api/queries/getNodes/5/dragging` | left only | false | — |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |
| `api/queries/getIntersectingNodes/5/position/x` | differs | 213.6280487804878 | 0 |
| `api/queries/getIntersectingNodes/5/position/y` | differs | 455.36585365853654 | 300 |
| `api/queries/getIntersectingNodes/5/selected` | differs | true | false |
| `api/queries/getIntersectingNodes/5/dragging` | left only | false | — |
| `api/queries/getNodesBounds/width` | differs | 463.6280487804878 | 400 |
| `api/queries/toObject/nodes/5/position/x` | differs | 213.6280487804878 | 0 |
| `api/queries/toObject/nodes/5/position/y` | differs | 455.36585365853654 | 300 |
| `api/queries/toObject/nodes/5/selected` | differs | true | false |
| `api/queries/toObject/nodes/5/dragging` | left only | false | — |

## Normalization

6 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — arrow-key-selected-node

**Failed:** self-inconsistent, unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | **disagrees with itself** | 2 |
| psflow | 1, 2 | reproduced | 0 |

### upstream disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… |
| `callbacks/17/args/1/position/x` | differs | 10 | 0 |

**upstream did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — arrow-key-selected-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 32 unclaimed difference(s).

## Unclaimed differences

### dom (6)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[0]/attrs/d` | differs | M85,60 C85,228.5 75,228.5 75,397 | M77,44 C77,220.5 75,220.5 75,397 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[1]/attrs/d` | differs | M85,60 C85,228.5 75,228.5 75,397 | M77,44 C77,220.5 75,220.5 75,397 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cx` | differs | 85 | 77 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cy` | differs | 70 | 54 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-1/attrs/style` | differs | pointer-events: all; transform: translate(10px, 20px); visibility: visible; z-index: 1000; | pointer-events: all; transform: translate(2px, 4px); visibility: visible; z-index: 1000; |
| `dom/root/children/react-flow__aria-live-1/text` | left only | Moved selected node right. New position, x: 5, y: 20 | — |

### callbacks (9)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/17` | left only | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… | — |
| `callbacks/11/args/0/0/position/y` | differs | 5 | 1 |
| `callbacks/12/args/0/0/position/y` | differs | 10 | 2 |
| `callbacks/13/args/0/0/position/y` | differs | 15 | 3 |
| `callbacks/14/args/0/0/position/y` | differs | 20 | 4 |
| `callbacks/15/args/0/0/position/x` | differs | 5 | 1 |
| `callbacks/15/args/0/0/position/y` | differs | 20 | 4 |
| `callbacks/16/args/0/0/position/x` | differs | 10 | 2 |
| `callbacks/16/args/0/0/position/y` | differs | 20 | 4 |

### api (17)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0/position/x` | differs | 10 | 2 |
| `api/queries/getNodes/0/position/y` | differs | 20 | 4 |
| `api/queries/getNode/position/x` | differs | 10 | 2 |
| `api/queries/getNode/position/y` | differs | 20 | 4 |
| `api/queries/getInternalNode/position/x` | differs | 10 | 2 |
| `api/queries/getInternalNode/position/y` | differs | 20 | 4 |
| `api/queries/getInternalNode/internals/positionAbsolute/x` | differs | 10 | 2 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 20 | 4 |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":10,"y":20},"type":"input","measured":{"width":150,"height":37},"selected":true,"dragging":false} | — |
| `api/queries/getIntersectingNodes/0/position/x` | differs | 10 | 2 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 20 | 4 |
| `api/queries/getNodesBounds/y` | differs | 20 | 4 |
| `api/queries/getNodesBounds/width` | differs | 160 | 152 |
| `api/queries/getNodesBounds/height` | differs | 1217 | 1233 |
| `api/queries/toObject/nodes/0/position/x` | differs | 10 | 2 |
| `api/queries/toObject/nodes/0/position/y` | differs | 20 | 4 |

## Normalization

11 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (6) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — keyboard-focus-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — keyboard-focus-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37},"selected":true} | — |


---

# System parity run — connect-handle-to-handle

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — connect-handle-to-handle

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 72 unclaimed difference(s).

## Unclaimed differences

### callbacks (70)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |
| `callbacks/14/args/0/@class` | differs | MouseEvent | SyntheticBaseEvent |
| `callbacks/14/args/0/_reactName` | right only | — | onMouseDown |
| `callbacks/14/args/0/_targetInst` | right only | — | null |
| `callbacks/14/args/0/type` | right only | — | mousedown |
| `callbacks/14/args/0/nativeEvent` | right only | — | {"@class":"MouseEvent","isTrusted":true} |
| `callbacks/14/args/0/target` | right only | — | {"@ref":"DIV"} |
| `callbacks/14/args/0/currentTarget` | right only | — | null |
| `callbacks/14/args/0/eventPhase` | right only | — | 3 |
| `callbacks/14/args/0/bubbles` | right only | — | true |
| `callbacks/14/args/0/cancelable` | right only | — | true |
| `callbacks/14/args/0/defaultPrevented` | right only | — | false |
| `callbacks/14/args/0/view` | right only | — | {"@ref":"Window"} |
| `callbacks/14/args/0/detail` | right only | — | 1 |
| `callbacks/14/args/0/screenX` | right only | — | 614 |
| `callbacks/14/args/0/screenY` | right only | — | 69 |
| `callbacks/14/args/0/clientX` | right only | — | 614 |
| `callbacks/14/args/0/clientY` | right only | — | 69 |
| `callbacks/14/args/0/pageX` | right only | — | 614 |
| `callbacks/14/args/0/pageY` | right only | — | 69 |
| `callbacks/14/args/0/ctrlKey` | right only | — | false |
| `callbacks/14/args/0/shiftKey` | right only | — | false |
| `callbacks/14/args/0/altKey` | right only | — | false |
| `callbacks/14/args/0/metaKey` | right only | — | false |
| `callbacks/14/args/0/getModifierState` | right only | — | {"@ref":"function"} |
| `callbacks/14/args/0/button` | right only | — | 0 |
| `callbacks/14/args/0/buttons` | right only | — | 1 |
| `callbacks/14/args/0/relatedTarget` | right only | — | null |
| `callbacks/14/args/0/movementX` | right only | — | 0 |
| `callbacks/14/args/0/movementY` | right only | — | 0 |
| `callbacks/14/args/0/isDefaultPrevented` | right only | — | {"@ref":"function"} |
| `callbacks/14/args/0/isPropagationStopped` | right only | — | {"@ref":"function"} |
| `callbacks/21/args/1/fromNode/internals/handleBounds/target` | differs | null | [] |
| `callbacks/21/args/1/fromNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |
| `callbacks/21/args/1/toNode/internals/handleBounds/source` | differs | null | [] |
| `callbacks/21/args/1/toNode/internals/userNode` | left only | {"id":"Node-4","data":{"label":"Node-4"},"position":{"x":0,"y":200},"type":"output","measured":{"width":150,"height":37}} | — |
| `callbacks/26/args/0/@class` | differs | PointerEvent | SyntheticBaseEvent |
| `callbacks/26/args/0/_reactName` | right only | — | onClick |
| `callbacks/26/args/0/_targetInst` | right only | — | null |
| `callbacks/26/args/0/type` | right only | — | click |
| `callbacks/26/args/0/nativeEvent` | right only | — | {"@class":"PointerEvent","isTrusted":true} |
| `callbacks/26/args/0/target` | right only | — | {"@ref":"DIV"} |
| `callbacks/26/args/0/currentTarget` | right only | — | {"@ref":"DIV"} |
| `callbacks/26/args/0/eventPhase` | right only | — | 3 |
| `callbacks/26/args/0/bubbles` | right only | — | true |
| `callbacks/26/args/0/cancelable` | right only | — | true |
| `callbacks/26/args/0/defaultPrevented` | right only | — | false |
| `callbacks/26/args/0/view` | right only | — | {"@ref":"Window"} |
| `callbacks/26/args/0/detail` | right only | — | 1 |
| `callbacks/26/args/0/screenX` | right only | — | 717 |
| `callbacks/26/args/0/screenY` | right only | — | 172 |
| `callbacks/26/args/0/clientX` | right only | — | 717 |
| `callbacks/26/args/0/clientY` | right only | — | 172 |
| `callbacks/26/args/0/pageX` | right only | — | 717 |
| `callbacks/26/args/0/pageY` | right only | — | 172 |
| `callbacks/26/args/0/ctrlKey` | right only | — | false |
| `callbacks/26/args/0/shiftKey` | right only | — | false |
| `callbacks/26/args/0/altKey` | right only | — | false |
| `callbacks/26/args/0/metaKey` | right only | — | false |
| `callbacks/26/args/0/getModifierState` | right only | — | {"@ref":"function"} |
| `callbacks/26/args/0/button` | right only | — | 0 |
| `callbacks/26/args/0/buttons` | right only | — | 0 |
| `callbacks/26/args/0/relatedTarget` | right only | — | null |
| `callbacks/26/args/0/movementX` | right only | — | 0 |
| `callbacks/26/args/0/movementY` | right only | — | 0 |
| `callbacks/26/args/0/isDefaultPrevented` | right only | — | {"@ref":"function"} |
| `callbacks/26/args/0/isPropagationStopped` | right only | — | {"@ref":"function"} |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

48 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (25) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — connect-then-keyboard-move

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — connect-then-keyboard-move

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 38 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/g[0]/children/path[0]/attrs/d` | differs | M75,36 C75,45.67454268292683 94.17378048780492,45.67454268292683 94.17378048780492,55.349085365853654 | M75,36 C75,62.5 634,62.5 634,89 |

### callbacks (35)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |
| `callbacks/23/args/0/@class` | differs | MouseEvent | SyntheticBaseEvent |
| `callbacks/23/args/0/_reactName` | right only | — | onMouseDown |
| `callbacks/23/args/0/_targetInst` | right only | — | null |
| `callbacks/23/args/0/type` | right only | — | mousedown |
| `callbacks/23/args/0/nativeEvent` | right only | — | {"@class":"MouseEvent","isTrusted":true} |
| `callbacks/23/args/0/target` | right only | — | {"@ref":"DIV"} |
| `callbacks/23/args/0/currentTarget` | right only | — | null |
| `callbacks/23/args/0/eventPhase` | right only | — | 3 |
| `callbacks/23/args/0/bubbles` | right only | — | true |
| `callbacks/23/args/0/cancelable` | right only | — | true |
| `callbacks/23/args/0/defaultPrevented` | right only | — | false |
| `callbacks/23/args/0/view` | right only | — | {"@ref":"Window"} |
| `callbacks/23/args/0/detail` | right only | — | 1 |
| `callbacks/23/args/0/screenX` | right only | — | 614 |
| `callbacks/23/args/0/screenY` | right only | — | 69 |
| `callbacks/23/args/0/clientX` | right only | — | 614 |
| `callbacks/23/args/0/clientY` | right only | — | 69 |
| `callbacks/23/args/0/pageX` | right only | — | 614 |
| `callbacks/23/args/0/pageY` | right only | — | 69 |
| `callbacks/23/args/0/ctrlKey` | right only | — | false |
| `callbacks/23/args/0/shiftKey` | right only | — | false |
| `callbacks/23/args/0/altKey` | right only | — | false |
| `callbacks/23/args/0/metaKey` | right only | — | false |
| `callbacks/23/args/0/getModifierState` | right only | — | {"@ref":"function"} |
| `callbacks/23/args/0/button` | right only | — | 0 |
| `callbacks/23/args/0/buttons` | right only | — | 1 |
| `callbacks/23/args/0/relatedTarget` | right only | — | null |
| `callbacks/23/args/0/movementX` | right only | — | 0 |
| `callbacks/23/args/0/movementY` | right only | — | 0 |
| `callbacks/23/args/0/isDefaultPrevented` | right only | — | {"@ref":"function"} |
| `callbacks/23/args/0/isPropagationStopped` | right only | — | {"@ref":"function"} |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

27 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (14) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — connect-second-touch-point

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — connect-second-touch-point

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 14 unclaimed difference(s).

## Unclaimed differences

### dom (6)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/svg[0]` | left only | {"tag":"svg","attrs":{"width":"1280","height":"720","class":"react-flow__connectionline react-flow__container"},"children":[{"tag":"g","attrs":{"class":"react-… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-1/children/1-Node-1-null-source/attrs/class` | differs | connectable connectableend connectablestart connectingfrom nodrag nopan react-flow__handle react-flow__handle-bottom source | connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-3/children/1-Node-3-null-source/attrs/class` | differs | connectable connectableend connectablestart nodrag nopan react-flow__handle react-flow__handle-bottom source | connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDraggable/children/1-notDraggable-null-source/attrs/class` | differs | connectable connectableend connectablestart nodrag nopan react-flow__handle react-flow__handle-bottom source | connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notSelectable/children/1-notSelectable-null-source/attrs/class` | differs | connectable connectableend connectablestart nodrag nopan react-flow__handle react-flow__handle-bottom source | connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDeletable/children/1-notDeletable-null-source/attrs/class` | differs | connectable connectableend connectablestart nodrag nopan react-flow__handle react-flow__handle-bottom source | connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source |

### callbacks (5)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/8` | left only | {"name":"onConnectStart","args":[{"@class":"TouchEvent","isTrusted":true},{"nodeId":"Node-1","handleId":null,"handleType":"source"}]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onPaneMouseEnt… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onPaneMouseEnt… |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

### console (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `console/1` | left only | {"level":"error","text":"Ignored attempt to cancel a touchmove event with cancelable=false, for example because scrolling is in progress and cannot be interrup… | — |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (7) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — probe-node-connections

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — probe-node-connections

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 47 unclaimed difference(s).

## Unclaimed differences

### callbacks (46)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/4/args/0/0/id` | differs | hub | down-1 |
| `callbacks/4/args/0/0/dimensions/width` | differs | 24 | 49 |
| `callbacks/4/args/0/1/id` | differs | up-1 | down-2 |
| `callbacks/4/args/0/1/dimensions/width` | differs | 29 | 49 |
| `callbacks/4/args/0/2/id` | differs | up-2 | down-3 |
| `callbacks/4/args/0/2/dimensions/width` | differs | 29 | 49 |
| `callbacks/4/args/0/3/id` | differs | down-1 | hub |
| `callbacks/4/args/0/3/dimensions/width` | differs | 49 | 24 |
| `callbacks/4/args/0/4/id` | differs | down-2 | up-1 |
| `callbacks/4/args/0/4/dimensions/width` | differs | 49 | 29 |
| `callbacks/4/args/0/5/id` | differs | down-3 | up-2 |
| `callbacks/4/args/0/5/dimensions/width` | differs | 49 | 29 |
| `callbacks/12/args/0/@class` | differs | MouseEvent | SyntheticBaseEvent |
| `callbacks/12/args/0/_reactName` | right only | — | onMouseDown |
| `callbacks/12/args/0/_targetInst` | right only | — | null |
| `callbacks/12/args/0/type` | right only | — | mousedown |
| `callbacks/12/args/0/nativeEvent` | right only | — | {"@class":"MouseEvent","isTrusted":true} |
| `callbacks/12/args/0/target` | right only | — | {"@ref":"DIV"} |
| `callbacks/12/args/0/currentTarget` | right only | — | null |
| `callbacks/12/args/0/eventPhase` | right only | — | 3 |
| `callbacks/12/args/0/bubbles` | right only | — | true |
| `callbacks/12/args/0/cancelable` | right only | — | true |
| `callbacks/12/args/0/defaultPrevented` | right only | — | false |
| `callbacks/12/args/0/view` | right only | — | {"@ref":"Window"} |
| `callbacks/12/args/0/detail` | right only | — | 1 |
| `callbacks/12/args/0/screenX` | right only | — | 99 |
| `callbacks/12/args/0/screenY` | right only | — | 645 |
| `callbacks/12/args/0/clientX` | right only | — | 99 |
| `callbacks/12/args/0/clientY` | right only | — | 645 |
| `callbacks/12/args/0/pageX` | right only | — | 99 |
| `callbacks/12/args/0/pageY` | right only | — | 645 |
| `callbacks/12/args/0/ctrlKey` | right only | — | false |
| `callbacks/12/args/0/shiftKey` | right only | — | false |
| `callbacks/12/args/0/altKey` | right only | — | false |
| `callbacks/12/args/0/metaKey` | right only | — | false |
| `callbacks/12/args/0/getModifierState` | right only | — | {"@ref":"function"} |
| `callbacks/12/args/0/button` | right only | — | 0 |
| `callbacks/12/args/0/buttons` | right only | — | 1 |
| `callbacks/12/args/0/relatedTarget` | right only | — | null |
| `callbacks/12/args/0/movementX` | right only | — | 0 |
| `callbacks/12/args/0/movementY` | right only | — | 0 |
| `callbacks/12/args/0/isDefaultPrevented` | right only | — | {"@ref":"function"} |
| `callbacks/12/args/0/isPropagationStopped` | right only | — | {"@ref":"function"} |
| `callbacks/18/args/1/fromNode/internals/userNode` | left only | {"id":"down-1","type":"connections","data":{"label":"down-1"},"position":{"x":0,"y":320},"measured":{"width":49,"height":18}} | — |
| `callbacks/18/args/1/toNode/internals/userNode` | left only | {"id":"hub","type":"connections","data":{"label":"hub"},"position":{"x":160,"y":160},"measured":{"width":24,"height":18}} | — |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"hub","type":"connections","data":{"label":"hub"},"position":{"x":160,"y":160},"measured":{"width":24,"height":18}} | — |

## Normalization

19 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (10) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — viewport-helpers-with-options

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — viewport-helpers-with-options

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — pan-gesture-complete

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — pan-gesture-complete

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

26 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (14) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — fitview-onnodeschange-variants

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — fitview-onnodeschange-variants

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 5 unclaimed difference(s).

## Unclaimed differences

### callbacks (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… |
| `callbacks/15/args/1/selected` | left only | true | — |
| `callbacks/15/args/2/0/selected` | left only | true | — |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":80,"y":60},"type":"input","measured":{"width":150,"height":37},"selected":true,"dragging":false} | — |

## Normalization

18 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (9) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — uncontrolled-update-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — uncontrolled-update-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onNodesChange#2","onNodesChange#3","onNodesChange#4","o… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onNodesChange#2","onNodesChange#3","onNodesChange#4","o… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"updated"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — flow-props-change-after-mount

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — flow-props-change-after-mount

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37},"selected":true} | — |

## Normalization

34 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (19) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — mount-in-display-none

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-in-display-none

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/attrs/style` | differs | display: none; height: 100%; overflow: hidden; position: relative; width: 100%; z-index: 0; | height: 100%; overflow: hidden; position: relative; width: 100%; z-index: 0; |

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — minimap-all-nodes-hidden

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — minimap-all-nodes-hidden

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[1]/children/svg[0]/children/path[0]/attrs/d` | differs | M-59.09584999560087,-169.90056873735244h1300.1086999032193v1004.6294499252149h-1300.1086999032193z⏎        M98.0830000879826,55.17168754949017h1083.83399982403… | M-59.09584999560087,-169.90056873735244h1300.1086999032193v1004.6294499252149h-1300.1086999032193z M98.0830000879826,55.17168754949017h1083.833999824035v609.65… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","hidden":true} | — |


---

# System parity run — minimap-custom-mask-colors

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — minimap-custom-mask-colors

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[1]/children/svg[0]/children/path[0]/attrs/d` | differs | M-277,-153.5h704v544h-704z⏎        M-245,-61.5h640v360h-640z | M-277,-153.5h704v544h-704z M-245,-61.5h640v360h-640z |

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37},"selected":true} | — |

## Normalization

14 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (7) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — controls-horizontal

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — controls-horizontal

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — panel-center-positions

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — panel-center-positions

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |


---

# System parity run — background-custom-bgcolor

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — background-custom-bgcolor

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 5 unclaimed difference(s).

## Unclaimed differences

### dom (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"10","y":"27","width":"48","height":"48","patternUnits":"userSpaceOnUse","patternTransform":"translate(-25,-25)"… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"10","y":"27","width":"48","height":"48","patternUnits":"userSpaceOnUse","p… |

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

6 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (4) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — flow-custom-testid

**Failed:** driving-divergence, unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — flow-custom-testid

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 5 driving divergence(s), 21 unclaimed difference(s).

**The inputs differed.** The driving log records what was done *to* each side — the target, whether
it resolved, the box it resolved to — and it does not agree. Selectors resolve against each side's
own render, so the pointer follows a divergence: two sides that place a node five pixels apart both
drag successfully while the two runs were not one experiment. Until the log agrees, every section
below it is a **consequence of the driving divergence**. None of them is suppressed —
a real divergence is exactly what would be hiding down there.

## Unclaimed differences

### driving (5)

| path | kind | upstream | psflow |
|---|---|---|---|
| `driving/1/resolved` | differs | true | false |
| `driving/1/box` | differs | {"x":0,"y":0,"width":1280,"height":720} | null |
| `driving/1/dispatched` | differs | {"x":8,"y":8,"button":"left"} | null |
| `driving/2/dispatched/x` | differs | 8 | 0 |
| `driving/2/dispatched/y` | differs | 8 | 0 |

### dom (1) — consequence of the driving divergence

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/attrs/data-testid` | differs | psflow-custom-flow | rf__wrapper |

### callbacks (18) — consequence of the driving divergence

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/8` | left only | {"name":"onMoveStart","args":[{"@class":"MouseEvent","isTrusted":true},{"x":490,"y":123,"zoom":2}]} | — |
| `callbacks/9` | left only | {"name":"onPaneClick","args":[{"@class":"SyntheticBaseEvent","_reactName":"onClick","_targetInst":null,"type":"click","nativeEvent":{"@class":"PointerEvent","i… | — |
| `callbacks/10` | left only | {"name":"onMoveEnd","args":[{"@class":"MouseEvent","isTrusted":true},{"x":490,"y":123,"zoom":2}]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1"] |
| `callbacks/6/args/0/screenX` | differs | 8 | 0 |
| `callbacks/6/args/0/screenY` | differs | 8 | 0 |
| `callbacks/6/args/0/clientX` | differs | 8 | 0 |
| `callbacks/6/args/0/clientY` | differs | 8 | 0 |
| `callbacks/6/args/0/pageX` | differs | 8 | 0 |
| `callbacks/6/args/0/pageY` | differs | 8 | 0 |
| `callbacks/7/args/0/screenX` | differs | 8 | 0 |
| `callbacks/7/args/0/screenY` | differs | 8 | 0 |
| `callbacks/7/args/0/clientX` | differs | 8 | 0 |
| `callbacks/7/args/0/clientY` | differs | 8 | 0 |
| `callbacks/7/args/0/pageX` | differs | 8 | 0 |
| `callbacks/7/args/0/pageY` | differs | 8 | 0 |
| `callbacks/7/args/0/movementX` | differs | 9 | 1 |
| `callbacks/7/args/0/movementY` | differs | 9 | 1 |

### api (2) — consequence of the driving divergence

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

5 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (3) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — custom-edge-baseedge-path

**Failed:** driving-divergence, unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — custom-edge-baseedge-path

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 13 driving divergence(s), 76 unclaimed difference(s).

**The inputs differed.** The driving log records what was done *to* each side — the target, whether
it resolved, the box it resolved to — and it does not agree. Selectors resolve against each side's
own render, so the pointer follows a divergence: two sides that place a node five pixels apart both
drag successfully while the two runs were not one experiment. Until the log agrees, every section
below it is a **consequence of the driving divergence**. None of them is suppressed —
a real divergence is exactly what would be hiding down there.

## Unclaimed differences

### driving (13)

| path | kind | upstream | psflow |
|---|---|---|---|
| `driving/0/resolved` | differs | true | false |
| `driving/0/box` | differs | {"x":0,"y":0,"width":1280,"height":720} | null |
| `driving/0/dispatched` | differs | {"route":"/tests/generic/edges/base-edge-path"} | null |
| `driving/1/resolved` | differs | true | false |
| `driving/1/box` | differs | {"x":356,"y":259,"width":288,"height":202} | null |
| `driving/1/dispatched` | differs | {"x":500,"y":360,"button":"left"} | null |
| `driving/2/dispatched/x` | differs | 500 | 0 |
| `driving/2/dispatched/y` | differs | 360 | 0 |
| `driving/3/resolved` | differs | true | false |
| `driving/3/box` | differs | {"x":619,"y":259,"width":322,"height":202} | null |
| `driving/3/dispatched` | differs | {"x":780,"y":360,"button":"left"} | null |
| `driving/4/dispatched/x` | differs | 780 | 0 |
| `driving/4/dispatched/y` | differs | 360 | 0 |

### dom (1) — consequence of the driving divergence

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root` | differs | {"tag":"div","attrs":{"data-testid":"rf__wrapper","class":"light react-flow","role":"application","style":"height: 100%; overflow: hidden; position: relative; … | null |

### callbacks (15) — consequence of the driving divergence

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/6` | left only | {"name":"onPaneMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onPointerEnter","_targetInst":{"@ref":"React fiber"},"type":"pointerenter","nat… | — |
| `callbacks/7` | left only | {"name":"onEdgeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… | — |
| `callbacks/8` | left only | {"name":"onPaneMouseMove","args":[{"@class":"SyntheticBaseEvent","_reactName":"onPointerMove","_targetInst":null,"type":"pointermove","nativeEvent":{"@class":"… | — |
| `callbacks/9` | left only | {"name":"onEdgeMouseMove","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseMove","_targetInst":null,"type":"mousemove","nativeEvent":{"@class":"Mous… | — |
| `callbacks/10` | left only | {"name":"onEdgesChange","args":[[{"id":"custom-1","type":"select","selected":true}]]} | — |
| `callbacks/11` | left only | {"name":"onEdgeClick","args":[{"@class":"SyntheticBaseEvent","_reactName":"onClick","_targetInst":null,"type":"click","nativeEvent":{"@class":"PointerEvent","i… | — |
| `callbacks/12` | left only | {"name":"onSelectionChange","args":[{"nodes":[],"edges":[{"id":"custom-1","type":"pathAttributes","source":"Node-1","target":"Node-2","selected":true}]}]} | — |
| `callbacks/13` | left only | {"name":"onEdgeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… | — |
| `callbacks/14` | left only | {"name":"onEdgeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… | — |
| `callbacks/15` | left only | {"name":"onPaneMouseMove","args":[{"@class":"SyntheticBaseEvent","_reactName":"onPointerMove","_targetInst":null,"type":"pointermove","nativeEvent":{"@class":"… | — |
| `callbacks/16` | left only | {"name":"onEdgeMouseMove","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseMove","_targetInst":null,"type":"mousemove","nativeEvent":{"@class":"Mous… | — |
| `callbacks/17` | left only | {"name":"onEdgesChange","args":[[{"id":"custom-1","type":"select","selected":false},{"id":"custom-2","type":"select","selected":true}]]} | — |
| `callbacks/18` | left only | {"name":"onEdgeClick","args":[{"@class":"SyntheticBaseEvent","_reactName":"onClick","_targetInst":null,"type":"click","nativeEvent":{"@class":"PointerEvent","i… | — |
| `callbacks/19` | left only | {"name":"onSelectionChange","args":[{"nodes":[],"edges":[{"id":"custom-2","type":"pathAttributes","source":"Node-1","target":"Node-3","label":"custom","selecte… | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (53) — consequence of the driving divergence

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |
| `api/queries/getNodes/1` | left only | {"id":"Node-2","data":{"label":"Node-2"},"position":{"x":-140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/getNodes/2` | left only | {"id":"Node-3","data":{"label":"Node-3"},"position":{"x":140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/getNode/id` | left only | Node-1 | — |
| `api/queries/getNode/data` | left only | {"label":"Node-1"} | — |
| `api/queries/getNode/position` | left only | {"x":0,"y":0} | — |
| `api/queries/getNode/type` | left only | input | — |
| `api/queries/getNode/measured` | left only | {"width":150,"height":37} | — |
| `api/queries/getNode/@undefined` | right only | — | true |
| `api/queries/getInternalNode/id` | left only | Node-1 | — |
| `api/queries/getInternalNode/data` | left only | {"label":"Node-1"} | — |
| `api/queries/getInternalNode/position` | left only | {"x":0,"y":0} | — |
| `api/queries/getInternalNode/type` | left only | input | — |
| `api/queries/getInternalNode/measured` | left only | {"width":150,"height":37} | — |
| `api/queries/getInternalNode/internals` | left only | {"positionAbsolute":{"x":0,"y":0},"handleBounds":{"source":[{"id":null,"type":"source","nodeId":"Node-1","position":"bottom","x":71,"y":32,"width":8,"height":8… | — |
| `api/queries/getInternalNode/@undefined` | right only | — | true |
| `api/queries/getEdges/0` | left only | {"id":"custom-1","type":"pathAttributes","source":"Node-1","target":"Node-2","selected":false} | — |
| `api/queries/getEdges/1` | left only | {"id":"custom-2","type":"pathAttributes","source":"Node-1","target":"Node-3","label":"custom","selected":true} | — |
| `api/queries/getEdges/2` | left only | {"id":"default-1","type":"default","source":"Node-2","target":"Node-3"} | — |
| `api/queries/getEdge/id` | left only | custom-1 | — |
| `api/queries/getEdge/type` | left only | pathAttributes | — |
| `api/queries/getEdge/source` | left only | Node-1 | — |
| `api/queries/getEdge/target` | left only | Node-2 | — |
| `api/queries/getEdge/selected` | left only | false | — |
| `api/queries/getEdge/@undefined` | right only | — | true |
| `api/queries/getIntersectingNodes/0` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |
| `api/queries/getIntersectingNodes/1` | left only | {"id":"Node-2","data":{"label":"Node-2"},"position":{"x":-140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/getIntersectingNodes/2` | left only | {"id":"Node-3","data":{"label":"Node-3"},"position":{"x":140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/isNodeIntersecting` | differs | true | false |
| `api/queries/getNodesBounds/x` | differs | -140 | 0 |
| `api/queries/getNodesBounds/width` | differs | 430 | 0 |
| `api/queries/getNodesBounds/height` | differs | 177 | 0 |
| `api/queries/getHandleConnections/0` | left only | {"edgeId":"custom-1","source":"Node-1","target":"Node-2","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/getHandleConnections/1` | left only | {"edgeId":"custom-2","source":"Node-1","target":"Node-3","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/getNodeConnections/0` | left only | {"edgeId":"custom-1","source":"Node-1","target":"Node-2","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/getNodeConnections/1` | left only | {"edgeId":"custom-2","source":"Node-1","target":"Node-3","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/toObject/nodes/0` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |
| `api/queries/toObject/nodes/1` | left only | {"id":"Node-2","data":{"label":"Node-2"},"position":{"x":-140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/toObject/nodes/2` | left only | {"id":"Node-3","data":{"label":"Node-3"},"position":{"x":140,"y":140},"measured":{"width":150,"height":37}} | — |
| `api/queries/toObject/edges/0` | left only | {"id":"custom-1","type":"pathAttributes","source":"Node-1","target":"Node-2","selected":false} | — |
| `api/queries/toObject/edges/1` | left only | {"id":"custom-2","type":"pathAttributes","source":"Node-1","target":"Node-3","label":"custom","selected":true} | — |
| `api/queries/toObject/edges/2` | left only | {"id":"default-1","type":"default","source":"Node-2","target":"Node-3"} | — |
| `api/queries/toObject/viewport/x` | differs | 490 | 0 |
| `api/queries/toObject/viewport/y` | differs | 183 | 0 |
| `api/queries/toObject/viewport/zoom` | differs | 2 | 1 |
| `api/queries/getZoom` | differs | 2 | 1 |
| `api/queries/getViewport/x` | differs | 490 | 0 |
| `api/queries/getViewport/y` | differs | 183 | 0 |
| `api/queries/getViewport/zoom` | differs | 2 | 1 |
| `api/queries/screenToFlowPosition/x` | differs | -245 | 0 |
| `api/queries/screenToFlowPosition/y` | differs | -91.5 | 0 |
| `api/queries/flowToScreenPosition/x` | differs | 490 | 0 |
| `api/queries/flowToScreenPosition/y` | differs | 183 | 0 |

### console (7) — consequence of the driving divergence

| path | kind | upstream | psflow |
|---|---|---|---|
| `console/1` | right only | — | {"level":"pageerror","text":"Failed pattern match at System.Utils.Edges.SmoothStep (line 39, column 19 - line 43, column 34): String"} |
| `console/2` | right only | — | {"level":"pageerror","text":"Failed pattern match at System.Utils.Edges.SmoothStep (line 39, column 19 - line 43, column 34): String"} |
| `console/3` | right only | — | {"level":"pageerror","text":"Failed pattern match at System.Utils.Edges.SmoothStep (line 39, column 19 - line 43, column 34): String"} |
| `console/4` | right only | — | {"level":"pageerror","text":"Failed pattern match at System.Utils.Edges.SmoothStep (line 39, column 19 - line 43, column 34): String"} |
| `console/5` | right only | — | {"level":"error","text":"The above error occurred in the <PathAttributeEdge> component:\n\n    at PathAttributeEdge (http://127.0.0.1:56822/parity/driver/dist/… |
| `console/6` | right only | — | {"level":"error","text":"The above error occurred in the <PathAttributeEdge> component:\n\n    at PathAttributeEdge (http://127.0.0.1:56822/parity/driver/dist/… |
| `console/7` | right only | — | {"level":"pageerror","text":"Failed pattern match at System.Utils.Edges.SmoothStep (line 39, column 19 - line 43, column 34): String"} |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (10) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — pinch-over-nowheel-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — pinch-over-nowheel-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseEnter#2","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseEnter#2","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"nowheel","data":{"label":"nowheel"},"position":{"x":0,"y":0},"className":"nowheel","style":{"width":400,"height":320},"measured":{"width":400,"height":3… | — |

## Normalization

24 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (12) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — minimap-default-click

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — minimap-default-click

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-184h1408v1088h-1408z⏎        M0,0h1280v720h-1280z | M-64,-184h1408v1088h-1408z M0,0h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"0","width":"20","height":"20","patternUnits":"userSpaceOnUse","patternTransform":"translate(-11,-11)"},… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"0","width":"20","height":"20","patternUnits":"userSpaceOnUse","pat… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |


---

# System parity run — controls-default-zoom

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — controls-default-zoom

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-177,-202h704v544h-704z⏎        M-145,-110h640v360h-640z | M-177,-202h704v544h-704z M-145,-110h640v360h-640z |
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"10","y":"20","width":"40","height":"40","patternUnits":"userSpaceOnUse","patternTransform":"translate(-21,-21)"… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"10","y":"20","width":"40","height":"40","patternUnits":"userSpaceOnUse","p… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |


---

# System parity run — wheel-zoom-from-identity-viewport

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — wheel-zoom-from-identity-viewport

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-56.251465064166375,-161.7229620594784h1237.53223141166v956.2749060908284h-1237.53223141166z⏎        M154.9706987166726,87.17101802812834h970.0586025666548v54… | M-56.251465064166375,-161.7229620594784h1237.53223141166v956.2749060908284h-1237.53223141166z M154.9706987166726,87.17101802812834h970.0586025666548v545.657963… |
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"-19.7539553864471","y":"-9.462215016410383","width":"26.390158215457884","height":"26.390158215457884","pattern… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"6.636202829010784","y":"16.92794319904749","width":"26.390158215457884","h… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |

## Normalization

4 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (2) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — pane-drag-from-identity-viewport

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — pane-drag-from-identity-viewport

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-164,-234h1408v1088h-1408z⏎        M-100,-50h1280v720h-1280z | M-164,-234h1408v1088h-1408z M-100,-50h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"10","width":"20","height":"20","patternUnits":"userSpaceOnUse","patternTransform":"translate(-11,-11)"}… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"10","width":"20","height":"20","patternUnits":"userSpaceOnUse","pa… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |

## Normalization

24 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (12) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-node-reports-changes

**Failed:** self-inconsistent, unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | **disagrees with itself** | 74 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(0px, 15px) scale(1); | transform: translate(0px, 13.125px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[0]/attrs/d` | differs | M148,50 C197.5,50 197.5,120 247,120 | M148,51.875 C197.5,51.875 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[1]/attrs/d` | differs | M148,50 C197.5,50 197.5,120 247,120 | M148,51.875 C197.5,51.875 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/circle[0]/attrs/cy` | differs | 50 | 51.875 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/n1/attrs/style` | differs | height: 40px; pointer-events: all; transform: translate(45px, 30px); visibility: visible; width: 100px; z-index: 1000; | height: 40px; pointer-events: all; transform: translate(45px, 31.875px); visibility: visible; width: 100px; z-index: 1000; |
| `dom/root/children/div[2]/children/svg[0]/attrs/viewBox` | differs | -32 -167 1344 1024 | -32 -165.125 1344 1024 |
| `dom/root/children/div[2]/children/svg[0]/children/rect[0]/attrs/y` | differs | 30 | 31.875 |
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-199h1408v1088h-1408z M0,-15h1280v720h-1280z | M-64,-197.125h1408v1088h-1408z M0,-13.125h1280v720h-1280z |
| `dom/root/children/svg[0]/children/defs[0]/children/pattern-1/attrs/y` | differs | 15 | 13.125 |
| `callbacks/31` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":13.125,"zoom":1}]} | — |
| `callbacks/32` | left only | {"name":"onViewportChange","args":[{"x":0,"y":15,"zoom":1}]} | — |
| `callbacks/33` | left only | {"name":"onMove","args":[null,{"x":0,"y":15,"zoom":1}]} | — |
| `callbacks/34` | left only | {"name":"onMoveEnd","args":[null,{"x":0,"y":15,"zoom":1}]} | — |
| `callbacks/57` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","position":{"x":45,"y":30},"data":{"label":"n1"},"sourcePosition":"right","tar… | — |
| `callbacks/58` | left only | {"name":"onNodesChange","args":[[{"type":"position","id":"n1","position":{"x":45,"y":30},"dragging":false}]]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/35/args/0/0/position/x` | differs | 10 | 15 |
| `callbacks/35/args/0/0/position/y` | differs | -5 | 1.875 |
| `callbacks/36/args/1/position/x` | differs | 10 | 15 |
| `callbacks/36/args/1/position/y` | differs | -5 | 1.875 |
| `callbacks/36/args/2/0/position/x` | differs | 10 | 15 |
| `callbacks/36/args/2/0/position/y` | differs | -5 | 1.875 |
| `callbacks/38/args/0/0/position/x` | differs | 15 | 20 |
| `callbacks/38/args/0/0/position/y` | differs | 0 | 6.875 |
| `callbacks/39/args/1/position/x` | differs | 15 | 20 |
| `callbacks/39/args/1/position/y` | differs | 0 | 6.875 |
| `callbacks/39/args/2/0/position/x` | differs | 15 | 20 |
| `callbacks/39/args/2/0/position/y` | differs | 0 | 6.875 |
| `callbacks/41/args/0/0/position/x` | differs | 20 | 25 |
| `callbacks/41/args/0/0/position/y` | differs | 5 | 11.875 |
| `callbacks/42/args/1/position/x` | differs | 20 | 25 |
| `callbacks/42/args/1/position/y` | differs | 5 | 11.875 |
| `callbacks/42/args/2/0/position/x` | differs | 20 | 25 |
| `callbacks/42/args/2/0/position/y` | differs | 5 | 11.875 |
| `callbacks/44/args/0/0/position/x` | differs | 25 | 30 |
| `callbacks/44/args/0/0/position/y` | differs | 10 | 16.875 |
| `callbacks/45/args/1/position/x` | differs | 25 | 30 |
| `callbacks/45/args/1/position/y` | differs | 10 | 16.875 |
| `callbacks/45/args/2/0/position/x` | differs | 25 | 30 |
| `callbacks/45/args/2/0/position/y` | differs | 10 | 16.875 |
| `callbacks/47/args/0/0/position/x` | differs | 30 | 35 |
| `callbacks/47/args/0/0/position/y` | differs | 15 | 21.875 |
| `callbacks/48/args/1/position/x` | differs | 30 | 35 |
| `callbacks/48/args/1/position/y` | differs | 15 | 21.875 |
| `callbacks/48/args/2/0/position/x` | differs | 30 | 35 |
| `callbacks/48/args/2/0/position/y` | differs | 15 | 21.875 |
| `callbacks/50/args/0/0/position/x` | differs | 35 | 40 |
| `callbacks/50/args/0/0/position/y` | differs | 20 | 26.875 |
| `callbacks/51/args/1/position/x` | differs | 35 | 40 |
| `callbacks/51/args/1/position/y` | differs | 20 | 26.875 |
| `callbacks/51/args/2/0/position/x` | differs | 35 | 40 |
| `callbacks/51/args/2/0/position/y` | differs | 20 | 26.875 |
| `callbacks/53/args/0/0/position/x` | differs | 40 | 45 |
| `callbacks/53/args/0/0/position/y` | differs | 25 | 31.875 |
| `callbacks/54/args/1/position/x` | differs | 40 | 45 |
| `callbacks/54/args/1/position/y` | differs | 25 | 31.875 |
| `callbacks/54/args/2/0/position/x` | differs | 40 | 45 |
| `callbacks/54/args/2/0/position/y` | differs | 25 | 31.875 |
| `callbacks/56/args/0/0/position/y` | differs | 30 | 31.875 |
| `callbacks/56/args/0/0/dragging` | differs | true | false |
| `callbacks/59/args/1/position/y` | differs | 30 | 31.875 |
| `callbacks/59/args/2/0/position/y` | differs | 30 | 31.875 |
| `api/queries/getNodes/0/position/y` | differs | 30 | 31.875 |
| `api/queries/getNode/position/y` | differs | 30 | 31.875 |
| `api/queries/getInternalNode/position/y` | differs | 30 | 31.875 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 30 | 31.875 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 30 | 31.875 |
| `api/queries/getNodesBounds/y` | differs | 30 | 31.875 |
| `api/queries/getNodesBounds/height` | differs | 110 | 108.125 |
| `api/queries/toObject/nodes/0/position/y` | differs | 30 | 31.875 |
| `api/queries/toObject/viewport/y` | differs | 15 | 13.125 |
| `api/queries/getViewport/y` | differs | 15 | 13.125 |
| `api/queries/screenToFlowPosition/y` | differs | -15 | -13.125 |
| `api/queries/flowToScreenPosition/y` | differs | 15 | 13.125 |

**psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — drag-node-reports-changes

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 80 unclaimed difference(s).

## Unclaimed differences

### dom (10)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(0px, 13.125px) scale(1); | transform: translate(0px, 15px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[0]/attrs/d` | differs | M148,51.875 C197.5,51.875 197.5,120 247,120 | M148,50 C197.5,50 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[1]/attrs/d` | differs | M148,51.875 C197.5,51.875 197.5,120 247,120 | M148,50 C197.5,50 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/circle[0]/attrs/cy` | differs | 51.875 | 50 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/n1/attrs/style` | differs | height: 40px; pointer-events: all; transform: translate(45px, 31.875px); visibility: visible; width: 100px; z-index: 1000; | height: 40px; pointer-events: all; transform: translate(45px, 30px); visibility: visible; width: 100px; z-index: 1000; |
| `dom/root/children/div[2]/children/svg[0]/attrs/viewBox` | differs | -32 -165.125 1344 1024 | -32 -167 1344 1024 |
| `dom/root/children/div[2]/children/svg[0]/children/rect[0]/attrs/y` | differs | 31.875 | 30 |
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-197.125h1408v1088h-1408z⏎        M0,-13.125h1280v720h-1280z | M-64,-199h1408v1088h-1408z M0,-15h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"13.125","width":"20","height":"20","patternUnits":"userSpaceOnUse","patternTransform":"translate(-11,-1… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"15","width":"20","height":"20","patternUnits":"userSpaceOnUse","pa… |

### callbacks (57)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/28` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":13.125,"zoom":1}]} |
| `callbacks/31` | right only | — | {"name":"onMoveStart","args":[null,{"x":0,"y":13.125,"zoom":1}]} |
| `callbacks/32` | right only | — | {"name":"onViewportChange","args":[{"x":0,"y":15,"zoom":1}]} |
| `callbacks/33` | right only | — | {"name":"onMove","args":[null,{"x":0,"y":15,"zoom":1}]} |
| `callbacks/34` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":15,"zoom":1}]} |
| `callbacks/57` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","position":{"x":45,"y":30},"data":{"label":"n1"},"sourcePosition":"right","tar… |
| `callbacks/58` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"n1","position":{"x":45,"y":30},"dragging":false}]]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/8/args/0/nodes/0` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |
| `callbacks/20/args/1/y` | differs | 11.25 | 7.5 |
| `callbacks/29/args/1/y` | differs | 13.125 | 11.25 |
| `callbacks/31/args/0/0/position/x` | differs | 15 | 10 |
| `callbacks/31/args/0/0/position/y` | differs | 1.875 | -5 |
| `callbacks/32/args/1/position/x` | differs | 15 | 10 |
| `callbacks/32/args/1/position/y` | differs | 1.875 | -5 |
| `callbacks/32/args/2/0/position/x` | differs | 15 | 10 |
| `callbacks/32/args/2/0/position/y` | differs | 1.875 | -5 |
| `callbacks/34/args/0/0/position/x` | differs | 20 | 15 |
| `callbacks/34/args/0/0/position/y` | differs | 6.875 | 0 |
| `callbacks/35/args/1/position/x` | differs | 20 | 15 |
| `callbacks/35/args/1/position/y` | differs | 6.875 | 0 |
| `callbacks/35/args/2/0/position/x` | differs | 20 | 15 |
| `callbacks/35/args/2/0/position/y` | differs | 6.875 | 0 |
| `callbacks/37/args/0/0/position/x` | differs | 25 | 20 |
| `callbacks/37/args/0/0/position/y` | differs | 11.875 | 5 |
| `callbacks/38/args/1/position/x` | differs | 25 | 20 |
| `callbacks/38/args/1/position/y` | differs | 11.875 | 5 |
| `callbacks/38/args/2/0/position/x` | differs | 25 | 20 |
| `callbacks/38/args/2/0/position/y` | differs | 11.875 | 5 |
| `callbacks/40/args/0/0/position/x` | differs | 30 | 25 |
| `callbacks/40/args/0/0/position/y` | differs | 16.875 | 10 |
| `callbacks/41/args/1/position/x` | differs | 30 | 25 |
| `callbacks/41/args/1/position/y` | differs | 16.875 | 10 |
| `callbacks/41/args/2/0/position/x` | differs | 30 | 25 |
| `callbacks/41/args/2/0/position/y` | differs | 16.875 | 10 |
| `callbacks/43/args/0/0/position/x` | differs | 35 | 30 |
| `callbacks/43/args/0/0/position/y` | differs | 21.875 | 15 |
| `callbacks/44/args/1/position/x` | differs | 35 | 30 |
| `callbacks/44/args/1/position/y` | differs | 21.875 | 15 |
| `callbacks/44/args/2/0/position/x` | differs | 35 | 30 |
| `callbacks/44/args/2/0/position/y` | differs | 21.875 | 15 |
| `callbacks/46/args/0/0/position/x` | differs | 40 | 35 |
| `callbacks/46/args/0/0/position/y` | differs | 26.875 | 20 |
| `callbacks/47/args/1/position/x` | differs | 40 | 35 |
| `callbacks/47/args/1/position/y` | differs | 26.875 | 20 |
| `callbacks/47/args/2/0/position/x` | differs | 40 | 35 |
| `callbacks/47/args/2/0/position/y` | differs | 26.875 | 20 |
| `callbacks/49/args/0/0/position/x` | differs | 45 | 40 |
| `callbacks/49/args/0/0/position/y` | differs | 31.875 | 25 |
| `callbacks/50/args/1/position/x` | differs | 45 | 40 |
| `callbacks/50/args/1/position/y` | differs | 31.875 | 25 |
| `callbacks/50/args/2/0/position/x` | differs | 45 | 40 |
| `callbacks/50/args/2/0/position/y` | differs | 31.875 | 25 |
| `callbacks/51/args/0/0/position/y` | differs | 31.875 | 30 |
| `callbacks/51/args/0/0/dragging` | differs | false | true |
| `callbacks/52/args/1/position/y` | differs | 31.875 | 30 |
| `callbacks/52/args/2/0/position/y` | differs | 31.875 | 30 |

### api (13)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0/position/y` | differs | 31.875 | 30 |
| `api/queries/getNode/position/y` | differs | 31.875 | 30 |
| `api/queries/getInternalNode/position/y` | differs | 31.875 | 30 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 31.875 | 30 |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":45,"y":31.875},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":10… | — |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 31.875 | 30 |
| `api/queries/getNodesBounds/y` | differs | 31.875 | 30 |
| `api/queries/getNodesBounds/height` | differs | 108.125 | 110 |
| `api/queries/toObject/nodes/0/position/y` | differs | 31.875 | 30 |
| `api/queries/toObject/viewport/y` | differs | 13.125 | 15 |
| `api/queries/getViewport/y` | differs | 13.125 | 15 |
| `api/queries/screenToFlowPosition/y` | differs | -13.125 | -15 |
| `api/queries/flowToScreenPosition/y` | differs | 13.125 | 15 |

## Normalization

28 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (22) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — click-connect-reverse-direction

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — click-connect-reverse-direction

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 35 unclaimed difference(s).

## Unclaimed differences

### dom (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-184h1408v1088h-1408z⏎        M0,0h1280v720h-1280z | M-64,-184h1408v1088h-1408z M0,0h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"0","width":"20","height":"20","patternUnits":"userSpaceOnUse","patternTransform":"translate(-11,-11)"},… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"0","width":"20","height":"20","patternUnits":"userSpaceOnUse","pat… |

### callbacks (31)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/5/args/0/@class` | differs | PointerEvent | SyntheticBaseEvent |
| `callbacks/5/args/0/_reactName` | right only | — | onClick |
| `callbacks/5/args/0/_targetInst` | right only | — | null |
| `callbacks/5/args/0/type` | right only | — | click |
| `callbacks/5/args/0/nativeEvent` | right only | — | {"@class":"PointerEvent","isTrusted":true} |
| `callbacks/5/args/0/target` | right only | — | {"@ref":"DIV"} |
| `callbacks/5/args/0/currentTarget` | right only | — | {"@ref":"DIV"} |
| `callbacks/5/args/0/eventPhase` | right only | — | 3 |
| `callbacks/5/args/0/bubbles` | right only | — | true |
| `callbacks/5/args/0/cancelable` | right only | — | true |
| `callbacks/5/args/0/defaultPrevented` | right only | — | false |
| `callbacks/5/args/0/view` | right only | — | {"@ref":"Window"} |
| `callbacks/5/args/0/detail` | right only | — | 1 |
| `callbacks/5/args/0/screenX` | right only | — | 349 |
| `callbacks/5/args/0/screenY` | right only | — | 120 |
| `callbacks/5/args/0/clientX` | right only | — | 349 |
| `callbacks/5/args/0/clientY` | right only | — | 120 |
| `callbacks/5/args/0/pageX` | right only | — | 349 |
| `callbacks/5/args/0/pageY` | right only | — | 120 |
| `callbacks/5/args/0/ctrlKey` | right only | — | false |
| `callbacks/5/args/0/shiftKey` | right only | — | false |
| `callbacks/5/args/0/altKey` | right only | — | false |
| `callbacks/5/args/0/metaKey` | right only | — | false |
| `callbacks/5/args/0/getModifierState` | right only | — | {"@ref":"function"} |
| `callbacks/5/args/0/button` | right only | — | 0 |
| `callbacks/5/args/0/buttons` | right only | — | 0 |
| `callbacks/5/args/0/relatedTarget` | right only | — | null |
| `callbacks/5/args/0/movementX` | right only | — | 0 |
| `callbacks/5/args/0/movementY` | right only | — | 0 |
| `callbacks/5/args/0/isDefaultPrevented` | right only | — | {"@ref":"function"} |
| `callbacks/5/args/0/isPropagationStopped` | right only | — | {"@ref":"function"} |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |

## Normalization

23 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (12) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — connect-drag-holding-source

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — connect-drag-holding-source

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 35 unclaimed difference(s).

## Unclaimed differences

### dom (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-184h1408v1088h-1408z⏎        M0,0h1280v720h-1280z | M-64,-184h1408v1088h-1408z M0,0h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"0","width":"20","height":"20","patternUnits":"userSpaceOnUse","patternTransform":"translate(-11,-11)"},… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"0","width":"20","height":"20","patternUnits":"userSpaceOnUse","pat… |

### callbacks (31)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/9/args/0/@class` | differs | MouseEvent | SyntheticBaseEvent |
| `callbacks/9/args/0/_reactName` | right only | — | onMouseDown |
| `callbacks/9/args/0/_targetInst` | right only | — | null |
| `callbacks/9/args/0/type` | right only | — | mousedown |
| `callbacks/9/args/0/nativeEvent` | right only | — | {"@class":"MouseEvent","isTrusted":true} |
| `callbacks/9/args/0/target` | right only | — | {"@ref":"DIV"} |
| `callbacks/9/args/0/currentTarget` | right only | — | null |
| `callbacks/9/args/0/eventPhase` | right only | — | 3 |
| `callbacks/9/args/0/bubbles` | right only | — | true |
| `callbacks/9/args/0/cancelable` | right only | — | true |
| `callbacks/9/args/0/defaultPrevented` | right only | — | false |
| `callbacks/9/args/0/view` | right only | — | {"@ref":"Window"} |
| `callbacks/9/args/0/detail` | right only | — | 1 |
| `callbacks/9/args/0/screenX` | right only | — | 99 |
| `callbacks/9/args/0/screenY` | right only | — | 20 |
| `callbacks/9/args/0/clientX` | right only | — | 99 |
| `callbacks/9/args/0/clientY` | right only | — | 20 |
| `callbacks/9/args/0/pageX` | right only | — | 99 |
| `callbacks/9/args/0/pageY` | right only | — | 20 |
| `callbacks/9/args/0/ctrlKey` | right only | — | false |
| `callbacks/9/args/0/shiftKey` | right only | — | false |
| `callbacks/9/args/0/altKey` | right only | — | false |
| `callbacks/9/args/0/metaKey` | right only | — | false |
| `callbacks/9/args/0/getModifierState` | right only | — | {"@ref":"function"} |
| `callbacks/9/args/0/button` | right only | — | 0 |
| `callbacks/9/args/0/buttons` | right only | — | 1 |
| `callbacks/9/args/0/relatedTarget` | right only | — | null |
| `callbacks/9/args/0/movementX` | right only | — | 0 |
| `callbacks/9/args/0/movementY` | right only | — | 0 |
| `callbacks/9/args/0/isDefaultPrevented` | right only | — | {"@ref":"function"} |
| `callbacks/9/args/0/isPropagationStopped` | right only | — | {"@ref":"function"} |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |

## Normalization

21 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (11) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — connect-drag-released-on-pane

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — connect-drag-released-on-pane

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 37 unclaimed difference(s).

## Unclaimed differences

### dom (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-184h1408v1088h-1408z⏎        M0,0h1280v720h-1280z | M-64,-184h1408v1088h-1408z M0,0h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1` | left only | {"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"0","width":"20","height":"20","patternUnits":"userSpaceOnUse","patternTransform":"translate(-11,-11)"},… | — |
| `dom/root/children/svg[0]/children/defs[0]` | right only | — | {"tag":"defs","attrs":{},"children":[{"tag":"pattern","attrs":{"id":"pattern-1","x":"0","y":"0","width":"20","height":"20","patternUnits":"userSpaceOnUse","pat… |

### callbacks (33)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/9/args/0/@class` | differs | MouseEvent | SyntheticBaseEvent |
| `callbacks/9/args/0/_reactName` | right only | — | onMouseDown |
| `callbacks/9/args/0/_targetInst` | right only | — | null |
| `callbacks/9/args/0/type` | right only | — | mousedown |
| `callbacks/9/args/0/nativeEvent` | right only | — | {"@class":"MouseEvent","isTrusted":true} |
| `callbacks/9/args/0/target` | right only | — | {"@ref":"DIV"} |
| `callbacks/9/args/0/currentTarget` | right only | — | null |
| `callbacks/9/args/0/eventPhase` | right only | — | 3 |
| `callbacks/9/args/0/bubbles` | right only | — | true |
| `callbacks/9/args/0/cancelable` | right only | — | true |
| `callbacks/9/args/0/defaultPrevented` | right only | — | false |
| `callbacks/9/args/0/view` | right only | — | {"@ref":"Window"} |
| `callbacks/9/args/0/detail` | right only | — | 1 |
| `callbacks/9/args/0/screenX` | right only | — | 99 |
| `callbacks/9/args/0/screenY` | right only | — | 20 |
| `callbacks/9/args/0/clientX` | right only | — | 99 |
| `callbacks/9/args/0/clientY` | right only | — | 20 |
| `callbacks/9/args/0/pageX` | right only | — | 99 |
| `callbacks/9/args/0/pageY` | right only | — | 20 |
| `callbacks/9/args/0/ctrlKey` | right only | — | false |
| `callbacks/9/args/0/shiftKey` | right only | — | false |
| `callbacks/9/args/0/altKey` | right only | — | false |
| `callbacks/9/args/0/metaKey` | right only | — | false |
| `callbacks/9/args/0/getModifierState` | right only | — | {"@ref":"function"} |
| `callbacks/9/args/0/button` | right only | — | 0 |
| `callbacks/9/args/0/buttons` | right only | — | 1 |
| `callbacks/9/args/0/relatedTarget` | right only | — | null |
| `callbacks/9/args/0/movementX` | right only | — | 0 |
| `callbacks/9/args/0/movementY` | right only | — | 0 |
| `callbacks/9/args/0/isDefaultPrevented` | right only | — | {"@ref":"function"} |
| `callbacks/9/args/0/isPropagationStopped` | right only | — | {"@ref":"function"} |
| `callbacks/12/args/1/fromNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |
| `callbacks/12/args/1/toPosition` | differs | null | left |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |

## Normalization

21 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (11) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — node-props-record-parented

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — node-props-record-parented

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouse… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouse… |

### api (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"props-parent","type":"propsRecord","data":{"label":"props-parent"},"position":{"x":100,"y":200},"width":300,"height":200,"measured":{"width":300,"height… | — |

## Normalization

20 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (11) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — wheel-zooms-to-changed-limits

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — wheel-zooms-to-changed-limits

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |
| `api/queries/screenToFlowPosition/x` | differs | {"@number":"-0"} | 0 |

## Normalization

4 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (2) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-pans-into-changed-extent

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — drag-pans-into-changed-extent

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

8 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (4) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — pan-after-controlled-viewport-change

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — pan-after-controlled-viewport-change

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onMove#1","onNodesChange#1","onMoveEnd#1","onMoveStart#2","onMove#2","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveEn… | ["onSelectionChange#1","onMoveStart#1","onMove#1","onMoveEnd#1","onNodesChange#1","onMoveStart#2","onMove#2","onMoveEnd#2","onPaneMouseEnter#1","onPaneMouseMov… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

8 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — ctrl-wheel-pinches-with-panonscroll

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — ctrl-wheel-pinches-with-panonscroll

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

4 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (2) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — pane-click-keeps-selection-when-not-selectable

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — pane-click-keeps-selection-when-not-selectable

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","selected":true,"measured":{"width":150,"height":37}} | — |

## Normalization

6 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (4) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — click-selects-node--probe-flow-node

**Failed:** unclaimed-difference.

Compared sections: `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — click-selects-node--probe-flow-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 29 unclaimed difference(s).

## Unclaimed differences

### callbacks (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/1` | right only | — | {"name":"useOnSelectionChange","args":[{"nodes":[{"id":"Node-1","position":{"x":0,"y":0},"data":{"label":"Node-1"},"type":"input","selected":true,"measured":{"… |
| `callbacks/0/args/0/nodes/0` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

### hooks (12)

| path | kind | upstream | psflow |
|---|---|---|---|
| `hooks/flow-probe/useConnection/inProgress` | left only | false | — |
| `hooks/flow-probe/useInternalNode/internals/handleBounds/target` | differs | null | [] |
| `hooks/flow-probe/useInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |
| `hooks/flow-probe/useStore/nodes` | left only | [{"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"me… | — |
| `hooks/flow-probe/useStore/edges` | left only | [{"id":"1-2","type":"default","source":"Node-1","target":"Node-2","label":"edge"},{"id":"1-3","type":"default","source":"Node-1","target":"Node-3","label":"edg… | — |
| `hooks/flow-probe/useStore/transform` | left only | [517.8398510242085,32,1.2216014897579144] | — |
| `hooks/flow-probe/useStore/viewportInitialized` | left only | {"@undefined":true} | — |
| `hooks/flow-probe/useStore/error` | right only | — | ps-flow: `useStore` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's obj… |
| `hooks/flow-probe/useStoreApi/getState` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/setState` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/subscribe` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/error` | right only | — | ps-flow: `useStoreApi` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's … |

### api (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getState` | left only | {"rfId":"1","width":1280,"height":720,"transform":[517.8398510242085,32,1.2216014897579144],"nodes":[{"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0… | — |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

### props (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `props/node-props/width` | differs | 0 | {"@undefined":true} |
| `props/node-props/height` | differs | 0 | {"@undefined":true} |

### console (10)

| path | kind | upstream | psflow |
|---|---|---|---|
| `console/1/level` | differs | warning | pageerror |
| `console/1/text` | differs | [DEPRECATED] `useHandleConnections` is deprecated. Instead use `useNodeConnections` https://reactflow.dev/api-reference/hooks/useNodeConnections | ps-flow: `useStore` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's obj… |
| `console/2/level` | differs | warning | pageerror |
| `console/2/text` | differs | [DEPRECATED] `useHandleConnections` is deprecated. Instead use `useNodeConnections` https://reactflow.dev/api-reference/hooks/useNodeConnections | ps-flow: `useStoreApi` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's … |
| `console/3/level` | differs | warning | pageerror |
| `console/3/text` | differs | [DEPRECATED] `useHandleConnections` is deprecated. Instead use `useNodeConnections` https://reactflow.dev/api-reference/hooks/useNodeConnections | ps-flow: `useStore` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's obj… |
| `console/4/level` | differs | warning | pageerror |
| `console/4/text` | differs | [DEPRECATED] `useHandleConnections` is deprecated. Instead use `useNodeConnections` https://reactflow.dev/api-reference/hooks/useNodeConnections | ps-flow: `useStoreApi` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's … |
| `console/5` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:56822/parity/driver/dist/psflow.js:65668:… |
| `console/6` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:56822/parity/driver/dist/psflow.js:65668:… |


---

# System parity run — wheel-zooms-the-pane--probe-flow-node

**Failed:** unclaimed-difference.

Compared sections: `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — wheel-zooms-the-pane--probe-flow-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 26 unclaimed difference(s).

## Unclaimed differences

### hooks (12)

| path | kind | upstream | psflow |
|---|---|---|---|
| `hooks/flow-probe/useConnection/inProgress` | left only | false | — |
| `hooks/flow-probe/useInternalNode/internals/handleBounds/target` | differs | null | [] |
| `hooks/flow-probe/useInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |
| `hooks/flow-probe/useStore/nodes` | left only | [{"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}},{"id":"2","data":{"label":"2"},"position":{"x":-1… | — |
| `hooks/flow-probe/useStore/edges` | left only | [{"id":"first-edge","source":"1","target":"2"},{"id":"second-edge","source":"1","target":"3"}] | — |
| `hooks/flow-probe/useStore/transform` | left only | [552.9449436703876,121.469145656862,3.4822022531844965] | — |
| `hooks/flow-probe/useStore/viewportInitialized` | left only | {"@undefined":true} | — |
| `hooks/flow-probe/useStore/error` | right only | — | ps-flow: `useStore` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's obj… |
| `hooks/flow-probe/useStoreApi/getState` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/setState` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/subscribe` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/error` | right only | — | ps-flow: `useStoreApi` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's … |

### api (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getState` | left only | {"rfId":"1","width":1280,"height":720,"transform":[552.9449436703876,121.469145656862,3.4822022531844965],"nodes":[{"id":"1","data":{"label":"1"},"position":{"… | — |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

### props (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `props/node-props/width` | differs | 0 | {"@undefined":true} |
| `props/node-props/height` | differs | 0 | {"@undefined":true} |

### console (9)

| path | kind | upstream | psflow |
|---|---|---|---|
| `console/1/level` | differs | warning | pageerror |
| `console/1/text` | differs | [DEPRECATED] `useHandleConnections` is deprecated. Instead use `useNodeConnections` https://reactflow.dev/api-reference/hooks/useNodeConnections | ps-flow: `useStore` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's obj… |
| `console/2/level` | differs | warning | pageerror |
| `console/2/text` | differs | [DEPRECATED] `useHandleConnections` is deprecated. Instead use `useNodeConnections` https://reactflow.dev/api-reference/hooks/useNodeConnections | ps-flow: `useStoreApi` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's … |
| `console/3/level` | differs | warning | pageerror |
| `console/3/text` | differs | [DEPRECATED] `useHandleConnections` is deprecated. Instead use `useNodeConnections` https://reactflow.dev/api-reference/hooks/useNodeConnections | ps-flow: `useStore` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's obj… |
| `console/4` | right only | — | {"level":"pageerror","text":"ps-flow: `useStoreApi` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScri… |
| `console/5` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:56822/parity/driver/dist/psflow.js:65668:… |
| `console/6` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:56822/parity/driver/dist/psflow.js:65668:… |


---

# System parity run — mount-baseline--edges-general--probe-edge

**Failed:** unclaimed-difference.

Compared sections: `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--edges-general--probe-edge

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### props (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `props/edge-component-props/selectable` | differs | true | {"@undefined":true} |
| `props/edge-component-props/deletable` | differs | true | {"@undefined":true} |
| `props/edge-props/selectable` | differs | true | {"@undefined":true} |
| `props/edge-props/deletable` | differs | true | {"@undefined":true} |


---

# System parity run — connect-source-handle-to-target-handle--probe-connection-line

**Failed:** unclaimed-difference.

Compared sections: `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — connect-source-handle-to-target-handle--probe-connection-line

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `props`, `console`.

**Failed:** 6 unclaimed difference(s).

## Unclaimed differences

### props (6)

| path | kind | upstream | psflow |
|---|---|---|---|
| `props/connection-line-props/fromNode/internals/handleBounds/target` | differs | null | [] |
| `props/connection-line-props/fromNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |
| `props/connection-line-props/toX` | differs | 75.00000000000003 | 614.25431711146 |
| `props/connection-line-props/toY` | differs | 201 | 238.99529042386186 |
| `props/connection-line-props/toNode/internals/handleBounds/source` | differs | null | [] |
| `props/connection-line-props/toNode/internals/userNode` | left only | {"id":"Node-4","data":{"label":"Node-4"},"position":{"x":0,"y":200},"type":"output","measured":{"width":150,"height":37}} | — |

