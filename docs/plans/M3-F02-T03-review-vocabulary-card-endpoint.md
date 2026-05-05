# M3-F02-T03 Review Vocabulary Card Endpoint

## Task ID

`M3-F02-T03`

## Title

Implement vocabulary card review endpoint.

## Goal

Allow an authenticated user to review one of their cards and update first-release spaced repetition state.

## Scope

This task only does:

- Add review request DTO.
- Add review scheduling behavior.
- Add `POST /api/v1/vocabulary/cards/{cardId}/review`.
- Add endpoint tests for known, unknown, missing card, and user isolation.

This task does not:

- Add advanced SRS algorithms.
- Add push notifications.
- Add all-cards endpoint.
- Add mobile code.

## Allowed Files

- `server/src/main/java/com/studyforread/server/vocabulary/VocabularyController.java`
- `server/src/main/java/com/studyforread/server/vocabulary/VocabularyService.java`
- `server/src/main/java/com/studyforread/server/vocabulary/dto/ReviewVocabularyCardRequest.java`
- `server/src/main/java/com/studyforread/server/vocabulary/dto/VocabularyCardResponse.java`
- `server/src/test/java/com/studyforread/server/vocabulary/ReviewVocabularyCardEndpointTest.java`

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
- `docs/specs/PRD-v2.md`
- `docs/specs/API_CONTRACT.md`
- `server/src/main/java/com/studyforread/server/vocabulary/VocabularyService.java`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCardRepository.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/vocabulary/ReviewVocabularyCardEndpointTest.java`

Test behavior:

- Reviewing a new card with `known=true` changes status to `learning`, increments review count, sets `lastReviewedAt`, and sets next review to reviewed time plus 3 days.
- Reviewing a learning card with `known=true` advances interval to 7, then 15, then 30 days according to review count.
- Reviewing any card with `known=false` changes status to `learning`, increments review count, and sets next review to reviewed time plus 1 day.
- Reviewing a missing card returns `WORD_CARD_NOT_FOUND`.
- User A cannot review User B's card.
- Unauthenticated request returns `UNAUTHORIZED`.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=ReviewVocabularyCardEndpointTest test
```

Expected red result:

- Test fails because review endpoint does not exist.

## Implementation Steps

- [ ] Step 1: Write `ReviewVocabularyCardEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing.
- [ ] Step 3: Create `ReviewVocabularyCardRequest` with `known` and `reviewedAt`.
- [ ] Step 4: Add review scheduling logic inside `VocabularyService.reviewCard`.
- [ ] Step 5: For `known=false`, set next review to plus 1 day.
- [ ] Step 6: For `known=true`, use intervals 3, 7, 15, and 30 days based on the resulting review count.
- [ ] Step 7: Keep first-release behavior simple; do not add ease factors or SM-2.
- [ ] Step 8: Add `VocabularyController.reviewCard`.
- [ ] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=ReviewVocabularyCardEndpointTest test
```

## Acceptance Criteria

- Endpoint path is exactly `/api/v1/vocabulary/cards/{cardId}/review`.
- Endpoint requires user auth.
- User can review only their own cards.
- First-release intervals match PRD-v2.
- Response matches API contract.

## Stop Conditions

- User word card repository cannot find by current user id and card id.
- Scheduling behavior conflicts with PRD-v2.
- Any file outside Allowed Files must be modified.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

