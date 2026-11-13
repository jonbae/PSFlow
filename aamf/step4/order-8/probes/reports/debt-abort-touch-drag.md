# System parity run — debt-abort-touch-drag

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

# Comparison report — debt-abort-touch-drag

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 11 unclaimed difference(s).

## Unclaimed differences

### callbacks (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/21` | left only | {"name":"onNodesChange","args":[[{"id":"Node-1","type":"position","position":{"x":10,"y":10},"dragging":false}]]} | — |
| `callbacks/23` | left only | {"name":"onNodesChange","args":[[{"id":"Node-3","type":"position","position":{"x":100,"y":100},"dragging":false}]]} | — |

### api (9)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0/dragging` | differs | false | true |
| `api/queries/getNodes/2/dragging` | left only | false | — |
| `api/queries/getNode/dragging` | differs | false | true |
| `api/queries/getInternalNode/dragging` | differs | false | true |
| `api/queries/getInternalNode/internals/userNode/dragging` | differs | false | true |
| `api/queries/getIntersectingNodes/0/dragging` | differs | false | true |
| `api/queries/getIntersectingNodes/2/dragging` | left only | false | — |
| `api/queries/toObject/nodes/0/dragging` | differs | false | true |
| `api/queries/toObject/nodes/2/dragging` | left only | false | — |

## Normalization

14 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (8) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing
