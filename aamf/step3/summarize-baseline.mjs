// Read-only triage over the existing comparator. This does not change a gate,
// normalize additional fields, or turn observation groups into proven causes.
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { compareRun } from '../../parity/system/compare/run.mjs';
import { readRun, storedScenarios } from '../../parity/system/net/traces.mjs';

const root = new URL('../../', import.meta.url);
const read = path => JSON.parse(readFileSync(new URL(path, root), 'utf8'));
const traces = fileURLToPath(new URL('parity/system/traces/', root));
const options = {
  rules: read('parity/system/normalization.json').rules,
  regions: read('parity/system/regions.json').regions,
  weakenings: read('parity/system/weakenings.json').weakenings,
};
const runs = storedScenarios(traces).map(id => compareRun(readRun(traces, id), options));
const classify = difference => {
  const path = difference.path;
  if (path.includes('userNode')) return 'original-node-provenance';
  if (path.includes('handleBounds')) return 'handle-bounds';
  if (path[0] === 'callbacks') return 'callback-log';
  if (path[0] === 'dom') return 'dom';
  return `${path[0]}-values`;
};
const groups = new Map();
const scenarioRows = runs.map(run => {
  const unstable = run.consistency.filter(side => !side.consistent);
  const driving = run.failures.some(failure => failure.class === 'driving-divergence');
  const interpretable = !unstable.length && !driving;
  const row = {
    scenario: run.scenario,
    passed: run.ok,
    interpretable,
    classes: [...new Set(run.failures.map(failure => failure.class))],
    selfConsistency: run.consistency.map(side => ({
      side: side.side, consistent: side.consistent, differences: side.differences.length,
      sections: [...new Set(side.differences.map(difference => difference.path[0]))],
      examples: side.differences.slice(0, 3),
    })),
    crossSideDifferences: run.comparison.unclaimed.length,
  };
  // A cross-side difference from an unstable experiment is retained in the
  // canonical report but never enters these implementation-triage groups.
  if (interpretable) {
    for (const difference of run.comparison.unclaimed) {
      const name = classify(difference);
      if (!groups.has(name)) groups.set(name, { name, differences: 0, scenarios: new Set(), examples: [] });
      const group = groups.get(name);
      group.differences++;
      group.scenarios.add(run.scenario);
      if (group.examples.length < 3) group.examples.push({ scenario: run.scenario, ...difference });
    }
  }
  return row;
});
const summary = {
  method: 'Unmodified compareRun with the committed normalization, region, and weakening registers. Groups describe observations, not established root causes. Unstable or differently driven runs are excluded from groups.',
  scenarios: runs.length,
  passed: runs.filter(run => run.ok).length,
  failed: runs.filter(run => !run.ok).length,
  interpretable: scenarioRows.filter(row => row.interpretable).length,
  quarantined: scenarioRows.filter(row => !row.interpretable).map(row => row.scenario),
  groups: [...groups.values()].map(group => ({ ...group, scenarios: [...group.scenarios].sort() })).sort((a, b) => b.scenarios.length - a.scenarios.length),
};
writeFileSync(new URL('baseline/scenarios.json', import.meta.url), JSON.stringify(scenarioRows, null, 2) + '\n');
writeFileSync(new URL('baseline/summary.json', import.meta.url), JSON.stringify(summary, null, 2) + '\n');
console.log(JSON.stringify({ ...summary, groups: summary.groups.map(({ name, differences, scenarios }) => ({ name, differences, scenarios: scenarios.length })) }, null, 2));
