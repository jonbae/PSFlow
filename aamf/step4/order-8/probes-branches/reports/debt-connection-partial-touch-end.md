# System parity run — debt-connection-partial-touch-end

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

# Comparison report — debt-connection-partial-touch-end

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

Compared sections: `driving`, `dom`, `callbacks`, `hooks`, `api`, `props`, `console`.

**Failed:** 8 unclaimed difference(s).

## Unclaimed differences

### dom (6)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/svg[0]` | left only | {"tag":"svg","attrs":{"width":"1280","height":"720","class":"react-flow__connectionline react-flow__container"},"children":[{"tag":"g","attrs":{"class":"react-… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/source/children/div[0]/children/1-source-in-target/attrs/class` | differs | connectable connectableend connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target | connectable connectableend nodrag nopan react-flow__handle react-flow__handle-top target |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/source/children/div[0]/children/1-source-out-source/attrs/class` | differs | connectable connectableend connectablestart connectingfrom nodrag nopan react-flow__handle react-flow__handle-bottom source | connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/target/children/div[0]/children/1-target-in-target/attrs/class` | differs | connectable connectableend connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target | connectable connectableend nodrag nopan react-flow__handle react-flow__handle-top target |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/target/children/div[0]/children/1-target-out-source/attrs/class` | differs | connectable connectableend connectablestart nodrag nopan react-flow__handle react-flow__handle-bottom source | connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source |
| `dom/root/children/output[0]/attrs/data-connection-state` | differs | {"inProgress":true,"from":{"x":260,"y":160},"to":{"x":290,"y":200},"pointer":{"x":290,"y":200},"fromId":"source"} | {"inProgress":false,"from":null,"to":null,"pointer":null} |

### callbacks (2)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/10` | right only | — | {"name":"onConnectEnd","args":[{"@class":"TouchEvent","isTrusted":true},{"isValid":null,"from":{"x":260,"y":160},"fromHandle":{"id":"out","nodeId":"source","x"… |
| `callbacks/12` | right only | — | {"name":"onMoveStart","args":[null,{"x":0,"y":0,"zoom":1}]} |

## Normalization

14 field(s) deleted by name and therefore **unobserved** — not passing:

- `callbacks/**/timeStamp` (8) — a DOM event's timeStamp is a clock reading — milliseconds since its document was created — so it differs between a side's own two captures of one scenario. Self-consistency is the one comparison no region and no weakening may claim, and there is nothing for either to say about a clock: neither implementation computes this number, the browser stamps it. Measured rather than assumed — with the pointer parked, upstream's whole drag reproduces itself exactly once this field is gone. Deleting is what the noise policy has for it, and a deleted field is unobserved rather than passing
