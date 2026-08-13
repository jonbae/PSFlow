import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { cpSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const here = dirname(fileURLToPath(import.meta.url));

const write = (root, path, contents) => {
  const target = join(root, path);
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, contents);
};

const censusFixture = (
  t,
  { valueExports, typeExports = [], classification, manifest, specs = {}, behavior = {} }
) => {
  const root = mkdtempSync(join(tmpdir(), "psflow-census-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));

  write(root, "package.json", '{"type":"module"}\n');
  write(
    root,
    "parity/surface/upstream.json",
    JSON.stringify({ reactVersion: "test", systemVersion: "test", valueExports, typeExports })
  );
  write(root, "parity/surface/psflow.json", JSON.stringify({ valueExports, typeExports }));
  write(root, "parity/census/classification.json", JSON.stringify(classification));
  write(
    root,
    "parity/surface/behavior.mjs",
    `export const ENUM_EXPORTS = ${JSON.stringify(behavior.enums ?? [])};\n` +
      `export const PURE_FUNCTION_CALLS = ${JSON.stringify(behavior.functions ?? [])}.map(name => ({ name }));\n`
  );
  write(root, "oracle/index.js", "export {};\n");
  write(
    root,
    "src/Boundary.js",
    `export const manifest = ${JSON.stringify({ stage: 1, ...manifest })};\n`
  );
  mkdirSync(join(root, "examples/react-smoke/tests"), { recursive: true });
  for (const [name, contents] of Object.entries(specs)) {
    write(root, `examples/react-smoke/tests/${name}`, contents);
  }
  cpSync(join(here, "build.mjs"), join(root, "parity/census/build.mjs"));

  return root;
};

const runCensus = (root) =>
  spawnSync(process.execPath, ["parity/census/build.mjs"], {
    cwd: root,
    encoding: "utf8",
  });

test("the standalone census distinguishes crossed exports that are ungated on the JS surface", (t) => {
  const root = censusFixture(t, {
    valueExports: ["CrossedGated", "CrossedBySurface", "CrossedUngated", "PassthroughGated"],
    typeExports: ["TypeGated"],
    classification: {
      CrossedGated: ["component", "dual-run-dom", ["conformance:js.spec.ts"], ""],
      CrossedBySurface: ["enum-value", "dual-run-value", [], ""],
      CrossedUngated: ["component", "dual-run-dom", [], ""],
      PassthroughGated: ["component", "dual-run-dom", ["conformance:js.spec.ts"], ""],
      TypeGated: ["data", "dual-run-dom", ["conformance:js.spec.ts"], ""],
    },
    manifest: {
      crossed: ["CrossedGated", "CrossedBySurface", "CrossedUngated"],
      passthrough: ["PassthroughGated"],
    },
    behavior: { enums: ["CrossedBySurface"] },
    specs: { "js.spec.ts": 'page.goto("/parity/driver/index.html");\n' },
  });

  execFileSync(process.execPath, ["parity/census/build.mjs"], { cwd: root });
  const report = readFileSync(join(root, "parity/census/report.md"), "utf8");

  assert.match(report, /Gated — JS surface.*Crossed, ungated — JS surface/);
  assert.match(report, /At boundary stage 1, 3 exports have crossed; 1 is crossed but ungated/);
  assert.match(report, /`CrossedGated`.*crossed, gated — conformance \(js\)/);
  assert.match(report, /`CrossedBySurface`.*crossed, gated — surface \(behavior\)/);
  assert.match(report, /`CrossedUngated`.*crossed, ungated/);
  assert.match(report, /`PassthroughGated`.*passthrough, gated — conformance \(js\)/);
  assert.match(report, /`TypeGated`.*no runtime value, gated — conformance \(js\)/);
});

test("the standalone census fails when a runtime export is absent from the boundary manifest", (t) => {
  const root = censusFixture(t, {
    valueExports: ["MissingFromManifest"],
    classification: { MissingFromManifest: ["component", "dual-run-dom", [], ""] },
    manifest: { crossed: [], passthrough: [] },
  });
  const failure = runCensus(root);

  assert.equal(failure.status, 1);
  assert.match(failure.stderr, /PSFlow runtime exports absent from the boundary manifest/);
});

test("the standalone census rejects a manifest name that is both crossed and passthrough", (t) => {
  const root = censusFixture(t, {
    valueExports: ["Ambiguous"],
    classification: { Ambiguous: ["component", "dual-run-dom", [], ""] },
    manifest: { crossed: ["Ambiguous"], passthrough: ["Ambiguous"] },
  });
  const failure = runCensus(root);

  assert.equal(failure.status, 1);
  assert.match(failure.stderr, /Boundary manifest names marked both crossed and passthrough.*Ambiguous/);
});

test("the standalone census rejects specs that enter through the retired Example.Main page", (t) => {
  const root = censusFixture(t, {
    valueExports: ["LegacyGate"],
    classification: {
      LegacyGate: ["component", "dual-run-dom", ["smoke:legacy.spec.ts"], ""],
    },
    manifest: { crossed: ["LegacyGate"], passthrough: [] },
    specs: {
      "legacy.spec.ts": 'page.goto("/examples/react-smoke/index.html");\n',
    },
  });
  const failure = runCensus(root);

  assert.equal(failure.status, 1);
  assert.match(failure.stderr, /legacy\.spec\.ts enters through the retired Example\.Main page/);
});

test("the standalone census checks unclassified specs for the retired page too", (t) => {
  const root = censusFixture(t, {
    valueExports: ["Ungated"],
    classification: { Ungated: ["component", "dual-run-dom", [], ""] },
    manifest: { crossed: ["Ungated"], passthrough: [] },
    specs: {
      "screenshot.spec.ts": 'page.goto("/examples/react-smoke/index.html");\n',
    },
  });
  const failure = runCensus(root);

  assert.equal(failure.status, 1);
  assert.match(failure.stderr, /screenshot\.spec\.ts enters through the retired Example\.Main page/);
});
