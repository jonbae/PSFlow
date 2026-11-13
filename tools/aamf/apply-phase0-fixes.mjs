import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';

const aamfRoot = process.argv[2] && resolve(process.argv[2]);
assert.ok(aamfRoot, 'Usage: node tools/aamf/apply-phase0-fixes.mjs <AAMF checkout>');
const loreRoot = join(aamfRoot, 'node_modules/@jafreck/lore');
const metadata = JSON.parse(await readFile(join(loreRoot, 'package.json'), 'utf8'));
assert.equal(metadata.version, '0.4.2', 'Only the reviewed Lore 0.4.2 distribution is supported');
const hash = text => createHash('sha256').update(text).digest('hex');
function replaceOnce(text, before, after) {
  assert.equal(text.split(before).length - 1, 1, `Expected exactly one patch context: ${before.slice(0, 90)}`);
  return text.replace(before, after);
}

const patches = [
  {
    path: 'dist/indexer/stages/scip-indexer.js',
    originalHash: 'f40bbe5fc9577bc14d9ce8ebf401b6bab17e93c795e9d86b7c2a9a3165e6cf4d',
    changes: [
      [
        'endCharacter: endChar, enclosingRange: [...occ.enclosingRange]',
        'endCharacter: endChar, selectionEndLine: occ.range.length === 4 ? occ.range[2] : occ.range[0], enclosingRange: [...occ.enclosingRange]',
      ],
      [
        'const { symbol, line, character, endCharacter, enclosingRange, symbolRoles: occRoles } = occ;',
        'const { symbol, line, character, endCharacter, selectionEndLine, enclosingRange, symbolRoles: occRoles } = occ;',
      ],
      [
        '                    // Prefer a real definition over an earlier same-file prototype.',
        `                    // PSFlow compatibility: enclosingRange can describe a variable's
                    // initializer. Retain that context and include the actual name range.
                    if (line < startLine || (line === startLine && character < startCharacter)) {
                        startLine = line;
                        startCharacter = character;
                    }
                    if (selectionEndLine > endLine || (selectionEndLine === endLine && endCharacter > spanEndCharacter)) {
                        endLine = selectionEndLine;
                        spanEndCharacter = endCharacter;
                    }
                    // Prefer a real definition over an earlier same-file prototype.`,
      ],
    ],
  },
  {
    path: 'dist/validation/index-health.js',
    originalHash: 'f74ba9293619e9aa42d4115dc55b535a5a1a9df3cb32ed5fa9e8d7885fac456f',
    changes: [
      [
        "import { validateScipScope } from './scip-scope.js';",
        "import { validateScipScope } from './scip-scope.js';\nimport { findReexportOnlyFiles } from './psflow-reexports.js';",
      ],
      [
        '    const symbolLessRows = selected.filter((row) => row.symbols === 0);',
        `    const symbolLessRows = selected.filter((row) => row.symbols === 0);
    const reexportOnlyRows = findReexportOnlyFiles(db, relations.files, rows, provenance, scipScope)
        .filter(row => selectedIds.has(row.id));
    const reexportOnlyIds = new Set(reexportOnlyRows.map(row => row.id));
    const unexpectedSymbolLessRows = symbolLessRows.filter(row => !reexportOnlyIds.has(row.id));`,
      ],
      [
        '        selected,\n        symbolLessRows,\n        invalidSpanRows,',
        '        selected,\n        symbolLessRows: unexpectedSymbolLessRows,\n        invalidSpanRows,',
      ],
      [
        "    evaluateThresholds('overall', overall, policy.thresholds, {\n",
        "    evaluateThresholds('overall', overall, policy.thresholds, {\n        expectedSymbolLessFiles: reexportOnlyRows.length,\n",
      ],
      [
        '        evaluateThresholds(`language:${language}`, byLanguage[language] ?? emptyCoverage(), thresholds, {\n',
        '        evaluateThresholds(`language:${language}`, byLanguage[language] ?? emptyCoverage(), thresholds, {\n            expectedSymbolLessFiles: reexportOnlyRows.filter(row => row.language === language).length,\n',
      ],
      [
        '            total: symbolLessRows.length,\n            files: symbolLessSamples,',
        `            total: symbolLessRows.length,
            unexpectedTotal: unexpectedSymbolLessRows.length,
            reexportOnly: {
                total: reexportOnlyRows.length,
                files: reexportOnlyRows.slice(0, maxSamples).map(toFileSample),
                truncated: reexportOnlyRows.length > maxSamples,
            },
            files: symbolLessSamples,`,
      ],
      [
        "['maxSymbolLessFiles', metrics.symbolLessFiles, 'symbol-less files'],",
        "['maxSymbolLessFiles', metrics.symbolLessFiles - (extras.expectedSymbolLessFiles ?? 0), 'unexpected symbol-less files'],",
      ],
    ],
  },
];

// Validate every input before writing. Reversing our exact edits also permits
// an idempotent reapply, while rejecting any unrelated dependency modification.
const plans = [];
for (const patch of patches) {
  const path = join(loreRoot, patch.path);
  const current = await readFile(path, 'utf8');
  let original = current;
  if (hash(original) !== patch.originalHash) {
    for (const [before, after] of [...patch.changes].reverse()) original = replaceOnce(original, after, before);
  }
  assert.equal(hash(original), patch.originalHash, `Unrecognized dependency contents: ${path}`);
  let patched = original;
  for (const [before, after] of patch.changes) patched = replaceOnce(patched, before, after);
  plans.push({ path, relativePath: patch.path, originalHash: patch.originalHash, patchedHash: hash(patched), current, patched });
}
const helperPath = join(loreRoot, 'dist/validation/psflow-reexports.js');
const helper = await readFile(new URL('./reexport-only.mjs', import.meta.url), 'utf8');
let existingHelper;
try { existingHelper = await readFile(helperPath, 'utf8'); } catch (error) { if (error.code !== 'ENOENT') throw error; }
assert.ok(existingHelper === undefined || existingHelper === helper, 'Unrecognized existing re-export helper');
if (existingHelper !== helper) await writeFile(helperPath, helper);
for (const plan of plans) if (plan.current !== plan.patched) await writeFile(plan.path, plan.patched);
console.log(JSON.stringify({
  loreVersion: metadata.version,
  files: plans.map(({ relativePath, originalHash, patchedHash }) => ({ path: relativePath, originalHash, patchedHash })),
  helper: { path: 'dist/validation/psflow-reexports.js', sha256: hash(helper) },
}, null, 2));
