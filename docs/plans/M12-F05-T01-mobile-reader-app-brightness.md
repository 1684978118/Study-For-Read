# M12-F05-T01 Mobile Reader App Brightness

## Task ID

`M12-F05-T01`

## Title

Apply Reader-only app brightness from the settings panel.

## Goal

Make the Reader `亮度` setting real by dimming only the Reader page inside the app, without changing Android system brightness or adding platform/native code.

## Scope

This task does:

- Add `ReaderController.setBrightness`.
- Clamp brightness to a safe app-local range.
- Enable the existing Reader settings `亮度` slider.
- Persist brightness changes through the existing Reader preferences repository.
- Apply brightness visually in the Reader page with an app-local dim overlay.

This task does not:

- Change global Android system brightness.
- Add Android native code or platform channels.
- Add a system permission.
- Implement page-turn animations.
- Implement volume-key paging.
- Add backend APIs or sync Reader preferences.

## Allowed Files

Always allowed:

- `docs/plans/M12_MOBILE_TOMATO_READER.md`
- `docs/plans/M12-F05-T01-mobile-reader-app-brightness.md`

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
- `apps/mobile/lib/src/features/reader/domain/reader_preferences.dart`
- `apps/mobile/lib/src/features/reader/data/local_reader_preferences_repository.dart`
- `apps/mobile/lib/src/features/reader/presentation/reading_text_view.dart`
- `server/**`
- `apps/web-reader/**`
- `apps/web-admin/**`
- `infra/**`
- Any old project path under `D:\Codex\Study for Read`
- Any file not listed in Allowed Files

## Tests First

Before production changes:

- Add controller test proving `setBrightness` clamps, persists, and does not require native/system hooks.
- Add widget test proving the `亮度` slider is enabled.
- Add widget test proving moving the brightness slider persists the value and shows a Reader-only dim overlay.
- Run focused tests and confirm red before implementation.

## Implementation Steps

- [x] Step 1: Add red controller and widget tests.
- [x] Step 2: Confirm focused tests fail for missing `setBrightness` and disabled brightness slider.
- [x] Step 3: Add `ReaderController.setBrightness` with app-local clamp.
- [x] Step 4: Enable the settings brightness slider.
- [x] Step 5: Add a Reader-only dim overlay keyed for tests.
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

- Brightness slider in Reader settings is enabled.
- Brightness changes persist to local Reader preferences.
- Brightness visually affects the Reader page only through app UI.
- No Android native code or system brightness API is added.
- No backend call is added.
- No sync payload contains original file path, full chapter/book content, selected text, paragraph text, translated text, image bytes, tokens, passwords, or secrets.
- Full Flutter tests and analyze pass.

## Stop Conditions

- Real brightness requires a system-level brightness API.
- A new third-party dependency is required.
- Any Android permission or platform-channel change is needed.

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
