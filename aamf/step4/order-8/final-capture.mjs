// Refresh the owned witnesses after the full wave. This includes the three
// baselines whose fixture inputs were strengthened during the reversion audit.
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { orderEightScenarios } from '../../../parity/system/corpus/order-eight.mjs';

const root = fileURLToPath(new URL('../../../', import.meta.url));
const ids = [...orderEightScenarios.map(s => s.id),
  'mount-baseline--flow-remount',
  'mount-baseline--nodes-selection-state',
  'mount-baseline--nodes-selection-on-drag',
];
const child = spawnSync(process.execPath, ['aamf/step4/order-8/capture.mjs',
  'parity/system/traces', ...ids], { cwd: root, stdio: 'inherit' });
if (child.error) throw child.error;
process.exitCode = child.status ?? 1;
