# M7-F03-T02 Mobile Save Vocabulary From Lookup Flow

## Task ID

`M7-F03-T02`

## Title

Add save-to-vocabulary flow from lookup.

## Goal

Allow users to save lookup results as public lexeme cards with offline-safe local state.

## Scope

This task only does:

- Add vocabulary save controller.
- Wire lookup bottom sheet Save action.
- Save local word card state.
- Enqueue pending `word_card_create` events when offline or API fails.
- Increment local `cards_created` stats.

This task does not:

- Add Vocabulary screen lists.
- Add card review behavior.
- Add save sentence controls under translated paragraphs.
- Add private sentence card creation.
- Add sync worker execution.
- Add public lexeme editing.

## Allowed Files

- `apps/mobile/lib/src/features/vocabulary/presentation/save_vocabulary_controller.dart`
- `apps/mobile/lib/src/features/study/presentation/lookup_bottom_sheet.dart`
- `apps/mobile/lib/src/features/vocabulary/data/vocabulary_api_client.dart`
- `apps/mobile/lib/src/features/vocabulary/data/local_word_card_repository.dart`
- `apps/mobile/lib/src/features/study/data/local_lexeme_repository.dart`
- `apps/mobile/lib/src/features/sync/data/pending_sync_event_repository.dart`
- `apps/mobile/lib/src/features/stats/data/local_study_stats_repository.dart`
- `apps/mobile/test/src/features/vocabulary/save_vocabulary_controller_test.dart`
- `apps/mobile/test/src/features/study/save_from_lookup_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_screen.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/review_controller.dart`
- `apps/mobile/lib/src/features/sync/presentation/**`
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
- `docs/specs/UI_FLOWS.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `apps/mobile/lib/src/features/vocabulary/data/vocabulary_api_client.dart`
- `apps/mobile/lib/src/features/vocabulary/data/local_word_card_repository.dart`
- `apps/mobile/lib/src/features/study/presentation/lookup_bottom_sheet.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/vocabulary/save_vocabulary_controller_test.dart`
- `apps/mobile/test/src/features/study/save_from_lookup_test.dart`

Test behavior:

- Saving a lookup lexeme online calls `VocabularyApiClient.createLexemeCard`, upserts local lexeme cache, and upserts local word card with `sync_status=synced`.
- Saving a lookup lexeme offline creates local word card with `sync_status=local_only` and enqueues `word_card_create`.
- Saving the same lexeme twice is idempotent for the same owner.
- Save success increments today's `cards_created` once.
- Pending sync payload includes source book fingerprint and title only, not chapter content.
- Translated paragraphs do not show save sentence controls in this task.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/vocabulary/save_vocabulary_controller_test.dart test/src/features/study/save_from_lookup_test.dart
```

Expected red result:

- Tests fail because save vocabulary controller or Save wiring does not exist.

## Implementation Steps

- [ ] Step 1: Write save vocabulary controller and sheet wiring tests.
- [ ] Step 2: Run red tests and confirm missing save behavior.
- [ ] Step 3: Create `SaveVocabularyController`.
- [ ] Step 4: Implement online lexeme card save using `VocabularyApiClient`.
- [ ] Step 5: Implement offline lexeme card save using local repository and pending sync event.
- [ ] Step 6: Increment `cards_created` only when a new local card is created.
- [ ] Step 7: Wire lookup bottom sheet Save action to the controller.
- [ ] Step 8: Ensure translated paragraphs do not gain save sentence controls.
- [ ] Step 9: Ensure pending payload excludes raw chapter content and original file path.
- [ ] Step 10: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/vocabulary/save_vocabulary_controller_test.dart test/src/features/study/save_from_lookup_test.dart
flutter analyze
```

## Acceptance Criteria

- Save vocabulary tests pass.
- Public lexeme cards use local storage rules.
- Offline save creates pending sync events.
- Cards-created stats increment correctly.
- Translated paragraphs do not show save sentence controls.
- No raw chapter content or original file path is synced.
- No Vocabulary list UI is created in this task.

## Stop Conditions

- Vocabulary API client is incomplete.
- Local learning data task is incomplete.
- Save action requires modifying UI files outside Allowed Files.
- Any implementation creates public lexemes from full private sentences.
- Any implementation adds translated-paragraph save buttons.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
