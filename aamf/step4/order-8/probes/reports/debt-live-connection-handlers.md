# System parity run — debt-live-connection-handlers

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

# Comparison report — debt-live-connection-handlers

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 16 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]` | right only | — | {"tag":"svg","attrs":{"style":"z-index: 0;"},"children":[{"tag":"g","attrs":{"class":"nopan react-flow__edge react-flow__edge-default selectable","tabindex":"0… |

### callbacks (5)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/13` | left only | {"name":"currentIsValidConnection","args":[false]} | — |
| `callbacks/14` | left only | {"name":"currentOnConnectEnd","args":[false,{"@class":"MouseEvent","isTrusted":true},{"isValid":false,"from":{"x":260,"y":160},"fromHandle":{"id":"out","type":… | — |
| `callbacks/13` | right only | — | {"name":"isValidConnection","args":[{"source":"source","target":"target","sourceHandle":"out","targetHandle":"in"}]} |
| `callbacks/14` | right only | — | {"name":"onConnect","args":[{"source":"source","target":"target","sourceHandle":"out","targetHandle":"in"}]} |
| `callbacks/15` | right only | — | {"name":"onConnectEnd","args":[{"@class":"MouseEvent","isTrusted":true},{"isValid":true,"from":{"x":260,"y":160},"fromHandle":{"id":"out","nodeId":"source","x"… |

### api (10)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getEdges/0` | right only | — | {"source":"source","target":"target","sourceHandle":"out","targetHandle":"in","id":"xy-edge__sourceout-targetin"} |
| `api/queries/getEdge/@undefined` | left only | true | — |
| `api/queries/getEdge/source` | right only | — | source |
| `api/queries/getEdge/target` | right only | — | target |
| `api/queries/getEdge/sourceHandle` | right only | — | out |
| `api/queries/getEdge/targetHandle` | right only | — | in |
| `api/queries/getEdge/id` | right only | — | xy-edge__sourceout-targetin |
| `api/queries/getHandleConnections/0` | right only | — | {"edgeId":"xy-edge__sourceout-targetin","source":"source","target":"target","sourceHandle":"out","targetHandle":"in"} |
| `api/queries/getNodeConnections/0` | right only | — | {"edgeId":"xy-edge__sourceout-targetin","source":"source","target":"target","sourceHandle":"out","targetHandle":"in"} |
| `api/queries/toObject/edges/0` | right only | — | {"source":"source","target":"target","sourceHandle":"out","targetHandle":"in","id":"xy-edge__sourceout-targetin"} |

## Normalization

18 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (9) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing
