# M12-F03-T01 Mobile Reader Bottom Controls And Directory

## Task ID

`M12-F03-T01`

## Title

Add Fanqie-style Reader bottom controls, real chapter directory, and night toggle.

## Goal

Replace the temporary Reader bottom controls with a Fanqie-style control overlay: previous chapter, chapter progress slider, next chapter, and a bottom action row for real directory, night mode, and settings entry.

## Scope

This task does:

- Show a top Reader header and a bottom Fanqie-style control panel when tapping blank Reader space.
- Replace the current font-size slider in the bottom bar with a real chapter progress slider.
- Add bottom action buttons: `目录`, `夜间` or `日间`, and `设置`.
- Open a real chapter directory panel sourced from loaded local chapters.
- Jump to a tapped chapter from the directory and save local reading progress as dirty.
- Toggle night mode through `ReaderController`, persist the preference, and update Reader background/text presentation.
- Keep `设置` as a visible entry point only; the full settings panel belongs to M12-F04.

This task does not:

- Implement the settings panel.
- Implement brightness controls.
- Implement background preset selection.
- Implement line height, paragraph spacing, page-turn modes, or volume-key paging.
- Add backend APIs, sync Reader preferences, or upload book/chapter content.

## Allowed Files

Always allowed:

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F03-T01-mobile-reader-bottom-controls-directory.md`

Allowed for implementation:

- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/test/src/features/reader/reader_controller_test.dart`
- `apps/mobile/test/src/features/reader/reader_screen_test.dart`

## Forbidden Files

- `apps/mobile/pubspec.yaml`
- `apps/mobile/android/**`
- `apps/mobile/lib/src/core/database/**`
- `apps/mobile/lib/src/features/library/**`
- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/vocabulary/**`
- `apps/mobile/lib/src/features/sync/**`
- `apps/mobile/lib/src/features/settings/**`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/lib/src/features/reader/domain/reader_preferences.dart`
- `apps/mobile/lib/src/features/reader/data/local_reader_preferences_repository.dart`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Tests First

Before production changes:

- Add controller test proving `goToChapter` jumps to a valid chapter and saves dirty progress.
- Add controller test proving invalid chapter jumps are ignored.
- Add controller test proving `toggleNightMode` persists pure-black night mode and restores the previous background on the next toggle.
- Add widget test proving the visible bottom overlay has `上一章`, a chapter progress slider, `下一章`, `目录`, `夜间`, and `设置`.
- Add widget test proving `目录` opens real chapter titles and tapping one jumps to that chapter.
- Add widget test proving `夜间` changes Reader presentation and the button becomes `日间`.
- Run focused tests and confirm red before implementation.

## Implementation Steps

- [x] Step 1: Add red controller and widget tests.
- [x] Step 2: Confirm focused tests fail for missing `goToChapter`, missing night toggle, and missing new overlay actions.
- [x] Step 3: Add controller chapter list exposure, `goToChapter`, and `toggleNightMode`.
- [x] Step 4: Replace bottom font-size slider with chapter progress slider and action row.
- [x] Step 5: Add directory bottom sheet using real local chapter titles.
- [x] Step 6: Apply night-mode background/text presentation on the Reader screen.
- [x] Step 7: Run focused tests, full Flutter tests, and analyze.
- [x] Step 8: Commit and push only allowed tracked files.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_controller_test.dart test/src/features/reader/reader_screen_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Acceptance Criteria

- Blank tap still toggles Reader overlay controls.
- Overlay top header still shows book title and current chapter title.
- Bottom progress row shows `上一章`, a chapter progress slider, and `下一章`.
- Bottom action row shows `目录`, `夜间` or `日间`, and `设置`.
- Directory lists real loaded local chapter titles.
- Tapping a directory chapter jumps to that chapter and saves dirty progress.
- Night toggle persists through the preferences repository.
- Night mode visibly changes the Reader page to a dark reading presentation; toggling back restores the previous background preference.
- `设置` is visible but does not open the settings panel in this task.
- No backend call is added.
- No sync payload contains original file path, full chapter/book content, selected text, paragraph text, translated text, image bytes, tokens, passwords, or secrets.
- Full Flutter tests and analyze pass.

## Stop Conditions

- The directory requires a new database query or repository contract outside `ReaderController`.
- Night mode requires Android native code.
- Implementing the settings panel becomes necessary; stop and create M12-F04 instead.

## Completion Report Format

Reply with:

- Modified files.
- Red test result.
- Verification commands.
- Verification results.
- Whether production code changed.
- Whether any Allowed Files boundary was crossed.
- Whether code was uploaded.
- Blockers.
- Recommended next task card.
