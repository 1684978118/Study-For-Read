# M7-F04-T01 Mobile Vocabulary Screen

## Task ID

`M7-F04-T01`

## Title

Implement mobile vocabulary screen.

## Goal

Show local vocabulary cards in Due, All, and Private Sentences tabs.

## Scope

This task only does:

- Add vocabulary screen controller.
- Update Vocabulary screen with tabs and local list states.
- Add widget tests for empty, loading, due, all, and private sentence states.

This task does not:

- Add review action behavior.
- Add sync worker.
- Add card editing.
- Add public lexeme admin tools.

## Allowed Files

- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_screen.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_controller.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_card_tile.dart`
- `apps/mobile/lib/src/features/vocabulary/data/local_word_card_repository.dart`
- `apps/mobile/lib/src/app/app_router.dart`
- `apps/mobile/test/src/features/vocabulary/vocabulary_screen_test.dart`
- `apps/mobile/test/src/features/vocabulary/vocabulary_controller_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/vocabulary/presentation/review_controller.dart`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/reader/**`
- `apps/mobile/pubspec.yaml`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `apps/mobile/lib/src/features/vocabulary/data/local_word_card_repository.dart`
- `apps/mobile/lib/src/features/vocabulary/presentation/vocabulary_screen.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/vocabulary/vocabulary_screen_test.dart`
- `apps/mobile/test/src/features/vocabulary/vocabulary_controller_test.dart`

Test behavior:

- Vocabulary screen has Due, All, and Private Sentences tabs.
- Due tab shows cards whose `next_review_at` is null or due now.
- All tab shows lexeme and private sentence cards.
- Private Sentences tab shows only `card_type=private_sentence`.
- Empty states are distinct for due and all cards.
- Card tile shows surface, reading when present, definition, review status, and next review time.
- Private sentence card tile does not show another user's private context.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/vocabulary/vocabulary_screen_test.dart test/src/features/vocabulary/vocabulary_controller_test.dart
```

Expected red result:

- Tests fail because vocabulary controller or tab UI does not exist.

## Implementation Steps

- [ ] Step 1: Write vocabulary controller and screen tests.
- [ ] Step 2: Run red tests and confirm missing tab or controller behavior.
- [ ] Step 3: Create `VocabularyController` that loads due, all, and private sentence cards for current user.
- [ ] Step 4: Create `VocabularyCardTile` for common card display.
- [ ] Step 5: Update `VocabularyScreen` with three tabs.
- [ ] Step 6: Render loading, empty, and list states.
- [ ] Step 7: Filter all repository calls by current owner user id.
- [ ] Step 8: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/vocabulary/vocabulary_screen_test.dart test/src/features/vocabulary/vocabulary_controller_test.dart
flutter analyze
```

## Acceptance Criteria

- Vocabulary screen tests pass.
- Due, All, and Private Sentences tabs work from local data.
- Private sentence cards are owner-filtered.
- No review update behavior is added in this task.
- No backend API calls are required for screen display.

## Stop Conditions

- Local word card repository is incomplete.
- Current user id is unavailable from auth session.
- UI requires files outside Allowed Files.
- Any implementation exposes another user's private sentence context.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
