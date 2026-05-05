# M0-F01-T01 Git Baseline

## Task ID

`M0-F01-T01`

## Title

Initialize Git safety baseline for the new project.

## Goal

Make future AI code changes trackable before any backend, mobile, web, admin, or deployment implementation begins.

## Scope

This task only does:

- Check whether `D:\Codex\Study For Read Phone` is already a Git repository.
- Run `git init` only if it is not already a Git repository.
- Create a root `.gitignore` for generated files, local secrets, logs, and dependency folders.
- Run `git status --short`.
- Optionally create a baseline commit containing only existing planning documents and the root `.gitignore`.

This task does not:

- Create `server`.
- Create `apps`.
- Create `infra`.
- Modify any files under `docs/specs`.
- Modify any old project path under `D:\Codex\Study for Read`.
- Delete any file or directory.
- Add dependencies.
- Start implementation of M1.

## Allowed Files

This task may create or modify only:

- `.gitignore`
- Git metadata created by `git init`

This task may stage existing planning documents for the baseline commit, but must not edit them.

## Forbidden Files

This task must not modify:

- `server/**`
- `apps/**`
- `infra/**`
- `docs/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`
- `docs/plans/MASTER_IMPLEMENTATION_ROADMAP.md`
- `docs/plans/IMPLEMENTATION_START_GATE.md`
- `docs/plans/M0_REPOSITORY_SAFETY.md`

## Tests First

This is a repository setup task, so the first verification is a repository-state check.

Run before changes:

```powershell
git -C "D:\Codex\Study For Read Phone" status --short
```

Expected result:

- If the directory is not a Git repository, Git reports `fatal: not a git repository`.
- If the directory is already a Git repository, Git prints a short status list or no output.

## Implementation Steps

- [ ] Step 1: Read all `Read First` files.
- [ ] Step 2: Run the before-change repository-state check.
- [ ] Step 3: If the directory is already a Git repository, do not run `git init`; skip to Step 6.
- [ ] Step 4: Run `git init` in `D:\Codex\Study For Read Phone`.
- [ ] Step 5: Create root `.gitignore` with generated files, local secrets, logs, and dependency folders.
- [ ] Step 6: Run `git status --short`.
- [ ] Step 7: Confirm no old project files are staged.
- [ ] Step 8: If Git user name/email is configured, create a baseline commit.
- [ ] Step 9: If Git user name/email is not configured, stop and report the blocker without faking a commit.

## Root .gitignore Target

If `.gitignore` must be created, use this content:

```gitignore
# Local environment
.env
.env.*
!.env.example

# Logs
*.log
logs/

# OS and IDE
.DS_Store
Thumbs.db
.idea/
.vscode/

# Java / Spring Boot
target/
*.class

# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
build/

# Node / Nuxt
node_modules/
.nuxt/
.output/
dist/

# Coverage and caches
coverage/
.nyc_output/
.pytest_cache/

# Docker/local runtime
tmp/
data/
```

## Verification Commands

```powershell
git -C "D:\Codex\Study For Read Phone" status --short
git -C "D:\Codex\Study For Read Phone" rev-parse --show-toplevel
```

If a baseline commit is created, also run:

```powershell
git -C "D:\Codex\Study For Read Phone" log --oneline -1
```

## Acceptance Criteria

- `git status --short` runs without `fatal: not a git repository`.
- `git rev-parse --show-toplevel` prints `D:/Codex/Study For Read Phone` or the Windows-equivalent path.
- Root `.gitignore` exists if Git was initialized by this task.
- No files under `D:\Codex\Study for Read` are modified or staged.
- No business code directories are created.
- If baseline commit cannot be created because Git identity is missing, the blocker is reported clearly.

## Stop Conditions

- Git is not installed.
- Git reports the directory is inside an unexpected parent repository.
- Running `git init` would target any path other than `D:\Codex\Study For Read Phone`.
- Any implementation requires modifying files outside Allowed Files.
- Any command would delete files or directories.
- Git identity is missing when attempting to commit.

## Completion Report Format

Reply with:

- Modified files.
- Git repository state.
- Verification command.
- Verification result.
- Baseline commit hash, or blocker if no commit was created.
- Recommended next task card.

