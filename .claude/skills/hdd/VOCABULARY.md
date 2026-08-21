# HDD vocabulary and labels

The single source of truth for what the HDD terms mean and what each `hdd:` label claims. Every HDD skill points here; none of them restate it.

## Terms

Five words carry weight. Everything else means what it usually means.

- **Hypothesis** — the central unit. A candidate design, strategy, or partial solution currently being tested against its parent's goal. Its executable form is a branch; its visible form is a draft PR.
- **Gap** — a missing capability in the system. _Offline edits are not persisted across restart._
- **Hole** — a missing expression or type, in the programming-language sense: `reconcile = ?todo`. Reserved for exactly that. A gap is not a hole.
- **Fog** — uncertainty that matters but cannot yet be stated precisely enough for someone else to act on. _Long offline sessions may create some scaling problem._ Fog lives in the body of the hypothesis that owns it.
- **Crystallization** — merging a resolved hypothesis into its parent. The root's final crystallization is into `main`.

**Draft PR** means _this is the current executable state of this hypothesis_ — holes, unfinished implementation, and unresolved children included. It makes no claim about merging to `main`.

### Fog or issue

The test is whether you can state the question precisely enough that another agent or human could pick it up — **not** whether you can answer it.

| | |
|---|---|
| _There may eventually be a performance problem with long offline sessions._ | fog — keep it in the hypothesis body |
| _Reconciliation exceeds the 16 ms UI budget past ~2,000 queued operations._ | issue — file it now |

Precise unresolved knowledge becomes durable immediately. Vague uncertainty stays fog until evidence sharpens it.

## Work labels — what kind of work this is

Exactly one per issue. This label, not the invoking prompt, decides how `/hdd-work` behaves.

- **`hdd:implementation`** — a mechanical **oracle** already decides correctness: compiler, type checker, tests, properties. The contract is known and the solution space is narrow.
- **`hdd:exploration`** — the local problem or solution space is unclear. Competing implementations, architectural probes, typed skeletons, performance experiments.
- **`hdd:research`** — the missing knowledge is external: library behaviour, standards, API documentation, algorithms, prior art.
- **`hdd:task`** — mechanical work that must happen: regenerate code, migrate fixtures, provision infrastructure, sweep call sites.
- **`hdd:hitl`** — the missing information is human authority, intent, preference, or product judgment. The human supplies the answer; the model records it.
- **`hdd:hypothesis`** — this issue _is_ a candidate design or strategy, not a unit of work. Combines with a shape label.

## Shape labels — how this node expands

- **`hdd:and`** — every required child must resolve before this node does.
- **`hdd:or`** — the children are competing hypotheses. One is selected, the rest pruned.
- **`hdd:leaf`** — **search-complete**: the recursive search below this node is finished.

`hdd:leaf` is a positive claim about the search, not bookkeeping about whether children currently exist. A node with no children yet is unlabelled, not a leaf. It goes on once, after the conditions in [`hdd-crystallize`](../hdd-crystallize/SKILL.md) have each been walked and confirmed.

## State labels — where this node stands

- **`hdd:blocked`** — cannot advance until some named dependency or answer arrives.
- **`hdd:selected`** — the surviving hypothesis of an OR group.
- **`hdd:pruned`** — rejected, falsified, superseded, or made unnecessary. Pruned hypotheses never crystallize.
- **`hdd:ready`** — verification passed; safe to cross into the parent. Strictly stronger than `hdd:leaf`: leaf says the search is done, ready says the engineering is too.
- **`hdd:crystallized`** — merged into its parent, or into `main`.

## Lifecycle

```text
active (no shape label)
   │  work, expand, recurse
   ▼
search complete ──────────▶ hdd:leaf
   │  verification passes
   ▼
hdd:leaf + hdd:ready
   │  merge into parent
   ▼
hdd:crystallized
```
