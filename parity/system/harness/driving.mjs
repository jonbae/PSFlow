// The driving log — the receipt for the input side (#26, #35).
//
// Targets are selectors, and **each side resolves them against its own
// render**, so the pointer follows a divergence: two sides that place a node
// five pixels apart both drag successfully and the DOM diff looks clean, while
// the two runs were not the same experiment. This section is what recovers
// that. It carries no exports; it records what was done *to* the page rather
// than how the page responded.
//
// Two rules shape it, and both are load-bearing:
//
//   * **An unresolved target is recorded, never thrown.** The action is
//     skipped and driving continues. A missing element is one of the most
//     interesting divergences available, and left alone it would surface as a
//     Playwright timeout, which reads as a flake.
//   * **Every entry carries all five fields.** A capture that quietly stopped
//     writing one would compare clean on both sides — the print-instead-of-fail
//     mistake this repo has already paid for twice. `target`, `box` and
//     `dispatched` are nullable, because an imperative call has no target and
//     an unresolved one has no box.
//
// The log joins the self-consistency check with **no tolerance applied**
// (#43): a side whose resolved boxes wobble between its own two captures fails
// against itself, which is the measured-DOM-dimensions question asked in the
// cheapest form it has.

export class DrivingLogError extends Error {
  constructor(message) {
    super(message);
    this.name = "DrivingLogError";
  }
}

export const createDrivingLog = () => {
  const entries = [];

  /**
   * Records one action. `target`, `box` and `dispatched` default to null;
   * `action` and `resolved` are required, and a `resolved: false` entry must
   * carry neither a box nor a dispatch, because nothing was measured and
   * nothing was sent.
   *
   * Returns the frozen entry, so a caller that wants to log and then act on
   * what it recorded does not have to reconstruct it.
   */
  const record = ({ action, target = null, resolved, box = null, dispatched = null }) => {
    if (typeof action !== "string" || action === "") {
      throw new DrivingLogError(`a driving entry needs an action name, got ${JSON.stringify(action)}`);
    }
    if (typeof resolved !== "boolean") {
      throw new DrivingLogError(`${action}: a driving entry must say whether its target resolved`);
    }
    if (target !== null && typeof target !== "string") {
      throw new DrivingLogError(`${action}: a target is a selector or null, got ${JSON.stringify(target)}`);
    }
    if (resolved) {
      // A resolved action that dispatched nothing is an action that did not
      // happen — and the log is the only place that would have said so.
      if (dispatched === null) {
        throw new DrivingLogError(`${action}: resolved, but the entry does not say what was dispatched`);
      }
    } else {
      if (box !== null) {
        throw new DrivingLogError(`${action}: unresolved, but carries the box it supposedly resolved to`);
      }
      if (dispatched !== null) {
        throw new DrivingLogError(`${action}: unresolved, but claims something was dispatched`);
      }
    }

    const entry = Object.freeze({ index: entries.length, action, target, resolved, box, dispatched });
    entries.push(entry);
    return entry;
  };

  return {
    record,
    /** The section, as it goes into a trace. A copy: the log owns its own length. */
    entries: () => [...entries],
  };
};
