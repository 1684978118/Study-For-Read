# M10 Deployment Operations Plan

> For AI workers: read `AGENTS.md`, `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`, `docs/specs/DEPLOYMENT.md`, and the task card before doing any coding. Execute one task card at a time.

## Goal

Create the first single-server Docker Compose deployment for the API, PostgreSQL, Nginx-served Web Reader and Web Admin, plus backups, logs, HTTPS guidance, and 4-core 4GB validation.

## Scope

This milestone does:

- Define deployment environment variables and secret boundaries.
- Add backend container build.
- Add static web build output handling for Web Reader and Web Admin.
- Add Docker Compose orchestration.
- Add Nginx routing and HTTPS configuration.
- Add PostgreSQL backup and restore scripts.
- Add health checks and logging configuration.
- Add deployment runbook and single-server validation checklist.
- Add deployment compliance regression tests.

This milestone does not:

- Add Kubernetes.
- Add object storage for user books.
- Add full observability stack.
- Add automatic backup retention deletion.
- Add mobile app binary build.
- Add full-book translation workers.

## Required Prior Milestones

M1 through M5 should be complete for backend deployment validation.

M8 and M9 should be complete for Web Reader and Web Admin static build validation.

If an app is not implemented yet, its deployment task must use placeholders only when the task card explicitly allows that and must mark live validation as blocked.

## Task Order

1. `M10-F01-T01-deployment-env-contract.md`
2. `M10-F02-T01-server-container-build.md`
3. `M10-F02-T02-web-static-container-builds.md`
4. `M10-F03-T01-docker-compose-core-stack.md`
5. `M10-F04-T01-nginx-routing-https.md`
6. `M10-F05-T01-postgres-backup-restore.md`
7. `M10-F06-T01-health-logs-operations.md`
8. `M10-F07-T01-single-server-validation-runbook.md`
9. `M10-F08-T01-deployment-compliance-regression.md`

## Milestone Acceptance

Milestone 10 is complete when:

- `.env.example` documents all required variables with placeholders only.
- Backend image builds and starts in Docker Compose.
- Web Reader and Web Admin static assets are served through Nginx.
- Nginx routes `/api/`, `/admin/`, and `/` correctly.
- PostgreSQL is not publicly exposed.
- Backup and restore procedures are documented and verified.
- Health checks exist for Nginx, API, and PostgreSQL.
- Logs do not include request bodies or forbidden content fields.
- 4-core 4GB validation results are documented.
- No deployment artifact introduces user book upload storage, object storage, or raw translation corpus storage.

