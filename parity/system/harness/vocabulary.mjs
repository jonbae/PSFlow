// The action vocabulary — the object a scenario is handed, and the only thing
// it is handed (#26, #35).
//
// The two tiers merged: `actions.mjs`'s closed seven and `gestures.mjs`'s
// open-by-addition six. It is called the **vocabulary** rather than the driver,
// because a *driver* in this repo is the React component that mounts a fixture,
// and the two would be impossible to tell apart in a sentence.
//
// **A scenario has no way to learn which side it is running against.** Not
// "should not" — no way. The vocabulary closes over the port, the driving log
// and the api log; there is no page, no URL, no bundle name and no library
// handle anywhere on it, and it is frozen so nothing can be attached later.
//
// **And nothing comes back.** Every function resolves to `undefined`. The tiers
// beneath return the driving entry they recorded — `gestures.mjs` needs the
// last dispatched point to walk a drag without drifting, and the harness's own
// tests read them — but an entry carries the **box that side resolved**, which
// is exactly what differs between the two: the spike's whole finding was a
// geometry gap. A scenario handed that could branch on it as surely as if it
// had been told the side's name. So the aperture is closed at the boundary
// where a scenario actually stands, and the only record of what happened is the
// driving log, which it cannot read.

import { PRIMITIVES, createPrimitives } from "./actions.mjs";
import { GESTURES, createGestures } from "./gestures.mjs";

export const VOCABULARY = [...PRIMITIVES, ...GESTURES];

/**
 * `log` is the driving log and `apiCalls` the trace's `api.calls`; both belong
 * to the harness, which reads them after the scenario has run.
 */
export const createVocabulary = (port, log, apiCalls = []) => {
  const primitives = createPrimitives(port, log, apiCalls);
  const gestures = createGestures(primitives);

  // A gesture named after a primitive would shadow it, and every scenario
  // reaching for the primitive would silently get the composition instead.
  const shadowed = Object.keys(gestures).filter((name) => name in primitives);
  if (shadowed.length) {
    throw new Error(`gesture(s) ${shadowed.join(", ")} shadow a primitive of the same name`);
  }

  const sealed = Object.entries({ ...primitives, ...gestures }).map(([name, action]) => [
    name,
    async (...args) => void (await action(...args)),
  ]);

  return Object.freeze(Object.fromEntries(sealed));
};
