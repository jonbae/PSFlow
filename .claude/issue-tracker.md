# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues on `jonbae/PSFlow`. Use the
`gh` CLI for all operations; it infers the repo from `git remote -v`.

Note: `tickets/*.md` is a *separate*, older convention — long-form prose reports
on parity work. It is not the issue tracker and is not maintained by these
skills. Treat it as reference material.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."` (heredoc for multi-line bodies).
- **Read an issue**: `gh issue view <number> --comments`
- **List issues**: `gh issue list --state open --json number,title,body,labels`
- **Comment**: `gh issue comment <number> --body "..."`
- **Label**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

## Pull requests as a triage surface

**PRs as a request surface: no.**

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: an issue labelled `wayfinder:map`.
- **Child ticket**: a GitHub sub-issue of the map, via
  `gh api --method POST repos/jonbae/PSFlow/issues/<map>/sub_issues -F sub_issue_id=<child-db-id>`
  where `<child-db-id>` is the child's numeric **database id**
  (`gh api repos/jonbae/PSFlow/issues/<n> --jq .id`), *not* its `#number`.
  Labels: `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`).
- **Blocking**: GitHub native issue dependencies —
  `gh api --method POST repos/jonbae/PSFlow/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`.
  Read back via `issue_dependencies_summary.blocked_by` (counts open blockers only).
- **Frontier**: the map's open sub-issues with no open blockers and no assignee;
  first in map order wins.
  `gh api repos/jonbae/PSFlow/issues/<map>/sub_issues --jq '.[] | select(.state=="open") | select(.assignee==null) | select(.issue_dependencies_summary.blocked_by==0) | {number,title}'`
- **Claim**: `gh issue edit <n> --add-assignee @me` — the session's first write.
- **Resolve**: `gh issue comment <n> --body "<answer>"`, `gh issue close <n>`,
  then append a context pointer (gist + link) to the map's Decisions-so-far.
