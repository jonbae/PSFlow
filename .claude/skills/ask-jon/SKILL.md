---
name: ask-jon
description: Ask what the HDD workflow is doing, or what some piece of the repo state means.
disable-model-invocation: true
---

# Ask Jon

Explains the recursive HDD workflow and reads its state back in plain language. Scope is exactly that system — the four commands below and the GitHub state they produce.

The issues and PRs *are* the status board: labels carry the classification, draft PRs carry the executable hypotheses, branch topology carries the tree. Nothing needs to be kept in sync with them, so there is no dashboard to build — only this one to read aloud.

Terms and labels are in [`../hdd/VOCABULARY.md`](../hdd/VOCABULARY.md). Answer from there and from the repo's live state, in whatever mixture the question calls for.

## The system

Four commands. Jon types all of them; nothing here fires on its own.

| Command | Does | He types it when |
|---|---|---|
| `/hdd` | runs the loop — orient, choose one move, execute, recurse | starting a goal, or continuing one |
| `/hdd-work` | advances one issue to durable progress or evidence | focusing a particular issue by hand |
| `/hdd-crystallize` | verifies a finished hypothesis and merges it upward | the root is `hdd:leaf` + `hdd:ready` and waiting on him |
| `/ask-jon` | this — explains the workflow and the state | he wants his bearings |

Underneath `/hdd` sit three reference files it reads as it goes: `VOCABULARY.md` (terms and labels), `GRAPH.md` (every write to the graph), `SYNTHESIZE.md` (the architecture record around an OR decision). They are documents, not commands — nobody types them.

The loop runs by itself once started, and halts in exactly two places: a question only Jon can answer, and the root's merge into `main`.

## Answer against the actual state

Most questions are about *this* repo rather than the workflow in the abstract, so go look before answering.

```bash
gh issue list --state open --json number,title,labels --jq '[.[] | {number, title, labels: [.labels[].name]}]'
gh pr list --state open --json number,title,headRefName,baseRefName,isDraft
gh issue view <n> --comments
```

| He asks | Read | Answer with |
|---|---|---|
| *How do I start a new goal?* | — | `/hdd <the goal>` — and what it will do first |
| *What does `hdd:leaf` mean?* | `VOCABULARY.md` | the claim the label makes, and what had to be true to apply it |
| *Why is this PR still a draft?* | the PR's hypothesis issue | what is still open beneath it |
| *Why did it fork CRDT and OT?* | the OR parent, the synthesis doc | the uncertainty that justified two branches |
| *Why was this hypothesis pruned?* | the closed draft PR, the synthesis doc | the evidence that killed it, and its revisit triggers |
| *Can this crystallize yet?* | the issue's labels, the PR's checks | which `/hdd-crystallize` conditions are unmet |
| *What needs my attention?* | the query below | the questions only he can answer |

The last one is the most common. Two things wait on Jon and nothing else does:

```bash
gh issue list --state open --label hdd:hitl                      # questions awaiting authority
gh issue list --state open --label hdd:ready --label hdd:leaf    # verified, awaiting authorization
```

## Explaining is the job

Where the honest answer is an action, name the command that performs it and leave the decision with him. He came for his bearings, not for the work to be done while he was looking away.

Prefer the concrete over the general: *`#42` is blocked because nobody has decided whether unmergeable edits show a conflict* beats a description of what `hdd:blocked` means — and if he wanted the definition, that is his next question.
