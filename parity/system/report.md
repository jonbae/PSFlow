# System parity

The dual-run net over 103 scenario(s), against vendored `@xyflow/react` 12.11.0.

Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice.

**100 of 103 scenario(s) failed.**

A failing net is the expected state while the divergence backlog is being worked: the scenarios below
are recording what the two implementations actually do, and a difference is fixed in the port or
claimed by a region — never by loosening what the net looks at.

| scenario | verdict | failure classes | differences |
|---|---|---|---|
| `mount-baseline--edges-general` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--node-toolbar-general` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-general` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--pane-general` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--pane-non-defaults` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--chrome-background` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--chrome-controls` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--chrome-minimap-colors` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--chrome-minimap-hidden-nodes` | **failed** | unclaimed-difference | 1 |
| `mount-baseline--chrome-panels` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--edges-base-edge-path` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--fitview-uncontrolled` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--flow-chrome-defaults` | **failed** | unclaimed-difference | 1 |
| `mount-baseline--flow-custom-testid` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--flow-display-none` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--flow-limits-change` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--flow-not-selectable` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--flow-props-change` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--nodes-autopan` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-connections` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-expand-parent` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-no-select-on-drag` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--nodes-nowheel` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-props-record` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--nodes-tall` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-unmeasured` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--viewport-controlled` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--viewport-helpers` | **failed** | unclaimed-difference | 3 |
| `mount-baseline--viewport-pan-on-scroll` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--examples-color-mode` | passed | — | 0 |
| `click-selects-edge` | **failed** | unclaimed-difference | 3 |
| `multi-select-edges-with-modifier` | **failed** | unclaimed-difference | 3 |
| `click-unselectable-edge` | **failed** | unclaimed-difference | 3 |
| `delete-key-removes-edge` | **failed** | unclaimed-difference | 3 |
| `delete-key-spares-undeletable-edge` | **failed** | unclaimed-difference | 3 |
| `click-inside-interaction-width` | **failed** | unclaimed-difference | 3 |
| `click-selects-node` | **failed** | unclaimed-difference | 3 |
| `shift-drag-selects-nodes` | **failed** | unclaimed-difference | 4 |
| `click-unselectable-node` | **failed** | unclaimed-difference | 3 |
| `drag-moves-node` | **failed** | unclaimed-difference | 3 |
| `drag-does-not-move-undraggable-node` | **failed** | unclaimed-difference | 3 |
| `drag-by-custom-drag-handle` | **failed** | unclaimed-difference | 3 |
| `delete-key-removes-node-and-edges` | **failed** | unclaimed-difference | 3 |
| `delete-key-spares-undeletable-node` | **failed** | unclaimed-difference | 3 |
| `connect-source-handle-to-target-handle` | **failed** | unclaimed-difference | 7 |
| `connect-output-to-output-handle` | **failed** | unclaimed-difference | 7 |
| `connect-input-to-input-handle` | **failed** | unclaimed-difference | 6 |
| `connect-to-unconnectable-handle` | **failed** | unclaimed-difference | 7 |
| `drag-pans-the-pane` | **failed** | unclaimed-difference | 3 |
| `wheel-zooms-the-pane` | **failed** | unclaimed-difference | 3 |
| `wheel-zooms-out-to-min` | **failed** | unclaimed-difference | 3 |
| `wheel-zooms-in-to-max` | **failed** | unclaimed-difference | 3 |
| `wheel-pans-with-panonscroll` | **failed** | unclaimed-difference | 2 |
| `click-reveals-default-toolbar` | **failed** | unclaimed-difference | 2 |
| `select-dark-color-mode` | passed | — | 0 |
| `drag-node-release` | **failed** | unclaimed-difference | 3 |
| `drag-node-escape-mid-gesture` | **failed** | unclaimed-difference | 20 |
| `drag-node-autopan` | **failed** | self-inconsistent, unclaimed-difference | 249 |
| `drag-node-no-select-on-drag` | **failed** | unclaimed-difference | 3 |
| `drag-child-expand-parent` | **failed** | unclaimed-difference | 2 |
| `drag-unmeasured-node` | **failed** | unclaimed-difference | 3 |
| `selection-box-from-node` | **failed** | unclaimed-difference | 3 |
| `selection-box-then-click-node` | **failed** | unclaimed-difference | 3 |
| `selection-box-mid-gesture` | **failed** | unclaimed-difference | 3 |
| `selection-box-touch` | **failed** | unclaimed-difference | 4 |
| `arrow-key-selected-node` | **failed** | self-inconsistent, unclaimed-difference | 34 |
| `keyboard-focus-node` | **failed** | unclaimed-difference | 2 |
| `connect-handle-to-handle` | **failed** | unclaimed-difference | 7 |
| `connect-then-keyboard-move` | **failed** | unclaimed-difference | 4 |
| `connect-second-touch-point` | **failed** | unclaimed-difference | 4 |
| `probe-node-connections` | **failed** | unclaimed-difference | 4 |
| `viewport-helpers-with-options` | **failed** | unclaimed-difference | 3 |
| `pan-gesture-complete` | **failed** | unclaimed-difference | 3 |
| `fitview-onnodeschange-variants` | **failed** | unclaimed-difference | 3 |
| `uncontrolled-update-node` | **failed** | unclaimed-difference | 3 |
| `flow-props-change-after-mount` | **failed** | unclaimed-difference | 3 |
| `mount-in-display-none` | **failed** | unclaimed-difference | 3 |
| `minimap-all-nodes-hidden` | **failed** | unclaimed-difference | 1 |
| `minimap-custom-mask-colors` | **failed** | unclaimed-difference | 3 |
| `controls-horizontal` | **failed** | unclaimed-difference | 3 |
| `panel-center-positions` | **failed** | unclaimed-difference | 3 |
| `background-custom-bgcolor` | **failed** | unclaimed-difference | 3 |
| `flow-custom-testid` | **failed** | unclaimed-difference | 3 |
| `custom-edge-baseedge-path` | **failed** | unclaimed-difference | 3 |
| `pinch-over-nowheel-node` | **failed** | unclaimed-difference | 2 |
| `minimap-default-click` | **failed** | unclaimed-difference | 1 |
| `controls-default-zoom` | **failed** | unclaimed-difference | 1 |
| `wheel-zoom-from-identity-viewport` | **failed** | unclaimed-difference | 3 |
| `pane-drag-from-identity-viewport` | **failed** | unclaimed-difference | 1 |
| `drag-node-reports-changes` | **failed** | self-inconsistent, unclaimed-difference | 175 |
| `click-connect-reverse-direction` | **failed** | unclaimed-difference | 1 |
| `connect-drag-holding-source` | **failed** | unclaimed-difference | 1 |
| `connect-drag-released-on-pane` | **failed** | unclaimed-difference | 2 |
| `node-props-record-parented` | **failed** | unclaimed-difference | 4 |
| `wheel-zooms-to-changed-limits` | **failed** | unclaimed-difference | 4 |
| `drag-pans-into-changed-extent` | **failed** | unclaimed-difference | 2 |
| `pan-after-controlled-viewport-change` | **failed** | unclaimed-difference | 3 |
| `ctrl-wheel-pinches-with-panonscroll` | **failed** | unclaimed-difference | 2 |
| `pane-click-keeps-selection-when-not-selectable` | **failed** | unclaimed-difference | 3 |
| `click-selects-node--probe-flow-node` | **failed** | unclaimed-difference | 29 |
| `wheel-zooms-the-pane--probe-flow-node` | **failed** | unclaimed-difference | 26 |
| `mount-baseline--edges-general--probe-edge` | passed | — | 0 |
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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

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

# Comparison report — mount-baseline--edges-base-edge-path

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

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

**Passed.** Both sides reproduced themselves, and the two sides agree everywhere unclaimed.

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

**No unclaimed differences.** The two traces agree everywhere.


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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

12 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (6) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

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

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[1]/children/div[0]/attrs/style` | left only | height: 137px; width: 350px; | — |

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onSelectionStart#1","onNodesChange#2","onEdgesChange#1"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onSelectionStart#1","onNodesChange#2","onEdgesChange#1"… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

4 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (2) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-2","type":"output","data":{"label":"Node-2"},"position":{"x":-100,"y":100},"measured":{"width":150,"height":37}} | — |

## Normalization

12 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (6) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 7 unclaimed difference(s).

## Unclaimed differences

### callbacks (5)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
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

24 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (12) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 7 unclaimed difference(s).

## Unclaimed differences

### callbacks (5)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
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

20 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (10) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 6 unclaimed difference(s).

## Unclaimed differences

### callbacks (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/19/args/1/fromNode/internals/handleBounds/target` | differs | null | [] |
| `callbacks/19/args/1/fromNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |
| `callbacks/19/args/1/toNode/internals/userNode` | left only | {"id":"Node-3","data":{"label":"Node-3"},"position":{"x":100,"y":100},"measured":{"width":150,"height":37}} | — |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

24 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (12) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 7 unclaimed difference(s).

## Unclaimed differences

### callbacks (5)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
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

22 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (11) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"default-node","type":"ToolbarNode","data":{"label":"toolbar top","toolbarPosition":"top"},"position":{"x":0,"y":-200},"className":"react-flow__node-defa… | — |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — select-dark-color-mode

**Passed.** Both sides reproduced themselves, and the two sides agree everywhere unclaimed.

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

**No unclaimed differences.** The two traces agree everywhere.


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
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":58.26219512195121,"y":38.84146341463414},"type":"input","className":"playwright-test-class-123","style… | — |

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

**Failed:** 20 unclaimed difference(s).

## Unclaimed differences

### callbacks (18)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/23` | right only | — | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… |
| `callbacks/24` | right only | — | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
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
| psflow | 1, 2 | **disagrees with itself** | 112 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(2000px, 2000px) scale(1); | transform: translate(1720px, 1940px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[0]/attrs/d` | differs | M-1995,-1973 C-1995,-938 -25,-938 -25,97 | M-1715,-1913 C-1715,-908 -25,-908 -25,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[1]/attrs/d` | differs | M-1995,-1973 C-1995,-938 -25,-938 -25,97 | M-1715,-1913 C-1715,-908 -25,-908 -25,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cx` | differs | -1995 | -1715 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cy` | differs | -1963 | -1903 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/path[0]/attrs/d` | differs | M-1995,-1973 C-1995,-938 175,-938 175,97 | M-1715,-1913 C-1715,-908 175,-908 175,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/path[1]/attrs/d` | differs | M-1995,-1973 C-1995,-938 175,-938 175,97 | M-1715,-1913 C-1715,-908 175,-908 175,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[0]/attrs/cx` | differs | -1995 | -1715 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[0]/attrs/cy` | differs | -1963 | -1903 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-1/attrs/style` | differs | pointer-events: all; transform: translate(-2070px, -2013px); visibility: visible; z-index: 1000; | pointer-events: all; transform: translate(-1790px, -1953px); visibility: visible; z-index: 1000; |
| `callbacks/54` | left only | {"name":"onMoveStart","args":[null,{"x":1720,"y":1920,"zoom":1}]} | — |
| `callbacks/55` | left only | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/56` | left only | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/57` | left only | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/60` | left only | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… | — |
| `callbacks/61` | left only | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/62` | left only | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/63` | left only | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/64` | left only | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/67` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"Node-1","position":{"x":-2070,"y":-2013},"data":{"label":"Node-1"},"type":"input",… | — |
| `callbacks/68` | left only | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/69` | left only | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/70` | left only | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/71` | left only | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/72` | left only | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… | — |
| `callbacks/73` | left only | {"name":"onNodesChange","args":[[{"type":"position","id":"Node-1","position":{"x":-2070,"y":-2013},"dragging":false}]]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… |
| `callbacks/28/args/1/position/x` | differs | -749 | -409 |
| `callbacks/28/args/1/position/y` | differs | -692 | -352 |
| `callbacks/30/args/0/x` | differs | 1020 | 1030 |
| `callbacks/31/args/1/x` | differs | 1020 | 1030 |
| `callbacks/32/args/1/x` | differs | 1020 | 1030 |
| `callbacks/33/args/0/0/position/x` | differs | -1089 | -750 |
| `callbacks/33/args/0/0/position/y` | differs | -1032 | -912 |
| `callbacks/34/args/1/position/x` | differs | -1089 | -750 |
| `callbacks/34/args/1/position/y` | differs | -1032 | -912 |
| `callbacks/34/args/2/0/position/x` | differs | -1089 | -750 |
| `callbacks/34/args/2/0/position/y` | differs | -1032 | -912 |
| `callbacks/36/args/0/0/position/x` | differs | -1090 | -1100 |
| `callbacks/37/args/1/position/x` | differs | -1090 | -1100 |
| `callbacks/37/args/2/0/position/x` | differs | -1090 | -1100 |
| `callbacks/38/args/1/x` | differs | 1020 | 1030 |
| `callbacks/39/args/0/y` | differs | 1580 | 1590 |
| `callbacks/40/args/1/y` | differs | 1580 | 1590 |
| `callbacks/41/args/1/y` | differs | 1580 | 1590 |
| `callbacks/42/args/0/0/position/x` | differs | -1440 | -1099 |
| `callbacks/42/args/0/0/position/y` | differs | -1592 | -1253 |
| `callbacks/43/args/1/position/x` | differs | -1440 | -1099 |
| `callbacks/43/args/1/position/y` | differs | -1592 | -1253 |
| `callbacks/43/args/2/0/position/x` | differs | -1440 | -1099 |
| `callbacks/43/args/2/0/position/y` | differs | -1592 | -1253 |
| `callbacks/44/args/0/screenX` | differs | 5 | 6 |
| `callbacks/44/args/0/screenY` | differs | 6 | 5 |
| `callbacks/44/args/0/clientX` | differs | 5 | 6 |
| `callbacks/44/args/0/clientY` | differs | 6 | 5 |
| `callbacks/44/args/0/pageX` | differs | 5 | 6 |
| `callbacks/44/args/0/pageY` | differs | 6 | 5 |
| `callbacks/44/args/1/position/x` | differs | -1440 | -1100 |
| `callbacks/44/args/1/position/y` | differs | -1592 | -1252 |
| `callbacks/45/args/1/y` | differs | 1580 | 1590 |
| `callbacks/46/args/0/y` | differs | 1920 | 1940 |
| `callbacks/47/args/1/y` | differs | 1920 | 1940 |
| `callbacks/48/args/1/y` | differs | 1920 | 1940 |
| `callbacks/49/args/0/0/position/x` | differs | -1790 | -1439 |
| `callbacks/49/args/0/0/position/y` | differs | -1932 | -1603 |
| `callbacks/50/args/1/position/x` | differs | -1790 | -1439 |
| `callbacks/50/args/1/position/y` | differs | -1932 | -1603 |
| `callbacks/50/args/2/0/position/x` | differs | -1790 | -1439 |
| `callbacks/50/args/2/0/position/y` | differs | -1932 | -1603 |
| `callbacks/52/args/0/0/position/x` | differs | -1789 | -1440 |
| `callbacks/52/args/0/0/position/y` | differs | -1933 | -1603 |
| `callbacks/53/args/1/position/x` | differs | -1789 | -1440 |
| `callbacks/53/args/1/position/y` | differs | -1933 | -1603 |
| `callbacks/53/args/2/0/position/x` | differs | -1789 | -1440 |
| `callbacks/53/args/2/0/position/y` | differs | -1933 | -1603 |
| `callbacks/58/args/0/0/position/x` | differs | -2129 | -1790 |
| `callbacks/58/args/0/0/position/y` | differs | -2283 | -1953 |
| `callbacks/59/args/1/position/x` | differs | -2129 | -1790 |
| `callbacks/59/args/1/position/y` | differs | -2283 | -1953 |
| `callbacks/59/args/2/0/position/x` | differs | -2129 | -1790 |
| `callbacks/59/args/2/0/position/y` | differs | -2283 | -1953 |
| `callbacks/66/args/0/0/position/x` | differs | -2070 | -1790 |
| `callbacks/66/args/0/0/position/y` | differs | -2013 | -1953 |
| `callbacks/66/args/0/0/dragging` | differs | true | false |
| `callbacks/74/args/1/position/x` | differs | -2070 | -1790 |
| `callbacks/74/args/1/position/y` | differs | -2013 | -1953 |
| `callbacks/74/args/2/0/position/x` | differs | -2070 | -1790 |
| `callbacks/74/args/2/0/position/y` | differs | -2013 | -1953 |
| `api/queries/getNodes/0/position/x` | differs | -2070 | -1790 |
| `api/queries/getNodes/0/position/y` | differs | -2013 | -1953 |
| `api/queries/getNode/position/x` | differs | -2070 | -1790 |
| `api/queries/getNode/position/y` | differs | -2013 | -1953 |
| `api/queries/getInternalNode/position/x` | differs | -2070 | -1790 |
| `api/queries/getInternalNode/position/y` | differs | -2013 | -1953 |
| `api/queries/getInternalNode/internals/positionAbsolute/x` | differs | -2070 | -1790 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | -2013 | -1953 |
| `api/queries/getIntersectingNodes/0/position/x` | differs | -2070 | -1790 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | -2013 | -1953 |
| `api/queries/getNodesBounds/x` | differs | -2070 | -1790 |
| `api/queries/getNodesBounds/y` | differs | -2013 | -1953 |
| `api/queries/getNodesBounds/width` | differs | 2320 | 2040 |
| `api/queries/getNodesBounds/height` | differs | 2150 | 2090 |
| `api/queries/toObject/nodes/0/position/x` | differs | -2070 | -1790 |
| `api/queries/toObject/nodes/0/position/y` | differs | -2013 | -1953 |
| `api/queries/toObject/viewport/x` | differs | 2000 | 1720 |
| `api/queries/toObject/viewport/y` | differs | 2000 | 1940 |
| `api/queries/getViewport/x` | differs | 2000 | 1720 |
| `api/queries/getViewport/y` | differs | 2000 | 1940 |
| `api/queries/screenToFlowPosition/x` | differs | -2000 | -1720 |
| `api/queries/screenToFlowPosition/y` | differs | -2000 | -1940 |
| `api/queries/flowToScreenPosition/x` | differs | 2000 | 1720 |
| `api/queries/flowToScreenPosition/y` | differs | 2000 | 1940 |

**psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — drag-node-autopan

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 137 unclaimed difference(s).

## Unclaimed differences

### dom (10)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(1380px, 1600px) scale(1); | transform: translate(2000px, 2000px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[0]/attrs/d` | differs | M-1375,-1573 C-1375,-738 -25,-738 -25,97 | M-1995,-1973 C-1995,-938 -25,-938 -25,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[1]/attrs/d` | differs | M-1375,-1573 C-1375,-738 -25,-738 -25,97 | M-1995,-1973 C-1995,-938 -25,-938 -25,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cx` | differs | -1375 | -1995 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cy` | differs | -1563 | -1963 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/path[0]/attrs/d` | differs | M-1375,-1573 C-1375,-738 175,-738 175,97 | M-1995,-1973 C-1995,-938 175,-938 175,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/path[1]/attrs/d` | differs | M-1375,-1573 C-1375,-738 175,-738 175,97 | M-1995,-1973 C-1995,-938 175,-938 175,97 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[0]/attrs/cx` | differs | -1375 | -1995 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[0]/attrs/cy` | differs | -1563 | -1963 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-1/attrs/style` | differs | pointer-events: all; transform: translate(-1450px, -1613px); visibility: visible; z-index: 1000; | pointer-events: all; transform: translate(-2070px, -2013px); visibility: visible; z-index: 1000; |

### callbacks (101)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/41` | right only | — | {"name":"onMoveEnd","args":[null,{"x":1370,"y":1580,"zoom":1}]} |
| `callbacks/45` | right only | — | {"name":"onMoveStart","args":[null,{"x":1370,"y":1580,"zoom":1}]} |
| `callbacks/46` | right only | — | {"name":"onViewportChange","args":[{"x":1720,"y":1920,"zoom":1}]} |
| `callbacks/47` | right only | — | {"name":"onMove","args":[null,{"x":1720,"y":1920,"zoom":1}]} |
| `callbacks/48` | right only | — | {"name":"onMoveEnd","args":[null,{"x":1720,"y":1920,"zoom":1}]} |
| `callbacks/54` | right only | — | {"name":"onMoveStart","args":[null,{"x":1720,"y":1920,"zoom":1}]} |
| `callbacks/55` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/56` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/57` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/59` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"Node-1","position":{"x":-2129,"y":-2283},"data":{"label":"Node-1"},"type":"input",… |
| `callbacks/60` | right only | — | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… |
| `callbacks/61` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/62` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/63` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/64` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/66` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"Node-1","position":{"x":-2070,"y":-2013},"dragging":true}]]} |
| `callbacks/67` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"Node-1","position":{"x":-2070,"y":-2013},"data":{"label":"Node-1"},"type":"input",… |
| `callbacks/68` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/69` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/70` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/71` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/72` | right only | — | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… |
| `callbacks/73` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"Node-1","position":{"x":-2070,"y":-2013},"dragging":false}]]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… |
| `callbacks/20/args/1/x` | differs | 340 | 0 |
| `callbacks/20/args/1/y` | differs | 560 | 220.00000000000003 |
| `callbacks/21/args/0/screenX` | differs | 5 | 6 |
| `callbacks/21/args/0/clientX` | differs | 5 | 6 |
| `callbacks/21/args/0/pageX` | differs | 5 | 6 |
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
| `callbacks/28/args/0/0/position/x` | differs | -760 | -1089 |
| `callbacks/28/args/0/0/position/y` | differs | -912 | -1032 |
| `callbacks/29/args/1/position/x` | differs | -760 | -1089 |
| `callbacks/29/args/1/position/y` | differs | -912 | -1032 |
| `callbacks/29/args/2/0/position/x` | differs | -760 | -1089 |
| `callbacks/29/args/2/0/position/y` | differs | -912 | -1032 |
| `callbacks/30/args/1/x` | differs | 690 | 340 |
| `callbacks/30/args/1/y` | differs | 900 | 560 |
| `callbacks/31/args/0/screenX` | differs | 6 | 5 |
| `callbacks/31/args/0/screenY` | differs | 5 | 6 |
| `callbacks/31/args/0/clientX` | differs | 6 | 5 |
| `callbacks/31/args/0/clientY` | differs | 5 | 6 |
| `callbacks/31/args/0/pageX` | differs | 6 | 5 |
| `callbacks/31/args/0/pageY` | differs | 5 | 6 |
| `callbacks/31/args/1/position/x` | differs | -760 | -1440 |
| `callbacks/31/args/1/position/y` | differs | -912 | -1592 |
| `callbacks/33/args/0/0/position/x` | differs | -759 | -1090 |
| `callbacks/33/args/0/0/position/y` | differs | -913 | -1252 |
| `callbacks/34/args/1/position/x` | differs | -759 | -1090 |
| `callbacks/34/args/1/position/y` | differs | -913 | -1252 |
| `callbacks/34/args/2/0/position/x` | differs | -759 | -1090 |
| `callbacks/34/args/2/0/position/y` | differs | -913 | -1252 |
| `callbacks/35/args/1/x` | differs | 690 | 680 |
| `callbacks/36/args/0/x` | differs | 1030 | 1020 |
| `callbacks/36/args/0/y` | differs | 1250 | 1240 |
| `callbacks/37/args/1/x` | differs | 1030 | 1020 |
| `callbacks/37/args/1/y` | differs | 1250 | 1240 |
| `callbacks/38/args/0/0/position/x` | differs | -1099 | -1440 |
| `callbacks/38/args/0/0/position/y` | differs | -1263 | -1592 |
| `callbacks/39/args/1/position/x` | differs | -1099 | -1440 |
| `callbacks/39/args/1/position/y` | differs | -1263 | -1592 |
| `callbacks/39/args/2/0/position/x` | differs | -1099 | -1440 |
| `callbacks/39/args/2/0/position/y` | differs | -1263 | -1592 |
| `callbacks/40/args/1/x` | differs | 1030 | 680 |
| `callbacks/40/args/1/y` | differs | 1250 | 900 |
| `callbacks/42/args/0/0/position/x` | differs | -1100 | -1790 |
| `callbacks/42/args/0/0/position/y` | differs | -1263 | -1932 |
| `callbacks/43/args/1/position/x` | differs | -1100 | -1790 |
| `callbacks/43/args/1/position/y` | differs | -1263 | -1932 |
| `callbacks/43/args/2/0/position/x` | differs | -1100 | -1790 |
| `callbacks/43/args/2/0/position/y` | differs | -1263 | -1932 |
| `callbacks/44/args/1/x` | differs | 1030 | 1020 |
| `callbacks/44/args/1/y` | differs | 1250 | 1240 |
| `callbacks/45/args/0/x` | differs | 1380 | 1370 |
| `callbacks/45/args/0/y` | differs | 1600 | 1580 |
| `callbacks/46/args/1/x` | differs | 1380 | 1370 |
| `callbacks/46/args/1/y` | differs | 1600 | 1580 |
| `callbacks/47/args/0/0/position/x` | differs | -1450 | -1789 |
| `callbacks/47/args/0/0/position/y` | differs | -1613 | -1933 |
| `callbacks/48/args/1/position/x` | differs | -1450 | -1789 |
| `callbacks/48/args/1/position/y` | differs | -1613 | -1933 |
| `callbacks/48/args/2/0/position/x` | differs | -1450 | -1789 |
| `callbacks/48/args/2/0/position/y` | differs | -1613 | -1933 |
| `callbacks/49/args/1/x` | differs | 1380 | 1020 |
| `callbacks/49/args/1/y` | differs | 1600 | 1240 |
| `callbacks/50/args/0/0/position/x` | differs | -1450 | -2129 |
| `callbacks/50/args/0/0/position/y` | differs | -1613 | -2283 |
| `callbacks/50/args/0/0/dragging` | differs | false | true |
| `callbacks/51/args/1/position/x` | differs | -1450 | -2070 |
| `callbacks/51/args/1/position/y` | differs | -1613 | -2013 |
| `callbacks/51/args/2/0/position/x` | differs | -1450 | -2070 |
| `callbacks/51/args/2/0/position/y` | differs | -1613 | -2013 |

### api (26)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0/position/x` | differs | -1450 | -2070 |
| `api/queries/getNodes/0/position/y` | differs | -1613 | -2013 |
| `api/queries/getNode/position/x` | differs | -1450 | -2070 |
| `api/queries/getNode/position/y` | differs | -1613 | -2013 |
| `api/queries/getInternalNode/position/x` | differs | -1450 | -2070 |
| `api/queries/getInternalNode/position/y` | differs | -1613 | -2013 |
| `api/queries/getInternalNode/internals/positionAbsolute/x` | differs | -1450 | -2070 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | -1613 | -2013 |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":-1450,"y":-1613},"type":"input","measured":{"width":150,"height":37},"selected":true,"dragging":false} | — |
| `api/queries/getIntersectingNodes/0/position/x` | differs | -1450 | -2070 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | -1613 | -2013 |
| `api/queries/getNodesBounds/x` | differs | -1450 | -2070 |
| `api/queries/getNodesBounds/y` | differs | -1613 | -2013 |
| `api/queries/getNodesBounds/width` | differs | 1700 | 2320 |
| `api/queries/getNodesBounds/height` | differs | 1750 | 2150 |
| `api/queries/toObject/nodes/0/position/x` | differs | -1450 | -2070 |
| `api/queries/toObject/nodes/0/position/y` | differs | -1613 | -2013 |
| `api/queries/toObject/viewport/x` | differs | 1380 | 2000 |
| `api/queries/toObject/viewport/y` | differs | 1600 | 2000 |
| `api/queries/getViewport/x` | differs | 1380 | 2000 |
| `api/queries/getViewport/y` | differs | 1600 | 2000 |
| `api/queries/screenToFlowPosition/x` | differs | -1380 | -2000 |
| `api/queries/screenToFlowPosition/y` | differs | -1600 | -2000 |
| `api/queries/flowToScreenPosition/x` | differs | 1380 | 2000 |
| `api/queries/flowToScreenPosition/y` | differs | 1600 | 2000 |

## Normalization

22 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (17) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

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
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":50,"y":30},"type":"input","selected":true,"measured":{"width":150,"height":37},"dragging":false} | — |

## Normalization

18 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (9) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onNodeMouseEnter#1","onNodeMouseMove#1","onSelectionSta… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onNodeMouseEnter#1","onNodeMouseMove#1","onSelectionSta… |

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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMov… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMov… |

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

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[1]/children/div[0]/attrs/style` | differs | -webkit-tap-highlight-color: rgba(0, 0, 0, 0); height: 37px; touch-action: none; width: 150px; | -webkit-tap-highlight-color: rgba(0, 0, 0, 0); touch-action: none; |

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onNodesChange#2","onNodeDragStart#1","onSelectionChange… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onNodesChange#2","onNodeDragStart#1","onSelectionChange… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

6 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (3) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 7 unclaimed difference(s).

## Unclaimed differences

### callbacks (5)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
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

46 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (23) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/g[0]/children/path[0]/attrs/d` | differs | M75,36 C75,45.67454268292683 94.17378048780492,45.67454268292683 94.17378048780492,55.349085365853654 | M75,36 C75,62.5 634,62.5 634,89 |

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

26 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (13) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/g[0]/children/path[0]/attrs/d` | differs | M75,36 C75,74.8414673688935 133.2622110320301,74.8414673688935 133.2622110320301,113.68293473778701 | M75,36 C75,92.53689575195312 674.2543334960938,92.53689575195312 674.2543334960938,149.07379150390625 |

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onConnectStart… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onConnectStart… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

## Normalization

10 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (5) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### callbacks (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/18/args/1/fromNode/internals/userNode` | left only | {"id":"down-1","type":"connections","data":{"label":"down-1"},"position":{"x":0,"y":320},"measured":{"width":49,"height":18}} | — |
| `callbacks/18/args/1/toNode/internals/userNode` | left only | {"id":"hub","type":"connections","data":{"label":"hub"},"position":{"x":160,"y":160},"measured":{"width":24,"height":18}} | — |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"hub","type":"connections","data":{"label":"hub"},"position":{"x":160,"y":160},"measured":{"width":24,"height":18}} | — |

## Normalization

18 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (9) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

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
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

6 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (4) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — flow-custom-testid

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

# Comparison report — flow-custom-testid

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
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

6 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (4) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — custom-edge-baseedge-path

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

# Comparison report — custom-edge-baseedge-path

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |

## Normalization

20 field(s) deleted by name and therefore **unobserved** — not passing:

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### dom (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/svg[0]/children/pattern-1/attrs/x` | differs | -19.7539553864471 | 6.636202829010784 |
| `dom/root/children/svg[0]/children/pattern-1/attrs/y` | differs | -9.462215016410383 | 16.92794319904749 |

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

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
| psflow | 1, 2 | **disagrees with itself** | 86 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(0px, 16.875px) scale(1); | transform: translate(0px, 13.125px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[0]/attrs/d` | differs | M148,48.125 C197.5,48.125 197.5,120 247,120 | M148,51.875 C197.5,51.875 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[1]/attrs/d` | differs | M148,48.125 C197.5,48.125 197.5,120 247,120 | M148,51.875 C197.5,51.875 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/circle[0]/attrs/cy` | differs | 48.125 | 51.875 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/n1/attrs/style` | differs | height: 40px; pointer-events: all; transform: translate(45px, 28.125px); visibility: visible; width: 100px; z-index: 1000; | height: 40px; pointer-events: all; transform: translate(45px, 31.875px); visibility: visible; width: 100px; z-index: 1000; |
| `dom/root/children/div[2]/children/svg[0]/attrs/viewBox` | differs | -32 -168.875 1344 1024 | -32 -165.125 1344 1024 |
| `dom/root/children/div[2]/children/svg[0]/children/rect[0]/attrs/y` | differs | 28.125 | 31.875 |
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-200.875h1408v1088h-1408z⏎        M0,-16.875h1280v720h-1280z | M-64,-197.125h1408v1088h-1408z⏎        M0,-13.125h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1/attrs/y` | differs | 16.875 | 13.125 |
| `callbacks/31` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":15,"zoom":1}]} | — |
| `callbacks/32` | left only | {"name":"onViewportChange","args":[{"x":0,"y":16.875,"zoom":1}]} | — |
| `callbacks/33` | left only | {"name":"onMove","args":[null,{"x":0,"y":16.875,"zoom":1}]} | — |
| `callbacks/34` | left only | {"name":"onMoveEnd","args":[null,{"x":0,"y":16.875,"zoom":1}]} | — |
| `callbacks/57` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","position":{"x":45,"y":28.125},"data":{"label":"n1"},"sourcePosition":"right",… | — |
| `callbacks/58` | left only | {"name":"onNodesChange","args":[[{"type":"position","id":"n1","position":{"x":45,"y":28.125},"dragging":false}]]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/23/args/0/y` | differs | 15 | 13.125 |
| `callbacks/24/args/1/y` | differs | 15 | 13.125 |
| `callbacks/25/args/1/y` | differs | 15 | 13.125 |
| `callbacks/26/args/0/0/position/x` | differs | 5 | 10 |
| `callbacks/26/args/0/0/position/y` | differs | -2.5 | -1.25 |
| `callbacks/27/args/1/position/x` | differs | 5 | 10 |
| `callbacks/27/args/1/position/y` | differs | -2.5 | -1.25 |
| `callbacks/27/args/2/0/position/x` | differs | 5 | 10 |
| `callbacks/27/args/2/0/position/y` | differs | -2.5 | -1.25 |
| `callbacks/29/args/0/0/position/y` | differs | -5 | -3.125 |
| `callbacks/30/args/1/position/y` | differs | -5 | -3.125 |
| `callbacks/30/args/2/0/position/y` | differs | -5 | -3.125 |
| `callbacks/35/args/0/0/position/x` | differs | 10 | 15 |
| `callbacks/35/args/0/0/position/y` | differs | -6.875 | 1.875 |
| `callbacks/36/args/1/position/x` | differs | 10 | 15 |
| `callbacks/36/args/1/position/y` | differs | -6.875 | 1.875 |
| `callbacks/36/args/2/0/position/x` | differs | 10 | 15 |
| `callbacks/36/args/2/0/position/y` | differs | -6.875 | 1.875 |
| `callbacks/38/args/0/0/position/x` | differs | 15 | 20 |
| `callbacks/38/args/0/0/position/y` | differs | -1.875 | 6.875 |
| `callbacks/39/args/1/position/x` | differs | 15 | 20 |
| `callbacks/39/args/1/position/y` | differs | -1.875 | 6.875 |
| `callbacks/39/args/2/0/position/x` | differs | 15 | 20 |
| `callbacks/39/args/2/0/position/y` | differs | -1.875 | 6.875 |
| `callbacks/41/args/0/0/position/x` | differs | 20 | 25 |
| `callbacks/41/args/0/0/position/y` | differs | 3.125 | 11.875 |
| `callbacks/42/args/1/position/x` | differs | 20 | 25 |
| `callbacks/42/args/1/position/y` | differs | 3.125 | 11.875 |
| `callbacks/42/args/2/0/position/x` | differs | 20 | 25 |
| `callbacks/42/args/2/0/position/y` | differs | 3.125 | 11.875 |
| `callbacks/44/args/0/0/position/x` | differs | 25 | 30 |
| `callbacks/44/args/0/0/position/y` | differs | 8.125 | 16.875 |
| `callbacks/45/args/1/position/x` | differs | 25 | 30 |
| `callbacks/45/args/1/position/y` | differs | 8.125 | 16.875 |
| `callbacks/45/args/2/0/position/x` | differs | 25 | 30 |
| `callbacks/45/args/2/0/position/y` | differs | 8.125 | 16.875 |
| `callbacks/47/args/0/0/position/x` | differs | 30 | 35 |
| `callbacks/47/args/0/0/position/y` | differs | 13.125 | 21.875 |
| `callbacks/48/args/1/position/x` | differs | 30 | 35 |
| `callbacks/48/args/1/position/y` | differs | 13.125 | 21.875 |
| `callbacks/48/args/2/0/position/x` | differs | 30 | 35 |
| `callbacks/48/args/2/0/position/y` | differs | 13.125 | 21.875 |
| `callbacks/50/args/0/0/position/x` | differs | 35 | 40 |
| `callbacks/50/args/0/0/position/y` | differs | 18.125 | 26.875 |
| `callbacks/51/args/1/position/x` | differs | 35 | 40 |
| `callbacks/51/args/1/position/y` | differs | 18.125 | 26.875 |
| `callbacks/51/args/2/0/position/x` | differs | 35 | 40 |
| `callbacks/51/args/2/0/position/y` | differs | 18.125 | 26.875 |
| `callbacks/53/args/0/0/position/x` | differs | 40 | 45 |
| `callbacks/53/args/0/0/position/y` | differs | 23.125 | 31.875 |
| `callbacks/54/args/1/position/x` | differs | 40 | 45 |
| `callbacks/54/args/1/position/y` | differs | 23.125 | 31.875 |
| `callbacks/54/args/2/0/position/x` | differs | 40 | 45 |
| `callbacks/54/args/2/0/position/y` | differs | 23.125 | 31.875 |
| `callbacks/56/args/0/0/position/y` | differs | 28.125 | 31.875 |
| `callbacks/56/args/0/0/dragging` | differs | true | false |
| `callbacks/59/args/1/position/y` | differs | 28.125 | 31.875 |
| `callbacks/59/args/2/0/position/y` | differs | 28.125 | 31.875 |
| `api/queries/getNodes/0/position/y` | differs | 28.125 | 31.875 |
| `api/queries/getNode/position/y` | differs | 28.125 | 31.875 |
| `api/queries/getInternalNode/position/y` | differs | 28.125 | 31.875 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 28.125 | 31.875 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 28.125 | 31.875 |
| `api/queries/getNodesBounds/y` | differs | 28.125 | 31.875 |
| `api/queries/getNodesBounds/height` | differs | 111.875 | 108.125 |
| `api/queries/toObject/nodes/0/position/y` | differs | 28.125 | 31.875 |
| `api/queries/toObject/viewport/y` | differs | 16.875 | 13.125 |
| `api/queries/getViewport/y` | differs | 16.875 | 13.125 |
| `api/queries/screenToFlowPosition/y` | differs | -16.875 | -13.125 |
| `api/queries/flowToScreenPosition/y` | differs | 16.875 | 13.125 |

**psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — drag-node-reports-changes

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 89 unclaimed difference(s).

## Unclaimed differences

### dom (9)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(0px, 13.125px) scale(1); | transform: translate(0px, 16.875px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[0]/attrs/d` | differs | M148,51.875 C197.5,51.875 197.5,120 247,120 | M148,48.125 C197.5,48.125 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[1]/attrs/d` | differs | M148,51.875 C197.5,51.875 197.5,120 247,120 | M148,48.125 C197.5,48.125 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/circle[0]/attrs/cy` | differs | 51.875 | 48.125 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/n1/attrs/style` | differs | height: 40px; pointer-events: all; transform: translate(45px, 31.875px); visibility: visible; width: 100px; z-index: 1000; | height: 40px; pointer-events: all; transform: translate(45px, 28.125px); visibility: visible; width: 100px; z-index: 1000; |
| `dom/root/children/div[2]/children/svg[0]/attrs/viewBox` | differs | -32 -165.125 1344 1024 | -32 -168.875 1344 1024 |
| `dom/root/children/div[2]/children/svg[0]/children/rect[0]/attrs/y` | differs | 31.875 | 28.125 |
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-197.125h1408v1088h-1408z⏎        M0,-13.125h1280v720h-1280z | M-64,-200.875h1408v1088h-1408z⏎        M0,-16.875h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1/attrs/y` | differs | 13.125 | 16.875 |

### callbacks (67)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/25` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":15,"zoom":1}]} |
| `callbacks/31` | right only | — | {"name":"onMoveStart","args":[null,{"x":0,"y":15,"zoom":1}]} |
| `callbacks/32` | right only | — | {"name":"onViewportChange","args":[{"x":0,"y":16.875,"zoom":1}]} |
| `callbacks/33` | right only | — | {"name":"onMove","args":[null,{"x":0,"y":16.875,"zoom":1}]} |
| `callbacks/34` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":16.875,"zoom":1}]} |
| `callbacks/57` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","position":{"x":45,"y":28.125},"data":{"label":"n1"},"sourcePosition":"right",… |
| `callbacks/58` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"n1","position":{"x":45,"y":28.125},"dragging":false}]]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/20/args/1/y` | differs | 11.25 | 7.5 |
| `callbacks/22/args/0/0/position/x` | differs | 10 | 5 |
| `callbacks/22/args/0/0/position/y` | differs | -1.25 | -2.5 |
| `callbacks/23/args/1/position/x` | differs | 10 | 5 |
| `callbacks/23/args/1/position/y` | differs | -1.25 | -2.5 |
| `callbacks/23/args/2/0/position/x` | differs | 10 | 5 |
| `callbacks/23/args/2/0/position/y` | differs | -1.25 | -2.5 |
| `callbacks/25/args/0/y` | differs | 13.125 | 15 |
| `callbacks/26/args/1/y` | differs | 13.125 | 15 |
| `callbacks/27/args/0/0/position/y` | differs | -3.125 | -5 |
| `callbacks/28/args/1/position/y` | differs | -3.125 | -5 |
| `callbacks/28/args/2/0/position/y` | differs | -3.125 | -5 |
| `callbacks/29/args/1/y` | differs | 13.125 | 11.25 |
| `callbacks/31/args/0/0/position/x` | differs | 15 | 10 |
| `callbacks/31/args/0/0/position/y` | differs | 1.875 | -6.875 |
| `callbacks/32/args/1/position/x` | differs | 15 | 10 |
| `callbacks/32/args/1/position/y` | differs | 1.875 | -6.875 |
| `callbacks/32/args/2/0/position/x` | differs | 15 | 10 |
| `callbacks/32/args/2/0/position/y` | differs | 1.875 | -6.875 |
| `callbacks/34/args/0/0/position/x` | differs | 20 | 15 |
| `callbacks/34/args/0/0/position/y` | differs | 6.875 | -1.875 |
| `callbacks/35/args/1/position/x` | differs | 20 | 15 |
| `callbacks/35/args/1/position/y` | differs | 6.875 | -1.875 |
| `callbacks/35/args/2/0/position/x` | differs | 20 | 15 |
| `callbacks/35/args/2/0/position/y` | differs | 6.875 | -1.875 |
| `callbacks/37/args/0/0/position/x` | differs | 25 | 20 |
| `callbacks/37/args/0/0/position/y` | differs | 11.875 | 3.125 |
| `callbacks/38/args/1/position/x` | differs | 25 | 20 |
| `callbacks/38/args/1/position/y` | differs | 11.875 | 3.125 |
| `callbacks/38/args/2/0/position/x` | differs | 25 | 20 |
| `callbacks/38/args/2/0/position/y` | differs | 11.875 | 3.125 |
| `callbacks/40/args/0/0/position/x` | differs | 30 | 25 |
| `callbacks/40/args/0/0/position/y` | differs | 16.875 | 8.125 |
| `callbacks/41/args/1/position/x` | differs | 30 | 25 |
| `callbacks/41/args/1/position/y` | differs | 16.875 | 8.125 |
| `callbacks/41/args/2/0/position/x` | differs | 30 | 25 |
| `callbacks/41/args/2/0/position/y` | differs | 16.875 | 8.125 |
| `callbacks/43/args/0/0/position/x` | differs | 35 | 30 |
| `callbacks/43/args/0/0/position/y` | differs | 21.875 | 13.125 |
| `callbacks/44/args/1/position/x` | differs | 35 | 30 |
| `callbacks/44/args/1/position/y` | differs | 21.875 | 13.125 |
| `callbacks/44/args/2/0/position/x` | differs | 35 | 30 |
| `callbacks/44/args/2/0/position/y` | differs | 21.875 | 13.125 |
| `callbacks/46/args/0/0/position/x` | differs | 40 | 35 |
| `callbacks/46/args/0/0/position/y` | differs | 26.875 | 18.125 |
| `callbacks/47/args/1/position/x` | differs | 40 | 35 |
| `callbacks/47/args/1/position/y` | differs | 26.875 | 18.125 |
| `callbacks/47/args/2/0/position/x` | differs | 40 | 35 |
| `callbacks/47/args/2/0/position/y` | differs | 26.875 | 18.125 |
| `callbacks/49/args/0/0/position/x` | differs | 45 | 40 |
| `callbacks/49/args/0/0/position/y` | differs | 31.875 | 23.125 |
| `callbacks/50/args/1/position/x` | differs | 45 | 40 |
| `callbacks/50/args/1/position/y` | differs | 31.875 | 23.125 |
| `callbacks/50/args/2/0/position/x` | differs | 45 | 40 |
| `callbacks/50/args/2/0/position/y` | differs | 31.875 | 23.125 |
| `callbacks/51/args/0/0/position/y` | differs | 31.875 | 28.125 |
| `callbacks/51/args/0/0/dragging` | differs | false | true |
| `callbacks/52/args/1/position/y` | differs | 31.875 | 28.125 |
| `callbacks/52/args/2/0/position/y` | differs | 31.875 | 28.125 |

### api (13)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0/position/y` | differs | 31.875 | 28.125 |
| `api/queries/getNode/position/y` | differs | 31.875 | 28.125 |
| `api/queries/getInternalNode/position/y` | differs | 31.875 | 28.125 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 31.875 | 28.125 |
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":45,"y":31.875},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":10… | — |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 31.875 | 28.125 |
| `api/queries/getNodesBounds/y` | differs | 31.875 | 28.125 |
| `api/queries/getNodesBounds/height` | differs | 108.125 | 111.875 |
| `api/queries/toObject/nodes/0/position/y` | differs | 31.875 | 28.125 |
| `api/queries/toObject/viewport/y` | differs | 13.125 | 16.875 |
| `api/queries/getViewport/y` | differs | 13.125 | 16.875 |
| `api/queries/screenToFlowPosition/y` | differs | -13.125 | -16.875 |
| `api/queries/flowToScreenPosition/y` | differs | 13.125 | 16.875 |

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |

## Normalization

22 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (11) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |

## Normalization

20 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (10) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/12/args/1/fromNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/userNode` | left only | {"id":"n1","data":{"label":"n1"},"position":{"x":0,"y":0},"sourcePosition":"right","targetPosition":"left","width":100,"height":40,"measured":{"width":100,"hei… | — |

## Normalization

20 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (10) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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
| `callbacks/1` | right only | — | {"name":"useOnSelectionChange","args":[{"nodes":[{"id":"Node-1","position":{"x":0,"y":0},"data":{"label":"Node-1"},"type":"input","measured":{"width":150,"heig… |
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
| `console/5` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:63029/parity/driver/dist/psflow.js:66970:… |
| `console/6` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:63029/parity/driver/dist/psflow.js:66970:… |


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
| `console/5` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:63029/parity/driver/dist/psflow.js:66970:… |
| `console/6` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:63029/parity/driver/dist/psflow.js:66970:… |


---

# System parity run — mount-baseline--edges-general--probe-edge

**Passed.** Both sides reproduced themselves, and the two sides agree everywhere unclaimed.

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

**No unclaimed differences.** The two traces agree everywhere.


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

