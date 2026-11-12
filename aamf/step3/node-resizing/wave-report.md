# System parity

The dual-run net over 107 scenario(s), against vendored `@xyflow/react` 12.11.0.

Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice.

**94 of 107 scenario(s) failed.**

A failing net is the expected state while the divergence backlog is being worked: the scenarios below
are recording what the two implementations actually do, and a difference is fixed in the port or
claimed by a region — never by loosening what the net looks at.

| scenario | verdict | failure classes | differences |
|---|---|---|---|
| `mount-baseline--edges-general` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--node-toolbar-general` | **failed** | unclaimed-difference | 1 |
| `mount-baseline--nodes-general` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--pane-general` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--pane-non-defaults` | **failed** | unclaimed-difference | 1 |
| `mount-baseline--chrome-background` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--chrome-controls` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--chrome-minimap-colors` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--chrome-minimap-hidden-nodes` | passed | — | 0 |
| `mount-baseline--chrome-panels` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--edges-base-edge-path` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--fitview-uncontrolled` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--flow-chrome-defaults` | passed | — | 0 |
| `mount-baseline--flow-custom-testid` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--flow-display-none` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--flow-limits-change` | **failed** | unclaimed-difference | 1 |
| `mount-baseline--flow-not-selectable` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--flow-props-change` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-autopan` | **failed** | unclaimed-difference | 1 |
| `mount-baseline--nodes-connections` | **failed** | unclaimed-difference | 1 |
| `mount-baseline--nodes-expand-parent` | **failed** | unclaimed-difference | 1 |
| `mount-baseline--nodes-no-select-on-drag` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-nowheel` | **failed** | unclaimed-difference | 1 |
| `mount-baseline--nodes-props-record` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--nodes-tall` | **failed** | unclaimed-difference | 1 |
| `mount-baseline--nodes-unmeasured` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--resize-lifecycle` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--viewport-controlled` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--viewport-helpers` | **failed** | unclaimed-difference | 2 |
| `mount-baseline--viewport-pan-on-scroll` | **failed** | unclaimed-difference | 1 |
| `mount-baseline--examples-color-mode` | passed | — | 0 |
| `click-selects-edge` | **failed** | unclaimed-difference | 2 |
| `multi-select-edges-with-modifier` | **failed** | unclaimed-difference | 2 |
| `click-unselectable-edge` | **failed** | unclaimed-difference | 2 |
| `delete-key-removes-edge` | **failed** | unclaimed-difference | 2 |
| `delete-key-spares-undeletable-edge` | **failed** | unclaimed-difference | 2 |
| `click-inside-interaction-width` | **failed** | unclaimed-difference | 2 |
| `click-selects-node` | **failed** | unclaimed-difference | 2 |
| `shift-drag-selects-nodes` | **failed** | unclaimed-difference | 2 |
| `click-unselectable-node` | **failed** | unclaimed-difference | 2 |
| `drag-moves-node` | **failed** | unclaimed-difference | 2 |
| `drag-does-not-move-undraggable-node` | **failed** | unclaimed-difference | 2 |
| `drag-by-custom-drag-handle` | **failed** | unclaimed-difference | 2 |
| `delete-key-removes-node-and-edges` | **failed** | unclaimed-difference | 2 |
| `delete-key-spares-undeletable-node` | **failed** | unclaimed-difference | 2 |
| `connect-source-handle-to-target-handle` | **failed** | unclaimed-difference | 4 |
| `connect-output-to-output-handle` | **failed** | unclaimed-difference | 4 |
| `connect-input-to-input-handle` | **failed** | unclaimed-difference | 3 |
| `connect-to-unconnectable-handle` | **failed** | unclaimed-difference | 4 |
| `drag-pans-the-pane` | **failed** | unclaimed-difference | 2 |
| `wheel-zooms-the-pane` | **failed** | unclaimed-difference | 2 |
| `wheel-zooms-out-to-min` | **failed** | unclaimed-difference | 2 |
| `wheel-zooms-in-to-max` | **failed** | unclaimed-difference | 2 |
| `wheel-pans-with-panonscroll` | **failed** | unclaimed-difference | 1 |
| `click-reveals-default-toolbar` | **failed** | unclaimed-difference | 1 |
| `select-dark-color-mode` | passed | — | 0 |
| `drag-node-release` | **failed** | unclaimed-difference | 2 |
| `drag-node-escape-mid-gesture` | **failed** | self-inconsistent, unclaimed-difference | 73 |
| `drag-node-autopan` | **failed** | self-inconsistent, unclaimed-difference | 118 |
| `drag-node-no-select-on-drag` | **failed** | unclaimed-difference | 2 |
| `drag-child-expand-parent` | **failed** | unclaimed-difference | 1 |
| `drag-unmeasured-node` | **failed** | unclaimed-difference | 2 |
| `selection-box-from-node` | **failed** | unclaimed-difference | 2 |
| `selection-box-then-click-node` | **failed** | unclaimed-difference | 2 |
| `selection-box-mid-gesture` | **failed** | unclaimed-difference | 2 |
| `selection-box-touch` | **failed** | unclaimed-difference | 2 |
| `arrow-key-selected-node` | **failed** | self-inconsistent, unclaimed-difference | 4 |
| `keyboard-focus-node` | **failed** | unclaimed-difference | 1 |
| `connect-handle-to-handle` | **failed** | unclaimed-difference | 4 |
| `connect-then-keyboard-move` | **failed** | unclaimed-difference | 2 |
| `connect-second-touch-point` | **failed** | unclaimed-difference | 2 |
| `probe-node-connections` | **failed** | unclaimed-difference | 1 |
| `viewport-helpers-with-options` | **failed** | unclaimed-difference | 2 |
| `pan-gesture-complete` | **failed** | unclaimed-difference | 2 |
| `fitview-onnodeschange-variants` | **failed** | unclaimed-difference | 2 |
| `uncontrolled-update-node` | **failed** | unclaimed-difference | 2 |
| `flow-props-change-after-mount` | **failed** | unclaimed-difference | 2 |
| `mount-in-display-none` | **failed** | unclaimed-difference | 2 |
| `minimap-all-nodes-hidden` | passed | — | 0 |
| `minimap-custom-mask-colors` | **failed** | unclaimed-difference | 2 |
| `controls-horizontal` | **failed** | unclaimed-difference | 2 |
| `panel-center-positions` | **failed** | unclaimed-difference | 2 |
| `background-custom-bgcolor` | **failed** | unclaimed-difference | 2 |
| `flow-custom-testid` | **failed** | unclaimed-difference | 2 |
| `custom-edge-baseedge-path` | **failed** | unclaimed-difference | 2 |
| `pinch-over-nowheel-node` | **failed** | unclaimed-difference | 1 |
| `minimap-default-click` | passed | — | 0 |
| `controls-default-zoom` | passed | — | 0 |
| `wheel-zoom-from-identity-viewport` | passed | — | 0 |
| `pane-drag-from-identity-viewport` | passed | — | 0 |
| `drag-node-reports-changes` | **failed** | self-inconsistent, unclaimed-difference | 345 |
| `click-connect-reverse-direction` | passed | — | 0 |
| `connect-drag-holding-source` | passed | — | 0 |
| `connect-drag-released-on-pane` | passed | — | 0 |
| `node-props-record-parented` | **failed** | unclaimed-difference | 3 |
| `resize-node-with-direct-control` | **failed** | unclaimed-difference | 2 |
| `resize-node-with-resizer` | **failed** | unclaimed-difference | 2 |
| `resize-node-after-active-limit-change` | **failed** | self-inconsistent, unclaimed-difference | 4 |
| `wheel-zooms-to-changed-limits` | **failed** | unclaimed-difference | 2 |
| `drag-pans-into-changed-extent` | **failed** | unclaimed-difference | 1 |
| `pan-after-controlled-viewport-change` | **failed** | unclaimed-difference | 2 |
| `ctrl-wheel-pinches-with-panonscroll` | **failed** | unclaimed-difference | 1 |
| `pane-click-keeps-selection-when-not-selectable` | **failed** | unclaimed-difference | 2 |
| `click-selects-node--probe-flow-node` | **failed** | unclaimed-difference | 27 |
| `wheel-zooms-the-pane--probe-flow-node` | **failed** | unclaimed-difference | 24 |
| `mount-baseline--edges-general--probe-edge` | passed | — | 0 |
| `connect-source-handle-to-target-handle--probe-connection-line` | **failed** | unclaimed-difference | 2 |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


---

# System parity run — mount-baseline--chrome-minimap-hidden-nodes

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

# Comparison report — mount-baseline--chrome-minimap-hidden-nodes

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**No unclaimed differences.** The two traces agree everywhere.


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


---

# System parity run — mount-baseline--flow-chrome-defaults

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

# Comparison report — mount-baseline--flow-chrome-defaults

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**No unclaimed differences.** The two traces agree everywhere.


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


---

# System parity run — mount-baseline--resize-lifecycle

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

# Comparison report — mount-baseline--resize-lifecycle

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onSelectionStart#1","onNodesChange#2","onEdgesChange#1"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onSelectionStart#1","onNodesChange#2","onEdgesChange#1"… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### callbacks (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/21/args/1/fromNode/internals/handleBounds/target` | differs | null | [] |
| `callbacks/21/args/1/toNode/internals/handleBounds/source` | differs | null | [] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### callbacks (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/15/args/1/fromNode/internals/handleBounds/source` | differs | null | [] |
| `callbacks/15/args/1/toNode/internals/handleBounds/source` | differs | null | [] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/19/args/1/fromNode/internals/handleBounds/target` | differs | null | [] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### callbacks (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/17/args/1/fromNode/internals/handleBounds/target` | differs | null | [] |
| `callbacks/17/args/1/toNode/internals/handleBounds/source` | differs | null | [] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

38 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (19) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-node-escape-mid-gesture

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
| psflow | 1, 2 | **disagrees with itself** | 36 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `callbacks/25` | left only | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… | — |
| `callbacks/26` | left only | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/17/args/0/screenX` | differs | 674 | 734 |
| `callbacks/17/args/0/screenY` | differs | 90 | 130 |
| `callbacks/17/args/0/clientX` | differs | 674 | 734 |
| `callbacks/17/args/0/clientY` | differs | 90 | 130 |
| `callbacks/17/args/0/pageX` | differs | 674 | 734 |
| `callbacks/17/args/0/pageY` | differs | 90 | 130 |
| `callbacks/17/args/1/position/x` | differs | 58.170731707317074 | 116.34146341463413 |
| `callbacks/17/args/1/position/y` | differs | 38.78048780487805 | 77.5609756097561 |
| `callbacks/17/args/1/selected` | differs | true | false |
| `callbacks/18/args/0/screenX` | differs | 734 | 794 |
| `callbacks/18/args/0/screenY` | differs | 130 | 170 |
| `callbacks/18/args/0/clientX` | differs | 734 | 794 |
| `callbacks/18/args/0/clientY` | differs | 130 | 170 |
| `callbacks/18/args/0/pageX` | differs | 734 | 794 |
| `callbacks/18/args/0/pageY` | differs | 130 | 170 |
| `callbacks/18/args/1/position/x` | differs | 58.170731707317074 | 116.34146341463413 |
| `callbacks/18/args/1/position/y` | differs | 38.78048780487805 | 77.5609756097561 |
| `callbacks/18/args/1/selected` | differs | true | false |
| `callbacks/24/args/0/screenX` | differs | 734 | 794 |
| `callbacks/24/args/0/screenY` | differs | 130 | 170 |
| `callbacks/24/args/0/clientX` | differs | 734 | 794 |
| `callbacks/24/args/0/clientY` | differs | 130 | 170 |
| `callbacks/24/args/0/pageX` | differs | 734 | 794 |
| `callbacks/24/args/0/pageY` | differs | 130 | 170 |
| `callbacks/24/args/1/id` | differs | Node-1 | Node-3 |
| `callbacks/24/args/1/position/x` | differs | 116.34146341463413 | 100 |
| `callbacks/24/args/1/position/y` | differs | 77.5609756097561 | 100 |
| `callbacks/24/args/1/data/label` | differs | Node-1 | Node-3 |
| `callbacks/24/args/1/type` | left only | input | — |
| `callbacks/24/args/1/selected` | left only | false | — |
| `callbacks/24/args/1/dragging` | left only | true | — |
| `callbacks/24/args/1/className` | left only | playwright-test-class-123 | — |
| `callbacks/24/args/1/style` | left only | {"backgroundColor":"red"} | — |

**psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — drag-node-escape-mid-gesture

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 37 unclaimed difference(s).

## Unclaimed differences

### callbacks (36)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/25` | right only | — | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… |
| `callbacks/26` | right only | — | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/22/args/0/screenX` | differs | 734 | 674 |
| `callbacks/22/args/0/screenY` | differs | 130 | 90 |
| `callbacks/22/args/0/clientX` | differs | 734 | 674 |
| `callbacks/22/args/0/clientY` | differs | 130 | 90 |
| `callbacks/22/args/0/pageX` | differs | 734 | 674 |
| `callbacks/22/args/0/pageY` | differs | 130 | 90 |
| `callbacks/22/args/1/position/x` | differs | 116.34146341463413 | 58.170731707317074 |
| `callbacks/22/args/1/position/y` | differs | 77.5609756097561 | 38.78048780487805 |
| `callbacks/22/args/1/selected` | differs | false | true |
| `callbacks/23/args/0/screenX` | differs | 794 | 734 |
| `callbacks/23/args/0/screenY` | differs | 170 | 130 |
| `callbacks/23/args/0/clientX` | differs | 794 | 734 |
| `callbacks/23/args/0/clientY` | differs | 170 | 130 |
| `callbacks/23/args/0/pageX` | differs | 794 | 734 |
| `callbacks/23/args/0/pageY` | differs | 170 | 130 |
| `callbacks/23/args/1/position/x` | differs | 116.34146341463413 | 58.170731707317074 |
| `callbacks/23/args/1/position/y` | differs | 77.5609756097561 | 38.78048780487805 |
| `callbacks/23/args/1/selected` | differs | false | true |
| `callbacks/24/args/0/screenX` | differs | 794 | 734 |
| `callbacks/24/args/0/screenY` | differs | 170 | 130 |
| `callbacks/24/args/0/clientX` | differs | 794 | 734 |
| `callbacks/24/args/0/clientY` | differs | 170 | 130 |
| `callbacks/24/args/0/pageX` | differs | 794 | 734 |
| `callbacks/24/args/0/pageY` | differs | 170 | 130 |
| `callbacks/24/args/1/id` | differs | Node-3 | Node-1 |
| `callbacks/24/args/1/data/label` | differs | Node-3 | Node-1 |
| `callbacks/24/args/1/position/x` | differs | 100 | 116.34146341463413 |
| `callbacks/24/args/1/position/y` | differs | 100 | 77.5609756097561 |
| `callbacks/24/args/1/type` | right only | — | input |
| `callbacks/24/args/1/selected` | right only | — | false |
| `callbacks/24/args/1/dragging` | right only | — | true |
| `callbacks/24/args/1/className` | right only | — | playwright-test-class-123 |
| `callbacks/24/args/1/style` | right only | — | {"backgroundColor":"red"} |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

24 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (15) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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
| psflow | 1, 2 | **disagrees with itself** | 15 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `callbacks/92` | left only | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/93` | left only | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/94` | left only | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/95` | left only | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/99` | left only | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/100` | left only | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/101` | left only | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/102` | left only | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… |
| `callbacks/72/args/0/screenX` | differs | 5 | 6 |
| `callbacks/72/args/0/screenY` | differs | 6 | 5 |
| `callbacks/72/args/0/clientX` | differs | 5 | 6 |
| `callbacks/72/args/0/clientY` | differs | 6 | 5 |
| `callbacks/72/args/0/pageX` | differs | 5 | 6 |
| `callbacks/72/args/0/pageY` | differs | 6 | 5 |

**psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — drag-node-autopan

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 103 unclaimed difference(s).

## Unclaimed differences

### callbacks (102)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/59` | left only | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… | — |
| `callbacks/67` | left only | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… | — |
| `callbacks/56` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/57` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/58` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/59` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/60` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/64` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/65` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/66` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/67` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/68` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/69` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/70` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/71` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/73` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/74` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/75` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/76` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/77` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/78` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/79` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/80` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/84` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/85` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/86` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/87` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/88` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/89` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/90` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/91` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/92` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/93` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/94` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/95` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/99` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/100` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/101` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/102` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… |
| `callbacks/20/args/1/x` | differs | 340 | 0 |
| `callbacks/20/args/1/y` | differs | 560 | 220.00000000000003 |
| `callbacks/27/args/1/x` | differs | 680 | 340 |
| `callbacks/27/args/1/y` | differs | 900 | 560 |
| `callbacks/29/args/0/0/position/x` | differs | -750 | -1089 |
| `callbacks/29/args/0/0/position/y` | differs | -912 | -1032 |
| `callbacks/30/args/1/position/x` | differs | -750 | -1089 |
| `callbacks/30/args/1/position/y` | differs | -912 | -1032 |
| `callbacks/30/args/2/0/position/x` | differs | -750 | -1089 |
| `callbacks/30/args/2/0/position/y` | differs | -912 | -1032 |
| `callbacks/32/args/0/x` | differs | 1030 | 1020 |
| `callbacks/33/args/1/x` | differs | 1030 | 1020 |
| `callbacks/34/args/0/0/position/x` | differs | -1100 | -1429 |
| `callbacks/34/args/0/0/position/y` | differs | -1252 | -1372 |
| `callbacks/35/args/1/position/x` | differs | -1100 | -1429 |
| `callbacks/35/args/1/position/y` | differs | -1252 | -1372 |
| `callbacks/35/args/2/0/position/x` | differs | -1100 | -1429 |
| `callbacks/35/args/2/0/position/y` | differs | -1252 | -1372 |
| `callbacks/36/args/1/x` | differs | 1030 | 680 |
| `callbacks/36/args/1/y` | differs | 1240 | 900 |
| `callbacks/37/args/1/position/x` | differs | -1100 | -2070 |
| `callbacks/37/args/1/position/y` | differs | -1252 | -2012 |
| `callbacks/38/args/1/x` | differs | 1030 | 1020 |
| `callbacks/39/args/0/x` | differs | 1380 | 1360 |
| `callbacks/40/args/1/x` | differs | 1380 | 1360 |
| `callbacks/41/args/0/0/position/x` | differs | -1450 | -1769 |
| `callbacks/41/args/0/0/position/y` | differs | -1592 | -1712 |
| `callbacks/42/args/1/position/x` | differs | -1450 | -1769 |
| `callbacks/42/args/1/position/y` | differs | -1592 | -1712 |
| `callbacks/42/args/2/0/position/x` | differs | -1450 | -1769 |
| `callbacks/42/args/2/0/position/y` | differs | -1592 | -1712 |
| `callbacks/43/args/1/x` | differs | 1380 | 1020 |
| `callbacks/43/args/1/y` | differs | 1580 | 1240 |
| `callbacks/45/args/0/0/position/x` | differs | -1449 | -2109 |
| `callbacks/45/args/0/0/position/y` | differs | -1593 | -2052 |
| `callbacks/46/args/1/position/x` | differs | -1449 | -2109 |
| `callbacks/46/args/1/position/y` | differs | -1593 | -2052 |
| `callbacks/46/args/2/0/position/x` | differs | -1449 | -2109 |
| `callbacks/46/args/2/0/position/y` | differs | -1593 | -2052 |
| `callbacks/47/args/1/x` | differs | 1380 | 1360 |
| `callbacks/48/args/0/x` | differs | 1720 | 1700 |
| `callbacks/48/args/0/y` | differs | 1930 | 1920 |
| `callbacks/49/args/1/x` | differs | 1720 | 1700 |
| `callbacks/49/args/1/y` | differs | 1930 | 1920 |
| `callbacks/50/args/0/0/position/x` | differs | -1789 | -2070 |
| `callbacks/50/args/0/0/position/y` | differs | -1943 | -2012 |
| `callbacks/51/args/1/position/x` | differs | -1789 | -2070 |
| `callbacks/51/args/1/position/y` | differs | -1943 | -2012 |
| `callbacks/51/args/2/0/position/x` | differs | -1789 | -2070 |
| `callbacks/51/args/2/0/position/y` | differs | -1943 | -2012 |
| `callbacks/52/args/1/x` | differs | 1720 | 1360 |
| `callbacks/52/args/1/y` | differs | 1930 | 1580 |
| `callbacks/53/args/1/x` | differs | 1720 | 1700 |
| `callbacks/53/args/1/y` | differs | 1930 | 1920 |
| `callbacks/56/args/0/0/position/x` | differs | -2129 | -2069 |
| `callbacks/56/args/0/0/position/y` | differs | -2293 | -2013 |
| `callbacks/57/args/1/position/x` | differs | -2129 | -2069 |
| `callbacks/57/args/1/position/y` | differs | -2293 | -2013 |
| `callbacks/57/args/2/0/position/x` | differs | -2129 | -2069 |
| `callbacks/57/args/2/0/position/y` | differs | -2293 | -2013 |
| `callbacks/58/args/1/x` | differs | 2000 | 1700 |
| `callbacks/58/args/1/y` | differs | 2000 | 1920 |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

22 field(s) deleted by name and therefore **unobserved** — not passing:

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onNodeMouseEnter#1","onNodeMouseMove#1","onSelectionSta… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onNodeMouseEnter#1","onNodeMouseMove#1","onSelectionSta… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMov… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMov… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onSelectionStart#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onSelectionStart#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onNodesChange#2","onNodeDragStart#1","onSelectionChange… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onNodesChange#2","onNodeDragStart#1","onSelectionChange… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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
| `callbacks/15/args/1/position/x` | differs | 0 | 10 |

**upstream did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — arrow-key-selected-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/react-flow__aria-live-1/text` | left only | Moved selected node right. New position, x: 5, y: 20 | — |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

12 field(s) deleted by name and therefore **unobserved** — not passing:

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### callbacks (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/21/args/1/fromNode/internals/handleBounds/target` | differs | null | [] |
| `callbacks/21/args/1/toNode/internals/handleBounds/source` | differs | null | [] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onConnectStart… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onConnectStart… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

26 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (13) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onNodesChange#2","onNodesChange#3","onNodesChange#4","o… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onNodesChange#2","onNodesChange#3","onNodesChange#4","o… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

34 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (18) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


---

# System parity run — minimap-all-nodes-hidden

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

# Comparison report — minimap-all-nodes-hidden

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**No unclaimed differences.** The two traces agree everywhere.


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onMoveStart#2","onViewportChange#2","onMove#2","onMoveE… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1"] |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onEdgeMouseEnter#1","onPaneMouseMo… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseEnter#2","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseEnter#2","onPaneMouseMo… |

## Normalization

24 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (12) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — minimap-default-click

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

# Comparison report — minimap-default-click

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**No unclaimed differences.** The two traces agree everywhere.


---

# System parity run — controls-default-zoom

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

# Comparison report — controls-default-zoom

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**No unclaimed differences.** The two traces agree everywhere.


---

# System parity run — wheel-zoom-from-identity-viewport

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

# Comparison report — wheel-zoom-from-identity-viewport

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**No unclaimed differences.** The two traces agree everywhere.

## Normalization

4 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (2) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — pane-drag-from-identity-viewport

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

# Comparison report — pane-drag-from-identity-viewport

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**No unclaimed differences.** The two traces agree everywhere.

## Normalization

24 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (12) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — drag-node-reports-changes

**Failed:** self-inconsistent, self-inconsistent, unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | **disagrees with itself** | 116 |
| psflow | 1, 2 | **disagrees with itself** | 114 |

### upstream disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(0px, 30px) scale(1); | transform: translate(0px, 20.625px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[0]/attrs/d` | differs | M148,35 C197.5,35 197.5,120 247,120 | M148,44.375 C197.5,44.375 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[1]/attrs/d` | differs | M148,35 C197.5,35 197.5,120 247,120 | M148,44.375 C197.5,44.375 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/circle[0]/attrs/cy` | differs | 35 | 44.375 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/n1/attrs/style` | differs | height: 40px; pointer-events: all; transform: translate(45px, 15px); visibility: visible; width: 100px; z-index: 1000; | height: 40px; pointer-events: all; transform: translate(45px, 24.375px); visibility: visible; width: 100px; z-index: 1000; |
| `dom/root/children/div[2]/children/svg[0]/attrs/viewBox` | differs | -32 -182 1344 1024 | -32 -172.625 1344 1024 |
| `dom/root/children/div[2]/children/svg[0]/children/rect[0]/attrs/y` | differs | 15 | 24.375 |
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-214h1408v1088h-1408z⏎        M0,-30h1280v720h-1280z | M-64,-204.625h1408v1088h-1408z⏎        M0,-20.625h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1/attrs/y` | differs | 10 | 0.625 |
| `callbacks/48` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":24.375,"zoom":1}]} | — |
| `callbacks/49` | left only | {"name":"onViewportChange","args":[{"x":0,"y":26.25,"zoom":1}]} | — |
| `callbacks/50` | left only | {"name":"onMove","args":[null,{"x":0,"y":26.25,"zoom":1}]} | — |
| `callbacks/53` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":26.25,"zoom":1}]} | — |
| `callbacks/54` | left only | {"name":"onViewportChange","args":[{"x":0,"y":28.125,"zoom":1}]} | — |
| `callbacks/55` | left only | {"name":"onMove","args":[null,{"x":0,"y":28.125,"zoom":1}]} | — |
| `callbacks/58` | left only | {"name":"onMoveEnd","args":[null,{"x":0,"y":28.125,"zoom":1}]} | — |
| `callbacks/59` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":28.125,"zoom":1}]} | — |
| `callbacks/60` | left only | {"name":"onViewportChange","args":[{"x":0,"y":30,"zoom":1}]} | — |
| `callbacks/61` | left only | {"name":"onMove","args":[null,{"x":0,"y":30,"zoom":1}]} | — |
| `callbacks/67` | left only | {"name":"onMoveEnd","args":[null,{"x":0,"y":30,"zoom":1}]} | — |
| `callbacks/79` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":35,"y":5},"sourcePosition":"right","targ… | — |
| `callbacks/81` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":40,"y":10},"dragging":true}]]} | — |
| `callbacks/82` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":40,"y":10},"sourcePosition":"right","tar… | — |
| `callbacks/84` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":45,"y":15},"dragging":true}]]} | — |
| `callbacks/85` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":45,"y":15},"sourcePosition":"right","tar… | — |
| `callbacks/86` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":45,"y":15},"dragging":false}]]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/28/args/0/y` | differs | 18.75 | 16.875 |
| `callbacks/29/args/1/y` | differs | 18.75 | 16.875 |
| `callbacks/30/args/0/0/position/x` | differs | 5 | 10 |
| `callbacks/30/args/0/0/position/y` | differs | -6.25 | -5 |
| `callbacks/31/args/1/position/x` | differs | 5 | 10 |
| `callbacks/31/args/1/position/y` | differs | -6.25 | -5 |
| `callbacks/31/args/2/0/position/x` | differs | 5 | 10 |
| `callbacks/31/args/2/0/position/y` | differs | -6.25 | -5 |
| `callbacks/32/args/1/y` | differs | 18.75 | 16.875 |
| `callbacks/33/args/1/y` | differs | 18.75 | 16.875 |
| `callbacks/34/args/0/y` | differs | 22.5 | 18.75 |
| `callbacks/35/args/1/y` | differs | 22.5 | 18.75 |
| `callbacks/36/args/0/0/position/x` | differs | 5 | 10 |
| `callbacks/36/args/0/0/position/y` | differs | -10 | -6.875 |
| `callbacks/37/args/1/position/x` | differs | 5 | 10 |
| `callbacks/37/args/1/position/y` | differs | -10 | -6.875 |
| `callbacks/37/args/2/0/position/x` | differs | 5 | 10 |
| `callbacks/37/args/2/0/position/y` | differs | -10 | -6.875 |
| `callbacks/38/args/1/y` | differs | 22.5 | 18.75 |
| `callbacks/40/args/0/0/position/y` | differs | -12.5 | -8.75 |
| `callbacks/41/args/1/position/y` | differs | -12.5 | -8.75 |
| `callbacks/41/args/2/0/position/y` | differs | -12.5 | -8.75 |
| `callbacks/42/args/1/y` | differs | 22.5 | 18.75 |
| `callbacks/43/args/0/y` | differs | 24.375 | 20.625 |
| `callbacks/44/args/1/y` | differs | 24.375 | 20.625 |
| `callbacks/45/args/0/0/position/y` | differs | -14.375 | -10.625 |
| `callbacks/46/args/1/position/y` | differs | -14.375 | -10.625 |
| `callbacks/46/args/2/0/position/y` | differs | -14.375 | -10.625 |
| `callbacks/47/args/1/y` | differs | 24.375 | 20.625 |
| `callbacks/51/args/0/0/position/x` | differs | 10 | 15 |
| `callbacks/51/args/0/0/position/y` | differs | -16.25 | -5.625 |
| `callbacks/52/args/1/position/x` | differs | 10 | 15 |
| `callbacks/52/args/1/position/y` | differs | -16.25 | -5.625 |
| `callbacks/52/args/2/0/position/x` | differs | 10 | 15 |
| `callbacks/52/args/2/0/position/y` | differs | -16.25 | -5.625 |
| `callbacks/56/args/0/0/position/x` | differs | 10 | 20 |
| `callbacks/56/args/0/0/position/y` | differs | -18.125 | -0.625 |
| `callbacks/57/args/1/position/x` | differs | 10 | 20 |
| `callbacks/57/args/1/position/y` | differs | -18.125 | -0.625 |
| `callbacks/57/args/2/0/position/x` | differs | 10 | 20 |
| `callbacks/57/args/2/0/position/y` | differs | -18.125 | -0.625 |
| `callbacks/62/args/0/0/position/x` | differs | 10 | 25 |
| `callbacks/62/args/0/0/position/y` | differs | -20 | 4.375 |
| `callbacks/63/args/1/position/x` | differs | 10 | 25 |
| `callbacks/63/args/1/position/y` | differs | -20 | 4.375 |
| `callbacks/63/args/2/0/position/x` | differs | 10 | 25 |
| `callbacks/63/args/2/0/position/y` | differs | -20 | 4.375 |
| `callbacks/65/args/0/0/position/x` | differs | 15 | 30 |
| `callbacks/65/args/0/0/position/y` | differs | -15 | 9.375 |
| `callbacks/66/args/1/position/x` | differs | 15 | 30 |
| `callbacks/66/args/1/position/y` | differs | -15 | 9.375 |
| `callbacks/66/args/2/0/position/x` | differs | 15 | 30 |
| `callbacks/66/args/2/0/position/y` | differs | -15 | 9.375 |
| `callbacks/69/args/0/0/position/x` | differs | 20 | 35 |
| `callbacks/69/args/0/0/position/y` | differs | -10 | 14.375 |
| `callbacks/70/args/1/position/x` | differs | 20 | 35 |
| `callbacks/70/args/1/position/y` | differs | -10 | 14.375 |
| `callbacks/70/args/2/0/position/x` | differs | 20 | 35 |
| `callbacks/70/args/2/0/position/y` | differs | -10 | 14.375 |
| `callbacks/72/args/0/0/position/x` | differs | 25 | 40 |
| `callbacks/72/args/0/0/position/y` | differs | -5 | 19.375 |
| `callbacks/73/args/1/position/x` | differs | 25 | 40 |
| `callbacks/73/args/1/position/y` | differs | -5 | 19.375 |
| `callbacks/73/args/2/0/position/x` | differs | 25 | 40 |
| `callbacks/73/args/2/0/position/y` | differs | -5 | 19.375 |
| `callbacks/75/args/0/0/position/x` | differs | 30 | 45 |
| `callbacks/75/args/0/0/position/y` | differs | 0 | 24.375 |
| `callbacks/76/args/1/position/x` | differs | 30 | 45 |
| `callbacks/76/args/1/position/y` | differs | 0 | 24.375 |
| `callbacks/76/args/2/0/position/x` | differs | 30 | 45 |
| `callbacks/76/args/2/0/position/y` | differs | 0 | 24.375 |
| `callbacks/78/args/0/0/position/x` | differs | 35 | 45 |
| `callbacks/78/args/0/0/position/y` | differs | 5 | 24.375 |
| `callbacks/78/args/0/0/dragging` | differs | true | false |
| `callbacks/87/args/1/position/y` | differs | 15 | 24.375 |
| `callbacks/87/args/2/0/position/y` | differs | 15 | 24.375 |
| `api/queries/getNodes/0/position/y` | differs | 15 | 24.375 |
| `api/queries/getNode/position/y` | differs | 15 | 24.375 |
| `api/queries/getInternalNode/position/y` | differs | 15 | 24.375 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 15 | 24.375 |
| `api/queries/getInternalNode/internals/userNode/position/y` | differs | 15 | 24.375 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 15 | 24.375 |
| `api/queries/getNodesBounds/y` | differs | 15 | 24.375 |
| `api/queries/getNodesBounds/height` | differs | 125 | 115.625 |
| `api/queries/toObject/nodes/0/position/y` | differs | 15 | 24.375 |
| `api/queries/toObject/viewport/y` | differs | 30 | 20.625 |
| `api/queries/getViewport/y` | differs | 30 | 20.625 |
| `api/queries/screenToFlowPosition/y` | differs | -30 | -20.625 |
| `api/queries/flowToScreenPosition/y` | differs | 30 | 20.625 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(0px, 35.625px) scale(1); | transform: translate(0px, 43.125px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[0]/attrs/d` | differs | M148,29.375 C197.5,29.375 197.5,120 247,120 | M148,21.875 C197.5,21.875 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[1]/attrs/d` | differs | M148,29.375 C197.5,29.375 197.5,120 247,120 | M148,21.875 C197.5,21.875 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/circle[0]/attrs/cy` | differs | 29.375 | 21.875 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/n1/attrs/style` | differs | height: 40px; pointer-events: all; transform: translate(45px, 9.375px); visibility: visible; width: 100px; z-index: 1000; | height: 40px; pointer-events: all; transform: translate(45px, 1.875px); visibility: visible; width: 100px; z-index: 1000; |
| `dom/root/children/div[2]/children/svg[0]/attrs/viewBox` | differs | -32 -187.625 1344 1024 | -32 -195.125 1344 1024 |
| `dom/root/children/div[2]/children/svg[0]/children/rect[0]/attrs/y` | differs | 9.375 | 1.875 |
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-219.625h1408v1088h-1408z⏎        M0,-35.625h1280v720h-1280z | M-64,-227.125h1408v1088h-1408z⏎        M0,-43.125h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1/attrs/y` | differs | 15.625 | 3.125 |
| `callbacks/73` | right only | — | {"name":"onMoveStart","args":[null,{"x":0,"y":37.5,"zoom":1}]} |
| `callbacks/74` | right only | — | {"name":"onViewportChange","args":[{"x":0,"y":39.375,"zoom":1}]} |
| `callbacks/75` | right only | — | {"name":"onMove","args":[null,{"x":0,"y":39.375,"zoom":1}]} |
| `callbacks/76` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":39.375,"zoom":1}]} |
| `callbacks/79` | right only | — | {"name":"onMoveStart","args":[null,{"x":0,"y":39.375,"zoom":1}]} |
| `callbacks/80` | right only | — | {"name":"onViewportChange","args":[{"x":0,"y":41.25,"zoom":1}]} |
| `callbacks/81` | right only | — | {"name":"onMove","args":[null,{"x":0,"y":41.25,"zoom":1}]} |
| `callbacks/82` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":41.25,"zoom":1}]} |
| `callbacks/85` | right only | — | {"name":"onMoveStart","args":[null,{"x":0,"y":41.25,"zoom":1}]} |
| `callbacks/86` | right only | — | {"name":"onViewportChange","args":[{"x":0,"y":43.125,"zoom":1}]} |
| `callbacks/87` | right only | — | {"name":"onMove","args":[null,{"x":0,"y":43.125,"zoom":1}]} |
| `callbacks/88` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":43.125,"zoom":1}]} |
| `callbacks/105` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","position":{"x":35,"y":-8.125},"data":{"label":"n1"},"sourcePosition":"right",… |
| `callbacks/107` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"n1","position":{"x":40,"y":-3.125},"dragging":true}]]} |
| `callbacks/108` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","position":{"x":40,"y":-3.125},"data":{"label":"n1"},"sourcePosition":"right",… |
| `callbacks/110` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"n1","position":{"x":45,"y":1.875},"dragging":true}]]} |
| `callbacks/111` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","position":{"x":45,"y":1.875},"data":{"label":"n1"},"sourcePosition":"right","… |
| `callbacks/112` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"n1","position":{"x":45,"y":1.875},"dragging":false}]]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/53/args/0/0/position/x` | differs | 10 | 5 |
| `callbacks/53/args/0/0/position/y` | differs | -20 | -21.25 |
| `callbacks/54/args/1/position/x` | differs | 10 | 5 |
| `callbacks/54/args/1/position/y` | differs | -20 | -21.25 |
| `callbacks/54/args/2/0/position/x` | differs | 10 | 5 |
| `callbacks/54/args/2/0/position/y` | differs | -20 | -21.25 |
| `callbacks/56/args/0/y` | differs | 31.875 | 33.75 |
| `callbacks/57/args/1/y` | differs | 31.875 | 33.75 |
| `callbacks/58/args/1/y` | differs | 31.875 | 33.75 |
| `callbacks/59/args/0/0/position/y` | differs | -21.875 | -23.75 |
| `callbacks/60/args/1/position/y` | differs | -21.875 | -23.75 |
| `callbacks/60/args/2/0/position/y` | differs | -21.875 | -23.75 |
| `callbacks/61/args/1/y` | differs | 31.875 | 33.75 |
| `callbacks/62/args/0/y` | differs | 33.75 | 35.625 |
| `callbacks/63/args/1/y` | differs | 33.75 | 35.625 |
| `callbacks/64/args/1/y` | differs | 33.75 | 35.625 |
| `callbacks/65/args/0/0/position/y` | differs | -23.75 | -25.625 |
| `callbacks/66/args/1/position/y` | differs | -23.75 | -25.625 |
| `callbacks/66/args/2/0/position/y` | differs | -23.75 | -25.625 |
| `callbacks/67/args/1/y` | differs | 33.75 | 35.625 |
| `callbacks/68/args/0/y` | differs | 35.625 | 37.5 |
| `callbacks/69/args/1/y` | differs | 35.625 | 37.5 |
| `callbacks/70/args/1/y` | differs | 35.625 | 37.5 |
| `callbacks/71/args/0/0/position/y` | differs | -25.625 | -27.5 |
| `callbacks/72/args/1/position/y` | differs | -25.625 | -27.5 |
| `callbacks/72/args/2/0/position/y` | differs | -25.625 | -27.5 |
| `callbacks/74/args/0/0/position/x` | differs | 15 | 10 |
| `callbacks/74/args/0/0/position/y` | differs | -20.625 | -29.375 |
| `callbacks/75/args/1/position/x` | differs | 15 | 10 |
| `callbacks/75/args/1/position/y` | differs | -20.625 | -29.375 |
| `callbacks/75/args/2/0/position/x` | differs | 15 | 10 |
| `callbacks/75/args/2/0/position/y` | differs | -20.625 | -29.375 |
| `callbacks/77/args/0/0/position/x` | differs | 20 | 10 |
| `callbacks/77/args/0/0/position/y` | differs | -15.625 | -31.25 |
| `callbacks/78/args/1/position/x` | differs | 20 | 10 |
| `callbacks/78/args/1/position/y` | differs | -15.625 | -31.25 |
| `callbacks/78/args/2/0/position/x` | differs | 20 | 10 |
| `callbacks/78/args/2/0/position/y` | differs | -15.625 | -31.25 |
| `callbacks/80/args/0/0/position/x` | differs | 25 | 10 |
| `callbacks/80/args/0/0/position/y` | differs | -10.625 | -33.125 |
| `callbacks/81/args/1/position/x` | differs | 25 | 10 |
| `callbacks/81/args/1/position/y` | differs | -10.625 | -33.125 |
| `callbacks/81/args/2/0/position/x` | differs | 25 | 10 |
| `callbacks/81/args/2/0/position/y` | differs | -10.625 | -33.125 |
| `callbacks/83/args/0/0/position/x` | differs | 30 | 15 |
| `callbacks/83/args/0/0/position/y` | differs | -5.625 | -28.125 |
| `callbacks/84/args/1/position/x` | differs | 30 | 15 |
| `callbacks/84/args/1/position/y` | differs | -5.625 | -28.125 |
| `callbacks/84/args/2/0/position/x` | differs | 30 | 15 |
| `callbacks/84/args/2/0/position/y` | differs | -5.625 | -28.125 |
| `callbacks/86/args/0/0/position/x` | differs | 35 | 20 |
| `callbacks/86/args/0/0/position/y` | differs | -0.625 | -23.125 |
| `callbacks/87/args/1/position/x` | differs | 35 | 20 |
| `callbacks/87/args/1/position/y` | differs | -0.625 | -23.125 |
| `callbacks/87/args/2/0/position/x` | differs | 35 | 20 |
| `callbacks/87/args/2/0/position/y` | differs | -0.625 | -23.125 |
| `callbacks/89/args/0/0/position/x` | differs | 40 | 25 |
| `callbacks/89/args/0/0/position/y` | differs | 4.375 | -18.125 |
| `callbacks/90/args/1/position/x` | differs | 40 | 25 |
| `callbacks/90/args/1/position/y` | differs | 4.375 | -18.125 |
| `callbacks/90/args/2/0/position/x` | differs | 40 | 25 |
| `callbacks/90/args/2/0/position/y` | differs | 4.375 | -18.125 |
| `callbacks/92/args/0/0/position/x` | differs | 45 | 30 |
| `callbacks/92/args/0/0/position/y` | differs | 9.375 | -13.125 |
| `callbacks/93/args/1/position/x` | differs | 45 | 30 |
| `callbacks/93/args/1/position/y` | differs | 9.375 | -13.125 |
| `callbacks/93/args/2/0/position/x` | differs | 45 | 30 |
| `callbacks/93/args/2/0/position/y` | differs | 9.375 | -13.125 |
| `callbacks/94/args/0/0/position/x` | differs | 45 | 35 |
| `callbacks/94/args/0/0/position/y` | differs | 9.375 | -8.125 |
| `callbacks/94/args/0/0/dragging` | differs | false | true |
| `callbacks/95/args/1/position/y` | differs | 9.375 | 1.875 |
| `callbacks/95/args/2/0/position/y` | differs | 9.375 | 1.875 |
| `api/queries/getNodes/0/position/y` | differs | 9.375 | 1.875 |
| `api/queries/getNode/position/y` | differs | 9.375 | 1.875 |
| `api/queries/getInternalNode/position/y` | differs | 9.375 | 1.875 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 9.375 | 1.875 |
| `api/queries/getInternalNode/internals/userNode/position/y` | differs | 9.375 | 1.875 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 9.375 | 1.875 |
| `api/queries/getNodesBounds/y` | differs | 9.375 | 1.875 |
| `api/queries/getNodesBounds/height` | differs | 130.625 | 138.125 |
| `api/queries/toObject/nodes/0/position/y` | differs | 9.375 | 1.875 |
| `api/queries/toObject/viewport/y` | differs | 35.625 | 43.125 |
| `api/queries/getViewport/y` | differs | 35.625 | 43.125 |
| `api/queries/screenToFlowPosition/y` | differs | -35.625 | -43.125 |
| `api/queries/flowToScreenPosition/y` | differs | 35.625 | 43.125 |

**upstream and psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — drag-node-reports-changes

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 115 unclaimed difference(s).

## Unclaimed differences

### dom (9)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(0px, 30px) scale(1); | transform: translate(0px, 35.625px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[0]/attrs/d` | differs | M148,35 C197.5,35 197.5,120 247,120 | M148,29.375 C197.5,29.375 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[1]/attrs/d` | differs | M148,35 C197.5,35 197.5,120 247,120 | M148,29.375 C197.5,29.375 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/circle[0]/attrs/cy` | differs | 35 | 29.375 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/n1/attrs/style` | differs | height: 40px; pointer-events: all; transform: translate(45px, 15px); visibility: visible; width: 100px; z-index: 1000; | height: 40px; pointer-events: all; transform: translate(45px, 9.375px); visibility: visible; width: 100px; z-index: 1000; |
| `dom/root/children/div[2]/children/svg[0]/attrs/viewBox` | differs | -32 -182 1344 1024 | -32 -187.625 1344 1024 |
| `dom/root/children/div[2]/children/svg[0]/children/rect[0]/attrs/y` | differs | 15 | 9.375 |
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-214h1408v1088h-1408z⏎        M0,-30h1280v720h-1280z | M-64,-219.625h1408v1088h-1408z⏎        M0,-35.625h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1/attrs/y` | differs | 10 | 15.625 |

### callbacks (93)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/58` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":31.875,"zoom":1}]} |
| `callbacks/64` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":33.75,"zoom":1}]} |
| `callbacks/67` | right only | — | {"name":"onMoveStart","args":[null,{"x":0,"y":33.75,"zoom":1}]} |
| `callbacks/68` | right only | — | {"name":"onViewportChange","args":[{"x":0,"y":35.625,"zoom":1}]} |
| `callbacks/69` | right only | — | {"name":"onMove","args":[null,{"x":0,"y":35.625,"zoom":1}]} |
| `callbacks/70` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":35.625,"zoom":1}]} |
| `callbacks/93` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","position":{"x":45,"y":9.375},"data":{"label":"n1"},"sourcePosition":"right","… |
| `callbacks/94` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"n1","position":{"x":45,"y":9.375},"dragging":false}]]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/20/args/1/y` | differs | 11.25 | 7.5 |
| `callbacks/26/args/1/y` | differs | 15 | 11.25 |
| `callbacks/32/args/1/y` | differs | 18.75 | 15 |
| `callbacks/38/args/1/y` | differs | 22.5 | 18.75 |
| `callbacks/40/args/0/0/position/x` | differs | 10 | 5 |
| `callbacks/40/args/0/0/position/y` | differs | -12.5 | -13.75 |
| `callbacks/41/args/1/position/x` | differs | 10 | 5 |
| `callbacks/41/args/1/position/y` | differs | -12.5 | -13.75 |
| `callbacks/41/args/2/0/position/x` | differs | 10 | 5 |
| `callbacks/41/args/2/0/position/y` | differs | -12.5 | -13.75 |
| `callbacks/43/args/0/y` | differs | 24.375 | 26.25 |
| `callbacks/44/args/1/y` | differs | 24.375 | 26.25 |
| `callbacks/45/args/0/0/position/x` | differs | 10 | 5 |
| `callbacks/45/args/0/0/position/y` | differs | -14.375 | -17.5 |
| `callbacks/46/args/1/position/x` | differs | 10 | 5 |
| `callbacks/46/args/1/position/y` | differs | -14.375 | -17.5 |
| `callbacks/46/args/2/0/position/x` | differs | 10 | 5 |
| `callbacks/46/args/2/0/position/y` | differs | -14.375 | -17.5 |
| `callbacks/47/args/1/y` | differs | 24.375 | 22.5 |
| `callbacks/48/args/1/y` | differs | 24.375 | 26.25 |
| `callbacks/49/args/0/y` | differs | 26.25 | 30 |
| `callbacks/50/args/1/y` | differs | 26.25 | 30 |
| `callbacks/51/args/0/0/position/y` | differs | -16.25 | -20 |
| `callbacks/52/args/1/position/y` | differs | -16.25 | -20 |
| `callbacks/52/args/2/0/position/y` | differs | -16.25 | -20 |
| `callbacks/53/args/1/y` | differs | 26.25 | 30 |
| `callbacks/54/args/0/y` | differs | 28.125 | 31.875 |
| `callbacks/55/args/1/y` | differs | 28.125 | 31.875 |
| `callbacks/56/args/0/0/position/y` | differs | -18.125 | -21.875 |
| `callbacks/57/args/1/position/y` | differs | -18.125 | -21.875 |
| `callbacks/57/args/2/0/position/y` | differs | -18.125 | -21.875 |
| `callbacks/58/args/1/y` | differs | 28.125 | 26.25 |
| `callbacks/59/args/1/y` | differs | 28.125 | 31.875 |
| `callbacks/60/args/0/y` | differs | 30 | 33.75 |
| `callbacks/61/args/1/y` | differs | 30 | 33.75 |
| `callbacks/62/args/0/0/position/y` | differs | -20 | -23.75 |
| `callbacks/63/args/1/position/y` | differs | -20 | -23.75 |
| `callbacks/63/args/2/0/position/y` | differs | -20 | -23.75 |
| `callbacks/65/args/0/0/position/x` | differs | 15 | 10 |
| `callbacks/65/args/0/0/position/y` | differs | -15 | -25.625 |
| `callbacks/66/args/1/position/x` | differs | 15 | 10 |
| `callbacks/66/args/1/position/y` | differs | -15 | -25.625 |
| `callbacks/66/args/2/0/position/x` | differs | 15 | 10 |
| `callbacks/66/args/2/0/position/y` | differs | -15 | -25.625 |
| `callbacks/69/args/0/0/position/x` | differs | 20 | 15 |
| `callbacks/69/args/0/0/position/y` | differs | -10 | -20.625 |
| `callbacks/70/args/1/position/x` | differs | 20 | 15 |
| `callbacks/70/args/1/position/y` | differs | -10 | -20.625 |
| `callbacks/70/args/2/0/position/x` | differs | 20 | 15 |
| `callbacks/70/args/2/0/position/y` | differs | -10 | -20.625 |
| `callbacks/72/args/0/0/position/x` | differs | 25 | 20 |
| `callbacks/72/args/0/0/position/y` | differs | -5 | -15.625 |
| `callbacks/73/args/1/position/x` | differs | 25 | 20 |
| `callbacks/73/args/1/position/y` | differs | -5 | -15.625 |
| `callbacks/73/args/2/0/position/x` | differs | 25 | 20 |
| `callbacks/73/args/2/0/position/y` | differs | -5 | -15.625 |
| `callbacks/75/args/0/0/position/x` | differs | 30 | 25 |
| `callbacks/75/args/0/0/position/y` | differs | 0 | -10.625 |
| `callbacks/76/args/1/position/x` | differs | 30 | 25 |
| `callbacks/76/args/1/position/y` | differs | 0 | -10.625 |
| `callbacks/76/args/2/0/position/x` | differs | 30 | 25 |
| `callbacks/76/args/2/0/position/y` | differs | 0 | -10.625 |
| `callbacks/78/args/0/0/position/x` | differs | 35 | 30 |
| `callbacks/78/args/0/0/position/y` | differs | 5 | -5.625 |
| `callbacks/79/args/1/position/x` | differs | 35 | 30 |
| `callbacks/79/args/1/position/y` | differs | 5 | -5.625 |
| `callbacks/79/args/2/0/position/x` | differs | 35 | 30 |
| `callbacks/79/args/2/0/position/y` | differs | 5 | -5.625 |
| `callbacks/81/args/0/0/position/x` | differs | 40 | 35 |
| `callbacks/81/args/0/0/position/y` | differs | 10 | -0.625 |
| `callbacks/82/args/1/position/x` | differs | 40 | 35 |
| `callbacks/82/args/1/position/y` | differs | 10 | -0.625 |
| `callbacks/82/args/2/0/position/x` | differs | 40 | 35 |
| `callbacks/82/args/2/0/position/y` | differs | 10 | -0.625 |
| `callbacks/84/args/0/0/position/x` | differs | 45 | 40 |
| `callbacks/84/args/0/0/position/y` | differs | 15 | 4.375 |
| `callbacks/85/args/1/position/x` | differs | 45 | 40 |
| `callbacks/85/args/1/position/y` | differs | 15 | 4.375 |
| `callbacks/85/args/2/0/position/x` | differs | 45 | 40 |
| `callbacks/85/args/2/0/position/y` | differs | 15 | 4.375 |
| `callbacks/86/args/0/0/position/y` | differs | 15 | 9.375 |
| `callbacks/86/args/0/0/dragging` | differs | false | true |
| `callbacks/87/args/1/position/y` | differs | 15 | 9.375 |
| `callbacks/87/args/2/0/position/y` | differs | 15 | 9.375 |

### api (13)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0/position/y` | differs | 15 | 9.375 |
| `api/queries/getNode/position/y` | differs | 15 | 9.375 |
| `api/queries/getInternalNode/position/y` | differs | 15 | 9.375 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 15 | 9.375 |
| `api/queries/getInternalNode/internals/userNode/position/y` | differs | 15 | 9.375 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 15 | 9.375 |
| `api/queries/getNodesBounds/y` | differs | 15 | 9.375 |
| `api/queries/getNodesBounds/height` | differs | 125 | 130.625 |
| `api/queries/toObject/nodes/0/position/y` | differs | 15 | 9.375 |
| `api/queries/toObject/viewport/y` | differs | 30 | 35.625 |
| `api/queries/getViewport/y` | differs | 30 | 35.625 |
| `api/queries/screenToFlowPosition/y` | differs | -30 | -35.625 |
| `api/queries/flowToScreenPosition/y` | differs | 30 | 35.625 |

## Normalization

28 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (22) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — click-connect-reverse-direction

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

# Comparison report — click-connect-reverse-direction

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**No unclaimed differences.** The two traces agree everywhere.

## Normalization

22 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (11) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — connect-drag-holding-source

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

# Comparison report — connect-drag-holding-source

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**No unclaimed differences.** The two traces agree everywhere.

## Normalization

20 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (10) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — connect-drag-released-on-pane

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

# Comparison report — connect-drag-released-on-pane

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**No unclaimed differences.** The two traces agree everywhere.

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

**Failed:** 3 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouse… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouse… |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

20 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (11) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — resize-node-with-direct-control

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

# Comparison report — resize-node-with-direct-control

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

18 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (9) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — resize-node-with-resizer

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

# Comparison report — resize-node-with-resizer

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

18 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (9) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


---

# System parity run — resize-node-after-active-limit-change

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
| `callbacks/8` | left only | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… | — |
| `callbacks/9` | left only | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… | — |

**upstream did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — resize-node-after-active-limit-change

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

18 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (9) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onMove#1","onNodesChange#1","onMoveEnd#1","onMoveStart#2","onMove#2","onMoveEnd#2","onPaneMouseEnter#1","onPaneMouseMov… | ["onSelectionChange#1","onMoveStart#1","onMove#1","onMoveEnd#1","onNodesChange#1","onMoveStart#2","onMove#2","onMoveEnd#2","onPaneMouseEnter#1","onPaneMouseMov… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

8 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (4) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing


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

**Failed:** 1 unclaimed difference(s).

## Unclaimed differences

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onPaneMouseMove#1","onMoveStart#2"… |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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

**Failed:** 27 unclaimed difference(s).

## Unclaimed differences

### callbacks (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/1` | right only | — | {"name":"useOnSelectionChange","args":[{"nodes":[{"id":"Node-1","position":{"x":0,"y":0},"data":{"label":"Node-1"},"type":"input","measured":{"width":150,"heig… |
| `callbacks/0/args/0/nodes/0` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"mea… | — |

### hooks (11)

| path | kind | upstream | psflow |
|---|---|---|---|
| `hooks/flow-probe/useConnection/inProgress` | left only | false | — |
| `hooks/flow-probe/useInternalNode/internals/handleBounds/target` | differs | null | [] |
| `hooks/flow-probe/useStore/nodes` | left only | [{"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","className":"playwright-test-class-123","style":{"backgroundColor":"red"},"me… | — |
| `hooks/flow-probe/useStore/edges` | left only | [{"id":"1-2","type":"default","source":"Node-1","target":"Node-2","label":"edge"},{"id":"1-3","type":"default","source":"Node-1","target":"Node-3","label":"edg… | — |
| `hooks/flow-probe/useStore/transform` | left only | [517.6119402985074,32,1.2238805970149254] | — |
| `hooks/flow-probe/useStore/viewportInitialized` | left only | {"@undefined":true} | — |
| `hooks/flow-probe/useStore/error` | right only | — | ps-flow: `useStore` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's obj… |
| `hooks/flow-probe/useStoreApi/getState` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/setState` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/subscribe` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/error` | right only | — | ps-flow: `useStoreApi` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's … |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getState` | left only | {"rfId":"1","width":1280,"height":720,"transform":[517.6119402985074,32,1.2238805970149254],"nodes":[{"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0… | — |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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
| `console/5` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:55569/parity/driver/dist/psflow.js:69636:… |
| `console/6` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:55569/parity/driver/dist/psflow.js:69636:… |


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

**Failed:** 24 unclaimed difference(s).

## Unclaimed differences

### hooks (11)

| path | kind | upstream | psflow |
|---|---|---|---|
| `hooks/flow-probe/useConnection/inProgress` | left only | false | — |
| `hooks/flow-probe/useInternalNode/internals/handleBounds/target` | differs | null | [] |
| `hooks/flow-probe/useStore/nodes` | left only | [{"id":"1","data":{"label":"1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":36}},{"id":"2","data":{"label":"2"},"position":{"x":-1… | — |
| `hooks/flow-probe/useStore/edges` | left only | [{"id":"first-edge","source":"1","target":"2"},{"id":"second-edge","source":"1","target":"3"}] | — |
| `hooks/flow-probe/useStore/transform` | left only | [552.9449436703876,123.21024678345424,3.4822022531844965] | — |
| `hooks/flow-probe/useStore/viewportInitialized` | left only | {"@undefined":true} | — |
| `hooks/flow-probe/useStore/error` | right only | — | ps-flow: `useStore` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's obj… |
| `hooks/flow-probe/useStoreApi/getState` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/setState` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/subscribe` | left only | {"@ref":"function"} | — |
| `hooks/flow-probe/useStoreApi/error` | right only | — | ps-flow: `useStoreApi` has not crossed the JavaScript boundary — it hands over ps-flow's internal store state, which is a PureScript record and not upstream's … |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getState` | left only | {"rfId":"1","width":1280,"height":720,"transform":[552.9449436703876,123.21024678345424,3.4822022531844965],"nodes":[{"id":"1","data":{"label":"1"},"position":… | — |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

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
| `console/5` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:55569/parity/driver/dist/psflow.js:69636:… |
| `console/6` | right only | — | {"level":"error","text":"The above error occurred in the <HookProbe> component:\n\n    at HookProbe (http://127.0.0.1:55569/parity/driver/dist/psflow.js:69636:… |


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

**Failed:** 2 unclaimed difference(s).

## Unclaimed differences

### props (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `props/connection-line-props/fromNode/internals/handleBounds/target` | differs | null | [] |
| `props/connection-line-props/toNode/internals/handleBounds/source` | differs | null | [] |

