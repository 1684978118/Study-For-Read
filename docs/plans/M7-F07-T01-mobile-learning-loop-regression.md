# M7-F07-T01 Mobile Learning Loop Regression

## Task ID

`M7-F07-T01`

## Title

Add mobile learning loop regression tests.

## Goal

Protect the complete first-release mobile learning path with fake HTTP and local storage.

## Scope

This task only does:

- Add regression tests across Reader lookup, inline paragraph translation, vocabulary save, review, Anki export, stats, and sync payload boundaries.
- Fix only boundary failures found by those tests.

This task does not:

- Add new features.
- Add live backend integration.
- Add web or admin code.
- Add full-book translation.

## Allowed Files

- `apps/mobile/test/src/regression/mobile_learning_loop_regression_test.dart`
- If and only if tests expose a boundary failure, these files may be modified:
  - `apps/mobile/lib/src/features/study/presentation/lookup_controller.dart`
  - `apps/mobile/lib/src/features/study/presentation/paragraph_translation_controller.dart`
  - `apps/mobile/lib/src/features/vocabulary/presentation/save_vocabulary_controller.dart`
  - `apps/mobile/lib/src/features/vocabulary/presentation/review_controller.dart`
  - `apps/mobile/lib/src/features/vocabulary/export/anki_export_service.dart`
  - `apps/mobile/lib/src/features/stats/data/study_stats_tracker.dart`
  - `apps/mobile/lib/src/features/sync/data/learning_sync_worker.dart`
  - `apps/mobile/lib/src/features/sync/data/pending_sync_event_repository.dart`
  - `apps/mobile/lib/src/features/vocabulary/data/local_word_card_repository.dart`
  - `apps/mobile/lib/src/features/study/data/local_translation_cache_repository.dart`
  - `apps/mobile/lib/src/features/stats/data/local_study_stats_repository.dart`

## Forbidden Files

- `apps/mobile/pubspec.yaml`
- `apps/mobile/lib/src/features/auth/**`
- `apps/mobile/lib/src/core/database/mobile_database_migrations.dart`
- `apps/mobile/lib/src/features/library/data/local_chapter_repository.dart`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/specs/PRD-v2.md`
- `docs/specs/UI_FLOWS.md`
- `docs/specs/MOBILE_UI_STYLE.md`
- `docs/specs/API_CONTRACT.md`
- `docs/specs/MOBILE_LOCAL_DATA.md`
- All M7 mobile learning loop task cards.

## Tests First

Create:

- `apps/mobile/test/src/regression/mobile_learning_loop_regression_test.dart`

Test behavior:

- A signed-in test user opens an imported local book, looks up a Japanese word, and sees a lookup result.
- The lookup result includes kana reading and a speaker pronunciation button.
- Saving the lookup result creates a local lexeme card.
- Tapping the subtle paragraph-end `+` translates one paragraph and caches the result locally.
- The translated paragraph is inserted inline below the original paragraph.
- Translated paragraphs do not show copy, save, or collapse buttons.
- Reviewing the saved card offline updates local review state.
- Exporting vocabulary generates Anki-compatible text locally.
- Local stats show one lookup, one paragraph translation, at least one card created, and one card reviewed.
- Sync worker payloads contain no original file path, chapter content, full paragraph text, or translated text.
- The test uses fake HTTP and no live backend.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/regression/mobile_learning_loop_regression_test.dart
```

Expected red or green result:

- If prior tasks already comply, test may pass after writing it.
- If it fails, failure must show an actual learning-loop or privacy boundary gap.

## Implementation Steps

- [ ] Step 1: Write mobile learning loop regression test.
- [ ] Step 2: Run verification command.
- [ ] Step 3: If tests pass, do not change production code.
- [ ] Step 4: If tests fail due to learning-loop or sync privacy boundary leaks, fix only the relevant Allowed Files.
- [ ] Step 5: Run verification command again.
- [ ] Step 6: Run all M7 mobile learning tests.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/regression/mobile_learning_loop_regression_test.dart
flutter test
flutter analyze
```

## Acceptance Criteria

- Learning-loop regression test passes.
- All mobile tests pass.
- Lookup, inline translation, save card, review, Anki export, stats, and sync boundaries work together.
- Reader paragraph translation matches `MOBILE_UI_STYLE.md`.
- Anki export generates local text and does not upload anything.
- Sync payloads never contain original file content, chapter content, paragraph text, or translated text.
- No backend, web, infra, or old project files are modified.

## Stop Conditions

- Any prior M7 task is incomplete.
- Failure requires changing database migration files.
- Fix requires modifying files outside Allowed Files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
