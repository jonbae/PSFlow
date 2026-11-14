# System parity run — debt-store-effect-timing

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

# Comparison report — debt-store-effect-timing

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 4 unclaimed difference(s).

## Unclaimed differences

### callbacks (4)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/0/args/0/ariaLabelConfig/controls.zoomIn.ariaLabel` | differs | Zoom In | initial zoom |
| `callbacks/5/args/0/minZoom` | differs | 0.5 | 0.2 |
| `callbacks/5/args/0/ariaLabelConfig/controls.zoomIn.ariaLabel` | differs | initial zoom | Zoom In |
| `callbacks/5/args/0/ariaLabelConfig/controls.zoomOut.ariaLabel` | differs | Zoom Out | changed zoom |
