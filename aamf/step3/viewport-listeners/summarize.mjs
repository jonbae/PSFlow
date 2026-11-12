// Read-only evidence projection with the preserved, unchanged gate policy.
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { compareRun } from '../../../parity/system/compare/run.mjs';
import { readRun } from '../../../parity/system/net/traces.mjs';

const read = path => JSON.parse(readFileSync(new URL(path, import.meta.url), 'utf8'));
const options = {
  rules: read('./comparison/normalization.json').rules,
  regions: read('./comparison/regions.json').regions,
  weakenings: read('./comparison/weakenings.json').weakenings,
};
const project = run => {
  const interpretable = run.consistency.every(side => side.consistent) &&
    !run.failures.some(failure => failure.class === 'driving-divergence');
  return {
    passed: run.ok, interpretable,
    selfConsistency: run.consistency.map(side => ({ side: side.side, consistent: side.consistent, differences: side.differences.length })),
    classes: [...new Set(run.failures.map(failure => failure.class))],
    unclaimed: interpretable ? run.comparison.unclaimed.length : null,
    differences: interpretable ? run.comparison.unclaimed : null,
  };
};
const run = (folder, id) => project(compareRun(readRun(fileURLToPath(new URL(folder, import.meta.url)), id), options));
const rows = ['pan-gesture-complete', 'node-props-record-parented'].map(id => ({
  scenario: id,
  beforeSource: id === 'pan-gesture-complete' ? 'stage-5 checkpoint; unstable experiment excluded from cross-side interpretation' : 'W04 checkpoint',
  before: run('./before-captures/', id),
  current: run('./captures/', id),
  ...(id === 'pan-gesture-complete' ? { independentRepeat: run('./captures-repeat/', id) } : {}),
}));
writeFileSync(new URL('./scenario-summary.json', import.meta.url), JSON.stringify(rows, null, 2) + '\n');
console.log(JSON.stringify(rows.map(({ scenario, before, current, independentRepeat }) => ({
  scenario, beforeInterpretable: before.interpretable,
  currentInterpretable: current.interpretable, currentDifferences: current.unclaimed,
  repeatInterpretable: independentRepeat?.interpretable,
  repeatDifferences: independentRepeat?.unclaimed,
})), null, 2));
