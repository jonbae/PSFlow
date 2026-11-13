# System parity run — debt-live-expand-parent

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

# Comparison report — debt-live-expand-parent

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 25 unclaimed difference(s).

## Unclaimed differences

### dom (1)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/parent/attrs/style` | differs | background-color: rgba(80, 120, 200, 0.12); height: 220px; pointer-events: all; transform: translate(0px, 0px); visibility: visible; width: 320px; z-index: 0; | background-color: rgba(80, 120, 200, 0.12); height: 220px; pointer-events: all; transform: translate(0px, 0px); visibility: visible; width: 350px; z-index: 0; |

### callbacks (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/25/args/0/1` | right only | — | {"type":"dimensions","id":"parent","dimensions":{"width":350,"height":220},"setAttributes":true} |
| `callbacks/27/args/1/measured/width` | differs | 320 | 350 |
| `callbacks/27/args/1/width` | right only | — | 350 |
| `callbacks/27/args/1/height` | right only | — | 220 |

### api (20)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0/measured/width` | differs | 320 | 350 |
| `api/queries/getNodes/0/width` | right only | — | 350 |
| `api/queries/getNodes/0/height` | right only | — | 220 |
| `api/queries/getNode/measured/width` | differs | 320 | 350 |
| `api/queries/getNode/width` | right only | — | 350 |
| `api/queries/getNode/height` | right only | — | 220 |
| `api/queries/getInternalNode/measured/width` | differs | 320 | 350 |
| `api/queries/getInternalNode/internals/handleBounds/source/0/x` | differs | 156 | 171 |
| `api/queries/getInternalNode/internals/handleBounds/target/0/x` | differs | 156 | 171 |
| `api/queries/getInternalNode/internals/userNode/measured/width` | differs | 320 | 350 |
| `api/queries/getInternalNode/internals/userNode/width` | right only | — | 350 |
| `api/queries/getInternalNode/internals/userNode/height` | right only | — | 220 |
| `api/queries/getInternalNode/width` | right only | — | 350 |
| `api/queries/getInternalNode/height` | right only | — | 220 |
| `api/queries/getIntersectingNodes/0/measured/width` | differs | 320 | 350 |
| `api/queries/getIntersectingNodes/0/width` | right only | — | 350 |
| `api/queries/getIntersectingNodes/0/height` | right only | — | 220 |
| `api/queries/toObject/nodes/0/measured/width` | differs | 320 | 350 |
| `api/queries/toObject/nodes/0/width` | right only | — | 350 |
| `api/queries/toObject/nodes/0/height` | right only | — | 220 |

## Normalization

28 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (14) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing
