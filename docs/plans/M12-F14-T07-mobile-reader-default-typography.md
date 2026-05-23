# M12-F14-T07 Mobile Reader Default Typography

## Summary

Tighten the mobile reader's default typography so an imported novel opens with a normal reading density instead of oversized acceptance-style text. This card only changes default reader layout preferences and their tests. Existing user-saved preferences must continue to load unchanged.

## Scope

- Change the default reader typography to:
  - `fontSize`: `18`
  - `lineHeight`: `1.55`
  - `paragraphSpacing`: `10`
- Keep user preference persistence intact.
- Keep the settings panel controls and clamp ranges intact.
- Keep paragraph translation hotspot, lookup, reader controls, directory, EPUB image rendering, and translation APIs unchanged.

## Allowed Files

- `apps/mobile/lib/src/features/reader/domain/reader_preferences.dart`
- `apps/mobile/lib/src/features/reader/presentation/reader_controller.dart`
- `apps/mobile/test/src/features/reader/local_reader_preferences_repository_test.dart`
- `apps/mobile/test/src/features/reader/reader_controller_test.dart`
- `apps/mobile/test/src/features/reader/reader_screen_test.dart`
- `docs/plans/M12-F14-T07-mobile-reader-default-typography.md`

## Test Plan

1. Add or update tests proving empty/local default reader preferences use `18 / 1.55 / 10`.
2. Add or update controller tests proving `ReaderController.defaultFontSize` and initial loaded preferences match the denser defaults.
3. Add or update reader screen tests proving the first `ReadingTextView` receives the denser defaults when no saved preference exists.
4. Verify saved preferences still override defaults.

## Validation

- `D:\flutter\flutter\bin\flutter.bat test test/src/features/reader/local_reader_preferences_repository_test.dart test/src/features/reader/reader_controller_test.dart test/src/features/reader/reader_screen_test.dart`
- `D:\flutter\flutter\bin\flutter.bat analyze`
- `D:\flutter\flutter\bin\flutter.bat test`
- Build debug APK and install to LDPlayer for visual acceptance.

## Acceptance Criteria

- A fresh reader opens with default `fontSize = 18`, `lineHeight = 1.55`, and `paragraphSpacing = 10`.
- A saved reader preference still wins over the default.
- The reader page no longer feels like oversized demo text by default.
- No new backend, sync, translation, lookup, import, or EPUB image behavior is introduced.
