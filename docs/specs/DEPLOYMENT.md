# Deployment And Operations

This document defines the first single-server deployment and operations boundary.

## 1. Target Environment

First production-style deployment target:

- One Linux server.
- 4 CPU cores.
- 4 GB RAM.
- Docker Compose.
- Nginx reverse proxy.
- Spring Boot API.
- PostgreSQL.
- Redis only when a later task explicitly enables cache or rate limiting.
- Static web assets for Web Reader and Web Admin served by Nginx.

The first deployment must fit inside 4 GB RAM. Do not add Kubernetes, managed object storage, message queues, or multi-node infrastructure in first release.

## 2. Container Roles

Required services:

- `nginx`: public HTTP/HTTPS entrypoint, static web assets, reverse proxy.
- `api`: Spring Boot backend.
- `postgres`: PostgreSQL database.

Optional later service:

- `redis`: rate limiting or cache only when a later task card enables it.

Forbidden services in first release:

- Object storage for user books.
- Book upload worker.
- Search engine indexing full user books.
- Queue consumer for full-book translation.

## 3. Routing

Nginx routes:

- `/api/` -> Spring Boot API container.
- `/admin/` -> Web Admin static app.
- `/` -> Web Reader static app.

Rules:

- API remains under `/api/v1`.
- Admin UI must not be served from the same route as user reader pages.
- Nginx must not expose PostgreSQL or Redis publicly.
- Nginx logs must not include request bodies.

## 4. Environment Variables

Use `.env.example` for non-secret names and expected formats. Do not commit real `.env`.

Required variables:

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`
- `JWT_SECRET`
- `ADMIN_JWT_SECRET`
- `API_BASE_URL`
- `WEB_READER_PUBLIC_API_BASE`
- `WEB_ADMIN_PUBLIC_API_BASE`
- `TRANSLATION_PROVIDER`
- `TRANSLATION_PROVIDER_API_KEY`
- `TRANSLATION_TEXT_MAX_LENGTH`
- `CORS_ALLOWED_ORIGINS`

Rules:

- Secrets must be provided through runtime environment files or host secret management, not committed.
- `.env.example` must contain placeholders only.
- Translation provider keys stay on the server and must not be exposed to mobile or web clients.

## 5. Volumes

Required volumes:

- PostgreSQL data volume.
- PostgreSQL backup output directory.
- Nginx certificate directory when HTTPS is enabled.

Forbidden volumes:

- User original book storage.
- Uploaded chapter content storage.
- Translation corpus storage.
- Full-book translation output storage.

## 6. Build Strategy

Backend:

- Build Spring Boot artifact inside a multi-stage Dockerfile or from CI-produced artifact.
- Runtime image should run as a non-root user when feasible.

Web Reader and Web Admin:

- Build Nuxt apps as static assets for first release.
- Serve static assets through Nginx.
- Runtime API base URL must be configurable.

Mobile:

- Mobile binaries are not built by the server deployment stack.

## 7. Backups And Restore

Backups:

- PostgreSQL logical backups with `pg_dump`.
- Backups written to a host-mounted backup directory.
- Backup filenames include UTC timestamp.
- Backup script must not include raw passwords in command output.

Restore:

- Restore procedure must be documented and tested against a fresh PostgreSQL container.
- Restore must not require deleting live data in bulk during the test task.

Retention:

- First release documents manual retention.
- Automated deletion of old backups is not implemented unless a later task explicitly designs safe retention.

## 8. Logs And Health

Logs:

- Container logs are collected through Docker logging.
- Application logs must not include passwords, tokens, original book content, chapter content, raw lookup text, raw paragraph text, or translated paragraph text.

Health endpoints:

- API health endpoint should be reachable by Docker Compose healthcheck.
- PostgreSQL health uses `pg_isready`.
- Nginx health uses a static `/health` response.

## 9. HTTPS

First release supports HTTPS through Nginx.

Allowed:

- Certificate files mounted from host.
- A documented Certbot/manual certificate workflow.

Not in first release:

- Automatic DNS provider integration.
- Multi-domain certificate automation.

## 10. Single-Server Validation

Validation must cover:

- Containers start successfully.
- API health works through Nginx.
- Web Reader static app loads.
- Web Admin static app loads.
- PostgreSQL migrations run.
- Login API responds.
- Reading sync endpoint rejects original content fields.
- Translation endpoint does not persist raw paragraphs.
- Admin endpoint rejects user tokens.
- Backup and restore commands are executable.
- Memory usage is documented after startup and basic API calls.

## 11. Deployment Non-Goals

Do not implement in first release:

- Kubernetes.
- Cloud object storage for user books.
- CDN-specific deployment.
- Auto-scaling.
- Blue-green deployment.
- Full observability stack.
- Payment infrastructure.
- Full-text search over user books.

