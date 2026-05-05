# M4-F01-T01 Translation Events Persistence

## Task ID

`M4-F01-T01`

## Title

Create translation event persistence.

## Goal

Add the migration, entity, enum, repository, and tests for minimal translation usage logging without raw text storage.

## Scope

This task only does:

- Add `translation_events` migration.
- Add `TranslationEvent` entity.
- Add `TranslationRequestType` enum.
- Add repository methods for writing and basic lookup.
- Add repository tests for schema constraints and forbidden columns.

This task does not:

- Add lookup endpoint.
- Add translation endpoint.
- Add annotation endpoint.
- Add provider code.
- Store raw text or translated text.

## Allowed Files

- `server/src/main/resources/db/migration/V5__create_translation_events.sql`
- `server/src/main/java/com/studyforread/server/study/TranslationEvent.java`
- `server/src/main/java/com/studyforread/server/study/TranslationRequestType.java`
- `server/src/main/java/com/studyforread/server/study/TranslationEventRepository.java`
- `server/src/test/java/com/studyforread/server/study/TranslationEventRepositoryTest.java`

## Forbidden Files

- `server/src/main/java/com/studyforread/server/study/*Controller.java`
- `server/src/main/java/com/studyforread/server/study/*Service.java`
- `server/src/main/java/com/studyforread/server/vocabulary/**`
- `server/src/main/java/com/studyforread/server/auth/**`
- `apps/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DATA_MODEL.md`
- `docs/specs/API_CONTRACT.md`
- `server/src/main/java/com/studyforread/server/user/UserAccount.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/study/TranslationEventRepositoryTest.java`

Test behavior:

- Saving a `word_lookup` event stores `source_text_hash` as 64-character SHA-256 hex.
- `source_text_length <= 0` is rejected.
- `request_type` rejects values outside `word_lookup`, `paragraph_translation`, and `annotation`.
- Table has no columns named `source_text`, `raw_text`, `translated_text`, `paragraph_text`, or `chapter_content`.
- Query by user and created time returns only that user's events.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=TranslationEventRepositoryTest test
```

Expected red result:

- Test fails because `TranslationEvent`, repository, or migration does not exist.

## Implementation Steps

- [ ] Step 1: Write `TranslationEventRepositoryTest`.
- [ ] Step 2: Run red test and confirm missing class or missing table failure.
- [ ] Step 3: Create `V5__create_translation_events.sql` following `DATA_MODEL.md`.
- [ ] Step 4: Add `source_text_hash char(64) not null`.
- [ ] Step 5: Add `source_text_length integer not null check (source_text_length > 0)`.
- [ ] Step 6: Add `request_type` check constraint for `word_lookup`, `paragraph_translation`, and `annotation`.
- [ ] Step 7: Add `user_id references users(id) on delete restrict`.
- [ ] Step 8: Ensure migration does not include forbidden raw-text columns.
- [ ] Step 9: Create `TranslationRequestType` enum mapped to lowercase database values or converted at persistence boundary.
- [ ] Step 10: Create `TranslationEvent` entity mapped to `translation_events`.
- [ ] Step 11: Create `TranslationEventRepository`.
- [ ] Step 12: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=TranslationEventRepositoryTest test
```

## Acceptance Criteria

- Repository tests pass.
- Migration stores hash and length only.
- No raw source or translated text column exists.
- No endpoint or provider logic is created in this task.

## Stop Conditions

- M1 user persistence is incomplete.
- Migration number conflicts.
- Test datasource cannot run migrations.
- Any file outside Allowed Files must be modified.
- Any implementation stores raw source or translated text.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

