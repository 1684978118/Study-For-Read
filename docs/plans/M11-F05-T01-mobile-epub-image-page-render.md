# M11-F05-T01 Mobile EPUB Image Page Render

## Task ID

`M11-F05-T01`

## Title

Preserve and render EPUB image-only pages during mobile reading.

## Goal

Allow EPUB books that contain image-only spine pages to import successfully and show those pages as actual images in the Reader.

## Scope

This task only does:

- Update EPUB parsing so a spine item with no visible text can still become an image page chapter.
- Extract referenced local EPUB image resources into the app's private book storage.
- Render image page chapters as actual images in the Reader.
- Allow tapping an image page to preview it larger.
- Add focused tests that reproduce the current import failure and verify actual image rendering.
- Keep the change local-first and offline.

This task does not:

- Render full EPUB HTML/CSS layouts.
- Support remote image URLs or external EPUB resources.
- Add new database tables or backend APIs.
- Change TXT parsing, library import flow, auth, sync, or vocabulary/stats logic.
- Upload image bytes, raw chapter text, or file paths anywhere new.

## Allowed Files

Always allowed:

- `docs/plans/M11_MOBILE_ACCEPTANCE_IMPROVEMENTS.md`
- `docs/plans/M11-F05-T01-mobile-epub-image-page-render.md`

Allowed only if the failing test shows the image-only EPUB import gap:

- `apps/mobile/lib/src/features/library/data/book_parse_result.dart`
- `apps/mobile/lib/src/features/library/data/book_import_service.dart`
- `apps/mobile/lib/src/features/library/data/epub_book_parser.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_screen.dart`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/test/src/features/library/book_import_service_test.dart`
- `apps/mobile/test/src/features/library/epub_book_parser_test.dart`
- `apps/mobile/test/src/features/reader/reader_screen_test.dart`
- Matching focused tests under `apps/mobile/test/src/features/library/**` or `apps/mobile/test/src/features/reader/**`

## Forbidden Files

- `apps/mobile/lib/src/features/**/domain/**` other than the explicitly allowed parse result file above
- `apps/mobile/lib/src/features/**/data/**` other than the explicitly allowed EPUB parser file above
- `apps/mobile/pubspec.yaml`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Read First

- `AGENTS.md`
- `docs/plans/M11_MOBILE_ACCEPTANCE_IMPROVEMENTS.md`
- `apps/mobile/lib/src/features/library/data/epub_book_parser.dart`
- `apps/mobile/test/src/features/library/epub_book_parser_test.dart`

## Tests First

Before any production change:

- Add a focused import/parser test showing the current EPUB import failure on an image-only spine page.
- Add a focused reader widget test proving image page chapters render as images.
- Run the focused test and confirm it fails for the expected reason.

## Implementation Steps

- [x] Step 1: Add the failing import/parser test for an EPUB spine item that contains only an image.
- [x] Step 2: Run the focused test and confirm the current import still fails.
- [x] Step 3: Implement the smallest import/parser change to extract and preserve the image page.
- [x] Step 4: Add a focused reader widget test for image page rendering and preview.
- [x] Step 5: Run the focused test, full Flutter test suite, and analyze.
- [x] Step 6: Re-import the sample EPUB in the Android emulator and confirm the book opens.
- [ ] Step 7: Commit and push only tracked task-card and code/test files. Do not commit screenshots unless explicitly requested.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/library/epub_book_parser_test.dart
D:\flutter\flutter\bin\flutter.bat test test/src/features/library/book_import_service_test.dart
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_screen_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
```

## Acceptance Criteria

- The sample EPUB with image-only spine pages imports without failing.
- Image-only pages are preserved as local image page chapters instead of being dropped.
- The Reader can open the imported book and display image pages as images.
- Tapping an image page opens a larger preview and can return to reading.
- No new raw image bytes, chapter text leaks, original file paths, tokens, passwords, or secrets are exposed.
- Full Flutter tests and analyze pass if production or test code changes are made.

## Stop Conditions

- Fixing the reader presentation requires files outside Allowed Files.
- The issue turns out to require backend or database schema changes.
- A requested action would bulk-delete files or directories.
- The EPUB sample cannot be exercised locally on the emulator.

## Completion Report Format

Reply with:

- Modified files.
- Emulator/device status.
- Screenshot artifact paths, if captured.
- Visual findings.
- Red test result, if any production issue was fixed.
- Verification commands.
- Verification results.
- Whether any Allowed Files boundary was crossed.
- Blockers.
- Recommended next task card.
