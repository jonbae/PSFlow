---
name: hdd
description: Run the recursive HDD loop — fork hypotheses downward, crystallize proven work upward.
disable-model-invocation: true
---

# Recursive HDD

> **Fork downward. Crystallize upward.**

A goal-to-`main` engine. Hold one hypothesis at a time, build far enough to see the next real question, expand only what the evidence justifies, and merge proven work upward into its parent.

The graph is created while you traverse it. Expand a hypothesis when reality has shown you something that justifies it — a compiler error, a failed probe, a benchmark, a document you read. A plan drafted up front forecloses the search before any evidence has shaped it, so the first move is always to build or investigate, never to enumerate.

Read [`VOCABULARY.md`](VOCABULARY.md) once per session for the terms and the full `hdd:` label set.

This skill is the control plane: it decides **what happens next** and hands the operation to whoever owns it. It reads the graph freely; [`GRAPH.md`](GRAPH.md) owns every write to it.

## The loop

### 1. Orient

Load the low-resolution view — the goal, the hypothesis you are on, and what is open beneath it.

```bash
git branch --show-current
gh issue list --state open --json number,title,labels --jq '[.[] | {number, title, labels: [.labels[].name]}]'
gh pr list --state open --json number,title,headRefName,baseRefName,isDraft
```

Zoom into a single issue or PR body only when the move you are choosing depends on it.

### 2. Choose one move

| What the state shows | Move |
|---|---|
| an actionable issue on the current hypothesis | dispatch a worker subagent — see [Dispatching work](#dispatching-work) |
| precise uncertainty that exists only in this context | file it — [`GRAPH.md`](GRAPH.md) |
| the hypothesis needs children | decide the shape below, then [`GRAPH.md`](GRAPH.md) |
| an OR group carrying enough evidence to choose | [`SYNTHESIZE.md`](SYNTHESIZE.md) phase A, then select and prune |
| a hypothesis whose search is complete | [`hdd-crystallize`](../hdd-crystallize/SKILL.md) — at an internal boundary, follow it yourself |
| the next step needs an answer only the human has | stop and ask — see [Authority](#authority) |

### 3. Execute it

One move per iteration. Finish it, and make its result durable in GitHub before starting the next.

### 4. Recurse

Return to step 1 against the new state. After a crystallization into `main`, reassess the original goal from the new reality: if a real gap is still visible, a fresh hypothesis begins; if not, the loop is done.

## Deciding the shape

You own this decision; `GRAPH.md` only represents it.

- **AND** — the pieces are all required, and resolving one does not answer another. _Authentication = parse credentials AND look up user AND verify password._
- **OR** — the children are rival answers to the same question, and evidence will eliminate all but one. _Synchronization = CRDT OR OT._

Fork OR only when the alternatives are genuinely competing and the choice between them is not already determined. When existing constraints settle it, pick the answer and file the work as AND — an OR group whose outcome you already know spends two branches to learn nothing.

## When a hypothesis earns a branch and draft PR

Open one when the hypothesis has executable state worth building, testing, comparing, or preserving on its own. Otherwise the work rides on the branch you are already on.

| | |
|---|---|
| meaningful implementation hypothesis | branch + draft PR |
| executable architectural experiment | branch + draft PR |
| small implementation inside the current hypothesis | stays on the current branch |
| research, HITL, or non-code task | issue only |

Branch topology mirrors the hypothesis hierarchy, and each PR is based on its parent's branch — `crdt → synchronization → feature → main`. A finished child may crystallize into a parent that is still incomplete; what may never cross a boundary is work that is itself unfinished.

## Dispatching work

Send `/hdd-work` to a **subagent**, one issue per dispatch. The boundary is load-bearing: it keeps this control plane small across a long loop, and it means anything the worker fails to write to GitHub dies with its context — which is the invariant you want enforced structurally rather than remembered.

Prompt it with the issue number and the path, nothing more:

```text
Follow .claude/skills/hdd-work/SKILL.md for issue #123.
```

Withhold what comes after the work — crystallization, the next hypothesis, the shape of the tree. A worker that can see the finish line stops early.

Hold it to the report its own skill closes with, and treat a thin one as unfinished work rather than a finished issue.

`hdd:hitl` issues never dispatch. The answer is the human's, so take it to them.

## Authority

Proceed on your own by default — create issues and children, fork and prune hypotheses, branch, commit, run the compiler and tests, maintain labels, and crystallize into speculative parents.

Stop at four gates, where the missing thing is authority rather than evidence:

1. **Product intent.** _Should unmergeable concurrent edits show a conflict, or prefer one side?_ If the repository and the goal do not already answer it, the answer is not yours to invent.
2. **A contract change.** When implementation keeps failing because the contract is wrong, first ask whether the correction follows from what is already authorized. If it does, resolve it by exploration; if it does not, the human decides.
3. **A consequential preference** with no prior authority: cost, UX, compatibility policy, public API semantics, data retention, anything irreversible.
4. **Root → `main`.** Present the root as `hdd:leaf` + `hdd:ready` and wait for the human to invoke `/hdd-crystallize`.

At the first three, file an `hdd:hitl` issue so the question is durable, then ask it in plain language. The human answers in conversation, and their answer goes back onto the issue before the loop moves.

## Where the loop ends

An iteration is finished when its result is durable in GitHub — an issue, a label, a commit, a comment, a merge. Uncertainty that matters and lives only in this context window has not been externalized, and the loop may not advance past it.

The loop itself ends in exactly one of two states: authority is missing and the human has been asked, or the root has crystallized into `main` and the goal shows no further gap.
