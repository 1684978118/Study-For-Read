# M3-F02-T01 Create Vocabulary Card Endpoint

## Task ID

`M3-F02-T01`

## Title

Implement create vocabulary card endpoint.

## Goal

Allow an authenticated user to create or reuse a vocabulary card for a public lexeme or create a private sentence card.

## Scope

This task only does:

- Add vocabulary card request and response DTOs.
- Add vocabulary service create-card behavior.
- Add `POST /api/v1/vocabulary/cards`.
- Add endpoint tests for lexeme cards, duplicate reuse, private sentence cards, validation, and user isolation.

This task does not:

- Add due-card list endpoint.
- Add review endpoint.
- Create lexemes automatically from translation output.
- Add lookup endpoint.
- Add mobile code.

## Allowed Files

- `server/src/main/java/com/studyforread/server/vocabulary/VocabularyController.java`
- `server/src/main/java/com/studyforread/server/vocabulary/VocabularyService.java`
- `server/src/main/java/com/studyforread/server/vocabulary/dto/CreateVocabularyCardRequest.java`
- `server/src/main/java/com/studyforread/server/vocabulary/dto/VocabularyCardResponse.java`
- `server/src/main/java/com/studyforread/server/vocabulary/dto/LexemeSummaryResponse.java`
- `server/src/test/java/com/studyforread/server/vocabulary/CreateVocabularyCardEndpointTest.java`

## Forbidden Files

- `server/src/main/resources/db/migration/**`
- `server/src/main/java/com/studyforread/server/vocabulary/Lexeme.java`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCard.java`
- `server/src/main/java/com/studyforread/server/vocabulary/LexemeRepository.java`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCardRepository.java`
- `server/src/main/java/com/studyforread/server/auth/**`
- `apps/**`
- `infra/**`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/DATA_MODEL.md`
- `server/src/main/java/com/studyforread/server/vocabulary/Lexeme.java`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCard.java`
- `server/src/main/java/com/studyforread/server/vocabulary/LexemeRepository.java`
- `server/src/main/java/com/studyforread/server/vocabulary/UserWordCardRepository.java`

## Tests First

Create:

- `server/src/test/java/com/studyforread/server/vocabulary/CreateVocabularyCardEndpointTest.java`

Test behavior:

- Authenticated user can create a `lexeme` card with an existing `lexemeId`.
- Recreating the same lexeme card for the same user returns the existing card, not a duplicate.
- A different user can create a card for the same lexeme.
- Missing `lexemeId` for `cardType=lexeme` returns `PRIVATE_CARD_INVALID` or `VALIDATION_ERROR` according to existing error handling.
- Authenticated user can create a `private_sentence` card with `privateSurface` and `privateDefinition`.
- Missing private sentence required fields returns `PRIVATE_CARD_INVALID`.
- Invalid `sourceBookFingerprint` returns `PRIVATE_CARD_INVALID`.
- Response never exposes another user's review state.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=CreateVocabularyCardEndpointTest test
```

Expected red result:

- Test fails because vocabulary card endpoint does not exist.

## Implementation Steps

- [ ] Step 1: Write `CreateVocabularyCardEndpointTest`.
- [ ] Step 2: Run red test and confirm endpoint missing.
- [ ] Step 3: Create `CreateVocabularyCardRequest` matching `API_CONTRACT.md`.
- [ ] Step 4: Validate `cardType` is `lexeme` or `private_sentence`.
- [ ] Step 5: Validate `sourceBookFingerprint`, when present, as 64-character lowercase SHA-256 hex.
- [ ] Step 6: Create `LexemeSummaryResponse`.
- [ ] Step 7: Create `VocabularyCardResponse`.
- [ ] Step 8: Add `VocabularyService.createCard`.
- [ ] Step 9: For `cardType=lexeme`, require existing lexeme and reuse current user's existing card if present.
- [ ] Step 10: For `cardType=private_sentence`, create user-private card only; do not create a public lexeme.
- [ ] Step 11: Add `VocabularyController.createCard` at `POST /api/v1/vocabulary/cards`.
- [ ] Step 12: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\server"
.\mvnw.cmd -Dtest=CreateVocabularyCardEndpointTest test
```

## Acceptance Criteria

- Endpoint path is exactly `/api/v1/vocabulary/cards`.
- Endpoint requires user auth.
- Duplicate lexeme cards return existing current-user card.
- Private sentence cards remain private.
- Response matches API contract.
- No lookup or review endpoint is implemented.

## Stop Conditions

- Current-user extraction from auth is unavailable.
- User word card persistence task is incomplete.
- Any file outside Allowed Files must be modified.
- Implementing this requires creating public lexemes from private sentence cards.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

