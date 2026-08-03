// Changelog audit — entry extractor. Reads the vendored `@xyflow/react` and
// `@xyflow/system` CHANGELOGs and emits every changelog entry published *above*
// the version PSFlow was originally ported against, keyed by PR number.
//
// Emits `entries.json` (gitignored — regenerated, needs `xyflow/`):
//   { reactVersion, systemVersion, floors: {...},
//     entries: { "<pr>": { pkg, version, title } } }
//
// The committed half of this audit is `verdicts.json` + `report.md`, both of
// which embed the PR titles, so review survives a clean clone without `xyflow/`.
//
// Floors are the versions PSFlow ported against, and are *exclusive*: their own
// entries were part of the original port, so the audit starts above them.
// `@xyflow/react` 12.3.5 shipped with `@xyflow/system` 0.0.46 (12.4.0 is the
// release that bumped the dependency to 0.0.47).

import { fileURLToPath } from "node:url";
import { dirname, resolve, join } from "node:path";
import { readFileSync, writeFileSync, existsSync } from "node:fs";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");
const xyflow = (p) => join(repoRoot, "xyflow", p);

const PACKAGES = [
  { pkg: "react", dir: "packages/react", floor: "12.3.5" },
  { pkg: "system", dir: "packages/system", floor: "0.0.46" },
];

// `- [#5677](…pull/5677) [`e6661de`](…commit/…) [Thanks [@user](…)! ]- <title>`
//
// The `Thanks` clause is present on some entries and absent on others; both
// forms end with ` - ` before the prose. `- Updated dependencies [[`…`]]:`
// roll-ups carry no `[#pr]` and so fail this match for free.
const ENTRY_RE = /^- \[#(\d+)\]\([^)]*\)\s+\[`[^`]+`\]\([^)]*\)\s*(?:Thanks\s+\[@[^\]]*\]\([^)]*\)!)?\s*-\s*(.+?)\s*$/;
const VERSION_RE = /^## (\S+)\s*$/;

const missing = PACKAGES.map((p) => xyflow(`${p.dir}/CHANGELOG.md`)).filter((p) => !existsSync(p));
if (missing.length) {
  console.error("[extract-entries] FAIL: vendored xyflow/ CHANGELOGs not found:");
  for (const m of missing) console.error(`  - ${m}`);
  console.error(
    "\n`xyflow/` is gitignored and does not survive a clean clone. Restore the\n" +
      "vendored checkout to regenerate; the committed audit artifacts are\n" +
      "parity/changelog-audit/{verdicts,report}.md."
  );
  process.exit(1);
}

const readJson = (p) => JSON.parse(readFileSync(p, "utf8"));
const reactVersion = readJson(xyflow("packages/react/package.json")).version;
const systemVersion = readJson(xyflow("packages/system/package.json")).version;

// PRs are deduped across packages: a single PR touching both packages appears
// in both CHANGELOGs with the same title. `react` is scanned first, so a shared
// PR is attributed there — the verdict is about the change, not the package.
const entries = {};
const stats = {};

for (const { pkg, dir, floor } of PACKAGES) {
  const src = readFileSync(xyflow(`${dir}/CHANGELOG.md`), "utf8");
  let version = null;
  let reachedFloor = false;
  let found = 0;

  for (const line of src.split("\n")) {
    const v = VERSION_RE.exec(line);
    if (v) {
      if (v[1] === floor) {
        reachedFloor = true;
        break;
      }
      version = v[1];
      continue;
    }
    const m = ENTRY_RE.exec(line);
    if (!m) continue;
    found++;
    const [, pr, title] = m;
    if (entries[pr]) continue; // already attributed to an earlier package
    entries[pr] = { pkg, version, title };
  }

  if (!reachedFloor) {
    console.error(
      `[extract-entries] FAIL: never reached floor version ${floor} in ${pkg} CHANGELOG.\n` +
        "The floor is exclusive and must exist as a `## <version>` header. If the\n" +
        "vendored checkout no longer contains it, the audit range is wrong."
    );
    process.exit(1);
  }
  stats[pkg] = found;
}

const output = {
  reactVersion,
  systemVersion,
  floors: Object.fromEntries(PACKAGES.map((p) => [p.pkg, p.floor])),
  entries,
};

const outPath = join(here, "entries.json");
writeFileSync(outPath, JSON.stringify(output, null, 2) + "\n");

const total = Object.keys(entries).length;
console.log(
  `[extract-entries] react ${reactVersion} (>${PACKAGES[0].floor}) / system ${systemVersion} (>${PACKAGES[1].floor}): ` +
    `${stats.react} react + ${stats.system} system entries → ${total} unique PRs → ${outPath}`
);
