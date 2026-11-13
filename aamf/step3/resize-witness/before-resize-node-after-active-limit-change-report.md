# System parity

The dual-run net over 1 scenario(s), against vendored `@xyflow/react` 12.11.0.

Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice.

**1 of 1 scenario(s) failed.**

A failing net is the expected state while the divergence backlog is being worked: the scenarios below
are recording what the two implementations actually do, and a difference is fixed in the port or
claimed by a region — never by loosening what the net looks at.

| scenario | verdict | failure classes | differences |
|---|---|---|---|
| `resize-node-after-active-limit-change` | **failed** | unclaimed-difference | 27 |

Every trace behind this report is on disk under `parity/system/traces` — four per scenario, two sides captured
twice each. They are the artifact: re-diffing them costs seconds and no browser.

---

# System parity run — resize-node-after-active-limit-change

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

# Comparison report — resize-node-after-active-limit-change

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 27 unclaimed difference(s).

## Unclaimed differences

### dom (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/resize/attrs/style` | differs | height: 110px; pointer-events: all; transform: translate(240px, 180px); visibility: visible; width: 145px; z-index: 0; | height: 110px; pointer-events: all; transform: translate(240px, 180px); visibility: visible; width: 180px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/resize/children/div[0]/attrs/data-resize-history` | differs | [{"name":"control:start","values":{"width":120,"height":80,"x":240,"y":180}},{"name":"control:resize","values":{"width":135,"height":90,"x":240,"y":180,"direct… | [{"name":"control:start","values":{"x":240,"y":180,"width":120,"height":80}},{"name":"control:resize","values":{"x":240,"y":180,"width":135,"height":90,"direct… |

### callbacks (5)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/12` | right only | — | {"name":"onNodeMouseEnter","args":[{"@class":"SyntheticBaseEvent","_reactName":"onMouseEnter","_targetInst":{"@ref":"React fiber"},"type":"mouseenter","nativeE… |
| `callbacks/8/args/1/resizing` | left only | true | — |
| `callbacks/9/args/1/resizing` | left only | true | — |
| `callbacks/11/args/0/0/dimensions/width` | differs | 145 | 180 |
| `callbacks/12/args/0/0/dimensions/width` | differs | 145 | 180 |

### api (20)

| path | kind | upstream | psflow |
|---|---|---|---|
| `api/queries/getNodes/0/width` | differs | 145 | 180 |
| `api/queries/getNodes/0/measured/width` | differs | 145 | 180 |
| `api/queries/getNodes/0/resizing` | left only | false | — |
| `api/queries/getNode/width` | differs | 145 | 180 |
| `api/queries/getNode/measured/width` | differs | 145 | 180 |
| `api/queries/getNode/resizing` | left only | false | — |
| `api/queries/getInternalNode/width` | differs | 145 | 180 |
| `api/queries/getInternalNode/measured/width` | differs | 145 | 180 |
| `api/queries/getInternalNode/resizing` | left only | false | — |
| `api/queries/getInternalNode/internals/handleBounds/source` | differs | null | [] |
| `api/queries/getInternalNode/internals/handleBounds/target` | differs | null | [] |
| `api/queries/getInternalNode/internals/userNode/width` | differs | 145 | 180 |
| `api/queries/getInternalNode/internals/userNode/measured/width` | differs | 145 | 180 |
| `api/queries/getIntersectingNodes/0/width` | differs | 145 | 180 |
| `api/queries/getIntersectingNodes/0/measured/width` | differs | 145 | 180 |
| `api/queries/getIntersectingNodes/0/resizing` | left only | false | — |
| `api/queries/getNodesBounds/width` | differs | 145 | 180 |
| `api/queries/toObject/nodes/0/width` | differs | 145 | 180 |
| `api/queries/toObject/nodes/0/measured/width` | differs | 145 | 180 |
| `api/queries/toObject/nodes/0/resizing` | left only | false | — |

## Normalization

19 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (10) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing

