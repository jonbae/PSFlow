// The sections capture does not fill yet — declared, so they cannot be silent.
//
// The trace format requires all seven sections to be present, because an absent
// section would compare as "nothing differed there". A section that is present
// and *empty because nobody built its capture yet* has exactly the same
// problem, and the harness (#35) left five of them that way; `dom` has since
// landed (#51) and its entry is gone, which is the register working.
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
// scenario is almost entirely made of. The four entries left are what the gate
// still cannot see.

/**
 * Each entry says which section, what is missing from it, who lands it, and how
 * to recognise that it has landed. `empty` returning false means the entry is
 * stale.
 */
export const PENDING = [
  {
    // The comparison and the argument serializer landed with #44; what is still
    // missing is the in-page log that accumulates the calls — and the boundary
    // stage (#52) that has to cross the callback props before there is anything
    // to accumulate.
    section: "callbacks",
    what: "the in-page call log; `serialize.mjs` is what it will record with",
    issue: 54,
    empty: (callbacks) => callbacks.length === 0,
  },
  {
    section: "hooks",
    what: "what each probe saw its hooks return",
    issue: 59,
    empty: (hooks) => Object.keys(hooks).length === 0,
  },
  {
    section: "api",
    what: "the imperative queries; `api.calls` is captured, and stays empty until the bridge exists",
    issue: 59,
    empty: (api) => Object.keys(api.queries).length === 0,
  },
  {
    section: "props",
    what: "the props object each probe was handed",
    issue: 59,
    empty: (props) => Object.keys(props).length === 0,
  },
];

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
