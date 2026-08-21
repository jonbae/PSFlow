# System parity

The dual-run net over 5 scenario(s), against vendored `@xyflow/react` 12.11.0.

Captured by this run: both sides mounted the same unmodified fixtures through the same driver, bundled twice.

**5 of 5 scenario(s) failed.**

A failing net is the expected state while the divergence backlog is being worked: the scenarios below
are recording what the two implementations actually do, and a difference is fixed in the port or
claimed by a region — never by loosening what the net looks at.

| scenario | verdict | failure classes | differences |
|---|---|---|---|
| `mount-baseline--edges-general` | **failed** | unclaimed-difference | 321 |
| `mount-baseline--node-toolbar-general` | **failed** | unclaimed-difference | 237 |
| `mount-baseline--nodes-general` | **failed** | unclaimed-difference | 147 |
| `mount-baseline--pane-general` | **failed** | unclaimed-difference | 66 |
| `mount-baseline--pane-non-defaults` | **failed** | self-inconsistent, unclaimed-difference | 50 |

Every trace behind this report is on disk under `parity/system/traces` — four per scenario, two sides captured
twice each. They are the artifact: re-diffing them costs seconds and no browser.

---

# System parity run — mount-baseline--edges-general

**Failed:** unclaimed-difference.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. The driving log takes part with
no tolerance applied — it never reaches the normalizer at all — so a side whose resolved boxes wobble
between its own captures fails against itself.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--edges-general

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

**Failed:** 321 unclaimed difference(s).

## Unclaimed differences

### dom (178)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/edge-with-class/attrs/aria-label` | left only | Edge from 1 to 2 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/edge-with-class/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/edge-with-class/children/path[0]/attrs/d` | differs | M75,39 C75,68 -25,68 -25,97 | M75.00001857790781,38.99999653044963 C75.00001857790781,67.99999672609705 -24.99998142209219,67.99999672609705 -24.99998142209219,96.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/edge-with-class/children/path[1]/attrs/d` | differs | M75,39 C75,68 -25,68 -25,97 | M75.00001857790781,38.99999653044963 C75.00001857790781,67.99999672609705 -24.99998142209219,67.99999672609705 -24.99998142209219,96.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/edge-with-class/children/circle[0]/attrs/cx` | differs | 75 | 75.00001857790781 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/edge-with-class/children/circle[0]/attrs/cy` | differs | 49 | 48.99999653044963 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/edge-with-class/children/circle[1]/attrs/cx` | differs | -25 | -24.99998142209219 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/edge-with-class/children/circle[1]/attrs/cy` | differs | 87 | 86.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[2]/children/edge-with-style/attrs/aria-label` | left only | Edge from 1 to 3 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[2]/children/edge-with-style/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[2]/children/edge-with-style/children/path[0]/attrs/d` | differs | M75,39 C75,68 175,68 175,97 | M75.00001857790781,38.99999653044963 C75.00001857790781,67.99999672609705 174.99995344894003,67.99999672609705 174.99995344894003,96.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[2]/children/edge-with-style/children/path[1]/attrs/d` | differs | M75,39 C75,68 175,68 175,97 | M75.00001857790781,38.99999653044963 C75.00001857790781,67.99999672609705 174.99995344894003,67.99999672609705 174.99995344894003,96.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[2]/children/edge-with-style/children/circle[0]/attrs/cx` | differs | 75 | 75.00001857790781 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[2]/children/edge-with-style/children/circle[0]/attrs/cy` | differs | 49 | 48.99999653044963 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[2]/children/edge-with-style/children/circle[1]/attrs/cx` | differs | 175 | 174.99995344894003 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[2]/children/edge-with-style/children/circle[1]/attrs/cy` | differs | 87 | 86.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[3]/children/animated-edge/attrs/aria-label` | left only | Edge from 3 to 5 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[3]/children/animated-edge/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[3]/children/animated-edge/children/path[0]/attrs/d` | differs | M175,139 C175,168 175,168 175,197 | M174.99995344894003,138.99999653044964 C174.99995344894003,167.99999672609704 174.99995344894003,167.99999672609704 174.99995344894003,196.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[3]/children/animated-edge/children/path[1]/attrs/d` | differs | M175,139 C175,168 175,168 175,197 | M174.99995344894003,138.99999653044964 C174.99995344894003,167.99999672609704 174.99995344894003,167.99999672609704 174.99995344894003,196.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[3]/children/animated-edge/children/g[0]/attrs/transform` | differs | translate(156.6763515472412 162.66463375091553) | translate(156.67630499618124 162.66463047701257) |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[3]/children/animated-edge/children/circle[0]/attrs/cx` | differs | 175 | 174.99995344894003 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[3]/children/animated-edge/children/circle[0]/attrs/cy` | differs | 149 | 148.99999653044964 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[3]/children/animated-edge/children/circle[1]/attrs/cx` | differs | 175 | 174.99995344894003 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[3]/children/animated-edge/children/circle[1]/attrs/cy` | differs | 187 | 186.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[4]/children/not-selectable-edge/attrs/aria-label` | left only | Edge from 4 to 6 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[4]/children/not-selectable-edge/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[4]/children/not-selectable-edge/children/path[0]/attrs/d` | differs | M-25,239 C-25,268 -25,268 -25,297 | M-24.99998142209219,238.99998838932865 C-24.99998142209219,267.9999926555366 -24.99998142209219,267.9999926555366 -24.99998142209219,296.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[4]/children/not-selectable-edge/children/path[1]/attrs/d` | differs | M-25,239 C-25,268 -25,268 -25,297 | M-24.99998142209219,238.99998838932865 C-24.99998142209219,267.9999926555366 -24.99998142209219,267.9999926555366 -24.99998142209219,296.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[4]/children/not-selectable-edge/children/g[0]/attrs/transform` | differs | translate(-52.760576248168945 262.6646337509155) | translate(-52.760557670261136 262.6646264064521) |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[4]/children/not-selectable-edge/children/circle[0]/attrs/cx` | differs | -25 | -24.99998142209219 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[4]/children/not-selectable-edge/children/circle[0]/attrs/cy` | differs | 249 | 248.99998838932865 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[4]/children/not-selectable-edge/children/circle[1]/attrs/cx` | differs | -25 | -24.99998142209219 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[4]/children/not-selectable-edge/children/circle[1]/attrs/cy` | differs | 287 | 286.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[5]/children/not-deletable/attrs/aria-label` | left only | Edge from 5 to 7 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[5]/children/not-deletable/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[5]/children/not-deletable/children/path[0]/attrs/d` | differs | M175,239 C175,268 175,268 175,297 | M174.99995344894003,238.99998838932865 C174.99995344894003,267.9999926555366 174.99995344894003,267.9999926555366 174.99995344894003,296.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[5]/children/not-deletable/children/path[1]/attrs/d` | differs | M175,239 C175,268 175,268 175,297 | M174.99995344894003,238.99998838932865 C174.99995344894003,267.9999926555366 174.99995344894003,267.9999926555366 174.99995344894003,296.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[5]/children/not-deletable/children/g[0]/attrs/transform` | differs | translate(148.89838790893555 262.6646337509155) | translate(148.89834135787558 262.6646264064521) |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[5]/children/not-deletable/children/circle[0]/attrs/cx` | differs | 175 | 174.99995344894003 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[5]/children/not-deletable/children/circle[0]/attrs/cy` | differs | 249 | 248.99998838932865 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[5]/children/not-deletable/children/circle[1]/attrs/cx` | differs | 175 | 174.99995344894003 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[5]/children/not-deletable/children/circle[1]/attrs/cy` | differs | 287 | 286.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[6]/children/z-index/attrs/aria-label` | left only | Edge from 6 to 8 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[6]/children/z-index/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[6]/children/z-index/children/path[0]/attrs/d` | differs | M-25,339 C-25,368 -25,368 -25,397 | M-24.99998142209219,338.9999883893287 C-24.99998142209219,367.9999926555366 -24.99998142209219,367.9999926555366 -24.99998142209219,396.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[6]/children/z-index/children/path[1]/attrs/d` | differs | M-25,339 C-25,368 -25,368 -25,397 | M-24.99998142209219,338.9999883893287 C-24.99998142209219,367.9999926555366 -24.99998142209219,367.9999926555366 -24.99998142209219,396.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[6]/children/z-index/children/g[0]/attrs/transform` | differs | translate(-39.99738025665283 362.6646337509155) | translate(-39.99736167874502 362.66462640645204) |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[6]/children/z-index/children/circle[0]/attrs/cx` | differs | -25 | -24.99998142209219 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[6]/children/z-index/children/circle[0]/attrs/cy` | differs | 349 | 348.9999883893287 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[6]/children/z-index/children/circle[1]/attrs/cx` | differs | -25 | -24.99998142209219 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[6]/children/z-index/children/circle[1]/attrs/cy` | differs | 387 | 386.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[7]/children/aria-label/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[7]/children/aria-label/children/path[0]/attrs/d` | differs | M175,339 C175,368 175,368 175,397 | M174.99995344894003,338.9999883893287 C174.99995344894003,367.9999926555366 174.99995344894003,367.9999926555366 174.99995344894003,396.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[7]/children/aria-label/children/path[1]/attrs/d` | differs | M175,339 C175,368 175,368 175,397 | M174.99995344894003,338.9999883893287 C174.99995344894003,367.9999926555366 174.99995344894003,367.9999926555366 174.99995344894003,396.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[7]/children/aria-label/children/g[0]/attrs/transform` | differs | translate(156.12614250183105 362.6646337509155) | translate(156.1260959507711 362.66462640645204) |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[7]/children/aria-label/children/circle[0]/attrs/cx` | differs | 175 | 174.99995344894003 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[7]/children/aria-label/children/circle[0]/attrs/cy` | differs | 349 | 348.9999883893287 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[7]/children/aria-label/children/circle[1]/attrs/cx` | differs | 175 | 174.99995344894003 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[7]/children/aria-label/children/circle[1]/attrs/cy` | differs | 387 | 386.99999692174447 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[8]/children/interaction-width/attrs/aria-label` | left only | Edge from 8 to 10 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[8]/children/interaction-width/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[8]/children/interaction-width/children/path[0]/attrs/d` | differs | M-25,439 C-25,468 -25,468 -25,497 | M-24.99998142209219,438.9999883893287 C-24.99998142209219,468.0000089377785 -24.99998142209219,468.0000089377785 -24.99998142209219,497.00002948622836 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[8]/children/interaction-width/children/path[1]/attrs/d` | differs | M-25,439 C-25,468 -25,468 -25,497 | M-24.99998142209219,438.9999883893287 C-24.99998142209219,468.0000089377785 -24.99998142209219,468.0000089377785 -24.99998142209219,497.00002948622836 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[8]/children/interaction-width/children/g[0]/attrs/transform` | differs | translate(-59.42978286743164 462.6646337509155) | translate(-59.42976428952383 462.664642688694) |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[8]/children/interaction-width/children/circle[0]/attrs/cx` | differs | -25 | -24.99998142209219 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[8]/children/interaction-width/children/circle[0]/attrs/cy` | differs | 449 | 448.9999883893287 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[8]/children/interaction-width/children/circle[1]/attrs/cx` | differs | -25 | -24.99998142209219 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[8]/children/interaction-width/children/circle[1]/attrs/cy` | differs | 487 | 487.00002948622836 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[9]/children/markers/attrs/aria-label` | left only | Edge from 9 to 11 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[9]/children/markers/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[9]/children/markers/children/path[0]/attrs/d` | differs | M175,439 C175,468 175,468 175,497 | M174.99995344894003,438.9999883893287 C174.99995344894003,468.0000089377785 174.99995344894003,468.0000089377785 174.99995344894003,497.00002948622836 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[9]/children/markers/children/path[1]/attrs/d` | differs | M175,439 C175,468 175,468 175,497 | M174.99995344894003,438.9999883893287 C174.99995344894003,468.0000089377785 174.99995344894003,468.0000089377785 174.99995344894003,497.00002948622836 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[9]/children/markers/children/g[0]/attrs/transform` | differs | translate(158.89386367797852 462.6646337509155) | translate(158.89381712691855 462.664642688694) |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[9]/children/markers/children/circle[0]/attrs/cx` | differs | 175 | 174.99995344894003 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[9]/children/markers/children/circle[0]/attrs/cy` | differs | 449 | 448.9999883893287 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[9]/children/markers/children/circle[1]/attrs/cx` | differs | 175 | 174.99995344894003 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[9]/children/markers/children/circle[1]/attrs/cy` | differs | 487 | 487.00002948622836 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[10]/children/subflow-edge/attrs/aria-label` | left only | Edge from 11 to 12-a | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[10]/children/subflow-edge/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[10]/children/subflow-edge/children/path[0]/attrs/d` | differs | M175,539 C175,578 135,578 135,617 | M174.99995344894003,539.0000209538125 C174.99995344894003,578.0000252200205 134.99998898330483,578.0000252200205 134.99998898330483,617.0000294862283 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[10]/children/subflow-edge/children/path[1]/attrs/d` | differs | M175,539 C175,578 135,578 135,617 | M174.99995344894003,539.0000209538125 C174.99995344894003,578.0000252200205 134.99998898330483,578.0000252200205 134.99998898330483,617.0000294862283 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[10]/children/subflow-edge/children/circle[0]/attrs/cx` | differs | 175 | 174.99995344894003 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[10]/children/subflow-edge/children/circle[0]/attrs/cy` | differs | 549 | 549.0000209538125 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[10]/children/subflow-edge/children/circle[1]/attrs/cx` | differs | 135 | 134.99998898330483 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[10]/children/subflow-edge/children/circle[1]/attrs/cy` | differs | 607 | 607.0000294862283 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[11]/children/subflow-edge-2/attrs/aria-label` | left only | Edge from 12-a to 12-b | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[11]/children/subflow-edge-2/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[11]/children/subflow-edge-2/children/path[0]/attrs/d` | differs | M135,673 C135,719.7707173346743 265,570.2292826653257 265,617 | M134.99998898330483,673.0000136093491 C134.99998898330483,719.7707243139066 265.0000541122726,570.2293187816708 265.0000541122726,617.0000294862283 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[11]/children/subflow-edge-2/children/path[1]/attrs/d` | differs | M135,673 C135,719.7707173346743 265,570.2292826653257 265,617 | M134.99998898330483,673.0000136093491 C134.99998898330483,719.7707243139066 265.0000541122726,570.2293187816708 265.0000541122726,617.0000294862283 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[11]/children/subflow-edge-2/children/circle[0]/attrs/cx` | differs | 135 | 134.99998898330483 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[11]/children/subflow-edge-2/children/circle[0]/attrs/cy` | differs | 683 | 683.0000136093491 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[11]/children/subflow-edge-2/children/circle[1]/attrs/cx` | differs | 265 | 265.0000541122726 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[11]/children/subflow-edge-2/children/circle[1]/attrs/cy` | differs | 607 | 607.0000294862283 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children` | ordered differently | ["1","2","3","4","5","6","7","8","9","10","11","12","12-a","12-b"] | ["1","10","11","12","12-a","12-b","2","3","4","5","6","7","8","9"] |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/attrs/style` | differs | pointer-events: all; transform: translate(0px, 0px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, 0px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/children/1-1-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"1","data-handlepos":"bottom","data-id":"1-1-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/children/1-1--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/attrs/style` | differs | pointer-events: all; transform: translate(-100px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(-100px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"2","data-handlepos":"top","data-id":"1-2-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"2","data-handlepos":"bottom","data-id":"1-2-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/attrs/style` | differs | pointer-events: all; transform: translate(100px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(100px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"3","data-handlepos":"top","data-id":"1-3-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"3","data-handlepos":"bottom","data-id":"1-3-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/4/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/4/attrs/style` | differs | pointer-events: all; transform: translate(-100px, 200px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(-100px, 200px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/4/children/1-4-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"4","data-handlepos":"top","data-id":"1-4-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/4/children/1-4-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"4","data-handlepos":"bottom","data-id":"1-4-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/4/children/1-4--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/4/children/1-4--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/5/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/5/attrs/style` | differs | pointer-events: all; transform: translate(100px, 200px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(100px, 200px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/5/children/1-5-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"5","data-handlepos":"top","data-id":"1-5-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/5/children/1-5-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"5","data-handlepos":"bottom","data-id":"1-5-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/5/children/1-5--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/5/children/1-5--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/6/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/6/attrs/style` | differs | pointer-events: all; transform: translate(-100px, 300px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(-100px, 300px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/6/children/1-6-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"6","data-handlepos":"top","data-id":"1-6-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/6/children/1-6-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"6","data-handlepos":"bottom","data-id":"1-6-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/6/children/1-6--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/6/children/1-6--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/7/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/7/attrs/style` | differs | pointer-events: all; transform: translate(100px, 300px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(100px, 300px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/7/children/1-7-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"7","data-handlepos":"top","data-id":"1-7-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/7/children/1-7-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"7","data-handlepos":"bottom","data-id":"1-7-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/7/children/1-7--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/7/children/1-7--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/8/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/8/attrs/style` | differs | pointer-events: all; transform: translate(-100px, 400px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(-100px, 400px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/8/children/1-8-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"8","data-handlepos":"top","data-id":"1-8-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/8/children/1-8-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"8","data-handlepos":"bottom","data-id":"1-8-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/8/children/1-8--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/8/children/1-8--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/9/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/9/attrs/style` | differs | pointer-events: all; transform: translate(100px, 400px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(100px, 400px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/9/children/1-9-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"9","data-handlepos":"top","data-id":"1-9-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/9/children/1-9-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"9","data-handlepos":"bottom","data-id":"1-9-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/9/children/1-9--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/9/children/1-9--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/10/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/10/attrs/style` | differs | pointer-events: all; transform: translate(-100px, 500px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(-100px, 500px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/10/children/1-10-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"10","data-handlepos":"top","data-id":"1-10-null-target","class":"connectable connectableend connectablestart connectionind… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/10/children/1-10-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"10","data-handlepos":"bottom","data-id":"1-10-null-source","class":"connectable connectableend connectablestart connection… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/10/children/1-10--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/10/children/1-10--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/11/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/11/attrs/style` | differs | pointer-events: all; transform: translate(100px, 500px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(100px, 500px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/11/children/1-11-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"11","data-handlepos":"top","data-id":"1-11-null-target","class":"connectable connectableend connectablestart connectionind… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/11/children/1-11-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"11","data-handlepos":"bottom","data-id":"1-11-null-source","class":"connectable connectableend connectablestart connection… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/11/children/1-11--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/11/children/1-11--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12/children/1-12-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"12","data-handlepos":"top","data-id":"1-12-null-target","class":"connectable connectableend connectablestart connectionind… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12/children/1-12-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"12","data-handlepos":"bottom","data-id":"1-12-null-source","class":"connectable connectableend connectablestart connection… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12/children/1-12--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12/children/1-12--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12-a/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12-a/children/1-12-a-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"12-a","data-handlepos":"top","data-id":"1-12-a-null-target","class":"connectable connectableend connectablestart connectio… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12-a/children/1-12-a-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"12-a","data-handlepos":"bottom","data-id":"1-12-a-null-source","class":"connectable connectableend connectablestart connec… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12-a/children/1-12-a--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12-a/children/1-12-a--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12-b/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12-b/children/1-12-b-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"12-b","data-handlepos":"top","data-id":"1-12-b-null-target","class":"connectable connectableend connectablestart connectio… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12-b/children/1-12-b-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"12-b","data-handlepos":"bottom","data-id":"1-12-b-null-source","class":"connectable connectableend connectablestart connec… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12-b/children/1-12-b--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/12-b/children/1-12-b--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[1]/attrs/data-message` | left only | Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev | — |
| `dom/root/children/div[1]/children/a[0]` | left only | {"tag":"a","attrs":{"href":"https://reactflow.dev","target":"_blank","rel":"noopener noreferrer","aria-label":"React Flow attribution"},"text":"React Flow","ch… | — |
| `dom/root/children/div[1]/children/span[0]` | right only | — | {"tag":"span","attrs":{"data-message":"Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev"},"children":[{"t… |
| `dom/root/children/react-flow__node-desc-1/text` | differs | Press enter or space to select a node. You can then use the arrow keys to move the node around. Press delete to remove it and escape to cancel. | Press enter or space to select a node. Press delete to remove it and escape to cancel. |

### callbacks (143)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/1` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":0,"zoom":1}]} | — |
| `callbacks/3` | left only | {"name":"onMove","args":[null,{"x":546.2857142857142,"y":32,"zoom":0.9371428571428572}]} | — |
| `callbacks/4` | right only | — | {"name":"onSelectionChange","args":[{"nodes":[],"edges":[]}]} |
| `callbacks/5` | right only | — | {"name":"onViewportChange","args":[{"x":546.2857142857142,"y":32,"zoom":0.9371428571428572}]} |
| `callbacks/6` | right only | — | {"name":"onMoveEnd","args":[null,{"x":546.2857142857142,"y":32,"zoom":0.9371428571428572}]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onViewportChange#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onNodesChange#1","onViewportChange#1","onMoveEnd#1"] |
| `callbacks/4/args/0/0/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/resizing` | right only | — | false |
| `callbacks/4/args/0/0/setAttributes` | right only | — | true |
| `callbacks/4/args/0/1/id` | differs | 2 | 10 |
| `callbacks/4/args/0/1/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/resizing` | right only | — | false |
| `callbacks/4/args/0/1/setAttributes` | right only | — | true |
| `callbacks/4/args/0/2/id` | differs | 3 | 11 |
| `callbacks/4/args/0/2/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/resizing` | right only | — | false |
| `callbacks/4/args/0/2/setAttributes` | right only | — | true |
| `callbacks/4/args/0/3/id` | differs | 4 | 12 |
| `callbacks/4/args/0/3/dimensions/width` | differs | 150 | 200 |
| `callbacks/4/args/0/3/dimensions/height` | differs | 36 | 100 |
| `callbacks/4/args/0/3/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/resizing` | right only | — | false |
| `callbacks/4/args/0/3/setAttributes` | right only | — | true |
| `callbacks/4/args/0/4/id` | differs | 5 | 12-a |
| `callbacks/4/args/0/4/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/4/dimensions/height` | differs | 36 | 50 |
| `callbacks/4/args/0/4/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/resizing` | right only | — | false |
| `callbacks/4/args/0/4/setAttributes` | right only | — | true |
| `callbacks/4/args/0/5/id` | differs | 6 | 12-b |
| `callbacks/4/args/0/5/dimensions/width` | differs | 150 | 50 |
| `callbacks/4/args/0/5/dimensions/height` | differs | 36 | 50 |
| `callbacks/4/args/0/5/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/resizing` | right only | — | false |
| `callbacks/4/args/0/5/setAttributes` | right only | — | true |
| `callbacks/4/args/0/6/id` | differs | 7 | 2 |
| `callbacks/4/args/0/6/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/resizing` | right only | — | false |
| `callbacks/4/args/0/6/setAttributes` | right only | — | true |
| `callbacks/4/args/0/7/id` | differs | 8 | 3 |
| `callbacks/4/args/0/7/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/resizing` | right only | — | false |
| `callbacks/4/args/0/7/setAttributes` | right only | — | true |
| `callbacks/4/args/0/8/id` | differs | 9 | 4 |
| `callbacks/4/args/0/8/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/resizing` | right only | — | false |
| `callbacks/4/args/0/8/setAttributes` | right only | — | true |
| `callbacks/4/args/0/9/id` | differs | 10 | 5 |
| `callbacks/4/args/0/9/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/resizing` | right only | — | false |
| `callbacks/4/args/0/9/setAttributes` | right only | — | true |
| `callbacks/4/args/0/10/id` | differs | 11 | 6 |
| `callbacks/4/args/0/10/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/resizing` | right only | — | false |
| `callbacks/4/args/0/10/setAttributes` | right only | — | true |
| `callbacks/4/args/0/11/id` | differs | 12 | 7 |
| `callbacks/4/args/0/11/dimensions/width` | differs | 200 | 150 |
| `callbacks/4/args/0/11/dimensions/height` | differs | 100 | 36 |
| `callbacks/4/args/0/11/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/resizing` | right only | — | false |
| `callbacks/4/args/0/11/setAttributes` | right only | — | true |
| `callbacks/4/args/0/12/id` | differs | 12-a | 8 |
| `callbacks/4/args/0/12/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/12/dimensions/height` | differs | 50 | 36 |
| `callbacks/4/args/0/12/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/resizing` | right only | — | false |
| `callbacks/4/args/0/12/setAttributes` | right only | — | true |
| `callbacks/4/args/0/13/id` | differs | 12-b | 9 |
| `callbacks/4/args/0/13/dimensions/width` | differs | 50 | 150 |
| `callbacks/4/args/0/13/dimensions/height` | differs | 50 | 36 |
| `callbacks/4/args/0/13/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/13/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/13/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/13/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/13/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/13/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/13/resizing` | right only | — | false |
| `callbacks/4/args/0/13/setAttributes` | right only | — | true |


---

# System parity run — mount-baseline--node-toolbar-general

**Failed:** unclaimed-difference.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. The driving log takes part with
no tolerance applied — it never reaches the normalizer at all — so a side whose resolved boxes wobble
between its own captures fails against itself.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--node-toolbar-general

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

**Failed:** 237 unclaimed difference(s).

## Unclaimed differences

### dom (115)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/node-center-bottom` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-center-bottom","style":"position: absolute; transform: translate(806.286px, 500.811px)… |
| `dom/root/children/node-center-left` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-center-left","style":"position: absolute; transform: translate(1045.71px, 470.857px) t… |
| `dom/root/children/node-center-right` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-center-right","style":"position: absolute; transform: translate(566.857px, 470.857px) … |
| `dom/root/children/node-center-top` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-center-top","style":"position: absolute; transform: translate(141.143px, 440.903px) tr… |
| `dom/root/children/node-end-bottom` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-end-bottom","style":"position: absolute; transform: translate(889.429px, 611.669px) tr… |
| `dom/root/children/node-end-left` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-end-left","style":"position: absolute; transform: translate(1045.71px, 601.669px) tran… |
| `dom/root/children/node-end-right` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-end-right","style":"position: absolute; transform: translate(566.857px, 601.669px) tra… |
| `dom/root/children/node-end-top` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-end-top","style":"position: absolute; transform: translate(224.286px, 551.76px) transl… |
| `dom/root/children/node-start-bottom` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-start-bottom","style":"position: absolute; transform: translate(723.143px, 389.954px) … |
| `dom/root/children/node-start-left` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-start-left","style":"position: absolute; transform: translate(1045.71px, 340.046px) tr… |
| `dom/root/children/node-start-right` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-start-right","style":"position: absolute; transform: translate(566.857px, 340.046px) t… |
| `dom/root/children/node-start-top` | right only | — | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-start-top","style":"position: absolute; transform: translate(58px, 330.046px) translat… |
| `dom/root/children/div[0]/children/node-start-top` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-start-top","style":"position: absolute; transform: translate(58px, 330.046px) translat… | — |
| `dom/root/children/div[0]/children/node-center-top` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-center-top","style":"position: absolute; transform: translate(141.143px, 440.903px) tr… | — |
| `dom/root/children/div[0]/children/node-end-top` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-end-top","style":"position: absolute; transform: translate(224.286px, 551.76px) transl… | — |
| `dom/root/children/div[0]/children/node-start-right` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-start-right","style":"position: absolute; transform: translate(566.857px, 340.046px) t… | — |
| `dom/root/children/div[0]/children/node-center-right` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-center-right","style":"position: absolute; transform: translate(566.857px, 470.857px) … | — |
| `dom/root/children/div[0]/children/node-end-right` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-end-right","style":"position: absolute; transform: translate(566.857px, 601.669px) tra… | — |
| `dom/root/children/div[0]/children/node-start-bottom` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-start-bottom","style":"position: absolute; transform: translate(723.143px, 389.954px) … | — |
| `dom/root/children/div[0]/children/node-center-bottom` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-center-bottom","style":"position: absolute; transform: translate(806.286px, 500.811px)… | — |
| `dom/root/children/div[0]/children/node-end-bottom` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-end-bottom","style":"position: absolute; transform: translate(889.429px, 611.669px) tr… | — |
| `dom/root/children/div[0]/children/node-start-left` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-start-left","style":"position: absolute; transform: translate(1045.71px, 340.046px) tr… | — |
| `dom/root/children/div[0]/children/node-center-left` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-center-left","style":"position: absolute; transform: translate(1045.71px, 470.857px) t… | — |
| `dom/root/children/div[0]/children/node-end-left` | left only | {"tag":"div","attrs":{"class":"react-flow__node-toolbar","data-id":"node-end-left","style":"position: absolute; transform: translate(1045.71px, 601.669px) tran… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/attrs/aria-label` | left only | Edge from default-node to node-start-top | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/path[0]/attrs/d` | differs | M153,-182 C231.06247497997998,-182 -81.06247497997998,18 -3,18 | M153.00018842898396,-181.99997810471064 C231.0627114818381,-181.99997810471064 -81.06252676153119,18.000008130900056 -3.0000037086770566,18.000008130900056 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/path[1]/attrs/d` | differs | M153,-182 C231.06247497997998,-182 -81.06247497997998,18 -3,18 | M153.00018842898396,-181.99997810471064 C231.0627114818381,-181.99997810471064 -81.06252676153119,18.000008130900056 -3.0000037086770566,18.000008130900056 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/circle[0]/attrs/cx` | differs | 163 | 163.00018842898396 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/circle[0]/attrs/cy` | differs | -182 | -181.99997810471064 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/circle[1]/attrs/cx` | differs | -13 | -13.000003708677056 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/circle[1]/attrs/cy` | differs | 18 | 18.000008130900056 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children` | ordered differently | ["default-node","node-start-top","node-center-top","node-end-top","node-start-right","node-center-right","node-end-right","node-start-bottom","node-center-bott… | ["default-node","node-center-bottom","node-center-left","node-center-right","node-center-top","node-end-bottom","node-end-left","node-end-right","node-end-top"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/default-node/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/default-node/attrs/style` | differs | pointer-events: all; transform: translate(0px, -200px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, -200px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/default-node/children/1-default-node-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"default-node","data-handlepos":"left","data-id":"1-default-node-null-target","class":"connectable connectableend connectab… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/default-node/children/1-default-node-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"default-node","data-handlepos":"right","data-id":"1-default-node-null-source","class":"connectable connectableend connecta… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/default-node/children/1-default-node--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/default-node/children/1-default-node--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-top/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-top/attrs/style` | differs | pointer-events: all; transform: translate(0px, 0px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, 0px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-top/children/1-node-start-top-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-start-top","data-handlepos":"left","data-id":"1-node-start-top-null-target","class":"connectable connectableend conne… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-top/children/1-node-start-top-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-start-top","data-handlepos":"right","data-id":"1-node-start-top-null-source","class":"connectable connectableend conn… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-top/children/1-node-start-top--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-top/children/1-node-start-top--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-top/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-top/attrs/style` | differs | pointer-events: all; transform: translate(0px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-top/children/1-node-center-top-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-center-top","data-handlepos":"left","data-id":"1-node-center-top-null-target","class":"connectable connectableend con… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-top/children/1-node-center-top-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-center-top","data-handlepos":"right","data-id":"1-node-center-top-null-source","class":"connectable connectableend co… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-top/children/1-node-center-top--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-top/children/1-node-center-top--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-top/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-top/attrs/style` | differs | pointer-events: all; transform: translate(0px, 200px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, 200px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-top/children/1-node-end-top-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-end-top","data-handlepos":"left","data-id":"1-node-end-top-null-target","class":"connectable connectableend connectab… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-top/children/1-node-end-top-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-end-top","data-handlepos":"right","data-id":"1-node-end-top-null-source","class":"connectable connectableend connecta… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-top/children/1-node-end-top--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-top/children/1-node-end-top--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-right/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-right/attrs/style` | differs | pointer-events: all; transform: translate(300px, 0px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(300px, 0px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-right/children/1-node-start-right-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-start-right","data-handlepos":"left","data-id":"1-node-start-right-null-target","class":"connectable connectableend c… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-right/children/1-node-start-right-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-start-right","data-handlepos":"right","data-id":"1-node-start-right-null-source","class":"connectable connectableend … | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-right/children/1-node-start-right--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-right/children/1-node-start-right--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-right/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-right/attrs/style` | differs | pointer-events: all; transform: translate(300px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(300px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-right/children/1-node-center-right-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-center-right","data-handlepos":"left","data-id":"1-node-center-right-null-target","class":"connectable connectableend… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-right/children/1-node-center-right-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-center-right","data-handlepos":"right","data-id":"1-node-center-right-null-source","class":"connectable connectableen… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-right/children/1-node-center-right--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-right/children/1-node-center-right--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-right/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-right/attrs/style` | differs | pointer-events: all; transform: translate(300px, 200px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(300px, 200px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-right/children/1-node-end-right-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-end-right","data-handlepos":"left","data-id":"1-node-end-right-null-target","class":"connectable connectableend conne… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-right/children/1-node-end-right-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-end-right","data-handlepos":"right","data-id":"1-node-end-right-null-source","class":"connectable connectableend conn… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-right/children/1-node-end-right--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-right/children/1-node-end-right--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-bottom/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-bottom/attrs/style` | differs | pointer-events: all; transform: translate(600px, 0px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(600px, 0px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-bottom/children/1-node-start-bottom-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-start-bottom","data-handlepos":"left","data-id":"1-node-start-bottom-null-target","class":"connectable connectableend… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-bottom/children/1-node-start-bottom-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-start-bottom","data-handlepos":"right","data-id":"1-node-start-bottom-null-source","class":"connectable connectableen… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-bottom/children/1-node-start-bottom--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-bottom/children/1-node-start-bottom--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-bottom/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-bottom/attrs/style` | differs | pointer-events: all; transform: translate(600px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(600px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-bottom/children/1-node-center-bottom-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-center-bottom","data-handlepos":"left","data-id":"1-node-center-bottom-null-target","class":"connectable connectablee… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-bottom/children/1-node-center-bottom-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-center-bottom","data-handlepos":"right","data-id":"1-node-center-bottom-null-source","class":"connectable connectable… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-bottom/children/1-node-center-bottom--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-bottom/children/1-node-center-bottom--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-bottom/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-bottom/attrs/style` | differs | pointer-events: all; transform: translate(600px, 200px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(600px, 200px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-bottom/children/1-node-end-bottom-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-end-bottom","data-handlepos":"left","data-id":"1-node-end-bottom-null-target","class":"connectable connectableend con… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-bottom/children/1-node-end-bottom-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-end-bottom","data-handlepos":"right","data-id":"1-node-end-bottom-null-source","class":"connectable connectableend co… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-bottom/children/1-node-end-bottom--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-bottom/children/1-node-end-bottom--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-left/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-left/attrs/style` | differs | pointer-events: all; transform: translate(900px, 0px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(900px, 0px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-left/children/1-node-start-left-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-start-left","data-handlepos":"left","data-id":"1-node-start-left-null-target","class":"connectable connectableend con… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-left/children/1-node-start-left-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-start-left","data-handlepos":"right","data-id":"1-node-start-left-null-source","class":"connectable connectableend co… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-left/children/1-node-start-left--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-start-left/children/1-node-start-left--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-left/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-left/attrs/style` | differs | pointer-events: all; transform: translate(900px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(900px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-left/children/1-node-center-left-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-center-left","data-handlepos":"left","data-id":"1-node-center-left-null-target","class":"connectable connectableend c… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-left/children/1-node-center-left-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-center-left","data-handlepos":"right","data-id":"1-node-center-left-null-source","class":"connectable connectableend … | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-left/children/1-node-center-left--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-center-left/children/1-node-center-left--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-left/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-left/attrs/style` | differs | pointer-events: all; transform: translate(900px, 200px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(900px, 200px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-left/children/1-node-end-left-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"node-end-left","data-handlepos":"left","data-id":"1-node-end-left-null-target","class":"connectable connectableend connect… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-left/children/1-node-end-left-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"node-end-left","data-handlepos":"right","data-id":"1-node-end-left-null-source","class":"connectable connectableend connec… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-left/children/1-node-end-left--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-left target",… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/node-end-left/children/1-node-end-left--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-right source"… |
| `dom/root/children/div[1]/attrs/data-message` | left only | Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev | — |
| `dom/root/children/div[1]/children/a[0]` | left only | {"tag":"a","attrs":{"href":"https://reactflow.dev","target":"_blank","rel":"noopener noreferrer","aria-label":"React Flow attribution"},"text":"React Flow","ch… | — |
| `dom/root/children/div[1]/children/span[0]` | right only | — | {"tag":"span","attrs":{"data-message":"Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev"},"children":[{"t… |
| `dom/root/children/react-flow__node-desc-1/text` | differs | Press enter or space to select a node. You can then use the arrow keys to move the node around. Press delete to remove it and escape to cancel. | Press enter or space to select a node. Press delete to remove it and escape to cancel. |

### callbacks (122)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/1` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":0,"zoom":1}]} | — |
| `callbacks/3` | left only | {"name":"onMove","args":[null,{"x":58,"y":340.04571428571427,"zoom":1.1085714285714285}]} | — |
| `callbacks/4` | right only | — | {"name":"onError","args":["002","It looks like you've created a new nodeTypes or edgeTypes object. If this wasn't on purpose please define the nodeTypes/edgeTy… |
| `callbacks/5` | right only | — | {"name":"onSelectionChange","args":[{"nodes":[],"edges":[]}]} |
| `callbacks/6` | right only | — | {"name":"onViewportChange","args":[{"x":58,"y":340.04571428571427,"zoom":1.1085714285714285}]} |
| `callbacks/7` | right only | — | {"name":"onMoveEnd","args":[null,{"x":58,"y":340.04571428571427,"zoom":1.1085714285714285}]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onViewportChange#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onNodesChange#1","onViewportChange#1","onMoveEnd#1"] |
| `callbacks/4/args/0/0/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/resizing` | right only | — | false |
| `callbacks/4/args/0/0/setAttributes` | right only | — | true |
| `callbacks/4/args/0/1/id` | differs | node-start-top | node-center-bottom |
| `callbacks/4/args/0/1/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/resizing` | right only | — | false |
| `callbacks/4/args/0/1/setAttributes` | right only | — | true |
| `callbacks/4/args/0/2/id` | differs | node-center-top | node-center-left |
| `callbacks/4/args/0/2/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/resizing` | right only | — | false |
| `callbacks/4/args/0/2/setAttributes` | right only | — | true |
| `callbacks/4/args/0/3/id` | differs | node-end-top | node-center-right |
| `callbacks/4/args/0/3/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/resizing` | right only | — | false |
| `callbacks/4/args/0/3/setAttributes` | right only | — | true |
| `callbacks/4/args/0/4/id` | differs | node-start-right | node-center-top |
| `callbacks/4/args/0/4/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/resizing` | right only | — | false |
| `callbacks/4/args/0/4/setAttributes` | right only | — | true |
| `callbacks/4/args/0/5/id` | differs | node-center-right | node-end-bottom |
| `callbacks/4/args/0/5/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/resizing` | right only | — | false |
| `callbacks/4/args/0/5/setAttributes` | right only | — | true |
| `callbacks/4/args/0/6/id` | differs | node-end-right | node-end-left |
| `callbacks/4/args/0/6/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/resizing` | right only | — | false |
| `callbacks/4/args/0/6/setAttributes` | right only | — | true |
| `callbacks/4/args/0/7/id` | differs | node-start-bottom | node-end-right |
| `callbacks/4/args/0/7/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/resizing` | right only | — | false |
| `callbacks/4/args/0/7/setAttributes` | right only | — | true |
| `callbacks/4/args/0/8/id` | differs | node-center-bottom | node-end-top |
| `callbacks/4/args/0/8/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/resizing` | right only | — | false |
| `callbacks/4/args/0/8/setAttributes` | right only | — | true |
| `callbacks/4/args/0/9/id` | differs | node-end-bottom | node-start-bottom |
| `callbacks/4/args/0/9/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/9/resizing` | right only | — | false |
| `callbacks/4/args/0/9/setAttributes` | right only | — | true |
| `callbacks/4/args/0/10/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/10/resizing` | right only | — | false |
| `callbacks/4/args/0/10/setAttributes` | right only | — | true |
| `callbacks/4/args/0/11/id` | differs | node-center-left | node-start-right |
| `callbacks/4/args/0/11/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/11/resizing` | right only | — | false |
| `callbacks/4/args/0/11/setAttributes` | right only | — | true |
| `callbacks/4/args/0/12/id` | differs | node-end-left | node-start-top |
| `callbacks/4/args/0/12/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/12/resizing` | right only | — | false |
| `callbacks/4/args/0/12/setAttributes` | right only | — | true |


---

# System parity run — mount-baseline--nodes-general

**Failed:** unclaimed-difference.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. The driving log takes part with
no tolerance applied — it never reaches the normalizer at all — so a side whose resolved boxes wobble
between its own captures fails against itself.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--nodes-general

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

**Failed:** 147 unclaimed difference(s).

## Unclaimed differences

### dom (65)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/attrs/aria-label` | left only | Edge from Node-1 to Node-2 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[0]/attrs/d` | differs | M75,39 C75,68 -25,68 -25,97 | M74.99978384873843,38.99989906076928 C74.99978384873843,67.9999593059509 -25.000245738326498,67.9999593059509 -25.000245738326498,97.00001955113251 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/path[1]/attrs/d` | differs | M75,39 C75,68 -25,68 -25,97 | M74.99978384873843,38.99989906076928 C74.99978384873843,67.9999593059509 -25.000245738326498,67.9999593059509 -25.000245738326498,97.00001955113251 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/g[0]/attrs/transform` | differs | translate(15.56240463256836 61.69817113876343) | translate(15.562173687774326 61.69813044471432) |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cx` | differs | 75 | 74.99978384873843 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[0]/attrs/cy` | differs | 49 | 48.99989906076928 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[1]/attrs/cx` | differs | -25 | -25.000245738326498 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/1-2/children/circle[1]/attrs/cy` | differs | 87 | 87.00001955113251 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/attrs/aria-label` | left only | Edge from Node-1 to Node-3 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/path[0]/attrs/d` | differs | M75,39 C75,68 175,68 175,97 | M74.99978384873843,38.99989906076928 C74.99978384873843,67.9999593059509 174.99978384873845,67.9999593059509 174.99978384873845,97.00001955113251 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/path[1]/attrs/d` | differs | M75,39 C75,68 175,68 175,97 | M74.99978384873843,38.99989906076928 C74.99978384873843,67.9999593059509 174.99978384873845,67.9999593059509 174.99978384873845,97.00001955113251 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/g[0]/attrs/transform` | differs | translate(115.56240463256836 61.69817113876343) | translate(115.5621884813068 61.69813044471432) |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[0]/attrs/cx` | differs | 75 | 74.99978384873843 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[0]/attrs/cy` | differs | 49 | 48.99989906076928 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[1]/attrs/cx` | differs | 175 | 174.99978384873845 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/1-3/children/circle[1]/attrs/cy` | differs | 87 | 87.00001955113251 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children` | ordered differently | ["Node-1","Node-2","Node-3","Node-4","drag-handle","notConnectable","notDraggable","notSelectable","notDeletable"] | ["Node-1","Node-2","Node-3","Node-4","drag-handle","notConnectable","notDeletable","notDraggable","notSelectable"] |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-1/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-1/attrs/style` | differs | background-color: red; pointer-events: all; transform: translate(0px, 0px); visibility: visible; z-index: 0; | background-color: red; height: 36px; pointer-events: all; transform: translate(0px, 0px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-1/children/1-Node-1-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"Node-1","data-handlepos":"bottom","data-id":"1-Node-1-null-source","class":"connectable connectableend connectablestart co… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-1/children/1-Node-1--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-2/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-2/attrs/style` | differs | pointer-events: all; transform: translate(-100px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(-100px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-2/children/1-Node-2-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"Node-2","data-handlepos":"top","data-id":"1-Node-2-null-target","class":"connectable connectableend connectablestart conne… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-2/children/1-Node-2--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-3/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-3/attrs/style` | differs | pointer-events: all; transform: translate(100px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(100px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-3/children/1-Node-3-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"Node-3","data-handlepos":"top","data-id":"1-Node-3-null-target","class":"connectable connectableend connectablestart conne… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-3/children/1-Node-3-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"Node-3","data-handlepos":"bottom","data-id":"1-Node-3-null-source","class":"connectable connectableend connectablestart co… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-3/children/1-Node-3--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-3/children/1-Node-3--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-4/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-4/attrs/style` | differs | pointer-events: all; transform: translate(0px, 200px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, 200px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-4/children/1-Node-4-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"Node-4","data-handlepos":"top","data-id":"1-Node-4-null-target","class":"connectable connectableend connectablestart conne… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/Node-4/children/1-Node-4--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/drag-handle/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/drag-handle/attrs/style` | differs | pointer-events: all; transform: translate(200px, 0px); visibility: visible; z-index: 0; | height: 50px; pointer-events: all; transform: translate(200px, 0px); visibility: visible; width: 100px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notConnectable/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notConnectable/attrs/style` | differs | pointer-events: all; transform: translate(0px, 300px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, 300px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notConnectable/children/1-notConnectable-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"notConnectable","data-handlepos":"top","data-id":"1-notConnectable-null-target","class":"connectableend connectablestart n… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notConnectable/children/1-notConnectable--target` | right only | — | {"tag":"div","attrs":{"class":"connectableend connectablestart nodrag nopan react-flow__handle react-flow__handle-top target","data-nodeid":"notConnectable","d… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDraggable/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDraggable/attrs/style` | differs | pointer-events: all; transform: translate(0px, 400px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, 400px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDraggable/children/1-notDraggable-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"notDraggable","data-handlepos":"top","data-id":"1-notDraggable-null-target","class":"connectable connectableend connectabl… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDraggable/children/1-notDraggable-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"notDraggable","data-handlepos":"bottom","data-id":"1-notDraggable-null-source","class":"connectable connectableend connect… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDraggable/children/1-notDraggable--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDraggable/children/1-notDraggable--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notSelectable/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notSelectable/attrs/style` | differs | pointer-events: all; transform: translate(0px, 500px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, 500px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notSelectable/children/1-notSelectable-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"notSelectable","data-handlepos":"top","data-id":"1-notSelectable-null-target","class":"connectable connectableend connecta… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notSelectable/children/1-notSelectable-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"notSelectable","data-handlepos":"bottom","data-id":"1-notSelectable-null-source","class":"connectable connectableend conne… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notSelectable/children/1-notSelectable--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notSelectable/children/1-notSelectable--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDeletable/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDeletable/attrs/style` | differs | pointer-events: all; transform: translate(0px, 600px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, 600px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDeletable/children/1-notDeletable-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"notDeletable","data-handlepos":"top","data-id":"1-notDeletable-null-target","class":"connectable connectableend connectabl… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDeletable/children/1-notDeletable-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"notDeletable","data-handlepos":"bottom","data-id":"1-notDeletable-null-source","class":"connectable connectableend connect… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDeletable/children/1-notDeletable--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/notDeletable/children/1-notDeletable--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[1]/attrs/data-message` | left only | Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev | — |
| `dom/root/children/div[1]/children/a[0]` | left only | {"tag":"a","attrs":{"href":"https://reactflow.dev","target":"_blank","rel":"noopener noreferrer","aria-label":"React Flow attribution"},"text":"React Flow","ch… | — |
| `dom/root/children/div[1]/children/span[0]` | right only | — | {"tag":"span","attrs":{"data-message":"Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev"},"children":[{"t… |
| `dom/root/children/react-flow__node-desc-1/text` | differs | Press enter or space to select a node. You can then use the arrow keys to move the node around. Press delete to remove it and escape to cancel. | Press enter or space to select a node. Press delete to remove it and escape to cancel. |

### callbacks (82)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/1` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":0,"zoom":1}]} | — |
| `callbacks/3` | left only | {"name":"onMove","args":[null,{"x":536.8553459119497,"y":32,"zoom":1.0314465408805031}]} | — |
| `callbacks/4` | right only | — | {"name":"onError","args":["002","It looks like you've created a new nodeTypes or edgeTypes object. If this wasn't on purpose please define the nodeTypes/edgeTy… |
| `callbacks/5` | right only | — | {"name":"onSelectionChange","args":[{"nodes":[],"edges":[]}]} |
| `callbacks/6` | right only | — | {"name":"onViewportChange","args":[{"x":536.8553459119497,"y":32,"zoom":1.0314465408805031}]} |
| `callbacks/7` | right only | — | {"name":"onMoveEnd","args":[null,{"x":536.8553459119497,"y":32,"zoom":1.0314465408805031}]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onViewportChange#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onNodesChange#1","onViewportChange#1","onMoveEnd#1"] |
| `callbacks/4/args/0/0/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/resizing` | right only | — | false |
| `callbacks/4/args/0/0/setAttributes` | right only | — | true |
| `callbacks/4/args/0/1/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/resizing` | right only | — | false |
| `callbacks/4/args/0/1/setAttributes` | right only | — | true |
| `callbacks/4/args/0/2/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/resizing` | right only | — | false |
| `callbacks/4/args/0/2/setAttributes` | right only | — | true |
| `callbacks/4/args/0/3/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/3/resizing` | right only | — | false |
| `callbacks/4/args/0/3/setAttributes` | right only | — | true |
| `callbacks/4/args/0/4/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/4/resizing` | right only | — | false |
| `callbacks/4/args/0/4/setAttributes` | right only | — | true |
| `callbacks/4/args/0/5/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/5/resizing` | right only | — | false |
| `callbacks/4/args/0/5/setAttributes` | right only | — | true |
| `callbacks/4/args/0/6/id` | differs | notDraggable | notDeletable |
| `callbacks/4/args/0/6/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/6/resizing` | right only | — | false |
| `callbacks/4/args/0/6/setAttributes` | right only | — | true |
| `callbacks/4/args/0/7/id` | differs | notSelectable | notDraggable |
| `callbacks/4/args/0/7/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/7/resizing` | right only | — | false |
| `callbacks/4/args/0/7/setAttributes` | right only | — | true |
| `callbacks/4/args/0/8/id` | differs | notDeletable | notSelectable |
| `callbacks/4/args/0/8/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/8/resizing` | right only | — | false |
| `callbacks/4/args/0/8/setAttributes` | right only | — | true |


---

# System parity run — mount-baseline--pane-general

**Failed:** unclaimed-difference.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. The driving log takes part with
no tolerance applied — it never reaches the normalizer at all — so a side whose resolved boxes wobble
between its own captures fails against itself.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | reproduced | 0 |

---

# Comparison report — mount-baseline--pane-general

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

**Failed:** 66 unclaimed difference(s).

## Unclaimed differences

### dom (36)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/attrs/aria-label` | left only | Edge from 1 to 2 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/path[0]/attrs/d` | differs | M75,39 C75,68 -25,68 -25,97 | M75.00008777202368,39.00004291112603 C75.00008777202368,68.00002418935426 -24.99990305171677,68.00002418935426 -24.99990305171677,97.00000546758248 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/path[1]/attrs/d` | differs | M75,39 C75,68 -25,68 -25,97 | M75.00008777202368,39.00004291112603 C75.00008777202368,68.00002418935426 -24.99990305171677,68.00002418935426 -24.99990305171677,97.00000546758248 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/circle[0]/attrs/cx` | differs | 75 | 75.00008777202368 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/circle[0]/attrs/cy` | differs | 49 | 49.00004291112603 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/circle[1]/attrs/cx` | differs | -25 | -24.99990305171677 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/children/circle[1]/attrs/cy` | differs | 87 | 87.00000546758248 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/second-edge/attrs/aria-label` | left only | Edge from 1 to 3 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/second-edge/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/second-edge/children/path[0]/attrs/d` | differs | M75,39 C75,68 175,68 175,97 | M75.00008777202368,39.00004291112603 C75.00008777202368,68.00002418935426 175.00007859576414,68.00002418935426 175.00007859576414,97.00000546758248 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/second-edge/children/path[1]/attrs/d` | differs | M75,39 C75,68 175,68 175,97 | M75.00008777202368,39.00004291112603 C75.00008777202368,68.00002418935426 175.00007859576414,68.00002418935426 175.00007859576414,97.00000546758248 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/second-edge/children/circle[0]/attrs/cx` | differs | 75 | 75.00008777202368 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/second-edge/children/circle[0]/attrs/cy` | differs | 49 | 49.00004291112603 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/second-edge/children/circle[1]/attrs/cx` | differs | 175 | 175.00007859576414 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/second-edge/children/circle[1]/attrs/cy` | differs | 87 | 87.00000546758248 |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/attrs/style` | differs | pointer-events: all; transform: translate(0px, 0px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, 0px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/children/1-1-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"1","data-handlepos":"bottom","data-id":"1-1-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/children/1-1--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/attrs/style` | differs | pointer-events: all; transform: translate(-100px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(-100px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"2","data-handlepos":"top","data-id":"1-2-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"2","data-handlepos":"bottom","data-id":"1-2-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/attrs/style` | differs | pointer-events: all; transform: translate(100px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(100px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"3","data-handlepos":"top","data-id":"1-3-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"3","data-handlepos":"bottom","data-id":"1-3-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[1]/attrs/data-message` | left only | Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev | — |
| `dom/root/children/div[1]/children/a[0]` | left only | {"tag":"a","attrs":{"href":"https://reactflow.dev","target":"_blank","rel":"noopener noreferrer","aria-label":"React Flow attribution"},"text":"React Flow","ch… | — |
| `dom/root/children/div[1]/children/span[0]` | right only | — | {"tag":"span","attrs":{"data-message":"Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev"},"children":[{"t… |
| `dom/root/children/react-flow__node-desc-1/text` | differs | Press enter or space to select a node. You can then use the arrow keys to move the node around. Press delete to remove it and escape to cancel. | Press enter or space to select a node. Press delete to remove it and escape to cancel. |

### callbacks (30)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/1` | left only | {"name":"onMoveStart","args":[null,{"x":0,"y":0,"zoom":1}]} | — |
| `callbacks/3` | left only | {"name":"onMove","args":[null,{"x":390.57142857142856,"y":133.85142857142858,"zoom":3.3257142857142856}]} | — |
| `callbacks/4` | right only | — | {"name":"onSelectionChange","args":[{"nodes":[],"edges":[]}]} |
| `callbacks/5` | right only | — | {"name":"onViewportChange","args":[{"x":390.57142857142856,"y":133.85142857142858,"zoom":3.3257142857142856}]} |
| `callbacks/6` | right only | — | {"name":"onMoveEnd","args":[null,{"x":390.57142857142856,"y":133.85142857142858,"zoom":3.3257142857142856}]} |
| `callbacks` | ordered differently | ["onSelectionChange#1","onViewportChange#1","onNodesChange#1","onMoveEnd#1"] | ["onSelectionChange#1","onNodesChange#1","onViewportChange#1","onMoveEnd#1"] |
| `callbacks/4/args/0/0/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/0/resizing` | right only | — | false |
| `callbacks/4/args/0/0/setAttributes` | right only | — | true |
| `callbacks/4/args/0/1/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/1/resizing` | right only | — | false |
| `callbacks/4/args/0/1/setAttributes` | right only | — | true |
| `callbacks/4/args/0/2/position` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/dragging` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/selected` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/item` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/index` | right only | — | {"@undefined":true} |
| `callbacks/4/args/0/2/resizing` | right only | — | false |
| `callbacks/4/args/0/2/setAttributes` | right only | — | true |


---

# System parity run — mount-baseline--pane-non-defaults

**Failed:** self-inconsistent, unclaimed-difference.

## Self-consistency

Each side is captured twice and compared against itself **before** the sides are compared at all: a
recorded trace baseline is meaningless if traces are not reproducible. The driving log takes part with
no tolerance applied — it never reaches the normalizer at all — so a side whose resolved boxes wobble
between its own captures fails against itself.

| side | captures | verdict | differences |
|---|---|---|---|
| upstream | 1, 2 | reproduced | 0 |
| psflow | 1, 2 | **disagrees with itself** | 1 |

### psflow disagrees with itself

| path | kind | capture 1 | capture 2 |
|---|---|---|---|
| `callbacks` | ordered differently | ["onSelectionChange#1","onNodesChange#1","onSelectionChange#2"] | ["onSelectionChange#1","onSelectionChange#2","onNodesChange#1"] |

**psflow did not reproduce.** The comparison below ran anyway —
capture-everything applies to a failed run as much as to a passing one — but a difference it reports
cannot yet be attributed to either implementation. Fix the reproducibility, then read it.

---

# Comparison report — mount-baseline--pane-non-defaults

upstream (capture 1, baseline 12.11.0) against psflow (capture 1, baseline 12.11.0).

**Failed:** 49 unclaimed difference(s).

## Unclaimed differences

### dom (24)

| path | kind | upstream | psflow |
|---|---|---|---|
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/attrs/aria-label` | left only | Edge from 1 to 2 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[0]/children/first-edge/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/second-edge/attrs/aria-label` | left only | Edge from 1 to 3 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[0]/children/svg[1]/children/second-edge/attrs/aria-describedby` | left only | react-flow__edge-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/attrs/style` | differs | pointer-events: all; transform: translate(0px, 0px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(0px, 0px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/children/1-1-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"1","data-handlepos":"bottom","data-id":"1-1-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/1/children/1-1--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/attrs/style` | differs | pointer-events: all; transform: translate(-100px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(-100px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"2","data-handlepos":"top","data-id":"1-2-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"2","data-handlepos":"bottom","data-id":"1-2-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/2/children/1-2--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/attrs/aria-describedby` | left only | react-flow__node-desc-1 | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/attrs/style` | differs | pointer-events: all; transform: translate(100px, 100px); visibility: visible; z-index: 0; | height: 36px; pointer-events: all; transform: translate(100px, 100px); visibility: visible; width: 150px; z-index: 0; |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3-null-target` | left only | {"tag":"div","attrs":{"data-nodeid":"3","data-handlepos":"top","data-id":"1-3-null-target","class":"connectable connectableend connectablestart connectionindic… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3-null-source` | left only | {"tag":"div","attrs":{"data-nodeid":"3","data-handlepos":"bottom","data-id":"1-3-null-source","class":"connectable connectableend connectablestart connectionin… | — |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3--target` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-top target","… |
| `dom/root/children/div[0]/children/div[0]/children/div[0]/children/div[2]/children/3/children/1-3--source` | right only | — | {"tag":"div","attrs":{"class":"connectable connectableend connectablestart connectionindicator nodrag nopan react-flow__handle react-flow__handle-bottom source… |
| `dom/root/children/div[1]/attrs/data-message` | left only | Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev | — |
| `dom/root/children/div[1]/children/a[0]` | left only | {"tag":"a","attrs":{"href":"https://reactflow.dev","target":"_blank","rel":"noopener noreferrer","aria-label":"React Flow attribution"},"text":"React Flow","ch… | — |
| `dom/root/children/div[1]/children/span[0]` | right only | — | {"tag":"span","attrs":{"data-message":"Please only hide this attribution when you are subscribed to React Flow Pro: https://pro.reactflow.dev"},"children":[{"t… |
| `dom/root/children/react-flow__node-desc-1/text` | differs | Press enter or space to select a node. You can then use the arrow keys to move the node around. Press delete to remove it and escape to cancel. | Press enter or space to select a node. Press delete to remove it and escape to cancel. |

### callbacks (25)

| path | kind | upstream | psflow |
|---|---|---|---|
| `callbacks/2` | right only | — | {"name":"onSelectionChange","args":[{"nodes":[],"edges":[]}]} |
| `callbacks/1/args/0/0/position` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/0/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/0/dragging` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/0/selected` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/0/item` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/0/index` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/0/resizing` | right only | — | false |
| `callbacks/1/args/0/0/setAttributes` | right only | — | true |
| `callbacks/1/args/0/1/position` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/1/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/1/dragging` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/1/selected` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/1/item` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/1/index` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/1/resizing` | right only | — | false |
| `callbacks/1/args/0/1/setAttributes` | right only | — | true |
| `callbacks/1/args/0/2/position` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/2/positionAbsolute` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/2/dragging` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/2/selected` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/2/item` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/2/index` | right only | — | {"@undefined":true} |
| `callbacks/1/args/0/2/resizing` | right only | — | false |
| `callbacks/1/args/0/2/setAttributes` | right only | — | true |

