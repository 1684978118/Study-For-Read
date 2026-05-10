# Docker Compose Core Stack

This directory documents the first-release core Docker Compose stack. The stack contains only:

- `nginx`: public HTTP entrypoint and static asset placeholder service.
- `api`: Spring Boot API image built from `server/Dockerfile`.
- `postgres`: PostgreSQL database with a persistent named data volume.

## Local Environment

Create a local `.env` manually from the repository root `.env.example` when you need to run the stack:

```powershell
Copy-Item .env.example .env
```

This task does not create `.env`. Replace every `change-me`, `placeholder`, or `example` value locally before using the stack outside disposable development checks.

## Validate Compose

From the repository root:

```powershell
docker compose -f .\infra\docker-compose.yml config
```

## Service Boundary

PostgreSQL is only exposed to other compose services and is not published to the public host interface. Do not publish the database port in the first-release stack.

The backup directory mount is a placeholder for later backup and restore tasks:

```text
${POSTGRES_BACKUP_HOST_DIR:-../infra/backups}
```

No backup scripts are created in this task. This stack also does not add cache services, external storage services, user book storage, upload volumes, or provider corpus storage.

Nginx route configuration and production static asset wiring are intentionally left for the later Nginx task. The current compose file only reserves the service boundary.
