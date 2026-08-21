import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, mkdtempSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import {
  CallbackDerivationError,
  HOLES,
  NOT_INSTALLED,
  UNHANDLED_ANSWERS,
  callablePropsOf,
  observedCallbacks,
  staleEntries,
} from "./callbacks.mjs";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");

// The derivation reads real TypeScript with the real compiler, so the tests
// build a real miniature of the shape it reads rather than mocking one: an
// interface of its own members, extending one declared **outside** its root the
// way `ReactFlowProps` extends React's `HTMLAttributes`.
const miniature = (files) => {
  const dir = mkdtempSync(join(tmpdir(), "psflow-callbacks-"));
  for (const [name, contents] of Object.entries(files)) {
    mkdirSync(dirname(join(dir, name)), { recursive: true });
    writeFileSync(join(dir, name), contents);
  }
  return dir;
};

const LIBRARY = `
import type { Foreign } from '../outside/foreign';

type NodeMouseHandler = (event: unknown, node: unknown) => void;
type OnError = (id: string, message: string) => void;

export interface Props extends Foreign {
  nodes?: unknown[];
  colorMode?: 'light' | 'dark';
  nodeTypes?: Record<string, unknown>;
  onNodeClick?: NodeMouseHandler;
  onError?: OnError;
  isValidConnection?: (connection: unknown) => boolean;
  onBeforeDelete?: (params: unknown) => Promise<boolean>;
}
`;

const OUTSIDE = `
export interface Foreign {
  onScroll?: (event: unknown) => void;
  className?: string;
}
`;

const propsOf = (dir) =>
  callablePropsOf({ file: join(dir, "library/props.ts"), typeName: "Props", root: join(dir, "library") });

// The claim that no name pattern can make: `isValidConnection` is a callback and
// `nodeTypes` — a record of components — is not, and neither of them starts with
// `on`. A whitelist of interesting handlers is a hand-authored reading of what
// upstream calls, which is the failure the whole net is built to avoid.
test("a prop is a callback exactly when its type is callable, whatever it is named", () => {
  const dir = miniature({ "library/props.ts": LIBRARY, "outside/foreign.ts": OUTSIDE });

  assert.deepEqual(propsOf(dir), ["onNodeClick", "onError", "isValidConnection", "onBeforeDelete"]);
});

// The real case is React's ~100 DOM handlers, which land on the wrapper div
// rather than in the library. Installing them would put an entry in the log for
// every pixel of every drag, and none of it would be about xyflow.
test("a member inherited from outside the library's own source is not one of its callbacks", () => {
  const dir = miniature({ "library/props.ts": LIBRARY, "outside/foreign.ts": OUTSIDE });

  assert.ok(!propsOf(dir).includes("onScroll"));
});

test("a source file that is not there fails, naming the vendored tree", () => {
  const dir = miniature({ "outside/foreign.ts": OUTSIDE });

  assert.throws(() => propsOf(dir), { name: "CallbackDerivationError", message: /re-vendor/i });
});

// Upstream renaming the props type is itself a finding. Answering "no callbacks
// then" would build a driver that installs nothing, and a section that compares
// clean because neither side was ever asked.
test("a props type that is no longer declared fails rather than deriving nothing", () => {
  const dir = miniature({ "library/props.ts": LIBRARY, "outside/foreign.ts": OUTSIDE });

  assert.throws(
    () => callablePropsOf({ file: join(dir, "library/props.ts"), typeName: "ReactFlowProps", root: join(dir, "library") }),
    { name: "CallbackDerivationError", message: /interface ReactFlowProps/ }
  );
});

test("CallbackDerivationError is what the derivation throws", () => {
  const dir = miniature({});

  assert.throws(() => propsOf(dir), CallbackDerivationError);
});

// ── The two registers ──────────────────────────────────────────────────────

test("a withheld prop that upstream no longer declares as a callback is stale", () => {
  assert.deepEqual(staleEntries(["onNodeClick", "onBeforeDelete", "isValidConnection"]), [
    "NOT_INSTALLED: onInit",
  ]);
});

test("an unset-answer entry that upstream no longer declares as a callback is stale", () => {
  assert.deepEqual(staleEntries(["onInit", "isValidConnection"]), ["UNHANDLED_ANSWERS: onBeforeDelete"]);
});

test("registers that name real callback props are not stale", () => {
  const derived = ["onInit", "onBeforeDelete", "isValidConnection"];

  assert.deepEqual(staleEntries(derived), []);
});

test("an answer for a prop nothing installs is a contradiction, not a filter", () => {
  const derived = ["onInit", "onBeforeDelete", "isValidConnection"];
  const contradictions = staleEntries(derived).filter((s) => s.includes("withholds"));

  // The registers agree today, so this asks the rule rather than the data: the
  // one prop `HOLES` withholds must not also carry an unset answer.
  assert.deepEqual(contradictions, []);
  assert.ok(
    !Object.keys(UNHANDLED_ANSWERS).some((prop) => NOT_INSTALLED.some((hole) => hole.prop === prop)),
    "an unset answer for a withheld prop is an answer nothing can ever give"
  );
});

// Every hole is a written reason and a ticket where it stops being one. A hole
// with neither is an empty section nobody can read a decision out of.
test("every hole carries a reason and the issue that lands it", () => {
  for (const hole of HOLES) {
    assert.equal(typeof hole.export, "string");
    assert.ok(hole.reason.length > 20, `${hole.export} needs a written reason`);
    assert.ok(Number.isInteger(hole.issue), `${hole.export} needs the issue that lands it`);
  }
});

test("the withheld props are the holes that name one", () => {
  assert.deepEqual(NOT_INSTALLED, HOLES.filter((hole) => hole.prop));
});

// ── The holes, against the census ──────────────────────────────────────────
//
// The census is the authority for which exports this section is meant to carry:
// the 47 with mechanism `dual-run-callback`. A hole naming an export it no
// longer assigns here is stale — someone reclassified it, or upstream removed
// it, and the reason written beside it has stopped being about anything.
//
// The reached side of the question is deliberately *not* asserted here. That is
// coverage, it has to come from runs that actually happened, and #57 is where it
// derives from traces rather than from this file's word.

const census = JSON.parse(readFileSync(join(repoRoot, "parity/census/classification.json"), "utf8"));
const callbackExports = Object.entries(census)
  .filter(([name, entry]) => name !== "_schema" && entry[1] === "dual-run-callback")
  .map(([name]) => name);

test("the census still assigns this section the exports the holes are counted against", () => {
  assert.equal(callbackExports.length, 47);
});

test("every declared hole names an export the census assigns to this section", () => {
  const assigned = new Set(callbackExports);

  assert.deepEqual(
    HOLES.filter((hole) => !assigned.has(hole.export)).map((hole) => hole.export),
    [],
    "a hole naming an export the census no longer puts in `callbacks` is stale"
  );
});

// The whole point of a hole register: what the section does not reach is
// *written down*, so it is a decision someone made rather than an absence
// nobody noticed. These are the ones a driver installing every ReactFlow
// callback prop still cannot see.
test("the exports outside ReactFlowProps are the ones declared", () => {
  assert.deepEqual(
    HOLES.map((hole) => hole.export).sort(),
    [
      "OnInit",
      "OnResize",
      "OnResizeEnd",
      "OnResizeStart",
      "ResizeDragEvent",
      "ResizeParams",
      "ResizeParamsWithDirection",
      "ShouldResize",
      "UseOnSelectionChangeOptions",
      "UseOnViewportChangeOptions",
    ]
  );
});

// ── Against the vendored tree ──────────────────────────────────────────────
//
// `xyflow/` is gitignored, so these skip on a clean clone the way the two
// upstream-bundle tests in `live.spec.mjs` do. Everything above runs anywhere.

const vendored = existsSync(join(repoRoot, "xyflow/packages/react/src/types/component-props.ts"));

test("upstream's own callback props are what the driver installs, minus the withheld ones", { skip: !vendored }, () => {
  const { props, unhandled, holes } = observedCallbacks(repoRoot);

  assert.ok(props.length >= 45, `derived only ${props.length} callback props`);
  assert.ok(props.includes("onNodesChange"));
  assert.ok(props.includes("isValidConnection"));
  assert.ok(!props.includes("onInit"), "onInit is withheld — ps-flow refuses it at mount");
  assert.ok(!props.includes("onScroll"), "onScroll is React's, inherited from HTMLAttributes");
  assert.deepEqual(holes, NOT_INSTALLED);
  assert.deepEqual(Object.keys(unhandled).sort(), Object.keys(UNHANDLED_ANSWERS).sort());
});

test("no prop is both installed and withheld", { skip: !vendored }, () => {
  const { props, holes } = observedCallbacks(repoRoot);

  assert.deepEqual(
    props.filter((prop) => holes.some((hole) => hole.prop === prop)),
    []
  );
});

test("both registers name props upstream still declares as callbacks", { skip: !vendored }, () => {
  const { props, holes } = observedCallbacks(repoRoot);
  const declared = new Set([...props, ...holes.map((hole) => hole.prop)]);

  for (const prop of Object.keys(UNHANDLED_ANSWERS)) assert.ok(declared.has(prop), `${prop} is stale`);
});
