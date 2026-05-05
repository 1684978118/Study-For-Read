# M6-F07-T01 Mobile Offline Reading Regression

## Task ID

`M6-F07-T01`

## Title

Add mobile offline reading regression tests.

## Goal

Protect the first mobile local-first boundary: imported books remain readable offline and raw book content never enters sync payloads.

## Scope

This task only does:

- Add regression tests across import, local storage, library, reader, and pending sync events.
- Fix only boundary failures found by those tests.

This task does not:

- Add new product features.
- Add lookup or translation.
- Add vocabulary review.
- Add backend sync worker.
- Add web or admin code.

## Allowed Files

- `apps/mobile/test/src/regression/offline_reading_regression_test.dart`
- If and only if tests expose a boundary failure, these files may be modified:
  - `apps/mobile/lib/src/features/library/data/book_import_service.dart`
  - `apps/mobile/lib/src/features/library/data/book_file_storage_service.dart`
  - `apps/mobile/lib/src/features/library/data/local_book_repository.dart`
  - `apps/mobile/lib/src/features/library/data/local_chapter_repository.dart`
  - `apps/mobile/lib/src/features/library/presentation/library_controller.dart`
  - `apps/mobile/lib/src/features/library/presentation/library_screen.dart`
  - `apps/mobile/lib/src/features/reader/data/local_reading_position_repository.dart`
  - `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
  - `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
  - `apps/mobile/lib/src/features/sync/data/pending_sync_event_repository.dart`

## Forbidden Files

- `apps/mobile/pubspec.yaml`
- `apps/mobile/lib/src/features/auth/**`
- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/vocabulary/**`
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
- `docs/specs/MOBILE_LOCAL_DATA.md`
- All M6 mobile task cards.

## Tests First

Create:

- `apps/mobile/test/src/regression/offline_reading_regression_test.dart`

Test behavior:

- A signed-in test user can import a local TXT fixture, see it in Library, open Reader, and read chapter text without a network client.
- Closing and reopening Reader restores saved local reading position.
- Pending sync event for imported book contains metadata only.
- Pending sync event for reading progress contains position only.
- Pending sync payloads do not include `content`, `chapterContent`, `chapter_content`, `originalFile`, `original_file`, `filePath`, `file_path`, `rawText`, `raw_text`, `translatedText`, or `translated_text`.
- Library and Reader do not require live backend when local data already exists.

Run before implementation:

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/regression/offline_reading_regression_test.dart
```

Expected red or green result:

- If prior tasks already comply, test may pass after writing it.
- If it fails, failure must show an actual offline or privacy boundary gap.

## Implementation Steps

- [ ] Step 1: Write offline reading regression test.
- [ ] Step 2: Run verification command.
- [ ] Step 3: If tests pass, do not change production code.
- [ ] Step 4: If tests fail due to offline reading or raw-content sync leaks, fix only the relevant Allowed Files.
- [ ] Step 5: Run verification command again.
- [ ] Step 6: Run all M6 mobile tests.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
flutter test test/src/regression/offline_reading_regression_test.dart
flutter test
flutter analyze
```

## Acceptance Criteria

- Offline regression test passes.
- All M6 mobile tests pass.
- Already imported books remain readable without network.
- Local progress is restored.
- Sync payloads never contain raw book or chapter content.
- No backend, web, infra, or old project files are modified.

## Stop Conditions

- Reader basic page task is incomplete.
- Import orchestration task is incomplete.
- Failure requires adding a dependency.
- Fix requires modifying files outside Allowed Files.
- Any command would delete files or directories in bulk.

## Completion Report Format

Reply with:

- Modified files.
- Verification command.
- Verification result.
- Blockers.
- Recommended next task card.
