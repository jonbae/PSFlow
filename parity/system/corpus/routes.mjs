// How a route and a scenario id are derived, for every source of the corpus.
//
// Split out of `mount-baselines.mjs` because the **conformance seed** needs the
// same two answers: a seed scenario names the fixture it drives by the same
// registry key its baseline does, and the two must land on the same route or
// the corpus would be driving one page and comparing another.

export class CorpusError extends Error {
  constructor(message) {
    super(message);
    this.name = "CorpusError";
  }
}

/** Upstream's own route for the generic fixtures, kept so a lifted spec changes only its origin. */
export const ROUTE_PREFIX = "/tests/generic";

/** `./nodes/general.ts` — the registry's key — is `/tests/generic/nodes/general` to the page. */
export const routeOf = (fixture) => `${ROUTE_PREFIX}${fixture.replace(/^\./, "").replace(/\.ts$/, "")}`;

/**
 * `./pane/non-defaults.ts` becomes `mount-baseline--pane-non-defaults`, and a
 * directly mounted component's `/examples/color-mode` becomes
 * `mount-baseline--examples-color-mode`.
 *
 * `--` separates the kind of scenario from what it runs against, and the path's
 * own separators flatten to `-`. Semantic throughout: a gate cites scenarios by
 * name, and a number would move the moment the corpus is trimmed.
 *
 * The two kinds of input differ only in their prefix — a fixture's registry key
 * leads with `./` and a component's route with `/` — so one rule strips either.
 */
export const idOf = (path) =>
  `mount-baseline--${path
    .replace(/^\.?\//, "")
    .replace(/\.ts$/, "")
    .split("/")
    .join("-")}`;
