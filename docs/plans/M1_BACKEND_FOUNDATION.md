# M1 Backend Foundation Plan

> For AI workers: read `AGENTS.md`, `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`, and the task card before doing any coding. Execute one task card at a time.

## Goal

Build the smallest Spring Boot backend foundation that supports authentication, PostgreSQL migrations, unified API responses, and the first user account endpoints.

## Scope

This milestone does:

- Create the `server` Spring Boot project.
- Configure PostgreSQL profile and migration tool.
- Define a consistent API response envelope.
- Define stable error codes.
- Create user and refresh token persistence.
- Implement register, login, refresh, and current-user APIs.

This milestone does not:

- Build mobile app code.
- Build Nuxt code.
- Implement reading sync.
- Implement vocabulary.
- Implement translation.
- Implement admin APIs.
- Implement payment.

## Required Environment

- JDK 17.
- Network access for dependency download.
- PowerShell on Windows.

If JDK 17 is not available, stop and report the blocker. Do not downgrade the project to Java 8.

## Task Order

1. `M1-F01-T01-server-project-skeleton.md`
2. `M1-F01-T02-postgresql-flyway-config.md`
3. `M1-F02-T01-api-envelope-error-codes.md`
4. `M1-F03-T01-users-refresh-tokens-persistence.md`
5. `M1-F04-T01-register-endpoint.md`
6. `M1-F04-T02-login-refresh-me-endpoints.md`

## Milestone Acceptance

Milestone 1 is complete when:

- `server` exists and `.\mvnw.cmd test` runs.
- Test profile can start with PostgreSQL-compatible schema migrations.
- API response envelope is used by auth endpoints.
- Register returns a user plus access and refresh tokens.
- Login returns a user plus access and refresh tokens.
- Refresh returns new tokens.
- `/api/v1/auth/me` returns the current user.
- No endpoint stores or accepts original book text.

