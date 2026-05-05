# M3-F02-T02 List Due Vocabulary Cards Endpoint

## Task ID

`M3-F02-T02`

## Title

Implement due vocabulary cards endpoint.

## Goal

Allow an authenticated user to list only their due vocabulary cards.

## Scope

This task only does:

- Add due-card list response DTO if needed.
- Add vocabulary service due-card list behavior.
- Add `GET /api/v1/vocabulary/cards/due`.
- Add endpoint tests for due logic, user isolation, and response shape.

This task does not:

- Add create-card endpoint.
- Add review endpoint.
- Add all-cards endpoint.
- Add import/export.
- Add mobile code.

## Allowed Files

- `server/src/main/java/com/studyforread/server/vocabulary/VocabularyController.java`
- `server/src/main/java/com/studyforread/server/vocabulary/VocabularyService.java`
- `server/src/main/java/com/studyforread/server/vocabulary/dto/DueVocabularyCardsResponse.java`
- `server/src/main/java/com/studyforread/server/vocabulary/dto/VocabularyCardResponse.java`
- `server/src/test/java/com/studyforread/server/vocabulary/ListDueVocabularyCardsEndpointTest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCard.java`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCardRepository.java`
- `server/src/main/java/com/studyforread/server/vocabulary/Lexeme.java`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `server/src/main/java/com/studyforread/server/vocabulary/VocabularyController.java`
- `server/src/main/java/com/studyforread/server/vocabulary/VocabularyService.java`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCardRepository.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/vocabulary/ListDueVocabularyCardsEndpointTest.java`

Test behavior:

- New cards with `nextReviewAt=null` are returned as due.
- Cards with `nextReviewAt` in the past are returned as due.
- Cards with `nextReviewAt` in the future are not returned.
- User sees only their own due cards.
- Lexeme cards include public lexeme summary.
- Private sentence cards include private surface and definition only for the owning user.
- Unauthenticated request returns `UNAUTHORIZED`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=ListDueVocabularyCardsEndpointTest test
```

Expected red result:

- Test fails because due cards endpoint does not exist.

## Implementation Steps

- [ ] Step 1: Write `ListDueVocabularyCardsEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing.
- [ ] Step 3: Create `DueVocabularyCardsResponse` with `items`.
- [ ] Step 4: Reuse or extend `VocabularyCardResponse` without exposing other users' state.
- [ ] Step 5: Add `VocabularyService.listDueCards`.
- [ ] Step 6: Use repository query filtered by current user id.
- [ ] Step 7: Treat `nextReviewAt=null` as due.
- [ ] Step 8: Add `VocabularyController.listDueCards`.
- [ ] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=ListDueVocabularyCardsEndpointTest test
```

## Acceptance Criteria

- Endpoint path is exactly `/api/v1/vocabulary/cards/due`.
- Endpoint requires user auth.
- Due logic matches task tests.
- User isolation is tested.
- Response shape matches API contract.

## Stop Conditions

- Create-card task is incomplete and response DTOs do not exist.
- Repository does not support due-card query and cannot be changed within this task.
- Any file outside Allowed Files must be modified.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

