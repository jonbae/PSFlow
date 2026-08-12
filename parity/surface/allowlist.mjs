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
  const found = new Set(differences);
  const claimed = [];
  const unclaimed = [];
  for (const name of differences) {
    if (Object.hasOwn(entries, name)) claimed.push(name);
    else unclaimed.push(name);
  }
  const stale = Object.keys(entries).filter((name) => !found.has(name));
  return { claimed: claimed.sort(), unclaimed, stale: stale.sort() };
};

/**
 * The reason a shape divergence is tolerated has to name what will end it —
 * a boundary stage or a ticket. Enforced rather than asked for, because the
 * allowlist is the per-stage progress ledger: "stage 2 is done" means its
 * entries can be deleted and surface parity stays green, which only works if
 * every entry says which stage owns it.
 */
// A floor, not a proof: the pattern cannot tell a ticket that *retires* the
// divergence from one that merely records it, so it catches the entry that
// names nothing and leaves the rest to a reader. Tightening it further would
// mean encoding which ticket numbers are stages, which goes stale faster than
// the entries it polices.
export const RETIRING_EVENT = {
  pattern: /\bstage [1-4]\b|#\d+|\bticket \d+\b/,
  requirement:
    "name the event that retires it — a boundary stage (`stage 2`) or a ticket (`#27`, `ticket 058`)",
};

/** Every entry needs a written reason; some registers demand more of it. */
export const validateReasons = (register, entries = {}, rule = null) => {
  for (const [name, reason] of Object.entries(entries)) {
    if (typeof reason !== "string" || reason.trim() === "") {
      throw new AllowlistError(
        `${register}.${name} has no written reason — an unexplained entry is a dumping ground.`
      );
    }
    if (rule && !rule.pattern.test(reason)) {
      throw new AllowlistError(`${register}.${name}: the reason must ${rule.requirement}.\n  got: ${reason}`);
    }
  }
};

/**
 * A rename (`upstream member → the PSFlow name standing in for it`) is applied
 * to the upstream set before diffing, so one entry cancels a divergence on both
 * sides. It is alive only while all three of its premises hold: upstream still
 * has the name it translates from, PSFlow still has the name it translates to,
 * and PSFlow does not also publish upstream's own name — in which case the
 * rename cancels nothing and is hiding a genuine extra member.
 *
 * `live` holds the surviving pairs rather than their upstream halves, so a
 * caller reporting them does not have to go back to the register for the other
 * half of something this function already had in hand.
 */
export const liveRenames = (renames = {}, upstreamMembers, psflowMembers) => {
  const upstream = new Set(upstreamMembers);
  const psflow = new Set(psflowMembers);
  const live = [];
  const stale = [];
  for (const [from, to] of Object.entries(renames)) {
    const cancels = upstream.has(from) && psflow.has(to) && !psflow.has(from);
    if (cancels) live.push([from, to]);
    else stale.push(from);
  }
  return { live: live.sort(([a], [b]) => a.localeCompare(b)), stale: stale.sort() };
};
