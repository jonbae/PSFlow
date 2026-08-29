// Sections capture does not fill yet are declared here, so they cannot be silent.
//
// The trace format requires all seven sections to be present, because an absent
// section would compare as "nothing differed there". A section that is present
// and *empty because nobody built its capture yet* has exactly the same
// problem, and the harness (#35) left five of them that way. `dom` (#51),
// `callbacks` (#54), and finally `hooks`, `api` and `props` (#59) have landed;
// their entries being gone is the register working.
//
// The gaps are written down, and the register behaves the way every other
// register in this repo does: **an entry that stops corresponding to reality
// fails.** Land a section's capture and forget to delete its entry here, and
// the next capture goes red naming the entry rather than quietly shipping a
// trace whose declared-empty section is now full. That inverts the failure — a
// forgotten entry bites instead of rotting — which is the only property that
// makes a declaration worth writing at all.
//
// It is not a substitute for the sections themselves. A comparison between two
// traces whose sections are all empty on both sides reports no differences and
// means nothing, which is why `parity:system` waited for `dom`: it is the
// section that carries 64 of the trace's 156 exports and the one a mount-only
// scenario is almost entirely made of. The register is empty now, and remains
// as the stable guard a future trace-format section must pass through.

/**
 * Each entry says which section, what is missing from it, who lands it, and how
 * to recognise that it has landed. `empty` returning false means the entry is
 * stale.
 */
export const PENDING = [];

export class PendingSectionError extends Error {
  constructor(message) {
    super(message);
    this.name = "PendingSectionError";
  }
}

/**
 * Throws when a section declared pending turns out to carry content — which
 * means its capture landed and the declaration outlived it.
 */
export const assertPendingStillEmpty = (sections) => {
  const landed = PENDING.filter(({ section, empty }) => !empty(sections[section]));
  if (!landed.length) return sections;

  throw new PendingSectionError(
    `capture has landed for ${landed.map((p) => p.section).join(", ")}, but ` +
      `parity/system/harness/pending.mjs still declares ${landed.length === 1 ? "it" : "them"} unbuilt:\n` +
      landed.map((p) => `  - ${p.section}: ${p.what} (#${p.issue})`).join("\n") +
      `\nDelete the entr${landed.length === 1 ? "y" : "ies"}. A declaration nobody removes is a section ` +
      `reported as unobserved while it is being observed.`
  );
};
