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
// So calls are **paired** first (see below), and each of the three claims is
// then asked of the pairing separately:
//
//   * **count** — a call with no partner is a `left-only` or `right-only`
//     difference at its own index. A missing call and a duplicated one are the
//     same question asked from the two sides.
//   * **order** — the paired calls' sequences are compared as sequences. Same
//     calls in a different order is exactly one `order` difference carrying both,
//     never a cascade.
//   * **arguments** — each pair is diffed by `diff.mjs` under the call's index.
//
// Pairing is not keying in the sense `diff.mjs` means it: nothing about order is
// forgiven, it is asserted one line down. Paths stay positional —
// `callbacks/3/args/0/dimensions/width` addresses the trace itself, which is
// what lets `assertNoCollapse` and a region's pattern speak the same language.
// The index of a paired difference is the **left** side's; the right's is
// recoverable from the order difference that reported the two sequences.
//
// ## Weakening
//
// One callback, one axis, one written reason. The axes are closed at `count`
// and `order` — the two a *comparison* can relax.
//
// **`arguments` is deliberately not an axis.** An argument difference is already
// claimable: it has a path, so a **region** claims it, carrying a reason, a
// ticket and the recorded values that must be re-affirmed when they move. A
// weakening records nothing, so an `arguments` axis would make a whole handler's
// payload unobserved for as long as the entry survived — the dumping ground the
// noise policy is built to prevent. Nothing about `count` or `order` can be said
// that way, which is why they need a mechanism of their own.
//
// The two axes are not quite independent, and the seam is worth stating. A call
// only one side made has no position on the other, so it cannot take part in an
// order comparison at all — which means a `count` weakening also drops that
// call's *unpaired* occurrences from the interleaving check. The calls that do
// pair still compare their order exactly. There is no stricter reading
// available: comparing the position of a call one side never made is not a
// question with an answer.
//
// A weakening that forgives nothing **fails as stale**, like every other register
// here, and it is judged on what it alone forgives: two weakenings that overlap
// cannot each ride on the other's back. Note what that costs, and it is the cost
// regions already carry — a weakening is affirmed against the run it is
// committed with, so an entry earning its place in one scenario is stale in a run
// of another. Scoping is how regions answer that; a weakening has no case for it
// yet, and inventing one before the corpus exists would be guessing.

import { difference, diffValues } from "./diff.mjs";
import { OUTCOME } from "./regions.mjs";

/** The two axes a comparison can relax. `arguments` is a region's job — see above. */
export const WEAKENING_AXES = ["count", "order"];

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
    // `axis` rather than regions' `kind`, because it is not regions' taxonomy:
    // a region's kind says what sort of claim it is, and this says which of the
    // three things the comparison asserts is being let go.
    if (!WEAKENING_AXES.includes(weakening.axis)) {
      throw new WeakeningError(
        `${at}: axis ${JSON.stringify(weakening.axis)} is not one of ${WEAKENING_AXES.join(", ")}. ` +
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

    const key = `${weakening.callback}/${weakening.axis}`;
    if (seen.has(key)) {
      throw new WeakeningError(`${at}: ${weakening.callback} already weakens ${weakening.axis}; one of the two could never go stale`);
    }
    seen.add(key);
  });
  return weakenings;
};

// ── Pairing ────────────────────────────────────────────────────────────────
// Which call on one side is *the same call* on the other. Calls of different
// names never pair — a call named `onNodeDrag` cannot be a call named
// `onNodesChange` — so the question is only ever asked within one name.
//
// Within a name, occurrence is the identity: the second `onNodesChange` against
// the second. That is right until the two sides made **the same calls in a
// different sequence**, where it pairs each against the other's partner and
// reports two differences in *arguments*. That is the cascade this module exists
// to avoid, arriving by a different route and in its worst form —
// `onNodesChange` is the highest-volume callback in the corpus, so it would be
// the common case, and invented argument differences read as findings about what
// the two libraries pass.
//
// So a name whose two sides carry the same arguments in a different sequence
// pairs by those arguments instead, and the reordering surfaces one level up as
// the `order` difference it is. That is the same test `diff.mjs` applies to
// keyed DOM children — same keys, different sequence — asked here of a call's
// arguments rather than of an element's id.
//
// A name where both happened at once, a reorder *and* an argument change, pairs
// by occurrence and reports the arguments. Nothing is hidden; the reorder is
// simply not separable from the change without guessing which call became which.

const argumentsOf = (call) => JSON.stringify(call.args);

const sameCalls = (left, right) =>
  left.length === right.length && [...left].sort().join(" ") === [...right].sort().join(" ");

/** The calls of each name on one side, in the order that side made them. */
const groupByName = (calls) => {
  const names = new Map();
  calls.forEach((call, index) => {
    if (!names.has(call.name)) names.set(call.name, []);
    names.get(call.name).push({ call, index });
  });
  return names;
};

/**
 * Pairs one name's calls: by argument where the two sides merely reordered
 * them, by occurrence otherwise. Returns the pairs, and whatever one side made
 * that the other did not.
 */
const pairOneName = (left, right) => {
  const leftArgs = left.map((entry) => argumentsOf(entry.call));
  const rightArgs = right.map((entry) => argumentsOf(entry.call));

  if (sameCalls(leftArgs, rightArgs) && leftArgs.join(" ") !== rightArgs.join(" ")) {
    const queues = new Map();
    right.forEach((entry, i) => {
      if (!queues.has(rightArgs[i])) queues.set(rightArgs[i], []);
      queues.get(rightArgs[i]).push(entry);
    });
    return {
      pairs: left.map((entry, i) => ({ left: entry, right: queues.get(leftArgs[i]).shift() })),
      unpairedLeft: [],
      unpairedRight: [],
    };
  }

  const shared = Math.min(left.length, right.length);
  return {
    pairs: left.slice(0, shared).map((entry, i) => ({ left: entry, right: right[i] })),
    unpairedLeft: left.slice(shared),
    unpairedRight: right.slice(shared),
  };
};

const pairCalls = (left, right) => {
  const leftByName = groupByName(left);
  const rightByName = groupByName(right);
  const pairs = [];
  const unpairedLeft = [];
  const unpairedRight = [];

  for (const name of new Set([...leftByName.keys(), ...rightByName.keys()])) {
    const paired = pairOneName(leftByName.get(name) ?? [], rightByName.get(name) ?? []);
    pairs.push(...paired.pairs);
    unpairedLeft.push(...paired.unpairedLeft);
    unpairedRight.push(...paired.unpairedRight);
  }

  // Back into the order each side made them, so every list below reads the way
  // the trace does.
  const byIndex = (a, b) => a.index - b.index;
  return {
    pairs: pairs.sort((a, b) => byIndex(a.left, b.left)),
    unpairedLeft: unpairedLeft.sort(byIndex),
    unpairedRight: unpairedRight.sort(byIndex),
  };
};

const weakened = (weakenings, axis) =>
  new Set(weakenings.filter((w) => w.axis === axis).map((w) => w.callback));

const diffSequences = (left, right, weakenings, path) => {
  const out = [];
  const forgivenCount = weakened(weakenings, "count");
  const forgivenOrder = weakened(weakenings, "order");

  const { pairs, unpairedLeft, unpairedRight } = pairCalls(left, right);

  // `name#n` labels a *pair*, numbered by where its left call sits among that
  // name's pairs. It is what the order difference carries, and it never reaches
  // a path — paths stay positional, so they address the trace itself.
  const labels = new Map();
  const numbered = new Map();
  for (const pair of pairs) {
    const n = (numbered.get(pair.left.call.name) ?? 0) + 1;
    numbered.set(pair.left.call.name, n);
    labels.set(pair, `${pair.left.call.name}#${n}`);
  }

  // A call with no partner. From the left it reads as missing, from the right as
  // duplicated or spurious; they are one question, and the two kinds say which
  // side made the call.
  for (const entry of unpairedLeft) {
    if (!forgivenCount.has(entry.call.name)) {
      out.push(difference("left-only", [...path, entry.index], entry.call, undefined));
    }
  }
  for (const entry of unpairedRight) {
    if (!forgivenCount.has(entry.call.name)) {
      out.push(difference("right-only", [...path, entry.index], undefined, entry.call));
    }
  }

  // Order is judged over the calls both sides made, so a call one side skipped
  // does not also report as everything after it having moved.
  const sequence = (side) =>
    [...pairs]
      .filter((pair) => !forgivenOrder.has(pair.left.call.name))
      .sort((a, b) => a[side].index - b[side].index)
      .map((pair) => labels.get(pair));
  const leftOrder = sequence("left");
  const rightOrder = sequence("right");
  if (leftOrder.join(" ") !== rightOrder.join(" ")) out.push(difference("order", path, leftOrder, rightOrder));

  for (const pair of pairs) {
    // The whole entry, not only `args`: a field the trace format grows would
    // otherwise be captured and never compared. Reported at the left call's
    // index; the right's is recoverable from the order difference.
    out.push(...diffValues(pair.left.call, pair.right.call, [...path, pair.left.index]));
  }

  return out;
};

/**
 * Compares two `callbacks` sections.
 *
 * Returns `{ differences, outcomes }`. An outcome is `{ weakening, status }`,
 * and only `rides-free` passes — a weakening rides free when the comparison
 * would have reported something without it. Two of regions' three outcomes:
 * a weakening records no values, so there is nothing of it that could have
 * `moved`.
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

