# M9-F03-T01 Admin Users Stats Audit Endpoints

## Task ID

`M9-F03-T01`

## Title

Implement admin users, stats, and audit log endpoints.

## Goal

Allow admins to list users, view aggregate platform stats, and inspect redacted audit logs without exposing user content.

## Scope

This task only does:

- Add `GET /api/v1/admin/users`.
- Add `GET /api/v1/admin/stats/summary`.
- Add `GET /api/v1/admin/audit-logs`.
- Add tests for pagination, filtering, admin auth, and forbidden fields.

This task does not:

- Add lexeme management endpoints.
- Add admin web UI.
- Add user status mutation.
- Expose user book content.

## Allowed Files

- `server/src/main/java/com/studyforread/server/admin/AdminManagementController.java`
- `server/src/main/java/com/studyforread/server/admin/AdminManagementService.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminUserListResponse.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminUserSummaryResponse.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminPlatformStatsResponse.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminAuditLogListResponse.java`
- `server/src/main/java/com/studyforread/server/admin/dto/AdminAuditLogResponse.java`
- `server/src/main/java/com/studyforread/server/user/UserAccountRepository.java`
- `server/src/main/java/com/studyforread/server/reading/UserBookRepository.java`
- `server/src/main/java/com/studyforread/server/stats/StudyDailyStatRepository.java`
- `server/src/main/java/com/studyforread/server/vocabulary/LexemeRepository.java`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCardRepository.java`
- `server/src/test/java/com/studyforread/server/admin/AdminManagementEndpointTest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/admin/AdminAuthController.java`
- `server/src/main/java/com/studyforread/server/admin/AdminAuthService.java`
- `server/src/main/java/com/studyforread/server/vocabulary/*Controller.java`
- `server/src/main/java/com/studyforread/server/vocabulary/*Service.java`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/WEB_ADMIN.md`
- `server/src/main/java/com/studyforread/server/admin/AdminAuditLogRepository.java`
- `server/src/main/java/com/studyforread/server/admin/AdminPrincipal.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/admin/AdminManagementEndpointTest.java`

Test behavior:

- Admin can list users with pagination.
- User list supports status filter and query search.
- User list response excludes password hashes, tokens, book content, chapter content, private sentence context, raw lookup text, and translated text.
- User token cannot list admin users and returns `ADMIN_REQUIRED`.
- Platform stats summary returns aggregate counts only.
- Audit log list returns redacted details and pagination metadata.
- Audit log response excludes passwords, tokens, raw book content, raw paragraph text, translated paragraph text, and full private sentence context.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AdminManagementEndpointTest test
```

Expected red result:

- Test fails because admin management endpoints do not exist.

## Implementation Steps

- [ ] Step 1: Write `AdminManagementEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoints missing.
- [ ] Step 3: Create response DTOs for user list, platform stats, and audit logs.
- [ ] Step 4: Add repository aggregate methods if missing.
- [ ] Step 5: Implement `AdminManagementService.listUsers`.
- [ ] Step 6: Implement `AdminManagementService.getPlatformStats`.
- [ ] Step 7: Implement `AdminManagementService.listAuditLogs`.
- [ ] Step 8: Implement controller routes from `API_CONTRACT.md`.
- [ ] Step 9: Redact audit details before returning.
- [ ] Step 10: Ensure responses do not include forbidden fields.
- [ ] Step 11: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AdminManagementEndpointTest test
```

## Acceptance Criteria

- Admin management endpoint tests pass.
- Admin auth is required for all routes.
- User list and stats are metadata only.
- Audit logs are redacted.
- No lexeme mutation endpoint is added in this task.

## Stop Conditions

- Admin auth endpoints are incomplete.
- Required repositories do not exist from prior milestones.
- Adding aggregate methods requires modifying files outside Allowed Files.
- Any implementation exposes raw user content or secrets.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

