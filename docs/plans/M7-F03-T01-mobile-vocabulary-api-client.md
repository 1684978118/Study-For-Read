# M7-F03-T01 Mobile Vocabulary API Client

## Task ID

`M7-F03-T01`

## Title

Implement mobile vocabulary API client.

## Goal

Add fake-testable mobile API calls for creating cards, listing due cards, and reviewing cards.

## Scope

This task only does:

- Add vocabulary DTOs matching `API_CONTRACT.md`.
- Add `VocabularyApiClient`.
- Add unit tests with fake HTTP.

This task does not:

- Add Vocabulary UI.
- Add local card repository behavior.
- Add offline review scheduling.
- Add sync worker.

## Allowed Files

- `apps/mobile/lib/src/features/vocabulary/domain/vocabulary_card.dart`
- `apps/mobile/lib/src/features/vocabulary/data/vocabulary_api_client.dart`
- `apps/mobile/lib/src/core/network/api_client.dart`
- `apps/mobile/test/src/features/vocabulary/vocabulary_api_client_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/vocabulary/presentation/**`
- `apps/mobile/lib/src/features/vocabulary/data/local_word_card_repository.dart`
- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/pubspec.yaml`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `apps/mobile/lib/src/core/network/api_client.dart`
- `apps/mobile/lib/src/core/network/api_envelope.dart`
- `apps/mobile/lib/src/core/network/api_error.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/vocabulary/vocabulary_api_client_test.dart`

Test behavior:

- Creating a lexeme card sends `POST /api/v1/vocabulary/cards` with `cardType=lexeme`, `lexemeId`, `sourceBookFingerprint`, and `sourceBookTitle`.
- Creating a private sentence card sends `cardType=private_sentence`, `privateSurface`, `privateDefinition`, `privateContext`, and source book metadata.
- Listing due cards calls `GET /api/v1/vocabulary/cards/due`.
- Reviewing a card calls `POST /api/v1/vocabulary/cards/{cardId}/review` with `known` and `reviewedAt`.
- `WORD_CARD_ALREADY_EXISTS` maps to an idempotent existing-card result if response data is available, otherwise a stable mobile error.
- `WORD_CARD_NOT_FOUND` maps to a stable mobile error.
- Client never sends original chapter content or original file path.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/vocabulary/vocabulary_api_client_test.dart
```

Expected red result:

- Test fails because `VocabularyApiClient` or DTOs do not exist.

## Implementation Steps

- [ ] Step 1: Write `vocabulary_api_client_test.dart`.
- [ ] Step 2: Run red test and confirm missing class failures.
- [ ] Step 3: Create `VocabularyCard` domain model with public lexeme and private sentence display fields.
- [ ] Step 4: Create `VocabularyApiClient.createLexemeCard`.
- [ ] Step 5: Create `VocabularyApiClient.createPrivateSentenceCard`.
- [ ] Step 6: Create `VocabularyApiClient.listDueCards`.
- [ ] Step 7: Create `VocabularyApiClient.reviewCard`.
- [ ] Step 8: Reuse existing API envelope and error parsing.
- [ ] Step 9: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/vocabulary/vocabulary_api_client_test.dart
flutter analyze
```

## Acceptance Criteria

- Vocabulary API client tests pass.
- DTOs match `API_CONTRACT.md`.
- Tests use fake HTTP and do not require a live backend.
- Client does not send original file path, full chapter text, or full book text.
- No UI is added in this task.

## Stop Conditions

- M6 auth network client is incomplete.
- API envelope parsing is missing and cannot be changed within Allowed Files.
- Any file outside Allowed Files must be modified.
- Any implementation sends full chapters or original files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.

