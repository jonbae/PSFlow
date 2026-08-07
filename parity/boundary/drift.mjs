// Boundary drift — a staleness gate over the outbound conversions.
//
// The inbound direction of the boundary module is compiler-checked for free:
// building a PureScript record forces a value for every field, so a field
// added to `NodeBaseRow` breaks `Boundary.Elements` until someone reads it off
// the JavaScript object.
//
// The outbound direction has no such check. Nothing makes `JsNode` name every
// field `NodeBaseRow` has, so a field added to the PureScript record and
// forgotten in the JS-shaped one is silently dropped on the way out — and a
// round-trip property would not find it either, because the repo's generators
// vary 5 of that record's 28 fields and would happily agree about the other 23
// while one of them vanished.
//
// So this compares the two type declarations' label sets directly. There is no
// recorded baseline to re-bless: both sides are read live from source, and the
// gate fails on the field that appears in one and not the other. The only
// hand-written data is the rename table, which is itself checked — a rename
// naming a field that no longer exists on either side fails as stale.
//
// The run ends with a falsification probe. A green differential result proves
// nothing until it has been shown it can go red, and this one has three
// failure classes to demonstrate, so it demonstrates all three on every run.
//
// Usage: node parity/boundary/drift.mjs

import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { fail, recordFields } from "./purs.mjs";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..", "..");

// ── The pairs ───────────────────────────────────────────────────────────
//
// `renames` maps a PureScript label to the JS label it crosses as. Every one
// of them is a deliberate divergence with a reason: PureScript keeps `type`
// free for the element's own tag, so a nested type tag is `nodeType` /
// `edgeType` / `handleType` / `markerType`; and upstream keys its aria-label
// config by dotted path, which is not a PureScript identifier.

const pairs = [
  {
    what: "Node",
    ps: { file: "src/System/Types/Node.purs", type: "NodeBaseRow" },
    js: { file: "src/Boundary/Elements.purs", type: "JsNode" },
    renames: { nodeType: "type" },
  },
  {
    what: "Edge",
    ps: { file: "src/System/Types/Edge.purs", type: "EdgeBase" },
    js: { file: "src/Boundary/Elements.purs", type: "JsEdge" },
    renames: { edgeType: "type" },
  },
  {
    what: "NodeProps",
    ps: { file: "src/React/Types/Nodes.purs", type: "NodeProps" },
    js: { file: "src/Boundary/Elements.purs", type: "JsNodeProps" },
    renames: {},
  },
  {
    what: "NodeHandle",
    ps: { file: "src/System/Types/Node.purs", type: "NodeHandle" },
    js: { file: "src/Boundary/Elements.purs", type: "JsNodeHandle" },
    renames: { handleType: "type" },
  },
  {
    what: "EdgeMarker",
    ps: { file: "src/System/Types/Edge.purs", type: "EdgeMarker" },
    js: { file: "src/Boundary/Elements.purs", type: "JsEdgeMarker" },
    renames: { markerType: "type" },
  },
  {
    what: "Connection",
    ps: { file: "src/System/Types/Connection.purs", type: "Connection" },
    js: { file: "src/Boundary/Elements.purs", type: "JsConnection" },
    renames: {},
  },
  {
    what: "ReactFlowProps",
    ps: { file: "src/React/Types/Component.purs", type: "ReactFlowProps" },
    js: { file: "src/Boundary/Flow.purs", type: "JsFlowProps" },
    renames: {},
  },
  {
    what: "DefaultEdgeOptions",
    ps: { file: "src/React/Types/Edges.purs", type: "DefaultEdgeOptions" },
    js: { file: "src/Boundary/Flow.purs", type: "JsDefaultEdgeOptions" },
    renames: {},
  },
  {
    what: "FitViewOptions",
    ps: { file: "src/System/Utils/Graph.purs", type: "FitViewOptions" },
    js: { file: "src/Boundary/Flow.purs", type: "JsFitViewOptions" },
    renames: {},
  },
  {
    what: "ProOptions",
    ps: { file: "src/React/Types/General.purs", type: "ProOptions" },
    js: { file: "src/Boundary/Flow.purs", type: "JsProOptions" },
    renames: {},
  },
  {
    what: "AriaLabelConfig",
    ps: { file: "src/System/Constants.purs", type: "AriaLabelConfigOverride" },
    js: { file: "src/Boundary/Flow.purs", type: "JsAriaLabelConfig" },
    renames: {
      nodeA11yDescriptionDefault: "node.a11yDescription.default",
      nodeA11yDescriptionKeyboardDisabled: "node.a11yDescription.keyboardDisabled",
      nodeA11yDescriptionAriaLiveMessage: "node.a11yDescription.ariaLiveMessage",
      edgeA11yDescriptionDefault: "edge.a11yDescription.default",
      controlsAriaLabel: "controls.ariaLabel",
      controlsZoomInAriaLabel: "controls.zoomIn.ariaLabel",
      controlsZoomOutAriaLabel: "controls.zoomOut.ariaLabel",
      controlsFitViewAriaLabel: "controls.fitView.ariaLabel",
      controlsInteractiveAriaLabel: "controls.interactive.ariaLabel",
      minimapAriaLabel: "minimap.ariaLabel",
      handleAriaLabel: "handle.ariaLabel",
    },
  },
];

// ── The comparison ──────────────────────────────────────────────────────

// Pure, so the falsification probe below can hand it perturbed field lists
// without touching a file.
export function compare({ psType, jsType, psFields, jsFields, renames }) {
  const psSet = new Set(psFields);
  const jsSet = new Set(jsFields);
  const problems = [];

  // A rename must name a field that exists on both sides. One that stops
  // matching means the divergence it documents is gone, and a rename table
  // outliving its cause is how the next silent drop gets missed.
  for (const [psName, jsName] of Object.entries(renames)) {
    if (!psSet.has(psName)) {
      problems.push(
        `stale rename: \`${psName}\` -> \`${jsName}\` names a field ${psType} no longer has`
      );
    }
    if (!jsSet.has(jsName)) {
      problems.push(
        `stale rename: \`${psName}\` -> \`${jsName}\` names a field ${jsType} no longer has`
      );
    }
  }

  const crossed = (name) => renames[name] ?? name;
  const psCrossed = new Set(psFields.map(crossed));
  const reverse = new Map(Object.entries(renames).map(([ps, js]) => [js, ps]));

  for (const name of psFields) {
    if (!jsSet.has(crossed(name))) {
      problems.push(`${psType}.${name} has no field in ${jsType} — it is dropped on the way out`);
    }
  }
  for (const name of jsFields) {
    if (!psCrossed.has(name)) {
      const origin = reverse.get(name);
      problems.push(
        `${jsType}.${name} has no field in ${psType}` +
          (origin ? ` (renamed from \`${origin}\`, which is also missing)` : "")
      );
    }
  }

  return problems;
}

function pairInput(pair) {
  return {
    psType: pair.ps.type,
    jsType: pair.js.type,
    psFields: recordFields(join(repoRoot, pair.ps.file), pair.ps.type),
    jsFields: recordFields(join(repoRoot, pair.js.file), pair.js.type),
    renames: pair.renames,
  };
}

// ── The falsification probe ─────────────────────────────────────────────
//
// Three failure classes, three perturbations, checked against the real field
// lists so the probe cannot pass on a shape the gate never sees.

function falsify(inputs) {
  const base = inputs[0];
  const checks = [
    [
      "a field added to the PureScript record and not to the JS one",
      { ...base, psFields: [...base.psFields, "psOnlyFieldForProbe"] },
    ],
    [
      "a field added to the JS record and not to the PureScript one",
      { ...base, jsFields: [...base.jsFields, "jsOnlyFieldForProbe"] },
    ],
    [
      "a rename naming a field neither side has",
      { ...base, renames: { ...base.renames, goneFromBoth: "alsoGone" } },
    ],
  ];

  for (const [what, input] of checks) {
    if (compare(input).length === 0) {
      fail(`falsification probe failed — the drift check stays green on ${what}`);
    }
  }

  if (compare(base).length !== 0) {
    fail("falsification probe failed — the unperturbed baseline is not green");
  }
}

// ── Run ─────────────────────────────────────────────────────────────────

const inputs = pairs.map(pairInput);

let failures = 0;
const rows = [];

pairs.forEach((pair, i) => {
  const problems = compare(inputs[i]);
  if (problems.length > 0) {
    failures += problems.length;
    console.error(`\n✗ ${pair.what}`);
    for (const problem of problems) console.error(`    ${problem}`);
  } else {
    rows.push(`  ✓ ${pair.what.padEnd(20)} ${inputs[i].psFields.length} fields`);
  }
});

if (failures > 0) {
  console.error(
    `\n${failures} boundary drift problem(s). A field on one side of the crossing ` +
      `and not the other is either silently dropped outbound or invented inbound; ` +
      `add it to the JS-shaped record in src/Boundary/ and convert it, or record ` +
      `the rename in parity/boundary/drift.mjs.\n`
  );
  process.exit(1);
}

falsify(inputs);

console.log("boundary drift: every crossed record agrees, field for field.");
console.log(rows.join("\n"));
console.log("\n  ✓ falsification probe — the check goes red on all three failure classes.");
