// The callbacks section — an exact sequence, and the only weakening of one
// (#19 §5, #44).
//
// Callbacks are compared more strictly than anything else in the trace, for a
// reason that is structural rather than a matter of taste: **they leave no
// residue in end state**. If PSFlow never fires a handler the DOM is identical,
// every other section agrees, and an end-state net passes green. The call log is
// the only place the absence is visible, so it is compared exactly — order,
// count and interleaving all.
//
// That strictness carries downstream weight worth knowing before anyone relaxes
// it: three audit rows in the `flow-props-change-after-mount` scenario are
// reachable **only** because this comparison is exact (spec #37). If it is ever
// weakened, check those first.
//
// ## Exact, and still legible
//
// A plain positional diff is exact and unreadable. Drop the third call of five
// and it reports one missing entry plus every later call as an argument
// difference — the shift cascade `diff.mjs` was keyed to avoid, one section
// over, and here it is worse: the invented differences are in *arguments*, and
// read as findings about what the two libraries pass.
//
// So calls are paired by name and occurrence — the second `onNodesChange` on one
// side against the second on the other — and each of the three claims is then
// asked separately:
//
//   * **count** — a call with no partner is a `left-only` or `right-only`
//     difference at its own index. A missing call and a duplicated one are the
//     same question asked from the two sides.
//   * **order** — the paired calls' sequences are compared as sequences. Same
//     calls in a different order is exactly one `order` difference carrying both,
//     never a cascade.
//   * **arguments** — each pair is diffed by `diff.mjs` under the call's index.
//
// Pairing by occurrence is not keying in the sense `diff.mjs` means it: nothing
// about order is forgiven, it is asserted one line down. Paths stay positional —
// `callbacks/3/args/0/dimensions/width` addresses the trace itself, which is
// what lets `assertNoCollapse` and a region's pattern speak the same language.
// The index of a paired difference is the **left** side's; the right's is
// recoverable from the order difference that reported the two sequences.
//
// ## Weakening
//
// One callback, one axis, one written reason. The kinds are closed at `count`
// and `order` — the two axes a *comparison* can relax.
//
// **`arguments` is deliberately not a kind.** An argument difference is already
// claimable: it has a path, so a **region** claims it, carrying a reason, a
// ticket and the recorded values that must be re-affirmed when they move. A
// weakening records nothing, so an `arguments` kind would make a whole handler's
// payload unobserved for as long as the entry survived — the dumping ground the
// noise policy is built to prevent. Nothing about `count` or `order` can be said
// that way, which is why they need a mechanism of their own.
//
// A weakening that forgives nothing **fails as stale**, like every other register
// here, and it is judged on what it alone forgives: two weakenings that overlap
// cannot each ride on the other's back. Note what that costs, and it is the cost
// regions already carry — a weakening is affirmed against the run it is
// committed with, so an entry earning its place in one scenario is stale in a run
// of another. Scoping is how regions answer that; a weakening has no case for it
// yet, and inventing one before the corpus exists would be guessing.

import { diffValues } from "./diff.mjs";
import { OUTCOME } from "./regions.mjs";

/** The two axes a comparison can relax. `arguments` is a region's job — see above. */
export const WEAKENING_KINDS = ["count", "order"];

export class WeakeningError extends Error {
  constructor(message) {
    super(message);
    this.name = "WeakeningError";
  }
}

export const validateWeakenings = (weakenings) => {
  if (!Array.isArray(weakenings)) throw new WeakeningError("callback weakenings must be an array");
  const seen = new Set();
  weakenings.forEach((weakening, i) => {
    const at = `weakening ${i} (${weakening?.callback ?? "no callback"})`;
    if (typeof weakening?.callback !== "string" || weakening.callback === "") {
      throw new WeakeningError(`${at}: needs the name of the callback it weakens`);
    }
    if (!WEAKENING_KINDS.includes(weakening.kind)) {
      throw new WeakeningError(
        `${at}: kind ${JSON.stringify(weakening.kind)} is not one of ${WEAKENING_KINDS.join(", ")}. ` +
          `An argument that differs has a path, so it is claimed by a region — which records the values ` +
          `and makes someone re-affirm them when they move.`
      );
    }
    if (typeof weakening.reason !== "string" || weakening.reason === "") {
      throw new WeakeningError(`${at}: needs a written reason — callbacks are the one class nothing else can observe`);
    }
    if ("ticket" in weakening && (typeof weakening.ticket !== "string" || weakening.ticket === "")) {
      throw new WeakeningError(`${at}: a ticket is where the difference stays someone's problem, or it is absent`);
    }

    const key = `${weakening.callback}/${weakening.kind}`;
    if (seen.has(key)) {
      throw new WeakeningError(`${at}: ${weakening.callback} already weakens ${weakening.kind}; one of the two could never go stale`);
    }
    seen.add(key);
  });
  return weakenings;
};

const difference = (kind, path, left, right) => ({ kind, path, left, right });

/**
 * Each call tagged with its position and with `name#n`, where n counts that
 * name's occurrences on its own side. The tag is what pairs the two sides; it
 * never reaches a path.
 */
const occurrences = (calls) => {
  const counts = new Map();
  return calls.map((call, index) => {
    const n = (counts.get(call.name) ?? 0) + 1;
    counts.set(call.name, n);
    return { call, index, key: `${call.name}#${n}` };
  });
};

const namesWeakening = (weakenings, kind) =>
  new Set(weakenings.filter((w) => w.kind === kind).map((w) => w.callback));

const diffSequences = (left, right, weakenings, path) => {
  const out = [];
  const forgivenCount = namesWeakening(weakenings, "count");
  const forgivenOrder = namesWeakening(weakenings, "order");

  const leftCalls = occurrences(left);
  const rightCalls = occurrences(right);
  const leftByKey = new Map(leftCalls.map((e) => [e.key, e]));
  const rightByKey = new Map(rightCalls.map((e) => [e.key, e]));

  // A call with no partner. From the left it reads as missing, from the right as
  // duplicated or spurious; they are one question, and the two kinds say which
  // side made the call.
  for (const entry of leftCalls) {
    if (!rightByKey.has(entry.key) && !forgivenCount.has(entry.call.name)) {
      out.push(difference("left-only", [...path, entry.index], entry.call, undefined));
    }
  }
  for (const entry of rightCalls) {
    if (!leftByKey.has(entry.key) && !forgivenCount.has(entry.call.name)) {
      out.push(difference("right-only", [...path, entry.index], undefined, entry.call));
    }
  }

  // Order is judged over the calls both sides made, so a call one side skipped
  // does not also report as everything after it having moved.
  const sequence = (entries, other) =>
    entries.filter((e) => other.has(e.key) && !forgivenOrder.has(e.call.name)).map((e) => e.key);
  const leftOrder = sequence(leftCalls, rightByKey);
  const rightOrder = sequence(rightCalls, leftByKey);
  if (leftOrder.join(" ") !== rightOrder.join(" ")) out.push(difference("order", path, leftOrder, rightOrder));

  for (const entry of leftCalls) {
    const partner = rightByKey.get(entry.key);
    // The whole entry, not only `args`: a field the trace format grows would
    // otherwise be captured and never compared.
    if (partner) out.push(...diffValues(entry.call, partner.call, [...path, entry.index]));
  }

  return out;
};

/**
 * Compares two `callbacks` sections.
 *
 * Returns `{ differences, outcomes }`. An outcome is `{ weakening, status }`,
 * and only `rides-free` passes — a weakening rides free when the comparison
 * would have reported something without it.
 */
export const compareCallbacks = (left, right, { weakenings = [], path = ["callbacks"] } = {}) => {
  validateWeakenings(weakenings);

  const differences = diffSequences(left, right, weakenings, path);

  // Judged one at a time and against the full set, so a weakening is stale
  // unless it is load-bearing by itself. Weakenings only ever remove
  // differences, which is what makes counting them a sound test of that.
  const outcomes = weakenings.map((weakening) => {
    const without = diffSequences(left, right, weakenings.filter((w) => w !== weakening), path);
    return { weakening, status: without.length > differences.length ? OUTCOME.ridesFree : OUTCOME.stale };
  });

  return { differences, outcomes };
};

/** The weakenings with one status — what the report counts and a run names. */
export const weakeningsWith = (outcomes, status) => outcomes.filter((o) => o.status === status);
