# Single Server Deployment Runbook

This runbook is for the first 4-core 4GB single-server Docker Compose deployment. It documents the sequence operators should run and the evidence they should record. Do not fabricate results; if a step was not executed, mark it `Not run` or `Pending`.

## Prerequisites

Confirm the target host has:

- One Linux server with 4 CPU cores and 4GB RAM.
- Docker and Docker Compose available.
- Git access to the repository.
- Network access for pulling base images and runtime images.
- Operator-managed secrets available outside source control.

Record blockers using this format:

```text
Blocker:
Category: missing tools | Docker unavailable | incomplete apps | failed health checks | privacy/compliance failures | other
Command:
Observed result:
Expected result:
Next owner:
```

## First Deployment Steps

1. Fetch the intended commit.

```powershell
git status --short --branch
git rev-parse HEAD
```

2. Build the server image.

```powershell
docker build -t study-for-read-api:local .\server
```

3. Build Web Reader static assets.

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-reader"
npm ci
npm run build
```

4. Build Web Admin static assets.

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-admin"
npm ci
npm run build
```

5. Prepare runtime environment locally from `.env.example`.

```powershell
cd "D:\Codex\Study For Read Phone"
Copy-Item .env.example .env
```

Replace every `change-me`, `placeholder`, and `example` value in the local `.env`. Do not commit `.env`. Do not paste real passwords, tokens, provider keys, or production hostnames into repository files.

6. Validate Compose rendering.

```powershell
docker compose -f .\infra\docker-compose.yml config
```

7. Start the stack.

```powershell
docker compose -f .\infra\docker-compose.yml up -d
docker compose -f .\infra\docker-compose.yml ps
```

8. Inspect logs without copying secrets or private user content.

```powershell
docker compose -f .\infra\docker-compose.yml logs --tail 200
```

Logs must not include passwords, tokens, original book content, chapter content, raw lookup text, raw paragraph text, or translated paragraph text.

## Health Checks

Nginx static health:

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing
```

Container health:

```powershell
docker compose -f .\infra\docker-compose.yml ps
```

Expected state:

- `postgres`: healthy.
- `api`: healthy.
- `nginx`: running.

API health is checked inside the API container by Compose. Public API behavior should be validated through Nginx using `/api/` routes.

## Rollback Notes

If validation fails, do not invent a passing result. Record the blocker, preserve the failing command output with secrets redacted, and choose one rollback path:

- Keep the previous deployment running and do not switch traffic.
- Stop the new stack if it is isolated.
- Rebuild from the last known-good commit.

Do not delete live database data while rolling back.

## Validation Record

Use `infra/VALIDATION_CHECKLIST.md` and `infra/operations/RESOURCE_VALIDATION.md` for the actual acceptance record. Any item not executed must stay `Pending` or `Not run`.
