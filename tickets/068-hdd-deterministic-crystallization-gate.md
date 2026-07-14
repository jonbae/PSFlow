# 068 — Deterministic crystallization gate for the `ps-hdd` workflow

## Context

The `ps-hdd` agent (`.claude/agents/ps-hdd.md`) runs the hole-driven loop —
explore → crystallize → generate — in one continuous context. Its central control
point is the **crystallization gate**: the human checkpoint where specification
error (a correctly-typed wrong answer) is caught, and the only point at which the
workflow is allowed to start writing to `src/`.

Today that gate is **soft** — enforced only by the agent's own prose ("STOP here,
present the scaffold, do not write to `src/` until the user approves"). This relies
on model cooperation, which the workflow design explicitly distrusts: a slash
command or a convention can be bypassed, and a single mis-step writes unreviewed
code into the canonical tree, erasing the invariant that **`src/` = crystallized**.

This ticket tracks making the gate **deterministic** — enforced by the Claude Code
harness via hooks, not by the model. It was scoped out of the agent-merge pass on
purpose (that pass was agent-definition only); it is the natural follow-up.

## Goal

Move the crystallization stop from discipline to interlock: the harness blocks any
`src/` write until a human-created approval marker exists, and it counts failed
build attempts to enforce the retry ceiling.

## Design

### Approval marker + PreToolUse gate

- Exploration writes only to a scratch dir (`.hdd/scratch/`) — **always allowed**.
- Nothing enters `src/` unless an approval marker `.hdd/approved` exists.
- A **`PreToolUse` hook** on `Write` and `Edit`:
  - path under `.hdd/scratch/` → allow
  - path under `src/` **and** `.hdd/approved` exists → allow
  - path under `src/` **and** no marker → **block (exit code 2)**, with the reason
    fed back to the model so it stops and asks for crystallization.
- The marker must be **model-inaccessible**: also gate `Bash` so the model cannot
  create `.hdd/approved` itself (block `touch`/`echo`/redirects targeting it). The
  human creating the marker by hand **is** the crystallization act.

### Retry-ceiling counter

- A **`PostToolUse`** hook counts failed `spago build` attempts and denies further
  `src/` writes once the 3-attempt ceiling is hit, forcing re-entry into
  exploration rather than trusting the model to count. (Reset the counter when a
  build passes or a new `.hdd/approved` is created.)

### Plumbing required

- Create `.claude/settings.json` — only `.claude/settings.local.json`
  (permissions-only, no `hooks` key) exists today; the shared hook config belongs
  in `settings.json` so it is version-controlled.
- Create `.claude/hooks/` with the gate script(s).
- Decide marker lifecycle: `.hdd/` should be git-ignored (scratch + marker are
  session-local, never committed).

## Open question (carry over from design)

**Gate style:** hard interlock (approval file the model can't cross, as above) vs.
native `permissionDecision: "ask"` confirmation (one keystroke, but model-adjacent).
The hard interlock matches the "enforce by harness, not trust" principle; the `ask`
form is lighter but re-introduces a model-adjacent decision. Resolve before building.

## Acceptance criteria

- A `Write`/`Edit` to any `src/` path is **blocked** by the harness when
  `.hdd/approved` is absent, and the block reason reaches the model.
- The same write **succeeds** once `.hdd/approved` exists.
- Writes under `.hdd/scratch/` are never blocked.
- The model cannot create `.hdd/approved` via `Bash` (attempt is blocked).
- After 3 failed `spago build` attempts, further `src/` writes are denied until
  re-crystallization; the counter resets on a passing build or a fresh marker.
- Hook config lives in a committed `.claude/settings.json`; `.hdd/` is git-ignored.

## Source files

- **Create** `.claude/settings.json` — `hooks` config (`PreToolUse`, `PostToolUse`)
- **Create** `.claude/hooks/` — gate script(s)
- **Reference** `.claude/agents/ps-hdd.md` — "Crystallization Gate" section (the soft
  gate this ticket hardens) and the pointer that links here
- **Reference** `.claude/settings.local.json` — existing permissions-only settings
