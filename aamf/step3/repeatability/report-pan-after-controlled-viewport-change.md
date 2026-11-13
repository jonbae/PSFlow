# System parity

The dual-run net over 1 scenario(s), against vendored `@xyflow/react` 12.11.0.

Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice.

**1 of 1 scenario(s) failed.**

A failing net is the expected state while the divergence backlog is being worked: the scenarios below
are recording what the two implementations actually do, and a difference is fixed in the port or
claimed by a region — never by loosening what the net looks at.

| scenario | verdict | failure classes | differences |
|---|---|---|---|
| `pan-after-controlled-viewport-change` | **failed** | unclaimed-difference | 2 |

Every trace behind this report is on disk under `parity/system/traces` — four per scenario, two sides captured
twice each. They are the artifact: re-diffing them costs seconds and no browser.

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

