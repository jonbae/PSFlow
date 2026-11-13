// Writes wave-summary.json from the canonical report and coverage file, in
// Order H's shape. Run from the repository root after a full wave.
import { readFileSync, writeFileSync } from 'node:fs';

const report = readFileSync('parity/system/report.md', 'utf8');
const coverage = readFileSync('parity/system/coverage.md', 'utf8');

const results = [...report.matchAll(/^\| `([^`]+)` \| (\w[\w-]*) \| ([^|]+) \| (\d+) \|$/gm)].map(
  ([, scenario, outcome, reason, differences]) => ({
    scenario,
    outcome,
    reason: reason.trim(),
    differences: Number(differences),
  })
);
const sides = [...report.matchAll(/^\| (upstream|psflow) \| 1, 2 \| reproduced \|/gm)].length;
const [, driven, total, holes] = coverage.match(/(\d+) of (\d+)[^\n]*?driven[^\n]*?(\d+) declared hole/) ?? [];

const summary = {
  scenarios: results.length,
  passed: results.filter(({ outcome }) => outcome === 'passed').length,
  failed: results.filter(({ outcome }) => outcome !== 'passed').length,
  selfConsistentSides: sides,
  coverage: [Number(driven), Number(total), Number(holes)],
  failing: results.filter(({ outcome }) => outcome !== 'passed').map(({ scenario }) => scenario),
  results,
};
writeFileSync('aamf/step3/order-i/wave-summary.json', `${JSON.stringify(summary, null, 1)}\n`);
console.log(JSON.stringify({ ...summary, results: undefined }));
