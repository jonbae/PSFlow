// Vendors the **parity baseline** — the `xyflow/` checkout the three parity
// gates compare against — from the release tag named by the exact-pinned
// `@xyflow/*` devDependencies.
//
// `xyflow/` is gitignored, so a fresh clone has no baseline and CI has nothing
// for surface parity to compare against. That leaves CI needing the version
// written down somewhere, and a version written down twice is a version that
// drifts. So this reads the pin rather than carrying one: `package.json` is
// already the declared baseline ("a **parity baseline pin**, not a build
// dependency" — README), and this makes it the thing CI actually resolves.
//
// The tag names the react version only; the system version rides along on
// whatever commit it points at. The baseline is both, so the extracted tree is
// checked against both pins — a tag whose commit carries a different
// `@xyflow/system` is a different baseline than the one this repo declares,
// and it would otherwise arrive silently and reshape every parity gate at once.
//
// Usage: node .github/scripts/vendor-baseline.mjs
//        (refuses to touch an existing `xyflow/`: `rm -rf xyflow` first, which
//        is what a bump does anyway — delete and re-vendor, never a merge.)

import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, join, resolve } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");

/** The two packages the baseline is pinned at, and where each one's version lives. */
const PACKAGES = {
  react: { dependency: "@xyflow/react", manifest: "packages/react/package.json" },
  system: { dependency: "@xyflow/system", manifest: "packages/system/package.json" },
};

/** An exact version, with an optional prerelease tail. Not a range — see below. */
const EXACT = /^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/;

const readJson = (path) => JSON.parse(readFileSync(path, "utf8"));

/**
 * The declared baseline, read from `package.json`'s devDependencies.
 *
 * A range is refused rather than resolved. README: "Do not add a caret: a
 * floating range would let `npm install` drift the declared baseline away from
 * the vendored one without any gate noticing." Here it is worse — the pin is
 * what the tag is built from, so a range would make the vendored tree
 * unreproducible between two runs of the same commit.
 */
export function baselinePins(pkg) {
  const devDependencies = pkg.devDependencies ?? {};

  return Object.fromEntries(
    Object.entries(PACKAGES).map(([key, { dependency }]) => {
      const declared = devDependencies[dependency];

      if (declared === undefined) {
        throw new Error(
          `[vendor-baseline] package.json declares no \`${dependency}\` devDependency. ` +
            `It is the parity baseline pin, and the vendored tree is resolved from it.`
        );
      }
      if (!EXACT.test(declared)) {
        throw new Error(
          `[vendor-baseline] \`${dependency}\` is pinned at ${JSON.stringify(declared)}, ` +
            `which is a range and not an exact version. The parity baseline must name ` +
            `one version: it is what the vendored tree is downloaded from.`
        );
      }
      return [key, declared];
    })
  );
}

/**
 * The source tarball for a react version's release tag.
 *
 * The tag is `@xyflow/react@<version>` — two `@` and a `/`, all of which are
 * path-significant to codeload, so it goes over as one encoded segment.
 */
export function tarballUrl(reactVersion) {
  const tag = encodeURIComponent(`${PACKAGES.react.dependency}@${reactVersion}`);

  return `https://codeload.github.com/xyflow/xyflow/tar.gz/refs/tags/${tag}`;
}

/**
 * What the tree that landed actually says its versions are, checked against
 * what was asked for. Returns them, so a caller can report the baseline it got
 * rather than the baseline it requested.
 */
export function assertVendoredVersions(dir, pins) {
  const found = Object.fromEntries(
    Object.entries(PACKAGES).map(([key, { manifest }]) => {
      const path = join(dir, manifest);

      if (!existsSync(path)) {
        throw new Error(
          `[vendor-baseline] the extracted tree has no ${manifest}. ` +
            `${dir} is not an @xyflow/xyflow checkout.`
        );
      }
      return [key, readJson(path).version];
    })
  );

  for (const [key, { dependency }] of Object.entries(PACKAGES)) {
    if (found[key] !== pins[key]) {
      throw new Error(
        `[vendor-baseline] the vendored tree is ${dependency} ${found[key]}, but ` +
          `package.json pins ${pins[key]}. The tag names the react version only, so a ` +
          `bump that moved one package without the other lands here rather than in a ` +
          `parity gate's report.`
      );
    }
  }

  return found;
}

async function vendor() {
  const pins = baselinePins(readJson(join(repoRoot, "package.json")));
  const dir = join(repoRoot, "xyflow");

  if (existsSync(dir)) {
    throw new Error(
      `[vendor-baseline] ${dir} already exists. A baseline bump is a delete and ` +
        `re-vendor with no merge — \`rm -rf xyflow\` first, deliberately.`
    );
  }

  const url = tarballUrl(pins.react);
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(
      `[vendor-baseline] ${response.status} ${response.statusText} for ${url}. ` +
        `Is \`@xyflow/react\` ${pins.react} a released tag?`
    );
  }

  const tarball = join(tmpdir(), `xyflow-${pins.react}.tar.gz`);
  writeFileSync(tarball, Buffer.from(await response.arrayBuffer()));
  mkdirSync(dir, { recursive: true });
  // `--strip-components=1` drops the `xyflow-<sha>/` wrapper GitHub adds, so
  // the tree lands at the paths every parity script already resolves.
  execFileSync("tar", ["-xzf", tarball, "-C", dir, "--strip-components=1"], { stdio: "inherit" });

  const found = assertVendoredVersions(dir, pins);

  console.log(
    `[vendor-baseline] xyflow/ is @xyflow/react ${found.react} / ` +
      `@xyflow/system ${found.system}, from ${url}`
  );
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  try {
    await vendor();
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
