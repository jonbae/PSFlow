# System parity

The dual-run net over 1 scenario(s), against vendored `@xyflow/react` 12.11.0.

Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice.

**1 of 1 scenario(s) failed.**

A failing net is the expected state while the divergence backlog is being worked: the scenarios below
are recording what the two implementations actually do, and a difference is fixed in the port or
claimed by a region — never by loosening what the net looks at.

| scenario | verdict | failure classes | differences |
|---|---|---|---|
| `drag-node-autopan` | **failed** | self-inconsistent, unclaimed-difference | 139 |

Every trace behind this report is on disk under `parity/system/traces` — four per scenario, two sides captured
twice each. They are the artifact: re-diffing them costs seconds and no browser.

---

# System parity run — drag-node-autopan

**Failed:** self-inconsistent, self-inconsistent, unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | **disagrees with itself** | 49 |
| psflow | 1, 2 | **disagrees with itself** | 5 |

### upstream disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `callbacks/67` | left only | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/68` | left only | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/69` | left only | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks/70` | left only | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… |
| `callbacks/27/args/1/position/x` | differs | -749 | -409 |
| `callbacks/27/args/1/position/y` | differs | -692 | -352 |
| `callbacks/29/args/0/x` | differs | 1020 | 1030 |
| `callbacks/30/args/1/x` | differs | 1020 | 1030 |
| `callbacks/31/args/0/0/position/x` | differs | -1089 | -750 |
| `callbacks/31/args/0/0/position/y` | differs | -1032 | -912 |
| `callbacks/32/args/1/position/x` | differs | -1089 | -750 |
| `callbacks/32/args/1/position/y` | differs | -1032 | -912 |
| `callbacks/32/args/2/0/position/x` | differs | -1089 | -750 |
| `callbacks/32/args/2/0/position/y` | differs | -1032 | -912 |
| `callbacks/33/args/1/x` | differs | 1020 | 1030 |
| `callbacks/35/args/0/0/position/x` | differs | -1090 | -1100 |
| `callbacks/36/args/1/position/x` | differs | -1090 | -1100 |
| `callbacks/36/args/2/0/position/x` | differs | -1090 | -1100 |
| `callbacks/37/args/1/x` | differs | 1020 | 1030 |
| `callbacks/38/args/0/x` | differs | 1370 | 1380 |
| `callbacks/39/args/1/x` | differs | 1370 | 1380 |
| `callbacks/40/args/0/0/position/x` | differs | -1440 | -1450 |
| `callbacks/41/args/1/position/x` | differs | -1440 | -1450 |
| `callbacks/41/args/2/0/position/x` | differs | -1440 | -1450 |
| `callbacks/42/args/1/x` | differs | 1370 | 1380 |
| `callbacks/43/args/1/position/x` | differs | -1440 | -1100 |
| `callbacks/43/args/1/position/y` | differs | -1592 | -1252 |
| `callbacks/44/args/1/x` | differs | 1370 | 1380 |
| `callbacks/45/args/0/y` | differs | 1920 | 1930 |
| `callbacks/46/args/1/y` | differs | 1920 | 1930 |
| `callbacks/47/args/0/0/position/x` | differs | -1790 | -1449 |
| `callbacks/47/args/0/0/position/y` | differs | -1932 | -1593 |
| `callbacks/48/args/1/position/x` | differs | -1790 | -1449 |
| `callbacks/48/args/1/position/y` | differs | -1932 | -1593 |
| `callbacks/48/args/2/0/position/x` | differs | -1790 | -1449 |
| `callbacks/48/args/2/0/position/y` | differs | -1932 | -1593 |
| `callbacks/49/args/1/y` | differs | 1920 | 1930 |
| `callbacks/51/args/0/0/position/y` | differs | -1933 | -1943 |
| `callbacks/52/args/1/position/y` | differs | -1933 | -1943 |
| `callbacks/52/args/2/0/position/y` | differs | -1933 | -1943 |
| `callbacks/53/args/1/y` | differs | 1920 | 1930 |
| `callbacks/56/args/0/0/position/y` | differs | -2283 | -2293 |
| `callbacks/57/args/1/position/y` | differs | -2283 | -2293 |
| `callbacks/57/args/2/0/position/y` | differs | -2283 | -2293 |
| `callbacks/59/args/0/screenX` | differs | 6 | 5 |
| `callbacks/59/args/0/clientX` | differs | 6 | 5 |
| `callbacks/59/args/0/pageX` | differs | 6 | 5 |
| `callbacks/59/args/1/position/y` | differs | -2283 | -2293 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `callbacks/99` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/100` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/101` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/102` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… |

**upstream and psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — drag-node-autopan

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 85 unclaimed difference(s).

## Unclaimed differences

### callbacks (84)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/59` | left only | {"name":"onNodeMouseLeave","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseLeave","_targetInst":{"@ref":"React fiber"},"type":"mouseleave","nativeE… | — |
| `callbacks/71` | left only | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… | — |
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
| `callbacks/80` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/81` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/82` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/83` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/84` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/85` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/86` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/87` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/88` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/89` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/90` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/91` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/95` | right only | — | {"name":"onMoveStart","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/96` | right only | — | {"name":"onViewportChange","args":[{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/97` | right only | — | {"name":"onMove","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks/98` | right only | — | {"name":"onMoveEnd","args":[null,{"x":2000,"y":2000,"zoom":1}]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… | ["onSelectionChange#1","onNodesChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onNodesChange#2","onNodeDragStart#1… |
| `callbacks/20/args/1/x` | differs | 340 | 0 |
| `callbacks/20/args/1/y` | differs | 560 | 220.00000000000003 |
| `callbacks/26/args/1/x` | differs | 680 | 340 |
| `callbacks/26/args/1/y` | differs | 900 | 560 |
| `callbacks/27/args/1/position/x` | differs | -749 | -409 |
| `callbacks/27/args/1/position/y` | differs | -692 | -352 |
| `callbacks/33/args/1/x` | differs | 1020 | 680 |
| `callbacks/33/args/1/y` | differs | 1240 | 900 |
| `callbacks/35/args/0/0/position/x` | differs | -1090 | -1429 |
| `callbacks/35/args/0/0/position/y` | differs | -1252 | -1372 |
| `callbacks/36/args/1/position/x` | differs | -1090 | -1429 |
| `callbacks/36/args/1/position/y` | differs | -1252 | -1372 |
| `callbacks/36/args/2/0/position/x` | differs | -1090 | -1429 |
| `callbacks/36/args/2/0/position/y` | differs | -1252 | -1372 |
| `callbacks/38/args/0/x` | differs | 1370 | 1360 |
| `callbacks/39/args/1/x` | differs | 1370 | 1360 |
| `callbacks/40/args/0/0/position/x` | differs | -1440 | -1769 |
| `callbacks/40/args/0/0/position/y` | differs | -1592 | -1712 |
| `callbacks/41/args/1/position/x` | differs | -1440 | -1769 |
| `callbacks/41/args/1/position/y` | differs | -1592 | -1712 |
| `callbacks/41/args/2/0/position/x` | differs | -1440 | -1769 |
| `callbacks/41/args/2/0/position/y` | differs | -1592 | -1712 |
| `callbacks/42/args/1/x` | differs | 1370 | 1020 |
| `callbacks/42/args/1/y` | differs | 1580 | 1240 |
| `callbacks/43/args/1/position/x` | differs | -1440 | -2070 |
| `callbacks/43/args/1/position/y` | differs | -1592 | -2012 |
| `callbacks/44/args/1/x` | differs | 1370 | 1360 |
| `callbacks/45/args/0/x` | differs | 1720 | 1700 |
| `callbacks/46/args/1/x` | differs | 1720 | 1700 |
| `callbacks/47/args/0/0/position/x` | differs | -1790 | -2109 |
| `callbacks/47/args/0/0/position/y` | differs | -1932 | -2052 |
| `callbacks/48/args/1/position/x` | differs | -1790 | -2109 |
| `callbacks/48/args/1/position/y` | differs | -1932 | -2052 |
| `callbacks/48/args/2/0/position/x` | differs | -1790 | -2109 |
| `callbacks/48/args/2/0/position/y` | differs | -1932 | -2052 |
| `callbacks/49/args/1/x` | differs | 1720 | 1360 |
| `callbacks/49/args/1/y` | differs | 1920 | 1580 |
| `callbacks/51/args/0/0/position/x` | differs | -1789 | -2070 |
| `callbacks/51/args/0/0/position/y` | differs | -1933 | -2012 |
| `callbacks/52/args/1/position/x` | differs | -1789 | -2070 |
| `callbacks/52/args/1/position/y` | differs | -1933 | -2012 |
| `callbacks/52/args/2/0/position/x` | differs | -1789 | -2070 |
| `callbacks/52/args/2/0/position/y` | differs | -1933 | -2012 |
| `callbacks/53/args/1/x` | differs | 1720 | 1700 |
| `callbacks/56/args/0/0/position/x` | differs | -2129 | -2069 |
| `callbacks/56/args/0/0/position/y` | differs | -2283 | -2013 |
| `callbacks/57/args/1/position/x` | differs | -2129 | -2069 |
| `callbacks/57/args/1/position/y` | differs | -2283 | -2013 |
| `callbacks/57/args/2/0/position/x` | differs | -2129 | -2069 |
| `callbacks/57/args/2/0/position/y` | differs | -2283 | -2013 |
| `callbacks/58/args/1/x` | differs | 2000 | 1700 |
| `callbacks/58/args/1/y` | differs | 2000 | 1920 |

### api (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |

## Normalization

22 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (17) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing

