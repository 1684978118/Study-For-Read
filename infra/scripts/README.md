# PostgreSQL Backup And Restore

These scripts run PostgreSQL tools through the compose `postgres` container. They rely on environment values already present in the container, so database credentials are not written into scripts or committed files.

## Backup

From the repository root:

```powershell
.\infra\scripts\backup-postgres.ps1
```

The backup script runs `pg_dump` inside the PostgreSQL container and writes a custom-format dump into the mounted backup directory. File names include a UTC timestamp, for example:

```text
study-for-read-postgres-20260510T030000Z.dump
```

You can override the compose file, service name, file prefix, or in-container output directory with script parameters. Do not print or paste database passwords into command lines.

## Restore Validation

Restore validation must use a non-production target database/container. The script refuses to run unless both guard values are present:

```powershell
.\infra\scripts\restore-postgres.ps1 `
  -BackupFileInContainer "/backups/study-for-read-postgres-20260510T030000Z.dump" `
  -TargetDatabase "study_for_read_restore_test" `
  -ConfirmNonProduction `
  -ConfirmationText "RESTORE_NON_PRODUCTION"
```

The target database must be fresh. The script creates the target database and runs `pg_restore` with `--no-owner --no-privileges`.

## Operational Boundary

Use host or deployment environment secret handling for credentials. Do not commit `.env`, database passwords, tokens, provider keys, or backup artifacts.

Automated pruning of old backup files is out of scope for this task. Cloud uploads and external storage integrations are also out of scope.
