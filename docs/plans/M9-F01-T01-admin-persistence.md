# M9-F01-T01 Admin Persistence

## Task ID

`M9-F01-T01`

## Title

Create admin user and audit log persistence.

## Goal

Add database persistence for administrators and admin audit logs.

## Scope

This task only does:

- Add `admin_users` and `admin_audit_logs` migration.
- Add admin entities and repositories.
- Add repository tests for constraints, redaction boundaries, and relationships.
- Add or repair `lexemes.created_by_admin_id` foreign key if needed.

This task does not:

- Add admin login endpoint.
- Add admin web UI.
- Add role management.
- Seed production admin credentials.

## Allowed Files

- `server/src/main/resources/db/migration/V7__create_admin_users_and_audit_logs.sql`
- `server/src/main/java/com/studyforread/server/admin/AdminUser.java`
- `server/src/main/java/com/studyforread/server/admin/AdminRole.java`
- `server/src/main/java/com/studyforread/server/admin/AdminStatus.java`
- `server/src/main/java/com/studyforread/server/admin/AdminAuditLog.java`
- `server/src/main/java/com/studyforread/server/admin/AdminUserRepository.java`
- `server/src/main/java/com/studyforread/server/admin/AdminAuditLogRepository.java`
- `server/src/test/java/com/studyforread/server/admin/AdminPersistenceTest.java`

## Forbidden Files

- `server/src/main/java/com/studyforread/server/admin/*Controller.java`
- `server/src/main/java/com/studyforread/server/admin/*Service.java`
- `server/src/main/java/com/studyforread/server/auth/**`
- `server/src/main/java/com/studyforread/server/user/**`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DATA_MODEL.md`
- `docs/specs/API_CONTRACT.md`
- `server/src/main/resources/db/migration/V3__create_lexemes.sql`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/admin/AdminPersistenceTest.java`

Test behavior:

- `admin_users.username` is unique.
- `admin_users.role` accepts only `admin` and `operator`.
- `admin_users.status` accepts only `active` and `disabled`.
- `admin_audit_logs.admin_user_id` references `admin_users.id` on delete restrict.
- Audit details can store redacted JSON.
- Audit table has no columns named `password`, `password_hash`, `token`, `token_hash`, `content`, `chapter_content`, `raw_text`, `translated_text`, or `paragraph_text`.
- Lexeme `created_by_admin_id` references admin users if the column exists.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AdminPersistenceTest test
```

Expected red result:

- Test fails because admin persistence does not exist.

## Implementation Steps

- [ ] Step 1: Write `AdminPersistenceTest`.
- [ ] Step 2: Run red test and confirm missing table or missing class failure.
- [ ] Step 3: Create `V7__create_admin_users_and_audit_logs.sql` following `DATA_MODEL.md`.
- [ ] Step 4: Add check constraints for admin role and status.
- [ ] Step 5: Add audit log foreign key with `on delete restrict`.
- [ ] Step 6: Add or repair `lexemes.created_by_admin_id` reference to `admin_users(id)` on delete set null if needed.
- [ ] Step 7: Ensure migration does not include forbidden secret or raw-content columns.
- [ ] Step 8: Create admin entities and enum types.
- [ ] Step 9: Create admin repositories.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=AdminPersistenceTest test
```

## Acceptance Criteria

- Admin persistence tests pass.
- Admin role and status constraints are enforced.
- Audit logs are append-only style records with redacted details only.
- No endpoint or web UI is created.

## Stop Conditions

- M1 migrations are incomplete.
- Migration number conflicts.
- Lexeme migration shape conflicts with `DATA_MODEL.md`.
- Any file outside Allowed Files must be modified.
- Any implementation stores raw passwords, tokens, book content, or translated paragraphs.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

