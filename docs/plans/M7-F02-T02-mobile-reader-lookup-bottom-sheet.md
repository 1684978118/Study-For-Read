# M7-F02-T02 Mobile Reader Lookup Bottom Sheet

## Task ID

`M7-F02-T02`

## Title

Add reader lookup bottom sheet.

## Goal

Allow the user to tap or select text in Reader, call lookup, and see a result bottom sheet with save action placeholder.

## Scope

This task only does:

- Add reader selection model.
- Add lookup controller.
- Add lookup bottom sheet UI states.
- Wire Reader text tap or selection to lookup.
- Cache returned public lexeme locally.
- Increment lookup stats locally.

This task does not:

- Save vocabulary cards.
- Add paragraph translation.
- Add annotation token rendering.
- Add backend sync worker.

## Allowed Files

- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/lib/src/features/study/presentation/lookup_bottom_sheet.dart`
- `apps/mobile/lib/src/features/study/presentation/lookup_controller.dart`
- `apps/mobile/lib/src/features/study/domain/reader_text_selection.dart`
- `apps/mobile/lib/src/features/study/data/study_api_client.dart`
- `apps/mobile/lib/src/features/study/data/local_lexeme_repository.dart`
- `apps/mobile/lib/src/features/stats/data/local_study_stats_repository.dart`
- `apps/mobile/test/src/features/study/lookup_controller_test.dart`
- `apps/mobile/test/src/features/reader/reader_lookup_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/vocabulary/**`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/lib/src/features/study/presentation/paragraph_translation_sheet.dart`
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
- `docs/specs/API_CONTRACT.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/lib/src/features/study/data/study_api_client.dart`

## Tests First

Create:

- `apps/mobile/test/src/features/study/lookup_controller_test.dart`
- `apps/mobile/test/src/features/reader/reader_lookup_test.dart`

Test behavior:

- Lookup controller sends selected text and optional paragraph context to `StudyApiClient.lookup`.
- Successful public lexeme lookup is cached in `local_lexeme_cache`.
- Successful lookup increments today's `lookup_count`.
- Provider unavailable state leaves Reader usable and shows error state.
- Offline state shows offline unavailable message.
- Bottom sheet shows surface, reading, short definition, full definition, entry type, speaker pronunciation button, and Save action.
- Reader lookup does not send full chapter text as context.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/study/lookup_controller_test.dart test/src/features/reader/reader_lookup_test.dart
```

Expected red result:

- Tests fail because lookup controller or bottom sheet does not exist.

## Implementation Steps

- [ ] Step 1: Write lookup controller and Reader lookup widget tests.
- [ ] Step 2: Run red tests and confirm missing lookup UI or controller failures.
- [ ] Step 3: Create `ReaderTextSelection` with selected text and optional paragraph context.
- [ ] Step 4: Create `LookupController` with loading, success, not found, offline, and error states.
- [ ] Step 5: Cache public lexeme results through `LocalLexemeRepository`.
- [ ] Step 6: Increment local `lookup_count` on successful lookup.
- [ ] Step 7: Create `LookupBottomSheet` matching `UI_FLOWS.md`.
- [ ] Step 8: Add visible kana reading and speaker pronunciation button matching `MOBILE_UI_STYLE.md`.
- [ ] Step 9: Wire Reader text interaction to open the bottom sheet.
- [ ] Step 10: Keep Save action disabled or callback-only until the save vocabulary task.
- [ ] Step 11: Run verification command.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/features/study/lookup_controller_test.dart test/src/features/reader/reader_lookup_test.dart
flutter analyze
```

## Acceptance Criteria

- Lookup tests pass.
- Reader remains usable after lookup errors.
- Lookup result is visible in bottom sheet.
- Lookup bottom sheet shows kana reading and a speaker pronunciation button.
- Lookup stats increment locally.
- No vocabulary card creation happens in this task.
- No full chapter text is sent to lookup API.

## Stop Conditions

- Study API client is incomplete.
- Learning local data is incomplete.
- Reader text widget cannot support selection without modifying files outside Allowed Files.
- Any implementation sends full chapters or original book files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
