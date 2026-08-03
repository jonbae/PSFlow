# 057 — `snapPosition` rounds negative half-multiples the wrong way

## ✅ RESOLVED (2026-08-03)

`roundHalfAwayFromZero` is gone, replaced by `roundHalfUp` in
[General.purs](../src/System/Utils/General.purs), which matches JS `Math.round`
across the full signed domain. Both call sites were affected and both are fixed:
`snapPosition` and — not noted at filing — `XYDrag.purs`'s multi-drag snap
offset (`~576`), which mirrors upstream `XYDrag.ts:170-171`'s `Math.round`.

Implementation deviates slightly from the fix proposed below: the prescribed
`floor (n + 0.5)` is itself wrong for `0.49999999999999994` (the largest double
under one half — `n + 0.5` rounds up to `1.0`, yielding `1.0` where
`Math.round` gives `0`). `roundHalfUp` compares the fractional part instead,
which is exact.

Guarded at two levels, both confirmed to fail under a reverted helper:

- **Unit** ([Test/Main.purs](../test/Test/Main.purs)) — the spot-check below
  plus `roundHalfUp` on `-1.5` / `-0.5` / `1.5` / `0.49999999999999994`.
  Deterministic; fails on every run.
- **Layer 1 parity** ([Test/Parity/Geometry.purs](../test/Test/Parity/Geometry.purs))
  — the `snapPosition` generator is widened to the full signed domain and the
  ticket caveat dropped, `pointToRendererPoint` gains a `Just grid` property,
  and a new `genHalfCell` generator puts *every* draw exactly on a half-multiple.
  That last one matters: under the plain widened generator alone, exact halves
  are rare enough (~1% of draws) that a reverted fix still passed roughly 1 run
  in 14.

`spago test` green; full smoke suite 54/54.

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
