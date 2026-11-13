// Read-only comparison using the existing, unchanged gate registers.
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
const project = run => ({
  passed: run.ok,
  selfConsistency: run.consistency.map(side => ({ side: side.side, consistent: side.consistent, differences: side.differences.length })),
  classes: [...new Set(run.failures.map(failure => failure.class))],
  unclaimed: run.comparison.unclaimed.length,
  userNodeDifferences: run.comparison.unclaimed.filter(difference => difference.path.includes('userNode')),
  differences: run.comparison.unclaimed,
});
const result = ['node-props-record-parented', 'mount-baseline--nodes-unmeasured'].map(id => ({
  scenario: id,
  stage5: project(compareRun(readRun(fileURLToPath(new URL('./before-captures/', import.meta.url)), id), options)),
  w04: project(compareRun(readRun(fileURLToPath(new URL('./captures/', import.meta.url)), id), options)),
}));
writeFileSync(new URL('./scenario-summary.json', import.meta.url), JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify(result.map(({ scenario, stage5, w04 }) => ({
  scenario, before: stage5.unclaimed, after: w04.unclaimed,
  beforeUserNode: stage5.userNodeDifferences.length, afterUserNode: w04.userNodeDifferences.length,
  selfConsistency: w04.selfConsistency,
})), null, 2));
