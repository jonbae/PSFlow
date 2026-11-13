# System parity run — debt-detached-handle

**Failed:** unclaimed-difference.

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`. All seven remain captured in the trace.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. In a plain run the driving log
takes part with no tolerance applied. Probe variants compare only their declared observation level, so
probe-induced rendering and pointer-resolution changes cannot contaminate that experiment.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — debt-detached-handle

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 15 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]` | left only | {"tag":"svg","attrs":{"style":"z-index: 0;"},"children":[{"tag":"g","attrs":{"class":"nopan react-flow__edge react-flow__edge-default selectable","tabindex":"0… | — |

### callbacks (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/9` | left only | {"name":"onConnectStart","args":[{"@class":"MouseEvent","isTrusted":true},{"nodeId":"source","handleId":"out","handleType":"source"}]} | — |
| `callbacks/14` | left only | {"name":"isValidConnection","args":[{"source":"source","sourceHandle":"out","target":"target","targetHandle":"in"}]} | — |
| `callbacks/15` | left only | {"name":"onConnect","args":[{"source":"source","sourceHandle":"out","target":"target","targetHandle":"in"}]} | — |
| `callbacks/16` | left only | {"name":"onConnectEnd","args":[{"@class":"MouseEvent","isTrusted":true},{"isValid":true,"from":{"x":260,"y":160},"fromHandle":{"id":"out","type":"source","node… | — |

### api (10)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getEdges/0` | left only | {"source":"source","sourceHandle":"out","target":"target","targetHandle":"in","id":"xy-edge__sourceout-targetin"} | — |
| `api/queries/getEdge/source` | left only | source | — |
| `api/queries/getEdge/sourceHandle` | left only | out | — |
| `api/queries/getEdge/target` | left only | target | — |
| `api/queries/getEdge/targetHandle` | left only | in | — |
| `api/queries/getEdge/id` | left only | xy-edge__sourceout-targetin | — |
| `api/queries/getEdge/@undefined` | right only | — | true |
| `api/queries/getHandleConnections/0` | left only | {"edgeId":"xy-edge__sourceout-targetin","source":"source","target":"target","sourceHandle":"out","targetHandle":"in"} | — |
| `api/queries/getNodeConnections/0` | left only | {"edgeId":"xy-edge__sourceout-targetin","source":"source","target":"target","sourceHandle":"out","targetHandle":"in"} | — |
| `api/queries/toObject/edges/0` | left only | {"source":"source","sourceHandle":"out","target":"target","targetHandle":"in","id":"xy-edge__sourceout-targetin"} | — |

## Normalization

20 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (11) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing
