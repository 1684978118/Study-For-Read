# M12-F07-T01 Mobile Reader Page Turn Modes

## Task ID

`M12-F07-T01`

## Title

Apply Reader page-turn modes to paginated reading.

## Goal

Make the persisted Reader page-turn mode affect real reading interaction instead of remaining a settings-only value.

## Scope

This task does:

- Pass `ReaderPageTurnMode` from `ReaderScreen` into `ReadingTextView`.
- Keep `平移` as the default horizontal paged swipe.
- Make `上下` use vertical page swiping.
- Make `无动画` disable gesture swiping and rely on programmatic page changes.
- Add lightweight observable page presentation differences for `覆盖` and `仿真`.

This task does not:

- Implement a full paper-curl renderer.
- Add native Android code.
- Add hardware volume-key paging; that belongs to M12-F08.
- Change database schema.
- Add backend APIs or sync Reader preferences.

## Allowed Files

Always allowed:

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F07-T01-mobile-reader-page-turn-modes.md`

Allowed for implementation:

- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
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
- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
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

- Add widget test proving `上下` uses a vertical `PageView` and vertical drag changes page.
- Add widget test proving `无动画` disables swipe gestures.
- Add widget test proving `覆盖` and `仿真` modes are applied to rendered page widgets with observable mode keys.
- Run focused tests and confirm red before implementation.

## Implementation Steps

- [x] Step 1: Add red widget tests.
- [x] Step 2: Confirm focused tests fail because `ReadingTextView` does not receive or apply page-turn mode.
- [x] Step 3: Add `pageTurnMode` to `ReadingTextView`.
- [x] Step 4: Map `上下` to vertical `PageView`.
- [x] Step 5: Map `无动画` to non-scrollable page physics.
- [x] Step 6: Add lightweight cover/simulation page wrappers.
- [x] Step 7: Run focused tests, full Flutter tests, and analyze.
- [x] Step 8: Commit and push only allowed tracked files.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_screen_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Acceptance Criteria

- `平移` remains horizontal paged swiping.
- `上下` changes the reading pager to vertical swiping.
- `无动画` disables swipe gestures so pages only change through controller/programmatic navigation.
- `覆盖` and `仿真` are applied as distinct page wrappers, with full paper curl left for future refinement.
- Existing directory, night, settings, lookup, paragraph translation, and EPUB image display remain usable.
- No backend call is added.
- Full Flutter tests and analyze pass.

## Stop Conditions

- A full paper-curl renderer requires custom canvas work beyond the current task.
- Native Android code or a new dependency becomes necessary.

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
