# M10-F03-T01 Docker Compose Core Stack

## Task ID

`M10-F03-T01`

## Title

Add Docker Compose core stack.

## Goal

Define the first single-server Docker Compose stack for Nginx, API, and PostgreSQL.

## Scope

This task only does:

- Add Docker Compose file.
- Add Compose environment wiring.
- Add named volumes for PostgreSQL data and backups.
- Add health checks.
- Add compose validation documentation.

This task does not:

- Add Nginx route config details.
- Add backup scripts.
- Add Redis.
- Add object storage or upload volumes.

## Allowed Files

- `infra/docker-compose.yml`
- `infra/compose/README.md`
- `.env.example`
- `docs/plans/M10-F03-T01-docker-compose-core-stack.md`

## Forbidden Files

- `.env`
- `server/**`
- `apps/**`
- `infra/nginx/**`
- `infra/scripts/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DEPLOYMENT.md`
- `.env.example`
- `server/README_DEPLOYMENT.md`

## Tests First

Before implementation, run:

```powershell
cd "D:\Codex\Study For Read Phone"
Test-Path ".env.example"
Test-Path "server\Dockerfile"
```

Expected result:

- Environment contract and server Dockerfile exist.

If either is missing, stop and report the prior task blocker.

## Implementation Steps

- [x] Step 1: Create `infra/docker-compose.yml` with `nginx`, `api`, and `postgres`.
- [x] Step 2: Wire API database variables from environment.
- [x] Step 3: Add PostgreSQL named data volume.
- [x] Step 4: Add host-mounted backup directory path placeholder.
- [x] Step 5: Add health checks for API and PostgreSQL.
- [x] Step 6: Ensure PostgreSQL is not published to the public host interface.
- [x] Step 7: Do not add Redis unless a later task explicitly enables it.
- [x] Step 8: Create `infra/compose/README.md`.
- [x] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone"
docker compose -f .\infra\docker-compose.yml config
```

## Acceptance Criteria

- Compose config validates.
- Required services are `nginx`, `api`, and `postgres`.
- PostgreSQL has a persistent data volume.
- No user book storage, object storage, or translation corpus volume exists.
- Redis is absent unless explicitly enabled by a later task.

## Stop Conditions

- Environment contract task is incomplete.
- Server container build task is incomplete.
- Compose validation requires real secrets.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
