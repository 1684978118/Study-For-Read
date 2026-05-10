param(
    [Parameter(Mandatory = $true)]
    [string]$BackupFileInContainer,

    [Parameter(Mandatory = $true)]
    [string]$TargetDatabase,

    [switch]$ConfirmNonProduction,

    [string]$ConfirmationText = "",
    [string]$ComposeFile = "infra/docker-compose.yml",
    [string]$PostgresService = "postgres"
)

$ErrorActionPreference = "Stop"

if (-not $ConfirmNonProduction -or $ConfirmationText -ne "RESTORE_NON_PRODUCTION") {
    throw "Refusing restore. Pass -ConfirmNonProduction and -ConfirmationText RESTORE_NON_PRODUCTION for a non-production target."
}

if ($TargetDatabase -match '(?i)(prod|production|live)') {
    throw "Refusing restore into a target database name that looks like production/live data."
}

if ($TargetDatabase -notmatch '^[a-zA-Z0-9_]+$') {
    throw "TargetDatabase may only contain letters, numbers, and underscores."
}

Write-Host "Preparing restore into non-production database: $TargetDatabase"
Write-Host "Backup path inside container: $BackupFileInContainer"

$restoreCommand = @'
set -eu
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE" >&2
  exit 1
fi
if psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$TARGET_DB'" | grep -q 1; then
  echo "Target database already exists. Use a fresh non-production target name." >&2
  exit 1
fi
createdb -U "$POSTGRES_USER" "$TARGET_DB"
pg_restore -U "$POSTGRES_USER" -d "$TARGET_DB" --no-owner --no-privileges "$BACKUP_FILE"
'@

$dockerArgs = @(
    "compose",
    "-f", $ComposeFile,
    "exec",
    "-T",
    "-e", "BACKUP_FILE=$BackupFileInContainer",
    "-e", "TARGET_DB=$TargetDatabase",
    $PostgresService,
    "sh",
    "-lc",
    $restoreCommand
)

& docker @dockerArgs
if ($LASTEXITCODE -ne 0) {
    throw "restore failed with exit code $LASTEXITCODE."
}

Write-Host "Restore complete for non-production database: $TargetDatabase"
