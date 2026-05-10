# Deployment Compliance Checks

This directory contains local deployment compliance checks for first-release infrastructure artifacts.

## Run

From the repository root:

```powershell
.\infra\tests\deployment-compliance.ps1
```

The script prints `PASS` or `FAIL` for each check and exits with code `1` when any check fails.

## Boundary

The check is static and local:

- It confirms `.env` does not exist.
- It renders Docker Compose config without starting the live stack.
- It checks for forbidden services such as object storage, search, queues, and Redis.
- It checks that PostgreSQL is not published on `5432`.
- It checks that Nginx does not log request bodies or use `request_body`.
- It checks that deployment docs mention forbidden log content.
- It checks backup docs/scripts for automated deletion or retention pruning.
- It scans infra deployment artifacts for obvious secret or private key patterns.

The check does not require real secrets, does not contact a live backend, and does not create `.env`.

## Fix Policy

If this check fails, first confirm whether the failure is a real deployment compliance leak. Fix only the deployment files allowed by the active task card. Do not change application code, server code, mobile code, web app code, or old project files to satisfy this check.
