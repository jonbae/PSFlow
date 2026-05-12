# 022 — Rename `src/XYFlow/` → `src/System/`

## Title

Rename the existing PureScript system port directory from `XYFlow` to `System` to mirror `xyflow-main/packages/{system,react}/`. Prerequisite for tickets 023–049.

## Why

The React layer port (tickets 023–049) lives at `src/React/` as a sibling of the system layer. To keep the directory tree mirroring `xyflow-main/packages/`, the existing `src/XYFlow/` becomes `src/System/`. The React port imports heavily from the system layer, so this rename must happen first to avoid massive churn later.

## Scope

A pure rename. No semantic or behavioural change. No new modules. No FFI changes. No dependency changes.

## Concrete Steps

1. **Move the directory.**

   ```
   git mv src/XYFlow src/System
   ```

2. **Rewrite module headers.** For every `*.purs` file under `src/System/`:

   ```
   module XYFlow.X.Y where  →  module System.X.Y where
   ```

3. **Rewrite imports across the repo.** In every `.purs` file (including `test/`):

   ```
   import XYFlow.…  →  import System.…
   ```

4. **Rewrite FFI module-name comments.** Every `.js` file under `src/System/` that has a `// module XYFlow.X.Y` header gets the prefix updated.

5. **Update `spago.yaml`** if it pins module paths or uses an `XYFlow` prefix in any `dependencies`/`workspaces`/`bundle.entryPoint` field. (At time of writing it should only need `package.name` review — keep `ps-flow` as the package name.)

6. **Update `test/Test/Main.purs`** imports.

7. **Append a one-line note to `tickets/000-overview.md`:**
   > Note (2026-05): the system port directory was renamed `src/XYFlow/` → `src/System/` in ticket 022 to match `xyflow-main/packages/system/`. Module paths in tickets 001–021 read `XYFlow.*` for historical accuracy; on disk they are `System.*`.

## Out of Scope

- Renaming the package itself (`package.name` in `spago.yaml` stays `ps-flow`).
- Renaming the npm-style scope. There is no npm publish here.
- Editing tickets 001–021's body text (treat as historical).
- Any code-behaviour change.

## Tooling Hints

- Use `Grep` / `rg` with `-n` to enumerate occurrences first, then do the substitution with `Edit replace_all` per file (or a one-shot scripted sed pass — but verify diff before committing).
- Run `spago build` between the directory move and the import rewrite to confirm the failure mode (every `import XYFlow.…` now fails); the green build after the rewrite is the gate.

## Prerequisite Tickets

- 001–021 (the entire system port must already be on disk, otherwise there is nothing to rename).

## Acceptance Criteria

- `src/XYFlow/` no longer exists; `src/System/` contains the same tree.
- `git grep -n 'XYFlow\.' src/ test/` returns zero results in `.purs` and `.js` files.
- `spago build` exits 0 with no new warnings.
- `spago test` exits 0; existing system test suite passes unchanged.
- Module names in compile output now read `System.*`.
- A note mentioning the rename is appended to `tickets/000-overview.md`.
