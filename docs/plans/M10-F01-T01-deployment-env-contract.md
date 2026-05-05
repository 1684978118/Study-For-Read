# M10-F01-T01 Deployment Env Contract

## Task ID

`M10-F01-T01`

## Title

Create deployment environment contract.

## Goal

Document all runtime environment variables, secret handling rules, and first-release deployment boundaries.

## Scope

This task only does:

- Add `.env.example` with placeholders only.
- Add deployment environment documentation.
- Add tests or checks proving real secrets are not committed.

This task does not:

- Add Docker Compose services.
- Add Dockerfiles.
- Add Nginx config.
- Add backup scripts.

## Allowed Files

- `.env.example`
- `infra/README.md`
- `infra/env/README.md`
- `docs/specs/DEPLOYMENT.md`
- `docs/plans/M10-F01-T01-deployment-env-contract.md`

## Forbidden Files

- `.env`
- `server/**`
- `apps/**`
- `infra/docker-compose.yml`
- `infra/nginx/**`
- `infra/scripts/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DEPLOYMENT.md`
- `docs/specs/ARCHITECTURE.md`

## Tests First

Create or update checks in documentation:

- List every required environment variable from `DEPLOYMENT.md`.
- Confirm `.env.example` contains placeholder values only.
- Confirm `.env` is not created.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone"
Test-Path ".env"
Test-Path ".env.example"
```

Expected red or neutral result:

- `.env.example` may not exist yet.
- `.env` must not be created by this task.

## Implementation Steps

- [ ] Step 1: Read deployment spec and list required variables.
- [ ] Step 2: Create `.env.example` with placeholder values only.
- [ ] Step 3: Create `infra/README.md` with first deployment overview.
- [ ] Step 4: Create `infra/env/README.md` explaining secret handling and how to create local `.env` manually.
- [ ] Step 5: Ensure no real API keys, passwords, tokens, or hostnames are committed.
- [ ] Step 6: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone"
Select-String -Path ".env.example","infra\\README.md","infra\\env\\README.md" -Pattern "change-me|placeholder|example"
Test-Path ".env"
```

## Acceptance Criteria

- `.env.example` exists with placeholders only.
- Real `.env` is not created.
- Environment docs explain secret boundaries.
- No Docker services are created in this task.

## Stop Conditions

- User provides real secrets in chat or files.
- Task requires creating `.env` with real values.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

