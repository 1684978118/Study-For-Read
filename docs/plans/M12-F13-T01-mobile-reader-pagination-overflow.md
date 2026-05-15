# M12-F13-T01 Mobile Reader Pagination Overflow

## Task ID

`M12-F13-T01`

## Title

Remove debug overflow stripes from mobile Reader pages.

## Goal

Fix the yellow and black Flutter overflow stripe shown at the bottom of the mobile Reader when a Japanese paragraph is taller than the available page area.

## Scope

This task does:

- Add a Reader widget regression test that fails on bottom `RenderFlex` overflow.
- Split oversized text paragraphs during pagination so a single long paragraph can continue across pages.
- Keep first-line indentation for displayed text.
- Keep Reader settings, directory, page-turn modes, volume keys, and EPUB image page behavior intact.

This task does not:

- Hide the debug stripe by turning off debug rendering.
- Remove paragraph translation hotspots.
- Change EPUB parser, import flow, backend APIs, or stored book content.
- Change production authentication or deployment configuration.

## Allowed Files

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F13-T01-mobile-reader-pagination-overflow.md`
- `docs/acceptance/M12-mobile-reader-pagination-overflow.md`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `apps/mobile/test/src/features/reader/reader_screen_test.dart`

## Forbidden Files

- `apps/mobile/lib/src/features/library/**`
- `apps/mobile/lib/src/features/study/**`
- `apps/mobile/lib/src/features/reader/data/**`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/android/**`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any screenshots, APKs, `.env`, secrets, or user book files

## TDD Steps

- [x] Step 1: Add a failing Reader widget test for bottom `RenderFlex` overflow on a long Japanese paragraph.
- [x] Step 2: Verify the test fails with `A RenderFlex overflowed`.
- [x] Step 3: Split oversized paragraphs in the pagination engine.
- [x] Step 4: Run the focused regression test until it passes.
- [x] Step 5: Run Reader tests, full mobile tests, analyze, and an emulator build/install.

## Verification Commands

```powershell
cd "D:\Codex\Study For Read Phone\apps\mobile"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_screen_test.dart --plain-name "paginated Japanese reader pages do not overflow at bottom"
D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/reader_screen_test.dart
D:\flutter\flutter\bin\flutter.bat test
D:\flutter\flutter\bin\flutter.bat analyze
D:\flutter\flutter\bin\flutter.bat build apk --debug --target-platform android-x64 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## Acceptance Criteria

- The Reader no longer shows Flutter yellow/black bottom overflow stripes for long Japanese paragraphs.
- Oversized paragraphs remain readable across paginated pages.
- Full Reader widget tests pass.
- Full mobile tests and analyze pass.
- No user book file or screenshot is committed.
