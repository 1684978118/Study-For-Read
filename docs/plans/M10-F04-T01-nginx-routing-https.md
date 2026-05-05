# M10-F04-T01 Nginx Routing HTTPS

## Task ID

`M10-F04-T01`

## Title

Add Nginx routing and HTTPS configuration.

## Goal

Configure Nginx to serve Web Reader, Web Admin, and reverse proxy API routes with HTTPS-ready settings.

## Scope

This task only does:

- Add Nginx config templates.
- Add static route mapping.
- Add API reverse proxy mapping.
- Add HTTPS certificate mount documentation.
- Add config validation command.

This task does not:

- Automate certificate issuance.
- Add Docker Compose service changes except Nginx config mount if necessary.
- Add application code.
- Expose database or Redis.

## Allowed Files

- `infra/nginx/nginx.conf`
- `infra/nginx/conf.d/study-for-read.conf`
- `infra/nginx/html/health.html`
- `infra/nginx/README.md`
- `infra/docker-compose.yml`
- `docs/plans/M10-F04-T01-nginx-routing-https.md`

## Forbidden Files

- `.env`
- `server/**`
- `apps/**`
- `infra/scripts/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DEPLOYMENT.md`
- `infra/docker-compose.yml`

## Tests First

Before implementation, run:

```powershell
cd "D:\Codex\Study For Read Phone"
Test-Path "infra\docker-compose.yml"
```

Expected result:

- Compose file exists.

If Compose file is missing, stop and report that M10-F03-T01 is incomplete.

## Implementation Steps

- [ ] Step 1: Create base `nginx.conf` without request body logging.
- [ ] Step 2: Create site config routing `/api/` to API upstream.
- [ ] Step 3: Route `/admin/` to Web Admin static assets.
- [ ] Step 4: Route `/` to Web Reader static assets.
- [ ] Step 5: Add static `/health` response.
- [ ] Step 6: Add HTTPS certificate paths as documented placeholders.
- [ ] Step 7: Update Compose Nginx mounts if needed.
- [ ] Step 8: Create `infra/nginx/README.md` with certificate setup notes.
- [ ] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone"
docker compose -f .\infra\docker-compose.yml config
```

## Acceptance Criteria

- Nginx routes `/api/`, `/admin/`, and `/`.
- Nginx does not log request bodies.
- PostgreSQL and internal services are not publicly exposed.
- HTTPS certificate paths are documented with placeholders only.
- No certificate private keys are committed.

## Stop Conditions

- Docker Compose task is incomplete.
- Real certificate files or private keys are provided.
- Any file outside Allowed Files must be modified.
- Any implementation exposes PostgreSQL publicly.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

