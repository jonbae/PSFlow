# System parity run — debt-focus-wrapper-scroll

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

# Comparison report — debt-focus-wrapper-scroll

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 5 unclaimed difference(s).

## Unclaimed differences

### callbacks (3)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/4` | left only | {"name":"wrapperScroll","args":[0,0]} | — |
| `callbacks/3/args/0` | differs | 0 | 520 |
| `callbacks/3/args/1` | differs | 0 | 670 |

### api (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/wrapperScroll/top` | differs | 0 | 520 |
| `api/queries/wrapperScroll/left` | differs | 0 | 670 |
