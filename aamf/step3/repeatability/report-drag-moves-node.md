# System parity

The dual-run net over 1 scenario(s), against vendored `@xyflow/react` 12.11.0.

Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice.

**1 of 1 scenario(s) failed.**

A failing net is the expected state while the divergence backlog is being worked: the scenarios below
are recording what the two implementations actually do, and a difference is fixed in the port or
claimed by a region — never by loosening what the net looks at.

| scenario | verdict | failure classes | differences |
|---|---|---|---|
| `drag-moves-node` | **failed** | self-inconsistent, unclaimed-difference | 138 |

Every trace behind this report is on disk under `parity/system/traces` — four per scenario, two sides captured
twice each. They are the artifact: re-diffing them costs seconds and no browser.

---

# System parity run — drag-moves-node

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
| psflow | 1, 2 | **disagrees with itself** | 79 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `callbacks/21` | left only | {"name":"onEdgeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… | — |
| `callbacks/25` | left only | {"name":"onEdgeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… | — |
| `callbacks/32` | left only | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… | — |
| `callbacks/33` | left only | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… | — |
| `callbacks/34` | left only | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… | — |
| `callbacks/41` | left only | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/18/args/0/target/@ref` | differs | path | rect |
| `callbacks/18/args/0/screenX` | differs | 654 | 734 |
| `callbacks/18/args/0/screenY` | differs | 90 | 170 |
| `callbacks/18/args/0/clientX` | differs | 654 | 734 |
| `callbacks/18/args/0/clientY` | differs | 90 | 170 |
| `callbacks/18/args/0/pageX` | differs | 654 | 734 |
| `callbacks/18/args/0/pageY` | differs | 90 | 170 |
| `callbacks/19/args/0/screenX` | differs | 654 | 734 |
| `callbacks/19/args/0/screenY` | differs | 90 | 170 |
| `callbacks/19/args/0/clientX` | differs | 654 | 734 |
| `callbacks/19/args/0/clientY` | differs | 90 | 170 |
| `callbacks/19/args/0/pageX` | differs | 654 | 734 |
| `callbacks/19/args/0/pageY` | differs | 90 | 170 |
| `callbacks/19/args/0/relatedTarget/@ref` | differs | path | rect |
| `callbacks/19/args/1/id` | differs | Node-1 | Node-3 |
| `callbacks/19/args/1/position/x` | differs | 38.78048780487805 | 100 |
| `callbacks/19/args/1/position/y` | differs | 38.78048780487805 | 100 |
| `callbacks/19/args/1/data/label` | differs | Node-1 | Node-3 |
| `callbacks/19/args/1/type` | left only | input | — |
| `callbacks/19/args/1/selected` | left only | true | — |
| `callbacks/19/args/1/dragging` | left only | true | — |
| `callbacks/19/args/1/className` | left only | playwright-test-class-123 | — |
| `callbacks/19/args/1/style` | left only | {"backgroundColor":"red"} | — |
| `callbacks/20/args/0/screenX` | differs | 694 | 774 |
| `callbacks/20/args/0/screenY` | differs | 130 | 210 |
| `callbacks/20/args/0/clientX` | differs | 694 | 774 |
| `callbacks/20/args/0/clientY` | differs | 130 | 210 |
| `callbacks/20/args/0/pageX` | differs | 694 | 774 |
| `callbacks/20/args/0/pageY` | differs | 130 | 210 |
| `callbacks/20/args/0/relatedTarget/@ref` | differs | rect | DIV |
| `callbacks/20/args/1/id` | differs | Node-1 | Node-3 |
| `callbacks/20/args/1/position/x` | differs | 38.78048780487805 | 100 |
| `callbacks/20/args/1/position/y` | differs | 38.78048780487805 | 100 |
| `callbacks/20/args/1/data/label` | differs | Node-1 | Node-3 |
| `callbacks/20/args/1/type` | left only | input | — |
| `callbacks/20/args/1/selected` | left only | true | — |
| `callbacks/20/args/1/dragging` | left only | true | — |
| `callbacks/20/args/1/className` | left only | playwright-test-class-123 | — |
| `callbacks/20/args/1/style` | left only | {"backgroundColor":"red"} | — |
| `callbacks/26/args/0/screenX` | differs | 694 | 774 |
| `callbacks/26/args/0/screenY` | differs | 130 | 210 |
| `callbacks/26/args/0/clientX` | differs | 694 | 774 |
| `callbacks/26/args/0/clientY` | differs | 130 | 210 |
| `callbacks/26/args/0/pageX` | differs | 694 | 774 |
| `callbacks/26/args/0/pageY` | differs | 130 | 210 |
| `callbacks/26/args/0/relatedTarget/@ref` | differs | rect | DIV |
| `callbacks/26/args/1/position/x` | differs | 77.56097560975608 | 155.1219512195122 |
| `callbacks/26/args/1/position/y` | differs | 77.5609756097561 | 155.1219512195122 |
| `callbacks/27/args/0/screenX` | differs | 734 | 814 |
| `callbacks/27/args/0/screenY` | differs | 170 | 250 |
| `callbacks/27/args/0/clientX` | differs | 734 | 814 |
| `callbacks/27/args/0/clientY` | differs | 170 | 250 |
| `callbacks/27/args/0/pageX` | differs | 734 | 814 |
| `callbacks/27/args/0/pageY` | differs | 170 | 250 |
| `callbacks/27/args/1/position/x` | differs | 77.56097560975608 | 155.1219512195122 |
| `callbacks/27/args/1/position/y` | differs | 77.5609756097561 | 155.1219512195122 |
| `callbacks/28/args/0/screenX` | differs | 734 | 814 |
| `callbacks/28/args/0/screenY` | differs | 170 | 250 |
| `callbacks/28/args/0/clientX` | differs | 734 | 814 |
| `callbacks/28/args/0/clientY` | differs | 170 | 250 |
| `callbacks/28/args/0/pageX` | differs | 734 | 814 |
| `callbacks/28/args/0/pageY` | differs | 170 | 250 |
| `callbacks/28/args/0/buttons` | differs | 1 | 0 |
| `callbacks/28/args/1/id` | differs | Node-3 | Node-1 |
| `callbacks/28/args/1/position/x` | differs | 100 | 193.90243902439028 |
| `callbacks/28/args/1/position/y` | differs | 100 | 193.90243902439022 |
| `callbacks/28/args/1/data/label` | differs | Node-3 | Node-1 |
| `callbacks/28/args/1/type` | right only | — | input |
| `callbacks/28/args/1/selected` | right only | — | true |
| `callbacks/28/args/1/dragging` | right only | — | true |
| `callbacks/28/args/1/className` | right only | — | playwright-test-class-123 |
| `callbacks/28/args/1/style` | right only | — | {"backgroundColor":"red"} |

**psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — drag-moves-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 59 unclaimed difference(s).

## Unclaimed differences

### callbacks (58)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/21` | right only | — | {"name":"onEdgeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… |
| `callbacks/25` | right only | — | {"name":"onEdgeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… |
| `callbacks/27` | right only | — | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… |
| `callbacks/28` | right only | — | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… |
| `callbacks/32` | right only | — | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… |
| `callbacks/33` | right only | — | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… |
| `callbacks/34` | right only | — | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… |
| `callbacks/41` | right only | — | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… |
| `callbacks` | ordered differently | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onNodesChange#1","onMoveEnd#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… | ["onSelectionChange#1","onMoveStart#1","onViewportChange#1","onMove#1","onMoveEnd#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMo… |
| `callbacks/21/args/0/target/@ref` | differs | rect | path |
| `callbacks/21/args/0/screenX` | differs | 734 | 654 |
| `callbacks/21/args/0/screenY` | differs | 170 | 90 |
| `callbacks/21/args/0/clientX` | differs | 734 | 654 |
| `callbacks/21/args/0/clientY` | differs | 170 | 90 |
| `callbacks/21/args/0/pageX` | differs | 734 | 654 |
| `callbacks/21/args/0/pageY` | differs | 170 | 90 |
| `callbacks/22/args/0/screenX` | differs | 734 | 654 |
| `callbacks/22/args/0/screenY` | differs | 170 | 90 |
| `callbacks/22/args/0/clientX` | differs | 734 | 654 |
| `callbacks/22/args/0/clientY` | differs | 170 | 90 |
| `callbacks/22/args/0/pageX` | differs | 734 | 654 |
| `callbacks/22/args/0/pageY` | differs | 170 | 90 |
| `callbacks/22/args/0/relatedTarget/@ref` | differs | rect | path |
| `callbacks/22/args/1/id` | differs | Node-3 | Node-1 |
| `callbacks/22/args/1/data/label` | differs | Node-3 | Node-1 |
| `callbacks/22/args/1/position/x` | differs | 100 | 38.78048780487805 |
| `callbacks/22/args/1/position/y` | differs | 100 | 38.78048780487805 |
| `callbacks/22/args/1/type` | right only | — | input |
| `callbacks/22/args/1/selected` | right only | — | true |
| `callbacks/22/args/1/dragging` | right only | — | true |
| `callbacks/22/args/1/className` | right only | — | playwright-test-class-123 |
| `callbacks/22/args/1/style` | right only | — | {"backgroundColor":"red"} |
| `callbacks/26/args/0/screenX` | differs | 774 | 694 |
| `callbacks/26/args/0/screenY` | differs | 210 | 130 |
| `callbacks/26/args/0/clientX` | differs | 774 | 694 |
| `callbacks/26/args/0/clientY` | differs | 210 | 130 |
| `callbacks/26/args/0/pageX` | differs | 774 | 694 |
| `callbacks/26/args/0/pageY` | differs | 210 | 130 |
| `callbacks/26/args/0/relatedTarget/@ref` | differs | DIV | rect |
| `callbacks/26/args/1/id` | differs | Node-3 | Node-1 |
| `callbacks/26/args/1/data/label` | differs | Node-3 | Node-1 |
| `callbacks/26/args/1/position/x` | differs | 100 | 38.78048780487805 |
| `callbacks/26/args/1/position/y` | differs | 100 | 38.78048780487805 |
| `callbacks/26/args/1/type` | right only | — | input |
| `callbacks/26/args/1/selected` | right only | — | true |
| `callbacks/26/args/1/dragging` | right only | — | true |
| `callbacks/26/args/1/className` | right only | — | playwright-test-class-123 |
| `callbacks/26/args/1/style` | right only | — | {"backgroundColor":"red"} |
| `callbacks/33/args/0/screenX` | differs | 814 | 694 |
| `callbacks/33/args/0/screenY` | differs | 250 | 130 |
| `callbacks/33/args/0/clientX` | differs | 814 | 694 |
| `callbacks/33/args/0/clientY` | differs | 250 | 130 |
| `callbacks/33/args/0/pageX` | differs | 814 | 694 |
| `callbacks/33/args/0/pageY` | differs | 250 | 130 |
| `callbacks/33/args/0/buttons` | differs | 0 | 1 |
| `callbacks/33/args/0/relatedTarget/@ref` | differs | DIV | rect |
| `callbacks/33/args/1/position/x` | differs | 193.90243902439028 | 77.56097560975608 |
| `callbacks/33/args/1/position/y` | differs | 193.90243902439022 | 77.5609756097561 |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

38 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (25) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing

