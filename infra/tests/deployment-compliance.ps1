$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$failures = New-Object System.Collections.Generic.List[string]
$passes = 0

function Resolve-RepoPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return Join-Path $repoRoot $Path
}

function Add-Pass {
    param([Parameter(Mandatory = $true)][string]$Message)
    $script:passes++
    Write-Host "PASS $Message"
}

function Add-Fail {
    param([Parameter(Mandatory = $true)][string]$Message)
    $script:failures.Add($Message)
    Write-Host "FAIL $Message"
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Condition) {
        Add-Pass $Message
    } else {
        Add-Fail $Message
    }
}

function Get-Text {
    param([Parameter(Mandatory = $true)][string]$Path)
    return Get-Content -Path (Resolve-RepoPath $Path) -Raw
}

function Test-TextDoesNotMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    Assert-True -Condition ($Text -notmatch $Pattern) -Message $Message
}

function Test-TextMatches {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    Assert-True -Condition ($Text -match $Pattern) -Message $Message
}

Push-Location $repoRoot
try {
    Assert-True -Condition (-not (Test-Path ".env")) -Message ".env does not exist"
    Assert-True -Condition (Test-Path ".env.example") -Message ".env.example exists"
    Assert-True -Condition (Test-Path "infra/docker-compose.yml") -Message "docker compose file exists"
    Assert-True -Condition (Test-Path "infra/nginx/nginx.conf") -Message "base Nginx config exists"
    Assert-True -Condition (Test-Path "infra/nginx/conf.d/study-for-read.conf") -Message "site Nginx config exists"

    $envExample = Get-Text ".env.example"
    $obviousSecretPattern = '(sk-[A-Za-z0-9_-]{12,}|ghp_[A-Za-z0-9_]{12,}|xox[baprs]-[A-Za-z0-9-]{12,}|AKIA[0-9A-Z]{16}|BEGIN (RSA |EC |OPENSSH |)?PRIVATE KEY|password123|secret123)'
    Test-TextDoesNotMatch -Text $envExample -Pattern $obviousSecretPattern -Message ".env.example has no obvious real secrets"
    Test-TextMatches -Text $envExample -Pattern 'change-me|placeholder|example' -Message ".env.example uses placeholder/example values"

    $composeOutput = & docker compose -f .\infra\docker-compose.yml config 2>&1
    $composeExit = $LASTEXITCODE
    $composeText = ($composeOutput | Out-String)
    Assert-True -Condition ($composeExit -eq 0) -Message "docker compose config renders"

    if ($composeExit -eq 0) {
        Test-TextDoesNotMatch -Text $composeText -Pattern '(?im)^\s{2}(redis|minio|s3|search|queue|object-storage|object_storage):\s*$' -Message "Compose has no redis/object storage/minio/s3/search/queue services"
        Test-TextDoesNotMatch -Text $composeText -Pattern '(?i)(user[-_ ]?book|book[-_ ]?upload|original[-_ ]?book|translation[-_ ]?corpus|full[-_ ]?book[-_ ]?translation)' -Message "Compose has no user book/original book/translation corpus/full-book translation storage"
        Test-TextDoesNotMatch -Text $composeText -Pattern '(?i)(5432:5432|published:\s*"?5432"?)' -Message "PostgreSQL is not publicly exposed"
        Test-TextMatches -Text $composeText -Pattern '(?im)^\s{2}nginx:\s*$' -Message "Compose includes nginx service"
        Test-TextMatches -Text $composeText -Pattern '(?im)^\s{2}api:\s*$' -Message "Compose includes api service"
        Test-TextMatches -Text $composeText -Pattern '(?im)^\s{2}postgres:\s*$' -Message "Compose includes postgres service"
    }

    $nginxText = (Get-Text "infra/nginx/nginx.conf") + "`n" + (Get-Text "infra/nginx/conf.d/study-for-read.conf")
    Test-TextDoesNotMatch -Text $nginxText -Pattern '\$request_body|request_body' -Message "Nginx config does not log request bodies"
    Test-TextMatches -Text $nginxText -Pattern 'location\s+/api/' -Message "Nginx routes /api/"
    Test-TextMatches -Text $nginxText -Pattern 'location\s+/admin/' -Message "Nginx routes /admin/"
    Test-TextMatches -Text $nginxText -Pattern 'location\s+/' -Message "Nginx routes /"

    $loggingDocs = (Get-Text "infra/operations/LOGGING.md") + "`n" + (Get-Text "infra/VALIDATION_CHECKLIST.md")
    Test-TextMatches -Text $loggingDocs -Pattern 'passwords' -Message "Deployment docs mention password logging boundary"
    Test-TextMatches -Text $loggingDocs -Pattern 'tokens' -Message "Deployment docs mention token logging boundary"
    Test-TextMatches -Text $loggingDocs -Pattern 'chapter content' -Message "Deployment docs mention chapter content logging boundary"
    Test-TextMatches -Text $loggingDocs -Pattern 'translated paragraph text' -Message "Deployment docs mention translated paragraph logging boundary"

    $backupScriptText = (Get-Text "infra/scripts/backup-postgres.ps1") + "`n" + (Get-Text "infra/scripts/restore-postgres.ps1")
    $backupText = $backupScriptText + "`n" + (Get-Text "infra/scripts/README.md")
    Test-TextDoesNotMatch -Text $backupText -Pattern '(?i)(Remove-Item\s+-Recurse|rm\s+-rf|rmdir\s+/s|rd\s+/s|del\s+/s)' -Message "Backup/restore artifacts contain no bulk deletion commands"
    Test-TextDoesNotMatch -Text $backupScriptText -Pattern '(?i)(retention|prun|delete\s+old\s+backup|prune\s+old\s+backup)' -Message "Backup scripts do not implement automated retention deletion"

    $infraFiles = Get-ChildItem -Path (Resolve-RepoPath "infra") -File -Recurse -Force |
        Where-Object {
            $_.FullName -notmatch '\\backups(\\|$)' -and
            $_.FullName -notmatch '\\tests(\\|$)'
        }
    $infraText = ($infraFiles | ForEach-Object { Get-Content -Path $_.FullName -Raw }) -join "`n"
    Test-TextDoesNotMatch -Text $infraText -Pattern '(BEGIN (RSA |EC |OPENSSH |)?PRIVATE KEY|sk-[A-Za-z0-9_-]{12,}|ghp_[A-Za-z0-9_]{12,}|xox[baprs]-[A-Za-z0-9-]{12,}|AKIA[0-9A-Z]{16}|password123|secret123)' -Message "Infra deployment artifacts contain no certificate private keys or obvious real secrets"

    if ($failures.Count -gt 0) {
        Write-Host ""
        Write-Host "Deployment compliance check failed with $($failures.Count) failure(s)."
        foreach ($failure in $failures) {
            Write-Host "FAIL $failure"
        }
        exit 1
    }

    Write-Host ""
    Write-Host "Deployment compliance check passed with $passes PASS checks."
    exit 0
}
finally {
    Pop-Location
}
