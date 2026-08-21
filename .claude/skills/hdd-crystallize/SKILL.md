---
name: hdd-crystallize
description: Verify a finished hypothesis and merge it across its crystallization boundary.
disable-model-invocation: true
---

# Crystallize

Decide whether a finished hypothesis may cross into its parent, then move it. Terms and labels are in [`../hdd/VOCABULARY.md`](../hdd/VOCABULARY.md); label writes go through [`../hdd/GRAPH.md`](../hdd/GRAPH.md).

The rule the whole verification serves: **incomplete work may not cross its own boundary.** The parent it lands in may be as speculative and unfinished as it likes — `operation-log` crystallizes into `synchronization` while `synchronization` still has two open children. What is checked is the thing crossing, not the thing receiving it.

## 1. Establish that the search is complete

Walk the scope and confirm each of these. A `no` ends the crystallization here and hands the node back to `/hdd` with what is missing.

- No holes remain in the code under this hypothesis.
- Every required AND child is resolved and crystallized.
- Every OR group has a `hdd:selected` survivor, with every loser `hdd:pruned` and its draft PR closed.
- No open issue in scope blocks completion.
- No fog remains that would change what *done* means here.

All yes → apply `hdd:leaf`, the positive claim that the search below this node is finished.

## 2. Verify the engineering

- The build passes; the tests and properties pass.
- The PR's base is the hypothesis's parent branch, so the diff is against what it actually merges into.
- An OR decision has its phase A synthesis recorded ([`SYNTHESIZE.md`](../hdd/SYNTHESIZE.md)).

All yes → apply `hdd:ready`. `hdd:leaf` says the search is over; `hdd:ready` says the engineering agrees.

## 3. Promote

```bash
gh pr ready <n>          # a draft PR cannot merge while it is a draft
gh pr merge <n>
gh issue edit <hypothesis> --add-label hdd:crystallized --remove-label hdd:ready
gh issue close <hypothesis> --comment "<what crossed, and the evidence that let it>"
```

Rebase any sibling still open on that parent onto the updated parent branch — a stacked PR left behind reports a diff that includes work already merged.

If this crystallization completed an OR decision, write the phase B record now, while the reasoning is still recoverable.

## The root gate

Root → `main` is the human's call, and the only boundary where verification passing does not authorize the merge.

Present the root as `hdd:leaf` + `hdd:ready`, say what crossing would put into `main`, and stop. The human types `/hdd-crystallize` themselves; that invocation is the authorization. Internal boundaries need no such ceremony — crystallize them as you reach them.

After the merge, `main` holds coherent finished work, and `/hdd` reassesses the original goal against the reality that now exists.
