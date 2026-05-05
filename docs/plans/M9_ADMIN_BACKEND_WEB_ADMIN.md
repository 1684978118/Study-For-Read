# M9 Admin Backend And Web Admin Plan

> For AI workers: read `AGENTS.md`, `docs/ai-process/AI_DEVELOPMENT_PROCESS.md`, the admin specs, and the task card before doing any coding. Execute one task card at a time.

## Goal

Build the first admin system: Spring Boot admin APIs plus a Nuxt web admin app for operational users, platform statistics, audit logs, and public lexeme management.

## Scope

This milestone does:

- Add admin user and audit log persistence.
- Add admin login and current-admin APIs.
- Add admin user list, platform stats, and audit log APIs.
- Add admin public lexeme list, create, edit, and reject APIs.
- Add backend compliance regression tests proving admin APIs do not expose user book content or raw translation text.
- Create `apps/web-admin` Nuxt app.
- Add web admin auth gate and shell.
- Add dashboard, users, stats, audit logs, and lexeme management pages.
- Add web admin compliance regression tests.

This milestone does not:

- Add role management UI.
- Add user content support tools.
- Add payment, subscription, or quota management.
- Add cloud bookshelf or book download features.
- Expose original book files, chapter content, raw lookup text, raw paragraph text, or translated paragraph text.

## Required Prior Milestones

M1 must be complete:

- Backend project, API envelope, JWT foundation, and user auth patterns exist.

M3 should be complete:

- Public lexeme persistence exists.

M5 should be complete:

- Study stats persistence exists for platform summary.

## Task Order

1. `M9-F01-T01-admin-persistence.md`
2. `M9-F02-T01-admin-auth-endpoints.md`
3. `M9-F03-T01-admin-users-stats-audit-endpoints.md`
4. `M9-F04-T01-admin-lexeme-management-endpoints.md`
5. `M9-F05-T01-admin-backend-compliance-regression.md`
6. `M9-F06-T01-web-admin-nuxt-skeleton.md`
7. `M9-F06-T02-web-admin-auth-shell.md`
8. `M9-F07-T01-web-admin-dashboard-users-audit.md`
9. `M9-F08-T01-web-admin-lexeme-management.md`
10. `M9-F09-T01-web-admin-compliance-regression.md`

## Milestone Acceptance

Milestone 9 is complete when:

- Admin users and audit logs are persisted.
- Admin access tokens are separate from user tokens.
- User tokens cannot access admin endpoints.
- Admin can list users without book content or secrets.
- Admin can view aggregate platform stats without raw content.
- Admin can view redacted audit logs.
- Admin can list, create, update, and reject public lexemes.
- Lexeme changes write audit logs.
- Web admin pages work against fake API clients in tests.
- Backend and web admin compliance regression tests pass.

