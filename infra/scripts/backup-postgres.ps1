param(
    [string]$ComposeFile = "infra/docker-compose.yml",
    [string]$PostgresService = "postgres",
    [string]$BackupDirectoryInContainer = "/backups",
    [string]$FilePrefix = "study-for-read"
)

$ErrorActionPreference = "Stop"

if ($FilePrefix -notmatch '^[a-zA-Z0-9._-]+$') {
    throw "FilePrefix may only contain letters, numbers, dots, underscores, and dashes."
}

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$backupFileName = "$FilePrefix-postgres-$timestamp.dump"
$backupPath = "$BackupDirectoryInContainer/$backupFileName"

Write-Host "Creating PostgreSQL backup with UTC timestamp $timestamp"
Write-Host "Output path inside container: $backupPath"

$dockerArgs = @(
    "compose",
    "-f", $ComposeFile,
    "exec",
    "-T",
    "-e", "BACKUP_FILE=$backupPath",
    $PostgresService,
    "sh",
    "-lc",
    'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc -f "$BACKUP_FILE"'
)

& docker @dockerArgs
if ($LASTEXITCODE -ne 0) {
    throw "pg_dump failed with exit code $LASTEXITCODE."
}

Write-Host "Backup complete: $backupPath"
