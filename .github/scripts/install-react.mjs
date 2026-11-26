// Installs one React release, `react` and `react-dom` together, and proves it
// is the one that landed.
//
// `package.json` declares React as a peer at a caret range and exact-pins it as
// a devDependency. The pin is one release; a range can admit more than one. CI
// runs the whole job once per release the range admits, and this script is how
// each run swaps its release in. A range wider than the releases CI has run is
// a claim held by convention rather than by a check.
//
// It rewrites `package.json` and `package-lock.json` in place, rather than
// installing with `--no-save`, because the net reinstalls from the lockfile:
// `parity/system/linux.mjs` runs `npm ci` in the Playwright image, keyed on the
// lockfile's hash. A run that changed only `node_modules/` would run every gate
// on its release except the net, which would run on the pin.
//
// So run it in a checkout you are about to throw away, or restore the two files
// afterward. Run it after `npm run test:ci`: the self-test reads the committed
// manifest, which this rewrites.
//
// Usage: node .github/scripts/install-react.mjs <version>
//        (refuses a version outside either peer range, before installing.)

import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, join, resolve } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

/** The packages installed together, at one version. */
export const REACT_PACKAGES = ["react", "react-dom"];

const EXACT = /^(\d+)\.(\d+)\.(\d+)$/;

const readJson = (path) => JSON.parse(readFileSync(path, "utf8"));

const parts = (version) => version.match(EXACT).slice(1).map(Number);

const compare = (a, b) => {
  const at = a.findIndex((part, index) => part !== b[index]);
  return at === -1 ? 0 : Math.sign(a[at] - b[at]);
};

/**
 * The lowest release a `^X.Y.Z` range admits.
 *
 * Only that one shape is read. Any other throws rather than being interpreted,
 * because CI's matrix is built from this floor: a range written another way —
 * `>=`, `||`, a prerelease — is a change to which releases need a run, and that
 * change belongs in this script and the matrix, deliberately.
 */
export function caretFloor(range) {
  const floor = /^\^(\d+\.\d+\.\d+)$/.exec(range)?.[1];

  if (floor === undefined) {
    throw new Error(
      `[install-react] ${JSON.stringify(range)} is not a \`^X.Y.Z\` range, the only ` +
        `shape this script reads. The CI matrix is built from the range's floor, so ` +
        `a range of another shape needs this script and the matrix revisited.`
    );
  }
  return floor;
}

/** Whether an exact `version` falls within a `^X.Y.Z` range, by npm's caret rule. */
export function satisfiesCaret(version, range) {
  const floor = parts(caretFloor(range));
  const [major, minor, patch] = floor;
  // The caret holds the leftmost nonzero part fixed.
  const ceiling = major > 0 ? [major + 1, 0, 0] : minor > 0 ? [0, minor + 1, 0] : [0, 0, patch + 1];
  const at = parts(version);

  return compare(at, floor) >= 0 && compare(at, ceiling) < 0;
}

/**
 * Throws unless `version` is an exact release that both peer ranges admit.
 * Returns the ranges it checked against.
 */
export function assertAdmitted(pkg, version) {
  if (!EXACT.test(version ?? "")) {
    throw new Error(
      `[install-react] ${JSON.stringify(version)} is not an exact \`X.Y.Z\` release. ` +
        `Usage: node .github/scripts/install-react.mjs <version>`
    );
  }

  return Object.fromEntries(
    REACT_PACKAGES.map((name) => {
      const range = pkg.peerDependencies?.[name];

      if (range === undefined) {
        throw new Error(`[install-react] package.json declares no \`${name}\` peer dependency.`);
      }
      if (!satisfiesCaret(version, range)) {
        throw new Error(
          `[install-react] ${name} ${version} is outside the declared peer range ` +
            `${range}. CI runs only a release the package claims to support.`
        );
      }
      return [name, range];
    })
  );
}

/**
 * The React version each place that decides what runs reports: the installed
 * packages, and the lockfile entries the net's `npm ci` installs from.
 */
export function installedVersions(root) {
  const lock = readJson(join(root, "package-lock.json"));

  return REACT_PACKAGES.flatMap((name) => [
    [`node_modules/${name}`, readJson(join(root, "node_modules", name, "package.json")).version],
    [`package-lock.json's node_modules/${name}`, lock.packages?.[`node_modules/${name}`]?.version],
  ]);
}

/** Throws unless every place in `installedVersions` reports `version`. */
export function assertInstalled(root, version) {
  const found = installedVersions(root);
  const wrong = found.filter(([, at]) => at !== version);

  if (wrong.length > 0) {
    throw new Error(
      `[install-react] asked for React ${version}, but ` +
        wrong.map(([where, at]) => `${where} is ${at}`).join(", ") +
        `. A run that installed something else would report on a release it did not run.`
    );
  }
  return found;
}

function install(version) {
  const manifest = join(repoRoot, "package.json");
  const ranges = assertAdmitted(readJson(manifest), version);

  execFileSync(
    "npm",
    [
      "install",
      "--save-exact",
      "--ignore-scripts",
      "--no-audit",
      "--no-fund",
      ...REACT_PACKAGES.map((name) => `${name}@${version}`),
    ],
    { cwd: repoRoot, stdio: "inherit" }
  );

  // npm widens a peer range that the saved version falls outside. That cannot
  // happen to an admitted version, and a range that moved would leave every
  // later check reading a claim this run wrote.
  const after = readJson(manifest).peerDependencies;
  for (const [name, range] of Object.entries(ranges)) {
    if (after[name] !== range) {
      throw new Error(`[install-react] the install rewrote the ${name} peer range from ${range} to ${after[name]}.`);
    }
  }

  assertInstalled(repoRoot, version);

  console.log(
    `[install-react] React ${version}: react and react-dom, installed and locked, ` +
      `within the peer ranges ${REACT_PACKAGES.map((name) => `${name} ${ranges[name]}`).join(", ")}`
  );
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  try {
    install(process.argv[2]);
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
