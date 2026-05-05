# M10-F06-T01 Health Logs Operations

## Task ID

`M10-F06-T01`

## Title

Add health checks and logging operations guidance.

## Goal

Define health checks, operational log boundaries, and basic troubleshooting commands for the single-server deployment.

## Scope

This task only does:

- Add health check documentation.
- Add logging rules and forbidden content checks.
- Add troubleshooting runbook.
- Add Compose health check updates if needed.

This task does not:

- Add full observability stack.
- Add Prometheus, Grafana, Loki, or ELK.
- Add application source logging changes unless a task card later allows it.

## Allowed Files

- `infra/operations/HEALTH_CHECKS.md`
- `infra/operations/LOGGING.md`
- `infra/operations/TROUBLESHOOTING.md`
- `infra/docker-compose.yml`
- `infra/nginx/conf.d/study-for-read.conf`
- `docs/plans/M10-F06-T01-health-logs-operations.md`

## Forbidden Files

- `.env`
- `server/src/**`
- `apps/**`
- `infra/scripts/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DEPLOYMENT.md`
- `infra/docker-compose.yml`
- `infra/nginx/conf.d/study-for-read.conf`

## Tests First

Before implementation, run:

```powershell
cd "D:\Codex\Study For Read Phone"
Test-Path "infra\docker-compose.yml"
Test-Path "infra\nginx\conf.d\study-for-read.conf"
```

Expected result:

- Compose and Nginx config exist.

If either is missing, stop and report the prior task blocker.

## Implementation Steps

- [ ] Step 1: Document API, Nginx, and PostgreSQL health checks.
- [ ] Step 2: Document Docker Compose health check behavior and expected statuses.
- [ ] Step 3: Document log commands using `docker compose logs`.
- [ ] Step 4: Document forbidden log content: passwords, tokens, original book content, chapter content, raw lookup text, raw paragraph text, and translated paragraph text.
- [ ] Step 5: Add troubleshooting commands for failed API, database, Nginx, and web static assets.
- [ ] Step 6: Update Compose health checks if missing.
- [ ] Step 7: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone"
Select-String -Path "infra\operations\*.md","infra\docker-compose.yml" -Pattern "health|logs|passwords|tokens|chapter content|translated paragraph"
docker compose -f .\infra\docker-compose.yml config
```

## Acceptance Criteria

- Health and logging docs exist.
- Compose config validates.
- Operational docs include forbidden log content.
- No new observability service is added.
- No application source files are modified.

## Stop Conditions

- Compose or Nginx tasks are incomplete.
- Health check requires changing application source outside Allowed Files.
- Any file outside Allowed Files must be modified.
- Any implementation logs request bodies.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

