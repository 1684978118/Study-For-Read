# Troubleshooting

Use this runbook for first-release single-server operations. It assumes the core services are `nginx`, `api`, and `postgres`.

## Validate Compose Configuration

Run:

```powershell
docker compose -f .\infra\docker-compose.yml config
docker compose -f .\infra\docker-compose.yml ps
```

`config` should render without errors. `ps` should show PostgreSQL and API as healthy after startup, and Nginx as running.

## API Failed

Check service status and recent logs:

```powershell
docker compose -f .\infra\docker-compose.yml ps api
docker compose -f .\infra\docker-compose.yml logs --tail 200 api
```

Common checks:

- Confirm `postgres` is healthy.
- Confirm datasource variables point to `postgres:5432` inside the Compose network.
- Confirm `JWT_SECRET` and `ADMIN_JWT_SECRET` are configured with non-placeholder runtime values outside source control.
- Confirm no passwords, tokens, chapter content, raw lookup text, raw paragraph text, or translated paragraph text are copied out of logs.

## Database Failed

Check PostgreSQL health and logs:

```powershell
docker compose -f .\infra\docker-compose.yml ps postgres
docker compose -f .\infra\docker-compose.yml logs --tail 200 postgres
```

Common checks:

- Confirm the named `postgres_data` volume is available.
- Confirm the backup host mount exists and is writable by the container where required.
- Confirm PostgreSQL is not published to the public host interface.
- Do not delete or overwrite live data while troubleshooting.

## Nginx Failed

Validate Nginx config and inspect logs:

```powershell
docker compose -f .\infra\docker-compose.yml logs --tail 200 nginx
docker run --rm -v "${PWD}\infra\nginx\nginx.conf:/etc/nginx/nginx.conf:ro" -v "${PWD}\infra\nginx\conf.d:/etc/nginx/conf.d:ro" -v "${PWD}\infra\nginx\html:/usr/share/nginx/health:ro" nginx:1.27-alpine nginx -t
```

Common checks:

- `/health` should serve the static health file.
- `/api/` should proxy to `api:8080`.
- `/admin/` should serve Web Admin static assets.
- `/` should serve Web Reader static assets.
- Nginx access logs must not include request bodies.

## Web Reader Or Web Admin Static Assets Missing

Check the static build output mounts:

```powershell
Test-Path "apps\web-reader\.output\public"
Test-Path "apps\web-admin\.output\public"
docker compose -f .\infra\docker-compose.yml ps nginx
```

If a static output path is missing, rebuild the relevant web app using its deployment README. Do not change API, database, or Nginx routing while diagnosing missing generated assets unless a later task card allows it.

## Privacy Reminder

Troubleshooting notes and copied logs must not include passwords, tokens, original book content, chapter content, raw lookup text, raw paragraph text, translated paragraph text, private sentence context, or full user content.
