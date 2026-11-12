# System parity

The dual-run net over 1 scenario(s), against vendored `@xyflow/react` 12.11.0.

Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice.

**1 of 1 scenario(s) failed.**

A failing net is the expected state while the divergence backlog is being worked: the scenarios below
are recording what the two implementations actually do, and a difference is fixed in the port or
claimed by a region — never by loosening what the net looks at.

| scenario | verdict | failure classes | differences |
|---|---|---|---|
| `drag-node-reports-changes` | **failed** | self-inconsistent, unclaimed-difference | 307 |

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
| upstream | 1, 2 | **disagrees with itself** | 135 |
| psflow | 1, 2 | **disagrees with itself** | 75 |

### upstream disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(0px, 41.25px) scale(1); | transform: translate(0px, 13.125px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[0]/attrs/d` | differs | M148,23.75 C197.5,23.75 197.5,120 247,120 | M148,51.875 C197.5,51.875 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[1]/attrs/d` | differs | M148,23.75 C197.5,23.75 197.5,120 247,120 | M148,51.875 C197.5,51.875 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/circle[0]/attrs/cy` | differs | 23.75 | 51.875 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/n1/attrs/style` | differs | height: 40px; pointer-events: all; transform: translate(45px, 3.75px); visibility: visible; width: 100px; z-index: 1000; | height: 40px; pointer-events: all; transform: translate(45px, 31.875px); visibility: visible; width: 100px; z-index: 1000; |
| `dom/root/children/div[2]/children/svg[0]/attrs/viewBox` | differs | -32 -193.25 1344 1024 | -32 -165.125 1344 1024 |
| `dom/root/children/div[2]/children/svg[0]/children/rect[0]/attrs/y` | differs | 3.75 | 31.875 |
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-225.25h1408v1088h-1408z⏎        M0,-41.25h1280v720h-1280z | M-64,-197.125h1408v1088h-1408z⏎        M0,-13.125h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1/attrs/y` | differs | 1.25 | 13.125 |
| `callbacks/25` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":15,"zoom":1}]} | — |
| `callbacks/26` | left only | {"name":"onViewportChange","args":[{"x":0,"y":18.75,"zoom":1}]} | — |
| `callbacks/27` | left only | {"name":"onMove","args":[null,{"x":0,"y":18.75,"zoom":1}]} | — |
| `callbacks/30` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":18.75,"zoom":1}]} | — |
| `callbacks/31` | left only | {"name":"onViewportChange","args":[{"x":0,"y":22.5,"zoom":1}]} | — |
| `callbacks/32` | left only | {"name":"onMove","args":[null,{"x":0,"y":22.5,"zoom":1}]} | — |
| `callbacks/36` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":22.5,"zoom":1}]} | — |
| `callbacks/37` | left only | {"name":"onViewportChange","args":[{"x":0,"y":26.25,"zoom":1}]} | — |
| `callbacks/38` | left only | {"name":"onMove","args":[null,{"x":0,"y":26.25,"zoom":1}]} | — |
| `callbacks/42` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":26.25,"zoom":1}]} | — |
| `callbacks/43` | left only | {"name":"onViewportChange","args":[{"x":0,"y":30,"zoom":1}]} | — |
| `callbacks/44` | left only | {"name":"onMove","args":[null,{"x":0,"y":30,"zoom":1}]} | — |
| `callbacks/47` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":30,"zoom":1}]} | — |
| `callbacks/48` | left only | {"name":"onViewportChange","args":[{"x":0,"y":33.75,"zoom":1}]} | — |
| `callbacks/49` | left only | {"name":"onMove","args":[null,{"x":0,"y":33.75,"zoom":1}]} | — |
| `callbacks/52` | left only | {"name":"onMoveEnd","args":[null,{"x":0,"y":33.75,"zoom":1}]} | — |
| `callbacks/56` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":33.75,"zoom":1}]} | — |
| `callbacks/57` | left only | {"name":"onViewportChange","args":[{"x":0,"y":35.625,"zoom":1}]} | — |
| `callbacks/58` | left only | {"name":"onMove","args":[null,{"x":0,"y":35.625,"zoom":1}]} | — |
| `callbacks/61` | left only | {"name":"onMoveEnd","args":[null,{"x":0,"y":35.625,"zoom":1}]} | — |
| `callbacks/62` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":35.625,"zoom":1}]} | — |
| `callbacks/63` | left only | {"name":"onViewportChange","args":[{"x":0,"y":37.5,"zoom":1}]} | — |
| `callbacks/64` | left only | {"name":"onMove","args":[null,{"x":0,"y":37.5,"zoom":1}]} | — |
| `callbacks/67` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":37.5,"zoom":1}]} | — |
| `callbacks/68` | left only | {"name":"onViewportChange","args":[{"x":0,"y":39.375,"zoom":1}]} | — |
| `callbacks/69` | left only | {"name":"onMove","args":[null,{"x":0,"y":39.375,"zoom":1}]} | — |
| `callbacks/71` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":10,"y":-29.375},"sourcePosition":"right"… | — |
| `callbacks/72` | left only | {"name":"onMoveEnd","args":[null,{"x":0,"y":39.375,"zoom":1}]} | — |
| `callbacks/73` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":39.375,"zoom":1}]} | — |
| `callbacks/74` | left only | {"name":"onViewportChange","args":[{"x":0,"y":41.25,"zoom":1}]} | — |
| `callbacks/75` | left only | {"name":"onMove","args":[null,{"x":0,"y":41.25,"zoom":1}]} | — |
| `callbacks/76` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":10,"y":-31.25},"dragging":true}]]} | — |
| `callbacks/77` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":10,"y":-31.25},"sourcePosition":"right",… | — |
| `callbacks/78` | left only | {"name":"onMoveEnd","args":[null,{"x":0,"y":41.25,"zoom":1}]} | — |
| `callbacks/80` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":15,"y":-26.25},"dragging":true}]]} | — |
| `callbacks/81` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":15,"y":-26.25},"sourcePosition":"right",… | — |
| `callbacks/83` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":20,"y":-21.25},"dragging":true}]]} | — |
| `callbacks/84` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":20,"y":-21.25},"sourcePosition":"right",… | — |
| `callbacks/86` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":25,"y":-16.25},"dragging":true}]]} | — |
| `callbacks/87` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":25,"y":-16.25},"sourcePosition":"right",… | — |
| `callbacks/89` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":30,"y":-11.25},"dragging":true}]]} | — |
| `callbacks/90` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":30,"y":-11.25},"sourcePosition":"right",… | — |
| `callbacks/92` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":35,"y":-6.25},"dragging":true}]]} | — |
| `callbacks/93` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":35,"y":-6.25},"sourcePosition":"right","… | — |
| `callbacks/95` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":40,"y":-1.25},"dragging":true}]]} | — |
| `callbacks/96` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":40,"y":-1.25},"sourcePosition":"right","… | — |
| `callbacks/98` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":45,"y":3.75},"dragging":true}]]} | — |
| `callbacks/99` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","data":{"label":"n1"},"position":{"x":45,"y":3.75},"sourcePosition":"right","t… | — |
| `callbacks/100` | left only | {"name":"onNodesChange","args":[[{"id":"n1","type":"position","position":{"x":45,"y":3.75},"dragging":false}]]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/21/args/0/y` | differs | 15 | 13.125 |
| `callbacks/22/args/1/y` | differs | 15 | 13.125 |
| `callbacks/23/args/0/0/position/x` | differs | 5 | 10 |
| `callbacks/23/args/0/0/position/y` | differs | -2.5 | -1.25 |
| `callbacks/24/args/1/position/x` | differs | 5 | 10 |
| `callbacks/24/args/1/position/y` | differs | -2.5 | -1.25 |
| `callbacks/24/args/2/0/position/x` | differs | 5 | 10 |
| `callbacks/24/args/2/0/position/y` | differs | -2.5 | -1.25 |
| `callbacks/28/args/0/0/position/x` | differs | 5 | 10 |
| `callbacks/28/args/0/0/position/y` | differs | -6.25 | -3.125 |
| `callbacks/29/args/1/position/x` | differs | 5 | 10 |
| `callbacks/29/args/1/position/y` | differs | -6.25 | -3.125 |
| `callbacks/29/args/2/0/position/x` | differs | 5 | 10 |
| `callbacks/29/args/2/0/position/y` | differs | -6.25 | -3.125 |
| `callbacks/33/args/0/0/position/x` | differs | 5 | 15 |
| `callbacks/33/args/0/0/position/y` | differs | -10 | 1.875 |
| `callbacks/34/args/1/position/x` | differs | 5 | 15 |
| `callbacks/34/args/1/position/y` | differs | -10 | 1.875 |
| `callbacks/34/args/2/0/position/x` | differs | 5 | 15 |
| `callbacks/34/args/2/0/position/y` | differs | -10 | 1.875 |
| `callbacks/35/args/1/y` | differs | 22.5 | 11.25 |
| `callbacks/39/args/0/0/position/x` | differs | 5 | 20 |
| `callbacks/39/args/0/0/position/y` | differs | -13.75 | 6.875 |
| `callbacks/40/args/1/position/x` | differs | 5 | 20 |
| `callbacks/40/args/1/position/y` | differs | -13.75 | 6.875 |
| `callbacks/40/args/2/0/position/x` | differs | 5 | 20 |
| `callbacks/40/args/2/0/position/y` | differs | -13.75 | 6.875 |
| `callbacks/41/args/1/y` | differs | 26.25 | 13.125 |
| `callbacks/45/args/0/0/position/x` | differs | 5 | 25 |
| `callbacks/45/args/0/0/position/y` | differs | -17.5 | 11.875 |
| `callbacks/46/args/1/position/x` | differs | 5 | 25 |
| `callbacks/46/args/1/position/y` | differs | -17.5 | 11.875 |
| `callbacks/46/args/2/0/position/x` | differs | 5 | 25 |
| `callbacks/46/args/2/0/position/y` | differs | -17.5 | 11.875 |
| `callbacks/50/args/0/0/position/x` | differs | 5 | 30 |
| `callbacks/50/args/0/0/position/y` | differs | -21.25 | 16.875 |
| `callbacks/51/args/1/position/x` | differs | 5 | 30 |
| `callbacks/51/args/1/position/y` | differs | -21.25 | 16.875 |
| `callbacks/51/args/2/0/position/x` | differs | 5 | 30 |
| `callbacks/51/args/2/0/position/y` | differs | -21.25 | 16.875 |
| `callbacks/54/args/0/0/position/x` | differs | 10 | 35 |
| `callbacks/54/args/0/0/position/y` | differs | -23.75 | 21.875 |
| `callbacks/55/args/1/position/x` | differs | 10 | 35 |
| `callbacks/55/args/1/position/y` | differs | -23.75 | 21.875 |
| `callbacks/55/args/2/0/position/x` | differs | 10 | 35 |
| `callbacks/55/args/2/0/position/y` | differs | -23.75 | 21.875 |
| `callbacks/59/args/0/0/position/x` | differs | 10 | 40 |
| `callbacks/59/args/0/0/position/y` | differs | -25.625 | 26.875 |
| `callbacks/60/args/1/position/x` | differs | 10 | 40 |
| `callbacks/60/args/1/position/y` | differs | -25.625 | 26.875 |
| `callbacks/60/args/2/0/position/x` | differs | 10 | 40 |
| `callbacks/60/args/2/0/position/y` | differs | -25.625 | 26.875 |
| `callbacks/65/args/0/0/position/x` | differs | 10 | 45 |
| `callbacks/65/args/0/0/position/y` | differs | -27.5 | 31.875 |
| `callbacks/66/args/1/position/x` | differs | 10 | 45 |
| `callbacks/66/args/1/position/y` | differs | -27.5 | 31.875 |
| `callbacks/66/args/2/0/position/x` | differs | 10 | 45 |
| `callbacks/66/args/2/0/position/y` | differs | -27.5 | 31.875 |
| `callbacks/70/args/0/0/position/x` | differs | 10 | 45 |
| `callbacks/70/args/0/0/position/y` | differs | -29.375 | 31.875 |
| `callbacks/70/args/0/0/dragging` | differs | true | false |
| `callbacks/101/args/1/position/y` | differs | 3.75 | 31.875 |
| `callbacks/101/args/2/0/position/y` | differs | 3.75 | 31.875 |
| `api/queries/getNodes/0/position/y` | differs | 3.75 | 31.875 |
| `api/queries/getNode/position/y` | differs | 3.75 | 31.875 |
| `api/queries/getInternalNode/position/y` | differs | 3.75 | 31.875 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 3.75 | 31.875 |
| `api/queries/getInternalNode/internals/userNode/position/y` | differs | 3.75 | 31.875 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 3.75 | 31.875 |
| `api/queries/getNodesBounds/y` | differs | 3.75 | 31.875 |
| `api/queries/getNodesBounds/height` | differs | 136.25 | 108.125 |
| `api/queries/toObject/nodes/0/position/y` | differs | 3.75 | 31.875 |
| `api/queries/toObject/viewport/y` | differs | 41.25 | 13.125 |
| `api/queries/getViewport/y` | differs | 41.25 | 13.125 |
| `api/queries/screenToFlowPosition/y` | differs | -41.25 | -13.125 |
| `api/queries/flowToScreenPosition/y` | differs | 41.25 | 13.125 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/attrs/style` | differs | transform: translate(0px, 41.25px) scale(1); | transform: translate(0px, 39.375px) scale(1); |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[0]/attrs/d` | differs | M148,23.75 C197.5,23.75 197.5,120 247,120 | M148,25.625 C197.5,25.625 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/path[1]/attrs/d` | differs | M148,23.75 C197.5,23.75 197.5,120 247,120 | M148,25.625 C197.5,25.625 197.5,120 247,120 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/e1-2/children/circle[0]/attrs/cy` | differs | 23.75 | 25.625 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/n1/attrs/style` | differs | height: 40px; pointer-events: all; transform: translate(45px, 3.75px); visibility: visible; width: 100px; z-index: 1000; | height: 40px; pointer-events: all; transform: translate(45px, 5.625px); visibility: visible; width: 100px; z-index: 1000; |
| `dom/root/children/div[2]/children/svg[0]/attrs/viewBox` | differs | -32 -193.25 1344 1024 | -32 -191.375 1344 1024 |
| `dom/root/children/div[2]/children/svg[0]/children/rect[0]/attrs/y` | differs | 3.75 | 5.625 |
| `dom/root/children/div[2]/children/svg[0]/children/path[0]/attrs/d` | differs | M-64,-225.25h1408v1088h-1408z⏎        M0,-41.25h1280v720h-1280z | M-64,-223.375h1408v1088h-1408z⏎        M0,-39.375h1280v720h-1280z |
| `dom/root/children/svg[0]/children/pattern-1/attrs/y` | differs | 1.25 | 19.375 |
| `callbacks/85` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":39.375,"zoom":1}]} | — |
| `callbacks/86` | left only | {"name":"onViewportChange","args":[{"x":0,"y":41.25,"zoom":1}]} | — |
| `callbacks/87` | left only | {"name":"onMove","args":[null,{"x":0,"y":41.25,"zoom":1}]} | — |
| `callbacks/88` | left only | {"name":"onMoveEnd","args":[null,{"x":0,"y":41.25,"zoom":1}]} | — |
| `callbacks/111` | left only | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","position":{"x":45,"y":3.75},"data":{"label":"n1"},"sourcePosition":"right","t… | — |
| `callbacks/112` | left only | {"name":"onNodesChange","args":[[{"type":"position","id":"n1","position":{"x":45,"y":3.75},"dragging":false}]]} | — |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/89/args/0/0/position/x` | differs | 10 | 15 |
| `callbacks/89/args/0/0/position/y` | differs | -31.25 | -24.375 |
| `callbacks/90/args/1/position/x` | differs | 10 | 15 |
| `callbacks/90/args/1/position/y` | differs | -31.25 | -24.375 |
| `callbacks/90/args/2/0/position/x` | differs | 10 | 15 |
| `callbacks/90/args/2/0/position/y` | differs | -31.25 | -24.375 |
| `callbacks/92/args/0/0/position/x` | differs | 15 | 20 |
| `callbacks/92/args/0/0/position/y` | differs | -26.25 | -19.375 |
| `callbacks/93/args/1/position/x` | differs | 15 | 20 |
| `callbacks/93/args/1/position/y` | differs | -26.25 | -19.375 |
| `callbacks/93/args/2/0/position/x` | differs | 15 | 20 |
| `callbacks/93/args/2/0/position/y` | differs | -26.25 | -19.375 |
| `callbacks/95/args/0/0/position/x` | differs | 20 | 25 |
| `callbacks/95/args/0/0/position/y` | differs | -21.25 | -14.375 |
| `callbacks/96/args/1/position/x` | differs | 20 | 25 |
| `callbacks/96/args/1/position/y` | differs | -21.25 | -14.375 |
| `callbacks/96/args/2/0/position/x` | differs | 20 | 25 |
| `callbacks/96/args/2/0/position/y` | differs | -21.25 | -14.375 |
| `callbacks/98/args/0/0/position/x` | differs | 25 | 30 |
| `callbacks/98/args/0/0/position/y` | differs | -16.25 | -9.375 |
| `callbacks/99/args/1/position/x` | differs | 25 | 30 |
| `callbacks/99/args/1/position/y` | differs | -16.25 | -9.375 |
| `callbacks/99/args/2/0/position/x` | differs | 25 | 30 |
| `callbacks/99/args/2/0/position/y` | differs | -16.25 | -9.375 |
| `callbacks/101/args/0/0/position/x` | differs | 30 | 35 |
| `callbacks/101/args/0/0/position/y` | differs | -11.25 | -4.375 |
| `callbacks/102/args/1/position/x` | differs | 30 | 35 |
| `callbacks/102/args/1/position/y` | differs | -11.25 | -4.375 |
| `callbacks/102/args/2/0/position/x` | differs | 30 | 35 |
| `callbacks/102/args/2/0/position/y` | differs | -11.25 | -4.375 |
| `callbacks/104/args/0/0/position/x` | differs | 35 | 40 |
| `callbacks/104/args/0/0/position/y` | differs | -6.25 | 0.625 |
| `callbacks/105/args/1/position/x` | differs | 35 | 40 |
| `callbacks/105/args/1/position/y` | differs | -6.25 | 0.625 |
| `callbacks/105/args/2/0/position/x` | differs | 35 | 40 |
| `callbacks/105/args/2/0/position/y` | differs | -6.25 | 0.625 |
| `callbacks/107/args/0/0/position/x` | differs | 40 | 45 |
| `callbacks/107/args/0/0/position/y` | differs | -1.25 | 5.625 |
| `callbacks/108/args/1/position/x` | differs | 40 | 45 |
| `callbacks/108/args/1/position/y` | differs | -1.25 | 5.625 |
| `callbacks/108/args/2/0/position/x` | differs | 40 | 45 |
| `callbacks/108/args/2/0/position/y` | differs | -1.25 | 5.625 |
| `callbacks/110/args/0/0/position/y` | differs | 3.75 | 5.625 |
| `callbacks/110/args/0/0/dragging` | differs | true | false |
| `callbacks/113/args/1/position/y` | differs | 3.75 | 5.625 |
| `callbacks/113/args/2/0/position/y` | differs | 3.75 | 5.625 |
| `api/queries/getNodes/0/position/y` | differs | 3.75 | 5.625 |
| `api/queries/getNode/position/y` | differs | 3.75 | 5.625 |
| `api/queries/getInternalNode/position/y` | differs | 3.75 | 5.625 |
| `api/queries/getInternalNode/internals/positionAbsolute/y` | differs | 3.75 | 5.625 |
| `api/queries/getInternalNode/internals/userNode/position/y` | differs | 3.75 | 5.625 |
| `api/queries/getIntersectingNodes/0/position/y` | differs | 3.75 | 5.625 |
| `api/queries/getNodesBounds/y` | differs | 3.75 | 5.625 |
| `api/queries/getNodesBounds/height` | differs | 136.25 | 134.375 |
| `api/queries/toObject/nodes/0/position/y` | differs | 3.75 | 5.625 |
| `api/queries/toObject/viewport/y` | differs | 41.25 | 39.375 |
| `api/queries/getViewport/y` | differs | 41.25 | 39.375 |
| `api/queries/screenToFlowPosition/y` | differs | -41.25 | -39.375 |
| `api/queries/flowToScreenPosition/y` | differs | 41.25 | 39.375 |

**upstream and psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — drag-node-reports-changes

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 97 unclaimed difference(s).

## Unclaimed differences

### callbacks (97)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/49` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":30,"zoom":1}]} |
| `callbacks/58` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":31.875,"zoom":1}]} |
| `callbacks/64` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":33.75,"zoom":1}]} |
| `callbacks/70` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":35.625,"zoom":1}]} |
| `callbacks/76` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":37.5,"zoom":1}]} |
| `callbacks/82` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":39.375,"zoom":1}]} |
| `callbacks/85` | right only | — | {"name":"onMoveStart","args":[null,{"x":0,"y":39.375,"zoom":1}]} |
| `callbacks/86` | right only | — | {"name":"onViewportChange","args":[{"x":0,"y":41.25,"zoom":1}]} |
| `callbacks/87` | right only | — | {"name":"onMove","args":[null,{"x":0,"y":41.25,"zoom":1}]} |
| `callbacks/88` | right only | — | {"name":"onMoveEnd","args":[null,{"x":0,"y":41.25,"zoom":1}]} |
| `callbacks/111` | right only | — | {"name":"onNodeDrag","args":[{"@class":"MouseEvent","isTrusted":true},{"id":"n1","position":{"x":45,"y":3.75},"data":{"label":"n1"},"sourcePosition":"right","t… |
| `callbacks/112` | right only | — | {"name":"onNodesChange","args":[[{"type":"position","id":"n1","position":{"x":45,"y":3.75},"dragging":false}]]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… | ["onSelectionChange#1","onPaneMouseEnter#1","onNodeMouseEnter#1","onPaneMouseMove#1","onNodeMouseMove#1","onPaneMouseMove#2","onNodesChange#1","onNodeDragStart… |
| `callbacks/35/args/1/y` | differs | 22.5 | 7.5 |
| `callbacks/41/args/1/y` | differs | 26.25 | 11.25 |
| `callbacks/48/args/0/y` | differs | 33.75 | 31.875 |
| `callbacks/49/args/1/y` | differs | 33.75 | 31.875 |
| `callbacks/50/args/0/0/position/x` | differs | 5 | 10 |
| `callbacks/50/args/0/0/position/y` | differs | -21.25 | -20 |
| `callbacks/51/args/1/position/x` | differs | 5 | 10 |
| `callbacks/51/args/1/position/y` | differs | -21.25 | -20 |
| `callbacks/51/args/2/0/position/x` | differs | 5 | 10 |
| `callbacks/51/args/2/0/position/y` | differs | -21.25 | -20 |
| `callbacks/52/args/1/y` | differs | 33.75 | 15 |
| `callbacks/54/args/0/0/position/y` | differs | -23.75 | -21.875 |
| `callbacks/55/args/1/position/y` | differs | -23.75 | -21.875 |
| `callbacks/55/args/2/0/position/y` | differs | -23.75 | -21.875 |
| `callbacks/56/args/1/y` | differs | 33.75 | 31.875 |
| `callbacks/57/args/0/y` | differs | 35.625 | 33.75 |
| `callbacks/58/args/1/y` | differs | 35.625 | 33.75 |
| `callbacks/59/args/0/0/position/y` | differs | -25.625 | -23.75 |
| `callbacks/60/args/1/position/y` | differs | -25.625 | -23.75 |
| `callbacks/60/args/2/0/position/y` | differs | -25.625 | -23.75 |
| `callbacks/61/args/1/y` | differs | 35.625 | 18.75 |
| `callbacks/62/args/1/y` | differs | 35.625 | 33.75 |
| `callbacks/63/args/0/y` | differs | 37.5 | 35.625 |
| `callbacks/64/args/1/y` | differs | 37.5 | 35.625 |
| `callbacks/65/args/0/0/position/y` | differs | -27.5 | -25.625 |
| `callbacks/66/args/1/position/y` | differs | -27.5 | -25.625 |
| `callbacks/66/args/2/0/position/y` | differs | -27.5 | -25.625 |
| `callbacks/67/args/1/y` | differs | 37.5 | 35.625 |
| `callbacks/68/args/0/y` | differs | 39.375 | 37.5 |
| `callbacks/69/args/1/y` | differs | 39.375 | 37.5 |
| `callbacks/70/args/0/0/position/y` | differs | -29.375 | -27.5 |
| `callbacks/71/args/1/position/y` | differs | -29.375 | -27.5 |
| `callbacks/71/args/2/0/position/y` | differs | -29.375 | -27.5 |
| `callbacks/72/args/1/y` | differs | 39.375 | 22.5 |
| `callbacks/73/args/1/y` | differs | 39.375 | 37.5 |
| `callbacks/74/args/0/y` | differs | 41.25 | 39.375 |
| `callbacks/75/args/1/y` | differs | 41.25 | 39.375 |
| `callbacks/76/args/0/0/position/y` | differs | -31.25 | -29.375 |
| `callbacks/77/args/1/position/y` | differs | -31.25 | -29.375 |
| `callbacks/77/args/2/0/position/y` | differs | -31.25 | -29.375 |
| `callbacks/78/args/1/y` | differs | 41.25 | 26.25 |
| `callbacks/80/args/0/0/position/x` | differs | 15 | 10 |
| `callbacks/80/args/0/0/position/y` | differs | -26.25 | -31.25 |
| `callbacks/81/args/1/position/x` | differs | 15 | 10 |
| `callbacks/81/args/1/position/y` | differs | -26.25 | -31.25 |
| `callbacks/81/args/2/0/position/x` | differs | 15 | 10 |
| `callbacks/81/args/2/0/position/y` | differs | -26.25 | -31.25 |
| `callbacks/83/args/0/0/position/x` | differs | 20 | 15 |
| `callbacks/83/args/0/0/position/y` | differs | -21.25 | -26.25 |
| `callbacks/84/args/1/position/x` | differs | 20 | 15 |
| `callbacks/84/args/1/position/y` | differs | -21.25 | -26.25 |
| `callbacks/84/args/2/0/position/x` | differs | 20 | 15 |
| `callbacks/84/args/2/0/position/y` | differs | -21.25 | -26.25 |
| `callbacks/86/args/0/0/position/x` | differs | 25 | 20 |
| `callbacks/86/args/0/0/position/y` | differs | -16.25 | -21.25 |
| `callbacks/87/args/1/position/x` | differs | 25 | 20 |
| `callbacks/87/args/1/position/y` | differs | -16.25 | -21.25 |
| `callbacks/87/args/2/0/position/x` | differs | 25 | 20 |
| `callbacks/87/args/2/0/position/y` | differs | -16.25 | -21.25 |
| `callbacks/89/args/0/0/position/x` | differs | 30 | 25 |
| `callbacks/89/args/0/0/position/y` | differs | -11.25 | -16.25 |
| `callbacks/90/args/1/position/x` | differs | 30 | 25 |
| `callbacks/90/args/1/position/y` | differs | -11.25 | -16.25 |
| `callbacks/90/args/2/0/position/x` | differs | 30 | 25 |
| `callbacks/90/args/2/0/position/y` | differs | -11.25 | -16.25 |
| `callbacks/92/args/0/0/position/x` | differs | 35 | 30 |
| `callbacks/92/args/0/0/position/y` | differs | -6.25 | -11.25 |
| `callbacks/93/args/1/position/x` | differs | 35 | 30 |
| `callbacks/93/args/1/position/y` | differs | -6.25 | -11.25 |
| `callbacks/93/args/2/0/position/x` | differs | 35 | 30 |
| `callbacks/93/args/2/0/position/y` | differs | -6.25 | -11.25 |
| `callbacks/95/args/0/0/position/x` | differs | 40 | 35 |
| `callbacks/95/args/0/0/position/y` | differs | -1.25 | -6.25 |
| `callbacks/96/args/1/position/x` | differs | 40 | 35 |
| `callbacks/96/args/1/position/y` | differs | -1.25 | -6.25 |
| `callbacks/96/args/2/0/position/x` | differs | 40 | 35 |
| `callbacks/96/args/2/0/position/y` | differs | -1.25 | -6.25 |
| `callbacks/98/args/0/0/position/x` | differs | 45 | 40 |
| `callbacks/98/args/0/0/position/y` | differs | 3.75 | -1.25 |
| `callbacks/99/args/1/position/x` | differs | 45 | 40 |
| `callbacks/99/args/1/position/y` | differs | 3.75 | -1.25 |
| `callbacks/99/args/2/0/position/x` | differs | 45 | 40 |
| `callbacks/99/args/2/0/position/y` | differs | 3.75 | -1.25 |
| `callbacks/100/args/0/0/dragging` | differs | false | true |

## Normalization

28 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (19) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing

