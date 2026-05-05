# M9-F08-T01 Web Admin Lexeme Management

## Task ID

`M9-F08-T01`

## Title

Implement web admin lexeme management.

## Goal

Allow admins to list, create, edit, and reject public lexemes through the Nuxt admin UI.

## Scope

This task only does:

- Add admin lexeme API client.
- Add lexeme list page.
- Add lexeme create page.
- Add lexeme edit page.
- Add reject action.
- Add form validation and tests with fake HTTP.

This task does not:

- Add bulk import.
- Add dictionary provider management.
- Add user private sentence moderation.
- Add raw book content views.

## Allowed Files

- `apps/web-admin/services/adminLexemeApiClient.ts`
- `apps/web-admin/stores/adminLexemes.ts`
- `apps/web-admin/pages/admin/lexemes/index.vue`
- `apps/web-admin/pages/admin/lexemes/new.vue`
- `apps/web-admin/pages/admin/lexemes/[id].vue`
- `apps/web-admin/components/lexemes/LexemeFilters.vue`
- `apps/web-admin/components/lexemes/LexemeTable.vue`
- `apps/web-admin/components/lexemes/LexemeForm.vue`
- `apps/web-admin/components/lexemes/LexemeRejectDialog.vue`
- `apps/web-admin/types/adminLexeme.ts`
- `apps/web-admin/tests/lexemes/lexeme-list-page.test.ts`
- `apps/web-admin/tests/lexemes/lexeme-form-page.test.ts`
- `apps/web-admin/tests/lexemes/lexeme-reject-action.test.ts`

## Forbidden Files

- `apps/web-admin/pages/admin/users.vue`
- `apps/web-admin/pages/admin/audit-logs.vue`
- `apps/web-admin/services/adminManagementApiClient.ts`
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
- `apps/web-admin/stores/adminAuth.ts`
- `apps/web-admin/components/layout/AdminShell.vue`

## Tests First

Create:

- `apps/web-admin/tests/lexemes/lexeme-list-page.test.ts`
- `apps/web-admin/tests/lexemes/lexeme-form-page.test.ts`
- `apps/web-admin/tests/lexemes/lexeme-reject-action.test.ts`

Test behavior:

- Lexeme list calls `/api/v1/admin/lexemes` with pagination and filters.
- Lexeme table shows surface, reading, language pair, entry type, status, and update time.
- Create form sends required fields to `POST /api/v1/admin/lexemes`.
- Edit form sends allowed fields to `PATCH /api/v1/admin/lexemes/{lexemeId}`.
- Reject action sends `POST /api/v1/admin/lexemes/{lexemeId}/reject`.
- Duplicate error `ADMIN_LEXEME_DUPLICATE` shows inline form error.
- Invalid error `ADMIN_LEXEME_INVALID` shows inline form error.
- Form does not include user private sentence source fields.
- UI copy indicates examples must be license-safe and admin-provided.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-admin"
npm run test -- tests/lexemes
```

Expected red result:

- Tests fail because lexeme management pages or API client do not exist.

## Implementation Steps

- [ ] Step 1: Write lexeme list, form, and reject tests.
- [ ] Step 2: Run red tests and confirm missing lexeme UI behavior.
- [ ] Step 3: Create admin lexeme types.
- [ ] Step 4: Create admin lexeme API client.
- [ ] Step 5: Create lexeme store for list, create, update, and reject.
- [ ] Step 6: Create filters, table, form, and reject dialog components.
- [ ] Step 7: Implement lexeme list page.
- [ ] Step 8: Implement new lexeme page.
- [ ] Step 9: Implement edit lexeme page.
- [ ] Step 10: Handle duplicate and invalid errors inline.
- [ ] Step 11: Ensure form does not include private sentence source fields.
- [ ] Step 12: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\web-admin"
npm run test -- tests/lexemes
npm run typecheck
```

## Acceptance Criteria

- Lexeme management tests pass.
- Admin can list, create, edit, and reject lexemes.
- Form fields match `API_CONTRACT.md`.
- No user private sentence or book content fields are present.
- No backend code is modified.

## Stop Conditions

- Dashboard admin shell is incomplete.
- Admin lexeme backend API contract changes.
- Tests require live backend.
- Any file outside Allowed Files must be modified.
- Any implementation exposes user private sentence context.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

