# Logging

The first-release deployment uses Docker container logs. No separate metrics, dashboard, log aggregation, or search service is part of this stack.

## Commands

Run commands from the repository root.

Show recent logs for all services:

```powershell
docker compose -f .\infra\docker-compose.yml logs --tail 200
```

Follow logs for all services:

```powershell
docker compose -f .\infra\docker-compose.yml logs -f
```

Inspect one service:

```powershell
docker compose -f .\infra\docker-compose.yml logs --tail 200 api
docker compose -f .\infra\docker-compose.yml logs --tail 200 nginx
docker compose -f .\infra\docker-compose.yml logs --tail 200 postgres
```

## Forbidden Log Content

Operational logs must not include:

- passwords
- tokens
- original book content
- chapter content
- raw lookup text
- raw paragraph text
- translated paragraph text

If any of these appear in logs, treat it as a privacy incident. Stop copying the logs into tickets or chat, capture only the minimal metadata needed to reproduce the issue, and open a follow-up task to fix the application or infrastructure logging boundary.

## Nginx Request Body Boundary

Nginx logging must not include request bodies. The Nginx configuration should use normal access logs only and must not add a request-body variable to any log format.

Request paths, status codes, response sizes, and timing are acceptable operational metadata. Request bodies may contain user text and must stay out of logs.

## Secrets

Secrets come from runtime environment configuration. Do not paste `.env` values, JWT secrets, database passwords, translation provider keys, access tokens, refresh tokens, or admin tokens into logs, tickets, commits, or screenshots.
