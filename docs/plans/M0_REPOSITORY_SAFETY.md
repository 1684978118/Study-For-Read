# M0 Repository Safety Plan

> For AI workers: read `AGENTS.md`, `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`, `docs/plans/MASTER_IMPLEMENTATION_ROADMAP.md`, `docs/plans/IMPLEMENTATION_START_GATE.md`, and the task card before doing any setup work. Execute one task card at a time.

## Goal

Create a minimal version-control safety baseline before business implementation starts.

## Scope

This milestone does:

- Confirm the new project directory is the only write target.
- Initialize Git if the new project is not already a Git repository.
- Add a root `.gitignore` for generated build outputs, IDE files, secrets, logs, and dependency folders.
- Create the first baseline commit if Git is available.
- Record blockers if Git is missing or the directory is already controlled by another repository.

This milestone does not:

- Create backend, mobile, web, admin, or infra code.
- Modify old project files.
- Delete files.
- Move files.
- Add dependencies.
- Change product, API, data model, or UI specifications.

## Required Prior Milestones

None.

This milestone exists because AI-assisted development needs a visible diff and a rollback point before code generation begins.

## Task Order

1. `M0-F01-T01-git-baseline.md`
2. `M0-F01-T02-github-remote-baseline-push.md`

## Milestone Acceptance

Milestone 0 is complete when:

- `D:\Codex\Study For Read Phone` is a Git repository, or a real blocker is reported.
- Root `.gitignore` exists if Git initialization is performed.
- `git status --short` can run from the new project directory.
- GitHub remote is configured when the user provides a remote URL.
- Existing remote history is preserved unless the user explicitly approves overwriting it.
- If overwriting remote history is explicitly approved, use `--force-with-lease`, not plain `--force`.
- Existing planning documents remain present.
- No business code has been created.
- Old project files under `D:\Codex\Study for Read` are untouched.
