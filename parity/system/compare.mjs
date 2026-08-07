// System parity — the compare step (#40).
//
//   node parity/system/compare.mjs <left-trace.json> <right-trace.json> [options]
//
//     --out <path>   also write the report to a file
//     --record       write refreshed values back into the regions whose content
//                    moved, and stamp them with this run's baseline. It cannot
//                    create a region: an unclaimed difference is still unclaimed
//                    after recording, and still fails.
//
// Exit codes: 0 clean, 1 differences the noise policy does not claim (or a
// region gone stale), 2 the run could not be interpreted at all — a malformed
// trace, an illegal normalization rule, a region missing its reason.

import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { readTrace } from "./trace-format.mjs";
import { compareTraces } from "./compare/index.mjs";
import { renderReport } from "./compare/report.mjs";
import { claimDifferences, recordRegions } from "./compare/regions.mjs";

// The ruleset and the register are fixed, not switchable by flag: a run must
// not be able to compare against a laxer noise policy than the committed one.
// The comparison core takes both as arguments, so its own tests supply theirs
// directly rather than pointing this script somewhere else.
const here = dirname(fileURLToPath(import.meta.url));
const NORMALIZATION = join(here, "normalization.json");
const REGIONS = join(here, "regions.json");

const readJson = (path) => JSON.parse(readFileSync(path, "utf8"));

const argv = process.argv.slice(2);
const flags = new Set(argv.filter((a) => a.startsWith("--")));
const outIndex = argv.indexOf("--out");
const out = outIndex === -1 ? null : argv[outIndex + 1];
const positional = argv.filter((a, i) => !a.startsWith("--") && !(outIndex !== -1 && i === outIndex + 1));

if (positional.length !== 2 || (flags.has("--out") && (!out || out.startsWith("--")))) {
  console.error("usage: node parity/system/compare.mjs <left-trace.json> <right-trace.json> [--out report.md] [--record]");
  process.exit(2);
}

try {
  const [leftTrace, rightTrace] = positional.map(readTrace);
  const rules = readJson(NORMALIZATION).rules;
  const regions = readJson(REGIONS).regions;

  let result = compareTraces(leftTrace, rightTrace, { rules, regions });

  if (flags.has("--record")) {
    const rerecorded = recordRegions(regions, result, { baseline: rightTrace.baseline });
    writeFileSync(REGIONS, JSON.stringify({ ...readJson(REGIONS), regions: rerecorded }, null, 2) + "\n");
    const reclaimed = claimDifferences(result.differences, rerecorded, { scenario: result.scenario });
    result = {
      ...result,
      ...reclaimed,
      ok: reclaimed.unclaimed.length === 0 && reclaimed.outcomes.every((o) => o.status === "rides-free"),
    };
  }

  const report = renderReport(result);
  console.log(report);
  if (out) writeFileSync(out, report.endsWith("\n") ? report : report + "\n");

  process.exit(result.ok ? 0 : 1);
} catch (e) {
  // A run that cannot be interpreted is its own outcome, and never a pass.
  console.error(e.message ?? e);
  process.exit(2);
}
