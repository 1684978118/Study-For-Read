# M3-F01-T01 Lexemes Persistence

## Task ID

`M3-F01-T01`

## Title

Create public lexeme persistence.

## Goal

Add the database migration, entity, enum types, repository, and repository tests for reusable public lexemes.

## Scope

This task only does:

- Add `lexemes` migration.
- Add `Lexeme` entity.
- Add `LexemeEntryType` enum.
- Add `LexemeStatus` enum.
- Add repository methods for lookup by normalized surface.
- Add repository tests for uniqueness and constraints.

This task does not:

- Add user word cards.
- Add vocabulary controllers.
- Add admin lexeme management.
- Call translation providers.
- Add mobile code.

## Allowed Files

- `server/src/main/resources/db/migration/V3__create_lexemes.sql`
- `server/src/main/java/com/studyforread/server/vocabulary/Lexeme.java`
- `server/src/main/java/com/studyforread/server/vocabulary/LexemeEntryType.java`
- `server/src/main/java/com/studyforread/server/vocabulary/LexemeStatus.java`
- `server/src/main/java/com/studyforread/server/vocabulary/LexemeRepository.java`
- `server/src/test/java/com/studyforread/server/vocabulary/LexemeRepositoryTest.java`

## Forbidden Files

- `server/src/main/java/com/studyforread/server/vocabulary/*Controller.java`
- `server/src/main/java/com/studyforread/server/vocabulary/*Service.java`
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
- `server/src/main/resources/db/migration/V1__create_users_and_refresh_tokens.sql`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/vocabulary/LexemeRepositoryTest.java`

Test behavior:

- Saving an active word lexeme can be found by source language, target language, normalized surface, and entry type.
- Duplicate `source_lang + target_lang + normalized_surface + entry_type` is rejected.
- `entry_type` rejects values outside `word`, `phrase`, and `idiom`.
- `status` rejects values outside `active`, `candidate`, and `rejected`.
- `normalized_surface` must equal `lower(trim(normalized_surface))`.
- No user review fields exist on `lexemes`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=LexemeRepositoryTest test
```

Expected red result:

- Test fails because `Lexeme`, repository, or migration does not exist.

## Implementation Steps

- [ ] Step 1: Write `LexemeRepositoryTest`.
- [ ] Step 2: Run red test and confirm missing class or missing table failure.
- [ ] Step 3: Create `V3__create_lexemes.sql` following `DATA_MODEL.md`.
- [ ] Step 4: Add unique constraint on `source_lang, target_lang, normalized_surface, entry_type`.
- [ ] Step 5: Add check constraint for `entry_type`.
- [ ] Step 6: Add check constraint for `status`.
- [ ] Step 7: Add check constraint that `normalized_surface = lower(trim(normalized_surface))`.
- [ ] Step 8: Ensure `created_by_admin_id` references `admin_users(id)` on delete set null only if `admin_users` already exists; if admin table is not created yet, omit this foreign key and write a follow-up admin migration task.
- [ ] Step 9: Create `LexemeEntryType` with `WORD`, `PHRASE`, and `IDIOM`, mapped to lowercase database values or converted at persistence boundary.
- [ ] Step 10: Create `LexemeStatus` with `ACTIVE`, `CANDIDATE`, and `REJECTED`, mapped to lowercase database values or converted at persistence boundary.
- [ ] Step 11: Create `Lexeme` entity mapped to `lexemes`.
- [ ] Step 12: Create `LexemeRepository` with lookup method for language pair, normalized surface, and entry type.
- [ ] Step 13: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=LexemeRepositoryTest test
```

## Acceptance Criteria

- Repository tests pass.
- Public lexeme uniqueness is enforced by database constraint.
- Lexeme table has no user-specific review columns.
- No vocabulary endpoint is created in this task.

## Stop Conditions

- Migration number conflicts.
- Admin table foreign key cannot be created because admin milestone is not complete.
- Test datasource cannot run migrations.
- Any file outside Allowed Files must be modified.
- Any implementation tries to store user review state in `lexemes`.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

