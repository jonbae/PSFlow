// Regions — the second of the noise policy's three mechanisms (#19, #40).
//
// Normalization claims what a content-blind rule can claim. A region claims
// everything else: a pattern carrying a written reason, plus a ticket where the
// difference is a known bug. That split is the whole answer to "what stops
// accepted noise becoming a dumping ground" — the baseline is *recorded*, the
// justification is *hand-written*, and the two cannot be produced by the same
// act:
//
//   * Re-recording values under an existing region is cheap.
//   * **Re-recording cannot create a region.** Claiming a new *class* of
//     difference is a reviewed prose change (see `recordRegions`).
//   * **An empty region fails as stale.** Entries bite when they stop
//     corresponding to reality rather than accumulating silently — someone
//     fixed the divergence and left the entry behind, or the fixture stopped
//     exercising it.
//   * A region whose content *moved* fails as needing re-affirmation. On a
//     baseline bump that re-affirm set is the behavioural changelog, and its
//     size is the bump's measured cost.

import { formatPath, matchPath } from "./paths.mjs";

const REGION_KINDS = ["intentional", "known-divergence"];

/** What a region did this run. Only `ridesFree` passes. */
export const OUTCOME = Object.freeze({
  ridesFree: "rides-free",
  stale: "stale",
  moved: "moved",
});

export class RegionError extends Error {
  constructor(message) {
    super(message);
    this.name = "RegionError";
  }
}

export const validateRegions = (regions) => {
  if (!Array.isArray(regions)) throw new RegionError("regions must be an array");
  const seen = new Set();
  regions.forEach((region, i) => {
    const at = `region ${i} (${region?.id ?? "no id"})`;
    if (typeof region?.id !== "string" || region.id === "") throw new RegionError(`${at}: needs an id`);
    if (seen.has(region.id)) throw new RegionError(`${at}: duplicate id ${region.id}`);
    seen.add(region.id);

    if (!REGION_KINDS.includes(region.kind)) {
      throw new RegionError(`${at}: kind ${JSON.stringify(region.kind)} is not one of ${REGION_KINDS.join(", ")}`);
    }
    if (typeof region.reason !== "string" || region.reason === "") {
      throw new RegionError(`${at}: needs a written reason — an unexplained region is a dumping ground`);
    }
    if (region.kind === "known-divergence" && (typeof region.ticket !== "string" || region.ticket === "")) {
      throw new RegionError(`${at}: a known divergence needs a ticket, so the bug stays someone's problem`);
    }
    if (typeof region.path !== "string" || region.path === "") throw new RegionError(`${at}: needs a path pattern`);
    if ("scenario" in region && typeof region.scenario !== "string") {
      throw new RegionError(`${at}: scenario must be a pattern string when present`);
    }
    if (typeof region.affirmedAgainst !== "string" || region.affirmedAgainst === "") {
      throw new RegionError(`${at}: needs the baseline version it was last affirmed against`);
    }
    if (!Array.isArray(region.recorded)) throw new RegionError(`${at}: recorded must be an array`);
  });
  return regions;
};

const matchesScenario = (region, scenario) => {
  const pattern = region.scenario ?? "*";
  return pattern === "*" || pattern === scenario;
};

/** The recorded form of a difference: what `--record` writes and compares. */
export const recordedForm = (difference) => ({
  path: formatPath(difference.path),
  kind: difference.kind,
  left: difference.left,
  right: difference.right,
});

const sameRecording = (a, b) =>
  a.length === b.length &&
  [...a].map((r) => JSON.stringify(r)).sort().join("\n") === [...b].map((r) => JSON.stringify(r)).sort().join("\n");

/**
 * Assigns each difference to the first region whose pattern claims it, and
 * judges every region against what it claimed.
 *
 * Returns `{ claims, unclaimed, outcomes }`. A run passes only when `unclaimed`
 * is empty and every outcome is `rides-free`.
 */
export const claimDifferences = (differences, regions, { scenario }) => {
  validateRegions(regions);

  const claims = new Map(regions.map((r) => [r.id, []]));
  const unclaimed = [];

  for (const difference of differences) {
    // First match wins: a difference claimed twice would let two regions share
    // one justification and neither go stale when the cause is fixed.
    const region = regions.find((r) => matchesScenario(r, scenario) && matchPath(r.path, difference.path));
    if (region) claims.get(region.id).push(difference);
    else unclaimed.push(difference);
  }

  const outcomes = regions.map((region) => {
    const claimed = claims.get(region.id);
    const recording = claimed.map(recordedForm);
    const status =
      claimed.length === 0
        ? OUTCOME.stale
        : sameRecording(recording, region.recorded)
          ? OUTCOME.ridesFree
          : OUTCOME.moved;
    return { region, status, claimed, recording };
  });

  return { claims, unclaimed, outcomes };
};

/** A comparison passes when nothing is unclaimed and every region rode free. */
export const passes = ({ unclaimed, outcomes }) =>
  unclaimed.length === 0 && outcomes.every((o) => o.status === OUTCOME.ridesFree);

/**
 * Refreshes the recorded values of regions that claimed something, and stamps
 * them with the baseline they were affirmed against.
 *
 * What it deliberately does not do: create a region. An unclaimed difference is
 * still unclaimed after recording, so a real divergence cannot be absorbed by
 * rerunning the recorder.
 */
export const recordRegions = (regions, { outcomes }, { baseline }) => {
  const byId = new Map(outcomes.map((o) => [o.region.id, o]));
  return regions.map((region) => {
    const outcome = byId.get(region.id);
    if (!outcome || outcome.status !== OUTCOME.moved) return region;
    return { ...region, affirmedAgainst: baseline, recorded: outcome.recording };
  });
};
