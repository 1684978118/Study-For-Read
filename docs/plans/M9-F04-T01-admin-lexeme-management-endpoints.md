# M9-F04-T01 Admin Lexeme Management Endpoints

## Task ID

`M9-F04-T01`

## Title

Implement admin public lexeme management endpoints.

## Goal

Allow admins to list, create, update, and reject public lexemes while writing audit logs.

## Scope

This task only does:

- Add `GET /api/v1/admin/lexemes`.
- Add `POST /api/v1/admin/lexemes`.
- Add `PATCH /api/v1/admin/lexemes/{lexemeId}`.
- Add `POST /api/v1/admin/lexemes/{lexemeId}/reject`.
- Add audit log writes for create, update, and reject.
- Add endpoint tests.

This task does not:

- Add web admin UI.
- Add bulk import.
- Add user private sentence moderation.
- Add dictionary provider integration.

## Allowed Files

- `server/src/main/java/com/studyforread/server/admin/AdminLexemeController.java`
- `server/src/main/java/com/studyforread/server/admin/AdminLexemeService.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminLexemeListResponse.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminLexemeResponse.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminLexemeUpsertRequest.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminLexemeRejectRequest.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminLexemeRejectResponse.java`
- `server/src/main/java/com/studyforread/server/admin/AdminAuditLogRepository.java`
- `server/src/main/java/com/studyforread/server/vocabulary/Lexeme.java`
- `server/src/main/java/com/studyforread/server/vocabulary/LexemeRepository.java`
- `server/src/test/java/com/studyforread/server/admin/AdminLexemeEndpointTest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/vocabulary/VocabularyController.java`
- `server/src/main/java/com/studyforread/server/vocabulary/VocabularyService.java`
- `server/src/main/java/com/studyforread/server/study/**`
- `server/src/main/java/com/studyforread/server/user/**`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/DATA_MODEL.md`
- `docs/specs/WEB_ADMIN.md`
- `server/src/main/java/com/studyforread/server/vocabulary/Lexeme.java`
- `server/src/main/java/com/studyforread/server/vocabulary/LexemeRepository.java`
- `server/src/main/java/com/studyforread/server/admin/AdminAuditLogRepository.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/admin/AdminLexemeEndpointTest.java`

Test behavior:

- Admin can list lexemes with pagination and filters.
- Creating lexeme normalizes `normalizedSurface`.
- Duplicate business key returns `ADMIN_LEXEME_DUPLICATE`.
- Blank surface or definition returns `ADMIN_LEXEME_INVALID`.
- Updating lexeme changes allowed public fields only.
- Rejecting lexeme sets status to `rejected`.
- Create, update, and reject write admin audit logs.
- User token cannot access lexeme admin endpoints.
- Admin lexeme endpoints do not read or expose user private sentence context.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AdminLexemeEndpointTest test
```

Expected red result:

- Test fails because admin lexeme endpoints do not exist.

## Implementation Steps

- [ ] Step 1: Write `AdminLexemeEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoints missing.
- [ ] Step 3: Create lexeme admin request and response DTOs.
- [ ] Step 4: Implement list with filters from `API_CONTRACT.md`.
- [ ] Step 5: Implement create with normalized surface and duplicate handling.
- [ ] Step 6: Implement update with validation.
- [ ] Step 7: Implement reject.
- [ ] Step 8: Write redacted audit log entries for create, update, and reject.
- [ ] Step 9: Ensure examples are treated as admin-provided license-safe text only.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AdminLexemeEndpointTest test
```

## Acceptance Criteria

- Admin lexeme endpoint tests pass.
- Lexeme validation and duplicate handling match `API_CONTRACT.md`.
- Lexeme mutations write audit logs.
- User private sentence context is not read or exposed.
- No web UI is added.

## Stop Conditions

- Admin auth is incomplete.
- Lexeme persistence is incomplete.
- Audit log persistence is incomplete.
- Any implementation copies user private book text into public lexeme example.
- Any file outside Allowed Files must be modified.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

