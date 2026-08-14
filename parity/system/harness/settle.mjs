// Settling — waiting until the page has stopped changing, on the page's own
// clock (#51).
//
// **Settled** is defined by observation, not by a duration: poll the `dom`
// section until consecutive snapshots agree. There is no wall-clock constant
// anywhere in this file, and that is the point. A fixed wait is a bet that one
// implementation is not slower than the other, and losing it silently is the
// worst outcome available — the slow side gets captured mid-mount and every
// section diverges at once, which reads as a library that renders nothing like
// the other rather than as a harness that did not wait.
//
// So each side settles on its own clock. The two are never synchronised and
// nothing here compares them; that a slow side and a fast side reach the same
// end state is precisely the claim the net is making, and it cannot be made by
// a harness that pinned both to one stopwatch.
//
// Between polls the harness asks the port to `tick`, which yields to the page's
// own frame loop rather than to a timer of ours. What that buys is described
// there.
//
// Two things depend on this, and both are load-bearing:
//
//   * **Self-consistency.** A side is captured twice and has to reproduce
//     itself exactly. A capture taken while React was still committing is
//     reproducible only by luck, so without settling the strictest check in the
//     net becomes a coin toss and the trace baseline it protects means nothing.
//   * **Targeting.** Selectors resolve against each side's own render, so an
//     action driven before the flow settles aims at a layout that is about to
//     move. That is why the harness settles *before acting* as well as before
//     capturing.

/** How many polls a page gets before never-settling becomes a person's problem. */
export const SETTLE_POLLS = 200;

/** Snapshots that must agree in a row. Two is "consecutive snapshots agree". */
export const SETTLE_AGREEMENTS = 2;

export class SettleError extends Error {
  /**
   * `previous` and `latest` are the two snapshots that were still disagreeing
   * when the ceiling was reached — carried on the error rather than rendered
   * into it, because a whole DOM subtree is not a sentence and the caller is
   * better placed to decide what to do with one.
   */
  constructor(message, { previous = null, latest = null, polls = 0 } = {}) {
    super(message);
    this.name = "SettleError";
    this.previous = previous;
    this.latest = latest;
    this.polls = polls;
  }
}

// Structural equality over two snapshots of one selector by one function, so
// key order is the same on both sides by construction and a string comparison
// is an honest one. Nothing is normalized here: settling asks whether the page
// changed, and the noise policy's opinion about which changes matter belongs
// downstream, where revising it does not need a browser.
const agree = (a, b) => JSON.stringify(a) === JSON.stringify(b);

/**
 * Polls `port.dom(selector)` until `agreements` consecutive snapshots are
 * identical, and returns the settled one — which *is* the snapshot the trace
 * records, so nothing can be captured that was never observed to be stable.
 *
 * Throws `SettleError` once `polls` have gone by without that happening. A page
 * that never stops changing is a question for a person: proceeding anyway would
 * record a snapshot known to be mid-flight, and every alternative to throwing is
 * a fixed timeout wearing a different hat.
 */
export const settleDom = async (port, selector, { agreements = SETTLE_AGREEMENTS, polls = SETTLE_POLLS } = {}) => {
  if (!Number.isInteger(agreements) || agreements < 2) {
    throw new SettleError(
      `settling needs at least two agreeing snapshots, got ${JSON.stringify(agreements)} — one snapshot ` +
        `is a single observation, and "the page has stopped changing" cannot be established from one`
    );
  }

  let previous = await port.dom(selector);
  let latest = previous;
  let agreed = 1;

  for (let poll = 1; poll <= polls; poll++) {
    await port.tick();
    previous = latest;
    latest = await port.dom(selector);

    agreed = agree(previous, latest) ? agreed + 1 : 1;
    if (agreed >= agreements) return latest;
  }

  throw new SettleError(
    `${selector} never settled: ${polls} polls of the page's own frame clock, and no ${agreements} ` +
      `consecutive snapshots agreed. Something on the page is still changing — an animation writing to ` +
      `the DOM, a render loop, a resize that never converges. Capturing anyway would record a snapshot ` +
      `known to be mid-flight, so this is a question for a person rather than a longer wait.`,
    { previous, latest, polls }
  );
};
