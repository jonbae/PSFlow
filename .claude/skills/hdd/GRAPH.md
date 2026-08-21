# Graph mechanics

Every write to the HDD graph happens here. `/hdd` decides *whether* a fork is warranted, which hypothesis survives, and when a search is complete; this file only represents those decisions faithfully. Label meanings live in [`VOCABULARY.md`](VOCABULARY.md).

`gh` infers the repo from the clone. Multi-line bodies go in a heredoc.

## Bootstrap

Once per repo, create the label set:

```bash
for l in implementation exploration research task hitl hypothesis and or leaf blocked selected pruned ready crystallized; do
  gh label create "hdd:$l" --force
done
```

## Create a hypothesis

An issue carrying `hdd:hypothesis`, plus a branch and draft PR when `/hdd` has judged the hypothesis to have executable state worth its own workspace.

```bash
gh issue create --label hdd:hypothesis --title "<name>" --body "$(cat <<'BODY'
## Hypothesis

<the candidate design, strategy, or partial solution being tested>

## Resolves

<what must become true for this to be settled>

## Fog

<uncertainty too vague to file — see VOCABULARY.md>
BODY
)"
```

Then the executable form, based on the parent's branch so the topology mirrors the hierarchy:

```bash
git switch -c <child-branch> <parent-branch>
git push -u origin <child-branch>
gh pr create --draft --base <parent-branch> --head <child-branch> \
  --title "<name>" --body "Hypothesis #<issue>. Executable state, not a merge request."
```

The root hypothesis is the same call with `main` as its parent.

## Create a work issue

One work label per issue, chosen by the classification in `VOCABULARY.md`.

```bash
gh issue create --label "hdd:implementation" --title "<what is unresolved>" --body "$(cat <<'BODY'
## Unresolved

<stated precisely enough for another agent or human to pick up>

## Oracle

<what decides correctness: compiler, property, test, benchmark, document>

Part of #<parent hypothesis>
BODY
)"
```

For `hdd:research`, `hdd:task`, and `hdd:hitl`, replace the **Oracle** section with what the answer must contain. An `hdd:hitl` body states the question and the options — never a guess at the answer.

## Link parent to child

GitHub sub-issues carry the relationship natively:

```bash
CHILD_ID=$(gh api repos/{owner}/{repo}/issues/<child> --jq .id)
gh api --method POST repos/{owner}/{repo}/issues/<parent>/sub_issues -F sub_issue_id=$CHILD_ID
```

Where sub-issues are unavailable, put `Part of #<parent>` at the top of the child body and a task list in the parent.

Link to the **nearest meaningful parent** only. Grandparents are reachable by walking, and restating those edges turns the graph into noise.

## AND and OR expansion

Both are the same mechanic — children plus a shape label on the parent:

```bash
gh issue edit <parent> --add-label hdd:and    # every required child must resolve
gh issue edit <parent> --add-label hdd:or     # children compete; one survives
```

Under `hdd:or`, each child is a full hypothesis with its own branch and draft PR, both based on the parent's branch, so the alternatives are built and compared independently.

## Fog

Fog lives in the **Fog** section of its owning hypothesis body, never as an issue. When evidence sharpens a patch of fog into something another agent could act on, file it as a work issue and delete that patch from the body — it now lives in exactly one place.

## Record state

```bash
gh issue edit <n> --add-label hdd:blocked    # add a comment naming what it waits on
gh issue edit <n> --add-label hdd:selected   # the survivor of an OR group
gh issue edit <n> --add-label hdd:pruned     # rejected, falsified, or superseded
gh issue edit <n> --add-label hdd:crystallized
```

Record the reasoning as a comment in the same call — a state label without its rationale loses the evidence that produced it.

Pruning an OR loser closes its workspace: comment the rationale, `gh pr close <n>`, and leave the branch alone unless there is a stated reason to keep it. The closed draft PR stays the archaeological record — diff, commits, failures, discussion — and the architecture document points at it.

## Applying `hdd:leaf` and `hdd:ready`

Apply either only when `/hdd` or `/hdd-crystallize` has established the claim it makes. `hdd:leaf` is a positive assertion that the search below a node is finished, so it goes on once and stays; it is not bookkeeping that follows the current child count up and down.
