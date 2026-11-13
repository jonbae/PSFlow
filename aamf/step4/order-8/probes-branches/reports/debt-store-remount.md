# System parity run — debt-store-remount

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

# Comparison report — debt-store-remount

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 20 unclaimed difference(s).

## Unclaimed differences

### callbacks (20)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/18/args/0/nodes/0` | left only | Node-1 | — |
| `callbacks/18/args/0/nodes/1` | left only | Node-2 | — |
| `callbacks/18/args/0/nodes/2` | left only | Node-3 | — |
| `callbacks/18/args/0/nodes/3` | left only | Node-4 | — |
| `callbacks/18/args/0/lookupSize` | differs | 4 | 0 |
| `callbacks/19/args/0/nodes/0` | left only | Node-1 | — |
| `callbacks/19/args/0/nodes/1` | left only | Node-2 | — |
| `callbacks/19/args/0/nodes/2` | left only | Node-3 | — |
| `callbacks/19/args/0/nodes/3` | left only | Node-4 | — |
| `callbacks/19/args/0/lookupSize` | differs | 4 | 0 |
| `callbacks/20/args/0/nodes/0` | left only | Node-1 | — |
| `callbacks/20/args/0/nodes/1` | left only | Node-2 | — |
| `callbacks/20/args/0/nodes/2` | left only | Node-3 | — |
| `callbacks/20/args/0/nodes/3` | left only | Node-4 | — |
| `callbacks/20/args/0/lookupSize` | differs | 4 | 0 |
| `callbacks/21/args/0/nodes/0` | left only | Node-1 | — |
| `callbacks/21/args/0/nodes/1` | left only | Node-2 | — |
| `callbacks/21/args/0/nodes/2` | left only | Node-3 | — |
| `callbacks/21/args/0/nodes/3` | left only | Node-4 | — |
| `callbacks/21/args/0/lookupSize` | differs | 4 | 0 |
