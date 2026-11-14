# System parity run — debt-minimap-missing-node

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — debt-minimap-missing-node

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 60 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root` | differs | {"tag":"div","attrs":{"data-testid":"rf__wrapper","class":"light react-flow","role":"application","style":"height: 100%; overflow: hidden; position: relative; … | null |

### callbacks (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/7` | right only | — | {"name":"onError","args":["004","The React Flow parent container needs a width and a height to render the graph."]} |

### api (54)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |
| `api/queries/getNodes/1` | left only | {"id":"Node-2","data":{"label":"Node-2"},"position":{"x":-100,"y":100},"type":"output","measured":{"width":150,"height":37}} | — |
| `api/queries/getNodes/2` | left only | {"id":"Node-3","data":{"label":"Node-3"},"position":{"x":100,"y":100},"measured":{"width":150,"height":37}} | — |
| `api/queries/getNodes/3` | left only | {"id":"Node-4","data":{"label":"Node-4"},"position":{"x":0,"y":200},"type":"output","measured":{"width":150,"height":37}} | — |
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
| `api/queries/getEdges/0` | left only | {"id":"1-2","type":"default","source":"Node-1","target":"Node-2","label":"edge"} | — |
| `api/queries/getEdges/1` | left only | {"id":"1-3","type":"default","source":"Node-1","target":"Node-3","label":"edge"} | — |
| `api/queries/getEdge/id` | left only | 1-2 | — |
| `api/queries/getEdge/type` | left only | default | — |
| `api/queries/getEdge/source` | left only | Node-1 | — |
| `api/queries/getEdge/target` | left only | Node-2 | — |
| `api/queries/getEdge/label` | left only | edge | — |
| `api/queries/getEdge/@undefined` | right only | — | true |
| `api/queries/getIntersectingNodes/0` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |
| `api/queries/getIntersectingNodes/1` | left only | {"id":"Node-2","data":{"label":"Node-2"},"position":{"x":-100,"y":100},"type":"output","measured":{"width":150,"height":37}} | — |
| `api/queries/getIntersectingNodes/2` | left only | {"id":"Node-3","data":{"label":"Node-3"},"position":{"x":100,"y":100},"measured":{"width":150,"height":37}} | — |
| `api/queries/getIntersectingNodes/3` | left only | {"id":"Node-4","data":{"label":"Node-4"},"position":{"x":0,"y":200},"type":"output","measured":{"width":150,"height":37}} | — |
| `api/queries/isNodeIntersecting` | differs | true | false |
| `api/queries/getNodesBounds/x` | differs | -100 | 0 |
| `api/queries/getNodesBounds/width` | differs | 350 | 0 |
| `api/queries/getNodesBounds/height` | differs | 237 | 0 |
| `api/queries/getHandleConnections/0` | left only | {"edgeId":"1-2","source":"Node-1","target":"Node-2","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/getHandleConnections/1` | left only | {"edgeId":"1-3","source":"Node-1","target":"Node-3","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/getNodeConnections/0` | left only | {"edgeId":"1-2","source":"Node-1","target":"Node-2","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/getNodeConnections/1` | left only | {"edgeId":"1-3","source":"Node-1","target":"Node-3","sourceHandle":null,"targetHandle":null} | — |
| `api/queries/toObject/nodes/0` | left only | {"id":"Node-1","data":{"label":"Node-1"},"position":{"x":0,"y":0},"type":"input","measured":{"width":150,"height":37}} | — |
| `api/queries/toObject/nodes/1` | left only | {"id":"Node-2","data":{"label":"Node-2"},"position":{"x":-100,"y":100},"type":"output","measured":{"width":150,"height":37}} | — |
| `api/queries/toObject/nodes/2` | left only | {"id":"Node-3","data":{"label":"Node-3"},"position":{"x":100,"y":100},"measured":{"width":150,"height":37}} | — |
| `api/queries/toObject/nodes/3` | left only | {"id":"Node-4","data":{"label":"Node-4"},"position":{"x":0,"y":200},"type":"output","measured":{"width":150,"height":37}} | — |
| `api/queries/toObject/edges/0` | left only | {"id":"1-2","type":"default","source":"Node-1","target":"Node-2","label":"edge"} | — |
| `api/queries/toObject/edges/1` | left only | {"id":"1-3","type":"default","source":"Node-1","target":"Node-3","label":"edge"} | — |
| `api/queries/toObject/viewport/x` | differs | 490 | 0 |
| `api/queries/toObject/viewport/y` | differs | 123 | 0 |
| `api/queries/toObject/viewport/zoom` | differs | 2 | 1 |
| `api/queries/getZoom` | differs | 2 | 1 |
| `api/queries/getViewport/x` | differs | 490 | 0 |
| `api/queries/getViewport/y` | differs | 123 | 0 |
| `api/queries/getViewport/zoom` | differs | 2 | 1 |
| `api/queries/screenToFlowPosition/x` | differs | -245 | 0 |
| `api/queries/screenToFlowPosition/y` | differs | -61.5 | 0 |
| `api/queries/flowToScreenPosition/x` | differs | 490 | 0 |
| `api/queries/flowToScreenPosition/y` | differs | 123 | 0 |

### console (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `console/1` | right only | — | {"level":"pageerror","text":"Failed pattern match at Data.Maybe (line 288, column 1 - line 288, column 46): Nothing2"} |
| `console/2` | right only | — | {"level":"pageerror","text":"Failed pattern match at Data.Maybe (line 288, column 1 - line 288, column 46): Nothing2"} |
| `console/3` | right only | — | {"level":"error","text":"The above error occurred in the <MiniMapNodes> component:\n\n    at http://127.0.0.1:34559/parity/driver/dist/psflow.js:32889:61\n    … |
| `console/4` | right only | — | {"level":"pageerror","text":"Failed pattern match at Data.Maybe (line 288, column 1 - line 288, column 46): Nothing2"} |
