# Health Checks

This runbook describes the first-release health checks for the single-server Docker Compose deployment.

## Services

The core stack has three services:

- `nginx`: public entrypoint for `/`, `/admin/`, `/api/`, and `/health`.
- `api`: Spring Boot API behind Nginx.
- `postgres`: PostgreSQL database used by the API.

Run health inspection from the repository root:

```powershell
docker compose -f .\infra\docker-compose.yml ps
```

Expected steady state:

- `postgres` is `healthy`.
- `api` is `healthy` after PostgreSQL is ready and migrations have completed.
- `nginx` is `running`; it depends on a healthy API before startup.

## Nginx Health

Nginx serves a static health response at:

```text
/health
```

The route verifies that Nginx is running and that the static health file is mounted. It does not prove database connectivity or API readiness.

Example local check:

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing
```

## API Health

The API container healthcheck calls the API health endpoint inside the Docker network:

```text
http://localhost:8080/actuator/health
```

This is an internal container check. Public callers should use `/api/` routes through Nginx. If the API healthcheck is failing, inspect API logs and database health before restarting services.

## PostgreSQL Health

PostgreSQL uses `pg_isready` with the configured database and user:

```text
pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

This confirms PostgreSQL is accepting connections. It does not validate application migrations or application-level behavior.

## Boundaries

- `/health` is an Nginx static health route.
- API health is owned by the API container healthcheck.
- PostgreSQL health is owned by the PostgreSQL container healthcheck.
- Health checks must not log passwords, tokens, chapter content, original book content, raw lookup text, raw paragraph text, or translated paragraph text.
