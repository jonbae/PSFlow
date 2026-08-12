// Surface parity — the allowlist, and what it means for an entry to be alive.
//
// The allowlist is the second implementation of a **region** (`CONTEXT.md`, and
// `parity/system/compare/regions.mjs` for the first): one concept, two files,
// because both turn a known difference from a failure into a recorded, reviewed
// fact so that red stays reserved for what is new.
//
// The rule that makes a register a gate rather than a record: **an entry that
// claims nothing fails as stale.** Without it a later boundary stage erases six
// shape divergences, nobody deletes those entries, and the allowlist quietly
// covers differences that no longer exist — so the next real one lands on a
// live entry and passes. Permanent entries are not exempt: a permanent entry
// that stops matching means upstream changed or PSFlow gained the export, and
// either is worth hearing about.
//
// Regions carry a third outcome, *moved* — they record the values they claimed,
// so a difference that changed content has to be re-affirmed. The allowlist has
// no equivalent because it claims *names*, and a name has no content to move.

export class AllowlistError extends Error {
  constructor(message) {
    super(message);
    this.name = "AllowlistError";
  }
}

/**
 * Splits the differences a run found against the entries claiming them.
 *
 * `claimed` and `unclaimed` partition the differences; `stale` is the entries
 * left holding nothing. A run passes on this register only when `unclaimed` and
 * `stale` are both empty.
 */
export const claim = (differences, entries = {}) => {
  const register = entries ?? {};
  const found = new Set(differences);
  const claimed = [];
  const unclaimed = [];
  for (const name of differences) {
    if (Object.hasOwn(register, name)) claimed.push(name);
    else unclaimed.push(name);
  }
  const stale = Object.keys(register).filter((name) => !found.has(name));
  return { claimed: claimed.sort(), unclaimed, stale: stale.sort() };
};

/**
 * The reason a shape divergence is tolerated has to name what will end it —
 * a boundary stage or a ticket. Enforced rather than asked for, because the
 * allowlist is the per-stage progress ledger: "stage 2 is done" means its
 * entries can be deleted and surface parity stays green, which only works if
 * every entry says which stage owns it.
 */
export const RETIRING_EVENT = {
  pattern: /\bstage [1-4]\b|#\d+|\bticket \d+\b/,
  requirement:
    "name the event that retires it — a boundary stage (`stage 2`) or a ticket (`#27`, `ticket 058`)",
};

/** Every entry needs a written reason; some registers need more of it. */
export const validateReasons = (register, entries = {}, extra = null) => {
  for (const [name, reason] of Object.entries(entries ?? {})) {
    if (typeof reason !== "string" || reason.trim() === "") {
      throw new AllowlistError(
        `${register}.${name} has no written reason — an unexplained entry is a dumping ground.`
      );
    }
    if (extra && !extra.pattern.test(reason)) {
      throw new AllowlistError(`${register}.${name}: the reason must ${extra.requirement}.\n  got: ${reason}`);
    }
  }
  return entries ?? {};
};

/**
 * A rename (`upstream member → the PSFlow name standing in for it`) is applied
 * to the upstream set before diffing, so one entry cancels a divergence on both
 * sides. It is alive only while all three of its premises hold: upstream still
 * has the name it translates from, PSFlow still has the name it translates to,
 * and PSFlow does not also publish upstream's own name — in which case the
 * rename cancels nothing and is hiding a genuine extra member.
 */
export const liveRenames = (renames = {}, upstreamMembers, psflowMembers) => {
  const upstream = new Set(upstreamMembers);
  const psflow = new Set(psflowMembers);
  const live = [];
  const stale = [];
  for (const [from, to] of Object.entries(renames ?? {})) {
    const cancels = upstream.has(from) && psflow.has(to) && !psflow.has(from);
    (cancels ? live : stale).push(from);
  }
  return { live: live.sort(), stale: stale.sort() };
};
