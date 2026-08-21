# Synthesis

An architecture document is the **lossy compression of the search tree**: it keeps what the next engineer needs and lets the closed draft PRs hold the rest — diffs, commits, failures, the whole argument.

Synthesis runs twice around an OR decision, into one document. Phase A is written to *make* the choice; phase B records the choice that was made.

Keep the document where the repo already keeps architecture notes; absent a convention, `docs/architecture/<slug>.md`. Link it from the OR parent issue.

## Phase A — before the decision

Triggered when an OR group has accumulated enough evidence to choose between its children, and before anything is selected or pruned. The reader is whoever decides — the loop itself when constraints determine the answer, or the human when authority is required.

Compress from the branches, commits, probes, benchmarks, and issue comments. Every claim traces to something someone can open.

```markdown
# <the question the fork was about>

## Problem

<the uncertainty that justified forking — why one hypothesis could not answer it>

## Constraints discovered

<what implementation, compiler feedback, tests, research, and human answers revealed
 that was not known when the fork was made>

## <Hypothesis A>

- **Approach** — <what it does>
- **Evidence** — <commits, PRs, probe results, benchmarks>
- **Holds up** — <where it succeeded>
- **Fails** — <where it broke, and how that was observed>
- **Consequences** — <what adopting it commits the system to>

## <Hypothesis B>

<same structure>

## Comparison

<the differences that actually bear on the choice>

## Remaining uncertainty

<what neither branch settled>

## Recommendation

<only where authorized technical or product constraints determine it —
 otherwise state plainly that the choice needs human authority, and why>
```

A recommendation asserted past the evidence is worse than none: it launders a preference into a finding. Where the evidence runs out, say so and let gate 1 of `/hdd`'s authority rules take over.

## Phase B — after crystallization

Triggered once the selected hypothesis has merged upward. Update the same document so it records the decision rather than the deliberation.

```markdown
## Decision

<what was selected, what was pruned, and when>

## Why

<the evidence and constraints that settled it>

## Rejected alternatives

<each loser, why it lost, and a link to its closed draft PR>

## Crystallization evidence

<the merge, the PRs, the test results that verified it>

## Deliberately unresolved

<what was left open on purpose>

## Revisit triggers

<the future conditions under which a rejected hypothesis deserves another look —
 a load threshold crossed, a dependency changing, a requirement arriving>
```

Revisit triggers are the part that pays off later. Write them as observable conditions rather than intentions: _if queued operations routinely exceed 2,000_ can be noticed, _if performance becomes a problem_ cannot.
