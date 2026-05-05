# M5-F01-T01 Study Daily Stats Persistence

## Task ID

`M5-F01-T01`

## Title

Create study daily stats persistence.

## Goal

Add the migration, entity, repository, and repository tests for per-user daily study statistics.

## Scope

This task only does:

- Add `study_daily_stats` migration.
- Add `StudyDailyStat` entity.
- Add `StudyDailyStatRepository`.
- Add repository tests for uniqueness, constraints, user ownership, and forbidden columns.

This task does not:

- Add stats API endpoints.
- Add automatic stats updates from reading, lookup, translation, or vocabulary endpoints.
- Add mobile code.
- Add admin stats.

## Allowed Files

- `server/src/main/resources/db/migration/V6__create_study_daily_stats.sql`
- `server/src/main/java/com/studyforread/server/stats/StudyDailyStat.java`
- `server/src/main/java/com/studyforread/server/stats/StudyDailyStatRepository.java`
- `server/src/test/java/com/studyforread/server/stats/StudyDailyStatRepositoryTest.java`

## Forbidden Files

- `server/src/main/java/com/studyforread/server/stats/*Controller.java`
- `server/src/main/java/com/studyforread/server/stats/*Service.java`
- `server/src/main/java/com/studyforread/server/auth/**`
- `server/src/main/java/com/studyforread/server/reading/**`
- `server/src/main/java/com/studyforread/server/study/**`
- `server/src/main/java/com/studyforread/server/vocabulary/**`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DATA_MODEL.md`
- `docs/specs/API_CONTRACT.md`
- `server/src/main/resources/db/migration/V1__create_users_and_refresh_tokens.sql`
- `server/src/main/java/com/studyforread/server/user/UserAccount.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/stats/StudyDailyStatRepositoryTest.java`

Test behavior:

- Saving one stats row for one user and date succeeds.
- Duplicate `user_id + stat_date` is rejected by the database.
- `reading_minutes`, `lookup_count`, `paragraph_translation_count`, `cards_created`, and `cards_reviewed` reject negative values.
- New rows can store zero values for every counter.
- `user_id` references `users(id)` and cascades on user delete.
- Table has no columns named `content`, `chapter_content`, `original_file`, `file_path`, `source_text`, `raw_text`, `translated_text`, or `paragraph_text`.
- Repository query by user returns only that user's rows.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=StudyDailyStatRepositoryTest test
```

Expected red result:

- Test fails because `StudyDailyStat`, repository, or migration does not exist.

## Implementation Steps

- [ ] Step 1: Write `StudyDailyStatRepositoryTest`.
- [ ] Step 2: Run red test and confirm missing class or missing table failure.
- [ ] Step 3: Create `V6__create_study_daily_stats.sql` following `DATA_MODEL.md`.
- [ ] Step 4: Use the same UUID strategy as earlier migrations; do not introduce a second UUID strategy in this task.
- [ ] Step 5: Add `user_id uuid not null references users(id) on delete cascade`.
- [ ] Step 6: Add `stat_date date not null`.
- [ ] Step 7: Add integer counters with `not null default 0`.
- [ ] Step 8: Add check constraints ensuring all counters are `>= 0`.
- [ ] Step 9: Add `created_at timestamptz not null default now()` and `updated_at timestamptz not null default now()`.
- [ ] Step 10: Add unique constraint or unique index on `user_id, stat_date`.
- [ ] Step 11: Ensure migration does not include forbidden raw-content columns.
- [ ] Step 12: Create `StudyDailyStat` entity mapped to `study_daily_stats`.
- [ ] Step 13: Create `StudyDailyStatRepository` with query methods for current user/date and current user rows.
- [ ] Step 14: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=StudyDailyStatRepositoryTest test
```

## Acceptance Criteria

- Repository tests pass.
- Uniqueness is enforced by database constraint.
- All counters reject negative values.
- Rows are user-owned.
- No raw book, lookup, or translated text column exists.
- No API endpoint is created in this task.

## Stop Conditions

- M1 user persistence is incomplete.
- Migration number conflicts.
- Test datasource cannot run migrations.
- Any file outside Allowed Files must be modified.
- Any implementation stores raw book content, raw lookup text, or translated paragraph text.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

