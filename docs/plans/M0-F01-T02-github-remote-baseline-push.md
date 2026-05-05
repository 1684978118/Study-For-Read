# M0-F01-T02 GitHub Remote Baseline Push

## Task ID

`M0-F01-T02`

## Title

Connect the new project to the GitHub remote and push the planning baseline.

## Goal

Push the current planning documents from `D:\Codex\Study For Read Phone` to the user-provided GitHub repository while preserving existing remote history.

## Scope

This task only does:

- Configure Git remote `origin`.
- Fetch the remote `main` branch.
- Preserve existing remote files such as `README.md`.
- Commit local planning documents and `.gitignore` on top of the remote branch.
- Push to `origin/main`.
- If the user explicitly approves overwriting remote history, push with `--force-with-lease`.

This task does not:

- Plain `git push --force`.
- Delete remote files.
- Delete local files.
- Create backend, mobile, web, admin, or infra code.
- Modify old project files under `D:\Codex\Study for Read`.
- Add dependencies.
- Start M1 implementation.

## Allowed Files

This task may create or modify only:

- `.gitignore`
- `README.md` if it comes from the existing remote branch
- Git metadata under `.git`

This task may stage and commit existing planning documents and `AGENTS.md`, but must not edit them.

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
- `docs/plans/M0_REPOSITORY_SAFETY.md`
- `docs/plans/M0-F01-T01-git-baseline.md`

## Tests First

Run before changes:

```powershell
git ls-remote https://github.com/1684978118/Study-For-Read.git
git -C "D:\Codex\Study For Read Phone" status --short
```

Expected result:

- Remote command lists refs or reports authentication/network failure.
- Local status either reports not a Git repository or shows current local state.

## Implementation Steps

- [ ] Step 1: Read all `Read First` files.
- [ ] Step 2: Confirm remote URL is `https://github.com/1684978118/Study-For-Read.git`.
- [ ] Step 3: If local project is not a Git repository, run `git init`.
- [ ] Step 4: Add remote `origin` if missing.
- [ ] Step 5: Fetch `origin main`.
- [ ] Step 6: Check out local `main` from `origin/main` when the remote branch exists.
- [ ] Step 7: Create root `.gitignore` if missing.
- [ ] Step 8: Stage `.gitignore`, `AGENTS.md`, and planning documents.
- [ ] Step 9: Do not stage unrelated scratch files.
- [ ] Step 10: Commit with message `chore: add planning baseline`.
- [ ] Step 11: Push to `origin/main` without force unless the user explicitly approved overwriting remote history.
- [ ] Step 12: If overwrite was approved, push with `--force-with-lease origin main`.
- [ ] Step 13: Run verification commands.

## Verification Commands

```powershell
git -C "D:\Codex\Study For Read Phone" status --short
git -C "D:\Codex\Study For Read Phone" remote -v
git -C "D:\Codex\Study For Read Phone" log --oneline -3
git ls-remote https://github.com/1684978118/Study-For-Read.git refs/heads/main
```

## Acceptance Criteria

- Local repository uses `origin` set to `https://github.com/1684978118/Study-For-Read.git`.
- Local `main` preserves the existing remote `README.md`.
- Baseline planning documents are committed.
- Push to `origin/main` succeeds.
- Plain `git push --force` is not used.
- No business code directories are created.
- No old project files are modified.
- Unrelated scratch files remain untracked.

## Stop Conditions

- Remote repository contains conflicting project files beyond simple metadata.
- Git authentication fails during push.
- Checkout would overwrite local files.
- Commit fails because Git identity is missing.
- Any operation requires plain `git push --force`.
- Any command would delete files or directories.

## Completion Report Format

Reply with:

- Modified files.
- Git repository state.
- Remote URL.
- Verification command.
- Verification result.
- Commit hash pushed, or blocker.
- Recommended next task card.
