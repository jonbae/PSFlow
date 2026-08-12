// Surface parity — two readings of one surface that must name the same set.
//
// The gate reads the JS surface from more places than one, on purpose: the
// boundary manifest, `index.js`'s export list and what importing it yields on
// PSFlow's side; the TypeScript declarations and the bundled sources on
// upstream's. Each pair is worth checking because a *silent* disagreement is
// the failure mode — a manifest that stopped listing what index.js publishes
// scopes every gate that reads it to the wrong set, and a declaration set that
// no longer matches the bundle means the shape comparison is measuring a
// different upstream than the name comparison.
//
// Written once because it was written three times: the third copy is how a
// check acquires a subtly different message and stops meaning the same thing.
// The *reason* stays per-site — `about` says which two readings, `remedy` says
// which file to go and edit — because that is the part a reader needs and the
// part no shared helper can know.

export class DisagreementError extends Error {
  constructor(message) {
    super(message);
    this.name = "DisagreementError";
  }
}

/**
 * Throws unless the two readings name exactly the same set.
 *
 * `left` and `right` are `{ label, names }`; the label completes the sentence
 * "<label> but not <the other label>", so it reads as a phrase and not a noun.
 * A side that agrees is left out of the message rather than printed empty.
 */
export const mustAgree = ({ about, left, right, remedy }) => {
  const leftNames = new Set(left.names);
  const rightNames = new Set(right.names);
  const onlyLeft = [...leftNames].filter((n) => !rightNames.has(n)).sort();
  const onlyRight = [...rightNames].filter((n) => !leftNames.has(n)).sort();
  if (!onlyLeft.length && !onlyRight.length) return;

  throw new DisagreementError(
    [
      about,
      onlyLeft.length ? `  ${left.label} but not ${right.label}: ${onlyLeft.join(", ")}` : null,
      onlyRight.length ? `  ${right.label} but not ${left.label}: ${onlyRight.join(", ")}` : null,
      remedy,
    ]
      .filter((line) => line !== null)
      .join("\n")
  );
};
