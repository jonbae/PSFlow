# 057 — `snapPosition` rounds negative half-multiples the wrong way

## Context

Discovered by the **Layer 1 live parity harness** (`test/Test/Parity/*`,
added alongside this ticket): a property comparing PSFlow's `snapPosition`
against the live XYFlow `snapPosition` over random inputs disagrees whenever
`position / gridSize` lands on an exact negative half-integer.

[`src/System/Utils/General.purs`](../src/System/Utils/General.purs) implements
`snapPosition` with a hand-rolled `roundHalfAwayFromZero`:

```purescript
roundHalfAwayFromZero n =
  if n >= 0.0 then Number.floor (n + 0.5)
  else -(Number.floor ((-n) + 0.5))
```

The accompanying comment claims *"TS uses `Math.round`, which rounds half away
from zero"*. That premise is **wrong**: JavaScript `Math.round` rounds half
**toward +∞**, not away from zero. So the two disagree on negative exact-halves:

| input | JS `Math.round` (XYFlow) | PSFlow `roundHalfAwayFromZero` |
|------:|:------------------------:|:------------------------------:|
| -0.5  | -0  → 0                   | -1                             |
| -1.5  | -1                        | -2                             |
| -2.5  | -2                        | -3                             |

Positive halves agree (both → +1, +2, +3). Upstream:

```ts
export const snapPosition = (position, snapGrid = [1, 1]) => ({
  x: snapGrid[0] * Math.round(position.x / snapGrid[0]),
  y: snapGrid[1] * Math.round(position.y / snapGrid[1]),
});
```

This also affects `pointToRendererPoint` **when a snap grid is supplied**
(it delegates to `snapPosition`).

## Impact

Low but real: a node/point at an exact negative half-cell snaps one grid cell
too far in the `-` direction versus XYFlow. For drop-in parity it is a genuine
behavioural divergence on the negative axis.

## Fix

Replace `roundHalfAwayFromZero` with round-half-toward-+∞ to match JS
`Math.round`:

```purescript
roundHalfUp :: Number -> Number
roundHalfUp n = Number.floor (n + 0.5)
```

(`Math.round(x) === Math.floor(x + 0.5)` for all finite `x`, including the
`-0.5 → -0` case.) Update the misleading comment. Then widen the
`snapPosition` parity generator in
[`test/Test/Parity/Geometry.purs`](../test/Test/Parity/Geometry.purs) back to
the full (incl. negative) domain and drop the ticket-057 caveat there.

## Verification

- `spago test` green with the widened generator.
- Spot-check: `snapPosition {x: -5, y: 0} (mkSnapGrid 2 2)` ⇒ `{x: -4, ...}`
  (was `{x: -6, ...}`), matching `Oracle.snapPosition`.

## Source Files

- [src/System/Utils/General.purs](../src/System/Utils/General.purs) — `snapPosition`, `roundHalfAwayFromZero`
- [test/Test/Parity/Geometry.purs](../test/Test/Parity/Geometry.purs) — the constrained property
- [xyflow/packages/system/src/utils/general.ts](../xyflow/packages/system/src/utils/general.ts) — upstream `snapPosition`
