# M3-F03-T01 Vocabulary Boundary Regression

## Task ID

`M3-F03-T01`

## Title

Add vocabulary boundary regression tests.

## Goal

Protect the core boundary between public lexemes and private user word cards.

## Scope

This task only does:

- Add regression tests across vocabulary persistence and APIs.
- Verify public lexemes do not store user review state.
- Verify user cards do not create public sentence lexemes.
- Verify user isolation.
- Verify private sentence context is never visible to other users.

This task does not:

- Add new production endpoints.
- Add admin APIs.
- Add translation lookup.
- Add mobile code.

## Allowed Files

- `server/src/test/java/com/studyforread/server/vocabulary/VocabularyBoundaryRegressionTest.java`
- If and only if tests expose a boundary failure, these files may be modified:
  - `server/src/main/java/com/studyforread/server/vocabulary/VocabularyController.java`
  - `server/src/main/java/com/studyforread/server/vocabulary/VocabularyService.java`
  - `server/src/main/java/com/studyforread/server/vocabulary/dto/CreateVocabularyCardRequest.java`
  - `server/src/main/java/com/studyforread/server/vocabulary/dto/VocabularyCardResponse.java`
  - `server/src/main/java/com/studyforread/server/vocabulary/dto/DueVocabularyCardsResponse.java`
  - `server/src/main/java/com/studyforread/server/vocabulary/dto/ReviewVocabularyCardRequest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/vocabulary/Lexeme.java`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCard.java`
- `server/src/main/java/com/studyforread/server/auth/**`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/PRD-v2.md`
- `docs/specs/DATA_MODEL.md`
- `docs/specs/API_CONTRACT.md`
- All M3 vocabulary task cards.

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/vocabulary/VocabularyBoundaryRegressionTest.java`

Test behavior:

- `lexemes` table has no columns named `review_status`, `review_count`, `next_review_at`, or `last_reviewed_at`.
- Creating a private sentence card does not insert a row into `lexemes`.
- Creating a lexeme card stores review state in `user_word_cards`, not `lexemes`.
- User A cannot list User B's due cards.
- User A cannot review User B's card.
- Private sentence surface, definition, and context are visible only to the owner.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=VocabularyBoundaryRegressionTest test
```

Expected red or green result:

- If prior tasks already comply, test may pass after writing it.
- If it fails, failure must show an actual boundary gap.

## Implementation Steps

- [ ] Step 1: Write `VocabularyBoundaryRegressionTest`.
- [ ] Step 2: Run verification command.
- [ ] Step 3: If tests pass, do not change production code.
- [ ] Step 4: If tests fail due to public/private boundary leaks, fix only the relevant Allowed Files.
- [ ] Step 5: Run verification command again.
- [ ] Step 6: Run all M3 vocabulary tests.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=VocabularyBoundaryRegressionTest test
.\mvnw.cmd -Dtest=LexemeRepositoryTest,UserWordCardRepositoryTest,CreateVocabularyCardEndpointTest,ListDueVocabularyCardsEndpointTest,ReviewVocabularyCardEndpointTest,VocabularyBoundaryRegressionTest test
```

## Acceptance Criteria

- Boundary regression test passes.
- All M3 vocabulary tests pass.
- Public lexemes do not store user review state.
- Private sentence cards never become public lexemes automatically.
- User isolation is enforced.

## Stop Conditions

- M3 endpoint tasks are incomplete.
- Boundary failure requires migration changes.
- Fix requires modifying files outside Allowed Files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

