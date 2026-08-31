// The three chrome components at their **defaults**, on a flow that does not
// fit its view — the condition the retired smoke assertions drove (#61).
//
// `parity/driver/src/Smoke.tsx` was a ps-flow **contract** component: a page
// only ps-flow ever mounted, carrying eight hand-authored parity assertions
// against a flow upstream was never asked the same questions about. This is
// that flow as data, so both implementations mount it and the net compares
// everything the eight assertions looked at and everything they did not.
//
// ## What is deliberately *not* set here
//
// **`connectOnClick`.** The smoke page set it explicitly and it is upstream's
// own default (`store/initialState.ts`), so pinning it here would restate a
// default both sides already share — and would hide a divergence in the default
// itself, which is the more interesting of the two claims. Left unset, the
// click-connect scenario proves the defaults agree as well as that the
// interaction works.
//
// **`fitView`.** Every other fixture in the corpus sets it, and upstream's
// `pane/non-defaults.ts` is the only other flow mounted without it. A viewport
// that starts at the identity transform is what makes a wheel-zoom or a pane
// drag a reading of the gesture rather than of `fitView`'s arithmetic, which is
// the one thing the retired assertions could observe cheaply and is worth
// keeping. `defaultViewport` is written out for the same reason it is in
// `nodes/autopan.ts`: the identity is the default, and saying so is what stops
// a reader assuming `fitView` was forgotten.
//
// ## What *is* set
//
// The three chrome components with **empty props**. The driver renders each one
// per entry in its config key, so `{}` is how a fixture asks for a component on
// upstream's own defaults. No other ps-flow fixture does — `chrome/*.ts` each
// set the non-default variant their changelog row is about — so a default
// `Background`, `Controls` or `MiniMap` is otherwise witnessed only by upstream's
// ColorMode example driver, which asserts nothing and drives nothing.
//
// The two nodes carry explicit `sourcePosition` / `targetPosition` and their own
// measurements, exactly as the smoke page's did: the click-connect scenario
// aims at a named side of a named node, and a handle whose position came from a
// default would move the target the scenario resolves.

export default {
  flowProps: {
    defaultViewport: { x: 0, y: 0, zoom: 1 },
    nodes: [
      {
        id: 'n1',
        data: { label: 'n1' },
        position: { x: 0, y: 0 },
        sourcePosition: 'right',
        targetPosition: 'left',
        width: 100,
        height: 40,
        measured: { width: 100, height: 40 },
      },
      {
        id: 'n2',
        data: { label: 'n2' },
        position: { x: 250, y: 100 },
        sourcePosition: 'right',
        targetPosition: 'left',
        width: 100,
        height: 40,
        measured: { width: 100, height: 40 },
      },
    ],
    edges: [{ id: 'e1-2', source: 'n1', target: 'n2' }],
  },
  backgroundProps: {},
  controlsProps: {},
  minimapProps: {},
};
