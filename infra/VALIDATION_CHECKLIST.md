# Single Server Validation Checklist

Use this checklist for the first 4-core 4GB deployment validation. Do not fabricate results. If a check has not been executed, leave the status as `Pending` or `Not run`.

## Deployment Metadata

| Field | Value |
| --- | --- |
| Commit | Pending |
| Host | Pending |
| Operator | Pending |
| Date/time UTC | Pending |
| Environment file prepared locally | Pending |
| Real secrets committed | No |

## Checklist

| Check | Command or evidence | Status | Notes |
| --- | --- | --- | --- |
| Container startup | `docker compose -f .\infra\docker-compose.yml up -d` then `docker compose -f .\infra\docker-compose.yml ps` | Pending | Expected `postgres` and `api` healthy, `nginx` running. |
| API health | Compose API healthcheck and `/api/` smoke route through Nginx | Pending | Do not record tokens or response bodies with private content. |
| Web Reader loads | Browser or HTTP check for `/` | Pending | Verify static assets load. |
| Web Admin loads | Browser or HTTP check for `/admin/` | Pending | Verify static assets load. |
| PostgreSQL migrations | API startup logs or DB metadata check | Pending | Logs must not expose passwords or tokens. |
| Login API responds | `/api/v1/...` login smoke check with test credentials | Pending | Do not record real credentials. |
| Reading sync rejects original content fields | Send a test payload containing forbidden original content fields and confirm rejection | Pending | Do not use real user book content. |
| Translation endpoint does not persist raw paragraphs | Exercise with synthetic text and inspect expected behavior | Pending | Do not use raw private paragraphs. |
| Admin endpoint rejects user tokens | Use a normal user token against `/api/v1/admin/...` and confirm admin-required rejection | Pending | Do not paste token values into notes. |
| Backup workflow | `.\infra\scripts\backup-postgres.ps1` against the running stack | Pending | Confirm UTC timestamped dump file. |
| Restore workflow | Restore script against non-production target with required guard flags | Pending | Do not overwrite live data. |
| Logs forbidden content check | Review `docker compose logs --tail 200` for forbidden content | Pending | Must not include passwords, tokens, original book content, chapter content, raw lookup text, raw paragraph text, or translated paragraph text. |
| Resource usage recording | Fill `infra/operations/RESOURCE_VALIDATION.md` with measured CPU, memory, disk, and container status | Pending | Mark Not run when measurements were not taken. |

## Forbidden Content

Validation notes, logs, screenshots, and tickets must not include:

- passwords
- tokens
- original book content
- chapter content
- raw lookup text
- raw paragraph text
- translated paragraph text
- private sentence context
- full book or full chapter content

## Blocker Reporting

```text
Blocker:
Category: missing tools | Docker unavailable | incomplete apps | failed health checks | privacy/compliance failures | other
Affected checklist item:
Command:
Observed result:
Expected result:
Evidence location:
Next owner:
```
