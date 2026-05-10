# M10-F07-T01 Single Server Validation Runbook

## Task ID

`M10-F07-T01`

## Title

Create single-server deployment validation runbook.

## Goal

Document the exact validation process for the 4-core 4GB Docker Compose deployment.

## Scope

This task only does:

- Add deployment runbook.
- Add 4-core 4GB validation checklist.
- Add manual acceptance checklist for API, web apps, backup, restore, logs, and resource usage.

This task does not:

- Add new Docker services.
- Add automated load testing tooling.
- Add production secrets.
- Modify application code.

## Allowed Files

- `infra/RUNBOOK.md`
- `infra/VALIDATION_CHECKLIST.md`
- `infra/operations/RESOURCE_VALIDATION.md`
- `docs/plans/M10-F07-T01-single-server-validation-runbook.md`

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
- `infra/README.md`
- `infra/compose/README.md`
- `infra/nginx/README.md`
- `infra/scripts/README.md`
- `infra/operations/HEALTH_CHECKS.md`
- `infra/operations/LOGGING.md`

## Tests First

Before implementation, run:

```powershell
cd "D:\Codex\Study For Read Phone"
Test-Path "infra\README.md"
Test-Path "infra\compose\README.md"
```

Expected result:

- Prior deployment docs exist.

If prior docs are missing, stop and report the blocker.

## Implementation Steps

- [x] Step 1: Create `infra/RUNBOOK.md` with first deployment steps.
- [x] Step 2: Create `infra/VALIDATION_CHECKLIST.md` with container startup, API health, Web Reader, Web Admin, migrations, login, reading sync rejection of content fields, translation privacy, admin token rejection, backup, and restore checks.
- [x] Step 3: Create `RESOURCE_VALIDATION.md` with commands for CPU, memory, disk, and container status.
- [x] Step 4: Include a section for recording actual 4-core 4GB validation results.
- [x] Step 5: Include blocker reporting format for missing tools or incomplete apps.
- [x] Step 6: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone"
Select-String -Path "infra\RUNBOOK.md","infra\VALIDATION_CHECKLIST.md","infra\operations\RESOURCE_VALIDATION.md" -Pattern "4-core|4GB|health|backup|restore|forbidden|blocker"
```

## Acceptance Criteria

- Runbook and validation checklist exist.
- Checklist covers deployment, privacy, backup, restore, and resource usage.
- No code or Compose config is changed.
- Real validation results are not fabricated; they must be filled during execution.

## Stop Conditions

- Prior deployment docs are missing.
- Task requires pretending validation was run.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
