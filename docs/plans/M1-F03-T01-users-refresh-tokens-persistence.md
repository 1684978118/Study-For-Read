# M1-F03-T01 Users And Refresh Tokens Persistence

## Task ID

`M1-F03-T01`

## Title

Create user and refresh token persistence.

## Goal

Add the database migration, JPA entities, and repositories needed for user authentication.

## Scope

This task only does:

- Add migration for `users` and `refresh_tokens`.
- Add `UserAccount` entity.
- Add `RefreshToken` entity.
- Add repositories.
- Add repository tests for email uniqueness and refresh token lookup.

Prerequisite:

- `M1-F02-T02-test-datasource-profile.md` must be complete so repository tests can run datasource, JPA, and Flyway in the `test` profile.

This task does not:

- Implement password hashing service.
- Implement JWT.
- Implement register or login controllers.
- Add admin users.
- Add book, vocabulary, translation, or stats tables.

## Allowed Files

- `server/src/main/resources/db/migration/V1__create_users_and_refresh_tokens.sql`
- `server/src/main/java/com/studyforread/server/user/UserAccount.java`
- `server/src/main/java/com/studyforread/server/user/UserStatus.java`
- `server/src/main/java/com/studyforread/server/user/UserAccountRepository.java`
- `server/src/main/java/com/studyforread/server/auth/RefreshToken.java`
- `server/src/main/java/com/studyforread/server/auth/RefreshTokenRepository.java`
- `server/src/test/java/com/studyforread/server/user/UserAccountRepositoryTest.java`
- `server/src/test/java/com/studyforread/server/auth/RefreshTokenRepositoryTest.java`

## Forbidden Files

- `server/src/main/java/com/studyforread/server/api/**`
- `server/src/main/java/com/studyforread/server/**/controller/**`
- `server/src/main/java/com/studyforread/server/**/service/**`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DATA_MODEL.md`
- `server/src/main/resources/application.yml`
- `server/src/test/resources/application-test.yml`

## Tests First

Create repository tests:

- `UserAccountRepositoryTest`
- `RefreshTokenRepositoryTest`

Test behavior:

- Saving a user lower-case email can be found by email.
- Duplicate email is rejected by database uniqueness.
- Saving a refresh token can be found by token hash.
- Revoked token has non-null `revokedAt`.
- Migration enables UUID generation consistently or documents application-generated UUIDs.
- `users.status` rejects values outside `active` and `disabled`.
- `refresh_tokens.token_hash` is stored as a 64-character SHA-256 hex hash.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=UserAccountRepositoryTest,RefreshTokenRepositoryTest test
```

Expected red result:

- Tests fail because entities, repositories, or migration do not exist.

## Implementation Steps

- [ ] Step 1: Write the two repository tests.
- [ ] Step 2: Run the red test command and confirm missing class or missing table failure.
- [ ] Step 3: Create migration `V1__create_users_and_refresh_tokens.sql` using the columns from `DATA_MODEL.md`.
- [ ] Step 4: Prefer application-generated UUIDs for this migration so the schema can run in the H2 PostgreSQL-compatible test profile. If choosing PostgreSQL `gen_random_uuid()` instead, first create a separate task card for PostgreSQL-backed tests.
- [ ] Step 5: Ensure `users.email` is unique and constrained to lowercase.
- [ ] Step 6: Ensure `users.status` has a check constraint for `active` and `disabled`.
- [ ] Step 7: Ensure `refresh_tokens.token_hash` is `char(64)` and unique.
- [ ] Step 8: Ensure `refresh_tokens.user_id` references `users(id)` on delete cascade.
- [ ] Step 9: Ensure `refresh_tokens.expires_at > created_at`.
- [ ] Step 10: Create `UserStatus` enum with `ACTIVE` and `DISABLED`, mapping to lowercase database values or converting at persistence boundary.
- [ ] Step 11: Create `UserAccount` entity mapped to `users`.
- [ ] Step 12: Create `UserAccountRepository` with `Optional<UserAccount> findByEmail(String email)`.
- [ ] Step 13: Create `RefreshToken` entity mapped to `refresh_tokens`.
- [ ] Step 14: Create `RefreshTokenRepository` with `Optional<RefreshToken> findByTokenHash(String tokenHash)`.
- [ ] Step 15: Run the verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=UserAccountRepositoryTest,RefreshTokenRepositoryTest test
```

## Acceptance Criteria

- Migration creates only `users` and `refresh_tokens`.
- No raw password field exists; only `password_hash`.
- Email uniqueness is enforced by database constraint.
- Status and token hash constraints match `DATA_MODEL.md`.
- Repository tests pass.
- No auth endpoint or service is implemented in this task.

## Stop Conditions

- `M1-F02-T02-test-datasource-profile.md` is incomplete.
- Test datasource cannot run migrations.
- Existing migration numbering conflicts.
- Any file outside Allowed Files must be modified.
- Implementing this requires changing config from prior tasks.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
