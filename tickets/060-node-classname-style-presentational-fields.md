# 060 — Node `className` / `style` presentational fields not carried

## Context

Surfaced during the Layer 2 DOM-contract audit (ticket [056]/[058] lineage, parity
branch). xyflow's `nodes/general` e2e fixture sets two presentational properties
on a node:

```ts
{ id: 'Node-1', …, className: 'playwright-test-class-123', style: { backgroundColor: 'red' } }
```

and `xyflow/tests/playwright/e2e/nodes.spec.ts` asserts both reach the DOM:

```ts
await expect(node).toHaveClass(/playwright-test-class-123/);          // "classes get applied"
await expect(node).toHaveCSS('background-color', 'rgb(255, 0, 0)');   // "styles get applied"
```

In PSFlow **neither can ever be true**: a node carries no `className` or user
`style`, and the wrapper applies neither. These are the only two `nodes.spec.ts`
assertions that fail — selection, drag, `draggable/selectable/deletable=false`,
connect, `hidden`, and visibility all pass (that wiring exists).

This is not "two missing CSS features" — it is the visible edge of one porting
decision (below).

## The gap, at two layers

**Type layer — the fields don't exist.** Upstream layers React presentational
fields onto the React `Node` (not the framework-agnostic `NodeBase`):
`xyflow/packages/react/src/types/nodes.ts` — `style?` (:17), `className?` (:18),
`domAttributes?` (:30). PSFlow collapsed the React node to a bare alias:

```purescript
-- src/React/Types/Nodes.purs:28
type Node n = NodeBase n          -- adds nothing
```

So `className` / `style` / `domAttributes` exist nowhere; a user has no field to set.

**Render layer — nothing would apply them even if set** (`src/React/Component/NodeWrapper.purs`):

- `buildNodeClassName` (lines 253-272) emits a fixed class list with no slot for a
  user class. Upstream interleaves it: `cc([… , node.className, {selected, …}])`
  (NodeWrapper/index.tsx:193).
- The style merge machinery exists but is wired to nothing:
  ```purescript
  -- NodeWrapper.purs:384
  mergedStyle = mergeStyles baseStyle emptyForeign   -- 2nd arg hardcoded empty
  ```
  `mergeStyles` is a `{...a, ...b}` FFI spread (:104); `baseStyle` (:368-381) is
  computed identically to upstream, but upstream spreads the user style over it:
  `style={{ ...base, ...node.style, ...inlineDimensions }}` (index.tsx:204-208).

## Root cause — why it is not a one-liner

Upstream makes the **whole node type** generic, so React-only fields ride along
into the internal node automatically:

```ts
InternalNodeBase<NodeType extends NodeBase = NodeBase> = Omit<NodeType,'measured'> & { measured… }
```

PSFlow flattened this so the internal pipeline is parameterized **only over the
data payload**, not the node type:

```purescript
-- src/System/Types/Node.purs
type InternalNodeBase nodeData = { internals :: NodeInternals | NodeBaseRow nodeData }
type NodeLookup nodeData      = Map NodeId (InternalNodeBase nodeData)
-- src/System/Utils/Store.purs:341
adoptUserNodes :: Array (NodeBase n) -> … -> { nodeLookup :: NodeLookup n, … }
```

The chain the wrapper reads from — `adoptUserNodes → NodeLookup → InternalNodeBase
→ selectNodeSlice → NodeWrapper` — is typed entirely on the fixed `NodeBaseRow`.
A React-only field on `Node` would be **erased at the `adoptUserNodes` boundary**
(`Array (NodeBase n)` in), so it never reaches the store or wrapper. There is no
ride-along channel because the node type is monomorphic except for `data`. (This is
also why `type Node n = NodeBase n` and the `unsafeCoerce … :: Node n` at
NodeWrapper.purs:328 exist.)

## Options

1. **Pragmatic (recommended).** Add `className :: Maybe String` and
   `style :: Maybe Foreign` to `NodeBaseRow` (src/System/Types/Node.purs). They
   then flow through `adoptUserNodes` → `InternalNodeBase` → wrapper for free, like
   the other presentational fields PSFlow *already* put on `NodeBaseRow` though
   upstream keeps them React-side (`draggable`, `selectable`, `connectable`,
   `deletable`, `dragHandle`, `hidden`). Render changes are small:
   - add a `className` slot to `buildNodeClassName` (interleave at upstream's
     position) and thread `node.className`;
   - replace `mergeStyles baseStyle emptyForeign` with
     `mergeStyles baseStyle <node.style as Foreign>` (style stays opaque `Foreign`,
     consistent with how `Style` is already modeled — NodeWrapper note line 31;
     build via the existing `toForeignStyle`).
   - Surface `NodeProps`'s missing members where relevant — overlaps ticket 058.

   Cost: mild divergence from upstream's layering, but consistent with a divergence
   PSFlow already made. Low risk.

2. **Faithful.** Re-introduce a distinct React `Node = NodeBase + className/style/
   domAttributes` and make the internal pipeline generic over the node type
   (`InternalNodeBase` / `NodeLookup` / `adoptUserNodes` / selectors parameterized
   over the full node row, not just `data`). Matches upstream architecture; large,
   invasive refactor (store types, every `NodeLookup` site, the `unsafeCoerce`
   Node↔NodeBase interchange) for mostly architectural purity.

## Adjacent (separate, not part of this ticket)

The inline `node.style.width/height` string-dimension fallback — upstream's third
spread `...inlineDimensions` — is also deferred (NodeWrapper note lines 30-32). The
`nodes.spec.ts` assertions don't exercise it.

## Acceptance criteria

- A node can carry a custom `className` and `style`; both reach the rendered
  `<div>` (class string includes the user class; style merges over `baseStyle`).
- `spago build` stays warning-clean.
- With the Layer 2 `nodes/general` fixture + adopted `nodes.spec.ts`, the
  "classes get applied" and "styles get applied" tests pass.

## Source files

- [src/React/Types/Nodes.purs](../src/React/Types/Nodes.purs) — `type Node n = NodeBase n`
- [src/System/Types/Node.purs](../src/System/Types/Node.purs) — `NodeBaseRow`, `InternalNodeBase`
- [src/System/Utils/Store.purs](../src/System/Utils/Store.purs) — `adoptUserNodes`
- [src/React/Component/NodeWrapper.purs](../src/React/Component/NodeWrapper.purs) — `buildNodeClassName` (253), `baseStyle`/`mergedStyle` (368-384)
- Reference: `xyflow/packages/react/src/types/nodes.ts`, `xyflow/packages/react/src/components/NodeWrapper/index.tsx`
- Related: ticket 058 (NodeProps surface gaps), ticket 056 (Layer 2 smoke follow-ups)
