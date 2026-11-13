# System parity

The dual-run net over 1 scenario(s), against vendored `@xyflow/react` 12.11.0.

Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice.

**1 of 1 scenario(s) failed.**

A failing net is the expected state while the divergence backlog is being worked: the scenarios below
are recording what the two implementations actually do, and a difference is fixed in the port or
claimed by a region — never by loosening what the net looks at.

| scenario | verdict | failure classes | differences |
|---|---|---|---|
| `drag-node-reports-changes` | **failed** | self-inconsistent, unclaimed-difference | 295 |

Every trace behind this report is on disk under `parity/system/traces` — four per scenario, two sides captured
twice each. They are the artifact: re-diffing them costs seconds and no browser.

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
| upstream | 1, 2 | **disagrees with itself** | 124 |
| psflow | 1, 2 | **disagrees with itself** | 83 |

### upstream disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(0px, 41.25px) scale(1); | transform: translate(0px, 48.75px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[0]/attrs/d` | differs | M148,23.75 C197.5,23.75 197.5,120 247,120 | M148,16.25 C197.5,16.25 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[1]/attrs/d` | differs | M148,23.75 C197.5,23.75 197.5,120 247,120 | M148,16.25 C197.5,16.25 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/circle[0]/attrs/cy` | differs | 23.75 | 16.25 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/n1/attrs/style` | differs | height: 40px; pointer-events: all; transform: translate(45px, 3.75px); visibility: visible; width: 100px; z-index: 1000; | height: 40px; pointer-events: all; transform: translate(45px, -3.75px); visibility: visible; width: 100px; z-index: 1000; |
| `dom/root/children/div[2]/children/svg[0]/attrs/viewBox` | differs | -32 -193.25 1344 1024 | -32 -200.75 1344 1024 |
| `dom/root/children/div[2]/children/svg[0]/children/rect[0]/attrs/y` | differs | 3.75 | -3.75 |
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-225.25h1408v1088h-1408z⏎        M0,-41.25h1280v720h-1280z | M-64,-232.75h1408v1088h-1408z⏎        M0,-48.75h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1/attrs/y` | differs | 1.25 | 8.75 |
| `callbacks/68` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":41.25,"zoom":1}]} |
| `callbacks/77` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":43.125,"zoom":1}]} |
| `callbacks/83` | right only | — | {"name":"onMoveStart","args":[null,{"x":0,"y":45,"zoom":1}]} |
| `callbacks/84` | right only | — | {"name":"onViewportChange","args":[{"x":0,"y":46.875,"zoom":1}]} |
| `callbacks/85` | right only | — | {"name":"onMove","args":[null,{"x":0,"y":46.875,"zoom":1}]} |
| `callbacks/88` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":46.875,"zoom":1}]} |
| `callbacks/89` | right only | — | {"name":"onMoveStart","args":[null,{"x":0,"y":46.875,"zoom":1}]} |
| `callbacks/90` | right only | — | {"name":"onViewportChange","args":[{"x":0,"y":48.75,"zoom":1}]} |
| `callbacks/91` | right only | — | {"name":"onMove","args":[null,{"x":0,"y":48.75,"zoom":1}]} |
| `callbacks/94` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":48.75,"zoom":1}]} |
| `callbacks/112` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":40,"y":-8.75},"sourcePosition":"right","… |
| `callbacks/114` | right only | — | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":45,"y":-3.75},"dragging":true}]]} |
| `callbacks/115` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":45,"y":-3.75},"sourcePosition":"right","… |
| `callbacks/116` | right only | — | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":45,"y":-3.75},"dragging":false}]]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/25/args/1/y` | differs | 15 | 11.25 |
| `callbacks/31/args/1/y` | differs | 18.75 | 15 |
| `callbacks/37/args/1/y` | differs | 22.5 | 18.75 |
| `callbacks/43/args/1/y` | differs | 26.25 | 22.5 |
| `callbacks/49/args/1/y` | differs | 30 | 26.25 |
| `callbacks/55/args/1/y` | differs | 33.75 | 30 |
| `callbacks/57/args/0/0/position/x` | differs | 10 | 5 |
| `callbacks/57/args/0/0/position/y` | differs | -23.75 | -25 |
| `callbacks/58/args/1/position/x` | differs | 10 | 5 |
| `callbacks/58/args/1/position/y` | differs | -23.75 | -25 |
| `callbacks/58/args/2/0/position/x` | differs | 10 | 5 |
| `callbacks/58/args/2/0/position/y` | differs | -23.75 | -25 |
| `callbacks/60/args/0/y` | differs | 35.625 | 37.5 |
| `callbacks/61/args/1/y` | differs | 35.625 | 37.5 |
| `callbacks/62/args/0/0/position/x` | differs | 10 | 5 |
| `callbacks/62/args/0/0/position/y` | differs | -25.625 | -28.75 |
| `callbacks/63/args/1/position/x` | differs | 10 | 5 |
| `callbacks/63/args/1/position/y` | differs | -25.625 | -28.75 |
| `callbacks/63/args/2/0/position/x` | differs | 10 | 5 |
| `callbacks/63/args/2/0/position/y` | differs | -25.625 | -28.75 |
| `callbacks/64/args/1/y` | differs | 35.625 | 37.5 |
| `callbacks/65/args/0/y` | differs | 37.5 | 41.25 |
| `callbacks/66/args/1/y` | differs | 37.5 | 41.25 |
| `callbacks/67/args/0/0/position/y` | differs | -27.5 | -31.25 |
| `callbacks/68/args/1/position/y` | differs | -27.5 | -31.25 |
| `callbacks/68/args/2/0/position/y` | differs | -27.5 | -31.25 |
| `callbacks/69/args/1/y` | differs | 37.5 | 41.25 |
| `callbacks/70/args/0/y` | differs | 39.375 | 43.125 |
| `callbacks/71/args/1/y` | differs | 39.375 | 43.125 |
| `callbacks/72/args/0/0/position/y` | differs | -29.375 | -33.125 |
| `callbacks/73/args/1/position/y` | differs | -29.375 | -33.125 |
| `callbacks/73/args/2/0/position/y` | differs | -29.375 | -33.125 |
| `callbacks/74/args/1/y` | differs | 39.375 | 33.75 |
| `callbacks/75/args/1/y` | differs | 39.375 | 43.125 |
| `callbacks/76/args/0/y` | differs | 41.25 | 45 |
| `callbacks/77/args/1/y` | differs | 41.25 | 45 |
| `callbacks/78/args/0/0/position/y` | differs | -31.25 | -35 |
| `callbacks/79/args/1/position/y` | differs | -31.25 | -35 |
| `callbacks/79/args/2/0/position/y` | differs | -31.25 | -35 |
| `callbacks/80/args/1/y` | differs | 41.25 | 37.5 |
| `callbacks/82/args/0/0/position/x` | differs | 15 | 10 |
| `callbacks/82/args/0/0/position/y` | differs | -26.25 | -36.875 |
| `callbacks/83/args/1/position/x` | differs | 15 | 10 |
| `callbacks/83/args/1/position/y` | differs | -26.25 | -36.875 |
| `callbacks/83/args/2/0/position/x` | differs | 15 | 10 |
| `callbacks/83/args/2/0/position/y` | differs | -26.25 | -36.875 |
| `callbacks/85/args/0/0/position/x` | differs | 20 | 10 |
| `callbacks/85/args/0/0/position/y` | differs | -21.25 | -38.75 |
| `callbacks/86/args/1/position/x` | differs | 20 | 10 |
| `callbacks/86/args/1/position/y` | differs | -21.25 | -38.75 |
| `callbacks/86/args/2/0/position/x` | differs | 20 | 10 |
| `callbacks/86/args/2/0/position/y` | differs | -21.25 | -38.75 |
| `callbacks/88/args/0/0/position/x` | differs | 25 | 15 |
| `callbacks/88/args/0/0/position/y` | differs | -16.25 | -33.75 |
| `callbacks/89/args/1/position/x` | differs | 25 | 15 |
| `callbacks/89/args/1/position/y` | differs | -16.25 | -33.75 |
| `callbacks/89/args/2/0/position/x` | differs | 25 | 15 |
| `callbacks/89/args/2/0/position/y` | differs | -16.25 | -33.75 |
| `callbacks/91/args/0/0/position/x` | differs | 30 | 20 |
| `callbacks/91/args/0/0/position/y` | differs | -11.25 | -28.75 |
| `callbacks/92/args/1/position/x` | differs | 30 | 20 |
| `callbacks/92/args/1/position/y` | differs | -11.25 | -28.75 |
| `callbacks/92/args/2/0/position/x` | differs | 30 | 20 |
| `callbacks/92/args/2/0/position/y` | differs | -11.25 | -28.75 |
| `callbacks/94/args/0/0/position/x` | differs | 35 | 25 |
| `callbacks/94/args/0/0/position/y` | differs | -6.25 | -23.75 |
| `callbacks/95/args/1/position/x` | differs | 35 | 25 |
| `callbacks/95/args/1/position/y` | differs | -6.25 | -23.75 |
| `callbacks/95/args/2/0/position/x` | differs | 35 | 25 |
| `callbacks/95/args/2/0/position/y` | differs | -6.25 | -23.75 |
| `callbacks/97/args/0/0/position/x` | differs | 40 | 30 |
| `callbacks/97/args/0/0/position/y` | differs | -1.25 | -18.75 |
| `callbacks/98/args/1/position/x` | differs | 40 | 30 |
| `callbacks/98/args/1/position/y` | differs | -1.25 | -18.75 |
| `callbacks/98/args/2/0/position/x` | differs | 40 | 30 |
| `callbacks/98/args/2/0/position/y` | differs | -1.25 | -18.75 |
| `callbacks/100/args/0/0/position/x` | differs | 45 | 35 |
| `callbacks/100/args/0/0/position/y` | differs | 3.75 | -13.75 |
| `callbacks/101/args/1/position/x` | differs | 45 | 35 |
| `callbacks/101/args/1/position/y` | differs | 3.75 | -13.75 |
| `callbacks/101/args/2/0/position/x` | differs | 45 | 35 |
| `callbacks/101/args/2/0/position/y` | differs | 3.75 | -13.75 |
| `callbacks/102/args/0/0/position/x` | differs | 45 | 40 |
| `callbacks/102/args/0/0/position/y` | differs | 3.75 | -8.75 |
| `callbacks/102/args/0/0/dragging` | differs | false | true |
| `callbacks/103/args/1/position/y` | differs | 3.75 | -3.75 |
| `callbacks/103/args/2/0/position/y` | differs | 3.75 | -3.75 |
| `api/queries/getNodes/0/position/y` | differs | 3.75 | -3.75 |
| `api/queries/getNode/position/y` | differs | 3.75 | -3.75 |
| `api/queries/getInternalNode/position/y` | differs | 3.75 | -3.75 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 3.75 | -3.75 |
| `api/queries/getInternalNode/internals/userNode/position/y` | differs | 3.75 | -3.75 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 3.75 | -3.75 |
| `api/queries/getNodesBounds/y` | differs | 3.75 | -3.75 |
| `api/queries/getNodesBounds/height` | differs | 136.25 | 143.75 |
| `api/queries/toObject/nodes/0/position/y` | differs | 3.75 | -3.75 |
| `api/queries/toObject/viewport/y` | differs | 41.25 | 48.75 |
| `api/queries/getViewport/y` | differs | 41.25 | 48.75 |
| `api/queries/screenToFlowPosition/y` | differs | -41.25 | -48.75 |
| `api/queries/flowToScreenPosition/y` | differs | 41.25 | 48.75 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `callbacks/85` | right only | — | {"name":"onMoveStart","args":[null,{"x":0,"y":41.25,"zoom":1}]} |
| `callbacks/86` | right only | — | {"name":"onViewportChange","args":[{"x":0,"y":43.125,"zoom":1}]} |
| `callbacks/87` | right only | — | {"name":"onMove","args":[null,{"x":0,"y":43.125,"zoom":1}]} |
| `callbacks/88` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":43.125,"zoom":1}]} |
| `callbacks/111` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","position":{"x":45,"y":1.875},"data":{"label":"n1"},"sourcePosition":"right","… |
| `callbacks/112` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"n1","position":{"x":45,"y":1.875},"dragging":false}]]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/59/args/0/y` | differs | 37.5 | 35.625 |
| `callbacks/60/args/1/y` | differs | 37.5 | 35.625 |
| `callbacks/61/args/1/y` | differs | 37.5 | 35.625 |
| `callbacks/62/args/0/0/position/x` | differs | 5 | 10 |
| `callbacks/62/args/0/0/position/y` | differs | -25 | -23.75 |
| `callbacks/63/args/1/position/x` | differs | 5 | 10 |
| `callbacks/63/args/1/position/y` | differs | -25 | -23.75 |
| `callbacks/63/args/2/0/position/x` | differs | 5 | 10 |
| `callbacks/63/args/2/0/position/y` | differs | -25 | -23.75 |
| `callbacks/65/args/0/0/position/y` | differs | -27.5 | -25.625 |
| `callbacks/66/args/1/position/y` | differs | -27.5 | -25.625 |
| `callbacks/66/args/2/0/position/y` | differs | -27.5 | -25.625 |
| `callbacks/67/args/1/y` | differs | 37.5 | 35.625 |
| `callbacks/68/args/0/y` | differs | 39.375 | 37.5 |
| `callbacks/69/args/1/y` | differs | 39.375 | 37.5 |
| `callbacks/70/args/1/y` | differs | 39.375 | 37.5 |
| `callbacks/71/args/0/0/position/y` | differs | -29.375 | -27.5 |
| `callbacks/72/args/1/position/y` | differs | -29.375 | -27.5 |
| `callbacks/72/args/2/0/position/y` | differs | -29.375 | -27.5 |
| `callbacks/73/args/1/y` | differs | 39.375 | 37.5 |
| `callbacks/74/args/0/y` | differs | 41.25 | 39.375 |
| `callbacks/75/args/1/y` | differs | 41.25 | 39.375 |
| `callbacks/76/args/1/y` | differs | 41.25 | 39.375 |
| `callbacks/77/args/0/0/position/y` | differs | -31.25 | -29.375 |
| `callbacks/78/args/1/position/y` | differs | -31.25 | -29.375 |
| `callbacks/78/args/2/0/position/y` | differs | -31.25 | -29.375 |
| `callbacks/79/args/1/y` | differs | 41.25 | 39.375 |
| `callbacks/80/args/0/y` | differs | 43.125 | 41.25 |
| `callbacks/81/args/1/y` | differs | 43.125 | 41.25 |
| `callbacks/82/args/1/y` | differs | 43.125 | 41.25 |
| `callbacks/83/args/0/0/position/y` | differs | -33.125 | -31.25 |
| `callbacks/84/args/1/position/y` | differs | -33.125 | -31.25 |
| `callbacks/84/args/2/0/position/y` | differs | -33.125 | -31.25 |
| `callbacks/86/args/0/0/position/x` | differs | 15 | 10 |
| `callbacks/86/args/0/0/position/y` | differs | -28.125 | -33.125 |
| `callbacks/87/args/1/position/x` | differs | 15 | 10 |
| `callbacks/87/args/1/position/y` | differs | -28.125 | -33.125 |
| `callbacks/87/args/2/0/position/x` | differs | 15 | 10 |
| `callbacks/87/args/2/0/position/y` | differs | -28.125 | -33.125 |
| `callbacks/89/args/0/0/position/x` | differs | 20 | 15 |
| `callbacks/89/args/0/0/position/y` | differs | -23.125 | -28.125 |
| `callbacks/90/args/1/position/x` | differs | 20 | 15 |
| `callbacks/90/args/1/position/y` | differs | -23.125 | -28.125 |
| `callbacks/90/args/2/0/position/x` | differs | 20 | 15 |
| `callbacks/90/args/2/0/position/y` | differs | -23.125 | -28.125 |
| `callbacks/92/args/0/0/position/x` | differs | 25 | 20 |
| `callbacks/92/args/0/0/position/y` | differs | -18.125 | -23.125 |
| `callbacks/93/args/1/position/x` | differs | 25 | 20 |
| `callbacks/93/args/1/position/y` | differs | -18.125 | -23.125 |
| `callbacks/93/args/2/0/position/x` | differs | 25 | 20 |
| `callbacks/93/args/2/0/position/y` | differs | -18.125 | -23.125 |
| `callbacks/95/args/0/0/position/x` | differs | 30 | 25 |
| `callbacks/95/args/0/0/position/y` | differs | -13.125 | -18.125 |
| `callbacks/96/args/1/position/x` | differs | 30 | 25 |
| `callbacks/96/args/1/position/y` | differs | -13.125 | -18.125 |
| `callbacks/96/args/2/0/position/x` | differs | 30 | 25 |
| `callbacks/96/args/2/0/position/y` | differs | -13.125 | -18.125 |
| `callbacks/98/args/0/0/position/x` | differs | 35 | 30 |
| `callbacks/98/args/0/0/position/y` | differs | -8.125 | -13.125 |
| `callbacks/99/args/1/position/x` | differs | 35 | 30 |
| `callbacks/99/args/1/position/y` | differs | -8.125 | -13.125 |
| `callbacks/99/args/2/0/position/x` | differs | 35 | 30 |
| `callbacks/99/args/2/0/position/y` | differs | -8.125 | -13.125 |
| `callbacks/101/args/0/0/position/x` | differs | 40 | 35 |
| `callbacks/101/args/0/0/position/y` | differs | -3.125 | -8.125 |
| `callbacks/102/args/1/position/x` | differs | 40 | 35 |
| `callbacks/102/args/1/position/y` | differs | -3.125 | -8.125 |
| `callbacks/102/args/2/0/position/x` | differs | 40 | 35 |
| `callbacks/102/args/2/0/position/y` | differs | -3.125 | -8.125 |
| `callbacks/104/args/0/0/position/x` | differs | 45 | 40 |
| `callbacks/104/args/0/0/position/y` | differs | 1.875 | -3.125 |
| `callbacks/105/args/1/position/x` | differs | 45 | 40 |
| `callbacks/105/args/1/position/y` | differs | 1.875 | -3.125 |
| `callbacks/105/args/2/0/position/x` | differs | 45 | 40 |
| `callbacks/105/args/2/0/position/y` | differs | 1.875 | -3.125 |
| `callbacks/106/args/0/0/dragging` | differs | false | true |

**upstream and psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — drag-node-reports-changes

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 88 unclaimed difference(s).

## Unclaimed differences

### dom (9)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(0px, 41.25px) scale(1); | transform: translate(0px, 43.125px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[0]/attrs/d` | differs | M148,23.75 C197.5,23.75 197.5,120 247,120 | M148,21.875 C197.5,21.875 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[1]/attrs/d` | differs | M148,23.75 C197.5,23.75 197.5,120 247,120 | M148,21.875 C197.5,21.875 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/circle[0]/attrs/cy` | differs | 23.75 | 21.875 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/n1/attrs/style` | differs | height: 40px; pointer-events: all; transform: translate(45px, 3.75px); visibility: visible; width: 100px; z-index: 1000; | height: 40px; pointer-events: all; transform: translate(45px, 1.875px); visibility: visible; width: 100px; z-index: 1000; |
| `dom/root/children/div[2]/children/svg[0]/attrs/viewBox` | differs | -32 -193.25 1344 1024 | -32 -195.125 1344 1024 |
| `dom/root/children/div[2]/children/svg[0]/children/rect[0]/attrs/y` | differs | 3.75 | 1.875 |
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-225.25h1408v1088h-1408z⏎        M0,-41.25h1280v720h-1280z | M-64,-227.125h1408v1088h-1408z⏎        M0,-43.125h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1/attrs/y` | differs | 1.25 | 3.125 |

### callbacks (66)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/61` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":37.5,"zoom":1}]} |
| `callbacks/70` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":39.375,"zoom":1}]} |
| `callbacks/76` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":41.25,"zoom":1}]} |
| `callbacks/82` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":43.125,"zoom":1}]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/25/args/1/y` | differs | 15 | 7.5 |
| `callbacks/31/args/1/y` | differs | 18.75 | 11.25 |
| `callbacks/37/args/1/y` | differs | 22.5 | 15 |
| `callbacks/43/args/1/y` | differs | 26.25 | 18.75 |
| `callbacks/49/args/1/y` | differs | 30 | 22.5 |
| `callbacks/55/args/1/y` | differs | 33.75 | 26.25 |
| `callbacks/57/args/0/0/position/x` | differs | 10 | 5 |
| `callbacks/57/args/0/0/position/y` | differs | -23.75 | -25 |
| `callbacks/58/args/1/position/x` | differs | 10 | 5 |
| `callbacks/58/args/1/position/y` | differs | -23.75 | -25 |
| `callbacks/58/args/2/0/position/x` | differs | 10 | 5 |
| `callbacks/58/args/2/0/position/y` | differs | -23.75 | -25 |
| `callbacks/60/args/0/y` | differs | 35.625 | 37.5 |
| `callbacks/61/args/1/y` | differs | 35.625 | 37.5 |
| `callbacks/62/args/0/0/position/y` | differs | -25.625 | -27.5 |
| `callbacks/63/args/1/position/y` | differs | -25.625 | -27.5 |
| `callbacks/63/args/2/0/position/y` | differs | -25.625 | -27.5 |
| `callbacks/64/args/1/y` | differs | 35.625 | 37.5 |
| `callbacks/65/args/0/y` | differs | 37.5 | 39.375 |
| `callbacks/66/args/1/y` | differs | 37.5 | 39.375 |
| `callbacks/67/args/0/0/position/y` | differs | -27.5 | -29.375 |
| `callbacks/68/args/1/position/y` | differs | -27.5 | -29.375 |
| `callbacks/68/args/2/0/position/y` | differs | -27.5 | -29.375 |
| `callbacks/69/args/1/y` | differs | 37.5 | 39.375 |
| `callbacks/70/args/0/y` | differs | 39.375 | 41.25 |
| `callbacks/71/args/1/y` | differs | 39.375 | 41.25 |
| `callbacks/72/args/0/0/position/y` | differs | -29.375 | -31.25 |
| `callbacks/73/args/1/position/y` | differs | -29.375 | -31.25 |
| `callbacks/73/args/2/0/position/y` | differs | -29.375 | -31.25 |
| `callbacks/74/args/1/y` | differs | 39.375 | 30 |
| `callbacks/75/args/1/y` | differs | 39.375 | 41.25 |
| `callbacks/76/args/0/y` | differs | 41.25 | 43.125 |
| `callbacks/77/args/1/y` | differs | 41.25 | 43.125 |
| `callbacks/78/args/0/0/position/y` | differs | -31.25 | -33.125 |
| `callbacks/79/args/1/position/y` | differs | -31.25 | -33.125 |
| `callbacks/79/args/2/0/position/y` | differs | -31.25 | -33.125 |
| `callbacks/80/args/1/y` | differs | 41.25 | 33.75 |
| `callbacks/82/args/0/0/position/y` | differs | -26.25 | -28.125 |
| `callbacks/83/args/1/position/y` | differs | -26.25 | -28.125 |
| `callbacks/83/args/2/0/position/y` | differs | -26.25 | -28.125 |
| `callbacks/85/args/0/0/position/y` | differs | -21.25 | -23.125 |
| `callbacks/86/args/1/position/y` | differs | -21.25 | -23.125 |
| `callbacks/86/args/2/0/position/y` | differs | -21.25 | -23.125 |
| `callbacks/88/args/0/0/position/y` | differs | -16.25 | -18.125 |
| `callbacks/89/args/1/position/y` | differs | -16.25 | -18.125 |
| `callbacks/89/args/2/0/position/y` | differs | -16.25 | -18.125 |
| `callbacks/91/args/0/0/position/y` | differs | -11.25 | -13.125 |
| `callbacks/92/args/1/position/y` | differs | -11.25 | -13.125 |
| `callbacks/92/args/2/0/position/y` | differs | -11.25 | -13.125 |
| `callbacks/94/args/0/0/position/y` | differs | -6.25 | -8.125 |
| `callbacks/95/args/1/position/y` | differs | -6.25 | -8.125 |
| `callbacks/95/args/2/0/position/y` | differs | -6.25 | -8.125 |
| `callbacks/97/args/0/0/position/y` | differs | -1.25 | -3.125 |
| `callbacks/98/args/1/position/y` | differs | -1.25 | -3.125 |
| `callbacks/98/args/2/0/position/y` | differs | -1.25 | -3.125 |
| `callbacks/100/args/0/0/position/y` | differs | 3.75 | 1.875 |
| `callbacks/101/args/1/position/y` | differs | 3.75 | 1.875 |
| `callbacks/101/args/2/0/position/y` | differs | 3.75 | 1.875 |
| `callbacks/102/args/0/0/position/y` | differs | 3.75 | 1.875 |
| `callbacks/103/args/1/position/y` | differs | 3.75 | 1.875 |
| `callbacks/103/args/2/0/position/y` | differs | 3.75 | 1.875 |

### api (13)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0/position/y` | differs | 3.75 | 1.875 |
| `api/queries/getNode/position/y` | differs | 3.75 | 1.875 |
| `api/queries/getInternalNode/position/y` | differs | 3.75 | 1.875 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 3.75 | 1.875 |
| `api/queries/getInternalNode/internals/userNode/position/y` | differs | 3.75 | 1.875 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 3.75 | 1.875 |
| `api/queries/getNodesBounds/y` | differs | 3.75 | 1.875 |
| `api/queries/getNodesBounds/height` | differs | 136.25 | 138.125 |
| `api/queries/toObject/nodes/0/position/y` | differs | 3.75 | 1.875 |
| `api/queries/toObject/viewport/y` | differs | 41.25 | 43.125 |
| `api/queries/getViewport/y` | differs | 41.25 | 43.125 |
| `api/queries/screenToFlowPosition/y` | differs | -41.25 | -43.125 |
| `api/queries/flowToScreenPosition/y` | differs | 41.25 | 43.125 |

## Normalization

28 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (22) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing

