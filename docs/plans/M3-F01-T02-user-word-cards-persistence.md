# M3-F01-T02 User Word Cards Persistence

## Task ID

`M3-F01-T02`

## Title

Create user word card persistence.

## Goal

Add the database migration, entity, enums, repository, and repository tests for user-specific vocabulary review cards.

## Scope

This task only does:

- Add `user_word_cards` migration.
- Add `UserWordCard` entity.
- Add `WordCardType` enum.
- Add `ReviewStatus` enum.
- Add repository methods for due card listing and user-owned lookup.
- Add repository tests for constraints and user isolation.

This task does not:

- Add vocabulary controllers.
- Add review scheduling service.
- Add public lexeme admin APIs.
- Add translation lookup.
- Add mobile code.

## Allowed Files

- `server/src/main/resources/db/migration/V4__create_user_word_cards.sql`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCard.java`
- `server/src/main/java/com/studyforread/server/vocabulary/WordCardType.java`
- `server/src/main/java/com/studyforread/server/vocabulary/ReviewStatus.java`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCardRepository.java`
- `server/src/test/java/com/studyforread/server/vocabulary/UserWordCardRepositoryTest.java`

## Forbidden Files

- `server/src/main/java/com/studyforread/server/vocabulary/*Controller.java`
- `server/src/main/java/com/studyforread/server/vocabulary/*Service.java`
- `server/src/main/java/com/studyforread/server/vocabulary/Lexeme.java`
- `server/src/main/java/com/studyforread/server/vocabulary/LexemeRepository.java`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/DATA_MODEL.md`
- `server/src/main/java/com/studyforread/server/user/UserAccount.java`
- `server/src/main/java/com/studyforread/server/vocabulary/Lexeme.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/vocabulary/UserWordCardRepositoryTest.java`

Test behavior:

- A user can save one lexeme card linked to a public lexeme.
- Duplicate `user_id + lexeme_id` is rejected for public lexeme cards.
- A different user can save a card for the same lexeme.
- A private sentence card requires `private_surface` and `private_definition`.
- A lexeme card requires `lexeme_id`.
- `source_book_fingerprint`, when present, must be 64-character SHA-256 hex.
- `review_count` rejects negative values.
- Due-card query returns only current user's due cards.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=UserWordCardRepositoryTest test
```

Expected red result:

- Test fails because `UserWordCard`, repository, or migration does not exist.

## Implementation Steps

- [ ] Step 1: Write `UserWordCardRepositoryTest`.
- [ ] Step 2: Run red test and confirm missing class or missing table failure.
- [ ] Step 3: Create `V4__create_user_word_cards.sql` following `DATA_MODEL.md`.
- [ ] Step 4: Add check constraint for `card_type`.
- [ ] Step 5: Add check constraint for `review_status`.
- [ ] Step 6: Add check constraint for `review_count >= 0`.
- [ ] Step 7: Add check constraint requiring `lexeme_id` when `card_type='lexeme'`.
- [ ] Step 8: Add check constraint requiring `private_surface` and `private_definition` when `card_type='private_sentence'`.
- [ ] Step 9: Add foreign key `user_id references users(id) on delete cascade`.
- [ ] Step 10: Add foreign key `lexeme_id references lexemes(id) on delete restrict`.
- [ ] Step 11: Add unique partial index on `user_id, lexeme_id` where `lexeme_id is not null`.
- [ ] Step 12: Create `WordCardType` with `LEXEME` and `PRIVATE_SENTENCE`, mapped to lowercase database values or converted at persistence boundary.
- [ ] Step 13: Create `ReviewStatus` with `NEW`, `LEARNING`, and `KNOWN`, mapped to lowercase database values or converted at persistence boundary.
- [ ] Step 14: Create `UserWordCard` entity mapped to `user_word_cards`.
- [ ] Step 15: Create `UserWordCardRepository` with:
  - `Optional<UserWordCard> findByUserIdAndId(UUID userId, UUID id)`
  - `Optional<UserWordCard> findByUserIdAndLexemeId(UUID userId, UUID lexemeId)`
  - due-card query filtered by user id and `nextReviewAt <= now or nextReviewAt is null`.
- [ ] Step 16: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=UserWordCardRepositoryTest test
```

## Acceptance Criteria

- Repository tests pass.
- Public lexeme cards and private sentence cards are valid but distinct.
- Review state lives only on `user_word_cards`.
- One user cannot query another user's due cards.
- No controller or service is created in this task.

## Stop Conditions

- Lexeme persistence task is incomplete.
- Migration number conflicts.
- Test datasource cannot run migrations.
- Any file outside Allowed Files must be modified.
- Any implementation tries to make private sentence cards public lexemes automatically.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

