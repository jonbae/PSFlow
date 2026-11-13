// Read-only W11 report: compare the preserved experiments with the unchanged policy.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { compareRun } from '../../../parity/system/compare/run.mjs';
import { readRun } from '../../../parity/system/net/traces.mjs';
const read = path => JSON.parse(readFileSync(new URL(path, import.meta.url), 'utf8'));
const options = { rules: read('./comparison/normalization.json').rules, regions: read('./comparison/regions.json').regions, weakenings: read('./comparison/weakenings.json').weakenings };
const project = run => {
 const interpretable = run.consistency.every(side => side.consistent) && !run.failures.some(f => f.class === 'driving-divergence');
 return { passed: run.ok, interpretable, consistency: run.consistency, classes: [...new Set(run.failures.map(f => f.class))], differences: interpretable ? run.comparison.unclaimed : null };
};
const run = (folder, id) => existsSync(new URL(`${folder}/${id}.psflow.capture2.json`, import.meta.url)) ? project(compareRun(readRun(fileURLToPath(new URL(folder, import.meta.url)), id), options)) : null;
const rows = read('./task.json').scenarios.map(scenario => ({ scenario, before: run('./before-captures', scenario), current: run('./captures', scenario), repeat: run('./captures-repeat', scenario) }));
writeFileSync(new URL('./scenario-summary.json', import.meta.url), JSON.stringify(rows, null, 2) + '\n');
console.log(JSON.stringify(rows.map(({scenario,...runs}) => ({ scenario, ...Object.fromEntries(Object.entries(runs).map(([name,r]) => [name,r && {interpretable:r.interpretable, consistency:r.consistency.map(s=>({side:s.side,consistent:s.consistent,differences:s.differences.length})), unclaimed:r.differences?.length}])) })), null, 2));
