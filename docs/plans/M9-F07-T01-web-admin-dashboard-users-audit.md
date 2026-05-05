# M9-F07-T01 Web Admin Dashboard Users Audit

## Task ID

`M9-F07-T01`

## Title

Implement web admin dashboard, users, stats, and audit log pages.

## Goal

Show admin dashboard summaries, users, platform stats, and redacted audit logs from admin APIs.

## Scope

This task only does:

- Add admin management API client.
- Add dashboard page.
- Add users page.
- Add stats page.
- Add audit logs page.
- Add table and filter components.
- Add tests with fake HTTP.

This task does not:

- Add lexeme management UI.
- Add user mutation actions.
- Add role management.
- Add raw content views.

## Allowed Files

- `apps/web-admin/services/adminManagementApiClient.ts`
- `apps/web-admin/stores/adminDashboard.ts`
- `apps/web-admin/stores/adminUsers.ts`
- `apps/web-admin/stores/adminAuditLogs.ts`
- `apps/web-admin/pages/admin/index.vue`
- `apps/web-admin/pages/admin/users.vue`
- `apps/web-admin/pages/admin/stats.vue`
- `apps/web-admin/pages/admin/audit-logs.vue`
- `apps/web-admin/components/admin/AdminMetricGrid.vue`
- `apps/web-admin/components/admin/AdminUsersTable.vue`
- `apps/web-admin/components/admin/AdminAuditLogTable.vue`
- `apps/web-admin/components/admin/AdminTableFilters.vue`
- `apps/web-admin/types/adminManagement.ts`
- `apps/web-admin/tests/admin/dashboard-page.test.ts`
- `apps/web-admin/tests/admin/users-page.test.ts`
- `apps/web-admin/tests/admin/audit-logs-page.test.ts`

## Forbidden Files

- `apps/web-admin/pages/admin/lexemes/**`
- `apps/web-admin/services/adminLexemeApiClient.ts`
- `apps/web-admin/components/lexemes/**`
- `apps/web-admin/package.json`
- `apps/mobile/**`
- `apps/web-reader/**`
- `server/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/WEB_ADMIN.md`
- `apps/web-admin/components/layout/AdminShell.vue`
- `apps/web-admin/stores/adminAuth.ts`

## Tests First

Create:

- `apps/web-admin/tests/admin/dashboard-page.test.ts`
- `apps/web-admin/tests/admin/users-page.test.ts`
- `apps/web-admin/tests/admin/audit-logs-page.test.ts`

Test behavior:

- Dashboard calls `/api/v1/admin/stats/summary` and shows aggregate counters.
- Users page calls `/api/v1/admin/users` with pagination and filters.
- Users table shows email, display name, language pair, status, created time, and updated time.
- Users table never renders password hashes, tokens, book content, chapter content, or private sentence context.
- Audit logs page calls `/api/v1/admin/audit-logs` with pagination and filters.
- Audit log table renders redacted details only.
- Admin API errors show inline error states without exposing raw response secrets.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-admin"
npm run test -- tests/admin/dashboard-page.test.ts tests/admin/users-page.test.ts tests/admin/audit-logs-page.test.ts
```

Expected red result:

- Tests fail because dashboard, users, or audit pages do not exist.

## Implementation Steps

- [ ] Step 1: Write dashboard, users, and audit page tests.
- [ ] Step 2: Run red tests and confirm missing page behavior.
- [ ] Step 3: Create admin management API client.
- [ ] Step 4: Create dashboard, users, and audit stores.
- [ ] Step 5: Create metric grid, table, and filter components.
- [ ] Step 6: Implement dashboard page.
- [ ] Step 7: Implement users page with pagination and filters.
- [ ] Step 8: Implement stats page using dashboard summary counters.
- [ ] Step 9: Implement audit logs page with redacted details.
- [ ] Step 10: Ensure forbidden fields are not displayed.
- [ ] Step 11: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-admin"
npm run test -- tests/admin/dashboard-page.test.ts tests/admin/users-page.test.ts tests/admin/audit-logs-page.test.ts
npm run typecheck
```

## Acceptance Criteria

- Dashboard, users, and audit tests pass.
- Admin pages use fake HTTP in tests.
- Tables render operational metadata only.
- No lexeme management UI is added.
- No raw content or secret field is displayed.

## Stop Conditions

- Admin auth shell is incomplete.
- API contract lacks fields needed by UI.
- Tests require live backend.
- Any file outside Allowed Files must be modified.
- Any implementation displays forbidden fields.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

