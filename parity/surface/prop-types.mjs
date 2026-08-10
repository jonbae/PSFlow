// Surface parity — the single source of truth for which prop records are compared.
//
// This list used to be hardcoded at five sites across three files
// (extract-upstream.ts, extract-psflow.mjs, diff.mjs x3). Adding a fourth
// prop record meant editing all five, and missing one silently dropped that
// record from either an extract or the gate. Both extractors and the diff
// now derive from here.
//
//   name     — the exported TypeScript type name; also the key used in
//              upstream.json / psflow.json `props` and in allowlist.json.
//   pursFile — repo-relative PureScript module holding the `type <name> = { … }`
//              record synonym that the PSFlow extractor parses.

export const PROP_TYPES = [
  { name: "ReactFlowProps", pursFile: "src/React/Types/Component.purs" },
  { name: "NodeProps", pursFile: "src/React/Types/Nodes.purs" },
  { name: "EdgeProps", pursFile: "src/React/Types/Edges.purs" },
];

export const PROP_TYPE_NAMES = PROP_TYPES.map((p) => p.name);
