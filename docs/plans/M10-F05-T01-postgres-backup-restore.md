# M10-F05-T01 Postgres Backup Restore

## Task ID

`M10-F05-T01`

## Title

Add PostgreSQL backup and restore workflow.

## Goal

Provide safe, documented PostgreSQL backup and restore scripts for the single-server deployment.

## Scope

This task only does:

- Add backup script.
- Add restore script for test restore workflow.
- Add backup documentation.
- Add verification steps against a non-production database/container.

This task does not:

- Add automated retention deletion.
- Delete live data.
- Add cloud backup upload.
- Add object storage.

## Allowed Files

- `infra/scripts/backup-postgres.ps1`
- `infra/scripts/restore-postgres.ps1`
- `infra/scripts/README.md`
- `infra/docker-compose.yml`
- `docs/plans/M10-F05-T01-postgres-backup-restore.md`

## Forbidden Files

- `.env`
- `server/**`
- `apps/**`
- `infra/nginx/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DEPLOYMENT.md`
- `infra/docker-compose.yml`

## Tests First

Before implementation, run:

```powershell
cd "D:\Codex\Study For Read Phone"
Test-Path "infra\docker-compose.yml"
```

Expected result:

- Compose file exists.

If Compose file is missing, stop and report that M10-F03-T01 is incomplete.

## Implementation Steps

- [x] Step 1: Create `backup-postgres.ps1` that runs `pg_dump` through the PostgreSQL container.
- [x] Step 2: Name backup files with UTC timestamp.
- [x] Step 3: Ensure script does not print database password.
- [x] Step 4: Create `restore-postgres.ps1` for restoring into a named target database/container.
- [x] Step 5: Add guard text requiring restore target confirmation and forbidding live production overwrite in tests.
- [x] Step 6: Add backup and restore docs.
- [x] Step 7: Do not implement retention deletion in this task.
- [ ] Step 8: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone"
Test-Path "infra\scripts\backup-postgres.ps1"
Test-Path "infra\scripts\restore-postgres.ps1"
Select-String -Path "infra\scripts\*.ps1","infra\scripts\README.md" -Pattern "pg_dump|restore|UTC|production"
```

## Acceptance Criteria

- Backup and restore scripts exist.
- Scripts document safe usage.
- Scripts do not require committing secrets.
- Restore workflow is designed for a non-production target during validation.
- No backup retention deletion is implemented.

## Stop Conditions

- Docker Compose task is incomplete.
- Task requires deleting or overwriting live data.
- Task requires real database password in a committed file.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
