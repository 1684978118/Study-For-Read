# Resource Validation

This document records 4-core 4GB single-server resource validation. Do not fabricate results. If a command was not run, mark the result as `Not run` or `Pending`.

## Target Boundary

- Host profile: 4-core, 4GB RAM.
- Stack: Docker Compose services `nginx`, `api`, and `postgres`.
- Goal: confirm the first-release stack can start, pass health checks, and leave enough CPU, memory, and disk headroom for normal operation.

## Commands

Run from the repository root unless noted.

Container status:

```powershell
docker compose -f .\infra\docker-compose.yml ps
```

Container CPU and memory:

```powershell
docker stats --no-stream
```

Docker disk usage:

```powershell
docker system df
```

Host disk usage on Linux:

```bash
df -h
```

Host memory on Linux:

```bash
free -h
```

Host CPU and process view on Linux:

```bash
top
```

Recent logs for health and startup context:

```powershell
docker compose -f .\infra\docker-compose.yml logs --tail 200
```

Logs must not include passwords, tokens, original book content, chapter content, raw lookup text, raw paragraph text, or translated paragraph text.

## Recording Table

| Measurement | Command | Result | Status |
| --- | --- | --- | --- |
| Compose config renders | `docker compose -f .\infra\docker-compose.yml config` | Pending | Pending |
| Container status | `docker compose -f .\infra\docker-compose.yml ps` | Pending | Pending |
| API health | Compose healthcheck / API smoke check | Pending | Pending |
| Nginx health | `Invoke-WebRequest http://localhost:8080/health` | Pending | Pending |
| PostgreSQL health | Compose `pg_isready` healthcheck | Pending | Pending |
| CPU snapshot | `docker stats --no-stream` | Not run | Not run |
| Memory snapshot | `docker stats --no-stream` | Not run | Not run |
| Docker disk usage | `docker system df` | Not run | Not run |
| Host disk usage | `df -h` | Not run | Not run |
| Host memory usage | `free -h` | Not run | Not run |

## 4-core 4GB Notes

Record observations after startup and after basic API/web smoke checks:

```text
Date/time UTC: Pending
Commit: Pending
Host CPU cores: Pending
Host memory: Pending
API memory: Pending
PostgreSQL memory: Pending
Nginx memory: Pending
Disk free before startup: Pending
Disk free after startup: Pending
Health status: Pending
Operator notes: Pending
```

If memory pressure, failed health checks, or privacy/compliance failures appear, stop validation and file a blocker report instead of tuning beyond this task boundary.

## Blocker Format

```text
Blocker:
Category: missing tools | Docker unavailable | incomplete apps | failed health checks | privacy/compliance failures | resource pressure | other
Command:
Observed result:
Expected result:
Next owner:
```
