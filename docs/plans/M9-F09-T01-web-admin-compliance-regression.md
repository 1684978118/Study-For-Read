# M9-F09-T01 Web Admin Compliance Regression

## Task ID

`M9-F09-T01`

## Title

Add web admin compliance regression tests.

## Goal

Protect the web admin UI so it never displays forbidden user content or secret fields.

## Scope

This task only does:

- Add regression tests across web admin auth, dashboard, users, audit logs, and lexeme pages.
- Fix only web admin compliance leaks found by those tests.

This task does not:

- Add new admin features.
- Add backend code.
- Add mobile or web reader code.
- Add live backend integration.

## Allowed Files

- `apps/web-admin/tests/regression/web-admin-compliance-regression.test.ts`
- If and only if tests expose a compliance failure, these files may be modified:
  - `apps/web-admin/services/adminManagementApiClient.ts`
  - `apps/web-admin/services/adminLexemeApiClient.ts`
  - `apps/web-admin/stores/adminDashboard.ts`
  - `apps/web-admin/stores/adminUsers.ts`
  - `apps/web-admin/stores/adminAuditLogs.ts`
  - `apps/web-admin/stores/adminLexemes.ts`
  - `apps/web-admin/components/admin/**`
  - `apps/web-admin/components/lexemes/**`
  - `apps/web-admin/pages/admin/**`

## Forbidden Files

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
- All M9 web admin task cards.

## Tests First

Create:

- `apps/web-admin/tests/regression/web-admin-compliance-regression.test.ts`

Test behavior:

- Signed-out admin cannot access protected admin pages.
- Fake API payloads containing forbidden fields are not rendered on dashboard, users, audit logs, or lexeme pages.
- User table does not render password hashes, token hashes, book content, chapter content, or private sentence context.
- Audit logs table redacts forbidden details even if fake API sends them.
- Lexeme form does not expose private sentence source fields.
- No web admin test requires live backend.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-admin"
npm run test -- tests/regression/web-admin-compliance-regression.test.ts
```

Expected red or green result:

- If prior tasks already comply, test may pass after writing it.
- If it fails, failure must show an actual web admin compliance leak.

## Implementation Steps

- [ ] Step 1: Write web admin compliance regression test.
- [ ] Step 2: Run verification command.
- [ ] Step 3: If tests pass, do not change production code.
- [ ] Step 4: If tests fail due to web admin compliance leaks, fix only the relevant Allowed Files.
- [ ] Step 5: Run verification command again.
- [ ] Step 6: Run all M9 web admin tests.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-admin"
npm run test -- tests/regression/web-admin-compliance-regression.test.ts
npm run test
npm run typecheck
```

## Acceptance Criteria

- Web admin compliance regression passes.
- All web admin tests pass.
- Forbidden content and secret fields are not rendered.
- No backend, mobile, web reader, infra, or old project files are modified.

## Stop Conditions

- Any prior M9 web admin task is incomplete.
- Compliance fix requires backend API changes.
- Fix requires modifying files outside Allowed Files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

