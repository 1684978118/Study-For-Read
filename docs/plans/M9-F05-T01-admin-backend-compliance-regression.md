# M9-F05-T01 Admin Backend Compliance Regression

## Task ID

`M9-F05-T01`

## Title

Add admin backend compliance regression tests.

## Goal

Protect the admin backend boundary so admin APIs never expose original books, chapter text, raw translation paragraphs, secrets, or full private sentence context.

## Scope

This task only does:

- Add regression tests across admin auth, users, stats, audit logs, and lexeme endpoints.
- Fix only compliance leaks found by those tests.

This task does not:

- Add new admin endpoints.
- Add web admin UI.
- Add role management.
- Add support access to user content.

## Allowed Files

- `server/src/test/java/com/studyforread/server/admin/AdminBackendComplianceRegressionTest.java`
- If and only if tests expose a compliance failure, these files may be modified:
  - `server/src/main/java/com/studyforread/server/admin/AdminAuthController.java`
  - `server/src/main/java/com/studyforread/server/admin/AdminManagementController.java`
  - `server/src/main/java/com/studyforread/server/admin/AdminManagementService.java`
  - `server/src/main/java/com/studyforread/server/admin/AdminLexemeController.java`
  - `server/src/main/java/com/studyforread/server/admin/AdminLexemeService.java`
  - `server/src/main/java/com/studyforread/server/admin/dto/**`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/user/**`
- `server/src/main/java/com/studyforread/server/reading/**`
- `server/src/main/java/com/studyforread/server/study/**`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCard.java`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/PRD-v2.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/DATA_MODEL.md`
- `docs/specs/WEB_ADMIN.md`
- All M9 backend admin task cards.

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/admin/AdminBackendComplianceRegressionTest.java`

Test behavior:

- User access token cannot call any `/api/v1/admin/**` endpoint.
- Admin user list response contains no book content, chapter content, private sentence context, password hashes, or token hashes.
- Admin stats response is aggregate only.
- Admin audit log response redacts forbidden details.
- Admin lexeme list and form responses contain only public lexeme fields.
- Admin lexeme example cannot be created from a flagged user-private source field.
- No admin response JSON contains forbidden field names from `WEB_ADMIN.md`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AdminBackendComplianceRegressionTest test
```

Expected red or green result:

- If prior tasks already comply, test may pass after writing it.
- If it fails, failure must show an actual admin compliance leak.

## Implementation Steps

- [ ] Step 1: Write `AdminBackendComplianceRegressionTest`.
- [ ] Step 2: Run verification command.
- [ ] Step 3: If tests pass, do not change production code.
- [ ] Step 4: If tests fail due to admin compliance leaks, fix only the relevant Allowed Files.
- [ ] Step 5: Run verification command again.
- [ ] Step 6: Run all M9 backend admin tests.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AdminPersistenceTest,AdminAuthEndpointTest,AdminManagementEndpointTest,AdminLexemeEndpointTest,AdminBackendComplianceRegressionTest test
```

## Acceptance Criteria

- Admin backend compliance regression passes.
- All M9 backend admin tests pass.
- Admin APIs do not expose forbidden fields or user content.
- User tokens cannot access admin APIs.
- No web code is added.

## Stop Conditions

- Any prior M9 backend task is incomplete.
- Compliance fix requires migration changes.
- Fix requires modifying files outside Allowed Files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

