# System parity

The dual-run net over 1 scenario(s), against vendored `@xyflow/react` 12.11.0.

Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice.

**1 of 1 scenario(s) failed.**

A failing net is the expected state while the divergence backlog is being worked: the scenarios below
are recording what the two implementations actually do, and a difference is fixed in the port or
claimed by a region — never by loosening what the net looks at.

| scenario | verdict | failure classes | differences |
|---|---|---|---|
| `arrow-key-selected-node` | **failed** | self-inconsistent, unclaimed-difference | 4 |

Every trace behind this report is on disk under `parity/system/traces` — four per scenario, two sides captured
twice each. They are the artifact: re-diffing them costs seconds and no browser.

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
| `callbacks/15/args/1/position/x` | differs | 0 | 5 |

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

