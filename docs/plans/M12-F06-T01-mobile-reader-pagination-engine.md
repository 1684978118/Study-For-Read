# M12-F06-T01 Mobile Reader Pagination Engine

## Task ID

`M12-F06-T01`

## Title

Add real chapter pagination for the mobile Reader.

## Goal

Replace the Reader's full-chapter scroll behavior with real page-based reading inside each chapter, while keeping page-turn animation variants for the later page-turn task.

## Scope

This task does:

- Add Reader page state to `ReaderController`.
- Reset page state when changing chapters.
- Add bounded page navigation methods that can later be used by tap/volume/page-turn controls.
- Paginate visible chapter paragraphs based on the available Reader viewport, font size, line height, and paragraph spacing.
- Render pages with a horizontal `PageView` for the default slide-style reading feel.
- Keep lookup, paragraph translation, and EPUB image page rendering usable inside paginated pages.

This task does not:

- Implement `仿真`, `覆盖`, `上下`, or `无动画` page-turn mode behavior; that belongs to M12-F07.
- Implement hardware volume-key paging; that belongs to M12-F08.
- Change database schema.
- Add backend APIs or sync page content.

## Allowed Files

Always allowed:

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F06-T01-mobile-reader-pagination-engine.md`

Allowed for implementation:

- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
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

- Add controller test proving page count/current page state is bounded.
- Add controller test proving next/previous page cross chapter boundaries only at page edges.
- Add widget test proving a long chapter produces multiple Reader pages.
- Add widget test proving swiping the Reader page view updates `ReaderController.currentPageIndex`.
- Run focused tests and confirm red before implementation.

## Implementation Steps

- [x] Step 1: Add red controller and widget tests.
- [x] Step 2: Confirm focused tests fail for missing page state and `reader-page-view`.
- [x] Step 3: Add page state and bounded page navigation methods to `ReaderController`.
- [x] Step 4: Convert `ReadingTextView` to support paginated PageView rendering.
- [x] Step 5: Wire `ReaderScreen` to pass page state and receive page count/page changes.
- [x] Step 6: Run focused tests, full Flutter tests, and analyze.
- [x] Step 7: Commit and push only allowed tracked files.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_controller_test.dart test/src/features/reader/reader_screen_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Acceptance Criteria

- Long chapters render as multiple Reader pages, not one continuous scroll.
- Horizontal swiping moves between pages and updates controller page state.
- Changing chapter resets the current page to the first page.
- Page state is bounded when page count changes.
- Lookup and paragraph translation callbacks still work on visible page text.
- EPUB image pseudo-paragraphs still render as image pages.
- No backend call is added.
- No sync payload contains original file path, full chapter/book content, selected text, paragraph text, translated text, image bytes, tokens, passwords, or secrets.
- Full Flutter tests and analyze pass.

## Stop Conditions

- Accurate typography requires native text layout APIs or a new third-party dependency.
- Implementing page-turn animation variants becomes necessary; stop and handle them in M12-F07.

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
