# M10-F08-T01 Deployment Compliance Regression

## Task ID

`M10-F08-T01`

## Title

Add deployment compliance regression checks.

## Goal

Protect deployment artifacts from introducing cloud book storage, raw content logging, public database exposure, or committed secrets.

## Scope

This task only does:

- Add deployment compliance check script.
- Add tests/checks for forbidden files, services, volumes, ports, and log settings.
- Fix only deployment compliance leaks found by those checks.

This task does not:

- Add application features.
- Add live load testing.
- Add Kubernetes.
- Add object storage.

## Allowed Files

- `infra/tests/deployment-compliance.ps1`
- `infra/tests/README.md`
- If and only if checks expose a deployment compliance failure, these files may be modified:
  - `.env.example`
  - `infra/docker-compose.yml`
  - `infra/nginx/nginx.conf`
  - `infra/nginx/conf.d/study-for-read.conf`
  - `infra/README.md`
  - `infra/compose/README.md`
  - `infra/nginx/README.md`
  - `infra/scripts/README.md`
  - `infra/operations/LOGGING.md`
  - `infra/VALIDATION_CHECKLIST.md`

## Forbidden Files

- `.env`
- `server/**`
- `apps/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DEPLOYMENT.md`
- All M10 deployment task cards.

## Tests First

Create:

- `infra/tests/deployment-compliance.ps1`

Check behavior:

- `.env` does not exist.
- `.env.example` does not contain obvious real secrets.
- Docker Compose does not define object storage services.
- Docker Compose does not define user book upload volumes.
- Docker Compose does not publish PostgreSQL publicly.
- Nginx config does not log request bodies.
- Nginx routes `/api/`, `/admin/`, and `/`.
- Deployment docs mention forbidden content logging.
- Backup docs do not implement automated deletion of backup files.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone"
Test-Path "infra\tests\deployment-compliance.ps1"
```

Expected red result:

- Check script does not exist yet.

## Implementation Steps

- [ ] Step 1: Write `deployment-compliance.ps1`.
- [ ] Step 2: Run the compliance check.
- [ ] Step 3: If checks pass, do not change deployment artifacts.
- [ ] Step 4: If checks fail due to deployment compliance leaks, fix only the relevant Allowed Files.
- [ ] Step 5: Run compliance check again.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone"
.\infra\tests\deployment-compliance.ps1
```

## Acceptance Criteria

- Deployment compliance check passes.
- No real `.env` file is created.
- No object storage, user book upload volume, or raw translation corpus storage exists.
- PostgreSQL is not publicly exposed.
- Nginx does not log request bodies.
- No application source code is modified.

## Stop Conditions

- Prior M10 deployment tasks are incomplete.
- Compliance fix requires modifying application code.
- Fix requires deleting files or directories in bulk.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

